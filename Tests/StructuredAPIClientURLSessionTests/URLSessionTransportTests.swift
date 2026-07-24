//===----------------------------------------------------------------------===//
//
// This source file is part of the StructuredAPIClient open source project
//
// Copyright (c) Stairtree GmbH
// Licensed under the MIT license
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Foundation)
import Foundation
#endif
import StructuredAPIClient
import StructuredAPIClientURLSession
import HTTPTypes

/// A `URLProtocol` that serves canned responses so the transport can be tested without a network.
final class StubURLProtocol: URLProtocol {
    struct Stub: Sendable {
        var handler: @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    }

    private static let current = NIOLockedValueBox<Stub?>(nil)

    static func setHandler(_ handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?) {
        self.current.withLockedValue { $0 = handler.map { Stub(handler: $0) } }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let stub = Self.current.withLockedValue({ $0 }) else {
            self.client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
            return
        }
        do {
            let (response, data) = try stub.handler(self.request)
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)
        } catch {
            self.client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class URLSessionTransportTests: XCTestCase {
    private func makeTransport() -> URLSessionTransport {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSessionTransport(URLSession(configuration: config))
    }

    func testRequestAndResponseRoundTrip() async throws {
        StubURLProtocol.setHandler { request in
            XCTAssertEqual(request.url?.absoluteString, "https://example.com/thing")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Test"), "42")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 201, httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "text/plain"]
            )!
            return (response, Data("hello".utf8))
        }
        defer { StubURLProtocol.setHandler(nil) }

        var head = HTTPRequest(method: .get, scheme: nil, authority: nil, path: nil)
        head.headerFields[HTTPField.Name("X-Test")!] = "42"
        let request = TransportRequest(url: URL(string: "https://example.com/thing")!, head: head)

        let response = try await self.makeTransport().send(request: request)
        XCTAssertEqual(response.status.code, 201)
        XCTAssertEqual(String(decoding: response.body, as: UTF8.self), "hello")
        XCTAssertEqual(response.headers[HTTPField.Name("Content-Type")!], "text/plain")
    }

    func testCancellationIsMapped() async throws {
        StubURLProtocol.setHandler { _ in throw URLError(.cancelled) }
        defer { StubURLProtocol.setHandler(nil) }

        let request = TransportRequest(
            url: URL(string: "https://example.com")!,
            head: .init(method: .get, scheme: nil, authority: nil, path: nil)
        )

        do {
            _ = try await self.makeTransport().send(request: request)
            XCTFail("Expected the request to fail with cancellation")
        } catch let failure as TransportFailure {
            XCTAssertEqual(failure, .cancelled)
        }
    }
}

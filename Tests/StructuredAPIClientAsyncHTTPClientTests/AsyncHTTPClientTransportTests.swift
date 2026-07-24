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

#if AsyncHTTPClientTransport
import XCTest
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
@testable import StructuredAPIClientAsyncHTTPClient
import StructuredAPIClient
import AsyncHTTPClient
import NIOCore
import NIOHTTP1
import HTTPTypes

final class AsyncHTTPClientTransportTests: XCTestCase {
    func testMakeRequestMapsMethodHeadersAndBody() throws {
        var head = HTTPRequest(method: .post, scheme: nil, authority: nil, path: nil)
        head.headerFields[.contentType] = "application/json"
        let request = TransportRequest(
            url: URL(string: "https://example.com/resource")!,
            head: head,
            body: Data(#"{"a":1}"#.utf8)
        )

        let httpRequest = try AsyncHTTPClientTransport.makeRequest(from: request)
        XCTAssertEqual(httpRequest.url, "https://example.com/resource")
        XCTAssertEqual(httpRequest.method, .POST)
        XCTAssertEqual(httpRequest.headers.first(name: "content-type"), "application/json")
    }

    func testHTTPMethodMapping() {
        XCTAssertEqual(AsyncHTTPClientTransport.httpMethod(from: .get), .GET)
        XCTAssertEqual(AsyncHTTPClientTransport.httpMethod(from: .delete), .DELETE)
        XCTAssertEqual(AsyncHTTPClientTransport.httpMethod(from: HTTPRequest.Method("WHATEVER")!), .RAW(value: "WHATEVER"))
    }

    func testMakeResponseMapsStatusHeadersAndBody() {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "text/plain")
        let clientResponse = HTTPClientResponse(status: .created, headers: headers)

        let response = AsyncHTTPClientTransport.makeResponse(clientResponse, body: ByteBuffer(string: "hi"))
        XCTAssertEqual(response.status.code, 201)
        XCTAssertEqual(response.headers[HTTPField.Name("Content-Type")!], "text/plain")
        XCTAssertEqual(String(decoding: response.body, as: UTF8.self), "hi")
    }

    func testCancelBeforeSendDoesNotPoisonTransport() {
        let transport = AsyncHTTPClientTransport()

        // Cancelling with nothing in flight must not permanently disable the transport.
        transport.cancel()

        // A subsequent request must be accepted — registered as in-flight — rather than
        // short-circuited to `.cancelled`. The target is a non-routable TEST-NET-1 address
        // (RFC 5737) so the request stays pending at its first `await`: no completion race, and
        // the assertion reads the transport's own state rather than any network result.
        let request = TransportRequest(
            url: URL(string: "http://192.0.2.1")!,
            head: .init(method: .get, scheme: nil, authority: nil, path: nil),
            timeoutInterval: 30
        )
        transport.send(request: request) { _ in }
        XCTAssertEqual(transport.inFlightRequestCount, 1, "cancel() must not poison the transport")

        // Cancelling again must stop the in-flight request and leave the transport usable.
        transport.cancel()
        XCTAssertEqual(transport.inFlightRequestCount, 0)
    }
}
#endif

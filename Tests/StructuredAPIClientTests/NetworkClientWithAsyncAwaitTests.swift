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
@testable import StructuredAPIClient
import StructuredAPIClientTestSupport

final class NetworkClientWithAsyncAwaitTests: XCTestCase {
    override class func setUp() {
        XCTAssert(isLoggingConfigured)
    }
        
    func testNetworkClientWithAsyncAwait() async throws {
        struct TestRequest: NetworkRequest {
            func makeRequest(baseURL: URL) throws -> URLRequest { URLRequest(url: baseURL) }
            func parseResponse(_ response: TransportResponse) throws -> String { .init(decoding: response.body, as: UTF8.self) }
        }
        
        let response: Result<TransportResponse, any Error> = .success(.init(status: .ok, headers: [:], body: Data("Test".utf8)))
        
        let requestAssertions: @Sendable (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
        }
        
        let client = NetworkClient(baseURL: URL(string: "https://test.somewhere.com")!, transport: TestTransport(responses: [response], assertRequest: requestAssertions))
        
        let value = try await client.load(TestRequest())
        
        XCTAssertEqual(value, "Test")
        XCTAssertEqual(client.baseURL.absoluteString, "https://test.somewhere.com")
    }
    
    func testTokenAuthWithAsyncAwait() async throws {
        struct TestRequest: NetworkRequest {
            func makeRequest(baseURL: URL) throws -> URLRequest { URLRequest(url: baseURL) }
            func parseResponse(_ response: TransportResponse) throws -> String { .init(decoding: response.body, as: UTF8.self) }
        }

        let accessToken = TestToken(raw: "abc", expiresAt: Date())
        let refreshToken = TestToken(raw: "def", expiresAt: Date())

        let tokenProvider = TestTokenProvider(accessToken: accessToken, refreshToken: refreshToken)

        let response: Result<TransportResponse, any Error> = .success(.init(status: .ok, headers: [:], body: Data("Test".utf8)))

        let requestAssertions: @Sendable (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
            XCTAssertEqual($0.allHTTPHeaderFields?["Authorization"], "Bearer abc")
        }

        let client = NetworkClient(
            baseURL: URL(string: "https://test.somewhere.com")!,
            transport: TokenAuthenticationHandler(
                base: TestTransport(responses: [response], assertRequest: requestAssertions),
                tokenProvider: tokenProvider
            )
        )
        
        let value = try await client.load(TestRequest())
        
        XCTAssertEqual(value, "Test")
        XCTAssertEqual(client.baseURL.absoluteString, "https://test.somewhere.com")
    }
}

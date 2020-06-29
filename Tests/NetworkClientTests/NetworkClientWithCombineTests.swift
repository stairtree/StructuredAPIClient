//===----------------------------------------------------------------------===//
//
// This source file is part of the Network Client open source project
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
import NetworkClient
import NetworkClientTestSupport
#if canImport(Combine)
import Combine

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
final class NetworkClientWithCombineTests: XCTestCase {
    var sink: AnyCancellable!
    
    override func setUp() {
        super.setUp()
        sink = nil
    }
    
    func testNetworkClientWithCombine() throws {
        struct TestRequest: NetworkRequest {
            func makeRequest(baseURL: URL) throws -> URLRequest { URLRequest(url: baseURL) }
            func parseResponse(_ data: Data) throws -> String { String(decoding: data, as: UTF8.self) }
        }
        
        let response: Response = .success(Data("Test".utf8))
        
        let requestAssertions: (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
        }
        
        let client = NetworkClient(baseURL: URL(string: "https://test.somewhere.com")!, transport: TestTransport(responses: [response], assertRequest: requestAssertions))
        
        let exp = expectation(description: "Result")
        
        sink = client.load(TestRequest())
            .sink (receiveCompletion: { _ in
                exp.fulfill()
            }, receiveValue: { value in
                XCTAssertEqual(value, "Test")
            })
        
        wait(for: [exp], timeout: 2)
        
        XCTAssertEqual(client.baseURL.absoluteString, "https://test.somewhere.com")
    }
    
    func testTokenAuthWithCombine() {
        struct TestRequest: NetworkRequest {
            func makeRequest(baseURL: URL) throws -> URLRequest { URLRequest(url: baseURL) }
            func parseResponse(_ data: Data) throws -> String { String(decoding: data, as: UTF8.self) }
        }

        let accessToken = TestToken(raw: "abc", expiresAt: Date())
        let refreshToken = TestToken(raw: "def", expiresAt: Date())

        let tokenProvider = TestTokenProvider(accessToken: accessToken, refreshToken: refreshToken)

        let response: Response = .success(Data("Test".utf8))

        let requestAssertions: (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
            XCTAssertEqual($0.allHTTPHeaderFields?["Authorization"], "Bearer abc")
        }

        let client = NetworkClient(
            baseURL: URL(string: "https://test.somewhere.com")!,
            transport: TokenAuth(
                base: TestTransport(responses: [response], assertRequest: requestAssertions),
                tokenProvider: tokenProvider
            )
        )
        
        let exp = expectation(description: "Result")
        
        sink = client.load(TestRequest())
            .sink (receiveCompletion: { _ in
                exp.fulfill()
            }, receiveValue: { value in
                XCTAssertEqual(value, "Test")
            })
        
        wait(for: [exp], timeout: 2)

        XCTAssertEqual(client.baseURL.absoluteString, "https://test.somewhere.com")
    }
}
#endif

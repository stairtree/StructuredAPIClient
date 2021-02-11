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

final class NetworkClientTests: XCTestCase {

    func testNetworkClient() throws {

        struct TestRequest: NetworkRequest {
            func makeRequest(baseURL: URL) throws -> URLRequest {
                return URLRequest(url: baseURL)
            }

            func parseResponse(_ data: Data) throws -> String {
                return String(decoding: data, as: UTF8.self)
            }
        }

        let response: Response = .success(Data("Test".utf8))

        let requestAssertions: (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
        }

        let client = NetworkClient(baseURL: URL(string: "https://test.somewhere.com")!, transport: TestTransport(responses: [response], assertRequest: requestAssertions))


        client.load(TestRequest()) { result in
            do {
                let response = try result.get()
                XCTAssertEqual(response, "Test")
            } catch {
                XCTFail("\(error)")
            }
        }

        XCTAssertEqual(client.baseURL.absoluteString, "https://test.somewhere.com")
    }

    func testTokenAuth() {
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

        let client = NetworkClient(baseURL: URL(string: "https://test.somewhere.com")!, transport:
            TokenAuth(
                base: TestTransport(responses: [response], assertRequest: requestAssertions),
                tokenProvider: tokenProvider
            )
        )

        client.load(TestRequest()) { result in
            do {
                let response = try result.get()
                XCTAssertEqual(response, "Test")
            } catch {
                XCTFail("\(error)")
            }
        }

        XCTAssertEqual(client.baseURL.absoluteString, "https://test.somewhere.com")
    }
    
    func testStackingHeaders() {
        struct TestRequest: NetworkRequest {
            func makeRequest(baseURL: URL) throws -> URLRequest {
                return URLRequest(url: baseURL)
            }

            func parseResponse(_ data: Data) throws -> String {
                return String(decoding: data, as: UTF8.self)
            }
        }

        let response: Response = .success(Data("Test".utf8))

        let requestAssertions: (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
            XCTAssertEqual($0.allHTTPHeaderFields?["H1"], "1")
            XCTAssertEqual($0.allHTTPHeaderFields?["H2"], "2")
        }

        let base = TestTransport(responses: [response], assertRequest: requestAssertions)
        let h1 = AddHeaders(base: base, headers: ["H1": "1"])
        let h2 = AddHeaders(base: h1, headers: ["H2": "2"])
        
        let client = NetworkClient(baseURL: URL(string: "https://test.somewhere.com")!, transport: h2)

        client.load(TestRequest()) { result in
            do {
                let response = try result.get()
                XCTAssertEqual(response, "Test")
            } catch {
                XCTFail("\(error)")
            }
        }

        XCTAssertEqual(client.baseURL.absoluteString, "https://test.somewhere.com")
    }
}

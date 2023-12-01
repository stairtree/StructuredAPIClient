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

final class LockedResult<R: Sendable>: @unchecked Sendable {
    let lock = NSLock()
    var result: Result<R, any Error>?
    
    var value: Result<R, any Error>? {
        get { self.lock.withLock { self.result } }
        set { self.lock.withLock { self.result = newValue } }
    }
}

final class NetworkClientTests: XCTestCase {
    private static let baseTestURL = URL(string: "https://test.somewhere.com")!
    
    private func _runTest<R: NetworkRequest>(
        request: R, client: NetworkClient,
        file: StaticString = #filePath, line: UInt = #line
    ) throws -> Result<R.ResponseDataType, any Error> {
        let expectation = XCTestExpectation(description: "network client completion expectation")
        let rawResult = LockedResult<R.ResponseDataType>()
        
        XCTAssertEqual(client.baseURL, Self.baseTestURL)
        client.load(request) { actualResult in
            rawResult.value = actualResult
            expectation.fulfill()
        }
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: 5.0), XCTWaiter.Result.completed,
            "Test network request timeout", file: file, line: line
        )
        return try XCTUnwrap(rawResult.value, "No result after network request completed", file: file, line: line)
    }
    
    private func runTest<R>(
        request: R, client: NetworkClient, expecting expectedResponse: R.ResponseDataType,
        file: StaticString = #filePath, line: UInt = #line
    ) throws where R: NetworkRequest, R.ResponseDataType: Equatable {
        switch try self._runTest(request: request, client: client) {
            case .success(let response):
                XCTAssertEqual(response, expectedResponse, file: file, line: line)
            case let result:
                XCTFail("Expected success response \(expectedResponse), but got \(result)", file: file, line: line)
        }
    }

    private func runTest<R, E>(
        request: R, client: NetworkClient, expecting expectedError: E,
        file: StaticString = #filePath, line: UInt = #line
    ) throws where R: NetworkRequest, E: Error, E: Equatable {
        switch try self._runTest(request: request, client: client) {
            case .failure(let rawError):
                let error = try XCTUnwrap(rawError as? E, "Unexpected error \(rawError)", file: file, line: line)
                XCTAssertEqual(error, expectedError, file: file, line: line)
            case let result:
                XCTFail("Expected failure response \(expectedError), but got \(result)", file: file, line: line)
        }
    }

    func testNetworkClient() throws {
        let response: Result<TransportResponse, any Error> = .success(.init(status: .ok, headers: [:], body: Data("Test".utf8)))
        let requestAssertions: @Sendable (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
        }
        let client = NetworkClient(baseURL: Self.baseTestURL, transport: TestTransport(responses: [response], assertRequest: requestAssertions))
        
        try self.runTest(request: TestRequest(), client: client, expecting: "Test")
    }

    func testTokenAuth() throws {
        let accessToken = TestToken(raw: "abc", expiresAt: Date())
        let refreshToken = TestToken(raw: "def", expiresAt: Date())
        let tokenProvider = TestTokenProvider(accessToken: accessToken, refreshToken: refreshToken)
        let response: Result<TransportResponse, any Error> = .success(.init(status: .ok, headers: [:], body: Data("Test".utf8)))
        let requestAssertions: @Sendable (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
            XCTAssertEqual($0.allHTTPHeaderFields?["Authorization"], "Bearer abc")
        }
        let client = NetworkClient(baseURL: Self.baseTestURL, transport:
            TokenAuthenticationHandler(
                base: TestTransport(responses: [response], assertRequest: requestAssertions),
                tokenProvider: tokenProvider
            )
        )
        
        try self.runTest(request: TestRequest(), client: client, expecting: "Test")
    }
    
    func testStackingHeaders() throws {
        let response: Result<TransportResponse, any Error> = .success(.init(status: .ok, headers: [:], body: Data("Test".utf8)))
        let requestAssertions: @Sendable (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
            XCTAssertEqual($0.allHTTPHeaderFields?["H1"], "1")
            XCTAssertEqual($0.allHTTPHeaderFields?["H2"], "2")
        }
        let base = TestTransport(responses: [response], assertRequest: requestAssertions)
        let h1 = AddHTTPHeadersHandler(base: base, headers: ["H1": "1"])
        let h2 = AddHTTPHeadersHandler(base: h1, headers: ["H2": "2"])
        let client = NetworkClient(baseURL: Self.baseTestURL, transport: h2)
        
        try self.runTest(request: TestRequest(), client: client, expecting: "Test")
    }
    
    func testConflictingHeaderDefaultMode() throws {
        let response: Result<TransportResponse, any Error> = .success(.init(status: .ok, headers: [:], body: Data("Test".utf8)))
        let requestAssertions: @Sendable (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
            XCTAssertEqual($0.allHTTPHeaderFields?["H1"], "1-3")
            XCTAssertEqual($0.allHTTPHeaderFields?["H2"], "2")
        }
        let base = TestTransport(responses: [response], assertRequest: requestAssertions)
        let h1_1 = AddHTTPHeadersHandler(base: base, headers: ["H1": "1-1"])
        let h1_2 = AddHTTPHeadersHandler(base: h1_1, headers: ["H1": "1-2"])
        let h2 = AddHTTPHeadersHandler(base: h1_2, headers: ["H2": "2"])
        let client = NetworkClient(baseURL: Self.baseTestURL, transport: h2)
        
        try self.runTest(request: TestRequest(extraHeaders: ["H1": "1-3"]), client: client, expecting: "Test")
    }

    func testConflictingHeaderAddMode() throws {
        let response: Result<TransportResponse, any Error> = .success(.init(status: .ok, headers: [:], body: Data("Test".utf8)))
        let requestAssertions: @Sendable (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
            XCTAssertEqual($0.allHTTPHeaderFields?["H1"], "1-3")
            XCTAssertEqual($0.allHTTPHeaderFields?["H2"], "2")
        }
        let base = TestTransport(responses: [response], assertRequest: requestAssertions)
        let h1_1 = AddHTTPHeadersHandler(base: base, headers: ["H1": "1-1"], mode: .add)
        let h1_2 = AddHTTPHeadersHandler(base: h1_1, headers: ["H1": "1-2"], mode: .add)
        let h2 = AddHTTPHeadersHandler(base: h1_2, headers: ["H2": "2"], mode: .add)
        let client = NetworkClient(baseURL: Self.baseTestURL, transport: h2)
        
        try self.runTest(request: TestRequest(extraHeaders: ["H1": "1-3"]), client: client, expecting: "Test")
    }

    func testConflictingHeaderAppendMode() throws {
        let response: Result<TransportResponse, any Error> = .success(.init(status: .ok, headers: [:], body: Data("Test".utf8)))
        let requestAssertions: @Sendable (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
            XCTAssertEqual($0.allHTTPHeaderFields?["H1"], "1-3,1-2,1-1")
            XCTAssertEqual($0.allHTTPHeaderFields?["H2"], "2")
        }
        let base = TestTransport(responses: [response], assertRequest: requestAssertions)
        let h1_1 = AddHTTPHeadersHandler(base: base, headers: ["H1": "1-1"], mode: .append)
        let h1_2 = AddHTTPHeadersHandler(base: h1_1, headers: ["H1": "1-2"], mode: .append)
        let h2 = AddHTTPHeadersHandler(base: h1_2, headers: ["H2": "2"], mode: .append)
        let client = NetworkClient(baseURL: Self.baseTestURL, transport: h2)
        
        try self.runTest(request: TestRequest(extraHeaders: ["H1": "1-3"]), client: client, expecting: "Test")
    }

    func testConflictingHeaderReplaceMode() throws {
        let response: Result<TransportResponse, any Error> = .success(.init(status: .ok, headers: [:], body: Data("Test".utf8)))
        let requestAssertions: @Sendable (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
            XCTAssertEqual($0.allHTTPHeaderFields?["H1"], "1-1")
            XCTAssertEqual($0.allHTTPHeaderFields?["H2"], "2")
        }
        let base = TestTransport(responses: [response], assertRequest: requestAssertions)
        let h1_1 = AddHTTPHeadersHandler(base: base, headers: ["H1": "1-1"], mode: .replace)
        let h1_2 = AddHTTPHeadersHandler(base: h1_1, headers: ["H1": "1-2"], mode: .replace)
        let h2 = AddHTTPHeadersHandler(base: h1_2, headers: ["H2": "2"], mode: .replace)
        let client = NetworkClient(baseURL: Self.baseTestURL, transport: h2)
        
        try self.runTest(request: TestRequest(extraHeaders: ["H1": "1-3"]), client: client, expecting: "Test")
    }
}

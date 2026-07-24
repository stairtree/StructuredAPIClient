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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
public import StructuredAPIClient
import HTTPTypes

private final class TestTransportData: @unchecked Sendable {
    let lock = NIOLock()
    var history: [TransportRequest]
    var responses: [Result<TransportResponse, any Error>]
    
    init(history: [TransportRequest], responses: [Result<TransportResponse, any Error>]) {
        self.history = history
        self.responses = responses
    }
    
    func withLock<R>(_ closure: @escaping @Sendable (inout [TransportRequest], inout [Result<TransportResponse, any Error>]) throws -> R) rethrows -> R {
        try self.lock.withLock {
            try closure(&self.history, &self.responses)
        }
    }
}

/// A ``Transport`` that synchronously returns static values for tests
public final class TestTransport: Transport {
    private let data: TestTransportData
    let assertRequest: @Sendable (TransportRequest) -> Void

    public init(responses: [Result<TransportResponse, any Error>], assertRequest: @escaping @Sendable (TransportRequest) -> Void = { _ in }) {
        self.data = .init(history: [], responses: responses)
        self.assertRequest = assertRequest
    }

    public func send(request: TransportRequest, completion: @escaping @Sendable (Result<TransportResponse, any Error>) -> Void) {
        self.assertRequest(request)
        self.data.withLock { history, responses in
            history.append(request)
            if !responses.isEmpty {
                completion(responses.removeFirst())
            } else {
                completion(.failure(APIError(status: .tooManyRequests, body: Data())))
            }
        }
    }
    
    public var next: (any Transport)? { nil }
}

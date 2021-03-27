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

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import StructuredAPIClient

// A `Transport` that synchronously returns static values for tests
public final class TestTransport: Transport {
    var history: [URLRequest] = []
    var responses: [Result<TransportResponse, Error>]
    var assertRequest: (URLRequest) -> Void

    public init(responses: [Result<TransportResponse, Error>], assertRequest: @escaping (URLRequest) -> Void = { _ in }) {
        self.responses = responses
        self.assertRequest = assertRequest
    }

    public func send(request: URLRequest, completion: @escaping (Result<TransportResponse, Error>) -> Void) {
        assertRequest(request)
        history.append(request)
        if !responses.isEmpty {
            completion(responses.removeFirst())
        } else {
            completion(.failure(APIError(status: .tooManyRequests, body: Data())))
        }
    }
    
    public var next: Transport? { nil }
}

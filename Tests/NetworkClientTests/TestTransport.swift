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

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import NetworkClient

// A `Transport` that synchronously returns static values for tests
final class TestTransport: Transport {
    var history: [URLRequest] = []
    var responseData: [Data]
    var assertRequest: (URLRequest) -> Void

    init(responseData: [Data], assertRequest: @escaping (URLRequest) -> Void = { _ in }) {
        self.responseData = responseData
        self.assertRequest = assertRequest
    }

    func send(request: URLRequest, completion: @escaping (Response) -> Void) {
        assertRequest(request)
        history.append(request)
        if !responseData.isEmpty {
            completion(.success(responseData.removeFirst()))
        } else {
            completion(.failure(status: .tooManyRequests, body: Data()))
        }
    }
}

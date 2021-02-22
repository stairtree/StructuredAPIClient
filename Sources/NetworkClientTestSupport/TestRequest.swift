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

public struct TestRequest: NetworkRequest {
    private let extraHeaders: [String: String]
    
    public init(extraHeaders: [String: String] = [:]) {
        self.extraHeaders = extraHeaders
    }
    
    public func makeRequest(baseURL: URL) throws -> URLRequest {
        var request = URLRequest(url: baseURL)
        extraHeaders.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        return request
    }

    public func parseResponse(_ data: Data) throws -> String {
        return String(decoding: data, as: UTF8.self)
    }
}

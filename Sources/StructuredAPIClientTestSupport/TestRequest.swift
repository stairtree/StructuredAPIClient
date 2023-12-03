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

/// A ``NetworkRequest`` that simply requests the base URL (optionally with additional headers added)
/// and expects UTF-8 `String`s as responses.
public struct TestRequest: NetworkRequest {
    private let extraHeaders: [String: String]
    
    public init(extraHeaders: [String: String] = [:]) {
        self.extraHeaders = extraHeaders
    }
    
    public func parseResponse(_ response: TransportResponse) throws -> String {
        String(decoding: response.body, as: UTF8.self)
    }
    
    public func makeRequest(baseURL: URL) throws -> URLRequest {
        var request = URLRequest(url: baseURL)
        extraHeaders.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        return request
    }
}

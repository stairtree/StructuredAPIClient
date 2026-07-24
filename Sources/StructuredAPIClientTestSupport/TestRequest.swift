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
public import FoundationEssentials
#else
public import Foundation
#endif
public import StructuredAPIClient
import HTTPTypes

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
    
    public func makeRequest(baseURL: URL) throws -> TransportRequest {
        var request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: nil)
        for (name, value) in extraHeaders {
            guard let name = HTTPField.Name(name) else { continue }
            request.headerFields[name] = value
        }
        return .init(url: baseURL, head: request)
    }
}

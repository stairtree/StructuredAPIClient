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

/// Any request that can be sent as a `URLRequest` with a `NetworkClient`, and returns a response.
public protocol NetworkRequest {
    /// The decoded data type that represents the response.
    associatedtype ResponseDataType
    
    /// Returns a request based on the given base URL.
    /// - Parameter baseURL: The `NetworkClient`'s base URL.
    func makeRequest(baseURL: URL) throws -> URLRequest
    
    /// Processes a response returned from the transport and either returns the associated response type or throws an
    /// application-specific error.
    ///
    /// - Parameters:
    ///   - response: A `TransportResponse` containing the response to a request.
    func parseResponse(_ response: TransportResponse) throws -> ResponseDataType
}

/// A convenient error type to use for handling non-2xx HTTP status codes.
public struct APIError: Error {
    public let status: HTTPStatusCode
    public let body: Data
    
    public init(status: HTTPStatusCode, body: Data) {
        self.status = status
        self.body = body
    }
}

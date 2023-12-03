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
import HTTPTypes

/// A successful response from a ``Transport``.
public struct TransportResponse: Sendable {
    /// The received HTTP status code.
    public let status: HTTPResponse.Status
    
    /// Any received HTTP headers, if the transport in use provides them.
    public let headers: HTTPFields
    
    /// The raw HTTP response body. If there was no response body, this will have a zero length.
    public let body: Data
    
    /// Create a new ``TransportResponse``. Intended for use by ``Transport`` implementations.
    public init(status: HTTPResponse.Status, headers: HTTPFields, body: Data) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}

/// A ``Transport`` asynchronously maps a `URLRequest` to a ``TransportResponse``.
public protocol Transport: Sendable {
    /// Sends the request and delivers the response asynchronously to a completion handler.
    ///
    /// Transports should make an effort to provide the most specific errors possible for failures.
    /// In particular, the ``TransportFailure`` enumeration is intended to encapsulate some of the
    /// most common failure modes.
    ///
    /// - Parameters:
    ///   - request: The request to be sent.
    ///   - completion: The completion handler that is called after the response is received.
    ///   - response: The received response from the server, or an error indicating a transport-level failure.
    func send(request: URLRequest, completion: @escaping @Sendable (_ result: Result<TransportResponse, any Error>) -> Void)
    
    /// The next ``Transport`` that the request is being forwarded to.
    ///
    /// If `nil`, this ``Transport`` is the end of the chain.
    var next: (any Transport)? { get }
    
    /// Cancel the request.
    ///
    /// - Note: Any ``Tranport`` forwarding the request must call `cancel()` on the next ``Transport``.
    func cancel()
}

extension Transport {
    /// If there is no special handling of cancellation, the default implementation just forwards to
    /// the next ``Transport``.
    ///
    /// - Note: Implementations which override this method must ensure that they forward the
    ///   cancellation to the next ``Transport`` in the chain, if any.
    public func cancel() { self.next?.cancel() }
}

extension Transport {
    /// Sends the request asynchronously and returns the response.
    ///
    /// Transports should make an effort to provide the most specific errors possible for failures.
    /// In particular, the ``TransportFailure`` enumeration is intended to encapsulate some of the
    /// most common failure modes.
    ///
    /// - Parameters:
    ///   - request: The request to be sent.
    /// - Returns: The received response from the server.
    /// - Throws: An error indicating a transport-level failure.
    public func send(request: URLRequest) async throws -> TransportResponse {
        try await withCheckedThrowingContinuation { continuation in
            self.send(request: request, completion: {
                continuation.resume(with: $0)
            })
        }
    }
}

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
public import HTTPTypes

/// An HTTP request prepared by a ``NetworkRequest`` for a ``Transport``.
///
/// This is intentionally separate from Foundation's `URLRequest`. Transports convert it to the
/// request type required by their underlying HTTP implementation.
public struct TransportRequest: Sendable {
    /// The destination URL for the request.
    public let url: URL

    /// The HTTP request head.
    public var head: HTTPRequest

    /// The optional request body.
    public var body: Data?

    /// An optional transport-specific timeout in seconds.
    public var timeoutInterval: TimeInterval?

    public init(
        url: URL,
        head: HTTPRequest,
        body: Data? = nil,
        timeoutInterval: TimeInterval? = nil
    ) {
        self.url = url
        self.head = head
        self.body = body
        self.timeoutInterval = timeoutInterval
    }
}

/// A successful response from a ``Transport``.
public struct TransportResponse: Sendable {
    /// The received HTTP response head.
    public let head: HTTPResponse
    
    /// The raw HTTP response body. If there was no response body, this will have a zero length.
    public let body: Data
    
    /// Create a new ``TransportResponse``. Intended for use by ``Transport`` implementations.
    public init(head: HTTPResponse, body: Data) {
        self.head = head
        self.body = body
    }

    /// The received HTTP status code.
    public var status: HTTPResponse.Status { self.head.status }

    /// Any received HTTP headers, if the transport in use provides them.
    public var headers: HTTPFields { self.head.headerFields }

    /// Creates a response from individual HTTP response values.
    public init(status: HTTPResponse.Status, headers: HTTPFields, body: Data) {
        self.init(head: .init(status: status, headerFields: headers), body: body)
    }
}

/// A ``Transport`` asynchronously maps a ``TransportRequest`` to a ``TransportResponse``.
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
    func send(request: TransportRequest, completion: @escaping @Sendable (_ result: Result<TransportResponse, any Error>) -> Void)
    
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
    public func send(request: TransportRequest) async throws -> TransportResponse {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.send(request: request, completion: {
                    continuation.resume(with: $0)
                })
            }
        } onCancel: {
            // Propagate structured-concurrency cancellation down to the transport chain.
            self.cancel()
        }
    }
}

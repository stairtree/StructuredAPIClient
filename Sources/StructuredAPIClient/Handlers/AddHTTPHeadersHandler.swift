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

import HTTPTypes

/// Add headers to all requests made by an existing ``Transport``.
public final class AddHTTPHeadersHandler: Transport {
    
    /// An enumeration of the possible modes for working with headers.
    public enum Mode: CaseIterable, Sendable, Hashable {
        /// Accumulating behavior - if a given header is already specified by a request, the transport's
        /// value is appended to the existing header value.
        ///
        /// - Warning: This is rarely what you want.
        case append
        
        /// Overwriting behavior - if a given header is already specified by a request, the transport's
        /// value for the header replaces it. In this
        /// mode, a request's header value is always overwritten.
        case replace
        
        /// Polyfill behavior - if a given header is already specified by a request, it is left untouched,
        /// and the transport's value is ignored.
        ///
        /// This behavior is the default.
        case add
    }
    
    /// The base ``Transport`` to extend with extra headers.
    ///
    /// - Note: Never `nil` in practice for this transport.
    public let next: (any Transport)?
    
    /// Additional headers that will be applied to the request upon sending.
    private let headers: [String: String]

    /// The mode used to add additional headers. Defaults to ``Mode/add``.
    private let mode: Mode
    
    /// Create a ``Transport`` that adds headers to the given base ``Transport``
    /// - Parameters:
    ///   - base: The base ``Transport`` that will have the headers applied
    ///   - headers: Headers to apply to the base ``Transport``
    ///   - mode: The mode to use for resolving conflicts between a request's headers and the
    ///     transport's headers.
    public init(base: any Transport, headers: [String: String], mode: Mode = .add) {
        self.next = base
        self.headers = headers
        self.mode = mode
    }

    // See `Transport.send(request:completion:)`
    public func send(request: TransportRequest, completion: @escaping @Sendable (Result<TransportResponse, any Error>) -> Void) {
        guard !self.headers.isEmpty else {
            return self.next?.send(request: request, completion: completion) ?? ()
        }

        var newRequest = request

        for (key, value) in self.headers {
            guard let name = HTTPField.Name(key) else { continue }
            switch self.mode {
                case .replace:
                    newRequest.head.headerFields[name] = value
                case .add:
                    guard newRequest.head.headerFields[name] == nil else { break }
                    fallthrough
                case .append:
                    if let existing = newRequest.head.headerFields[name] {
                        newRequest.head.headerFields[name] = "\(existing), \(value)"
                    } else {
                        newRequest.head.headerFields[name] = value
                    }
            }
        }
        self.next!.send(request: newRequest, completion: completion)
    }
}

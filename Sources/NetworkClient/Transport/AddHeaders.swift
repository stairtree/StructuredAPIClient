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

/// Add headers to an existing `Transport`.
public final class AddHeaders: Transport {
    
    /// An enumeration of the possible modes for working with headers.
    public enum Mode: CaseIterable {
        /// Accumulating behavior - if a given header is already specified by a request, the transport's value is
        /// appended, as per `URLRequest.addValue(_:forHTTPHeaderField:)`.
        ///
        /// - Note: This is rarely what you want, but it was the default behavior before this mechanism was added, and
        ///   thus remains the default.
        case append
        
        /// Overwriting behavior - if a given header is already specified by a request, the transport's value for the
        /// header replaces it, as per `URLRequest.setValue(_:forHTTPHeaderField:)`. In this mode, a request's header
        /// value is always overwritten.
        case replace
        
        /// Polyfill behavior - if a given header is already specified by a request, it is left untouched, and the
        /// transport's value is ignored.
        case add
    }
    
    /// The base `Transport` to extend with extra headers
    private let base: Transport
    
    /// Additional headers that will be applied to the request upon sending.
    private let headers: [String: String]

    /// The mode used to add additional headers. Defaults to `.append` for legacy compatibility.
    private let mode: Mode
    
    /// Create a `Transport` that adds headers to the base `Transport`
    /// - Parameters:
    ///   - base: The base `Transport` that will have the headers applied
    ///   - headers: Headers to apply to the base `Transport`
    ///   - mode: The mode to use for resolving conflicts between a request's headers and the transport's headers.
    public init(base: Transport, headers: [String: String], mode: Mode = .append) {
        self.base = base
        self.headers = headers
        self.mode = mode
    }

    public func send(request: URLRequest, completion: @escaping (Response) -> Void) {
        var newRequest = request

        for (key, value) in self.headers {
            switch self.mode {
                case .replace:
                    newRequest.setValue(value, forHTTPHeaderField: key)
                case .add:
                    guard newRequest.value(forHTTPHeaderField: key) == nil else { break }
                    fallthrough
                case .append:
                    newRequest.addValue(value, forHTTPHeaderField: key)
            }
        }
        base.send(request: newRequest, completion: completion)
    }
}

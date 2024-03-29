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

#if !canImport(Darwin)
@preconcurrency
#endif
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum TransportFailure: Error, Equatable {
    case invalidRequest(baseURL: URL, components: URLComponents?)
    case network(URLError)
    case cancelled
    case unknown(any Error)
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case let (.invalidRequest(lurl, lcomp), .invalidRequest(rurl, rcomp)):
                lurl == rurl && lcomp == rcomp
            case let (.network(lerror), .network(rerror)):
                lerror == rerror
            case (.cancelled, .cancelled):
                true
            case let (.unknown(lerror), .unknown(rerror)):
                (lerror as NSError) == (rerror as NSError)
            default:
                false
        }
    }
}

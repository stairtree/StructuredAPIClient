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

public enum TransportFailure: Error, Equatable {
    case invalidRequest(URL)
    case network(String)
    case cancelled
    case unknown(any Error)
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case let (.invalidRequest(lurl), .invalidRequest(rurl)):
                lurl == rurl
            case let (.network(lerror), .network(rerror)):
                lerror == rerror
            case (.cancelled, .cancelled):
                true
            case let (.unknown(lerror), .unknown(rerror)):
                String(describing: lerror) == String(describing: rerror)
            default:
                false
        }
    }
}

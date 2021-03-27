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

#if canImport(Combine)
import Combine

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
extension Transport {
    /// Provide a default implementation of `Transport.publisher(forRequest:)` for "traditional" transports. As per
    /// standard practice, this simply wraps `Transport.send(request:completion:)` with the `Future` published.
    ///
    /// Combine-aware `Transport`s may, if they choose, provide their own implementation of this method.
    public func publisher(forRequest request: URLRequest) -> AnyPublisher<TransportResponse, Error> {
        return Future { self.send(request: request, completion: $0) }.eraseToAnyPublisher()
    }
}

#endif // canImport(Combine)

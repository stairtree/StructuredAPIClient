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
extension URLSessionTransport {
    public func publisher(forRequest request: URLRequest) -> AnyPublisher<TransportResponse, Error> {
        return self.session.dataTaskPublisher(for: request)
            .mapError { netError -> Error in
                if netError.code == .cancelled { return TransportFailure.cancelled }
                else { return TransportFailure.network(netError) }
            }
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse else {
                    throw TransportFailure.network(URLError(.unsupportedURL))
                }
                return response.asTransportResponse(withData: output.data)
            }
            .eraseToAnyPublisher()
    }
}
#endif


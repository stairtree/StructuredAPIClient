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
import Logging
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

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
extension NetworkClient {
    /// Provides a Combine `Publisher` which emits the result of sending a given `NetworkRequest`.
    public func requestPublisher<Request: NetworkRequest>(for req: Request) -> AnyPublisher<Request.ResponseDataType, Error> {
        var start: DispatchTime = .distantFuture
        
        // Jump into the Combine universe by wrapping the URLRequest creation in a Result's publisher.
        return Result {
            try req.makeRequest(baseURL: self.baseURL)
        }.publisher

        // Start the request timing from the point where a subscription is made. See below for why we do this here.
        // Log the URL request.
        .handleEvents(
            receiveSubscription: { _ in start = .now() },
            receiveOutput: { self.logger.trace(Logger.Message(stringLiteral: $0.debugString)) }
        )
        
        // Invoke our Transport's publisher to send the request, but use Deferred to avoid performing the actual send
        // until someting downstream has subscribed to this pipeline.
        .map { urlRequest in
            Deferred {
                return self.transport().publisher(forRequest: urlRequest)
            }

            // Log the time between the request send and the receipt of a response. Must be chained to the Deferred
            // publisher directly instead of the outer pipeline in order to have access to the URLRequest.
            .handleEvents(receiveOutput: { _ in
                self.logger.trace("Request '\(urlRequest.debugString)' took \(String(format: "%.4f", (.now() - start).milliseconds))ms")
            })
        }
        
        // "Flatten" the upstream publisher so we see the transport's result instead of just the publisher.
        .switchToLatest()
        
        // Parse the response returned by the transport as success or API error according to status code.
        .tryMap { response in
            try req.parseResponse(response)
        }
        
        // Type-erase the pipeline.
        .eraseToAnyPublisher()
    }
}

#endif // canImport(Combine)

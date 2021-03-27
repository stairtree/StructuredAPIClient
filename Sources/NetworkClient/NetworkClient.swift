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
import Logging

public final class NetworkClient {
    public let baseURL: URL
    let transport: () -> Transport
    let logger: Logger

    /// Create a new `NetworkClient` from a base URL, a `Transport`, and an optional `Logger`.
    public init(baseURL: URL, transport: @escaping @autoclosure () -> Transport = URLSessionTransport(.shared), logger: Logger? = nil) {
        self.baseURL = baseURL
        self.transport = transport
        self.logger = logger ?? Logger(label: "NetworkClient")
    }

    /// Fetch any `NetworkRequest` type and return the response asynchronously.
    public func load<Request: NetworkRequest>(_ req: Request, completion: @escaping (Result<Request.ResponseDataType, Error>) -> Void) {
        let start = DispatchTime.now()
        // Construct the URLRequest
        do {
            let urlRequest =  try req.makeRequest(baseURL: baseURL)
            logger.trace(Logger.Message(stringLiteral: urlRequest.debugString))

            // Send it to the transport
            transport().send(request: urlRequest) { result in
                // TODO: Deliver a more accurate split of the different phases of the request
                defer { self.logger.trace("Request '\(urlRequest.debugString)' took \(String(format: "%.4f", (.now() - start).milliseconds))ms") }
                
                completion(result.flatMap { resp in .init { try req.parseResponse(resp) } })
            }
        } catch {
            return completion(.failure(error))
        }
    }
}

internal extension DispatchTime {
    static func -(lhs: Self, rhs: Self) -> Self {
        return .init(uptimeNanoseconds: lhs.uptimeNanoseconds - rhs.uptimeNanoseconds)
    }
    
    var milliseconds: Double {
        return Double(self.uptimeNanoseconds) / 1_000_000
    }
}

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
@preconcurrency import FoundationNetworking
#endif
import Logging

public final class NetworkClient {
    public let baseURL: URL
    let transport: () -> any Transport
    let logger: Logger

    /// Create a new `NetworkClient` from a base URL, a `Transport`, and an optional `Logger`.
    public init(baseURL: URL, transport: @escaping @Sendable @autoclosure () -> any Transport = URLSessionTransport(.shared), logger: Logger? = nil) {
        self.baseURL = baseURL
        self.transport = transport
        self.logger = logger ?? Logger(label: "NetworkClient")
    }

    /// Fetch any ``NetworkRequest`` type and return the response asynchronously.
    public func load<Request: NetworkRequest>(_ req: Request, completion: @escaping @Sendable (Result<Request.ResponseDataType, any Error>) -> Void) {
        let start = Date()
        // Construct the URLRequest
        do {
            let logger = self.logger
            let urlRequest = try req.makeRequest(baseURL: self.baseURL)

            // Send it to the transport
            self.transport().send(request: urlRequest) { result in
                let middle = Date()
                logger.trace("Request '\(urlRequest.debugString)' received response in \(start.millisecondsBeforeNowFormatted)ms")
                defer {
                    logger.trace("Request '\(urlRequest.debugString)' was processed in \(middle.millisecondsBeforeNowFormatted)ms")
                    logger.trace("Request '\(urlRequest.debugString)' took a total of \(start.millisecondsBeforeNowFormatted)ms")
                }
                
                completion(result.flatMap { resp in .init { try req.parseResponse(resp) } })
            }
        } catch {
            return completion(.failure(error))
        }
    }
}

extension NetworkClient {
    /// Fetch any ``NetworkRequest`` type asynchronously and return the response.
    public func load<Request: NetworkRequest>(_ req: Request) async throws -> Request.ResponseDataType {
        try await withCheckedThrowingContinuation { continuation in
            self.load(req) {
                continuation.resume(with: $0)
            }
        }
    }
}

private extension Date {
    var millisecondsBeforeNowFormatted: String {
        #if canImport(Darwin)
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
            return (self.timeIntervalSinceNow * -1000.0).formatted(.number.precision(.fractionLength(4...4)).grouping(.never))
        }
        #endif
        
        // This is both easier and much faster than using NumberFormatter
        let msInterval = (self.timeIntervalSinceNow * -10_000_000.0).rounded(.toNearestOrEven) / 10_000.0
        return "\(Int(msInterval))\("\(msInterval)0000".drop(while: { $0 != "." }).prefix(5))"
    }
}

internal extension URLRequest {
    var debugString: String {
        "\(self.httpMethod.map { "[\($0)] " } ?? "")\(url.map { "\($0)" } ?? "")"
    }
}

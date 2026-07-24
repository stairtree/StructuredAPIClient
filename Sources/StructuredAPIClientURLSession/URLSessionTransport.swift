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
import FoundationEssentials
#endif
#if canImport(FoundationNetworking)
@preconcurrency public import FoundationNetworking
#elseif canImport(Foundation)
public import Foundation
#endif
public import StructuredAPIClient
import HTTPTypes
import HTTPTypesFoundation

public final class URLSessionTransport: Transport {
    /// The actual `URLSession` instance used to create request tasks.
    public let session: URLSession

    // See `Transport.next`.
    public var next: (any Transport)? { nil }

    public init(_ session: URLSession) {
        self.session = .init(configuration: session.configuration, delegate: session.delegate, delegateQueue: session.delegateQueue)
    }

    /// Sends the request using a `URLSessionDataTask`
    /// - Parameters:
    ///   - request: The configured request to send
    ///   - completion: The completion handler that is called after the response is received.
    ///   - response: The received response from the server.
    public func send(request: TransportRequest, completion: @escaping @Sendable (Result<TransportResponse, any Error>) -> Void) {
        guard let urlRequest = Self.makeRequest(from: request) else {
            completion(.failure(TransportFailure.invalidRequest(request.url)))
            return
        }
        self.session.dataTask(with: urlRequest) { data, response, error in
            if let error {
                // A cancelled `URLSessionTask` reports `URLError.cancelled` (`NSURLErrorCancelled`),
                // *not* a Swift `CancellationError`, so both must be checked to reliably map
                // cancellation onto `TransportFailure.cancelled`. `URLError` is available on Darwin
                // and on glibc-based Linux (swift-foundation's `FoundationNetworking`), but not in
                // the slimmed-down Foundation of the static musl SDK, so the check is gated to those
                // platforms; elsewhere a plain `CancellationError` check suffices.
                let failure: TransportFailure
                #if canImport(Darwin) || canImport(Glibc)
                if error is CancellationError || (error as? URLError)?.code == .cancelled {
                    failure = .cancelled
                } else {
                    failure = .unknown(error)
                }
                #else
                failure = error is CancellationError ? .cancelled : .unknown(error)
                #endif
                return completion(.failure(failure))
            }

            guard let response else {
                return completion(.failure(TransportFailure.network("URLSession returned no response")))
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(TransportFailure.network("URLSession returned a non-HTTP response")))
            }

            guard let transportResponse = httpResponse.asTransportResponse(withData: data) else {
                return completion(.failure(TransportFailure.network("URLSession returned an invalid HTTP response")))
            }
            completion(.success(transportResponse))
        }.resume()
    }

    public func cancel() {
        self.session.getAllTasks {
            $0.forEach { $0.cancel() }
        }
    }

    private static func makeRequest(from request: TransportRequest) -> URLRequest? {
        var head = request.head
        head.url = request.url
        guard var result = URLRequest(httpRequest: head) else { return nil }
        result.httpBody = request.body
        if let timeoutInterval = request.timeoutInterval {
            result.timeoutInterval = timeoutInterval
        }
        return result
    }
}

extension HTTPURLResponse {
    func asTransportResponse(withData data: Data?) -> TransportResponse? {
        self.httpResponse.map { .init(head: $0, body: data ?? .init()) }
    }
}

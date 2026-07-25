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
                // A cancelled `URLSessionTask` surfaces as `NSURLErrorCancelled` (domain
                // `NSURLErrorDomain`, code -999), not a Swift `CancellationError`. Inspect the
                // bridged domain/code through the `Error` protocol so this compiles and behaves
                // consistently across Darwin, glibc-Linux, and the slim musl Foundation — which
                // disagree on whether `URLError`/`NSError` is importable here.
                let failure: TransportFailure
                if error is CancellationError || (error._domain == "NSURLErrorDomain" && error._code == -999) {
                    failure = .cancelled
                } else {
                    failure = .unknown(error)
                }
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

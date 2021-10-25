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

public final class URLSessionTransport: Transport {
    /// The actual `URLSession` instance used to create request tasks.
    public let session: URLSession
    
    /// See `Transport.next`.
    public var next: Transport? { nil }
    
    /// An in-progress data task representing a request in flight
    private var task: URLSessionDataTask!
    
    public init(_ session: URLSession) {
        self.session = session
    }
    
    /// Sends the request using a `URLSessionDataTask`
    /// - Parameters:
    ///   - request: The configured request to send
    ///   - completion: The completion handler that is called after the response is received.
    ///   - response: The received response from the server.
    public func send(request: URLRequest, completion: @escaping (Result<TransportResponse, Error>) -> Void) {
        self.task = session.dataTask(with: request) { (data, response, error) in
            switch error.map({ $0 as? URLError }) {
                case .some(.some(let netError)) where netError.code == .cancelled: return completion(.failure(TransportFailure.cancelled))
                case .some(.some(let netError)): return completion(.failure(TransportFailure.network(netError)))
                case .some(.none): return completion(.failure(TransportFailure.unknown(error!)))
                case .none: break // no error
            }
            guard let response = response else {
                return completion(.failure(TransportFailure.network(URLError(.unknown))))
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(TransportFailure.network(URLError(.unsupportedURL))))
            }
            
            completion(.success(httpResponse.asTransportResponse(withData: data)))
        }
        self.task.resume()
    }
    
    public func cancel() {
        self.task.cancel()
        self.task = nil
    }
}

extension URLRequest {
    var debugString: String {
        "\(httpMethod.map { "[\($0)] " } ?? "")\(url.map { "\($0) " } ?? "")"
    }
}

extension HTTPURLResponse {
    func asTransportResponse(withData data: Data?) -> TransportResponse {
        return TransportResponse(
            status: HTTPStatusCode(rawValue: self.statusCode) ?? .internalServerError,
            headers: .init(uniqueKeysWithValues: self.allHeaderFields.compactMap { k, v in
                guard let name = k.base as? String, let value = v as? String else { return nil }
                return (name, value)
            }),
            body: data ?? .init()
        )
    }
}

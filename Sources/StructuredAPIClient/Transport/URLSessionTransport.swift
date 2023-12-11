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
import HTTPTypes
import AsyncHelpers

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
    public func send(request: URLRequest, completion: @escaping @Sendable (Result<TransportResponse, any Error>) -> Void) {
        self.session.dataTask(with: request) { data, response, error in
            if let error {
                return completion(.failure((error as? URLError)?.asTransportFailure ?? .unknown(error)))
            }
            
            guard let response else {
                return completion(.failure(TransportFailure.network(URLError(.unknown))))
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(TransportFailure.network(URLError(.unsupportedURL))))
            }
            
            completion(.success(httpResponse.asTransportResponse(withData: data)))
        }.resume()
    }
    
    public func cancel() {
        self.session.getAllTasks {
            $0.forEach { $0.cancel() }
        }
    }
}

extension URLError {
    var asTransportFailure: TransportFailure {
        switch self.code {
        case .cancelled: .cancelled
        default: .network(self)
        }
    }
}

extension HTTPURLResponse {
    func asTransportResponse(withData data: Data?) -> TransportResponse {
        TransportResponse(
            status: HTTPResponse.Status(code: self.statusCode),
            headers: HTTPFields(self.allHeaderFields.compactMap { k, v in
                guard let name = (k.base as? String).flatMap(HTTPField.Name.init(_:)), let value = v as? String else { return nil }
                
                return HTTPField(name: name, value: value)
            }),
            body: data ?? .init()
        )
    }
}

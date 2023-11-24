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
import HTTPTypes

public final class URLSessionTransport: Transport {
    /// The actual `URLSession` instance used to create request tasks.
    public let session: URLSession
    
    /// See `Transport.next`.
    public var next: Transport? { nil }
    
    private final class LockedURLSessionDataTask: @unchecked Sendable {
        let lock = NSLock()
        var task: URLSessionDataTask?
        
        var value: URLSessionDataTask? {
            get { self.lock.withLock { self.task } }
            set { self.lock.withLock { self.task = newValue } }
        }
    }
    
    /// An in-progress data task representing a request in flight
    private let task = LockedURLSessionDataTask()
    
    public init(_ session: URLSession) {
        self.session = session
    }
    
    /// Sends the request using a `URLSessionDataTask`
    /// - Parameters:
    ///   - request: The configured request to send
    ///   - completion: The completion handler that is called after the response is received.
    ///   - response: The received response from the server.
    public func send(request: URLRequest, completion: @escaping @Sendable (Result<TransportResponse, Error>) -> Void) {
        self.task.value = session.dataTask(with: request) { (data, response, error) in
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
        }
        self.task.value?.resume()
    }
    
    public func cancel() {
        self.task.value?.cancel()
        self.task.value = nil
    }
}

extension URLError {
    var asTransportFailure: TransportFailure {
        switch self.code {
        case .cancelled:  .cancelled
        default:         .network(self)
        }
    }
}

extension URLRequest {
    var debugString: String {
        "\(httpMethod.map { "[\($0)] " } ?? "")\(url.map { "\($0) " } ?? "")"
    }
}

extension HTTPURLResponse {
    func asTransportResponse(withData data: Data?) -> TransportResponse {
        TransportResponse(
            status: HTTPResponse.Status(code: self.statusCode),
            headers: HTTPFields(self.allHeaderFields.compactMap { k, v in
                guard let name = (k.base as? String).flatMap(HTTPField.Name.init(_:)),
                      let value = v as? String
                else { return nil }
                
                return HTTPField(name: name, value: value)
            }),
            body: data ?? .init()
        )
    }
}

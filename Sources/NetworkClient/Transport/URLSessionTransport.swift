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

public final class URLSessionTransport: Transport {
    
    public let session: URLSession
    
    public var next: Transport? { nil }
    
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
        task = session.dataTask(with: request) { (data, response, error) in
            switch error.map({ $0 as? URLError }) {
                case .some(.some(let netError)) where netError.code == .cancelled: return completion(.failure(TransportFailure.cancelled))
                case .some(.some(let netError)): return completion(.failure(TransportFailure.network(netError)))
                case .some(.none): return completion(.failure(TransportFailure.unknown(error!)))
                default: break // no error
            }
            guard let response = response! as? HTTPURLResponse else {
                return completion(.failure(TransportFailure.network(URLError(.unsupportedURL))))
            }
            
            completion(.success(response.asTransportResponse(withData: data)))
        }
        task.resume()
    }
    
    public func cancel() {
        task.cancel()
    }
}

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

extension URLRequest {
    var debugString: String {
        "\(httpMethod.map { "[\($0)] " } ?? "")\(url.map { "\($0) " } ?? "")"
    }
}

extension HTTPURLResponse {
    // TODO: Mapping unknown status codes to either 200 or 500 is kinda cruddy, do something better.
    func asTransportResponse(withData data: Data?) -> TransportResponse {
        return TransportResponse(
            status: (HTTPStatusCode(rawValue: self.statusCode) ?? ((200..<300).contains(self.statusCode) ? .ok : .internalServerError)),
            headers: .init(uniqueKeysWithValues: self.allHeaderFields.compactMap { k, v in
                guard let name = k.base as? String else { return nil }
                guard let value = v as? String else { return nil }
                return (name, value)
            }),
            body: data ?? .init()
        )
    }
}

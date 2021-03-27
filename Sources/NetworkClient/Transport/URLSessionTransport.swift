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
    
    private var task: URLSessionDataTask!
    
    public init(_ session: URLSession) {
        self.session = session
    }
    
    /// Sends the request using a `URLSessionDataTask`
    /// - Parameters:
    ///   - request: The configured request to send
    ///   - completion: The completion handler that is called after the response is received.
    ///   - response: The received response from the server.
    public func send(request: URLRequest, completion: @escaping (Response) -> Void) {
        task = session.dataTask(with: request) { (data, response, error) in
            switch error.map({ $0 as? URLError }) {
                case .some(.some(let netError)) where netError.code == .cancelled: return completion(.error(.cancelled))
                case .some(.some(let netError)): return completion(.error(.network(netError)))
                case .some(.none): return completion(.error(.unknown(error!)))
                default: break // no error
            }
            guard let response = response! as? HTTPURLResponse else {
                return completion(.error(.network(URLError(.unsupportedURL))))
            }
            
            guard 200..<300 ~= response.statusCode else {
                if let data = data, let status = APIError.Status(code: response.statusCode) {
                    return completion(.failure(status: status, body: data))
                } else {
                    return completion(.error(.network(.init(.cannotParseResponse))))
                }
            }
            
            return completion(.success(data ?? Data()))
        }
        task.resume()
    }
    
    public var next: Transport? { nil }
    
    public func cancel() {
        task.cancel()
    }
}

extension URLRequest {
    var debugString: String {
        "\(httpMethod.map { "[\($0)] " } ?? "")\(url.map { "\($0) " } ?? "")"
    }
}
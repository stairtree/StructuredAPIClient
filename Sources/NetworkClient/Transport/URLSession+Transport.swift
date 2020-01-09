// Copyright © 2020 Stairtree GmbH. All rights reserved.

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession: Transport {
    
    /// Sends the request using a `URLSessionDataTask`
    /// - Parameters:
    ///   - request: The configured request to send
    ///   - completion: The completion handler that is called after the response is received.
    ///   - response: The received response from the server.
    public func send(request: URLRequest, completion: @escaping (Response) -> Void)
    {
        let task = self.dataTask(with: request) { (data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                if
                    let error = error as NSError?,
                    error.code == NSURLErrorCannotConnectToHost ||
                    error.code == NSURLErrorTimedOut
                {
                    return completion(.error(APIError.serverUnreachable))
                } else {
                    return completion(.error(APIError.invalidResponse))
                }
            }

            if let error = error {
                switch (error as NSError).code {
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorInternationalRoamingOff,
                     NSURLErrorSecureConnectionFailed,
                     NSURLErrorNetworkConnectionLost,
                     NSURLErrorCancelled:
                    return completion(.error(APIError.network))
                default:
                    return completion(.error(error))
                }
            }

            switch response.statusCode {
            case 400: return completion(.error(APIError.badRequest))
            case 401: return completion(.error(APIError.unauthorized))
            case 403: return completion(.error(APIError.forbidden))
            case 404: return completion(.error(APIError.notFound))
            case 405: return completion(.error(APIError.methodNotAllowed))
            default: break
            }

            guard 200..<300 ~= response.statusCode else {
                if let data = data {
                    return completion(.failure(data))
                } else {
                    return completion(.error(APIError.invalidResponse))
                }
            }
            
            return completion(.success(data ?? Data()))
        }
        task.resume()
    }
}

extension URLRequest {
    var debugString: String {
        "\(httpMethod.map { "[\($0)] " } ?? "")\(url.map { "\($0) " } ?? "")"
    }
}

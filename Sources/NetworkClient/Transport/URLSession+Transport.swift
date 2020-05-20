// Copyright © Stairtree GmbH. All rights reserved.

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
                    return completion(.error(.serverUnreachable(errorCode: error.code)))
                } else {
                    return completion(.error(.invalidResponse(.nonHTTPResponse)))
                }
            }

            if let error = error {
                switch (error as NSError).code {
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorInternationalRoamingOff,
                     NSURLErrorSecureConnectionFailed,
                     NSURLErrorNetworkConnectionLost,
                     NSURLErrorCancelled:
                    return completion(.error(.network(errorCode: (error as NSError).code)))
                default:
                    return completion(.error(.unknown(error)))
                }
            }

            guard 200..<300 ~= response.statusCode else {
                if let data = data, let status = APIError.Status(code: response.statusCode) {
                    return completion(.failure(status: status, body: data))
                } else {
                    return completion(.error(.invalidResponse(.invalidStatusCode(response.statusCode, response))))
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

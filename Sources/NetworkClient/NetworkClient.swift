// Copyright © 2019 Stairtree GmbH. All rights reserved.

import Foundation

// A transport maps a URLRequest to Data, asynchronously
public protocol Transport {
    func send(request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void)
}

public protocol NetworkRequest {
    associatedtype ResponseDataType

    func makeRequest(baseURL: URL) throws -> URLRequest
    func parseResponse(_ data: Data) throws -> ResponseDataType
}

extension URLSession: Transport {
    public func send(request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void)
    {
        let task = self.dataTask(with: request) { (data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                if
                    let error = error as NSError?,
                    error.code == NSURLErrorCannotConnectToHost ||
                    error.code == NSURLErrorTimedOut
                {
                    return completion(.failure(APIError.serverUnrachable))
                } else {
                    return completion(.failure(APIError.invalidResponse))
                }
            }

            if let error = error {
                switch (error as NSError).code {
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorInternationalRoamingOff,
                     NSURLErrorSecureConnectionFailed,
                     NSURLErrorNetworkConnectionLost,
                     NSURLErrorCancelled:
                    return completion(.failure(APIError.network))
                default:
                    return completion(.failure(error))
                }
            }

            switch response.statusCode {
            case 400: return completion(.failure(APIError.badRequest))
            case 401: return completion(.failure(APIError.unauthorized))
            case 403: return completion(.failure(APIError.forbidden))
            case 404: return completion(.failure(APIError.notFound))
            case 405: return completion(.failure(APIError.methodNotAllowed))
            default: break
            }

            guard 200..<300 ~= response.statusCode else {
                return completion(.failure(APIError.invalidResponse))
            }
            
            if let data = data { completion(.success(data)) }

            // We should never reach this point
        }
        task.resume()
    }
}

public final class NetworkClient {
    public let baseURL: URL
    let transport: Transport

    public init(baseURL: URL, transport: Transport = URLSession.shared) {
        self.baseURL = baseURL
        self.transport = transport
    }

    // Fetch any APIRequest type, and return its response asynchronously
    public func load<Request: NetworkRequest>(_ req: Request, completion: @escaping (Result<Request.ResponseDataType, Error>) -> Void) {
        // Construct the URLRequest
        do {
            let urlRequest =  try req.makeRequest(baseURL: baseURL)

            // Send it to the transport
            transport.send(request: urlRequest) { data in
                let result = Result { () -> Request.ResponseDataType in
                    return try req.parseResponse(data.get())
                }
                completion(result)
            }
        } catch {
            return completion(.failure(error))
        }
    }
}

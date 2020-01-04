// Copyright © 2019 Stairtree GmbH. All rights reserved.

import Foundation
import Logging

public enum Response {
    case success(Data)
    case failure(Data)
    case error(Error)
}

// A transport maps a URLRequest to Data, asynchronously
public protocol Transport {
    func send(request: URLRequest, completion: @escaping (Response) -> Void)
}

public protocol NetworkRequest {
    associatedtype ResponseDataType

    func makeRequest(baseURL: URL) throws -> URLRequest
    func parseResponse(_ data: Data) throws -> ResponseDataType
    func parseError(_ data: Data) throws -> Error
}

extension NetworkRequest {
    public func parseError(_ data: Data) throws -> Error {
        return APIError.invalidResponse
    }
}

extension URLSession: Transport {
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

public final class NetworkClient {
    public let baseURL: URL
    let transport: Transport
    let logger: Logger

    public init(baseURL: URL, transport: Transport = URLSession.shared, logger: Logger? = nil) {
        self.baseURL = baseURL
        self.transport = transport
        self.logger = logger ?? Logger(label: "NetworkClient")
    }

    // Fetch any APIRequest type, and return its response asynchronously
    public func load<Request: NetworkRequest>(_ req: Request, completion: @escaping (Result<Request.ResponseDataType, Error>) -> Void) {
        let start = DispatchTime.now()
        // Construct the URLRequest
        do {
            let urlRequest =  try req.makeRequest(baseURL: baseURL)
            logger.trace(Logger.Message(stringLiteral: urlRequest.debugString))

            // Send it to the transport
            transport.send(request: urlRequest) { response in
                // TODO: Deliver a more accurate split of the different phases of the request
                defer { self.logger.trace("Request '\(urlRequest.debugString)' took \(String(format: "%.4f", milliseconds(from: start, to: .now())))ms") }
                
                let result = Result { () throws -> Request.ResponseDataType in
                    switch response {
                    case let .success(data): return try req.parseResponse(data)
                    case let .failure(data): throw try req.parseError(data)
                    case let .error(error): throw error
                    }
                }

                completion(result)
            }
        } catch {
            return completion(.failure(error))
        }
    }
}

extension URLRequest {
    var debugString: String {
        "\(httpMethod.map { "[\($0)] " } ?? "")\(url.map { "\($0) " } ?? "")"
    }
}

func seconds(from: DispatchTime, to: DispatchTime) -> Double {
    let nanoTime = from.uptimeNanoseconds - to.uptimeNanoseconds
    return Double(nanoTime) / 1_000_000_000
}

func milliseconds(from: DispatchTime, to: DispatchTime) -> Double {
    let nanoTime = from.uptimeNanoseconds - to.uptimeNanoseconds
    return Double(nanoTime) / 1_000_000
}

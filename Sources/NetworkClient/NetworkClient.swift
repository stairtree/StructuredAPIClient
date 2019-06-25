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
        let task = self.dataTask(with: request) { (data, _, error) in
            if let error = error { completion(.failure(error)) }
            else if let data = data { completion(.success(data)) }
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

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
import Logging


/// A `Transport`'s response
public enum Response {
    /// Indicates a successful request
    case success(Data)
    /// A successful request but the response indicates an application-specific error with non-`2xx` HTTP response code.
    case failure(status: APIError.Status, body: Data)
    /// An unsuccessful request
    case error(APIError.TransportFailure)
}

/// A `Transport` maps a URLRequest to Data, asynchronously.
public protocol Transport {
    
    /// Sends the request and delivers the response asynchronously.
    /// - Parameters:
    ///   - request: The request to be sent.
    ///   - completion: The completion handler that is called after the response is received.
    ///   - response: The received response from the server.
    func send(request: URLRequest, completion: @escaping (_ response: Response) -> Void)
    
    /// The next Transport that the request is being forwarded to.
    ///
    /// If `nil`, this should be the final `Transport`
    var next: Transport? { get }
    
    /// Cancel the request
    ///
    /// - Note: Any `Tranport` forwarding the request must call `cancel()` on the next `Transport`
    func cancel()
}

extension Transport {
    
    /// If there is no special handling of cancellation, the default implementation just forwards to the next `Transport`.
    ///
    /// - Note: You must call `cancel()` on the next `Transport` if you customize this method.
    public func cancel() { next?.cancel() }
}

/// Any request that can be sent as a `URLRequest` with a `NetworkClient`, and returns a response.
public protocol NetworkRequest {
    /// The decoded data type that represents the response.
    associatedtype ResponseDataType
    
    /// Returns a request based on the given base URL.
    /// - Parameter baseURL: The `NetworkClient`'s base URL.
    func makeRequest(baseURL: URL) throws -> URLRequest
    
    /// Handles the returned data from the response and returns the associated data type
    /// - Parameter data: The data received in the response
    func parseResponse(_ data: Data) throws -> ResponseDataType
    
    /// Handles an application specific error that is received in a successful request with a response code outside `200..<300`.
    /// - Parameters
    ///   - data: The data received in the response.
    ///   - status: The HTTP status for the response.
    func parseError(_ data: Data, for status: APIError.Status) throws -> Error
}

extension NetworkRequest {
    
    /// Default implementation that returns an `APIError.api`.
    /// - Parameter data: The data received in the response.
    public func parseError(_ data: Data, for status: APIError.Status) throws -> Error {
        return APIError.api(status: status, body: data)
    }
}

public final class NetworkClient {
    public let baseURL: URL
    let transport: () -> Transport
    let logger: Logger

    public init(baseURL: URL, transport: @escaping @autoclosure () -> Transport = URLSessionTransport(.shared), logger: Logger? = nil) {
        self.baseURL = baseURL
        self.transport = transport
        self.logger = logger ?? Logger(label: "NetworkClient")
    }

    // Fetch any `NetworkRequest` type, and return its response asynchronously
    public func load<Request: NetworkRequest>(_ req: Request, completion: @escaping (Result<Request.ResponseDataType, Error>) -> Void) {
        let start = DispatchTime.now()
        // Construct the URLRequest
        do {
            let urlRequest =  try req.makeRequest(baseURL: baseURL)
            logger.trace(Logger.Message(stringLiteral: urlRequest.debugString))

            // Send it to the transport
            transport().send(request: urlRequest) { response in
                // TODO: Deliver a more accurate split of the different phases of the request
                defer { self.logger.trace("Request '\(urlRequest.debugString)' took \(String(format: "%.4f", milliseconds(from: start, to: .now())))ms") }
                
                let result = Result { () throws -> Request.ResponseDataType in
                    switch response {
                    case let .success(data): return try req.parseResponse(data)
                    case let .failure(status, data): throw try req.parseError(data, for: status)
                    case let .error(error): throw APIError.transport(error)
                    }
                }

                completion(result)
            }
        } catch {
            return completion(.failure(error))
        }
    }
}

func seconds(from: DispatchTime, to: DispatchTime) -> Double {
    let nanoTime = to.uptimeNanoseconds - from.uptimeNanoseconds
    return Double(nanoTime) / 1_000_000_000
}

func milliseconds(from: DispatchTime, to: DispatchTime) -> Double {
    let nanoTime = to.uptimeNanoseconds - from.uptimeNanoseconds
    return Double(nanoTime) / 1_000_000
}

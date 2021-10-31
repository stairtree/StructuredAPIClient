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

#if compiler(>=5.5) && canImport(_Concurrency) && canImport(Darwin)

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension URLSessionTransport {
    
    /// Sends the request using a `URLSessionDataTask`
    /// - Parameter request: The configured request to send.
    /// - Returns: The received response from the server.
    public func send(request: URLRequest) async throws -> TransportResponse {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TransportFailure.network(URLError(.unsupportedURL))
            }
            return httpResponse.asTransportResponse(withData: data)
            
        } catch let netError as URLError {
            if netError.code == .cancelled { throw TransportFailure.cancelled }
            throw TransportFailure.network(netError)
            
        } catch let error as TransportFailure {
            throw error
            
        } catch {
            throw TransportFailure.unknown(error)
        }
    }
}

#endif

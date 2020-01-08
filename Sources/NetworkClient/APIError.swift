// Copyright © 2020 Stairtree GmbH. All rights reserved.

import Foundation


/// Errors emitted by the `NetworkClient`
public enum APIError: Error {
    case badRequest
    case unauthorized
    case forbidden
    case invalidResponse
    case notFound
    case methodNotAllowed
    case invalidData
    case parsingError
    case network
    case serverUnreachable
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        return "\(self)"
    }
}

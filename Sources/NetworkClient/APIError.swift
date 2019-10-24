// Copyright © 2019 Stairtree GmbH. All rights reserved.

import Foundation


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
    case serverUnrachable
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        return "\(self)"
    }
}

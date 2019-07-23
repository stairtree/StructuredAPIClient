// Copyright © 2019 Stairtree GmbH. All rights reserved.

import Foundation


public enum APIError: Error {
    case notFound
    case unauthorized
    case forbidden
    case invalidResponse
    case methodNotAllowed
    case invalidData
    case parsingError
    case network
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        return "\(self)"
    }
}

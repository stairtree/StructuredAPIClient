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
import StructuredAPIClient


/// A `TokenProvider` that returns a given accessToken and refreshToken for the respective requests.
public final class TestTokenProvider: TokenProvider, Sendable {
    let accessToken: any Token
    let refreshToken: any Token

    public init(accessToken: any Token, refreshToken: any Token) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    public func fetchToken(completion: (Result<(any Token, any Token), any Error>) -> Void) {
        completion(.success((accessToken, refreshToken)))
    }

    public func refreshToken(withRefreshToken: any Token, completion: (Result<any Token, any Error>) -> Void) {
        completion(.success(accessToken))
    }
}

/// A sample `Token` that contains the raw String and an expiry date.
public struct TestToken: Token {
    public let raw: String
    public let expiresAt: Date?
    public init(raw: String, expiresAt: Date?) {
        self.raw = raw
        self.expiresAt = expiresAt
    }
}

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
import NetworkClient


/// A `TokenProvider` that returns a given accessToken and refreshToken for the respective requests.
final class TestTokenProvider: TokenProvider {
    let accessToken: Token
    let refreshToken: Token

    init(accessToken: Token, refreshToken: Token) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func fetchToken(completion: (Result<(Token, Token), Error>) -> Void) {
        completion(.success((accessToken, refreshToken)))
    }

    func refreshToken(withRefreshToken: Token, completion: (Result<Token, Error>) -> Void) {
        completion(.success(accessToken))
    }
}

/// A sample `Token` that contains the raw String and an expiry date.
struct TestToken: Token {
    let raw: String
    let expiresAt: Date?
    public init(raw: String, expiresAt: Date?) {
        self.raw = raw
        self.expiresAt = expiresAt
    }
}

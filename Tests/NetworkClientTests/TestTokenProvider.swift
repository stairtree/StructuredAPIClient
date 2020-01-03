// Copyright © 2020 Stairtree GmbH. All rights reserved.

import Foundation
import NetworkClient

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

struct TestToken: Token {
    let base64: String
    let expiresAt: Date?
    public init(base64: String, expiresAt: Date?) {
        self.base64 = base64
        self.expiresAt = expiresAt
    }
}

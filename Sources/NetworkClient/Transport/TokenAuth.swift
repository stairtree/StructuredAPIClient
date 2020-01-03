// Copyright © 2020 Stairtree GmbH. All rights reserved.

import Foundation

// Handle token auth and add headers to an existing transport
public final class TokenAuth: Transport {
    private let base: Transport
    var auth: AuthState

    public init(base: Transport, tokenProvider: TokenProvider) {
        self.base = base
        self.auth = AuthState(provider: tokenProvider)
    }

    public func send(request: URLRequest, completion: @escaping (Response) -> Void) {
        self.auth.token { result in
            switch result {
            case let .failure(error): completion(.error(error))
            case let .success(token):
                let headers = ["Authorization": "Bearer \(token)"]
                return AddHeaders(base: self.base, headers: headers).send(request: request, completion: completion)
            }
        }
    }
}

public protocol TokenProvider {
    // get access token and refresh token
    func fetchToken(completion: (Result<(Token, Token), Error>) -> Void)

    // refreh the current token
    func refreshToken(withRefreshToken: Token, completion: (Result<Token, Error>) -> Void)
}

public protocol Token {
    var base64: String { get }
    var expiresAt: Date? { get }
}


struct AuthState {
    var accessToken: Token? = nil
    var refreshToken: Token? = nil

    var provider: TokenProvider

    mutating func token(_ completion: (Result<String, Error>) -> Void) {
        if let access = self.accessToken, (access.expiresAt ?? Date()) < Date() {
            return completion(.success(access.base64))
        } else if let refresh = self.refreshToken, (refresh.expiresAt ?? Date()) < Date() {
            self.provider.refreshToken(withRefreshToken: refresh, completion: { result in
                switch result {
                case let .failure(error): return completion(.failure(error))
                case let .success(access):
                    self.accessToken = access
                    return completion(.success(access.base64))
                }
            })
        } else {
            self.provider.fetchToken(completion: { result in
                switch result {
                case let .failure(error): return completion(.failure(error))
                case let .success(access, refresh):
                    self.accessToken = access
                    self.refreshToken = refresh
                    return completion(.success(access.base64))
                }
            })
        }
    }
}

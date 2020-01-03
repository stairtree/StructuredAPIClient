// Copyright © 2020 Stairtree GmbH. All rights reserved.

import Foundation
import Logging

// Handle token auth and add headers to an existing transport
public final class TokenAuth: Transport {
    private let base: Transport
    private let logger: Logger

    let auth: AuthState

    public init(base: Transport, tokenProvider: TokenProvider, logger: Logger = Logger(label: "TokenAuth")) {
        self.base = base
        self.logger = logger
        self.auth = AuthState(provider: tokenProvider, logger: logger)
    }

    public func send(request: URLRequest, completion: @escaping (Response) -> Void) {
        self.auth.token { result in
            switch result {
            case let .failure(error):
                completion(.error(error))
            case let .success(token):
                self.logger.trace("Bearer Token: \(token)")
                let headers = ["Authorization": "Bearer \(token)"]
                let transport = AddHeaders(base: self.base, headers: headers)
                transport.send(request: request, completion: completion)
            }
        }
    }
}

public protocol TokenProvider {
    // Get access token and refresh token
    func fetchToken(completion: @escaping (Result<(Token, Token), Error>) -> Void)

    // Refreh the current token
    func refreshToken(withRefreshToken refreshToken: Token, completion: @escaping (Result<Token, Error>) -> Void)
}

public protocol Token {
    var raw: String { get }
    var expiresAt: Date? { get }
}

final class AuthState {
    var accessToken: Token? = nil
    var refreshToken: Token? = nil

    let provider: TokenProvider
    let logger: Logger

    internal init(provider: TokenProvider, logger: Logger) {
        self.provider = provider
        self.logger = logger
    }

    func token(_ completion: @escaping (Result<String, Error>) -> Void) {
        if let access = self.accessToken, (access.expiresAt ?? Date()) < Date() {
            logger.trace("Valid access token present")
            return completion(.success(access.raw))
        } else if let refresh = self.refreshToken, (refresh.expiresAt ?? Date()) < Date() {
            logger.trace("Refreshing token using \(refresh.raw)")
            self.provider.refreshToken(withRefreshToken: refresh, completion: { result in
                switch result {
                case let .failure(error):
                    return completion(.failure(error))
                case let .success(access):
                    self.accessToken = access
                    return completion(.success(access.raw))
                }
            })
        } else {
            logger.trace("Fetching initial tokens")
            self.provider.fetchToken(completion: { result in
                switch result {
                case let .failure(error):
                    return completion(.failure(error))
                case let .success(access, refresh):
                    self.accessToken = access
                    self.refreshToken = refresh
                    return completion(.success(access.raw))
                }
            })
        }
    }
}

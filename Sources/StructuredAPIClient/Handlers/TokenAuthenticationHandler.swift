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
@preconcurrency import FoundationNetworking
#endif
import Logging

// Handle token auth and add appropriate auth headers to an existing transport.
public final class TokenAuthenticationHandler: Transport {
    public let next: (any Transport)?
    private let logger: Logger
    private let auth: AuthState

    public init(base: any Transport, accessToken: (any Token)? = nil, refreshToken: (any Token)? = nil, tokenProvider: any TokenProvider, logger: Logger? = nil) {
        self.next = base
        self.logger = logger ?? Logger(label: "TokenAuth")
        self.auth = AuthState(accessToken: accessToken, refreshToken: refreshToken, provider: tokenProvider, logger: logger)
    }

    public func send(request: URLRequest, completion: @escaping @Sendable (Result<TransportResponse, any Error>) -> Void) {
        self.auth.token { result in
            switch result {
            case let .failure(error):
                completion(.failure(TransportFailure.unknown(error)))
            case let .success(token):
                let headers = ["Authorization": "Bearer \(token)"]
                let transport = AddHTTPHeadersHandler(base: self.next!, headers: headers)
                
                transport.send(request: request, completion: completion)
            }
        }
    }
}

public protocol TokenProvider {
    // Get access token and refresh token
    func fetchToken(completion: @escaping @Sendable (Result<(any Token, any Token), any Error>) -> Void)

    // Refreh the current token
    func refreshToken(withRefreshToken refreshToken: any Token, completion: @escaping @Sendable (Result<any Token, any Error>) -> Void)
}

public protocol Token: Sendable {
    var raw: String { get }
    var expiresAt: Date? { get }
}

final class AuthState: @unchecked Sendable {
    private final class LockedTokens: @unchecked Sendable {
        private let lock = NSLock()
        private var accessToken: (any Token)?
        private var refreshToken: (any Token)?
        
        init(accessToken: (any Token)?, refreshToken: (any Token)?) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
        }
        
        func withLock<R>(_ closure: @escaping @Sendable (inout (any Token)?, inout (any Token)?) throws -> R) rethrows -> R {
            try self.lock.withLock {
                try closure(&self.accessToken, &self.refreshToken)
            }
        }
    }
    
    private let tokens: LockedTokens
    let provider: any TokenProvider
    let logger: Logger

    internal init(accessToken: (any Token)? = nil, refreshToken: (any Token)? = nil, provider: any TokenProvider, logger: Logger? = nil) {
        self.tokens = .init(accessToken: accessToken, refreshToken: refreshToken)
        self.provider = provider
        self.logger = logger ?? Logger(label: "AuthState")
    }

    func token(_ completion: @escaping @Sendable (Result<String, any Error>) -> Void) {
        if let raw = self.tokens.withLock({ token, _ in token.flatMap { ($0.expiresAt ?? Date.distantFuture) > Date() ? $0.raw : nil } }) {
            return completion(.success(raw))
        } else if let refresh = self.tokens.withLock({ _, token in token.flatMap { ($0.expiresAt ?? Date.distantFuture) > Date() ? $0 : nil } }) {
            logger.trace("Refreshing token")
            self.provider.refreshToken(withRefreshToken: refresh, completion: { result in
                switch result {
                case let .failure(error):
                    return completion(.failure(error))
                case let .success(access):
                    self.tokens.withLock { token, _ in token = access }
                    return completion(.success(access.raw))
                }
            })
        } else {
            logger.trace("Fetching initial tokens")
            self.provider.fetchToken(completion: { result in
                switch result {
                case let .failure(error):
                    return completion(.failure(error))
                case let .success((access, refresh)):
                    self.tokens.withLock { accessToken, refreshToken in
                        accessToken = access
                        refreshToken = refresh
                    }
                    return completion(.success(access.raw))
                }
            })
        }
    }
}

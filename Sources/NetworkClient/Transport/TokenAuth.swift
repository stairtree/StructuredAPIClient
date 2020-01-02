// Copyright © 2020 Stairtree GmbH. All rights reserved.

import Foundation

// Handle token auth and add headers to an existing transport
public class TokenAuth: Transport {
    private let base: Transport

    var accessToken: AccessToken? = nil
    var refreshToken: String? = nil

    let tokenProvider: TokenProvider

    public init(base: Transport, tokenProvider: TokenProvider) {
        self.base = base
        self.tokenProvider = tokenProvider
    }

    public func send(request: URLRequest, completion: @escaping (Response) -> Void)
    {
        // if current token is nil, or expired is close or passed, first fetch new token, then send request with headers
        guard let accessToken = self.accessToken else {
            return tokenProvider.fetchToken(completion: { result in
                let (accessToken, refreshToken) = try! result.get()
                self.accessToken = accessToken
                self.refreshToken = refreshToken
                AddHeaders(base: base, headers: ["Authorization": "Bearer \(accessToken.token)"])
                    .send(request: request, completion: completion)
            })
        }

        // AddHeaders(base: base, headers: ["Authorization": "Bearer \(self.accessToken!.token!)"]))
        base.send(request: request) { response in
            // FIXME: handle token expired here

            // If the response indicates that the token is expired, we first ask the provider for a new one, and then send our request again, calling the completion at the end. we should probably count the number of attempts and abort after 3 failed ones.
            completion(response)
        }
    }
}

// Rough sketch
public protocol TokenProvider {
    // get access token and refresh token
    func fetchToken(completion: (Result<(AccessToken, String), Error>) -> Void)
    // refreh the current token
    func refreshToken(withRefreshToken: String, completion: (Result<AccessToken, Error>) -> Void)
}


public struct AccessToken {
    let token: String
    let expiresAt: Date?
}
extension TokenAuth {

    public func parseAccessToken(_ at: String) throws {

        struct Payload: Codable {
            var exp: Double
            var iat: Double
        }


        if at.split(separator: ".").count == 3 {
            let parts = at.split(separator: ".")
            let s = String(parts[1])
            if let data = Data(base64Encoded: s) {
                let payload = try JSONDecoder().decode(Payload.self, from: data)
                let currentTime = Date().timeIntervalSince1970

                // the difference between currentTime and issuedAt is the time difference between server and us
                let delta = currentTime - payload.iat

//                self.accessToken = at
//                self.accessToken?.expiresAt = Date(timeIntervalSince1970: (payload.exp + delta))
//
//                self.apiClient = NetworkClient(
//                    baseURL: self.serverUrl.appendingPathComponent("sync/\(self.version)/"),
//                    transport: AddHeaders(base: self.transport, headers: ["Authorization": "Bearer \(self.accessToken!)"])
//                )

            }
            else {
                print("no valid base64: ", s)
            }
        }
        else {
            print("No valid JWT: ", at)
        }
    }

    public func accessCheckThenLoad<Request: NetworkRequest>(_ req: Request, completion: @escaping (Result<Request.ResponseDataType, Error>) -> ()) {
        var needRefresh = false

        if self.accessToken == nil {
            needRefresh = true
        }
        else {
//            let renewPointInTime = (self.accessTokenExpiresAt?.timeIntervalSince1970 ?? 0) - 60 // substract a minute to be safe
//
//            if (renewPointInTime - Date().timeIntervalSince1970) < 0 {
//                // now in the timeframe to renew
//                needRefresh = true
//            }
        }

        if needRefresh {
//            self.refreshAccessToken() { res in
//                base.send(request: req, completion: completion)
//            }
        }
        else {
//            base.send(request: req, completion: completion)
        }
    }

}

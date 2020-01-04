// Copyright © 2019 Stairtree GmbH. All rights reserved.

import Foundation

// Add headers to an existing transport
public final class AddHeaders: Transport {
    private let base: Transport
    var headers: [String: String]

    public init(base: Transport, headers: [String: String]) {
        self.base = base
        self.headers = headers
    }

    public func send(request: URLRequest, completion: @escaping (Response) -> Void) {
        var newRequest = request
        for (key, value) in headers { newRequest.addValue(value, forHTTPHeaderField: key) }
        base.send(request: newRequest, completion: completion)
    }
}

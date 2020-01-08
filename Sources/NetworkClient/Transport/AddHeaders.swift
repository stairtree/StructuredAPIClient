// Copyright © 2020 Stairtree GmbH. All rights reserved.

import Foundation


/// Add headers to an existing `Transport`.
public final class AddHeaders: Transport {
    
    /// The base `Transport` to extend with extra headers
    private let base: Transport
    
    /// Additional headers that will be applied to the request upon sending.
    private let headers: [String: String]

    
    /// Create a `Transport` that adds headers to the base `Transport`
    /// - Parameters:
    ///   - base: The base `Transport` that will have the headers applied
    ///   - headers: Headers to apply to the base `Transport`
    ///
    /// - Note: Existing headers with the same keys will be overwritten

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

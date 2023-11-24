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
import Logging

#if !os(macOS) && canImport(UIKit)
import UIKit

public final class BackgroundExtendingHandler: Transport {
    
    /// The base `Transport` to extend.
    public let next: Transport?
    
    /// A debug name for the background task. It will be suffixed with the request's url.
    private let name: String?
    
    /// Called synchronously on the main thread shortly before the app is suspended.
    private let expirationHandler: (@Sendable () -> Void)?
    
    private final class LockedStartedFlag: @unchecked Sendable {
        private let lock = NSLock()
        private var flag = false
        
        var value: Bool {
            get { self.lock.withLock { self.flag } }
            set { self.lock.withLock { self.flag = newValue } }
        }
    }
    
    private let started = LockedStartedFlag()
    
    public init(base: Transport, name: String?, expirationHandler: (@Sendable () -> Void)?) {
        self.next = base
        self.name = name
        self.expirationHandler = expirationHandler
    }
    
    public func send(request: URLRequest, completion: @escaping @Sendable (Result<TransportResponse, Error>) -> Void) {
        let reason = request.debugString

        ProcessInfo.processInfo.performExpiringActivity(withReason: reason, using: { expired in
            // Being called with `expired` without being `started` means
            // the background assertion was not granted.
            if expired && !self.started.value {
                self.cancel()
                return completion(.failure(TransportFailure.cancelled))
            }
            
            self.started.value = true
            guard !expired else {
                return self.cancel()
            }
            
            self.next!.send(request: request, completion: completion)
        })
    }
}
#endif

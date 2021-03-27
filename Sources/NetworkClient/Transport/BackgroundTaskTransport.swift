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
import Logging

#if !os(macOS) && canImport(UIKit)
import UIKit

public final class BackgroundExtendingTransport: Transport {
    
    /// The base `Transport` to extend.
    public let next: Transport?
    
    /// A debug name for the background task. It will be suffixed with the request's url.
    private let name: String?
    
    /// Called synchronously on the main thread shortly before the app is suspended.
    private let expirationHandler: (() -> Void)?
    
    private var started: Bool = false
    
    public init(base: Transport, name: String?, expirationHandler: (() -> Void)?) {
        self.next = base
        self.name = name
        self.expirationHandler = expirationHandler
    }
    
    public func send(request: URLRequest, completion: @escaping (Result<TransportResponse, Error>) -> Void) {
        if #available(
            iOSApplicationExtension 9,
            tvOSApplicationExtension 9,
            macCatalystApplicationExtension 13,
            watchOS 2,
            iOS 999, tvOS 999, macCatalyst 999, *
        ) {
            let reason = request.debugString

            ProcessInfo().performExpiringActivity(withReason: reason, using: { expired in
                // Being called with `expired` without being `started` means
                // the background assertion was not granted.
                if expired && !self.started {
                    self.cancel()
                    return completion(.failure(TransportFailure.cancelled))
                }
                
                self.started = true
                guard !expired else {
                    return self.cancel()
                }
                
                self.next!.send(request: request, completion: completion)
            })
        } else {
            #if !os(watchOS)
            let reason = "\(name.map { "\($0)-" } ?? "")\(request.debugString)"
            var identifier: UIBackgroundTaskIdentifier!

            identifier = UIApplication.shared.beginBackgroundTask(withName: reason, expirationHandler: { [weak self] in
                self?.expirationHandler?()
                UIApplication.shared.endBackgroundTask(identifier)
            })

            guard identifier != .invalid else {
                self.cancel()
                return completion(.failure(TransportFailure.cancelled))
            }
            
            self.next!.send(request: request) { response in
                completion(response)
                UIApplication.shared.endBackgroundTask(identifier)
            }
            #endif
        }
    }
}
#endif

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

#if compiler(>=5.5) && canImport(_Concurrency) && canImport(Darwin)

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension NetworkClient {
   public func load<Request: NetworkRequest>(_ req: Request) async throws -> Request.ResponseDataType {
        try await withCheckedThrowingContinuation { continuation in
            self.load(req) { switch $0 {
                case .success(let value): continuation.resume(returning: value)
                case .failure(let error): continuation.resume(throwing: error)
            } }
        }
    }
}

#endif

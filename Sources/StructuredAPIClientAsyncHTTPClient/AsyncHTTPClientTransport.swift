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

#if AsyncHTTPClientTransport
public import StructuredAPIClient
public import AsyncHTTPClient
public import NIOCore
import NIOHTTP1
import HTTPTypes
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A ``Transport`` backed by AsyncHTTPClient's shared `HTTPClient`.
public final class AsyncHTTPClientTransport: Transport {
    private let client: HTTPClient
    private let defaultTimeout: TimeAmount
    private let maximumResponseBodySize: Int

    /// Tracks the in-flight request tasks so that ``cancel()`` can stop them.
    private struct State: Sendable {
        var nextID = 0
        var cancellationGeneration = 0
        var tasks: [Int: Task<Void, Never>] = [:]
    }
    private let state = NIOLockedValueBox(State())

    /// The number of in-flight request tasks currently registered. Exposed for tests to verify the
    /// cancellation state machine directly, without depending on network I/O.
    internal var inFlightRequestCount: Int {
        self.state.withLockedValue { $0.tasks.count }
    }

    public var next: (any Transport)? { nil }

    /// Create a transport backed by the shared `HTTPClient`.
    public convenience init() {
        self.init(client: .shared)
    }

    /// Create a transport backed by a specific `HTTPClient`, using default limits.
    ///
    /// - Parameter client: The `HTTPClient` used to execute requests. Pass a custom instance to
    ///   control the `EventLoopGroup`, proxy, or TLS configuration.
    public convenience init(client: HTTPClient) {
        self.init(
            client: client,
            defaultTimeout: .seconds(60),
            maximumResponseBodySize: 16 * 1024 * 1024
        )
    }

    /// Create a transport with full control over the backing client and limits.
    ///
    /// - Parameters:
    ///   - client: The `HTTPClient` used to execute requests.
    ///   - defaultTimeout: The timeout applied to requests that don't specify their own.
    ///   - maximumResponseBodySize: The maximum number of bytes to collect for a response body.
    public init(
        client: HTTPClient,
        defaultTimeout: TimeAmount,
        maximumResponseBodySize: Int
    ) {
        self.client = client
        self.defaultTimeout = defaultTimeout
        self.maximumResponseBodySize = maximumResponseBodySize
    }

    public func send(
        request: TransportRequest,
        completion: @escaping @Sendable (Result<TransportResponse, any Error>) -> Void
    ) {
        let httpRequest: HTTPClientRequest
        do {
            httpRequest = try Self.makeRequest(from: request)
        } catch {
            completion(.failure(error))
            return
        }

        // Capture the current cancellation generation. A cancellation that races this request
        // will advance the generation and cancel this task during registration.
        let (id, cancellationGeneration) = self.state.withLockedValue { state in
            defer { state.nextID += 1 }
            return (state.nextID, state.cancellationGeneration)
        }

        let timeout = request.timeoutInterval.map {
            TimeAmount.nanoseconds(Int64($0 * 1_000_000_000))
        }
            ?? defaultTimeout
        let client = client
        let maximumResponseBodySize = maximumResponseBodySize

        let task = Task {
            defer { self.state.withLockedValue { $0.tasks[id] = nil } }
            do {
                let response = try await client.execute(httpRequest, timeout: timeout)
                let body = try await response.body.collect(upTo: maximumResponseBodySize)
                completion(.success(Self.makeResponse(response, body: body)))
            } catch is CancellationError {
                completion(.failure(TransportFailure.cancelled))
            } catch {
                completion(.failure(TransportFailure.unknown(error)))
            }
        }

        // Register the task, or cancel it immediately if `cancel()` raced ahead of registration.
        // The task's first action is an `await`, so it cannot complete before this runs.
        let cancelImmediately = self.state.withLockedValue { state in
            guard state.cancellationGeneration == cancellationGeneration else { return true }
            state.tasks[id] = task
            return false
        }
        if cancelImmediately {
            task.cancel()
        }
    }

    public func cancel() {
        let tasks = self.state.withLockedValue { state in
            state.cancellationGeneration &+= 1
            defer { state.tasks.removeAll() }
            return Array(state.tasks.values)
        }
        for task in tasks {
            task.cancel()
        }
    }

    static func makeRequest(from request: TransportRequest) throws -> HTTPClientRequest {
        var result = HTTPClientRequest(url: request.url.absoluteString)
        result.method = httpMethod(from: request.head.method)
        for field in request.head.headerFields {
            result.headers.add(name: field.name.rawName, value: field.value)
        }
        if let body = request.body {
            result.body = .bytes(ByteBuffer(bytes: body))
        }
        return result
    }

    static func makeResponse(
        _ response: HTTPClientResponse,
        body: ByteBuffer
    ) -> TransportResponse {
        .init(
            head: .init(
                status: .init(code: Int(response.status.code)),
                headerFields: .init(response.headers.compactMap { name, value in
                    HTTPField.Name(name).map { HTTPField(name: $0, value: value) }
                })
            ),
            body: Data(body.readableBytesView)
        )
    }

    static func httpMethod(from method: HTTPRequest.Method) -> HTTPMethod {
        switch method.rawValue.uppercased() {
        case "GET": .GET
        case "POST": .POST
        case "PUT": .PUT
        case "DELETE": .DELETE
        case "PATCH": .PATCH
        case "HEAD": .HEAD
        case "OPTIONS": .OPTIONS
        case let other: .RAW(value: other)
        }
    }
}
#endif

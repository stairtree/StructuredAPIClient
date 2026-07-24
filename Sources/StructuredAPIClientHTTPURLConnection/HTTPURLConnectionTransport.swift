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

#if HTTPURLConnectionTransport
public import StructuredAPIClient
import SwiftJava
import JavaNet
import HTTPTypes
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A ``Transport`` backed by Java's `java.net.HttpURLConnection`, for use on Android (or any JVM
/// host) via swift-java's `JavaNet` bindings.
public final class HTTPURLConnectionTransport: Transport, @unchecked Sendable {
    private let defaultTimeoutMilliseconds: Int32
    private let maximumResponseBodySize: Int

    public var next: (any Transport)? { nil }

    public init(
        defaultTimeoutMilliseconds: Int32 = 60_000,
        maximumResponseBodySize: Int = 16 * 1024 * 1024
    ) {
        self.defaultTimeoutMilliseconds = defaultTimeoutMilliseconds
        self.maximumResponseBodySize = maximumResponseBodySize
    }

    public func send(
        request: TransportRequest,
        completion: @escaping @Sendable (Result<TransportResponse, any Error>) -> Void
    ) {
        let defaultTimeoutMilliseconds = self.defaultTimeoutMilliseconds
        let maximumResponseBodySize = self.maximumResponseBodySize
        Task {
            do {
                completion(.success(try Self.execute(
                    request: request,
                    defaultTimeoutMilliseconds: defaultTimeoutMilliseconds,
                    maximumResponseBodySize: maximumResponseBodySize
                )))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private static func execute(
        request: TransportRequest,
        defaultTimeoutMilliseconds: Int32,
        maximumResponseBodySize: Int
    ) throws -> TransportResponse {
        guard let javaURL = try URI(request.url.absoluteString).toURL(),
              let urlConnection = try javaURL.openConnection(),
              let connection = urlConnection.as(HttpURLConnection.self)
        else {
            throw HTTPURLConnectionTransportError.invalidURL
        }
        defer { connection.disconnect() }

        let timeoutMilliseconds = request.timeoutInterval.map {
            Int32(clamping: Int($0 * 1_000))
        }
            ?? defaultTimeoutMilliseconds
        connection.setConnectTimeout(timeoutMilliseconds)
        connection.setReadTimeout(timeoutMilliseconds)
        connection.setInstanceFollowRedirects(true)
        try connection.setRequestMethod(request.head.method.rawValue)

        for field in request.head.headerFields {
            connection.setRequestProperty(field.name.rawName, field.value)
        }

        if let body = request.body {
            connection.setDoOutput(true)
            if let outputStream = try connection.getOutputStream() {
                defer { try? outputStream.close() }
                try outputStream.write(body.map { Int8(bitPattern: $0) })
            }
        }

        let statusCode = Int(try connection.getResponseCode())
        return .init(
            // `HttpURLConnection` exposes response headers only positionally (and its swift-java
            // binding returns non-optional strings, so the end of the list can't be detected
            // reliably); response headers are therefore not surfaced by this transport.
            head: .init(status: .init(code: statusCode), headerFields: .init()),
            body: try readBody(
                from: connection,
                statusCode: statusCode,
                maximumResponseBodySize: maximumResponseBodySize
            )
        )
    }

    private static func readBody(
        from connection: HttpURLConnection,
        statusCode: Int,
        maximumResponseBodySize: Int
    ) throws -> Data {
        let inputStream = statusCode >= 400
            ? connection.getErrorStream()
            : try connection.getInputStream()
        guard let inputStream else { return Data() }
        defer { try? inputStream.close() }

        let readLimit = maximumResponseBodySize + 1
        guard readLimit <= Int(Int32.max) else {
            throw HTTPURLConnectionTransportError.responseBodyTooLarge
        }
        let bytes = try inputStream.readNBytes(Int32(readLimit))
        guard bytes.count <= maximumResponseBodySize else {
            throw HTTPURLConnectionTransportError.responseBodyTooLarge
        }
        return Data(bytes.map { UInt8(bitPattern: $0) })
    }
}

private enum HTTPURLConnectionTransportError: Error {
    case invalidURL
    case responseBodyTooLarge
}
#endif

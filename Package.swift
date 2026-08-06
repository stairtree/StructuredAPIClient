// swift-tools-version: 6.3
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

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("AsyncCallerExecution"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
    .enableExperimentalFeature("AnyAppleOSAvailability"),
]

let products: [Product] = [
    .library(name: "StructuredAPIClient", targets: ["StructuredAPIClient"]),
    .library(name: "StructuredAPIClientURLSession", targets: ["StructuredAPIClientURLSession"]),
    .library(name: "StructuredAPIClientAsyncHTTPClient", targets: ["StructuredAPIClientAsyncHTTPClient"]),
    .library(name: "StructuredAPIClientHTTPURLConnection", targets: ["StructuredAPIClientHTTPURLConnection"]),
    .library(name: "StructuredAPIClientTestSupport", targets: ["StructuredAPIClientTestSupport"]),
]

// `async-http-client`/`swift-nio` and `swift-java` are only resolved when their respective traits
// are enabled, because the only targets that reference them gate those references behind the trait.
let dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.0.2"),
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.28.0"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.101.3"),
    .package(url: "https://github.com/swiftlang/swift-java", from: "0.5.0"),
]

let targets: [Target] = [
        .target(
            name: "StructuredAPIClient",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "StructuredAPIClientURLSession",
            dependencies: [
                .target(name: "StructuredAPIClient"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "StructuredAPIClientAsyncHTTPClient",
            dependencies: [
                .target(name: "StructuredAPIClient"),
                .product(name: "AsyncHTTPClient", package: "async-http-client", condition: .when(traits: ["AsyncHTTPClientTransport"])),
                .product(name: "NIOCore", package: "swift-nio", condition: .when(traits: ["AsyncHTTPClientTransport"])),
                .product(name: "NIOHTTP1", package: "swift-nio", condition: .when(traits: ["AsyncHTTPClientTransport"])),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "StructuredAPIClientTestSupport",
            dependencies: [
                .target(name: "StructuredAPIClient"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "StructuredAPIClientTests",
            dependencies: [
                .target(name: "StructuredAPIClient"),
                .target(name: "StructuredAPIClientTestSupport"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "StructuredAPIClientURLSessionTests",
            dependencies: [
                .target(name: "StructuredAPIClient"),
                .target(name: "StructuredAPIClientURLSession"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "StructuredAPIClientAsyncHTTPClientTests",
            dependencies: [
                .target(name: "StructuredAPIClient"),
                .target(name: "StructuredAPIClientAsyncHTTPClient"),
                .product(name: "AsyncHTTPClient", package: "async-http-client", condition: .when(traits: ["AsyncHTTPClientTransport"])),
                .product(name: "NIOCore", package: "swift-nio", condition: .when(traits: ["AsyncHTTPClientTransport"])),
                .product(name: "NIOHTTP1", package: "swift-nio", condition: .when(traits: ["AsyncHTTPClientTransport"])),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "StructuredAPIClientHTTPURLConnection",
            dependencies: [
                .target(name: "StructuredAPIClient"),
                .product(name: "SwiftJava", package: "swift-java", condition: .when(traits: ["HTTPURLConnectionTransport"])),
                .product(name: "JavaNet", package: "swift-java", condition: .when(traits: ["HTTPURLConnectionTransport"])),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)] + swiftSettings
        ),
]

let package = Package(
    name: "StructuredAPIClient",
    platforms: [
        .macOS(.v13),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: products,
    traits: [
        .trait(
            name: "AsyncHTTPClientTransport",
            description: "Enables the AsyncHTTPClient-backed transport and its SwiftNIO dependencies."
        ),
        .trait(
            name: "HTTPURLConnectionTransport",
            description: "Enables the java.net.HttpURLConnection-backed transport (Android) and its swift-java dependency."
        ),
    ],
    dependencies: dependencies,
    targets: targets
)

// swift-tools-version:5.9
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
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency=complete"),
]

let package = Package(
    name: "StructuredAPIClient",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "StructuredAPIClient", targets: ["StructuredAPIClient"]),
        .library(name: "StructuredAPIClientTestSupport", targets: ["StructuredAPIClientTestSupport"]),
    ],
    dependencies: [
        // Swift logging API
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.0.2"),
    ],
    targets: [
        .target(
            name: "StructuredAPIClient",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "StructuredAPIClientTestSupport",
            dependencies: [
                .target(name: "StructuredAPIClient"),
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
    ]
)

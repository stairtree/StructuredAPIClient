// swift-tools-version:5.3
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

import PackageDescription

let package = Package(
    name: "NetworkClient",
    products: [
        .library(name: "NetworkClient", targets: ["NetworkClient"]),
        .library(name: "NetworkClientTestSupport", targets: ["NetworkClientTestSupport"]),
    ],
    dependencies: [
        // Swift logging API
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.4.0")),
    ],
    targets: [
        .target(
            name: "NetworkClient",
            dependencies: [.product(name: "Logging", package: "swift-log")]),
        .target(
            name: "NetworkClientTestSupport",
            dependencies: [.target(name: "NetworkClient")]),
        .testTarget(
            name: "NetworkClientTests",
            dependencies: [
                .target(name: "NetworkClient"),
                .target(name: "NetworkClientTestSupport"),
            ]),
    ]
)

// swift-tools-version:5.3
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

let package = Package(
    name: "StructuredAPIClient",
    products: [
        .library(name: "StructuredAPIClient", targets: ["StructuredAPIClient"]),
        .library(name: "StructuredAPIClientTestSupport", targets: ["StructuredAPIClientTestSupport"]),
    ],
    dependencies: [
        // Swift logging API
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.4.0")),
    ],
    targets: [
        .target(
            name: "StructuredAPIClient",
            dependencies: [.product(name: "Logging", package: "swift-log")]),
        .target(
            name: "StructuredAPIClientTestSupport",
            dependencies: [.target(name: "StructuredAPIClient")]),
        .testTarget(
            name: "StructuredAPIClientTests",
            dependencies: [
                .target(name: "StructuredAPIClient"),
                .target(name: "StructuredAPIClientTestSupport"),
            ]),
    ]
)

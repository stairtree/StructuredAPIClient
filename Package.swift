// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "NetworkClient",
    products: [
        .library(
            name: "NetworkClient",
            targets: ["NetworkClient"]),
    ],
    dependencies: [
        // Swift logging API
        .package(url: "https://github.com/apple/swift-log.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "NetworkClient",
            dependencies: ["Logging"]),
        .testTarget(
            name: "NetworkClientTests",
            dependencies: ["NetworkClient"]),
    ]
)

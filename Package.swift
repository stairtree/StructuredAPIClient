// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "NetworkClient",
    products: [
        .library(name: "NetworkClient", targets: ["NetworkClient"]),
    ],
    dependencies: [
        // Swift logging API
        .package(url: "https://github.com/apple/swift-log.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "NetworkClient",
            dependencies: [.product(name: "Logging", package: "swift-log")]),
        .testTarget(
            name: "NetworkClientTests",
            dependencies: [.target(name: "NetworkClient")]),
    ]
)

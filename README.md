# <div align="center">StructuredAPIClient</div>

<p align="center">

<a href="LICENSE.txt">
<img src="https://img.shields.io/badge/license-MIT-skyblue?style=plastic&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB2aWV3Qm94PSIwIDAgMTI4IDEyOCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBmaWxsPSJza3libHVlIiBkPSJNNzAuNTQsMTEuNWMtLjEtMy44Ny0xMi0zLjg3LTEyLDB2MTBjLTUuMjcuMi0yMC4zNCw3Ljg3LTI0LjQ0LDhoLTE4LjRjLTcuMSwwLTguMywxMy45NSwzLjUsMTIsMCwwLTE0Ljk2LDMzLjItMTYuNywzNy41NC04LjE1LDE4LjQ2LDUzLjkzLDE3LjMsNDUuOC44LTIuNS01LjA3LTE2LjctMzguMzQtMTYuNy0zOC4zNCw1LjcsMCwxOC40LTcuODMsMjcuMTQtOHY3Ni43OGgtMjBjLTMuOSwwLTMuOSwxMiwwLDEyaDUyYzMuOSwwLDMuOS0xMiwwLTEyaC0yMHYtNzYuNzhjOC43LS4xLDIxLjE2LDgsMjcuMzYsOCwwLDAtMTQuNDMsMzIuODYtMTYuNywzOC4zNC03LjEsMTUuOTYsNTMuNTYsMTguMyw0NS44LDAtMi4yLTUuMy0xNi43LTM4LjM0LTE2LjctMzguMzQsMTIuNiwxLjIsMTEuNS0xMiwzLjUtMTIsMCwwLTIyLjgtLjItMTguNCwwLDAsMC0xOS03LjktMjQuNDQtOHptMzIuODYsNDQuNjYsMTAuNCwyNGMtMy45LDEuNzQtMTguNiwxLjItMjAuODQsMHptLTc3LjcsMCwxMC40LDI0Yy04LDMuMy0xNSwyLjktMjAuODQsMCwzLjcyLTcuODcsNi41Ny0xNi4yNSwxMC40NC0yNHoiLz48L3N2Zz4%3D" alt="MIT License">
</a>

<a href="https://github.com/stairtree/StructuredAPIClient/actions/workflows/test.yml">
<img src="https://img.shields.io/github/actions/workflow/status/stairtree/StructuredAPIClient/test.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc" alt="CI">
</a>

<a href="https://codecov.io/gh/stairtree/StructuredAPIClient">
<img src="https://img.shields.io/codecov/c/gh/stairtree/StructuredAPIClient?style=plastic&logo=codecov&label=codecov">
</a>

<a href="https://swift.org">
<img src="https://img.shields.io/badge/swift-5.9%2b-white?style=plastic&logoColor=%23f07158&labelColor=gray&color=%23f07158&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB2aWV3Qm94PSIwIDAgMjQgMjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI%2BPHBhdGggZD0iTTYsMjRjLTMsMC02LTMtNi02di0xMmMwLTMsMy02LDYtNmgxMmMzLDAsNiwzLDYsNnYxMmMwLDMtMyw2LTYsNnoiIGZpbGw9IiNmMDcxNTgiLz48cGF0aCBkPSJNMTMuNiwzLjRjNC4yLDIuNCw2LjMsNy41LDUuMywxMS41LDEuOSwyLjgsMS42LDUuMiwxLjQsNC43LTEuMi0yLjMtMy4zLTEuNC00LjQtLjctMy45LDEuOC0xMC4yLjItMTMuNS01LDMsMi4yLDcuMiwzLjEsMTAuMywxLjItNC42LTMuNi04LjUtOS4yLTguNS05LjMsMi4zLDIuMSw2LDQuOCw3LjMsNS43LTIuOC0zLjEtNS4zLTYuNy01LjItNi43LDIuNywyLjcsNS43LDUuMiw4LjksNy4yLjQtLjgsMS40LTQuNS0xLjYtOC43eiIgZmlsbD0iI2ZmZiIvPjwvc3ZnPg%3D%3D" alt="Swift 5.9">
</a>

</p>

A testable and composable network client.

For more information, browse the API documentation (_coming soon_).

## Supported Platforms

StructuredAPIClient is tested on macOS, iOS, tvOS, watchOS, and Linux, and is known to support the following operating system versions:

* Ubuntu 22.04+ / Amazon Linux 2
* macOS 10.15+
* iOS 13+
* tvOS 13+
* watchOS 6+
* Android (via the `HTTPURLConnectionTransport` trait and a swift-java toolchain)

## Transports

The core `StructuredAPIClient` target is independent of any particular HTTP stack. You choose a
transport implementation from a separate product:

| Product | Backing stack | Notes |
| --- | --- | --- |
| `StructuredAPIClientURLSession` | Foundation `URLSession` | Best on Apple platforms; no extra dependencies. |
| `StructuredAPIClientAsyncHTTPClient` | [AsyncHTTPClient](https://github.com/swift-server/async-http-client) / SwiftNIO | Recommended for Linux servers. Requires the `AsyncHTTPClientTransport` trait. |
| `StructuredAPIClientHTTPURLConnection` | Java `HttpURLConnection` | For Android. Requires the `HTTPURLConnectionTransport` trait and a swift-java toolchain. |

The AsyncHTTPClient and HTTPURLConnection transports pull in heavy dependency trees (SwiftNIO and
swift-java respectively), so they are gated behind **package traits** that are *disabled by default*.
A consumer that only uses `URLSession` (or the core alone) never resolves those dependencies.

## Integration

```swift
dependencies: [
    .package(url: "https://github.com/stairtree/StructuredAPIClient.git", from: "3.0.0"),
]
```

Then depend on the transport product you want. For `URLSession` (no trait needed):

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "StructuredAPIClient", package: "StructuredAPIClient"),
    .product(name: "StructuredAPIClientURLSession", package: "StructuredAPIClient"),
])
```

For AsyncHTTPClient, enable the trait on the package dependency:

```swift
.package(url: "https://github.com/stairtree/StructuredAPIClient.git", from: "3.0.0", traits: ["AsyncHTTPClientTransport"]),
```

## Usage

```swift
import StructuredAPIClient
import StructuredAPIClientURLSession

// Store the transport (and any handler chain) so cached state — such as auth tokens — is reused
// across requests. See the `NetworkClient.init` docs about the `@autoclosure` transport parameter.
let transport = URLSessionTransport(.shared)
let client = NetworkClient(baseURL: URL(string: "https://api.example.com")!, transport: transport)

let result = try await client.load(MyRequest())
```

---

Inspired by blog posts by [Rob Napier](https://robnapier.net) and [Soroush Khanlou](http://khanlou.com), as well as the [Testing Tips & Tricks](https://developer.apple.com/videos/play/wwdc2018/417/) WWDC talk. Version 2.0 revised for full Concurrency support by [@gwynne](https://github.com/gwynne).

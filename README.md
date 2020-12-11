# NetworkClient

<a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
</a>
<a href="https://swift.org">
    <img src="https://img.shields.io/badge/swift-5.2-brightgreen.svg" alt="Swift 5.2">
</a>
<a href="https://github.com/stairtree/NetworkClient/actions">
    <img src="https://github.com/stairtree/NetworkClient/workflows/test/badge.svg" alt="CI">
</a>


A testable and composable network client.

### Supported Platforms

NetworkClient is tested on macOS, iOS, tvOS, Linux, and Windows, and is known to support the following operating system versions:

* Ubuntu 16.04+
* macOS 10.12+
* iOS 12+
* tvOS 12+
* watchOS (untested since watchOS doesn't support `XCTest`)
* Windows 10 (using the latest Swift development snapshot)

To integrate the package:

```swift
dependencies: [
    .package(url: "https://github.com/stairtree/NetworkClient.git", .branch("main"))
]
```

_**Note**: No releases have yet been tagged._

---

Inspired by blog posts by [Rob Napier](https://robnapier.net) and [Soroush Khanlou](http://khanlou.com), as well as the [Testing Tips & Tricks](https://developer.apple.com/videos/play/wwdc2018/417/) WWDC talk. 

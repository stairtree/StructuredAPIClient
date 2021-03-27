# StructuredAPIClient

<a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
</a>
<a href="https://swift.org">
    <img src="https://img.shields.io/badge/swift-5.3-brightgreen.svg" alt="Swift 5.3">
</a>
<a href="https://github.com/stairtree/StructuredAPIClient/actions">
    <img src="https://github.com/stairtree/StructuredAPIClient/workflows/test/badge.svg" alt="CI">
</a>

A testable and composable network client.

### Supported Platforms

StructuredAPIClient is tested on macOS, iOS, tvOS, Linux, and Windows, and is known to support the following operating system versions:

* Ubuntu 16.04+
* AmazonLinux2
* macOS 10.12+
* iOS 12+
* tvOS 12+
* watchOS 5+
* Windows 10 (using the latest Swift development snapshot)

To integrate the package:

```swift
dependencies: [
    .package(url: "https://github.com/stairtree/StructuredAPIClient.git", from: "1.0.0")
]
```

---

Inspired by blog posts by [Rob Napier](https://robnapier.net) and [Soroush Khanlou](http://khanlou.com), as well as the [Testing Tips & Tricks](https://developer.apple.com/videos/play/wwdc2018/417/) WWDC talk. 

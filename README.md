# <div align="center">StructuredAPIClient</div>

<p align="center">

<a href="LICENSE">
<img src="https://img.shields.io/badge/license-MIT-skyblue?style=plastic&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB2aWV3Qm94PSIwIDAgMTI4IDEyOCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBmaWxsPSJza3libHVlIiBkPSJNNzAuNTQsMTEuNWMtLjEtMy44Ny0xMi0zLjg3LTEyLDB2MTBjLTUuMjcuMi0yMC4zNCw3Ljg3LTI0LjQ0LDhoLTE4LjRjLTcuMSwwLTguMywxMy45NSwzLjUsMTIsMCwwLTE0Ljk2LDMzLjItMTYuNywzNy41NC04LjE1LDE4LjQ2LDUzLjkzLDE3LjMsNDUuOC44LTIuNS01LjA3LTE2LjctMzguMzQtMTYuNy0zOC4zNCw1LjcsMCwxOC40LTcuODMsMjcuMTQtOHY3Ni43OGgtMjBjLTMuOSwwLTMuOSwxMiwwLDEyaDUyYzMuOSwwLDMuOS0xMiwwLTEyaC0yMHYtNzYuNzhjOC43LS4xLDIxLjE2LDgsMjcuMzYsOCwwLDAtMTQuNDMsMzIuODYtMTYuNywzOC4zNC03LjEsMTUuOTYsNTMuNTYsMTguMyw0NS44LDAtMi4yLTUuMy0xNi43LTM4LjM0LTE2LjctMzguMzQsMTIuNiwxLjIsMTEuNS0xMiwzLjUtMTIsMCwwLTIyLjgtLjItMTguNCwwLDAsMC0xOS03LjktMjQuNDQtOHptMzIuODYsNDQuNjYsMTAuNCwyNGMtMy45LDEuNzQtMTguNiwxLjItMjAuODQsMHptLTc3LjcsMCwxMC40LDI0Yy04LDMuMy0xNSwyLjktMjAuODQsMCwzLjcyLTcuODcsNi41Ny0xNi4yNSwxMC40NC0yNHoiLz48L3N2Zz4%3D" alt="MIT License">
</a>

<a href="https://github.com/stairtree/StructuredAPIClient/actions/workflows/test.yml">
<img src="https://img.shields.io/github/actions/workflow/status/stairtree/StructuredAPIClient/test.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc" alt="CI">
</a>

<a href="https://codecov.io/gh/stairtree/StructuredAPIClient">
<img src="https://img.shields.io/codecov/c/gh/stairtree/StructuredAPIClient?style=plastic&logo=codecov&label=codecov&token=MD69L97AOO">
</a>

<a href="https://swift.org">
<img src="https://img.shields.io/badge/swift-5.9%2b-white?style=plastic&logoColor=%23f07158&labelColor=gray&color=%23f07158&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB2aWV3Qm94PSIwIDAgMjQgMjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI%2BPHBhdGggZD0iTTYsMjRjLTMsMC02LTMtNi02di0xMmMwLTMsMy02LDYtNmgxMmMzLDAsNiwzLDYsNnYxMmMwLDMtMyw2LTYsNnoiIGZpbGw9IiNmMDcxNTgiLz48cGF0aCBkPSJNMTMuNiwzLjRjNC4yLDIuNCw2LjMsNy41LDUuMywxMS41LDEuOSwyLjgsMS42LDUuMiwxLjQsNC43LTEuMi0yLjMtMy4zLTEuNC00LjQtLjctMy45LDEuOC0xMC4yLjItMTMuNS01LDMsMi4yLDcuMiwzLjEsMTAuMywxLjItNC42LTMuNi04LjUtOS4yLTguNS05LjMsMi4zLDIuMSw2LDQuOCw3LjMsNS43LTIuOC0zLjEtNS4zLTYuNy01LjItNi43LDIuNywyLjcsNS43LDUuMiw4LjksNy4yLjQtLjgsMS40LTQuNS0xLjYtOC43eiIgZmlsbD0iI2ZmZiIvPjwvc3ZnPg%3D%3D" alt="Swift 5.9">
</a>

</p>

A testable and composable network client.

For more information, browse the API documentation (_coming soon_).

## Supported Platforms

StructuredAPIClient is tested on macOS, iOS, tvOS, Linux, and Windows, and is known to support the following operating system versions:

* Ubuntu 18.04+
* AmazonLinux2
* macOS 10.12+
* iOS 12+
* tvOS 12+
* watchOS 5+
* Windows 10 (using the latest Swift development snapshot)

To integrate the package:

```swift
dependencies: [
    .package(url: "https://github.com/stairtree/StructuredAPIClient.git", from: "2.0.0")
]
```

---

Inspired by blog posts by [Rob Napier](https://robnapier.net) and [Soroush Khanlou](http://khanlou.com), as well as the [Testing Tips & Tricks](https://developer.apple.com/videos/play/wwdc2018/417/) WWDC talk. Version 2.0 revised for full Concurrency support by @gwynne.

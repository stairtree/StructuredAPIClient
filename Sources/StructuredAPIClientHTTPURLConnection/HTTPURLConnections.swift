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

#if HTTPURLConnectionTransport
public import SwiftJava
public import JavaNet

// swift-java's `JavaNet` and `SwiftJava` modules provide `URI`, `URLConnection`,
// `HttpURLConnection`, `JavaURL`, `InputStream`, and `OutputStream` directly, so the only binding
// this package still needs to add is `java.net.URL.openConnection()`, which swift-java does not
// currently generate.
extension JavaURL {
    @JavaMethod
    public func openConnection() throws -> URLConnection!
}
#endif

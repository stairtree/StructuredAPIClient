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

import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import StructuredAPIClient
import StructuredAPIClientTestSupport

final class HTTPStatusCodeTests: XCTestCase {

    func testRejectsInvalidNumbers() {
        XCTAssertNil(HTTPStatusCode.init(rawValue: 0))
        XCTAssertNil(HTTPStatusCode.init(rawValue: 99))
        XCTAssertNil(HTTPStatusCode.init(rawValue: 600))
        XCTAssertNil(HTTPStatusCode.init(rawValue: -1))
        XCTAssertNil(HTTPStatusCode.init(rawValue: .min))
        XCTAssertNil(HTTPStatusCode.init(rawValue: .max))
    }
    
    func testUsesKnownCasesWhenAvailable() {
        XCTAssertEqual(HTTPStatusCode.init(rawValue: 200), HTTPStatusCode.ok)
        XCTAssertEqual(HTTPStatusCode.init(rawValue: 418), HTTPStatusCode.imATeapot)
    }
    
    func testCustomCaseEqualityRules() {
        // N.B.: Creating custom cases for well-known status codes this way is considered invalid in its own right.
        XCTAssertNotEqual(HTTPStatusCode.custom(200), HTTPStatusCode.ok)
        XCTAssertNotEqual(HTTPStatusCode.custom(500), HTTPStatusCode.internalServerError)
        XCTAssertEqual(HTTPStatusCode.custom(209), HTTPStatusCode.init(rawValue: 209))
    }

}

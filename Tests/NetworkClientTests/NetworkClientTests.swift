import XCTest
@testable import NetworkClient

final class NetworkClientTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(NetworkClient().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

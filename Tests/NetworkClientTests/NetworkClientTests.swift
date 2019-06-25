import XCTest
import NetworkClient

final class NetworkClientTests: XCTestCase {

    func testNetworkClient() throws {

        struct TestRequest: NetworkRequest {
            func makeRequest(baseURL: URL) throws -> URLRequest {
                return URLRequest(url: baseURL)
            }

            func parseResponse(_ data: Data) throws -> String {
                return String(decoding: data, as: UTF8.self)
            }
        }

        let responseData = Data("Test".utf8)

        let requestAssertions: (URLRequest) -> Void = {
            XCTAssertEqual($0.url, URL(string: "https://test.somewhere.com")!)
        }

        let client = NetworkClient(baseURL: URL(string: "https://test.somewhere.com")!, transport: TestTransport(responseData: [responseData], assertRequest: requestAssertions))


        client.load(TestRequest()) { result in
            guard let response = try? result.get() else {
                return XCTFail()
            }
            XCTAssertEqual(response, "Test")
        }

        XCTAssertEqual(client.baseURL.absoluteString, "https://test.somewhere.com")
    }

}

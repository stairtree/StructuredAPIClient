// Copyright © 2019 Stairtree GmbH. All rights reserved.

import NetworkClient
import Foundation

// A transport that returns static values for tests
enum TestTransportError: Swift.Error { case tooManyRequests }

final class TestTransport: Transport {
    var history: [URLRequest] = []
    var responseData: [Data]
    var assertRequest: (URLRequest) -> Void

    init(responseData: [Data], assertRequest: @escaping (URLRequest) -> Void = { _ in }) {
        self.responseData = responseData
        self.assertRequest = assertRequest
    }

    func send(request: URLRequest, completion: @escaping (Response) -> Void) {
        assertRequest(request)
        history.append(request)
        if !responseData.isEmpty {
            completion(.success(responseData.removeFirst()))
        } else {
            completion(.error(TestTransportError.tooManyRequests))
        }
    }
}

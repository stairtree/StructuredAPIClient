// Copyright © 2020 Stairtree GmbH. All rights reserved.

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum APIError: Error {
    case transport(TransportFailure)
    case api(status: Status, body: Data)
}

extension APIError {
    public enum TransportFailure {
        case invalidRequest(baseURL: URL, components: URLComponents?)
        case invalidResponse(ResponseFailure)
        case network(errorCode: Int)
        case serverUnreachable(errorCode: Int)
        case unknown(Error)

        public enum ResponseFailure {
            case nonHTTPResponse
            case invalidStatusCode(Int, HTTPURLResponse)
        }
    }

    /// Errors emitted by the `NetworkClient`
    public enum Status: UInt {
        // 1xx information
        case `continue` = 100
        case switchingProtocols = 101
        case processing = 102

        // 2xx success
        case ok = 200
        case created = 201
        case accepted = 202
        case nonAuthoritativeInfo = 203
        case noContent = 204
        case resetContent = 205
        case partialContent = 206
        case multiStatus = 207
        case alreadyReported = 208
        case imUsed = 226

        // 3xx Redirect
        case multipleChoices = 300
        case movedPermanently = 301
        case found = 302
        case seeOther = 303
        case notModified = 304
        case useProxy = 305
        case unused = 306
        case temporaryRedirect = 307
        case permanentRedirect = 308

        // 4xx client errors
        case badRequest = 400
        case unauthorized = 401
        case paymentRequired = 402
        case forbidden = 403
        case notFound = 404
        case methodNotAllowed = 405
        case notAcceptable = 406
        case proxyAuthRequired = 407
        case timeoute = 408
        case conflict = 409
        case gone = 410
        case lengthRequired = 411
        case preconditionFailed = 412
        case entityTooLarge = 413
        case uriTooLong = 414
        case unsupportedMediaType = 415
        case rangeNotSatisfiable = 416
        case expectationFailed = 417
        case imATeapot = 418
        case enhanceYourCalm = 420
        case unprocessableEntity = 422
        case locked = 423
        case failedDependency = 424
        case reservedForWebDAV = 425
        case upgradeRequired = 426
        case preconditionRequired = 428
        case tooManyRequests = 429
        case headerFieldsTooLarge = 431
        case noResponse = 444
        case retryWith = 449
        case blockedByWindowsParentalControls = 450
        case unavailableForLegalReasons = 451
        case clientClosedRequest = 499

        // 5xx server errors
        case internalServerError = 500
        case notImplemented = 501
        case badGateway = 502
        case serviceUnavailable = 503
        case gatewayTimeout = 504
        case versionNotSupported = 505
        case variantAlsoNegotiates = 506
        case insufficientStorage = 507
        case loopDetected = 508
        case bandwidthLimitExceeded = 509
        case notExtended = 510
        case networkAuthRequired = 511
        case networkReadTimeout = 598
        case networkConnectionTimeout = 599

        public init?(code: Int) {
            self.init(rawValue: UInt(code))
        }
    }
}

extension APIError.Status: LocalizedError {
    public var errorDescription: String? {
        return "\(self)"
    }
}

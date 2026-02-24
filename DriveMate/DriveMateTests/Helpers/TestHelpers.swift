import Foundation
@testable import DriveMate

/// Thread-safe box for capturing values from URLProtocol handlers (background threads)
final class SendableBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: String?

    var value: String? {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
}

enum TestHelpers {
    static func makeTestSettings(apiKey: String = "test-api-key", language: AppLanguage = .spanish) -> AppSettings {
        let suiteName = "com.drivemate.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: defaults)
        settings.geminiAPIKey = apiKey
        settings.language = language
        return settings
    }

    static func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    static func geminiSuccessResponse(_ text: String) -> Data {
        let json: [String: Any] = [
            "candidates": [
                [
                    "content": [
                        "parts": [["text": text]],
                        "role": "model"
                    ],
                    "finishReason": "STOP"
                ]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func httpResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

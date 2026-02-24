import XCTest
@testable import DriveMate

final class GeminiServiceTests: XCTestCase {

    private var service: GeminiService!
    private var settings: AppSettings!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        session = TestHelpers.makeMockSession()
        service = GeminiService(session: session)
        settings = TestHelpers.makeTestSettings()
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        service = nil
        settings = nil
        session = nil
        super.tearDown()
    }

    // MARK: - No API Key

    func testSendMessageWithoutAPIKeyThrows() async {
        let emptyKeySettings = TestHelpers.makeTestSettings(apiKey: "")

        do {
            _ = try await service.sendMessage("Hola", settings: emptyKeySettings)
            XCTFail("Should have thrown noAPIKey error")
        } catch let error as GeminiService.GeminiError {
            if case .noAPIKey = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Successful Response

    func testSendMessageReturnsResponseText() async throws {
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            XCTAssertTrue(url.absoluteString.contains("generativelanguage.googleapis.com"))
            XCTAssertTrue(url.absoluteString.contains("key=test-api-key"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let response = TestHelpers.httpResponse(url: url, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("¡Claro! Te ayudo.")
            return (response, data)
        }

        let result = try await service.sendMessage("¿Puedes ayudarme?", settings: settings)
        XCTAssertEqual(result, "¡Claro! Te ayudo.")
    }

    // MARK: - Request Body Validation

    func testRequestBodyContainsUserMessage() async throws {
        let box = SendableBox()

        MockURLProtocol.requestHandler = { request in
            if let body = request.httpBody {
                box.value = String(data: body, encoding: .utf8)
            }
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("OK")
            return (response, data)
        }

        _ = try await service.sendMessage("Test message", settings: settings)

        // Validate request body after the call
        let bodyString = box.value ?? ""
        XCTAssertTrue(bodyString.contains("Test message"))
        XCTAssertTrue(bodyString.contains("\"role\":\"user\"") || bodyString.contains("\"role\" : \"user\""))
        XCTAssertTrue(bodyString.contains("DriveMate"))
    }

    func testRequestBodyContainsLanguageInSystemPrompt() async throws {
        let englishSettings = TestHelpers.makeTestSettings(language: .english)
        let box = SendableBox()

        MockURLProtocol.requestHandler = { request in
            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
               let sysInstruction = json["systemInstruction"] as? [String: Any],
               let sysParts = sysInstruction["parts"] as? [[String: Any]],
               let text = sysParts.first?["text"] as? String {
                box.value = text
            }

            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("Hello!")
            return (response, data)
        }

        _ = try await service.sendMessage("Hi", settings: englishSettings)
        XCTAssertTrue(box.value?.contains("English") == true)
    }

    // MARK: - Rate Limit (429)

    func testRateLimitedThrowsError() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 429)
            return (response, Data())
        }

        do {
            _ = try await service.sendMessage("Hola", settings: settings)
            XCTFail("Should have thrown rateLimited error")
        } catch let error as GeminiService.GeminiError {
            if case .rateLimited = error {
                XCTAssertTrue(error.errorDescription?.contains("Límite") == true)
            } else {
                XCTFail("Wrong error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - HTTP Errors

    func testHTTPError500() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 500)
            return (response, Data())
        }

        do {
            _ = try await service.sendMessage("Hola", settings: settings)
            XCTFail("Should have thrown httpError")
        } catch let error as GeminiService.GeminiError {
            if case .httpError(let code) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Wrong error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testHTTPError403() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 403)
            return (response, Data())
        }

        do {
            _ = try await service.sendMessage("Hola", settings: settings)
            XCTFail("Should have thrown httpError")
        } catch let error as GeminiService.GeminiError {
            if case .httpError(let code) = error {
                XCTAssertEqual(code, 403)
            } else {
                XCTFail("Wrong error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Decoding Error

    func testMalformedResponseThrowsDecodingError() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let malformed = try! JSONSerialization.data(withJSONObject: ["foo": "bar"])
            return (response, malformed)
        }

        do {
            _ = try await service.sendMessage("Hola", settings: settings)
            XCTFail("Should have thrown decodingError")
        } catch let error as GeminiService.GeminiError {
            if case .decodingError = error {
                // Expected
            } else {
                XCTFail("Wrong error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEmptyResponseBodyThrowsDecodingError() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            return (response, Data())
        }

        do {
            _ = try await service.sendMessage("Hola", settings: settings)
            XCTFail("Should have thrown decodingError")
        } catch let error as GeminiService.GeminiError {
            if case .decodingError = error {
                // Expected
            } else {
                XCTFail("Wrong error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testResponseWithEmptyCandidatesThrowsDecodingError() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = try! JSONSerialization.data(withJSONObject: ["candidates": []])
            return (response, data)
        }

        do {
            _ = try await service.sendMessage("Hola", settings: settings)
            XCTFail("Should have thrown decodingError")
        } catch let error as GeminiService.GeminiError {
            if case .decodingError = error {
                // Expected
            } else {
                XCTFail("Wrong error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Network Error

    func testNetworkErrorThrows() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await service.sendMessage("Hola", settings: settings)
            XCTFail("Should have thrown networkError")
        } catch let error as GeminiService.GeminiError {
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Wrong error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Conversation History

    func testClearHistory() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("Hola")
            return (response, data)
        }

        _ = try? await service.sendMessage("Msg 1", settings: settings)
        let countBefore = await service.historyCount()
        XCTAssertEqual(countBefore, 2) // user + model

        await service.clearHistory()
        let countAfter = await service.historyCount()
        XCTAssertEqual(countAfter, 0)
    }

    func testConversationHistoryGrows() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("Respuesta")
            return (response, data)
        }

        _ = try await service.sendMessage("Msg 1", settings: settings)
        let count1 = await service.historyCount()
        XCTAssertEqual(count1, 2)

        _ = try await service.sendMessage("Msg 2", settings: settings)
        let count2 = await service.historyCount()
        XCTAssertEqual(count2, 4)
    }

    func testHistoryLimitedTo20Messages() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("OK")
            return (response, data)
        }

        // Send 12 messages → 24 history entries → should be trimmed to 20
        for i in 1...12 {
            _ = try await service.sendMessage("Msg \(i)", settings: settings)
        }

        let count = await service.historyCount()
        XCTAssertLessThanOrEqual(count, 20)
    }

    func testHistoryRolledBackOnError() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 500)
            return (response, Data())
        }

        _ = try? await service.sendMessage("Will fail", settings: settings)
        let count = await service.historyCount()
        XCTAssertEqual(count, 0, "History should be empty after failed request")
    }

    // MARK: - Response Trimming

    func testResponseTrimsWhitespace() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("  Respuesta con espacios  \n")
            return (response, data)
        }

        let result = try await service.sendMessage("Test", settings: settings)
        XCTAssertEqual(result, "Respuesta con espacios")
    }

    // MARK: - Error Descriptions

    func testErrorDescriptions() {
        XCTAssertNotNil(GeminiService.GeminiError.noAPIKey.errorDescription)
        XCTAssertNotNil(GeminiService.GeminiError.invalidURL.errorDescription)
        XCTAssertNotNil(GeminiService.GeminiError.httpError(500).errorDescription)
        XCTAssertNotNil(GeminiService.GeminiError.rateLimited.errorDescription)
        XCTAssertNotNil(GeminiService.GeminiError.noResponse.errorDescription)
        XCTAssertNotNil(GeminiService.GeminiError.decodingError.errorDescription)

        let urlError = URLError(.timedOut)
        XCTAssertNotNil(GeminiService.GeminiError.networkError(urlError).errorDescription)
    }

    func testHTTPErrorIncludesStatusCode() {
        let error = GeminiService.GeminiError.httpError(404)
        XCTAssertTrue(error.errorDescription!.contains("404"))
    }
}

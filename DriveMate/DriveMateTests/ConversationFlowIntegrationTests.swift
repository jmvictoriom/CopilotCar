import XCTest
@testable import DriveMate

/// Integration tests that verify the full conversation flow:
/// user speech → Gemini API → assistant response, using mocked network.
@MainActor
final class ConversationFlowIntegrationTests: XCTestCase {

    private var viewModel: ConversationViewModel!
    private var settings: AppSettings!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        session = TestHelpers.makeMockSession()
        settings = TestHelpers.makeTestSettings()
        viewModel = ConversationViewModel(
            settings: settings,
            geminiService: GeminiService(session: session)
        )
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        viewModel = nil
        settings = nil
        session = nil
        super.tearDown()
    }

    // MARK: - Full Conversation Flow

    func testFullConversationFlow_UserMessageToAssistantResponse() async {
        let capturedBox = SendableBox()

        MockURLProtocol.requestHandler = { request in
            capturedBox.value = request.url?.absoluteString
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("La capital de Francia es París.")
            return (response, data)
        }

        // Simulate user message manually
        viewModel.messages.append(Message(role: .user, content: "¿Cuál es la capital de Francia?"))
        viewModel.state = .processing

        // Call sendToGemini directly (await ensures completion)
        await viewModel.sendToGemini("¿Cuál es la capital de Francia?")

        // Verify request was sent to Gemini
        XCTAssertTrue(capturedBox.value?.contains("generativelanguage.googleapis.com") == true)

        // Assistant response should be added
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages[1].role, .assistant)
        XCTAssertEqual(viewModel.messages[1].content, "La capital de Francia es París.")
        XCTAssertEqual(viewModel.state, .speaking)
    }

    // MARK: - Multi-Turn Conversation

    func testMultiTurnConversation() async {
        var requestCount = 0

        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let responseText = requestCount == 1 ? "Hola, ¿en qué te ayudo?" : "El tráfico está fluido."
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse(responseText)
            return (response, data)
        }

        // Turn 1
        viewModel.messages.append(Message(role: .user, content: "Hola DriveMate"))
        await viewModel.sendToGemini("Hola DriveMate")

        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages[1].content, "Hola, ¿en qué te ayudo?")

        // Turn 2
        viewModel.state = .idle
        viewModel.messages.append(Message(role: .user, content: "¿Cómo está el tráfico?"))
        await viewModel.sendToGemini("¿Cómo está el tráfico?")

        XCTAssertEqual(viewModel.messages.count, 4)
        XCTAssertEqual(viewModel.messages[3].content, "El tráfico está fluido.")
        XCTAssertEqual(requestCount, 2)
    }

    // MARK: - Error Recovery

    func testErrorRecovery_GeminiFailsThenSucceeds() async {
        var requestCount = 0

        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            if requestCount == 1 {
                let response = TestHelpers.httpResponse(url: request.url!, statusCode: 500)
                return (response, Data())
            } else {
                let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
                let data = TestHelpers.geminiSuccessResponse("Ahora sí funciono.")
                return (response, data)
            }
        }

        // First attempt fails
        viewModel.messages.append(Message(role: .user, content: "Hola"))
        await viewModel.sendToGemini("Hola")

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.messages.count, 1) // Only user message

        // Second attempt succeeds
        viewModel.errorMessage = nil
        viewModel.messages.append(Message(role: .user, content: "Hola otra vez"))
        await viewModel.sendToGemini("Hola otra vez")

        XCTAssertEqual(viewModel.messages.count, 3) // 2 user + 1 assistant
        XCTAssertEqual(viewModel.messages[2].content, "Ahora sí funciono.")
    }

    // MARK: - Rate Limit Handling

    func testRateLimitShowsUserFriendlyError() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 429)
            return (response, Data())
        }

        await viewModel.sendToGemini("Pregunta")

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Límite"))
    }

    // MARK: - Network Error

    func testNetworkErrorShowsMessage() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        await viewModel.sendToGemini("Sin conexión")

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Clear and Restart

    func testClearConversationAndRestart() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("Respuesta")
            return (response, data)
        }

        // Build up conversation
        viewModel.messages.append(Message(role: .user, content: "Mensaje 1"))
        await viewModel.sendToGemini("Mensaje 1")
        XCTAssertEqual(viewModel.messages.count, 2)

        // Clear
        viewModel.clearConversation()
        XCTAssertTrue(viewModel.messages.isEmpty)

        // Start fresh
        viewModel.state = .idle
        viewModel.messages.append(Message(role: .user, content: "Nuevo mensaje"))
        await viewModel.sendToGemini("Nuevo mensaje")

        XCTAssertEqual(viewModel.messages.count, 2) // Fresh conversation
    }

    // MARK: - Language Switch

    func testLanguageSwitchAffectsSystemPrompt() async {
        let capturedBox = SendableBox()

        MockURLProtocol.requestHandler = { request in
            if let body = request.httpBody {
                capturedBox.value = String(data: body, encoding: .utf8)
            }
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("OK")
            return (response, data)
        }

        // Test Spanish
        settings.language = .spanish
        await viewModel.sendToGemini("Test")
        XCTAssertTrue(capturedBox.value?.contains("español") == true)

        // Switch to English
        await viewModel.geminiService.clearHistory()
        viewModel.state = .idle
        settings.language = .english
        capturedBox.value = nil
        await viewModel.sendToGemini("Test")
        XCTAssertTrue(capturedBox.value?.contains("English") == true)
    }

    // MARK: - Settings Validation

    func testNoAPIKeyPreventsConversation() {
        settings.geminiAPIKey = ""
        viewModel.speechRecognizer.authorizationStatus = .authorized

        viewModel.startListening()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("API Key"))
        XCTAssertNotEqual(viewModel.state, .listening)
    }

    // MARK: - Gemini History Sync

    func testGeminiHistorySyncsWithViewModel() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("R")
            return (response, data)
        }

        // Send messages
        for i in 1...3 {
            viewModel.messages.append(Message(role: .user, content: "M\(i)"))
            await viewModel.sendToGemini("M\(i)")
            viewModel.state = .idle
        }

        // ViewModel should have 6 messages (3 user + 3 assistant)
        XCTAssertEqual(viewModel.messages.count, 6)

        // GeminiService should also have history
        let historyCount = await viewModel.geminiService.historyCount()
        XCTAssertEqual(historyCount, 6)

        // Clear should sync both
        viewModel.clearConversation()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(viewModel.messages.isEmpty)
        let clearedCount = await viewModel.geminiService.historyCount()
        XCTAssertEqual(clearedCount, 0)
    }

    // MARK: - HandleSpeechResult Integration

    func testHandleSpeechResultTriggersFullFlow() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("Respuesta")
            return (response, data)
        }

        viewModel.handleSpeechResult("Test message")

        // User message added immediately
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.state, .processing)

        // Wait for async Task to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages[1].role, .assistant)
    }
}

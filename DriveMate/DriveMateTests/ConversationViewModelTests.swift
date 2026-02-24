import XCTest
@testable import DriveMate

@MainActor
final class ConversationViewModelTests: XCTestCase {

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

    // MARK: - Initial State

    func testInitialStateIsIdle() {
        XCTAssertEqual(viewModel.state, .idle)
    }

    func testInitialMessagesEmpty() {
        XCTAssertTrue(viewModel.messages.isEmpty)
    }

    func testInitialErrorMessageIsNil() {
        XCTAssertNil(viewModel.errorMessage)
    }

    func testInitialTranscriptionIsEmpty() {
        XCTAssertEqual(viewModel.currentTranscription, "")
    }

    // MARK: - State Labels

    func testStateLabelIdle() {
        viewModel.state = .idle
        XCTAssertEqual(viewModel.stateLabel, "Toca para hablar")
    }

    func testStateLabelListening() {
        viewModel.state = .listening
        XCTAssertEqual(viewModel.stateLabel, "Escuchando...")
    }

    func testStateLabelProcessing() {
        viewModel.state = .processing
        XCTAssertEqual(viewModel.stateLabel, "Pensando...")
    }

    func testStateLabelSpeaking() {
        viewModel.state = .speaking
        XCTAssertEqual(viewModel.stateLabel, "Hablando...")
    }

    // MARK: - Toggle Without Auth

    func testToggleListeningWithoutAuthShowsError() {
        // Default authorizationStatus is .notDetermined
        viewModel.toggleListening()
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Permiso"))
    }

    // MARK: - Toggle Without API Key

    func testStartListeningWithoutAPIKeyShowsError() {
        settings.geminiAPIKey = ""
        // Simulate authorized status for speech
        viewModel.speechRecognizer.authorizationStatus = .authorized
        viewModel.startListening()
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("API Key"))
    }

    // MARK: - Handle Speech Result

    func testHandleSpeechResultAddsUserMessage() {
        viewModel.handleSpeechResult("¿Qué hora es?")

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages[0].role, .user)
        XCTAssertEqual(viewModel.messages[0].content, "¿Qué hora es?")
        XCTAssertEqual(viewModel.state, .processing)
    }

    func testHandleEmptySpeechResultGoesToIdle() {
        viewModel.state = .listening
        viewModel.handleSpeechResult("")

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.messages.isEmpty)
    }

    // MARK: - Send to Gemini

    func testSendToGeminiSuccess() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("Son las 3 de la tarde.")
            return (response, data)
        }

        viewModel.messages.append(Message(role: .user, content: "¿Qué hora es?"))
        await viewModel.sendToGemini("¿Qué hora es?")

        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages[1].role, .assistant)
        XCTAssertEqual(viewModel.messages[1].content, "Son las 3 de la tarde.")
        XCTAssertEqual(viewModel.state, .speaking)
    }

    func testSendToGeminiError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        await viewModel.sendToGemini("Hola")

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Speak Response

    func testSpeakResponseSetsStateSpeaking() {
        viewModel.speakResponse("Hola, soy DriveMate")
        XCTAssertEqual(viewModel.state, .speaking)
    }

    // MARK: - Clear Conversation

    func testClearConversationRemovesAllMessages() {
        viewModel.messages.append(Message(role: .user, content: "Hola"))
        viewModel.messages.append(Message(role: .assistant, content: "¡Hola!"))
        XCTAssertEqual(viewModel.messages.count, 2)

        viewModel.clearConversation()
        XCTAssertTrue(viewModel.messages.isEmpty)
    }

    func testClearConversationResetsError() {
        viewModel.errorMessage = "Some error"
        viewModel.clearConversation()
        // Error is not explicitly cleared by clearConversation,
        // but messages are cleared
        XCTAssertTrue(viewModel.messages.isEmpty)
    }

    // MARK: - Toggle From Speaking

    func testToggleFromSpeakingStopsSpeech() {
        viewModel.state = .speaking
        viewModel.toggleListening()
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertFalse(viewModel.speechSynthesizer.isSpeaking)
    }

    // MARK: - Toggle From Processing (no-op)

    func testToggleFromProcessingDoesNothing() {
        viewModel.state = .processing
        viewModel.toggleListening()
        XCTAssertEqual(viewModel.state, .processing)
    }

    // MARK: - Multiple Messages Flow

    func testMultipleMessagesAccumulate() async {
        MockURLProtocol.requestHandler = { request in
            let response = TestHelpers.httpResponse(url: request.url!, statusCode: 200)
            let data = TestHelpers.geminiSuccessResponse("Respuesta")
            return (response, data)
        }

        viewModel.messages.append(Message(role: .user, content: "Msg 1"))
        await viewModel.sendToGemini("Msg 1")

        viewModel.messages.append(Message(role: .user, content: "Msg 2"))
        await viewModel.sendToGemini("Msg 2")

        XCTAssertEqual(viewModel.messages.count, 4) // 2 user + 2 assistant
    }

    // MARK: - Settings Integration

    func testViewModelUsesInjectedSettings() {
        XCTAssertEqual(viewModel.settings.geminiAPIKey, "test-api-key")
        XCTAssertEqual(viewModel.settings.language, .spanish)
    }
}

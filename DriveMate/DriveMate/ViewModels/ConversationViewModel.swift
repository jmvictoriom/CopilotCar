import Foundation
import Speech

enum ConversationState: Equatable {
    case idle
    case listening
    case processing
    case speaking
}

@Observable
@MainActor
final class ConversationViewModel {
    var messages: [Message] = []
    var state: ConversationState = .idle
    var currentTranscription: String = ""
    var errorMessage: String?

    let settings: AppSettings
    let speechRecognizer: SpeechRecognizer
    let geminiService: GeminiService
    let speechSynthesizer: SpeechSynthesizer

    init(
        settings: AppSettings = .shared,
        speechRecognizer: SpeechRecognizer = SpeechRecognizer(),
        geminiService: GeminiService = GeminiService(),
        speechSynthesizer: SpeechSynthesizer = SpeechSynthesizer()
    ) {
        self.settings = settings
        self.speechRecognizer = speechRecognizer
        self.geminiService = geminiService
        self.speechSynthesizer = speechSynthesizer
    }

    func requestPermissions() {
        speechRecognizer.requestAuthorization()
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    func toggleListening() {
        switch state {
        case .idle:
            startListening()
        case .listening:
            speechRecognizer.stopListening()
            state = .idle
        case .speaking:
            speechSynthesizer.stop()
            state = .idle
        case .processing:
            break
        }
    }

    func startListening() {
        guard speechRecognizer.authorizationStatus == .authorized else {
            errorMessage = "Permiso de voz no concedido. Ve a Ajustes para activarlo."
            return
        }

        guard !settings.geminiAPIKey.isEmpty else {
            errorMessage = "Configura tu API Key de Gemini en Ajustes."
            return
        }

        errorMessage = nil
        state = .listening
        currentTranscription = ""

        do {
            try speechRecognizer.startListening(locale: settings.language.rawValue) { [weak self] finalText in
                Task { @MainActor in
                    self?.handleSpeechResult(finalText)
                }
            }
        } catch {
            state = .idle
            errorMessage = error.localizedDescription
        }
    }

    func handleSpeechResult(_ text: String) {
        guard !text.isEmpty else {
            state = .idle
            return
        }

        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        state = .processing

        Task {
            await sendToGemini(text)
        }
    }

    func sendToGemini(_ text: String) async {
        do {
            let response = try await geminiService.sendMessage(text, settings: settings)
            let assistantMessage = Message(role: .assistant, content: response)
            messages.append(assistantMessage)
            speakResponse(response)

            // Extract driver profile every 10 messages
            if messages.count % 10 == 0 {
                Task.detached { [weak self] in
                    await self?.updateDriverProfile()
                }
            }
        } catch {
            state = .idle
            errorMessage = error.localizedDescription
        }
    }

    private func updateDriverProfile() async {
        do {
            let profile = try await geminiService.extractDriverProfile(
                currentProfile: settings.driverProfile,
                settings: settings
            )
            settings.driverProfile = profile
        } catch {
            // Profile extraction is best-effort, don't show errors
        }
    }

    func speakResponse(_ text: String) {
        state = .speaking
        speechSynthesizer.speak(
            text,
            locale: settings.language.rawValue,
            rate: settings.speechRate
        ) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if self.settings.handsFreeMode {
                    self.startListening()
                } else {
                    self.state = .idle
                }
            }
        }
    }

    func clearConversation() {
        // Extract profile before clearing if there's enough conversation
        if messages.count >= 4 {
            Task {
                await updateDriverProfile()
                await geminiService.clearHistory()
            }
        } else {
            Task {
                await geminiService.clearHistory()
            }
        }
        messages.removeAll()
    }

    var stateLabel: String {
        switch state {
        case .idle: return "Toca para hablar"
        case .listening: return "Escuchando..."
        case .processing: return "Pensando..."
        case .speaking: return "Hablando..."
        }
    }
}

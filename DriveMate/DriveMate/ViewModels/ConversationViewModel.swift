import Foundation
import Speech
#if canImport(UIKit)
import UIKit
#endif

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
    let placesService: PlacesService

    init(
        settings: AppSettings = .shared,
        speechRecognizer: SpeechRecognizer = SpeechRecognizer(),
        geminiService: GeminiService = GeminiService(),
        speechSynthesizer: SpeechSynthesizer = SpeechSynthesizer(),
        placesService: PlacesService = PlacesService()
    ) {
        self.settings = settings
        self.speechRecognizer = speechRecognizer
        self.geminiService = geminiService
        self.speechSynthesizer = speechSynthesizer
        self.placesService = placesService
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
            let parsed = ResponseParser.parse(response)

            if let query = parsed.searchQuery, !settings.placesAPIKey.isEmpty {
                // Show Gemini's message while we search
                let searchingMessage = Message(role: .assistant, content: parsed.cleanText)
                messages.append(searchingMessage)
                speakResponse(parsed.cleanText)

                // Search in background
                Task {
                    await handlePlaceSearch(query: query)
                }
            } else {
                let assistantMessage = Message(role: .assistant, content: parsed.cleanText)
                messages.append(assistantMessage)
                speakResponse(parsed.cleanText)
            }

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

    private func handlePlaceSearch(query: String) async {
        do {
            let results = try await placesService.searchPlaces(
                query: query, apiKey: settings.placesAPIKey
            )

            let actions = results.map { place in
                PlaceAction(
                    id: place.id,
                    placeName: place.displayName,
                    address: place.formattedAddress,
                    rating: place.rating,
                    placeId: place.id,
                    phoneNumber: nil
                )
            }

            // Build summary for TTS
            let summary = results.enumerated().map { (i, place) in
                var line = "\(i + 1). \(place.displayName)"
                if let rating = place.rating {
                    line += ", \(String(format: "%.1f", rating)) estrellas"
                }
                return line
            }.joined(separator: ". ")

            let resultsMessage = Message(
                role: .assistant,
                content: "Encontré \(results.count) resultados:\n\(summary)",
                actions: actions
            )
            messages.append(resultsMessage)

            // Inject results into Gemini history
            await geminiService.injectMessage(
                role: "model",
                text: "Resultados de búsqueda: \(summary)"
            )

            speakResponse("Encontré \(results.count) resultados. \(summary). Puedes tocar llamar en cualquiera.")
        } catch {
            let errorMsg = Message(
                role: .assistant,
                content: "No pude encontrar resultados: \(error.localizedDescription)"
            )
            messages.append(errorMsg)
            speakResponse("No pude encontrar resultados.")
        }
    }

    func callPlace(_ action: PlaceAction) {
        Task {
            do {
                let phone = try await placesService.getPhoneNumber(
                    placeId: action.placeId, apiKey: settings.placesAPIKey
                )
                guard let number = phone.internationalPhone ?? phone.nationalPhone else {
                    errorMessage = "\(action.placeName) no tiene teléfono registrado."
                    return
                }
                openDialer(number: number)
            } catch {
                errorMessage = "No se pudo obtener el teléfono: \(error.localizedDescription)"
            }
        }
    }

    private func openDialer(number: String) {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        guard let url = URL(string: "tel://\(cleaned)") else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
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

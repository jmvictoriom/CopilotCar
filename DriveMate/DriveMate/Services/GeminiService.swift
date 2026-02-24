import Foundation

actor GeminiService {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/"
    private var conversationHistory: [[String: Any]] = []
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    enum GeminiError: LocalizedError {
        case noAPIKey
        case invalidURL
        case httpError(Int)
        case rateLimited
        case noResponse
        case networkError(Error)
        case decodingError

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "No se ha configurado la API Key de Gemini."
            case .invalidURL: return "URL inválida."
            case .httpError(let code): return "Error HTTP: \(code)"
            case .rateLimited: return "Límite de peticiones alcanzado. Espera un momento."
            case .noResponse: return "No se recibió respuesta de la IA."
            case .networkError(let error): return "Error de red: \(error.localizedDescription)"
            case .decodingError: return "Error al procesar la respuesta."
            }
        }
    }

    func clearHistory() {
        conversationHistory = []
    }

    func historyCount() -> Int {
        conversationHistory.count
    }

    func sendMessage(_ text: String, settings: AppSettings) async throws -> String {
        let apiKey = settings.geminiAPIKey
        guard !apiKey.isEmpty else { throw GeminiError.noAPIKey }

        let endpoint = "\(baseURL)\(settings.geminiModel.apiPath)?key=\(apiKey)"
        guard let url = URL(string: endpoint) else {
            throw GeminiError.invalidURL
        }

        conversationHistory.append([
            "role": "user",
            "parts": [["text": text]]
        ])

        let systemPrompt = "Eres un copiloto de voz para conductores llamado DriveMate. Responde de forma concisa, clara y útil en \(settings.language.systemPromptLanguage). Mantén las respuestas cortas (1-3 frases) porque serán leídas en voz alta mientras el usuario conduce. Puedes ayudar con navegación, información general, entretenimiento, y cualquier consulta. Sé amigable y natural."

        let body: [String: Any] = [
            "contents": conversationHistory,
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "generationConfig": [
                "maxOutputTokens": 256,
                "temperature": 0.7
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            conversationHistory.removeLast()
            throw GeminiError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            conversationHistory.removeLast()
            throw GeminiError.noResponse
        }

        if httpResponse.statusCode == 429 {
            conversationHistory.removeLast()
            throw GeminiError.rateLimited
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            conversationHistory.removeLast()
            throw GeminiError.httpError(httpResponse.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            conversationHistory.removeLast()
            throw GeminiError.decodingError
        }

        let responseText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        conversationHistory.append([
            "role": "model",
            "parts": [["text": responseText]]
        ])

        // Keep history manageable (last 20 messages)
        if conversationHistory.count > 20 {
            conversationHistory = Array(conversationHistory.suffix(20))
        }

        return responseText
    }
}

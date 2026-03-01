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

    private func buildSystemPrompt(settings: AppSettings) -> String {
        let lang = settings.language.systemPromptLanguage
        let profile = settings.driverProfile

        var prompt = """
            Eres DriveMate, un copiloto de voz inteligente para conductores. \
            Responde siempre en \(lang).

            PERSONALIDAD Y HUMOR:
            - Eres como un amigo ingenioso que va de copiloto. Cercano, divertido y con chispa.
            - Usa humor natural: chistes cortos, juegos de palabras, datos curiosos graciosos.
            - Adapta tu estilo de humor según lo que le guste al conductor.
            - Puedes lanzar trivias o curiosidades para amenizar el viaje.
            - Si el conductor está de buen humor, sé más bromista. Si está serio, sé más directo.

            REGLAS DE RESPUESTA:
            - Máximo 2-3 frases. Tus respuestas se leen en voz alta mientras conduce.
            - Sé directo, claro y natural. Nada de listas largas ni formato markdown.
            - Recuerda detalles de la conversación actual y úsalos para personalizar.

            SEGURIDAD VIAL (PRIORIDAD MÁXIMA):
            - Nunca sugieras que el conductor mire la pantalla, escriba o haga algo que distraiga.
            - Si detectas una emergencia, recomienda detenerse en un lugar seguro o llamar al 112/911.
            - No des indicaciones de navegación paso a paso (para eso está el GPS).

            CAPACIDADES:
            - Conversación general, curiosidades, noticias, cultura.
            - Orientación sobre rutas y destinos (sin reemplazar al GPS).
            - Entretenimiento: chistes, juegos de palabras, trivias para amenizar el viaje.
            - Información práctica: clima, gasolineras, restaurantes, horarios.
            - Ayuda con cálculos rápidos, traducciones y definiciones.

            Si no sabes algo, dilo honestamente. Nunca inventes datos críticos.
            """

        if !profile.isEmpty {
            prompt += "\n\nPERFIL DEL CONDUCTOR (lo que sabes de viajes anteriores):\n\(profile)"
        } else {
            prompt += "\n\nConductor nuevo. Adapta tu estilo según la conversación y aprende sus preferencias."
        }

        return prompt
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

        let body: [String: Any] = [
            "contents": conversationHistory,
            "systemInstruction": [
                "parts": [["text": buildSystemPrompt(settings: settings)]]
            ],
            "generationConfig": [
                "maxOutputTokens": 256,
                "temperature": 0.7
            ]
        ]

        let responseText = try await makeRequest(url: url, body: body)

        conversationHistory.append([
            "role": "model",
            "parts": [["text": responseText]]
        ])

        // Keep history manageable (last 40 messages for better context)
        if conversationHistory.count > 40 {
            conversationHistory = Array(conversationHistory.suffix(40))
        }

        return responseText
    }

    func extractDriverProfile(currentProfile: String, settings: AppSettings) async throws -> String {
        let apiKey = settings.geminiAPIKey
        guard !apiKey.isEmpty else { throw GeminiError.noAPIKey }

        let endpoint = "\(baseURL)\(settings.geminiModel.apiPath)?key=\(apiKey)"
        guard let url = URL(string: endpoint) else { throw GeminiError.invalidURL }

        let extractionPrompt = """
            Analiza nuestra conversación y actualiza el perfil del conductor. \
            Incluye solo información confirmada:
            - Nombre o apodo (si lo mencionó)
            - Intereses y temas favoritos
            - Estilo de humor preferido (qué tipo de chistes le gustan)
            - Destinos o rutas frecuentes
            - Cualquier dato personal relevante

            Perfil actual: \(currentProfile.isEmpty ? "Nuevo conductor, sin perfil aún." : currentProfile)

            Responde SOLO con el perfil actualizado en texto breve (máximo 150 palabras). \
            No incluyas explicaciones ni saludos.
            """

        var tempHistory = conversationHistory
        tempHistory.append([
            "role": "user",
            "parts": [["text": extractionPrompt]]
        ])

        let body: [String: Any] = [
            "contents": tempHistory,
            "generationConfig": [
                "maxOutputTokens": 300,
                "temperature": 0.3
            ]
        ]

        return try await makeRequest(url: url, body: body)
    }

    private func makeRequest(url: URL, body: [String: Any]) async throws -> String {
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

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

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

    func injectMessage(role: String, text: String) {
        conversationHistory.append([
            "role": role,
            "parts": [["text": text]]
        ])
    }

    private func buildSystemPrompt(settings: AppSettings) -> String {
        let lang = settings.language.systemPromptLanguage
        let profile = settings.driverProfile
        let hasPlacesKey = !settings.placesAPIKey.isEmpty

        var prompt = """
            Eres DriveMate, un copiloto de voz para conductores. \
            Responde siempre en \(lang).

            PERSONALIDAD:
            - Cercano y natural, como un buen copiloto. Práctico ante todo.
            - Puedes usar humor puntual (un comentario gracioso, un dato curioso) \
            pero sin forzarlo. La prioridad es ser útil.
            - Adapta el tono al conductor: si bromea, puedes seguirle; si va al grano, tú también.

            REGLAS DE RESPUESTA:
            - Máximo 2-3 frases. Tus respuestas se leen en voz alta mientras conduce.
            - Sé directo y claro. Nada de listas, formato markdown ni respuestas largas.
            - Recuerda detalles de la conversación y úsalos para personalizar.

            SEGURIDAD VIAL (PRIORIDAD MÁXIMA):
            - Nunca sugieras mirar la pantalla, escribir o cualquier distracción.
            - Emergencias: recomienda detenerse en lugar seguro o llamar al 112/911.
            - No des navegación paso a paso (para eso está el GPS).

            CAPACIDADES:
            - Conversación general, curiosidades, cultura.
            - Orientación sobre rutas y destinos (sin reemplazar al GPS).
            - Entretenimiento ligero: trivias, datos curiosos, chistes si los piden.
            - Info práctica: clima, gasolineras, restaurantes, horarios.
            - Cálculos rápidos, traducciones y definiciones.

            Si no sabes algo, dilo. Nunca inventes datos críticos como direcciones o teléfonos.
            """

        if hasPlacesKey {
            prompt += """

            BÚSQUEDA DE LUGARES:
            - Cuando el conductor pida buscar un lugar real (restaurante, gasolinera, hotel, etc.), \
            incluye el tag [BUSCAR:descripción del lugar] al final de tu respuesta.
            - Ejemplo: el conductor dice "busca restaurantes italianos cerca de Sol". \
            Tú respondes: "Voy a buscar eso por ti. [BUSCAR:restaurantes italianos cerca de Sol Madrid]"
            - Solo usa el tag cuando el conductor pida explícitamente buscar un lugar.
            - La descripción debe ser clara e incluir la zona si el conductor la menciona.
            - NO inventes resultados. El sistema buscará por ti y mostrará los resultados reales.
            """
        }

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

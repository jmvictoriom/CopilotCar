package com.drivemate.service

import com.drivemate.model.AppLanguage
import com.drivemate.model.GeminiModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

class GeminiService {

    private val baseURL = "https://generativelanguage.googleapis.com/v1beta/"
    private val conversationHistory = mutableListOf<JSONObject>()

    sealed class GeminiError(message: String) : Exception(message) {
        class NoAPIKey : GeminiError("No se ha configurado la API Key de Gemini.")
        class InvalidURL : GeminiError("URL inválida.")
        class HttpError(val code: Int) : GeminiError("Error HTTP: $code")
        class RateLimited : GeminiError("Límite de peticiones alcanzado. Espera un momento.")
        class NoResponse : GeminiError("No se recibió respuesta de la IA.")
        class NetworkError(cause: Throwable) : GeminiError("Error de red: ${cause.localizedMessage}")
        class DecodingError : GeminiError("Error al procesar la respuesta.")
    }

    fun clearHistory() {
        conversationHistory.clear()
    }

    fun historyCount(): Int = conversationHistory.size

    fun injectMessage(role: String, text: String) {
        conversationHistory.add(JSONObject().apply {
            put("role", role)
            put("parts", JSONArray().put(JSONObject().put("text", text)))
        })
    }

    private fun buildSystemPrompt(language: AppLanguage, driverProfile: String, hasPlacesKey: Boolean = false): String {
        val lang = language.systemPromptLanguage

        var prompt = "Eres DriveMate, un copiloto de voz para conductores. " +
                "Responde siempre en $lang.\n\n" +
                "PERSONALIDAD:\n" +
                "- Cercano y natural, como un buen copiloto. Práctico ante todo.\n" +
                "- Puedes usar humor puntual (un comentario gracioso, un dato curioso) " +
                "pero sin forzarlo. La prioridad es ser útil.\n" +
                "- Adapta el tono al conductor: si bromea, puedes seguirle; si va al grano, tú también.\n\n" +
                "REGLAS DE RESPUESTA:\n" +
                "- Máximo 2-3 frases. Tus respuestas se leen en voz alta mientras conduce.\n" +
                "- Sé directo y claro. Nada de listas, formato markdown ni respuestas largas.\n" +
                "- Recuerda detalles de la conversación y úsalos para personalizar.\n\n" +
                "SEGURIDAD VIAL (PRIORIDAD MÁXIMA):\n" +
                "- Nunca sugieras mirar la pantalla, escribir o cualquier distracción.\n" +
                "- Emergencias: recomienda detenerse en lugar seguro o llamar al 112/911.\n" +
                "- No des navegación paso a paso (para eso está el GPS).\n\n" +
                "CAPACIDADES:\n" +
                "- Conversación general, curiosidades, cultura.\n" +
                "- Orientación sobre rutas y destinos (sin reemplazar al GPS).\n" +
                "- Entretenimiento ligero: trivias, datos curiosos, chistes si los piden.\n" +
                "- Info práctica: clima, gasolineras, restaurantes, horarios.\n" +
                "- Cálculos rápidos, traducciones y definiciones.\n\n" +
                "Si no sabes algo, dilo. Nunca inventes datos críticos como direcciones o teléfonos."

        if (hasPlacesKey) {
            prompt += "\n\nBÚSQUEDA DE LUGARES:\n" +
                    "- Cuando el conductor pida buscar un lugar real (restaurante, gasolinera, hotel, etc.), " +
                    "incluye el tag [BUSCAR:descripción del lugar] al final de tu respuesta.\n" +
                    "- Ejemplo: el conductor dice \"busca restaurantes italianos cerca de Sol\". " +
                    "Tú respondes: \"Voy a buscar eso por ti. [BUSCAR:restaurantes italianos cerca de Sol Madrid]\"\n" +
                    "- Solo usa el tag cuando el conductor pida explícitamente buscar un lugar.\n" +
                    "- La descripción debe ser clara e incluir la zona si el conductor la menciona.\n" +
                    "- NO inventes resultados. El sistema buscará por ti y mostrará los resultados reales."
        }

        prompt += if (driverProfile.isNotEmpty()) {
            "\n\nPERFIL DEL CONDUCTOR (lo que sabes de viajes anteriores):\n$driverProfile"
        } else {
            "\n\nConductor nuevo. Adapta tu estilo según la conversación y aprende sus preferencias."
        }

        return prompt
    }

    suspend fun sendMessage(
        text: String,
        apiKey: String,
        model: GeminiModel,
        language: AppLanguage,
        driverProfile: String = "",
        hasPlacesKey: Boolean = false
    ): String = withContext(Dispatchers.IO) {
        if (apiKey.isEmpty()) throw GeminiError.NoAPIKey()

        val endpoint = "$baseURL${model.apiPath}?key=$apiKey"

        val userMsg = JSONObject().apply {
            put("role", "user")
            put("parts", JSONArray().put(JSONObject().put("text", text)))
        }
        conversationHistory.add(userMsg)

        val body = JSONObject().apply {
            put("contents", JSONArray(conversationHistory.map { it.toString() }.map { JSONObject(it) }))
            put("systemInstruction", JSONObject().apply {
                put("parts", JSONArray().put(JSONObject().put("text",
                    buildSystemPrompt(language, driverProfile, hasPlacesKey))))
            })
            put("generationConfig", JSONObject().apply {
                put("maxOutputTokens", 256)
                put("temperature", 0.7)
            })
        }

        val trimmedResponse = makeRequest(endpoint, body)

        val modelMsg = JSONObject().apply {
            put("role", "model")
            put("parts", JSONArray().put(JSONObject().put("text", trimmedResponse)))
        }
        conversationHistory.add(modelMsg)

        // Keep history manageable (last 40 messages for better context)
        if (conversationHistory.size > 40) {
            val keep = conversationHistory.takeLast(40)
            conversationHistory.clear()
            conversationHistory.addAll(keep)
        }

        trimmedResponse
    }

    suspend fun extractDriverProfile(
        currentProfile: String,
        apiKey: String,
        model: GeminiModel
    ): String = withContext(Dispatchers.IO) {
        if (apiKey.isEmpty()) throw GeminiError.NoAPIKey()

        val endpoint = "$baseURL${model.apiPath}?key=$apiKey"

        val extractionPrompt = "Analiza nuestra conversación y actualiza el perfil del conductor. " +
                "Incluye solo información confirmada:\n" +
                "- Nombre o apodo (si lo mencionó)\n" +
                "- Intereses y temas favoritos\n" +
                "- Estilo de humor preferido (qué tipo de chistes le gustan)\n" +
                "- Destinos o rutas frecuentes\n" +
                "- Cualquier dato personal relevante\n\n" +
                "Perfil actual: ${if (currentProfile.isEmpty()) "Nuevo conductor, sin perfil aún." else currentProfile}\n\n" +
                "Responde SOLO con el perfil actualizado en texto breve (máximo 150 palabras). " +
                "No incluyas explicaciones ni saludos."

        val tempHistory = conversationHistory.map { JSONObject(it.toString()) }.toMutableList()
        tempHistory.add(JSONObject().apply {
            put("role", "user")
            put("parts", JSONArray().put(JSONObject().put("text", extractionPrompt)))
        })

        val body = JSONObject().apply {
            put("contents", JSONArray(tempHistory.map { it.toString() }.map { JSONObject(it) }))
            put("generationConfig", JSONObject().apply {
                put("maxOutputTokens", 300)
                put("temperature", 0.3)
            })
        }

        makeRequest(endpoint, body)
    }

    private fun makeRequest(endpoint: String, body: JSONObject): String {
        try {
            val url = URL(endpoint)
            val connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                setRequestProperty("Content-Type", "application/json")
                connectTimeout = 30_000
                readTimeout = 30_000
                doOutput = true
            }

            OutputStreamWriter(connection.outputStream).use { writer ->
                writer.write(body.toString())
                writer.flush()
            }

            val statusCode = connection.responseCode

            if (statusCode == 429) {
                throw GeminiError.RateLimited()
            }

            if (statusCode !in 200..299) {
                throw GeminiError.HttpError(statusCode)
            }

            val responseBody = connection.inputStream.bufferedReader().use { it.readText() }
            connection.disconnect()

            val json = JSONObject(responseBody)
            val candidates = json.optJSONArray("candidates")
            val firstCandidate = candidates?.optJSONObject(0)
            val content = firstCandidate?.optJSONObject("content")
            val parts = content?.optJSONArray("parts")
            val responseText = parts?.optJSONObject(0)?.optString("text")

            if (responseText.isNullOrBlank()) {
                throw GeminiError.DecodingError()
            }

            return responseText.trim()
        } catch (e: GeminiError) {
            throw e
        } catch (e: Exception) {
            throw GeminiError.NetworkError(e)
        }
    }
}

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

    private fun buildSystemPrompt(language: AppLanguage, driverProfile: String): String {
        val lang = language.systemPromptLanguage

        var prompt = "Eres DriveMate, un copiloto de voz inteligente para conductores. " +
                "Responde siempre en $lang.\n\n" +
                "PERSONALIDAD Y HUMOR:\n" +
                "- Eres como un amigo ingenioso que va de copiloto. Cercano, divertido y con chispa.\n" +
                "- Usa humor natural: chistes cortos, juegos de palabras, datos curiosos graciosos.\n" +
                "- Adapta tu estilo de humor según lo que le guste al conductor.\n" +
                "- Puedes lanzar trivias o curiosidades para amenizar el viaje.\n" +
                "- Si el conductor está de buen humor, sé más bromista. Si está serio, sé más directo.\n\n" +
                "REGLAS DE RESPUESTA:\n" +
                "- Máximo 2-3 frases. Tus respuestas se leen en voz alta mientras conduce.\n" +
                "- Sé directo, claro y natural. Nada de listas largas ni formato markdown.\n" +
                "- Recuerda detalles de la conversación actual y úsalos para personalizar.\n\n" +
                "SEGURIDAD VIAL (PRIORIDAD MÁXIMA):\n" +
                "- Nunca sugieras que el conductor mire la pantalla, escriba o haga algo que distraiga.\n" +
                "- Si detectas una emergencia, recomienda detenerse en un lugar seguro o llamar al 112/911.\n" +
                "- No des indicaciones de navegación paso a paso (para eso está el GPS).\n\n" +
                "CAPACIDADES:\n" +
                "- Conversación general, curiosidades, noticias, cultura.\n" +
                "- Orientación sobre rutas y destinos (sin reemplazar al GPS).\n" +
                "- Entretenimiento: chistes, juegos de palabras, trivias para amenizar el viaje.\n" +
                "- Información práctica: clima, gasolineras, restaurantes, horarios.\n" +
                "- Ayuda con cálculos rápidos, traducciones y definiciones.\n\n" +
                "Si no sabes algo, dilo honestamente. Nunca inventes datos críticos."

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
        driverProfile: String = ""
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
                    buildSystemPrompt(language, driverProfile))))
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

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

    suspend fun sendMessage(
        text: String,
        apiKey: String,
        model: GeminiModel,
        language: AppLanguage
    ): String = withContext(Dispatchers.IO) {
        if (apiKey.isEmpty()) throw GeminiError.NoAPIKey()

        val endpoint = "$baseURL${model.apiPath}?key=$apiKey"

        // Add user message to history
        val userMsg = JSONObject().apply {
            put("role", "user")
            put("parts", JSONArray().put(JSONObject().put("text", text)))
        }
        conversationHistory.add(userMsg)

        val systemPrompt = "Eres un copiloto de voz para conductores llamado DriveMate. " +
                "Responde de forma concisa, clara y útil en ${language.systemPromptLanguage}. " +
                "Mantén las respuestas cortas (1-3 frases) porque serán leídas en voz alta " +
                "mientras el usuario conduce. Puedes ayudar con navegación, información general, " +
                "entretenimiento, y cualquier consulta. Sé amigable y natural."

        val body = JSONObject().apply {
            put("contents", JSONArray(conversationHistory.map { it.toString() }.map { JSONObject(it) }))
            put("systemInstruction", JSONObject().apply {
                put("parts", JSONArray().put(JSONObject().put("text", systemPrompt)))
            })
            put("generationConfig", JSONObject().apply {
                put("maxOutputTokens", 256)
                put("temperature", 0.7)
            })
        }

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
                conversationHistory.removeLast()
                throw GeminiError.RateLimited()
            }

            if (statusCode !in 200..299) {
                conversationHistory.removeLast()
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
                conversationHistory.removeLast()
                throw GeminiError.DecodingError()
            }

            val trimmedResponse = responseText.trim()

            // Add model response to history
            val modelMsg = JSONObject().apply {
                put("role", "model")
                put("parts", JSONArray().put(JSONObject().put("text", trimmedResponse)))
            }
            conversationHistory.add(modelMsg)

            // Keep history manageable (last 20 messages)
            if (conversationHistory.size > 20) {
                val keep = conversationHistory.takeLast(20)
                conversationHistory.clear()
                conversationHistory.addAll(keep)
            }

            trimmedResponse
        } catch (e: GeminiError) {
            throw e
        } catch (e: Exception) {
            conversationHistory.removeLast()
            throw GeminiError.NetworkError(e)
        }
    }
}

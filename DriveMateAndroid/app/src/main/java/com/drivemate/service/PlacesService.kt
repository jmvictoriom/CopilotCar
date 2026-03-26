package com.drivemate.service

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.io.OutputStreamWriter

data class PlaceResult(
    val id: String,
    val displayName: String,
    val formattedAddress: String?,
    val rating: Double?
)

data class PlacePhone(
    val nationalPhone: String?,
    val internationalPhone: String?
)

class PlacesService {

    private val baseURL = "https://places.googleapis.com/v1/"

    sealed class PlacesError(message: String) : Exception(message) {
        class NoAPIKey : PlacesError("No se ha configurado la API Key de Google Places.")
        class HttpError(val code: Int) : PlacesError("Error HTTP Places: $code")
        class NoResults : PlacesError("No se encontraron lugares.")
        class NetworkError(cause: Throwable) : PlacesError("Error de red: ${cause.localizedMessage}")
        class DecodingError : PlacesError("Error al procesar resultados de Places.")
    }

    suspend fun searchPlaces(query: String, apiKey: String): List<PlaceResult> = withContext(Dispatchers.IO) {
        if (apiKey.isEmpty()) throw PlacesError.NoAPIKey()

        val body = JSONObject().apply {
            put("textQuery", query)
            put("maxResultCount", 3)
        }

        try {
            val url = URL("${baseURL}places:searchText")
            val connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("X-Goog-Api-Key", apiKey)
                setRequestProperty(
                    "X-Goog-FieldMask",
                    "places.displayName,places.formattedAddress,places.rating,places.id"
                )
                connectTimeout = 15_000
                readTimeout = 15_000
                doOutput = true
            }

            OutputStreamWriter(connection.outputStream).use { writer ->
                writer.write(body.toString())
                writer.flush()
            }

            val statusCode = connection.responseCode
            if (statusCode !in 200..299) {
                throw PlacesError.HttpError(statusCode)
            }

            val responseBody = connection.inputStream.bufferedReader().use { it.readText() }
            connection.disconnect()

            val json = JSONObject(responseBody)
            val placesArray = json.optJSONArray("places") ?: throw PlacesError.NoResults()
            if (placesArray.length() == 0) throw PlacesError.NoResults()

            val results = mutableListOf<PlaceResult>()
            for (i in 0 until placesArray.length()) {
                val place = placesArray.getJSONObject(i)
                val id = place.optString("id", "")
                val displayNameObj = place.optJSONObject("displayName")
                val name = displayNameObj?.optString("text", "") ?: ""
                if (id.isEmpty() || name.isEmpty()) continue

                results.add(
                    PlaceResult(
                        id = id,
                        displayName = name,
                        formattedAddress = place.optString("formattedAddress", null),
                        rating = if (place.has("rating")) place.getDouble("rating") else null
                    )
                )
            }
            results
        } catch (e: PlacesError) {
            throw e
        } catch (e: Exception) {
            throw PlacesError.NetworkError(e)
        }
    }

    suspend fun getPhoneNumber(placeId: String, apiKey: String): PlacePhone = withContext(Dispatchers.IO) {
        if (apiKey.isEmpty()) throw PlacesError.NoAPIKey()

        try {
            val url = URL("${baseURL}places/$placeId")
            val connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                setRequestProperty("X-Goog-Api-Key", apiKey)
                setRequestProperty(
                    "X-Goog-FieldMask",
                    "nationalPhoneNumber,internationalPhoneNumber"
                )
                connectTimeout = 10_000
                readTimeout = 10_000
            }

            val statusCode = connection.responseCode
            if (statusCode !in 200..299) {
                throw PlacesError.HttpError(statusCode)
            }

            val responseBody = connection.inputStream.bufferedReader().use { it.readText() }
            connection.disconnect()

            val json = JSONObject(responseBody)
            PlacePhone(
                nationalPhone = json.optString("nationalPhoneNumber", null),
                internationalPhone = json.optString("internationalPhoneNumber", null)
            )
        } catch (e: PlacesError) {
            throw e
        } catch (e: Exception) {
            throw PlacesError.NetworkError(e)
        }
    }
}

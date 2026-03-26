package com.drivemate.service

import android.content.Context
import android.content.Intent
import android.net.Uri
import com.drivemate.model.AppSettings
import com.drivemate.model.Message
import com.drivemate.model.MessageRole
import com.drivemate.model.PlaceAction
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

enum class ConversationState {
    IDLE, LISTENING, PROCESSING, SPEAKING
}

class ConversationManager(
    private val context: Context,
    val settings: AppSettings,
    val speechRecognizer: SpeechRecognizerService,
    val geminiService: GeminiService,
    val speechSynthesizer: SpeechSynthesizerService,
    val placesService: PlacesService = PlacesService()
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val _messages = MutableStateFlow<List<Message>>(emptyList())
    val messages: StateFlow<List<Message>> = _messages.asStateFlow()

    private val _state = MutableStateFlow(ConversationState.IDLE)
    val state: StateFlow<ConversationState> = _state.asStateFlow()

    private val _currentTranscription = MutableStateFlow("")
    val currentTranscription: StateFlow<String> = _currentTranscription.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    val stateLabel: String
        get() = when (_state.value) {
            ConversationState.IDLE -> "Toca para hablar"
            ConversationState.LISTENING -> "Escuchando..."
            ConversationState.PROCESSING -> "Pensando..."
            ConversationState.SPEAKING -> "Hablando..."
        }

    fun toggleListening() {
        when (_state.value) {
            ConversationState.IDLE -> startListening()
            ConversationState.LISTENING -> {
                speechRecognizer.stopListening()
                _state.value = ConversationState.IDLE
            }
            ConversationState.SPEAKING -> {
                speechSynthesizer.stop()
                _state.value = ConversationState.IDLE
            }
            ConversationState.PROCESSING -> { /* no-op */ }
        }
    }

    fun startListening() {
        val apiKey = settings.geminiAPIKey.value
        if (apiKey.isEmpty()) {
            _errorMessage.value = "Configura tu API Key de Gemini en Ajustes."
            return
        }

        if (!speechRecognizer.isAvailable) {
            _errorMessage.value = "Reconocimiento de voz no disponible en este dispositivo."
            return
        }

        _errorMessage.value = null
        _state.value = ConversationState.LISTENING
        _currentTranscription.value = ""

        speechRecognizer.startListening(
            locale = settings.language.value.locale,
            onPartialResult = { partial ->
                _currentTranscription.value = partial
            },
            onFinalResult = { finalText ->
                handleSpeechResult(finalText)
            }
        )
    }

    private fun handleSpeechResult(text: String) {
        if (text.isEmpty()) {
            _state.value = ConversationState.IDLE
            return
        }

        val userMessage = Message(role = MessageRole.USER, content = text)
        _messages.value = _messages.value + userMessage
        _state.value = ConversationState.PROCESSING
        _currentTranscription.value = ""

        scope.launch {
            sendToGemini(text)
        }
    }

    private suspend fun sendToGemini(text: String) {
        try {
            val response = geminiService.sendMessage(
                text = text,
                apiKey = settings.geminiAPIKey.value,
                model = settings.geminiModel.value,
                language = settings.language.value,
                driverProfile = settings.driverProfile.value,
                hasPlacesKey = settings.placesAPIKey.value.isNotEmpty()
            )
            val parsed = ResponseParser.parse(response)

            if (parsed.searchQuery != null && settings.placesAPIKey.value.isNotEmpty()) {
                val searchingMessage = Message(role = MessageRole.ASSISTANT, content = parsed.cleanText)
                _messages.value = _messages.value + searchingMessage
                speakResponse(parsed.cleanText)

                scope.launch { handlePlaceSearch(parsed.searchQuery) }
            } else {
                val assistantMessage = Message(role = MessageRole.ASSISTANT, content = parsed.cleanText)
                _messages.value = _messages.value + assistantMessage
                speakResponse(parsed.cleanText)
            }

            // Extract driver profile every 10 messages
            if (_messages.value.size % 10 == 0) {
                scope.launch { updateDriverProfile() }
            }
        } catch (e: Exception) {
            _state.value = ConversationState.IDLE
            _errorMessage.value = e.message ?: "Error desconocido"
        }
    }

    private suspend fun handlePlaceSearch(query: String) {
        try {
            val results = placesService.searchPlaces(query, settings.placesAPIKey.value)

            val actions = results.map { place ->
                PlaceAction(
                    id = place.id,
                    placeName = place.displayName,
                    address = place.formattedAddress,
                    rating = place.rating,
                    placeId = place.id
                )
            }

            val summary = results.mapIndexed { i, place ->
                var line = "${i + 1}. ${place.displayName}"
                if (place.rating != null) {
                    line += ", ${"%.1f".format(place.rating)} estrellas"
                }
                line
            }.joinToString(". ")

            val resultsMessage = Message(
                role = MessageRole.ASSISTANT,
                content = "Encontré ${results.size} resultados:\n$summary",
                actions = actions
            )
            _messages.value = _messages.value + resultsMessage

            geminiService.injectMessage("model", "Resultados de búsqueda: $summary")

            speakResponse("Encontré ${results.size} resultados. $summary. Puedes tocar llamar en cualquiera.")
        } catch (e: Exception) {
            val errorMsg = Message(
                role = MessageRole.ASSISTANT,
                content = "No pude encontrar resultados: ${e.message}"
            )
            _messages.value = _messages.value + errorMsg
            speakResponse("No pude encontrar resultados.")
        }
    }

    fun callPlace(action: PlaceAction) {
        scope.launch {
            try {
                val phone = placesService.getPhoneNumber(action.placeId, settings.placesAPIKey.value)
                val number = phone.internationalPhone ?: phone.nationalPhone
                if (number == null) {
                    _errorMessage.value = "${action.placeName} no tiene teléfono registrado."
                    return@launch
                }
                openDialer(number)
            } catch (e: Exception) {
                _errorMessage.value = "No se pudo obtener el teléfono: ${e.message}"
            }
        }
    }

    private fun openDialer(number: String) {
        val cleaned = number.replace(" ", "")
        val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$cleaned")).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
    }

    private suspend fun updateDriverProfile() {
        try {
            val profile = geminiService.extractDriverProfile(
                currentProfile = settings.driverProfile.value,
                apiKey = settings.geminiAPIKey.value,
                model = settings.geminiModel.value
            )
            settings.setDriverProfile(profile)
        } catch (_: Exception) {
            // Profile extraction is best-effort, don't show errors
        }
    }

    private fun speakResponse(text: String) {
        _state.value = ConversationState.SPEAKING
        speechSynthesizer.speak(
            text = text,
            locale = settings.language.value.locale,
            rate = settings.speechRate.value,
            onFinished = {
                if (settings.handsFreeMode.value) {
                    startListening()
                } else {
                    _state.value = ConversationState.IDLE
                }
            }
        )
    }

    fun clearConversation() {
        // Extract profile before clearing if there's enough conversation
        if (_messages.value.size >= 4) {
            scope.launch {
                updateDriverProfile()
                geminiService.clearHistory()
            }
        } else {
            geminiService.clearHistory()
        }
        _messages.value = emptyList()
    }

    fun dismissError() {
        _errorMessage.value = null
    }
}

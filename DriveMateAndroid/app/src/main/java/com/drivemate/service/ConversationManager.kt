package com.drivemate.service

import com.drivemate.model.AppSettings
import com.drivemate.model.Message
import com.drivemate.model.MessageRole
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
    val settings: AppSettings,
    val speechRecognizer: SpeechRecognizerService,
    val geminiService: GeminiService,
    val speechSynthesizer: SpeechSynthesizerService
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
                language = settings.language.value
            )
            val assistantMessage = Message(role = MessageRole.ASSISTANT, content = response)
            _messages.value = _messages.value + assistantMessage
            speakResponse(response)
        } catch (e: Exception) {
            _state.value = ConversationState.IDLE
            _errorMessage.value = e.message ?: "Error desconocido"
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
        _messages.value = emptyList()
        geminiService.clearHistory()
    }

    fun dismissError() {
        _errorMessage.value = null
    }
}

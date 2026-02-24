package com.drivemate.service

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Locale

class SpeechSynthesizerService(context: Context) {

    private var tts: TextToSpeech? = null
    private var isInitialized = false
    private var onFinished: (() -> Unit)? = null

    private val _isSpeaking = MutableStateFlow(false)
    val isSpeaking: StateFlow<Boolean> = _isSpeaking.asStateFlow()

    init {
        tts = TextToSpeech(context) { status ->
            isInitialized = status == TextToSpeech.SUCCESS
        }

        tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {
                _isSpeaking.value = true
            }

            override fun onDone(utteranceId: String?) {
                _isSpeaking.value = false
                onFinished?.invoke()
                onFinished = null
            }

            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String?) {
                _isSpeaking.value = false
                onFinished = null
            }
        })
    }

    fun speak(text: String, locale: String, rate: Float, onFinished: (() -> Unit)? = null) {
        stop()
        if (!isInitialized) return

        this.onFinished = onFinished

        val parts = locale.split("-")
        val ttsLocale = if (parts.size >= 2) Locale(parts[0], parts[1]) else Locale(parts[0])
        tts?.language = ttsLocale
        tts?.setSpeechRate(rate)

        _isSpeaking.value = true
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "drivemate_utterance")
    }

    fun stop() {
        if (tts?.isSpeaking == true) {
            tts?.stop()
        }
        _isSpeaking.value = false
        onFinished = null
    }

    fun destroy() {
        stop()
        tts?.shutdown()
        tts = null
    }
}

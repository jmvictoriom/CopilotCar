package com.drivemate

import android.app.Application
import com.drivemate.model.AppSettings
import com.drivemate.service.ConversationManager
import com.drivemate.service.GeminiService
import com.drivemate.service.PlacesService
import com.drivemate.service.SpeechRecognizerService
import com.drivemate.service.SpeechSynthesizerService

class DriveMateApp : Application() {

    lateinit var settings: AppSettings
    lateinit var conversationManager: ConversationManager

    override fun onCreate() {
        super.onCreate()
        settings = AppSettings(this)
        val speechRecognizer = SpeechRecognizerService(this)
        val geminiService = GeminiService()
        val speechSynthesizer = SpeechSynthesizerService(this)
        val placesService = PlacesService()
        conversationManager = ConversationManager(
            context = this,
            settings = settings,
            speechRecognizer = speechRecognizer,
            geminiService = geminiService,
            speechSynthesizer = speechSynthesizer,
            placesService = placesService
        )
    }
}

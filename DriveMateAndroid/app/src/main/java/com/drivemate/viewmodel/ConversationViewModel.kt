package com.drivemate.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.drivemate.DriveMateApp
import com.drivemate.model.Message
import com.drivemate.service.ConversationManager
import com.drivemate.service.ConversationState
import kotlinx.coroutines.flow.StateFlow

class ConversationViewModel(application: Application) : AndroidViewModel(application) {

    private val manager: ConversationManager =
        (application as DriveMateApp).conversationManager

    val settings get() = manager.settings
    val speechRecognizer get() = manager.speechRecognizer
    val geminiService get() = manager.geminiService
    val speechSynthesizer get() = manager.speechSynthesizer

    val messages: StateFlow<List<Message>> = manager.messages
    val state: StateFlow<ConversationState> = manager.state
    val currentTranscription: StateFlow<String> = manager.currentTranscription
    val errorMessage: StateFlow<String?> = manager.errorMessage

    val stateLabel: String get() = manager.stateLabel

    fun toggleListening() = manager.toggleListening()
    fun startListening() = manager.startListening()
    fun clearConversation() = manager.clearConversation()
    fun dismissError() = manager.dismissError()
}

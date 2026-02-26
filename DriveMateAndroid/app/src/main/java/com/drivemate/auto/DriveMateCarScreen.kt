package com.drivemate.auto

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.Action
import androidx.car.app.model.CarIcon
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.core.graphics.drawable.IconCompat
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.drivemate.DriveMateApp
import com.drivemate.R
import com.drivemate.service.ConversationManager
import com.drivemate.service.ConversationState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch

class DriveMateCarScreen(carContext: CarContext) : Screen(carContext) {

    private val conversationManager: ConversationManager =
        (carContext.applicationContext as DriveMateApp).conversationManager

    private val scope = CoroutineScope(Dispatchers.Main)
    private var observeJob: Job? = null

    init {
        lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onStart(owner: LifecycleOwner) {
                observeJob = scope.launch {
                    combine(
                        conversationManager.state,
                        conversationManager.messages
                    ) { state, messages -> state to messages }.collectLatest {
                        invalidate()
                    }
                }
            }

            override fun onStop(owner: LifecycleOwner) {
                observeJob?.cancel()
                observeJob = null
            }
        })
    }

    override fun onGetTemplate(): Template {
        val currentState = conversationManager.state.value
        val messages = conversationManager.messages.value

        val statusText = when (currentState) {
            ConversationState.IDLE -> "Toca para hablar"
            ConversationState.LISTENING -> "Escuchando..."
            ConversationState.PROCESSING -> "Pensando..."
            ConversationState.SPEAKING -> "Hablando..."
        }

        val lastMessage = messages.lastOrNull()?.content ?: "Sin mensajes aún"

        val statusRow = Row.Builder()
            .setTitle(statusText)
            .addText(lastMessage)
            .build()

        val micIcon = CarIcon.Builder(
            IconCompat.createWithResource(carContext, R.drawable.ic_mic)
        ).build()

        val actionTitle = if (currentState == ConversationState.LISTENING ||
            currentState == ConversationState.SPEAKING) "Detener" else "Hablar"

        val talkAction = Action.Builder()
            .setTitle(actionTitle)
            .setIcon(micIcon)
            .setOnClickListener { conversationManager.toggleListening() }
            .build()

        val paneBuilder = Pane.Builder()

        if (currentState == ConversationState.PROCESSING) {
            paneBuilder.setLoading(true)
        } else {
            paneBuilder.addRow(statusRow)
            paneBuilder.addAction(talkAction)
        }

        return PaneTemplate.Builder(paneBuilder.build())
            .setTitle("DriveMate")
            .setHeaderAction(Action.APP_ICON)
            .build()
    }
}

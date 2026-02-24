package com.drivemate.model

import java.util.Date
import java.util.UUID

enum class MessageRole {
    USER, ASSISTANT
}

data class Message(
    val id: String = UUID.randomUUID().toString(),
    val role: MessageRole,
    val content: String,
    val timestamp: Date = Date()
)

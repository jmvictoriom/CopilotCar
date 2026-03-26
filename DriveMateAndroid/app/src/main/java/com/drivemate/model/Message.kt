package com.drivemate.model

import java.util.Date
import java.util.UUID

enum class MessageRole {
    USER, ASSISTANT
}

data class PlaceAction(
    val id: String,
    val placeName: String,
    val address: String? = null,
    val rating: Double? = null,
    val placeId: String,
    val phoneNumber: String? = null
)

data class Message(
    val id: String = UUID.randomUUID().toString(),
    val role: MessageRole,
    val content: String,
    val timestamp: Date = Date(),
    val actions: List<PlaceAction> = emptyList()
)

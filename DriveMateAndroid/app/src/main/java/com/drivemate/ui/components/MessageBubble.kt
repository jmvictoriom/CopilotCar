package com.drivemate.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.drivemate.model.Message
import com.drivemate.model.MessageRole
import com.drivemate.model.PlaceAction
import com.drivemate.ui.theme.AssistantBubbleDark
import com.drivemate.ui.theme.AssistantBubbleLight
import com.drivemate.ui.theme.UserBubble
import java.text.SimpleDateFormat
import java.util.Locale

@Composable
fun MessageBubble(
    message: Message,
    onCallPlace: ((PlaceAction) -> Unit)? = null
) {
    val isUser = message.role == MessageRole.USER
    val isDark = isSystemInDarkTheme()
    val bubbleColor = if (isUser) UserBubble else if (isDark) AssistantBubbleDark else AssistantBubbleLight
    val textColor = if (isUser) Color.White else MaterialTheme.colorScheme.onSurface
    val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start
    ) {
        if (isUser) Spacer(modifier = Modifier.weight(0.2f))

        Column(
            modifier = Modifier.widthIn(max = 300.dp),
            horizontalAlignment = if (isUser) Alignment.End else Alignment.Start
        ) {
            Text(
                text = message.content,
                color = textColor,
                style = MaterialTheme.typography.bodyLarge,
                modifier = Modifier
                    .clip(RoundedCornerShape(18.dp))
                    .background(bubbleColor)
                    .padding(horizontal = 14.dp, vertical = 10.dp)
            )

            if (message.actions.isNotEmpty()) {
                Spacer(modifier = Modifier.height(6.dp))
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    message.actions.forEach { action ->
                        Button(
                            onClick = { onCallPlace?.invoke(action) },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Color(0xFF4CAF50)
                            ),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Phone,
                                contentDescription = "Llamar",
                                modifier = Modifier.size(16.dp),
                                tint = Color.White
                            )
                            Spacer(modifier = Modifier.size(6.dp))
                            Column {
                                Text(
                                    text = action.placeName,
                                    style = MaterialTheme.typography.labelMedium,
                                    color = Color.White
                                )
                                if (action.rating != null) {
                                    Text(
                                        text = "${"%.1f".format(action.rating)} estrellas",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color.White.copy(alpha = 0.8f)
                                    )
                                }
                            }
                        }
                    }
                }
            }

            Text(
                text = timeFormat.format(message.timestamp),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
            )
        }

        if (!isUser) Spacer(modifier = Modifier.weight(0.2f))
    }
}

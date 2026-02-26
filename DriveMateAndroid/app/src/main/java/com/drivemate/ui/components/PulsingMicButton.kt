package com.drivemate.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.drivemate.ui.theme.Blue600
import com.drivemate.ui.theme.Blue800
import com.drivemate.ui.theme.Green500
import com.drivemate.ui.theme.Orange500
import com.drivemate.ui.theme.Red500
import com.drivemate.service.ConversationState

@Composable
fun PulsingMicButton(
    state: ConversationState,
    onClick: () -> Unit
) {
    val buttonColor by animateColorAsState(
        targetValue = when (state) {
            ConversationState.IDLE -> Blue600
            ConversationState.LISTENING -> Red500
            ConversationState.PROCESSING -> Orange500
            ConversationState.SPEAKING -> Green500
        },
        animationSpec = tween(300),
        label = "buttonColor"
    )

    val icon = when (state) {
        ConversationState.IDLE -> Icons.Filled.Mic
        ConversationState.LISTENING -> Icons.Filled.Mic
        ConversationState.PROCESSING -> Icons.Filled.Psychology
        ConversationState.SPEAKING -> Icons.Filled.GraphicEq
    }

    val infiniteTransition = rememberInfiniteTransition(label = "pulse")

    Box(contentAlignment = Alignment.Center) {
        // Pulse rings when listening
        if (state == ConversationState.LISTENING) {
            for (i in 0..2) {
                val scale by infiniteTransition.animateFloat(
                    initialValue = 0.9f,
                    targetValue = 1.3f + i * 0.15f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(
                            durationMillis = 1500,
                            delayMillis = i * 300,
                            easing = FastOutSlowInEasing
                        ),
                        repeatMode = RepeatMode.Restart
                    ),
                    label = "pulseScale$i"
                )
                val alpha by infiniteTransition.animateFloat(
                    initialValue = 0.4f,
                    targetValue = 0f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(
                            durationMillis = 1500,
                            delayMillis = i * 300,
                            easing = FastOutSlowInEasing
                        ),
                        repeatMode = RepeatMode.Restart
                    ),
                    label = "pulseAlpha$i"
                )

                Box(
                    modifier = Modifier
                        .size((100 + i * 30).dp)
                        .scale(scale)
                        .border(
                            width = 2.dp,
                            color = buttonColor.copy(alpha = alpha),
                            shape = CircleShape
                        )
                )
            }
        }

        // Main button
        Box(
            modifier = Modifier
                .size(90.dp)
                .shadow(10.dp, CircleShape, spotColor = buttonColor.copy(alpha = 0.5f))
                .clip(CircleShape)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(buttonColor, buttonColor.copy(alpha = 0.8f))
                    )
                )
                .clickable(onClick = onClick),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = "Micrófono",
                tint = Color.White,
                modifier = Modifier.size(36.dp)
            )
        }
    }
}

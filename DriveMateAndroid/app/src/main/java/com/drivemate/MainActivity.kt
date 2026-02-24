package com.drivemate

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.drivemate.ui.MainScreen
import com.drivemate.ui.SettingsScreen
import com.drivemate.ui.theme.DriveMateTheme
import com.drivemate.viewmodel.ConversationViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            val viewModel: ConversationViewModel = viewModel()
            val forceDarkMode by viewModel.settings.forceDarkMode.collectAsState()

            DriveMateTheme(forceDarkMode = forceDarkMode) {
                val navController = rememberNavController()

                NavHost(navController = navController, startDestination = "main") {
                    composable("main") {
                        MainScreen(
                            viewModel = viewModel,
                            onNavigateToSettings = { navController.navigate("settings") }
                        )
                    }
                    composable("settings") {
                        SettingsScreen(
                            settings = viewModel.settings,
                            onBack = { navController.popBackStack() }
                        )
                    }
                }
            }
        }
    }
}

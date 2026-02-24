package com.drivemate.model

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class AppSettings(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("drivemate_settings", Context.MODE_PRIVATE)

    private val _language = MutableStateFlow(
        AppLanguage.fromLocale(prefs.getString("language", AppLanguage.SPANISH.locale)!!)
    )
    val language: StateFlow<AppLanguage> = _language.asStateFlow()

    private val _geminiAPIKey = MutableStateFlow(prefs.getString("geminiAPIKey", "") ?: "")
    val geminiAPIKey: StateFlow<String> = _geminiAPIKey.asStateFlow()

    private val _geminiModel = MutableStateFlow(
        GeminiModel.fromId(prefs.getString("geminiModel", GeminiModel.FLASH_20.modelId)!!)
    )
    val geminiModel: StateFlow<GeminiModel> = _geminiModel.asStateFlow()

    private val _speechRate = MutableStateFlow(prefs.getFloat("speechRate", 1.0f))
    val speechRate: StateFlow<Float> = _speechRate.asStateFlow()

    private val _handsFreeMode = MutableStateFlow(prefs.getBoolean("handsFreeMode", false))
    val handsFreeMode: StateFlow<Boolean> = _handsFreeMode.asStateFlow()

    private val _forceDarkMode = MutableStateFlow(prefs.getBoolean("forceDarkMode", true))
    val forceDarkMode: StateFlow<Boolean> = _forceDarkMode.asStateFlow()

    fun setLanguage(value: AppLanguage) {
        _language.value = value
        prefs.edit().putString("language", value.locale).apply()
    }

    fun setGeminiAPIKey(value: String) {
        _geminiAPIKey.value = value
        prefs.edit().putString("geminiAPIKey", value).apply()
    }

    fun setGeminiModel(value: GeminiModel) {
        _geminiModel.value = value
        prefs.edit().putString("geminiModel", value.modelId).apply()
    }

    fun setSpeechRate(value: Float) {
        _speechRate.value = value
        prefs.edit().putFloat("speechRate", value).apply()
    }

    fun setHandsFreeMode(value: Boolean) {
        _handsFreeMode.value = value
        prefs.edit().putBoolean("handsFreeMode", value).apply()
    }

    fun setForceDarkMode(value: Boolean) {
        _forceDarkMode.value = value
        prefs.edit().putBoolean("forceDarkMode", value).apply()
    }
}

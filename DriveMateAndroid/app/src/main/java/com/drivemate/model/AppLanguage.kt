package com.drivemate.model

enum class AppLanguage(
    val locale: String,
    val displayName: String,
    val systemPromptLanguage: String
) {
    SPANISH("es-ES", "Español", "español"),
    ENGLISH("en-US", "English", "English"),
    FRENCH("fr-FR", "Français", "français"),
    GERMAN("de-DE", "Deutsch", "Deutsch"),
    PORTUGUESE("pt-BR", "Português", "português");

    companion object {
        fun fromLocale(locale: String): AppLanguage =
            entries.find { it.locale == locale } ?: SPANISH
    }
}

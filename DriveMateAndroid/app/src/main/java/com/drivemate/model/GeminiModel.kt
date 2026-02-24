package com.drivemate.model

enum class GeminiModel(
    val modelId: String,
    val displayName: String,
    val tierInfo: String
) {
    FLASH_15("gemini-1.5-flash", "Gemini 1.5 Flash", "Gratuito - Estable"),
    PRO_15("gemini-1.5-pro", "Gemini 1.5 Pro", "Gratuito - Estable"),
    FLASH_20("gemini-2.0-flash", "Gemini 2.0 Flash", "Gratuito - Recomendado"),
    FLASH_LITE_20("gemini-2.0-flash-lite", "Gemini 2.0 Flash Lite", "Gratuito - Ultra rápido"),
    FLASH_25("gemini-2.5-flash", "Gemini 2.5 Flash", "Gratuito - Mejor calidad/velocidad"),
    FLASH_LITE_25("gemini-2.5-flash-lite", "Gemini 2.5 Flash Lite", "Gratuito - Ligero"),
    PRO_25("gemini-2.5-pro", "Gemini 2.5 Pro", "Gratuito - Máxima calidad"),
    FLASH_3("gemini-3-flash-preview", "Gemini 3 Flash (Preview)", "Preview - Nueva generación"),
    PRO_3("gemini-3-pro-preview", "Gemini 3 Pro (Preview)", "Preview - Nueva generación"),
    PRO_31("gemini-3.1-pro-preview", "Gemini 3.1 Pro (Preview)", "Preview - Lo más nuevo");

    val apiPath: String get() = "models/$modelId:generateContent"

    companion object {
        fun fromId(id: String): GeminiModel =
            entries.find { it.modelId == id } ?: FLASH_20
    }
}

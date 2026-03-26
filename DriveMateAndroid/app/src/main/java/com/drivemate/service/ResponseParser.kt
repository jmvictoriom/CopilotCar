package com.drivemate.service

data class ParsedResponse(
    val cleanText: String,
    val searchQuery: String?,
    val callNumber: String?
)

object ResponseParser {

    private val searchPattern = Regex("""\[BUSCAR:(.+?)]""")
    private val callPattern = Regex("""\[LLAMAR:(.+?)]""")

    fun parse(text: String): ParsedResponse {
        val searchQuery = searchPattern.find(text)?.groupValues?.get(1)?.trim()
        val callNumber = callPattern.find(text)?.groupValues?.get(1)?.trim()

        var clean = text
        clean = searchPattern.replace(clean, "")
        clean = callPattern.replace(clean, "")
        clean = clean.trim()

        return ParsedResponse(
            cleanText = clean,
            searchQuery = searchQuery,
            callNumber = callNumber
        )
    }
}

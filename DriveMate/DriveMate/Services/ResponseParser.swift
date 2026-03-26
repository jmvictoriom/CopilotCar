import Foundation

struct ParsedResponse {
    let cleanText: String
    let searchQuery: String?
    let callNumber: String?
}

enum ResponseParser {

    private static let searchRegex = try! NSRegularExpression(pattern: "\\[BUSCAR:(.+?)\\]")
    private static let callRegex = try! NSRegularExpression(pattern: "\\[LLAMAR:(.+?)\\]")

    static func parse(_ text: String) -> ParsedResponse {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)

        var searchQuery: String?
        var callNumber: String?

        if let match = searchRegex.firstMatch(in: text, range: range) {
            searchQuery = nsText.substring(with: match.range(at: 1))
                .trimmingCharacters(in: .whitespaces)
        }

        if let match = callRegex.firstMatch(in: text, range: range) {
            callNumber = nsText.substring(with: match.range(at: 1))
                .trimmingCharacters(in: .whitespaces)
        }

        // Remove tags from visible text
        var clean = searchRegex.stringByReplacingMatches(
            in: text, range: range, withTemplate: ""
        )
        let cleanNS = clean as NSString
        clean = callRegex.stringByReplacingMatches(
            in: clean, range: NSRange(location: 0, length: cleanNS.length), withTemplate: ""
        )
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)

        return ParsedResponse(
            cleanText: clean,
            searchQuery: searchQuery,
            callNumber: callNumber
        )
    }
}

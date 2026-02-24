import XCTest
@testable import DriveMate

final class AppLanguageTests: XCTestCase {

    // MARK: - All Cases

    func testAllCasesCount() {
        XCTAssertEqual(AppLanguage.allCases.count, 5)
    }

    func testAllCasesContainsExpectedLanguages() {
        let cases = AppLanguage.allCases
        XCTAssertTrue(cases.contains(.spanish))
        XCTAssertTrue(cases.contains(.english))
        XCTAssertTrue(cases.contains(.french))
        XCTAssertTrue(cases.contains(.german))
        XCTAssertTrue(cases.contains(.portuguese))
    }

    // MARK: - Raw Values (Locale Codes)

    func testSpanishRawValue() {
        XCTAssertEqual(AppLanguage.spanish.rawValue, "es-ES")
    }

    func testEnglishRawValue() {
        XCTAssertEqual(AppLanguage.english.rawValue, "en-US")
    }

    func testFrenchRawValue() {
        XCTAssertEqual(AppLanguage.french.rawValue, "fr-FR")
    }

    func testGermanRawValue() {
        XCTAssertEqual(AppLanguage.german.rawValue, "de-DE")
    }

    func testPortugueseRawValue() {
        XCTAssertEqual(AppLanguage.portuguese.rawValue, "pt-BR")
    }

    // MARK: - Display Names

    func testSpanishDisplayName() {
        XCTAssertEqual(AppLanguage.spanish.displayName, "Español")
    }

    func testEnglishDisplayName() {
        XCTAssertEqual(AppLanguage.english.displayName, "English")
    }

    func testFrenchDisplayName() {
        XCTAssertEqual(AppLanguage.french.displayName, "Français")
    }

    func testGermanDisplayName() {
        XCTAssertEqual(AppLanguage.german.displayName, "Deutsch")
    }

    func testPortugueseDisplayName() {
        XCTAssertEqual(AppLanguage.portuguese.displayName, "Português")
    }

    // MARK: - System Prompt Languages

    func testSpanishSystemPromptLanguage() {
        XCTAssertEqual(AppLanguage.spanish.systemPromptLanguage, "español")
    }

    func testEnglishSystemPromptLanguage() {
        XCTAssertEqual(AppLanguage.english.systemPromptLanguage, "English")
    }

    func testFrenchSystemPromptLanguage() {
        XCTAssertEqual(AppLanguage.french.systemPromptLanguage, "français")
    }

    func testGermanSystemPromptLanguage() {
        XCTAssertEqual(AppLanguage.german.systemPromptLanguage, "Deutsch")
    }

    func testPortugueseSystemPromptLanguage() {
        XCTAssertEqual(AppLanguage.portuguese.systemPromptLanguage, "português")
    }

    // MARK: - Identifiable

    func testIdentifiableUsesRawValue() {
        for lang in AppLanguage.allCases {
            XCTAssertEqual(lang.id, lang.rawValue)
        }
    }

    // MARK: - Init from RawValue

    func testInitFromValidRawValue() {
        XCTAssertEqual(AppLanguage(rawValue: "es-ES"), .spanish)
        XCTAssertEqual(AppLanguage(rawValue: "en-US"), .english)
        XCTAssertEqual(AppLanguage(rawValue: "fr-FR"), .french)
        XCTAssertEqual(AppLanguage(rawValue: "de-DE"), .german)
        XCTAssertEqual(AppLanguage(rawValue: "pt-BR"), .portuguese)
    }

    func testInitFromInvalidRawValue() {
        XCTAssertNil(AppLanguage(rawValue: "xx-XX"))
        XCTAssertNil(AppLanguage(rawValue: ""))
        XCTAssertNil(AppLanguage(rawValue: "en-GB"))
    }
}

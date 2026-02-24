import XCTest
@testable import DriveMate

final class AppSettingsTests: XCTestCase {

    private var settings: AppSettings!
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "com.drivemate.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        settings = AppSettings(defaults: defaults)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        defaults = nil
        settings = nil
        super.tearDown()
    }

    // MARK: - Default Values

    func testDefaultLanguageIsSpanish() {
        XCTAssertEqual(settings.language, .spanish)
    }

    func testDefaultAPIKeyIsEmpty() {
        XCTAssertEqual(settings.geminiAPIKey, "")
    }

    func testDefaultSpeechRate() {
        XCTAssertEqual(settings.speechRate, 0.5, accuracy: 0.001)
    }

    func testDefaultHandsFreeModeIsOff() {
        XCTAssertFalse(settings.handsFreeMode)
    }

    func testDefaultForceDarkModeIsOn() {
        XCTAssertTrue(settings.forceDarkMode)
    }

    // MARK: - Persistence

    func testLanguagePersists() {
        settings.language = .english
        XCTAssertEqual(defaults.string(forKey: "language"), "en-US")

        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.language, .english)
    }

    func testAPIKeyPersists() {
        settings.geminiAPIKey = "my-secret-key"
        XCTAssertEqual(defaults.string(forKey: "geminiAPIKey"), "my-secret-key")

        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.geminiAPIKey, "my-secret-key")
    }

    func testSpeechRatePersists() {
        settings.speechRate = 0.3
        XCTAssertEqual(defaults.float(forKey: "speechRate"), 0.3, accuracy: 0.001)

        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.speechRate, 0.3, accuracy: 0.001)
    }

    func testHandsFreeModePersists() {
        settings.handsFreeMode = true
        XCTAssertTrue(defaults.bool(forKey: "handsFreeMode"))

        let reloaded = AppSettings(defaults: defaults)
        XCTAssertTrue(reloaded.handsFreeMode)
    }

    func testForceDarkModePersists() {
        settings.forceDarkMode = false
        XCTAssertFalse(defaults.bool(forKey: "forceDarkMode"))

        let reloaded = AppSettings(defaults: defaults)
        XCTAssertFalse(reloaded.forceDarkMode)
    }

    // MARK: - Language Cycling

    func testChangingLanguageThroughAllOptions() {
        for lang in AppLanguage.allCases {
            settings.language = lang
            XCTAssertEqual(settings.language, lang)
            XCTAssertEqual(defaults.string(forKey: "language"), lang.rawValue)
        }
    }

    // MARK: - Invalid Stored Language

    func testInvalidStoredLanguageFallsBackToSpanish() {
        defaults.set("invalid-locale", forKey: "language")
        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.language, .spanish)
    }

    // MARK: - Isolation

    func testDifferentSuitesAreIsolated() {
        settings.geminiAPIKey = "key-A"

        let otherSuite = "com.drivemate.tests.\(UUID().uuidString)"
        let otherDefaults = UserDefaults(suiteName: otherSuite)!
        let otherSettings = AppSettings(defaults: otherDefaults)

        XCTAssertEqual(otherSettings.geminiAPIKey, "")
        UserDefaults.standard.removePersistentDomain(forName: otherSuite)
    }
}

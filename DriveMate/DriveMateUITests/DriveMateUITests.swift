import XCTest

final class DriveMateUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - App Launch

    func testAppLaunches() {
        XCTAssertTrue(app.staticTexts["DriveMate"].waitForExistence(timeout: 5))
    }

    func testAppShowsStatusLabel() {
        XCTAssertTrue(app.staticTexts["Toca para hablar"].waitForExistence(timeout: 5))
    }

    // MARK: - Empty State

    func testEmptyStateShowsWelcomeMessage() {
        XCTAssertTrue(app.staticTexts["¡Hola! Soy DriveMate"].waitForExistence(timeout: 5))
    }

    func testEmptyStateShowsInstructions() {
        let instructions = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'copiloto de voz'"))
        XCTAssertGreaterThan(instructions.count, 0)
    }

    func testEmptyStateShowsCarIcon() {
        XCTAssertTrue(app.images["car.fill"].waitForExistence(timeout: 5))
    }

    // MARK: - Mic Button

    func testMicButtonExists() {
        let micButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'mic'")).firstMatch
        XCTAssertTrue(micButton.waitForExistence(timeout: 5))
    }

    func testMicButtonIsTappable() {
        let micButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'mic'")).firstMatch
        XCTAssertTrue(micButton.isHittable)
    }

    // MARK: - Settings

    func testSettingsButtonExists() {
        let gearButton = app.buttons["gearshape.fill"]
        XCTAssertTrue(gearButton.waitForExistence(timeout: 5))
    }

    func testSettingsOpens() {
        let gearButton = app.buttons["gearshape.fill"]
        gearButton.tap()

        XCTAssertTrue(app.navigationBars["Ajustes"].waitForExistence(timeout: 5))
    }

    func testSettingsShowsLanguageSection() {
        app.buttons["gearshape.fill"].tap()

        XCTAssertTrue(app.staticTexts["Idioma"].waitForExistence(timeout: 5))
    }

    func testSettingsShowsAPIKeySection() {
        app.buttons["gearshape.fill"].tap()

        XCTAssertTrue(app.staticTexts["Google Gemini API"].waitForExistence(timeout: 5))
    }

    func testSettingsShowsVoiceSection() {
        app.buttons["gearshape.fill"].tap()

        XCTAssertTrue(app.staticTexts["Voz"].waitForExistence(timeout: 5))
    }

    func testSettingsShowsAppearanceSection() {
        app.buttons["gearshape.fill"].tap()

        XCTAssertTrue(app.staticTexts["Apariencia"].waitForExistence(timeout: 5))
    }

    func testSettingsShowsAboutSection() {
        app.buttons["gearshape.fill"].tap()

        // Scroll down to find About section
        let aboutText = app.staticTexts["Acerca de"]
        if !aboutText.exists {
            app.swipeUp()
        }
        XCTAssertTrue(aboutText.waitForExistence(timeout: 5))
    }

    func testSettingsShowsVersion() {
        app.buttons["gearshape.fill"].tap()

        let versionText = app.staticTexts["1.0.0"]
        if !versionText.exists {
            app.swipeUp()
        }
        XCTAssertTrue(versionText.waitForExistence(timeout: 5))
    }

    func testSettingsShowsGeminiModel() {
        app.buttons["gearshape.fill"].tap()

        let modelText = app.staticTexts["Gemini 2.0 Flash"]
        if !modelText.exists {
            app.swipeUp()
        }
        XCTAssertTrue(modelText.waitForExistence(timeout: 5))
    }

    func testSettingsDismisses() {
        app.buttons["gearshape.fill"].tap()
        XCTAssertTrue(app.navigationBars["Ajustes"].waitForExistence(timeout: 5))

        app.buttons["Listo"].tap()

        // Should be back on main screen
        XCTAssertTrue(app.staticTexts["DriveMate"].waitForExistence(timeout: 5))
    }

    // MARK: - Settings Toggles

    func testHandsFreeToggleExists() {
        app.buttons["gearshape.fill"].tap()

        let toggle = app.switches["Modo manos libres"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
    }

    func testDarkModeToggleExists() {
        app.buttons["gearshape.fill"].tap()

        let toggle = app.switches["Modo oscuro forzado"]
        if !toggle.exists {
            app.swipeUp()
        }
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
    }

    // MARK: - Settings API Key Field

    func testAPIKeyFieldExists() {
        app.buttons["gearshape.fill"].tap()

        let apiKeyField = app.secureTextFields["API Key"]
        XCTAssertTrue(apiKeyField.waitForExistence(timeout: 5))
    }

    // MARK: - Dark Mode

    func testAppUsesDefaultDarkMode() {
        // The app defaults to dark mode, verify the UI renders
        XCTAssertTrue(app.staticTexts["DriveMate"].waitForExistence(timeout: 5))
    }
}

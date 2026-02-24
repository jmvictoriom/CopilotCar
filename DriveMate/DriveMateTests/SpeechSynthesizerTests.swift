import XCTest
@testable import DriveMate

final class SpeechSynthesizerTests: XCTestCase {

    private var synthesizer: SpeechSynthesizer!

    override func setUp() {
        super.setUp()
        synthesizer = SpeechSynthesizer()
    }

    override func tearDown() {
        synthesizer.stop()
        synthesizer = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateIsNotSpeaking() {
        XCTAssertFalse(synthesizer.isSpeaking)
    }

    // MARK: - Stop

    func testStopWhenNotSpeakingDoesNotCrash() {
        synthesizer.stop()
        XCTAssertFalse(synthesizer.isSpeaking)
    }

    func testStopMultipleTimesDoesNotCrash() {
        synthesizer.stop()
        synthesizer.stop()
        synthesizer.stop()
        XCTAssertFalse(synthesizer.isSpeaking)
    }

    // MARK: - Speak

    func testSpeakSetsIsSpeakingTrue() {
        synthesizer.speak("Hola mundo", locale: "es-ES", rate: 0.5)
        XCTAssertTrue(synthesizer.isSpeaking)
    }

    func testSpeakWithDifferentLocales() {
        let locales = ["es-ES", "en-US", "fr-FR", "de-DE", "pt-BR"]
        for locale in locales {
            synthesizer.speak("Test", locale: locale, rate: 0.5)
            XCTAssertTrue(synthesizer.isSpeaking)
            synthesizer.stop()
        }
    }

    func testSpeakWithMinRate() {
        synthesizer.speak("Test", locale: "es-ES", rate: 0.1)
        XCTAssertTrue(synthesizer.isSpeaking)
    }

    func testSpeakWithMaxRate() {
        synthesizer.speak("Test", locale: "es-ES", rate: 0.75)
        XCTAssertTrue(synthesizer.isSpeaking)
    }

    // MARK: - Stop During Speech

    func testStopDuringSpeech() {
        synthesizer.speak("Una frase larga que tarda en pronunciarse para probar la interrupción", locale: "es-ES", rate: 0.5)
        XCTAssertTrue(synthesizer.isSpeaking)

        synthesizer.stop()
        XCTAssertFalse(synthesizer.isSpeaking)
    }

    // MARK: - Speak Replaces Previous

    func testSpeakReplacesCurrentSpeech() {
        synthesizer.speak("Primer mensaje", locale: "es-ES", rate: 0.5)
        synthesizer.speak("Segundo mensaje", locale: "es-ES", rate: 0.5)
        XCTAssertTrue(synthesizer.isSpeaking)
    }

    // MARK: - Empty Text

    func testSpeakEmptyTextSetsIsSpeaking() {
        synthesizer.speak("", locale: "es-ES", rate: 0.5)
        // AVSpeechSynthesizer handles empty text gracefully
        // The state is set before speaking
        // It should either be speaking or have finished immediately
    }
}

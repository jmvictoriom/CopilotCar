import XCTest
@testable import DriveMate

final class ConversationStateTests: XCTestCase {

    // MARK: - Equatable

    func testStatesAreEquatable() {
        XCTAssertEqual(ConversationState.idle, ConversationState.idle)
        XCTAssertEqual(ConversationState.listening, ConversationState.listening)
        XCTAssertEqual(ConversationState.processing, ConversationState.processing)
        XCTAssertEqual(ConversationState.speaking, ConversationState.speaking)
    }

    func testDifferentStatesAreNotEqual() {
        XCTAssertNotEqual(ConversationState.idle, ConversationState.listening)
        XCTAssertNotEqual(ConversationState.listening, ConversationState.processing)
        XCTAssertNotEqual(ConversationState.processing, ConversationState.speaking)
        XCTAssertNotEqual(ConversationState.speaking, ConversationState.idle)
    }

    // MARK: - All States Exist

    func testAllStatesExist() {
        let states: [ConversationState] = [.idle, .listening, .processing, .speaking]
        XCTAssertEqual(states.count, 4)
    }
}

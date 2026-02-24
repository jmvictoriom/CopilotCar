import XCTest
@testable import DriveMate

final class MessageTests: XCTestCase {

    // MARK: - Creation

    func testMessageCreationWithDefaults() {
        let message = Message(role: .user, content: "Hola")

        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Hola")
        XCTAssertNotNil(message.id)
        XCTAssertNotNil(message.timestamp)
    }

    func testMessageCreationWithExplicitParams() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1000000)
        let message = Message(id: id, role: .assistant, content: "Respuesta", timestamp: date)

        XCTAssertEqual(message.id, id)
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Respuesta")
        XCTAssertEqual(message.timestamp, date)
    }

    func testMessageUserRole() {
        let message = Message(role: .user, content: "test")
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.role.rawValue, "user")
    }

    func testMessageAssistantRole() {
        let message = Message(role: .assistant, content: "test")
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.role.rawValue, "assistant")
    }

    // MARK: - Identifiable

    func testMessagesHaveUniqueIDs() {
        let m1 = Message(role: .user, content: "A")
        let m2 = Message(role: .user, content: "A")
        XCTAssertNotEqual(m1.id, m2.id)
    }

    // MARK: - Equatable

    func testMessageEqualitySameID() {
        let id = UUID()
        let date = Date()
        let m1 = Message(id: id, role: .user, content: "Hola", timestamp: date)
        let m2 = Message(id: id, role: .user, content: "Hola", timestamp: date)
        XCTAssertEqual(m1, m2)
    }

    func testMessageInequalityDifferentContent() {
        let id = UUID()
        let date = Date()
        let m1 = Message(id: id, role: .user, content: "Hola", timestamp: date)
        let m2 = Message(id: id, role: .user, content: "Adiós", timestamp: date)
        XCTAssertNotEqual(m1, m2)
    }

    func testMessageInequalityDifferentRole() {
        let id = UUID()
        let date = Date()
        let m1 = Message(id: id, role: .user, content: "Hola", timestamp: date)
        let m2 = Message(id: id, role: .assistant, content: "Hola", timestamp: date)
        XCTAssertNotEqual(m1, m2)
    }

    // MARK: - Role Codable

    func testRoleEncode() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(Message.Role.user)
        let string = String(data: data, encoding: .utf8)
        XCTAssertEqual(string, "\"user\"")
    }

    func testRoleDecode() throws {
        let decoder = JSONDecoder()
        let data = "\"assistant\"".data(using: .utf8)!
        let role = try decoder.decode(Message.Role.self, from: data)
        XCTAssertEqual(role, .assistant)
    }

    // MARK: - Edge Cases

    func testMessageWithEmptyContent() {
        let message = Message(role: .user, content: "")
        XCTAssertEqual(message.content, "")
    }

    func testMessageWithLongContent() {
        let longText = String(repeating: "a", count: 10000)
        let message = Message(role: .assistant, content: longText)
        XCTAssertEqual(message.content.count, 10000)
    }

    func testMessageWithSpecialCharacters() {
        let special = "¡Hola! ¿Cómo estás? 🚗 Ñ ü ö"
        let message = Message(role: .user, content: special)
        XCTAssertEqual(message.content, special)
    }
}

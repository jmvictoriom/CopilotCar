import Foundation

struct PlaceAction: Identifiable, Equatable {
    let id: String
    let placeName: String
    let address: String?
    let rating: Double?
    let placeId: String
    let phoneNumber: String?
}

struct Message: Identifiable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date
    var actions: [PlaceAction]

    enum Role: String, Codable {
        case user
        case assistant
    }

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date(), actions: [PlaceAction] = []) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.actions = actions
    }
}

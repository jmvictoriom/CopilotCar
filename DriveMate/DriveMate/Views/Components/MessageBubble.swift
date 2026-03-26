import SwiftUI

struct MessageBubble: View {
    let message: Message
    var onCallPlace: ((PlaceAction) -> Void)?

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(isUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isUser ? Color.blue : Color(.systemGray5))
                    )

                if !message.actions.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(message.actions) { action in
                            Button {
                                onCallPlace?(action)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                        .font(.caption)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(action.placeName)
                                            .font(.subheadline.bold())
                                        if let rating = action.rating {
                                            Text("\(String(format: "%.1f", rating)) estrellas")
                                                .font(.caption2)
                                        }
                                    }
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green)
                                )
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                Text(message.timestamp, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

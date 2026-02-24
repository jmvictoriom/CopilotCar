import SwiftUI

struct PulsingMicButton: View {
    let state: ConversationState
    let action: () -> Void

    @State private var isPulsing = false

    private var buttonColor: Color {
        switch state {
        case .idle: return .blue
        case .listening: return .red
        case .processing: return .orange
        case .speaking: return .green
        }
    }

    private var iconName: String {
        switch state {
        case .idle: return "mic.fill"
        case .listening: return "mic.fill"
        case .processing: return "brain.head.profile"
        case .speaking: return "speaker.wave.3.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer pulse rings
                if state == .listening {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(buttonColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 100 + CGFloat(index) * 30,
                                   height: 100 + CGFloat(index) * 30)
                            .scaleEffect(isPulsing ? 1.2 : 0.9)
                            .opacity(isPulsing ? 0 : 0.6)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                                value: isPulsing
                            )
                    }
                }

                // Main button
                Circle()
                    .fill(buttonColor.gradient)
                    .frame(width: 90, height: 90)
                    .shadow(color: buttonColor.opacity(0.5), radius: 10)

                Image(systemName: iconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(.plain)
        .onChange(of: state) { _, newState in
            isPulsing = newState == .listening
        }
        .onAppear {
            isPulsing = state == .listening
        }
    }
}

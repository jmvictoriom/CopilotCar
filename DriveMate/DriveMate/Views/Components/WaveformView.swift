import SwiftUI

struct WaveformView: View {
    let isActive: Bool
    let color: Color

    @State private var phase: CGFloat = 0

    private let barCount = 20

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.gradient)
                    .frame(width: 4, height: barHeight(for: index))
                    .animation(
                        .easeInOut(duration: 0.4 + Double.random(in: 0...0.3))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.05),
                        value: isActive
                    )
            }
        }
        .frame(height: 40)
    }

    private func barHeight(for index: Int) -> CGFloat {
        if isActive {
            let base = sin(CGFloat(index) * 0.5 + phase) * 15 + 20
            return max(4, base)
        } else {
            return 4
        }
    }
}

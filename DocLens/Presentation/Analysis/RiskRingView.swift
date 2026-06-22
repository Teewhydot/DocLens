import SwiftUI

/// Animated circular risk-score gauge.
struct RiskRingView: View {
    let score: Double          // 0.0 – 1.0
    var size: CGFloat = 160
    var lineWidth: CGFloat = 14

    @State private var animatedScore: Double = 0

    private var color: Color { Theme.riskColor(for: score) }
    private var label: String { Theme.riskLabel(for: score) }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(color.opacity(0.15), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Fill
            Circle()
                .trim(from: 0, to: animatedScore)
                .stroke(
                    AngularGradient(colors: [color.opacity(0.6), color], center: .center, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * animatedScore)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center text
            VStack(spacing: 2) {
                Text("\(Int((score * 100).rounded()))")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: size * 0.11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Risk")
                    .font(.system(size: size * 0.1))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) { animatedScore = score }
        }
        .onChange(of: score) { _, new in
            withAnimation(.easeOut(duration: 0.8)) { animatedScore = new }
        }
    }
}

#Preview {
    HStack(spacing: 32) {
        RiskRingView(score: 0.18)
        RiskRingView(score: 0.47)
        RiskRingView(score: 0.74)
    }
    .padding()
}

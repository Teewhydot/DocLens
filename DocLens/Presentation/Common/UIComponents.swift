import SwiftUI

/// Colored pill showing the document risk level.
struct RiskBadge: View {
    let score: Double

    var body: some View {
        Text("\(Int((score * 100).rounded()))")
            .font(.system(.caption, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .frame(minWidth: 34)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Theme.riskColor(for: score), in: Capsule())
            .accessibilityLabel("Risk score \(Int((score * 100).rounded())) out of 100")
    }
}

/// Status chip shown on each document cell.
struct StatusChip: View {
    let status: AnalysisStatus

    private var color: Color {
        switch status {
        case .complete: return Color(hex: 0x2A9D8F)
        case .processing, .pending: return Theme.amber
        case .failed: return Theme.crimson
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if status == .processing || status == .pending {
                ProgressView().controlSize(.mini).tint(color)
            }
            Text(status.displayLabel)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .background(color.opacity(0.15), in: Capsule())
    }
}

/// Generic empty-state used across screens.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var ctaTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Theme.accent)
                .symbolRenderingMode(.hierarchical)
            VStack(spacing: 8) {
                Text(title)
                    .font(.docHeadline())
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let ctaTitle, let action {
                Button(action: action) {
                    Label(ctaTitle, systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .padding(.top, 4)
            }
        }
        .padding(32)
    }
}

#Preview("Components") {
    VStack(spacing: 24) {
        HStack { RiskBadge(score: 0.2); RiskBadge(score: 0.5); RiskBadge(score: 0.8) }
        HStack { StatusChip(status: .complete); StatusChip(status: .processing); StatusChip(status: .failed) }
        EmptyStateView(
            symbol: "doc.text.magnifyingglass",
            title: "No documents yet",
            message: "Import your first contract to get started.",
            ctaTitle: "Import Document",
            action: {}
        )
    }
    .padding()
}

import SwiftUI

struct DocumentCell: View {
    let document: DocumentEntity

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private var icon: String {
        document.fileType == .pdf ? "doc.richtext.fill" : "photo.fill"
    }

    var body: some View {
        HStack(spacing: 14) {
            iconBadge
            VStack(alignment: .leading, spacing: 6) {
                Text(document.title)
                    .font(.system(.headline, design: .rounded))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(Self.dateFormatter.string(from: document.importedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    StatusChip(status: document.status)
                }
            }
            Spacer(minLength: 8)
            if document.status == .complete {
                RiskBadge(score: document.riskScore)
            }
        }
        .padding(.vertical, Theme.rowVPadding - 4)
    }

    private var iconBadge: some View {
        Image(systemName: icon)
            .font(.title3)
            .foregroundStyle(Theme.accent)
            .frame(width: 44, height: 44)
            .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    List(SampleData.documents) { DocumentCell(document: $0) }
}

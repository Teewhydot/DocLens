import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: HistoryFilter = .all
    @AppStorage("defaultSortNewest") private var sortNewest = true

    private var filtered: [DocumentEntity] {
        viewModel.documents
            .filter { selectedFilter.matches($0) }
            .filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted { sortNewest ? $0.importedAt > $1.importedAt : $0.importedAt < $1.importedAt }
    }

    private var grouped: [(String, [DocumentEntity])] {
        let calendar = Calendar.current
        let dict = Dictionary(grouping: filtered) { doc -> String in
            if calendar.isDateInToday(doc.importedAt)     { return "Today" }
            if calendar.isDateInYesterday(doc.importedAt) { return "Yesterday" }
            let comps = calendar.dateComponents([.year, .month], from: doc.importedAt)
            let d = calendar.date(from: comps) ?? doc.importedAt
            return d.formatted(.dateTime.month(.wide).year())
        }
        let order = ["Today", "Yesterday"]
        let rest = dict.keys.filter { !order.contains($0) }.sorted(by: >)
        return (order.filter { dict[$0] != nil } + rest).compactMap { key in
            guard let val = dict[key] else { return nil }
            return (key, val.sorted { sortNewest ? $0.importedAt > $1.importedAt : $0.importedAt < $1.importedAt })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.documents.isEmpty {
                    emptyState
                } else {
                    contentList
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search documents…")
            .toolbar { filterMenu }
            .task {
                await viewModel.fetchDocuments()
            }
        }
    }

    // MARK: - Subviews

    private var contentList: some View {
        ScrollView {
            VStack(spacing: 0) {
                statsBanner
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                if filtered.isEmpty {
                    noResultsState
                        .padding(.top, 60)
                } else {
                    ForEach(grouped, id: \.0) { header, docs in
                        sectionHeader(header)
                        ForEach(docs) { doc in
                            HistoryRow(doc: doc)
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var statsBanner: some View {
        let completed = viewModel.documents.filter { $0.status == .complete }
        let avgRisk: Double = completed.isEmpty ? 0 :
            completed.map(\.riskScore).reduce(0, +) / Double(completed.count)
        let highCount = completed.filter { $0.riskScore >= 0.6 }.count

        return HStack(spacing: 12) {
            StatPill(value: "\(completed.count)", label: "Analyzed", color: Theme.accent)
            StatPill(value: "\(Int((avgRisk * 100).rounded()))%", label: "Avg Risk", color: Theme.amber)
            StatPill(value: "\(highCount)", label: "High Risk", color: Theme.crimson)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 6)
            Spacer()
        }
        .background(Theme.background)
    }

    @ToolbarContentBuilder
    private var filterMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(HistoryFilter.allCases) { f in
                    Button {
                        selectedFilter = f
                    } label: {
                        Label(f.label, systemImage: selectedFilter == f ? "checkmark" : f.icon)
                    }
                }
            } label: {
                Image(systemName: selectedFilter == .all
                      ? "line.3.horizontal.decrease.circle"
                      : "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(Theme.accent)
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            symbol: "clock.arrow.circlepath",
            title: "No History Yet",
            message: "Documents you analyze will appear here, grouped by date."
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsState: some View {
        EmptyStateView(
            symbol: "magnifyingglass",
            title: "No Matches",
            message: "Try adjusting your search or filter."
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - HistoryRow

struct HistoryRow: View {
    let doc: DocumentEntity

    var body: some View {
        NavigationLink(destination: destinationView) {
            rowContent
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var destinationView: some View {
        AnalysisResultsView(document: doc)
    }

    private var rowContent: some View {
        HStack(spacing: 14) {
            fileIcon
            VStack(alignment: .leading, spacing: 4) {
                Text(doc.title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(doc.importedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    StatusChip(status: doc.status)
                }
            }
            Spacer()
            if doc.status == .complete {
                RiskBadge(score: doc.riskScore)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private var fileIcon: some View {
        let isImage = doc.fileType == .image
        return Image(systemName: isImage ? "photo.fill" : "doc.fill")
            .font(.system(size: 22))
            .foregroundStyle(isImage ? Theme.amber : Theme.accent)
            .frame(width: 42, height: 42)
            .background((isImage ? Theme.amber : Theme.accent).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - StatPill

struct StatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - HistoryFilter

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all, highRisk, complete, pending

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All Documents"
        case .highRisk: return "High Risk"
        case .complete: return "Analyzed"
        case .pending: return "Pending"
        }
    }

    var icon: String {
        switch self {
        case .all: return "doc.text"
        case .highRisk: return "exclamationmark.triangle"
        case .complete: return "checkmark.circle"
        case .pending: return "clock"
        }
    }

    func matches(_ doc: DocumentEntity) -> Bool {
        switch self {
        case .all: return true
        case .highRisk: return doc.riskScore >= 0.6
        case .complete: return doc.status == .complete
        case .pending: return doc.status == .pending || doc.status == .processing
        }
    }
}

#Preview {
    HistoryView()
        .tint(Theme.accent)
}

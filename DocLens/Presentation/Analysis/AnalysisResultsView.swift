import SwiftUI
import Charts

struct AnalysisResultsView: View {
    let document: DocumentEntity
    @EnvironmentObject private var store: DocumentStore
    @Environment(\.dismiss) private var dismiss

    private var flags: [RiskFlagEntity] { store.flags(for: document.id) }
    private var entities: [EntityMentionEntity] { store.entities(for: document.id) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    if !flags.isEmpty { riskFlagsSection }
                    if !entities.isEmpty { entitiesSection }
                    metaSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            Text(document.title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.top, 8)

            RiskRingView(score: document.riskScore, size: 180, lineWidth: 16)
                .padding(.vertical, 8)

            riskSummaryPills
            if !flags.isEmpty { riskCategoryChart }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var riskSummaryPills: some View {
        HStack(spacing: 12) {
            summaryPill(count: flags.filter { $0.severity == .high }.count, label: "High", color: Theme.crimson)
            summaryPill(count: flags.filter { $0.severity == .medium }.count, label: "Medium", color: Theme.amber)
            summaryPill(count: flags.filter { $0.severity == .low }.count, label: "Low", color: Color(hex: 0x2A9D8F))
        }
    }

    private func summaryPill(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Risk Category Chart

    private struct CategoryCount: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
        let color: Color
    }

    private var chartData: [CategoryCount] {
        let cats = RiskCategory.allCases
        return cats.compactMap { cat in
            let count = flags.filter { $0.category == cat }.count
            guard count > 0 else { return nil }
            return CategoryCount(name: cat.displayName, count: count, color: colorForCategory(cat))
        }
    }

    private func colorForCategory(_ cat: RiskCategory) -> Color {
        switch cat {
        case .liability: return Theme.crimson
        case .ipAssignment: return Color(hex: 0x9B5DE5)
        case .nonCompete: return Theme.amber
        case .penalties: return Color(hex: 0xF15BB5)
        case .autoRenewal: return Color(hex: 0x00BBF9)
        case .arbitration: return Color(hex: 0xFEE440)
        }
    }

    @ViewBuilder
    private var riskCategoryChart: some View {
        if !chartData.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Risk Breakdown").font(.caption).foregroundStyle(.secondary)
                Chart(chartData) { item in
                    BarMark(x: .value("Category", item.name), y: .value("Count", item.count))
                        .foregroundStyle(item.color)
                        .cornerRadius(6)
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.system(size: 9))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                        AxisValueLabel()
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Risk Flags

    private var riskFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Risk Flags", symbol: "exclamationmark.shield.fill", color: Theme.crimson)
            ForEach(flags.sorted { severityOrder($0.severity) > severityOrder($1.severity) }) { flag in
                RiskFlagCard(flag: flag)
            }
        }
    }

    private func severityOrder(_ s: RiskSeverity) -> Int {
        switch s { case .high: return 3; case .medium: return 2; case .low: return 1 }
    }

    // MARK: - Entities

    private var entitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Detected Entities", symbol: "tag.fill", color: Theme.accent)
            entityTypesView
        }
    }

    private var entityTypesView: some View {
        let grouped = Dictionary(grouping: entities, by: { $0.type })
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(EntityType.allCases, id: \.self) { type in
                if let group = grouped[type], !group.isEmpty {
                    EntityGroupRow(type: type, items: group)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    // MARK: - Meta

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Document Info", symbol: "info.circle.fill", color: .secondary)
            VStack(spacing: 0) {
                metaRow("Language", value: document.detectedLanguage)
                Divider().padding(.leading, 16)
                metaRow("File Type", value: document.fileType.rawValue.uppercased())
                Divider().padding(.leading, 16)
                metaRow("Imported", value: document.importedAt.formatted(date: .abbreviated, time: .shortened))
                Divider().padding(.leading, 16)
                metaRow("Entities Found", value: "\(entities.count)")
                Divider().padding(.leading, 16)
                metaRow("Risk Flags", value: "\(flags.count)")
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }

    private func metaRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func sectionHeader(_ title: String, symbol: String, color: Color) -> some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .foregroundStyle(color)
    }
}

// MARK: - Risk Flag Card

struct RiskFlagCard: View {
    let flag: RiskFlagEntity
    @State private var expanded = false

    private var severityColor: Color {
        switch flag.severity {
        case .high: return Theme.crimson
        case .medium: return Theme.amber
        case .low: return Color(hex: 0x2A9D8F)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(severityColor)
                        .frame(width: 4, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flag.keyword.capitalized)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(flag.category.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    severityBadge
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if expanded && !flag.excerptContext.isEmpty {
                Divider().padding(.horizontal, 16)
                Text(flag.excerptContext)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var severityBadge: some View {
        Text(flag.severity.rawValue.capitalized)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severityColor.opacity(0.15), in: Capsule())
            .foregroundStyle(severityColor)
    }
}

// MARK: - Entity Group Row

struct EntityGroupRow: View {
    let type: EntityType
    let items: [EntityMentionEntity]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(type.displayName, systemImage: type.symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(items.prefix(10)) { entity in
                        Text(entity.value)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.accent.opacity(0.12), in: Capsule())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

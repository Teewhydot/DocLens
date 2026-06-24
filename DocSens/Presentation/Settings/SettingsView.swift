import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("autoAnalyzeOnImport") private var autoAnalyze = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("defaultSortNewest") private var sortNewest = true
    @State private var showResetConfirm = false
    @State private var showClearHistoryConfirm = false
    @StateObject private var viewModel = SettingsViewModel()

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        NavigationStack {
            List {
                preferencesSection
                aboutSection
                dangerSection
            }
            .listStyle(.insetGrouped)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .alert("Reset Onboarding?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { hasCompletedOnboarding = false }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll see the DocSens intro screens next time you open the app.")
            }
            .alert("Clear All History?", isPresented: $showClearHistoryConfirm) {
                Button("Clear All", role: .destructive) { 
                    Task { await viewModel.clearAllHistory() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All analyzed documents and results will be permanently deleted from this device.")
            }
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $autoAnalyze) {
                Label("Auto-Analyze on Import", systemImage: "bolt.fill")
                    .labelStyle(SettingsLabelStyle(color: Theme.accent))
            }
            .tint(Theme.accent)

            Toggle(isOn: $hapticFeedback) {
                Label("Haptic Feedback", systemImage: "hand.tap.fill")
                    .labelStyle(SettingsLabelStyle(color: Theme.amber))
            }
            .tint(Theme.accent)

            Toggle(isOn: $sortNewest) {
                Label("Sort Newest First", systemImage: "arrow.up.arrow.down")
                    .labelStyle(SettingsLabelStyle(color: Color(hex: 0x6C63FF)))
            }
            .tint(Theme.accent)
        } header: {
            sectionHeader("Preferences", icon: "slider.horizontal.3")
        } footer: {
            HStack {
                Image(systemName: "checkmark.icloud.fill")
                    .foregroundStyle(.green)
                Text("iCloud Sync Active")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            settingsRow(icon: "doc.text.magnifyingglass", color: Theme.accent, title: "DocSens") {
                Text("Document Risk Analyzer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            settingsRow(icon: "info.circle.fill", color: Color(hex: 0x6C63FF), title: "Version") {
                Text("\(appVersion) (\(buildNumber))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://apple.com/legal/privacy")!) {
                HStack {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                        .labelStyle(SettingsLabelStyle(color: Theme.crimson))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
            }
            
            Link(destination: URL(string: "mailto:support@superapp.com?subject=DocSens%20Support&body=App%20Version:%20\(appVersion)%20(\(buildNumber))")!) {
                HStack {
                    Label("Contact Support", systemImage: "envelope.fill")
                        .labelStyle(SettingsLabelStyle(color: Theme.accent))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
            }
        } header: {
            sectionHeader("About DocSens", icon: "info.circle")
        }
    }

    // MARK: - Danger Section

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showClearHistoryConfirm = true
            } label: {
                Label("Clear All Documents", systemImage: "trash.fill")
                    .foregroundStyle(Theme.crimson)
            }
        } header: {
            sectionHeader("Data", icon: "externaldrive.fill")
        } footer: {
            Text("Removes all imported documents and analysis results from this device. This action cannot be undone.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(.footnote, design: .rounded).weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
    }

    @ViewBuilder
    private func settingsRow<T: View>(icon: String, color: Color, title: String, @ViewBuilder trailing: () -> T) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .labelStyle(SettingsLabelStyle(color: color))
            Spacer()
            trailing()
        }
    }
}

// MARK: - PrivacyFeatureRow

struct PrivacyFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Label Style

struct SettingsLabelStyle: LabelStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.icon
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            configuration.title
                .font(.system(.body))
        }
    }
}

#Preview {
    SettingsView()
        .tint(Theme.accent)
}

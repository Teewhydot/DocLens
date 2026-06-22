import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Documents", systemImage: "doc.text.magnifyingglass") }

            PlaceholderScreen(
                title: "History",
                symbol: "clock.arrow.circlepath",
                message: "Your analyzed documents will appear here, grouped by month."
            )
            .tabItem { Label("History", systemImage: "clock") }

            PlaceholderScreen(
                title: "Settings",
                symbol: "gearshape.fill",
                message: "Subscription, iCloud sync status, and privacy options live here."
            )
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

/// Temporary placeholder used for screens not yet implemented.
struct PlaceholderScreen: View {
    let title: String
    let symbol: String
    let message: String

    var body: some View {
        NavigationStack {
            EmptyStateView(symbol: symbol, title: "\(title) coming soon", message: message)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background.ignoresSafeArea())
                .navigationTitle(title)
        }
    }
}

#Preview {
    MainTabView().tint(Theme.accent)
}

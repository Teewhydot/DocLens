import SwiftUI

/// Root container that hosts the main TabView. Onboarding / paywall will be
/// layered in here in a later pass.
struct RootView: View {
    @StateObject private var store = DocumentStore.shared

    var body: some View {
        MainTabView()
            .tint(Theme.accent)
            .environmentObject(store)
    }
}

#Preview {
    RootView()
}

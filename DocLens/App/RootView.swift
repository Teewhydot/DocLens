import SwiftUI

/// Root container that hosts the main TabView. Onboarding / paywall will be
/// layered in here in a later pass.
struct RootView: View {
    var body: some View {
        MainTabView()
            .tint(Theme.accent)
    }
}

#Preview {
    RootView()
}

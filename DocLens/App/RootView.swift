import SwiftUI

struct RootView: View {
    @StateObject private var store = DocumentStore.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            MainTabView()
                .tint(Theme.accent)
                .environmentObject(store)

            if !hasCompletedOnboarding {
                OnboardingView {
                    withAnimation(.easeOut(duration: 0.4)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .zIndex(10)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: hasCompletedOnboarding)
    }
}

#Preview {
    RootView()
}

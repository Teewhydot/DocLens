import SwiftUI

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id: Int
    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
    let bullets: [BulletItem]

    struct BulletItem: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let text: String
    }
}

private let pages: [OnboardingPage] = [
    OnboardingPage(
        id: 0,
        icon: "doc.text.magnifyingglass",
        iconColors: [Color(hex: 0x0ABFBC), Color(hex: 0x0D7A78)],
        title: "Understand Any Contract",
        subtitle: "DocLens reads legal documents and highlights what matters — in plain language.",
        bullets: [
            .init(icon: "checkmark.shield.fill", color: Color(hex: 0x0ABFBC), text: "Spot risky clauses instantly"),
            .init(icon: "doc.plaintext.fill", color: Color(hex: 0x0ABFBC), text: "Works with PDFs and images"),
            .init(icon: "bolt.fill", color: Color(hex: 0x0ABFBC), text: "Results in seconds")
        ]
    ),
    OnboardingPage(
        id: 1,
        icon: "lock.shield.fill",
        iconColors: [Color(hex: 0x2A9D8F), Color(hex: 0x0D4B49)],
        title: "100% Private & On-Device",
        subtitle: "Your documents never leave your device. Analysis runs entirely on-device — no cloud, no servers.",
        bullets: [
            .init(icon: "lock.fill", color: Color(hex: 0x2A9D8F), text: "Zero data transmission"),
            .init(icon: "eye.slash.fill", color: Color(hex: 0x2A9D8F), text: "No account required"),
            .init(icon: "antenna.radiowaves.left.and.right.slash", color: Color(hex: 0x2A9D8F), text: "Works fully offline")
        ]
    ),
    OnboardingPage(
        id: 2,
        icon: "chart.bar.doc.horizontal.fill",
        iconColors: [Color(hex: 0xF4A261), Color(hex: 0xC1552A)],
        title: "Risk at a Glance",
        subtitle: "A visual risk score, category breakdown, and key entity detection — all in one tap.",
        bullets: [
            .init(icon: "exclamationmark.triangle.fill", color: Color(hex: 0xF4A261), text: "6 risk categories flagged"),
            .init(icon: "person.2.fill", color: Color(hex: 0xF4A261), text: "Names, dates & money extracted"),
            .init(icon: "dial.medium.fill", color: Color(hex: 0xF4A261), text: "Scored 0–100 risk gauge")
        ]
    )
]

// MARK: - Main Onboarding View

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @State private var animateContent = false

    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 0) {
                skipButton
                Spacer(minLength: 16)
                pageContent
                Spacer(minLength: 24)
                bottomControls
                    .padding(.bottom, 48)
            }
        }
        .onAppear { animateContent = true }
        .gesture(swipeGesture)
    }

    // MARK: Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(hex: 0x0D1B2A), Color(hex: 0x0D1B2A)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var skipButton: some View {
        HStack {
            Spacer()
            if currentPage < pages.count - 1 {
                Button("Skip") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentPage = pages.count - 1
                        resetAnimation()
                    }
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.5))
                .padding(.horizontal, 20)
                .padding(.top, 16)
            } else {
                Color.clear.frame(height: 44).padding(.top, 16)
            }
        }
    }

    private var pageContent: some View {
        TabView(selection: $currentPage) {
            ForEach(pages) { page in
                OnboardingPageView(page: page, isActive: currentPage == page.id)
                    .tag(page.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 520)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
    }

    private var bottomControls: some View {
        VStack(spacing: 28) {
            pageIndicator
            actionButton
        }
        .padding(.horizontal, 32)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color(hex: 0x0ABFBC) : Color.white.opacity(0.25))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    private var actionButton: some View {
        Button(action: handleAction) {
            HStack(spacing: 8) {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Image(systemName: currentPage == pages.count - 1 ? "checkmark" : "arrow.right")
                    .font(.system(.subheadline).weight(.bold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x0ABFBC), Color(hex: 0x08A8A5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color(hex: 0x0ABFBC).opacity(0.4), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                let threshold: CGFloat = 50
                if value.translation.width < -threshold, currentPage < pages.count - 1 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentPage += 1
                    }
                } else if value.translation.width > threshold, currentPage > 0 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentPage -= 1
                    }
                }
            }
    }

    private func handleAction() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentPage += 1
                resetAnimation()
            }
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                onComplete()
            }
        }
    }

    private func resetAnimation() {
        animateContent = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animateContent = true
        }
    }
}

// MARK: - Single Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            iconSection
                .padding(.bottom, 36)
            textSection
                .padding(.bottom, 32)
            bulletsSection
            Spacer()
        }
        .padding(.horizontal, 32)
        .onChange(of: isActive) { _, active in
            if active { triggerAnimation() }
        }
        .onAppear {
            if isActive { triggerAnimation() }
        }
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: page.iconColors.map { $0.opacity(0.2) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 130, height: 130)

            Circle()
                .strokeBorder(
                    LinearGradient(colors: page.iconColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
                .frame(width: 130, height: 130)

            Image(systemName: page.icon)
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(
                    LinearGradient(colors: page.iconColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        }
        .scaleEffect(iconScale)
        .opacity(iconOpacity)
    }

    private var textSection: some View {
        VStack(spacing: 12) {
            Text(page.title)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            Text(page.subtitle)
                .font(.system(.subheadline))
                .foregroundStyle(Color.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .offset(y: textOffset)
        .opacity(textOpacity)
    }

    private var bulletsSection: some View {
        VStack(spacing: 14) {
            ForEach(page.bullets) { bullet in
                HStack(spacing: 14) {
                    Image(systemName: bullet.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(bullet.color)
                        .frame(width: 28)

                    Text(bullet.text)
                        .font(.system(.callout, design: .rounded).weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .offset(y: textOffset)
        .opacity(textOpacity)
    }

    private func triggerAnimation() {
        iconScale = 0.6
        iconOpacity = 0
        textOffset = 30
        textOpacity = 0

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.05)) {
            iconScale = 1.0
            iconOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            textOffset = 0
            textOpacity = 1
        }
    }
}

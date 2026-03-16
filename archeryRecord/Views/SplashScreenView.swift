import SwiftUI

struct SplashScreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateLogo = false

    var body: some View {
        ZStack {
            splashBackground

            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.96),
                                    SharedStyles.elevatedSurfaceColor,
                                    SharedStyles.surfaceColor.opacity(0.98)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 188, height: 188)
                        .overlay {
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .stroke(Color.white.opacity(0.74), lineWidth: 1)
                        }
                        .shadow(color: SharedStyles.Shadow.light, radius: 18, x: 0, y: 12)

                    Image("splash_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 144, height: 144)
                        .rotationEffect(.degrees(animateLogo && !reduceMotion ? -4 : 0))
                        .scaleEffect(animateLogo && !reduceMotion ? 1.02 : 0.97)
                        .shadow(color: SharedStyles.Shadow.medium, radius: 10, x: 0, y: 6)
                }

                VStack(spacing: 10) {
                    Text(L10n.Content.appTitle)
                        .sharedTextStyle(SharedStyles.Text.screenTitle, color: SharedStyles.primaryTextColor)
                        .multilineTextAlignment(.center)

                    Capsule()
                        .fill(SharedStyles.groupBackgroundColor)
                        .frame(width: 76, height: 6)
                        .overlay {
                            Capsule()
                                .fill(SharedStyles.primaryColor.opacity(0.32))
                                .frame(width: 34, height: 6)
                        }
                }
            }
            .padding(.horizontal, 28)
        }
        .task {
            guard !reduceMotion else { return }

            withAnimation(
                .easeInOut(duration: 0.9)
                .repeatForever(autoreverses: true)
            ) {
                animateLogo = true
            }
        }
    }

    private var splashBackground: some View {
        ZStack {
            SharedStyles.blockGradient(SharedStyles.GradientSet.warmCanvas)
                .ignoresSafeArea()

            Circle()
                .fill(SharedStyles.Accent.sky.opacity(0.07))
                .frame(width: 220, height: 220)
                .blur(radius: 18)
                .offset(x: 150, y: -260)

            Circle()
                .fill(SharedStyles.Accent.mint.opacity(0.06))
                .frame(width: 200, height: 200)
                .blur(radius: 20)
                .offset(x: -150, y: -120)

            RoundedRectangle(cornerRadius: 88, style: .continuous)
                .fill(SharedStyles.Accent.violet.opacity(0.05))
                .frame(width: 250, height: 220)
                .rotationEffect(.degrees(18))
                .offset(x: 160, y: 250)
        }
    }
}

struct LaunchScreenHostView<Content: View>: View {
    let content: Content

    @State private var showSplash = true
    @State private var splashTaskStarted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
                .allowsHitTesting(!showSplash)

            if showSplash {
                SplashScreenView()
                    .transition(
                        .opacity
                        .combined(with: .scale(scale: reduceMotion ? 1 : 1.03))
                    )
                    .zIndex(1)
            }
        }
        .task {
            guard !splashTaskStarted else { return }

            splashTaskStarted = true

            try? await Task.sleep(for: .milliseconds(1500))

            withAnimation(reduceMotion ? .easeOut(duration: 0.18) : .easeInOut(duration: 0.32)) {
                showSplash = false
            }
        }
    }
}

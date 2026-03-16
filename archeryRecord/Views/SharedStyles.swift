import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum SharedStyles {
    static let primaryColor = Color(red: 0.26, green: 0.49, blue: 0.47)
    static let secondaryColor = Color(red: 0.41, green: 0.56, blue: 0.69)
    static let accentColor = Color(red: 0.56, green: 0.70, blue: 0.62)
    static let backgroundColor = Color(red: 0.95, green: 0.97, blue: 0.96)
    static let groupBackgroundColor = Color(red: 0.92, green: 0.95, blue: 0.94)
    static let surfaceColor = Color(red: 0.97, green: 0.98, blue: 0.98)
    static let elevatedSurfaceColor = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let primaryTextColor = Color(red: 0.16, green: 0.22, blue: 0.25)
    static let secondaryTextColor = Color(red: 0.37, green: 0.45, blue: 0.49)
    static let tertiaryTextColor = Color(red: 0.60, green: 0.66, blue: 0.69)
    static let singleRecordOutlineColor = Color(red: 0.18, green: 0.66, blue: 0.43)
    static let groupRecordOutlineColor = Color(red: 0.18, green: 0.47, blue: 0.88)

    static let sectionSpacing: CGFloat = 20
    static let itemSpacing: CGFloat = 12
    static let cornerRadius: CGFloat = 18
    static let bodyLineSpacing: CGFloat = 4
    static let captionLineSpacing: CGFloat = 2

    struct Text {
        static let screenTitle = Font.system(size: 30, weight: .semibold, design: .default)
        static let sectionTitle = Font.system(size: 23, weight: .semibold, design: .default)
        static let title = Font.system(size: 19, weight: .semibold, design: .default)
        static let subtitle = Font.system(size: 15, weight: .medium, design: .default)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyEmphasis = Font.system(size: 16, weight: .semibold, design: .default)
        static let caption = Font.system(size: 13, weight: .medium, design: .default)
        static let footnote = Font.system(size: 12, weight: .medium, design: .default)
        static let microCaption = Font.system(size: 11, weight: .medium, design: .default)
        static let compactValue = Font.system(size: 25, weight: .bold, design: .default)
        static let metricValue = Font.system(size: 28, weight: .bold, design: .default)
    }

    struct Shadow {
        static let highlight = Color.white.opacity(0.80)
        static let light = Color(red: 0.63, green: 0.71, blue: 0.73).opacity(0.16)
        static let medium = Color(red: 0.45, green: 0.55, blue: 0.58).opacity(0.12)
        static let deep = Color(red: 0.30, green: 0.40, blue: 0.43).opacity(0.10)
    }

    struct Accent {
        static let orange = Color(red: 0.79, green: 0.62, blue: 0.49)
        static let peach = Color(red: 0.89, green: 0.82, blue: 0.74)
        static let coral = Color(red: 0.76, green: 0.59, blue: 0.55)
        static let sky = Color(red: 0.70, green: 0.79, blue: 0.87)
        static let teal = Color(red: 0.45, green: 0.63, blue: 0.61)
        static let mint = Color(red: 0.68, green: 0.79, blue: 0.72)
        static let violet = Color(red: 0.66, green: 0.71, blue: 0.81)
        static let lemon = Color(red: 0.85, green: 0.82, blue: 0.67)
        static let rose = Color(red: 0.81, green: 0.70, blue: 0.73)
    }

    struct GradientSet {
        static let sunrise = [Color(red: 0.56, green: 0.71, blue: 0.67), Color(red: 0.44, green: 0.61, blue: 0.58)]
        static let sky = [Color(red: 0.55, green: 0.68, blue: 0.79), Color(red: 0.44, green: 0.58, blue: 0.67)]
        static let violet = [Color(red: 0.50, green: 0.61, blue: 0.73), Color(red: 0.43, green: 0.53, blue: 0.65)]
        static let mint = [Color(red: 0.65, green: 0.78, blue: 0.72), Color(red: 0.52, green: 0.66, blue: 0.61)]
        static let warmCanvas = [
            Color(red: 0.97, green: 0.98, blue: 0.98),
            Color(red: 0.94, green: 0.96, blue: 0.95),
            Color(red: 0.91, green: 0.94, blue: 0.93)
        ]
    }

    struct Spacing {
        static let dense: CGFloat = 10
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let section: CGFloat = 14
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
    }

    struct Score {
        static let tenColor = Accent.orange
        static let nineColor = Accent.lemon
        static let defaultColor = primaryTextColor

        static func color(for score: String) -> Color {
            if score == "X" || score == "10" {
                return tenColor
            } else if score == "9" {
                return nineColor
            }
            return defaultColor
        }
    }

    static func blockGradient(_ colors: [Color]) -> LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct SharedTextStyleModifier: ViewModifier {
    let font: Font
    let color: Color
    let lineSpacing: CGFloat

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
            .lineSpacing(lineSpacing)
    }
}

private struct ClayCardModifier: ViewModifier {
    let tint: Color
    let radius: CGFloat
    let borderOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                SharedStyles.elevatedSurfaceColor,
                                SharedStyles.surfaceColor,
                                tint.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
            }
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: radius - 2, style: .continuous)
                    .stroke(SharedStyles.Shadow.highlight.opacity(0.48), lineWidth: 0.8)
                    .blur(radius: 0.2)
                    .padding(1)
                    .mask(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.15), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: SharedStyles.Shadow.light, radius: 14, x: 0, y: 10)
            .shadow(color: SharedStyles.Shadow.highlight, radius: 10, x: -3, y: -3)
    }
}

private struct BlockSurfaceModifier: ViewModifier {
    let colors: [Color]
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(SharedStyles.blockGradient(colors))
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: colors.last?.opacity(0.14) ?? SharedStyles.Shadow.medium, radius: 14, x: 0, y: 10)
    }
}

private struct CanvasBackgroundModifier: ViewModifier {
    let showsDecorations: Bool

    func body(content: Content) -> some View {
        content.background(
            ZStack {
                SharedStyles.blockGradient(SharedStyles.GradientSet.warmCanvas)

                if showsDecorations {
                    Circle()
                        .fill(SharedStyles.Accent.sky.opacity(0.06))
                        .frame(width: 240, height: 240)
                        .blur(radius: 8)
                        .offset(x: 150, y: -260)

                    Circle()
                        .fill(SharedStyles.Accent.mint.opacity(0.05))
                        .frame(width: 220, height: 220)
                        .blur(radius: 10)
                        .offset(x: -150, y: -140)

                    RoundedRectangle(cornerRadius: 80, style: .continuous)
                        .fill(SharedStyles.Accent.violet.opacity(0.04))
                        .frame(width: 240, height: 220)
                        .rotationEffect(.degrees(18))
                        .offset(x: 130, y: 220)
                }
            }
            .ignoresSafeArea()
        )
    }
}

extension View {
    func sharedTextStyle(
        _ font: Font,
        color: Color = SharedStyles.primaryTextColor,
        lineSpacing: CGFloat = 0
    ) -> some View {
        modifier(
            SharedTextStyleModifier(
                font: font,
                color: color,
                lineSpacing: lineSpacing
            )
        )
    }

    func clayCard(
        tint: Color = SharedStyles.primaryColor,
        radius: CGFloat = SharedStyles.cornerRadius + 6,
        borderOpacity: Double = 0.62
    ) -> some View {
        modifier(ClayCardModifier(tint: tint, radius: radius, borderOpacity: borderOpacity))
    }

    func blockSurface(colors: [Color], radius: CGFloat = SharedStyles.cornerRadius + 8) -> some View {
        modifier(BlockSurfaceModifier(colors: colors, radius: radius))
    }

    func vibrantCanvasBackground(showsDecorations: Bool = false) -> some View {
        modifier(CanvasBackgroundModifier(showsDecorations: showsDecorations))
    }
}

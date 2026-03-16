import SwiftUI

struct AnalysisCardHeading: View {
    let phase: String
    let title: String
    var detail: String? = nil
    var accent: Color = SharedStyles.Accent.sky
    var isDarkBackground: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .sharedTextStyle(
                    SharedStyles.Text.title,
                    color: isDarkBackground ? .white : SharedStyles.primaryTextColor
                )

            if let detail, !detail.isEmpty {
                Text(detail)
                    .sharedTextStyle(
                        SharedStyles.Text.footnote,
                        color: isDarkBackground ? Color.white.opacity(0.72) : SharedStyles.secondaryTextColor,
                        lineSpacing: SharedStyles.captionLineSpacing
                    )
            }
        }
    }
}

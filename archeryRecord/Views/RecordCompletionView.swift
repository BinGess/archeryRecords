import SwiftUI

struct SingleRecordCompletionView: View {
    @Environment(\.dismiss) private var dismiss

    let record: ArcheryRecord
    let onDone: () -> Void

    @EnvironmentObject private var archeryStore: ArcheryStore

    private var analytics: ArcheryAnalytics {
        ScoreAnalytics.calculateSingleRecordAnalytics(record)
    }

    private var bestArrowLabel: String {
        if record.scores.contains("X") {
            return "X"
        }

        let bestValue = record.scores
            .compactMap(scoreValue)
            .max() ?? 0
        return "\(bestValue)"
    }

    private var highlightCount: Int {
        analytics.xRingCount + analytics.tenRingCount
    }

    private var summaryText: String {
        L10n.Completion.singleSummary(for: analytics.averageRing)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    CompletionHeroCard(
                        eyebrow: L10n.Completion.singleEyebrow,
                        title: "\(record.totalScore) \(L10n.Completion.ringUnit)",
                        subtitle: L10n.Completion.singleSubtitle(arrows: record.numberOfArrows, averageRing: analytics.averageRing),
                        colors: SharedStyles.GradientSet.sunrise
                    ) {
                        CompletionMetaRow(items: [
                            (icon: "calendar", text: formatDate(record.date)),
                            (icon: "location", text: record.distance),
                            (icon: "target", text: TargetTypeDisplay.primaryTitle(for: record.targetType))
                        ])
                    }

                    CompletionInsightCard(
                        title: L10n.Completion.summaryTitle,
                        message: summaryText,
                        tint: SharedStyles.Accent.orange
                    )

                    CompletionMetricGrid(metrics: [
                        CompletionMetric(
                            icon: "scope",
                            title: L10n.Completion.averageRing,
                            value: String(format: "%.1f", analytics.averageRing),
                            subtitle: L10n.Completion.ringUnit,
                            tint: SharedStyles.Accent.sky
                        ),
                        CompletionMetric(
                            icon: "star.fill",
                            title: L10n.Completion.highlightHits,
                            value: "\(highlightCount)",
                            subtitle: L10n.Completion.arrowUnit,
                            tint: SharedStyles.Accent.lemon
                        ),
                        CompletionMetric(
                            icon: "bolt.fill",
                            title: L10n.Completion.bestArrow,
                            value: bestArrowLabel,
                            subtitle: "",
                            tint: SharedStyles.Accent.coral
                        ),
                        CompletionMetric(
                            icon: "arrow.up.right.circle",
                            title: L10n.Completion.bowType,
                            value: record.bowType,
                            subtitle: "",
                            tint: SharedStyles.Accent.mint
                        )
                    ])

                    CompletionSectionCard(
                        title: L10n.Completion.singleReviewTitle,
                        caption: L10n.Completion.singleReviewCaption
                    ) {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                            spacing: 10
                        ) {
                            ForEach(Array(record.scores.enumerated()), id: \.offset) { index, score in
                                CompletionScoreChip(
                                    label: L10n.Completion.arrowLabel(index + 1),
                                    score: score
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .padding(.bottom, 90)
            }
            .vibrantCanvasBackground(showsDecorations: true)

            CompletionBottomBar(
                primaryTitle: L10n.Completion.singleAgain,
                primaryColors: SharedStyles.GradientSet.sunrise,
                primaryDestination: ScoreInputView(
                    prefillBowType: record.bowType,
                    distance: record.distance,
                    targetType: record.targetType
                )
                    .environmentObject(archeryStore),
                secondaryTitle: L10n.Common.done,
                secondaryAction: finishFlow
            )
        }
        #if os(iOS)
        .toolbar(.hidden, for: .tabBar)
        #endif
        .customNavigationBar(
            title: L10n.Completion.singleResultTitle,
            leadingButton: finishFlow,
            backgroundColor: SharedStyles.backgroundColor,
            foregroundColor: SharedStyles.primaryTextColor
        )
        .hiddenAppTabBar()
    }

    private func finishFlow() {
        dismiss()

        DispatchQueue.main.async {
            onDone()
        }
    }
}

struct GroupRecordCompletionView: View {
    @Environment(\.dismiss) private var dismiss

    let record: ArcheryGroupRecord
    let onDone: () -> Void

    @EnvironmentObject private var archeryStore: ArcheryStore

    private var analytics: ArcheryAnalytics {
        ScoreAnalytics.calculateGroupRecordAnalytics(record)
    }

    private var totalArrows: Int {
        record.groupScores.flatMap { $0 }.filter { !$0.isEmpty }.count
    }

    private var bestGroupIndex: Int {
        record.groupScores
            .enumerated()
            .max(by: { lhs, rhs in
                record.getGroupScore(lhs.offset) < record.getGroupScore(rhs.offset)
            })?
            .offset ?? 0
    }

    private var bestGroupScore: Int {
        guard !record.groupScores.isEmpty else { return 0 }
        return record.getGroupScore(bestGroupIndex)
    }

    private var highlightCount: Int {
        analytics.xRingCount + analytics.tenRingCount
    }

    private var summaryText: String {
        L10n.Completion.groupSummary(stabilityScore: analytics.stabilityScore, averageRing: analytics.averageRing)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    CompletionHeroCard(
                        eyebrow: L10n.Completion.groupEyebrow,
                        title: "\(record.totalScore) \(L10n.Completion.ringUnit)",
                        subtitle: L10n.Completion.groupSubtitle(groups: record.numberOfGroups, arrows: totalArrows, averageRing: analytics.averageRing),
                        colors: SharedStyles.GradientSet.violet
                    ) {
                        CompletionMetaRow(items: [
                            (icon: "calendar", text: formatDate(record.date)),
                            (icon: "location", text: record.distance),
                            (icon: "target", text: TargetTypeDisplay.primaryTitle(for: record.targetType))
                        ])
                    }

                    CompletionInsightCard(
                        title: L10n.Completion.summaryTitle,
                        message: summaryText,
                        tint: SharedStyles.Accent.violet
                    )

                    CompletionMetricGrid(metrics: [
                        CompletionMetric(
                            icon: "scope",
                            title: L10n.Completion.averageRing,
                            value: String(format: "%.1f", analytics.averageRing),
                            subtitle: L10n.Completion.ringUnit,
                            tint: SharedStyles.Accent.sky
                        ),
                        CompletionMetric(
                            icon: "chart.line.uptrend.xyaxis",
                            title: L10n.Completion.stability,
                            value: String(format: "%.0f", analytics.stabilityScore),
                            subtitle: L10n.Completion.pointUnit,
                            tint: SharedStyles.Accent.mint
                        ),
                        CompletionMetric(
                            icon: "flag.checkered",
                            title: L10n.Completion.bestGroup,
                            value: L10n.Completion.groupLabel(bestGroupIndex + 1),
                            subtitle: L10n.Completion.groupScore(bestGroupScore),
                            tint: SharedStyles.Accent.coral
                        ),
                        CompletionMetric(
                            icon: "star.fill",
                            title: L10n.Completion.highlightHits,
                            value: "\(highlightCount)",
                            subtitle: L10n.Completion.arrowUnit,
                            tint: SharedStyles.Accent.lemon
                        )
                    ])

                    CompletionSectionCard(
                        title: L10n.Completion.groupReviewTitle,
                        caption: L10n.Completion.groupReviewCaption
                    ) {
                        VStack(spacing: 10) {
                            ForEach(Array(record.groupScores.enumerated()), id: \.offset) { index, scores in
                                CompletionGroupRow(
                                    groupIndex: index,
                                    scores: scores,
                                    total: record.getGroupScore(index),
                                    highlight: index == bestGroupIndex
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .padding(.bottom, 90)
            }
            .vibrantCanvasBackground(showsDecorations: true)

            CompletionBottomBar(
                primaryTitle: L10n.Completion.groupAgain,
                primaryColors: SharedStyles.GradientSet.violet,
                primaryDestination: ScoreGroupInputView(
                    prefillBowType: record.bowType,
                    distance: record.distance,
                    targetType: record.targetType,
                    numberOfGroups: record.numberOfGroups,
                    arrowsPerGroup: record.arrowsPerGroup
                )
                    .environmentObject(archeryStore),
                secondaryTitle: L10n.Common.done,
                secondaryAction: finishFlow
            )
        }
        #if os(iOS)
        .toolbar(.hidden, for: .tabBar)
        #endif
        .customNavigationBar(
            title: L10n.Completion.groupResultTitle,
            leadingButton: finishFlow,
            backgroundColor: SharedStyles.backgroundColor,
            foregroundColor: SharedStyles.primaryTextColor
        )
        .hiddenAppTabBar()
    }

    private func finishFlow() {
        dismiss()

        DispatchQueue.main.async {
            onDone()
        }
    }
}

private struct CompletionHeroCard<Content: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let colors: [Color]
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(eyebrow.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.3)
                .foregroundStyle(Color.white.opacity(0.78))

            Text(title)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(subtitle)
                .sharedTextStyle(SharedStyles.Text.bodyEmphasis, color: Color.white.opacity(0.9))

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .blockSurface(colors: colors, radius: 28)
    }
}

private struct CompletionMetaRow: View {
    let items: [(icon: String, text: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 8) {
                    Image(systemName: item.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.76))
                    Text(item.text)
                        .sharedTextStyle(SharedStyles.Text.caption, color: Color.white.opacity(0.88))
                }
            }
        }
    }
}

private struct CompletionInsightCard: View {
    let title: String
    let message: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint)
                Text(title)
                    .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
            }

            Text(message)
                .sharedTextStyle(
                    SharedStyles.Text.body,
                    color: SharedStyles.secondaryTextColor,
                    lineSpacing: SharedStyles.bodyLineSpacing
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .clayCard(tint: tint, radius: 22)
    }
}

private struct CompletionMetric: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let tint: Color
}

private struct CompletionMetricGrid: View {
    let metrics: [CompletionMetric]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(metrics) { metric in
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: metric.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(metric.tint)

                    Text(metric.title)
                        .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(metric.value)
                            .sharedTextStyle(SharedStyles.Text.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        if !metric.subtitle.isEmpty {
                            Text(metric.subtitle)
                                .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
                .padding(16)
                .clayCard(tint: metric.tint, radius: 20)
            }
        }
    }
}

private struct CompletionSectionCard<Content: View>: View {
    let title: String
    let caption: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .sharedTextStyle(SharedStyles.Text.title)

            Text(caption)
                .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .clayCard(tint: SharedStyles.Accent.sky, radius: 24)
    }
}

private struct CompletionScoreChip: View {
    let label: String
    let score: String

    private var tint: Color {
        SharedStyles.Score.color(for: score)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .sharedTextStyle(SharedStyles.Text.microCaption, color: SharedStyles.secondaryTextColor)

            Text(score.isEmpty ? "-" : score)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(score.isEmpty ? SharedStyles.tertiaryTextColor : tint)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SharedStyles.elevatedSurfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(score.isEmpty ? 0.12 : 0.28), lineWidth: 1)
        )
    }
}

private struct CompletionGroupRow: View {
    let groupIndex: Int
    let scores: [String]
    let total: Int
    let highlight: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Completion.groupLabel(groupIndex + 1))
                    .sharedTextStyle(SharedStyles.Text.bodyEmphasis)

                if highlight {
                    Text(L10n.Completion.bestInSession)
                        .sharedTextStyle(SharedStyles.Text.microCaption, color: SharedStyles.Accent.coral)
                }
            }
            .frame(width: 64, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(scores.enumerated()), id: \.offset) { _, score in
                        Text(score.isEmpty ? "-" : score)
                            .sharedTextStyle(
                                SharedStyles.Text.caption,
                                color: score.isEmpty ? SharedStyles.tertiaryTextColor : SharedStyles.Score.color(for: score)
                            )
                            .frame(width: 34, height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(SharedStyles.elevatedSurfaceColor)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
                            )
                    }
                }
            }

            Text("\(total)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(highlight ? SharedStyles.Accent.coral : SharedStyles.primaryTextColor)
                .frame(minWidth: 42, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(highlight ? SharedStyles.Accent.coral.opacity(0.10) : SharedStyles.elevatedSurfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(highlight ? SharedStyles.Accent.coral.opacity(0.22) : Color.white.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct CompletionBottomBar<Destination: View>: View {
    let primaryTitle: String
    let primaryColors: [Color]
    let primaryDestination: Destination
    let secondaryTitle: String
    let secondaryAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: primaryDestination) {
                Text(primaryTitle)
                    .font(SharedStyles.Text.bodyEmphasis)
                    .foregroundStyle(SharedStyles.secondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .clayCard(tint: SharedStyles.Accent.sky, radius: 18)
            }
            .buttonStyle(.plain)

            Button(action: secondaryAction) {
                Text(secondaryTitle)
                    .font(SharedStyles.Text.bodyEmphasis)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .blockSurface(colors: primaryColors, radius: 18)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.72))
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: L10n.getCurrentLanguage())
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

private func scoreValue(_ score: String) -> Int? {
    if score == "X" {
        return 10
    }

    if score == "M" {
        return 0
    }

    return Int(score)
}

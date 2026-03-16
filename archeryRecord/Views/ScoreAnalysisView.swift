import SwiftUI
import Charts
import Foundation

struct ScoreAnalysisView: View {
    @EnvironmentObject var archeryStore: ArcheryStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var timeRange = 0
    @State private var activePaywallFeature: ProFeature?
    
    var body: some View {
        ZStack {
            SharedStyles.blockGradient(SharedStyles.GradientSet.warmCanvas)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                analysisRangePicker

                if filteredRecords.isEmpty && filteredGroupRecords.isEmpty {
                    EmptyAnalysisView()
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            analysisSectionHeader(
                                title: L10n.Analysis.comprehensive,
                                subtitle: L10n.tr("analysis_comprehensive_evaluation"),
                                icon: "chart.xyaxis.line",
                                tint: Color(red: 0.22, green: 0.41, blue: 0.86)
                            )
                            ComprehensiveAnalysisView(
                                records: archeryStore.records,
                                groupRecords: archeryStore.groupRecords,
                                timeRange: timeRange
                            )

                            if purchaseManager.isProUnlocked {
                                analysisSectionHeader(
                                    title: L10n.Analysis.accuracy,
                                    subtitle: L10n.tr("analysis_impact_accuracy"),
                                    icon: "scope",
                                    tint: Color(red: 0.17, green: 0.54, blue: 0.63)
                                )
                                AccuracyAnalysisView(
                                    records: archeryStore.records,
                                    groupRecords: archeryStore.groupRecords,
                                    timeRange: timeRange
                                )

                                analysisSectionHeader(
                                    title: L10n.Analysis.stability,
                                    subtitle: L10n.tr("analysis_stability_assessment"),
                                    icon: "waveform.path.ecg.rectangle",
                                    tint: Color(red: 0.18, green: 0.57, blue: 0.38)
                                )
                                StabilityAnalysisView(
                                    records: archeryStore.records,
                                    groupRecords: archeryStore.groupRecords,
                                    timeRange: timeRange
                                )

                                analysisSectionHeader(
                                    title: L10n.tr("analysis_fatigue"),
                                    subtitle: L10n.tr("analysis_fatigue_assessment"),
                                    icon: "bolt.heart",
                                    tint: Color(red: 0.85, green: 0.44, blue: 0.19)
                                )
                                FatigueAnalysisView(
                                    records: archeryStore.records,
                                    groupRecords: archeryStore.groupRecords,
                                    timeRange: timeRange
                                )
                            } else {
                                AnalysisProUpgradeCard {
                                    activePaywallFeature = .advancedAnalytics
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, contentBottomPadding)
                    }
                }
            }
        }
        #if os(iOS)
        .navigationBarTitle(L10n.Analysis.title, displayMode: .inline)
        #else
        .navigationTitle(L10n.Analysis.title)
        #endif
        .sheet(item: $activePaywallFeature) { _ in
            ProPaywallView()
                .environmentObject(purchaseManager)
        }
    }

    private var analysisRangePicker: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Analysis.title)
                        .sharedTextStyle(SharedStyles.Text.title)

                    Text(selectedTimeLabel)
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }

                Spacer()

                Label(trendSummary.momentum.localizedLabel, systemImage: trendSummary.momentum.symbolName)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(SharedStyles.groupBackgroundColor)
                    .foregroundColor(trendSummary.momentum.color)
                    .clipShape(Capsule())
            }

            Picker(L10n.Analysis.timeRange, selection: $timeRange) {
                Text(L10n.Time.today).tag(0)
                Text(L10n.Time.week).tag(1)
                Text(L10n.Time.month).tag(2)
                Text(L10n.Time.year).tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .clayCard(tint: SharedStyles.Accent.sky, radius: 22)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var filteredData: (records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord]) {
        ScoreAnalytics.filterRecords(
            records: archeryStore.records,
            groupRecords: archeryStore.groupRecords,
            timeRange: timeRange
        )
    }

    private var filteredRecords: [ArcheryRecord] {
        filteredData.records
    }

    private var filteredGroupRecords: [ArcheryGroupRecord] {
        filteredData.groupRecords
    }

    private var trendSummary: ScoreTrendSummary {
        ScoreAnalytics.calculateTrendSummary(
            records: archeryStore.records,
            groupRecords: archeryStore.groupRecords,
            timeRange: timeRange
        )
    }

    private var selectedTimeLabel: String {
        switch timeRange {
        case 0: return L10n.Time.today
        case 1: return L10n.Time.week
        case 2: return L10n.Time.month
        case 3: return L10n.Time.year
        default: return L10n.Time.month
        }
    }

    private var contentBottomPadding: CGFloat {
        purchaseManager.isProUnlocked ? 96 : 140
    }

    private func analysisSectionHeader(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .sharedTextStyle(SharedStyles.Text.title)

                Text(subtitle)
                    .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
            }

            Spacer()
        }
    }
}

private struct AnalysisProUpgradeCard: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SharedStyles.Accent.orange)
                    .frame(width: 42, height: 42)
                    .background(SharedStyles.Accent.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.AnalysisUpgrade.title)
                        .sharedTextStyle(SharedStyles.Text.title)

                    Text(L10n.AnalysisUpgrade.subtitle)
                        .sharedTextStyle(
                            SharedStyles.Text.caption,
                            color: SharedStyles.secondaryTextColor,
                            lineSpacing: SharedStyles.captionLineSpacing
                        )
                }
            }

            HStack(spacing: 10) {
                lockedChip(title: L10n.AnalysisUpgrade.accuracy)
                lockedChip(title: L10n.AnalysisUpgrade.stability)
                lockedChip(title: L10n.AnalysisUpgrade.fatigue)
            }

            Button(action: action) {
                HStack {
                    Spacer()
                    Text(L10n.AnalysisUpgrade.cta)
                        .font(SharedStyles.Text.bodyEmphasis)
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
            .blockSurface(colors: SharedStyles.GradientSet.sunrise, radius: 18)
        }
        .padding(20)
        .clayCard(tint: SharedStyles.Accent.orange, radius: 24)
    }

    private func lockedChip(title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .bold))
            Text(title)
                .font(SharedStyles.Text.microCaption)
        }
        .foregroundStyle(SharedStyles.primaryTextColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.74))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 简化的分析视图

struct AccuracyAnalysisView: View {
    let records: [ArcheryRecord]
    let groupRecords: [ArcheryGroupRecord]
    let timeRange: Int
    
    var body: some View {
        VStack(spacing: 20) {
            accuracyScoreCard
            impactAccuracyCard
            coachInsights
        }
    }
    
    private var accuracyScoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AnalysisCardHeading(
                phase: L10n.AnalysisCardCopy.phaseConclusion,
                title: L10n.AnalysisCardCopy.accuracyConclusionTitle,
                detail: L10n.AnalysisCardCopy.accuracyConclusionDetail,
                accent: SharedStyles.Accent.sky
            )
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f", accuracyStats.averageScore))")
                        .sharedTextStyle(SharedStyles.Text.metricValue)
                    
                    Text(L10n.tr("analysis_average_ring"))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(accuracyStats.accuracyGrade)
                        .font(SharedStyles.Text.title)
                        .foregroundColor(gradeColor(accuracyStats.accuracyGrade))
                    
                    Text(L10n.tr("analysis_accuracy_grade"))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f%%", accuracyStats.tenRingRate))")
                        .sharedTextStyle(SharedStyles.Text.title)
                    Text(L10n.tr("analysis_ten_ring_rate"))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(accuracyStats.groupTightness)
                        .sharedTextStyle(SharedStyles.Text.title)
                    Text(L10n.tr("analysis_group_tightness"))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
            }
        }
        .padding()
        .analysisCardSurface()
    }
    
    private var impactAccuracyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                AnalysisCardHeading(
                    phase: L10n.AnalysisCardCopy.phaseChart,
                    title: L10n.AnalysisCardCopy.impactDistributionTitle,
                    detail: impactAnalysis.scopeDescription ?? L10n.AnalysisCardCopy.impactDistributionDetail,
                    accent: .orange
                )

                Spacer()

                if impactAnalysis.hasData {
                    Label(impactAnalysis.biasDirection.localizedLabel, systemImage: impactAnalysis.biasDirection.symbolName)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(biasBadgeColor.opacity(0.12))
                        .foregroundColor(biasBadgeColor)
                        .clipShape(Capsule())
                }
            }

            if impactAnalysis.hasData {
                HStack(alignment: .top, spacing: 16) {
                    ImpactTargetPreview(summary: impactAnalysis)

                    VStack(spacing: 10) {
                        compactMetric(
                            title: L10n.tr("analysis_grouping_radius"),
                            value: String(format: "%.1fcm", impactAnalysis.groupingRadius95),
                            accent: .blue
                        )
                        compactMetric(
                            title: L10n.tr("analysis_center_offset"),
                            value: String(format: "%.1fcm", impactAnalysis.centerOffset),
                            accent: .orange
                        )
                        compactMetric(
                            title: L10n.tr("analysis_coordinate_hits"),
                            value: "\(impactAnalysis.totalHits)",
                            accent: .green
                        )
                        compactMetric(
                            title: L10n.tr("analysis_bias_direction"),
                            value: impactAnalysis.biasDirection.localizedLabel,
                            accent: biasBadgeColor
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.tr("analysis_impact_no_real_data"))
                        .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
                    Text(L10n.tr("analysis_impact_no_real_data_subtitle"))
                        .sharedTextStyle(
                            SharedStyles.Text.caption,
                            color: SharedStyles.secondaryTextColor,
                            lineSpacing: SharedStyles.captionLineSpacing
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }
        }
        .padding()
        .analysisCardSurface()
    }
    
    private var coachInsights: some View {
        VStack(alignment: .leading, spacing: 12) {
            AnalysisCardHeading(
                phase: L10n.AnalysisCardCopy.phaseAction,
                title: L10n.AnalysisCardCopy.accuracyAdviceTitle,
                detail: L10n.AnalysisCardCopy.accuracyAdviceDetail,
                accent: .green
            )

            Text(accuracyAdviceSummary)
                .sharedTextStyle(
                    SharedStyles.Text.body,
                    color: SharedStyles.secondaryTextColor,
                    lineSpacing: SharedStyles.bodyLineSpacing
                )
                .lineLimit(nil)

            if impactAnalysis.insights.isEmpty {
                Text(L10n.tr("analysis_impact_no_real_data_subtitle"))
                    .sharedTextStyle(
                        SharedStyles.Text.caption,
                        color: SharedStyles.secondaryTextColor,
                        lineSpacing: SharedStyles.captionLineSpacing
                    )
            } else {
                ForEach(impactAnalysis.insights) { insight in
                    CoachInsightRow(insight: insight)
                }
            }
        }
        .padding()
        .analysisCardSurface()
    }

    private var accuracyAdviceSummary: String {
        ScoreAnalytics.generateAccuracyAnalysis(
            stats: (
                spreadRadius: accuracyStats.spreadRadius,
                groupTightness: accuracyStats.groupTightness,
                accuracyGrade: accuracyStats.accuracyGrade
            )
        )
    }
    
    private var accuracyStats: (averageScore: Double, tenRingRate: Double, spreadRadius: Double, groupTightness: String, accuracyGrade: String) {
        let summary = ScoreAnalytics.aggregateAccuracySummary(records: records, groupRecords: groupRecords, timeRange: timeRange)
        return (
            summary.averageScore,
            summary.tenRingRate,
            summary.spreadRadius,
            summary.groupTightness,
            summary.accuracyGrade
        )
    }

    private var impactAnalysis: ImpactAnalysisSummary {
        ScoreAnalytics.calculateImpactAnalysis(records: records, groupRecords: groupRecords, timeRange: timeRange)
    }

    private var biasBadgeColor: Color {
        impactAnalysis.biasDirection == .centered ? .green : .orange
    }
    
    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case L10n.tr("analysis_grade_excellent"): return .green
        case L10n.tr("analysis_grade_good"): return .blue
        case L10n.tr("analysis_grade_average"): return .orange
        case L10n.tr("analysis_grade_improve"): return .red
        default: return .gray
        }
    }

    private func compactMetric(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)

            Text(value)
                .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(accent.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
        .cornerRadius(10)
    }
}

private struct ImpactTargetPreview: View {
    let summary: ImpactAnalysisSummary
    private let canvasSize: CGFloat = 180

    var body: some View {
        ZStack {
            if let targetFace = summary.targetFace {
                TargetFaceView(
                    targetFace: targetFace,
                    size: CGSize(width: canvasSize, height: canvasSize),
                    showLabels: false
                )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: canvasSize, height: canvasSize)
            }

            if let targetFace = summary.targetFace {
                ForEach(summary.points) { point in
                    Circle()
                        .fill(ScoreAnalytics.ringColor(for: point.score))
                        .frame(width: 7, height: 7)
                        .position(position(for: point.position, targetFace: targetFace))
                        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                }

                Circle()
                    .stroke(Color.blue.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    .frame(
                        width: circleDiameter(targetFace: targetFace),
                        height: circleDiameter(targetFace: targetFace)
                    )
                    .position(position(for: summary.centroid, targetFace: targetFace))

                Circle()
                    .fill(Color.orange)
                    .frame(width: 9, height: 9)
                    .position(position(for: summary.centroid, targetFace: targetFace))
            }
        }
        .frame(width: canvasSize, height: canvasSize)
    }

    private func position(for point: CGPoint, targetFace: TargetFace) -> CGPoint {
        let scale = (canvasSize / 2) / CGFloat(targetFace.diameter / 2)
        return CGPoint(
            x: canvasSize / 2 + point.x * scale,
            y: canvasSize / 2 + point.y * scale
        )
    }

    private func circleDiameter(targetFace: TargetFace) -> CGFloat {
        let scale = (canvasSize / 2) / CGFloat(targetFace.diameter / 2)
        return CGFloat(summary.groupingRadius95 * 2) * scale
    }
}

private struct CoachInsightRow: View {
    let insight: ImpactInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 32, height: 32)
                .background(Color.orange.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
                Text(insight.message)
                    .sharedTextStyle(
                        SharedStyles.Text.caption,
                        color: SharedStyles.secondaryTextColor,
                        lineSpacing: SharedStyles.captionLineSpacing
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(0.75))
        .cornerRadius(10)
    }
}

struct StabilityAnalysisView: View {
    let records: [ArcheryRecord]
    let groupRecords: [ArcheryGroupRecord]
    let timeRange: Int
    
    var body: some View {
        VStack(spacing: 20) {
            stabilityScoreCard
            controlChart
            stabilityAdvice
        }
    }
    
    private var stabilityScoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AnalysisCardHeading(
                phase: L10n.AnalysisCardCopy.phaseConclusion,
                title: L10n.AnalysisCardCopy.stabilityConclusionTitle,
                detail: L10n.AnalysisCardCopy.stabilityConclusionDetail,
                accent: SharedStyles.Accent.sky
            )
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f", stabilityData.stabilityScore))")
                        .sharedTextStyle(SharedStyles.Text.metricValue)
                    
                    Text(L10n.tr("analysis_stability_score"))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(ScoreAnalytics.getStabilityLevel(stabilityData.stabilityScore))
                        .font(SharedStyles.Text.title)
                        .foregroundColor(ScoreAnalytics.getStabilityLevelColor(stabilityData.stabilityScore))
                    
                    Text(L10n.tr("analysis_stability_grade"))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.2f%%", stabilityData.coefficientOfVariation * 100))")
                        .sharedTextStyle(SharedStyles.Text.title)
                    Text(L10n.tr("analysis_coefficient_variation"))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(String(format: "%.1f", stabilityData.standardDeviation))")
                        .sharedTextStyle(SharedStyles.Text.title)
                    Text(L10n.Analysis.standardDeviation)
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
            }
        }
        .padding()
        .analysisCardSurface()
    }
    
    private var controlChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            AnalysisCardHeading(
                phase: L10n.AnalysisCardCopy.phaseChart,
                title: L10n.AnalysisCardCopy.stabilityChartTitle,
                detail: L10n.AnalysisCardCopy.stabilityChartDetail,
                accent: .orange
            )
            
            if !stabilityData.groupScores.isEmpty {
                Chart {
                    // 数据点
                    ForEach(Array(stabilityData.groupScores.enumerated()), id: \.offset) { index, score in
                        LineMark(
                            x: .value(L10n.tr("analysis_index"), index + 1),
                            y: .value(L10n.Analysis.score, score)
                        )
                        .foregroundStyle(.blue)
                        
                        PointMark(
                            x: .value(L10n.tr("analysis_index"), index + 1),
                            y: .value(L10n.Analysis.score, score)
                        )
                        .foregroundStyle(.blue)
                    }
                    
                    // 上控制线
                    RuleMark(y: .value(L10n.tr("analysis_control_upper"), stabilityData.upperLimit))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    
                    // 下控制线
                    RuleMark(y: .value(L10n.tr("analysis_control_lower"), stabilityData.lowerLimit))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    
                    // 平均线
                    RuleMark(y: .value(L10n.tr("analysis_average_line"), stabilityData.groupScores.reduce(0, +) / Double(stabilityData.groupScores.count)))
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
            } else {
                Text(L10n.Analysis.noData)
                    .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor)
                    .frame(height: 200)
            }
        }
        .padding()
        .analysisCardSurface()
    }
    
    private var stabilityAdvice: some View {
        VStack(alignment: .leading, spacing: 12) {
            AnalysisCardHeading(
                phase: L10n.AnalysisCardCopy.phaseAction,
                title: L10n.AnalysisCardCopy.stabilityAdviceTitle,
                detail: L10n.AnalysisCardCopy.stabilityAdviceDetail,
                accent: .green
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(ScoreAnalytics.generateStabilityAnalysisForGroup(score: stabilityData.stabilityScore, cv: stabilityData.coefficientOfVariation * 100))
                    .sharedTextStyle(SharedStyles.Text.body, lineSpacing: SharedStyles.bodyLineSpacing)
                
                Text(ScoreAnalytics.generateStabilityTrainingAdvice(score: stabilityData.stabilityScore, cv: stabilityData.coefficientOfVariation * 100))
                    .sharedTextStyle(
                        SharedStyles.Text.body,
                        color: SharedStyles.secondaryTextColor,
                        lineSpacing: SharedStyles.bodyLineSpacing
                    )
            }
        }
        .padding()
        .analysisCardSurface()
    }
    
    private var stabilityData: (stabilityScore: Double, coefficientOfVariation: Double, standardDeviation: Double, groupScores: [Double], upperLimit: Double, lowerLimit: Double) {
        let filteredData = ScoreAnalytics.filterRecords(records: records, groupRecords: groupRecords, timeRange: timeRange)
        let allScores = (filteredData.records.flatMap(\.scores) + filteredData.groupRecords.flatMap { $0.groupScores.flatMap { $0 } })
            .map(scoreValue)

        if allScores.isEmpty {
            return (0, 0, 0, [], 0, 0)
        }

        let average = Double(allScores.reduce(0, +)) / Double(allScores.count)
        let variance = allScores.map { pow(Double($0) - average, 2) }.reduce(0, +) / Double(allScores.count)
        let standardDeviation = sqrt(variance)
        let stabilityScore = max(0, 100 - standardDeviation * 10)

        let coefficientOfVariation = average > 0 ? standardDeviation / average : 0
        let groupScores = allScores.map(Double.init)
        let upperLimit = average + 2 * standardDeviation
        let lowerLimit = average - 2 * standardDeviation

        return (stabilityScore, coefficientOfVariation, standardDeviation, groupScores, upperLimit, lowerLimit)
    }

    private func scoreValue(_ score: String) -> Int {
        switch score.uppercased() {
        case "X":
            return 10
        case "M":
            return 0
        default:
            return Int(score) ?? 0
        }
    }
}

struct FatigueAnalysisView: View {
    let records: [ArcheryRecord]
    let groupRecords: [ArcheryGroupRecord]
    let timeRange: Int
    
    var body: some View {
        VStack(spacing: 20) {
            fatigueIndexCard
            fatigueTrendChart
            fatigueAdvice
        }
    }
    
    private var fatigueIndexCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AnalysisCardHeading(
                phase: L10n.AnalysisCardCopy.phaseConclusion,
                title: L10n.AnalysisCardCopy.fatigueConclusionTitle,
                detail: L10n.AnalysisCardCopy.fatigueConclusionDetail,
                accent: SharedStyles.Accent.sky
            )
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f", fatigueData.fatigueIndex))")
                        .sharedTextStyle(SharedStyles.Text.metricValue)
                    
                    Text(L10n.tr("analysis_fatigue_index"))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(ScoreAnalytics.getFatigueLevel(fatigueData.fatigueIndex))
                        .font(SharedStyles.Text.title)
                        .foregroundColor(ScoreAnalytics.getFatigueIndexColor(fatigueData.fatigueIndex))
                    
                    Text(L10n.tr("analysis_fatigue_grade"))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f", fatigueData.firstHalfAverage))")
                        .sharedTextStyle(SharedStyles.Text.title)
                    Text(L10n.tr("analysis_first_half_average"))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(String(format: "%.1f", fatigueData.secondHalfAverage))")
                        .sharedTextStyle(SharedStyles.Text.title)
                    Text(L10n.tr("analysis_second_half_average"))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
            }
        }
        .padding()
        .analysisCardSurface()
    }
    
    private var fatigueTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            AnalysisCardHeading(
                phase: L10n.AnalysisCardCopy.phaseChart,
                title: L10n.AnalysisCardCopy.fatigueTrendTitle,
                detail: L10n.AnalysisCardCopy.fatigueTrendDetail,
                accent: .orange
            )
            
            if !fatigueData.scores.isEmpty {
                Chart {
                    ForEach(Array(fatigueData.scores.enumerated()), id: \.offset) { index, score in
                        LineMark(
                            x: .value(L10n.tr("analysis_arrow_count_axis"), index + 1),
                            y: .value(L10n.tr("analysis_ring_axis"), score)
                        )
                        .foregroundStyle(.blue)
                        
                        PointMark(
                            x: .value(L10n.tr("analysis_arrow_count_axis"), index + 1),
                            y: .value(L10n.tr("analysis_ring_axis"), score)
                        )
                        .foregroundStyle(.blue)
                    }
                    
                    // 前半段平均线
                    if fatigueData.scores.count > 1 {
                        RuleMark(y: .value(L10n.tr("analysis_first_half_average"), fatigueData.firstHalfAverage))
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        
                        // 后半段平均线
                        RuleMark(y: .value(L10n.tr("analysis_second_half_average"), fatigueData.secondHalfAverage))
                            .foregroundStyle(.orange)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
            } else {
                Text(L10n.Analysis.noData)
                    .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor)
                    .frame(height: 200)
            }
        }
        .padding()
        .analysisCardSurface()
    }
    
    private var fatigueAdvice: some View {
        VStack(alignment: .leading, spacing: 12) {
            AnalysisCardHeading(
                phase: L10n.AnalysisCardCopy.phaseAction,
                title: L10n.AnalysisCardCopy.fatigueAdviceTitle,
                detail: L10n.AnalysisCardCopy.fatigueAdviceDetail,
                accent: .green
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(ScoreAnalytics.generateFatigueAnalysis(index: fatigueData.fatigueIndex))
                    .sharedTextStyle(SharedStyles.Text.body, lineSpacing: SharedStyles.bodyLineSpacing)
                
                Text(ScoreAnalytics.generateFatigueTrainingAdvice(index: fatigueData.fatigueIndex))
                    .sharedTextStyle(
                        SharedStyles.Text.body,
                        color: SharedStyles.secondaryTextColor,
                        lineSpacing: SharedStyles.bodyLineSpacing
                    )
            }
        }
        .padding()
        .analysisCardSurface()
    }
    
    private var fatigueData: (fatigueIndex: Double, firstHalfAverage: Double, secondHalfAverage: Double, scores: [Int]) {
        let filteredData = ScoreAnalytics.filterRecords(records: records, groupRecords: groupRecords, timeRange: timeRange)
        let allScores = (filteredData.records.flatMap(\.scores) + filteredData.groupRecords.flatMap { $0.groupScores.flatMap { $0 } })
            .map(scoreValue)

        if allScores.isEmpty {
            return (0, 0, 0, [])
        }

        guard allScores.count > 1 else {
            return (0, 0, 0, allScores)
        }
        
        let firstHalf = Array(allScores.prefix(allScores.count / 2))
        let secondHalf = Array(allScores.suffix(allScores.count / 2))
        
        let firstAvg = firstHalf.isEmpty ? 0 : Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
        let secondAvg = secondHalf.isEmpty ? 0 : Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
        
        let fatigueIndex = firstAvg > 0 ? max(0, (firstAvg - secondAvg) / firstAvg * 100) : 0
        
        return (fatigueIndex, firstAvg, secondAvg, allScores)
    }

    private func scoreValue(_ score: String) -> Int {
        switch score.uppercased() {
        case "X":
            return 10
        case "M":
            return 0
        default:
            return Int(score) ?? 0
        }
    }
}

private extension View {
    func analysisCardSurface() -> some View {
        self
            .clayCard(tint: SharedStyles.Accent.sky, radius: 18)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
    }
}

struct EmptyAnalysisView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundStyle(SharedStyles.tertiaryTextColor)
            
            Text(L10n.tr("analysis_empty_prompt"))
                .sharedTextStyle(
                    SharedStyles.Text.body,
                    color: SharedStyles.secondaryTextColor,
                    lineSpacing: SharedStyles.bodyLineSpacing
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clayCard(tint: SharedStyles.Accent.sky, radius: 24)
    }
}

#Preview {
    ScoreAnalysisView()
}

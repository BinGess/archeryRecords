import SwiftUI
import Charts

struct ComprehensiveAnalysisView: View {
    let records: [ArcheryRecord]
    let groupRecords: [ArcheryGroupRecord]
    let timeRange: Int
    
    var body: some View {
        let filteredData = ScoreAnalytics.filterRecords(records: records, groupRecords: groupRecords, timeRange: timeRange)
        let filteredRecords = filteredData.records
        let filteredGroupRecords = filteredData.groupRecords

        return Group {
            if filteredRecords.isEmpty && filteredGroupRecords.isEmpty {
                EmptyView()
            } else {
                VStack(spacing: 20) {
                    totalScoreCard(filteredRecords, filteredGroupRecords)
                    coreMetricsSection(filteredRecords, filteredGroupRecords)
                    ringAnalysisSection(filteredRecords, filteredGroupRecords)
                    comprehensiveEvaluationSection(filteredRecords, filteredGroupRecords)
                }
            }
        }
    }

    // MARK: - 辅助方法
    
    /// 总成绩卡片
    private func totalScoreCard(_ records: [ArcheryRecord], _ groupRecords: [ArcheryGroupRecord]) -> some View {
        let totalScore = calculateTotalScore(records, groupRecords)
        let totalShots = calculateTotalShots(records, groupRecords)
        let trendSummary = ScoreAnalytics.calculateTrendSummary(records: records, groupRecords: groupRecords, timeRange: 4)
        
        return VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.18, blue: 0.30),
                        Color(red: 0.55, green: 0.20, blue: 0.18),
                        Color(red: 0.91, green: 0.54, blue: 0.17)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(16)
                
                VStack(spacing: 16) {
                    HStack {
                        AnalysisCardHeading(
                            phase: L10n.AnalysisCardCopy.phaseConclusion,
                            title: L10n.AnalysisCardCopy.comprehensiveConclusionTitle,
                            detail: L10n.tr("analysis_sessions_with_value", trendSummary.sessionCount),
                            accent: .white,
                            isDarkBackground: true
                        )
                        
                        Spacer()
                        
                        Label(trendSummary.momentum.localizedLabel, systemImage: trendSummary.momentum.symbolName)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.16))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(format: "%.1f", trendSummary.overallAverage))
                                .sharedTextStyle(SharedStyles.Text.metricValue, color: .white)

                            Text(L10n.tr("analysis_average_ring"))
                                .sharedTextStyle(SharedStyles.Text.caption, color: .white.opacity(0.85))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            Text(formatTrend(trendSummary.recentChangePercent))
                                .font(SharedStyles.Text.compactValue)
                                .foregroundColor(trendSummary.momentum == .falling ? Color(red: 1.0, green: 0.86, blue: 0.86) : Color.white)

                            Text(L10n.Analysis.recentTrend)
                                .sharedTextStyle(SharedStyles.Text.footnote, color: .white.opacity(0.75))
                        }
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                        trendMetricChip(
                            title: L10n.tr("analysis_latest_session_avg"),
                            value: String(format: "%.1f", trendSummary.latestAverage)
                        )
                        trendMetricChip(
                            title: L10n.tr("analysis_recent_sessions_avg"),
                            value: String(format: "%.1f", trendSummary.recentAverage)
                        )
                        trendMetricChip(
                            title: L10n.tr("analysis_trend_baseline_avg"),
                            value: String(format: "%.1f", trendSummary.baselineAverage)
                        )
                        trendMetricChip(
                            title: L10n.tr("analysis_best_session_avg"),
                            value: String(format: "%.1f", trendSummary.bestAverage)
                        )
                    }

                    if !trendSummary.points.isEmpty {
                        Chart {
                            ForEach(trendSummary.points, id: \.date) { point in
                                PointMark(
                                    x: .value(L10n.Analysis.date, point.date),
                                    y: .value(L10n.Analysis.score, point.score)
                                )
                                .foregroundStyle(Color.white.opacity(0.75))
                                .symbolSize(28)
                            }

                            ForEach(trendSummary.rollingAveragePoints, id: \.date) { point in
                                LineMark(
                                    x: .value(L10n.Analysis.date, point.date),
                                    y: .value(L10n.tr("analysis_rolling_average"), point.score)
                                )
                                .foregroundStyle(Color.white)
                                .lineStyle(StrokeStyle(lineWidth: 3))
                                .interpolationMethod(.monotone)
                            }
                        }
                        .frame(height: 120)
                        .chartLegend(.hidden)
                        .chartYAxis(.hidden)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 3)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                                    .foregroundStyle(Color.white.opacity(0.16))
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                                    .foregroundStyle(Color.white.opacity(0.75))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(trendSummary.insight.title)
                                .sharedTextStyle(SharedStyles.Text.bodyEmphasis, color: .white)

                            Spacer()

                            if trendSummary.hasEnoughHistory {
                                Text(formatTrend(trendSummary.recentChangePercent))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.92))
                            }
                        }

                        Text(trendSummary.insight.message)
                            .sharedTextStyle(
                                SharedStyles.Text.footnote,
                                color: .white.opacity(0.82),
                                lineSpacing: SharedStyles.captionLineSpacing
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.black.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .cornerRadius(14)
                    
                    HStack {
                        Text(L10n.tr("analysis_total_arrows_with_value", totalShots))
                            .sharedTextStyle(SharedStyles.Text.caption, color: .white.opacity(0.8))
                        
                        Spacer()
                        
                        Text(L10n.tr("analysis_total_score_with_value", totalScore))
                            .sharedTextStyle(SharedStyles.Text.caption, color: .white.opacity(0.8))

                        Spacer()

                        Text(L10n.tr("analysis_sessions_with_value", trendSummary.sessionCount))
                            .sharedTextStyle(SharedStyles.Text.caption, color: .white.opacity(0.8))
                    }
                }
                .padding(20)
            }
        }
    }
    
    /// 核心指标区域
    private func coreMetricsSection(_ records: [ArcheryRecord], _ groupRecords: [ArcheryGroupRecord]) -> some View {
        let analytics = calculateAnalytics(records, groupRecords)
        
        return VStack(alignment: .leading, spacing: 16) {
            AnalysisCardHeading(
                phase: L10n.AnalysisCardCopy.phaseChart,
                title: L10n.AnalysisCardCopy.coreMetricsTitle,
                detail: L10n.AnalysisCardCopy.coreMetricsDetail,
                accent: SharedStyles.Accent.sky
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                // 平均环数
                MetricCard(
                    icon: "target",
                    title: L10n.tr("analysis_average_ring"),
                    value: String(format: "%.1f", analytics.averageRing),
                    subtitle: L10n.tr("analysis_ring_unit"),
                    color: .blue
                )
                
                // 稳定性评分
                MetricCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: L10n.Analysis.stability,
                    value: String(format: "%.0f", analytics.stabilityScore),
                    subtitle: L10n.tr("content_points_unit"),
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                // 疲劳指数
                MetricCard(
                    icon: "bolt.fill",
                    title: L10n.tr("analysis_fatigue_index"),
                    value: String(format: "%.0f%%", analytics.fatigueIndex),
                    subtitle: "",
                    color: .orange
                )
                
                // 10环率
                MetricCard(
                    icon: "scope",
                    title: L10n.tr("analysis_ten_ring_rate"),
                    value: String(format: "%.0f%%", analytics.tenRingRate),
                    subtitle: "",
                    color: .purple
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    /// 环数分析区域
    private func ringAnalysisSection(_ records: [ArcheryRecord], _ groupRecords: [ArcheryGroupRecord]) -> some View {
        let ringStats = calculateRingDistribution(records, groupRecords)
        
        return VStack(alignment: .leading, spacing: 16) {
            AnalysisCardHeading(
                phase: L10n.AnalysisCardCopy.phaseChart,
                title: L10n.AnalysisCardCopy.ringStructureTitle,
                detail: L10n.AnalysisCardCopy.ringStructureDetail,
                accent: .orange
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(Array(ringStats.sorted(by: { $0.key > $1.key })), id: \.key) { ring, count in
                    let totalShots = calculateTotalShots(records, groupRecords)
                    RingStatCard(
                        ring: L10n.tr("analysis_ring_label", ring),
                        count: count,
                        total: totalShots,
                        color: ringColor(for: ring)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    /// 综合评估区域
    private func comprehensiveEvaluationSection(_ records: [ArcheryRecord], _ groupRecords: [ArcheryGroupRecord]) -> some View {
        let analytics = calculateAnalytics(records, groupRecords)
        let evaluation = generateComprehensiveEvaluation(analytics)
        
        return VStack(alignment: .leading, spacing: 16) {
            AnalysisCardHeading(
                phase: L10n.AnalysisCardCopy.phaseAction,
                title: L10n.AnalysisCardCopy.trainingAdviceTitle,
                detail: L10n.AnalysisCardCopy.trainingAdviceDetail,
                accent: .green
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(evaluation)
                    .sharedTextStyle(
                        SharedStyles.Text.body,
                        color: SharedStyles.secondaryTextColor,
                        lineSpacing: SharedStyles.bodyLineSpacing
                    )
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - 计算方法
    
    private func calculateTotalScore(_ records: [ArcheryRecord], _ groupRecords: [ArcheryGroupRecord]) -> Int {
        let recordsScore = records.reduce(0) { $0 + $1.totalScore }
        let groupRecordsScore = groupRecords.reduce(0) { total, record in
            total + record.totalScore
        }
        return recordsScore + groupRecordsScore
    }
    
    private func calculateTotalShots(_ records: [ArcheryRecord], _ groupRecords: [ArcheryGroupRecord]) -> Int {
        let recordsShots = records.reduce(0) { $0 + $1.scores.count }
        let groupRecordsShots = groupRecords.reduce(0) { total, record in
            total + record.groupScores.flatMap { $0 }.count
        }
        return recordsShots + groupRecordsShots
    }
    
    private func calculateAnalytics(_ records: [ArcheryRecord], _ groupRecords: [ArcheryGroupRecord]) -> ArcheryAnalytics {
        let totalScore = calculateTotalScore(records, groupRecords)
        let totalShots = calculateTotalShots(records, groupRecords)
        let averageRing = totalShots > 0 ? Double(totalScore) / Double(totalShots) : 0.0
        
        // 计算稳定性评分
        let allScores = getAllScores(records, groupRecords)
        let stabilityScore = calculateStabilityScore(allScores)
        
        // 计算疲劳指数
        let fatigueIndex = calculateFatigueIndex(allScores)
        
        // 计算各环数统计
        let xRingCount = countRings(records, groupRecords, ring: "X")
        let tenRingCount = countRings(records, groupRecords, ring: "10")
        let nineRingCount = countRings(records, groupRecords, ring: "9")
        let tenRingRate = totalShots > 0 ? (Double(tenRingCount + xRingCount) / Double(totalShots)) * 100 : 0.0
        
        return ArcheryAnalytics(
            averageRing: averageRing,
            stabilityScore: stabilityScore,
            fatigueIndex: fatigueIndex,
            tenRingRate: tenRingRate,
            xRingCount: xRingCount,
            tenRingCount: tenRingCount,
            nineRingCount: nineRingCount,
            totalArrows: totalShots
        )
    }
    
    private func getAllScores(_ records: [ArcheryRecord], _ groupRecords: [ArcheryGroupRecord]) -> [Double] {
        var allScores: [Double] = []
        
        // 添加单箭记录
        for record in records {
            for scoreStr in record.scores {
                if let score = Double(scoreStr) {
                    allScores.append(score)
                } else if scoreStr.uppercased() == "X" {
                    allScores.append(10.0)
                } else if scoreStr.uppercased() == "M" {
                    allScores.append(0.0)
                }
            }
        }
        
        // 添加组记录
        for groupRecord in groupRecords {
            for group in groupRecord.groupScores {
                for scoreStr in group {
                    if let score = Double(scoreStr) {
                        allScores.append(score)
                    } else if scoreStr.uppercased() == "X" {
                        allScores.append(10.0)
                    } else if scoreStr.uppercased() == "M" {
                        allScores.append(0.0)
                    }
                }
            }
        }
        
        return allScores
    }
    
    private func calculateStabilityScore(_ scores: [Double]) -> Double {
        guard scores.count > 1 else { return 100.0 }
        
        let average = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.map { pow($0 - average, 2) }.reduce(0, +) / Double(scores.count)
        let standardDeviation = sqrt(variance)
        let coefficientOfVariation = average > 0 ? (standardDeviation / average) * 100 : 0
        
        // 稳定性评分：变异系数越小，稳定性越高
        return max(0, 100 - coefficientOfVariation * 10)
    }
    
    private func calculateFatigueIndex(_ scores: [Double]) -> Double {
        guard scores.count >= 6 else { return 0.0 }
        
        let firstHalf = Array(scores.prefix(scores.count / 2))
        let secondHalf = Array(scores.suffix(scores.count / 2))
        
        let firstAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let decline = (firstAverage - secondAverage) / firstAverage * 100
        return max(0, decline)
    }
    
    private func countRings(_ records: [ArcheryRecord], _ groupRecords: [ArcheryGroupRecord], ring: String) -> Int {
        var count = 0
        
        // 计算单箭记录
        for record in records {
            if ring.uppercased() == "X" {
                count += record.scores.filter { $0.uppercased() == "X" }.count
            } else {
                count += record.scores.filter { $0 == ring }.count
            }
        }
        
        // 计算组记录
        for groupRecord in groupRecords {
            for group in groupRecord.groupScores {
                if ring.uppercased() == "X" {
                    count += group.filter { $0.uppercased() == "X" }.count
                } else {
                    count += group.filter { $0 == ring }.count
                }
            }
        }
        
        return count
    }
    
    private func calculateRingDistribution(_ records: [ArcheryRecord], _ groupRecords: [ArcheryGroupRecord]) -> [String: Int] {
        var distribution: [String: Int] = [:]
        
        // 统计单箭记录
        for record in records {
            for scoreStr in record.scores {
                let ring = scoreStr.uppercased() == "X" ? "10" : scoreStr
                distribution[ring, default: 0] += 1
            }
        }
        
        // 统计组记录
        for groupRecord in groupRecords {
            for group in groupRecord.groupScores {
                for scoreStr in group {
                    let ring = scoreStr.uppercased() == "X" ? "10" : scoreStr
                    distribution[ring, default: 0] += 1
                }
            }
        }
        
        return distribution
    }
    
    private func ringColor(for ring: String) -> Color {
        switch ring {
        case "10", "X", "x":
            return .red
        case "9":
            return .orange
        case "8":
            return .yellow
        case "7":
            return .green
        case "6":
            return .blue
        default:
            return .gray
        }
    }
    
    private func generateComprehensiveEvaluation(_ analytics: ArcheryAnalytics) -> String {
        var evaluationParts: [String] = []
        
        // 平均环数评估
        if analytics.averageRing >= 9.0 {
            evaluationParts.append(L10n.tr("analysis_comprehensive_eval_average_excellent"))
        } else if analytics.averageRing >= 8.0 {
            evaluationParts.append(L10n.tr("analysis_comprehensive_eval_average_good"))
        } else {
            evaluationParts.append(L10n.tr("analysis_comprehensive_eval_average_improve"))
        }

        // 稳定性评估
        if analytics.stabilityScore >= 80 {
            evaluationParts.append(L10n.tr("analysis_comprehensive_eval_stability_excellent"))
        } else if analytics.stabilityScore >= 60 {
            evaluationParts.append(L10n.tr("analysis_comprehensive_eval_stability_good"))
        } else {
            evaluationParts.append(L10n.tr("analysis_comprehensive_eval_stability_improve"))
        }

        // 疲劳指数评估
        if analytics.fatigueIndex <= 5 {
            evaluationParts.append(L10n.tr("analysis_comprehensive_eval_fatigue_excellent"))
        } else if analytics.fatigueIndex <= 15 {
            evaluationParts.append(L10n.tr("analysis_comprehensive_eval_fatigue_good"))
        } else {
            evaluationParts.append(L10n.tr("analysis_comprehensive_eval_fatigue_improve"))
        }
        
        return evaluationParts.joined(separator: " ")
    }

    private func formatTrend(_ trend: Double) -> String {
        guard trend.isFinite else { return "--" }
        let sign = trend >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", trend))%"
    }

    private func trendMetricChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.72))

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.12))
        .cornerRadius(12)
    }
}

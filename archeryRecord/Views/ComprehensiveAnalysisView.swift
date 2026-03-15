import SwiftUI

struct ComprehensiveAnalysisView: View {
    let records: [ArcheryRecord]
    let groupRecords: [ArcheryGroupRecord]
    @State private var timeRange = 0
    
    var body: some View {
        VStack {
            // 时间范围选择器
            Picker("时间范围", selection: $timeRange) {
                Text("今天").tag(0)
                Text("本周").tag(1)
                Text("本月").tag(2)
                Text("本年").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            let filteredRecords = filterRecords(records, by: timeRange)
            let filteredGroupRecords = filterGroupRecords(groupRecords, by: timeRange)
            
            if filteredRecords.isEmpty && filteredGroupRecords.isEmpty {
                EmptyAnalysisView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // 总成绩卡片
                        totalScoreCard(filteredRecords, filteredGroupRecords)
                        
                        // 核心指标区域
                        coreMetricsSection(filteredRecords, filteredGroupRecords)
                        
                        // 环数分析卡片
                        ringAnalysisSection(filteredRecords, filteredGroupRecords)
                        
                        // 综合评估卡片
                        comprehensiveEvaluationSection(filteredRecords, filteredGroupRecords)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - 辅助方法
    
    /// 过滤记录
    private func filterRecords(_ records: [ArcheryRecord], by timeRange: Int) -> [ArcheryRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        return records.filter { record in
            switch timeRange {
            case 0: // 今天
                return calendar.isDate(record.date, inSameDayAs: now)
            case 1: // 本周
                return calendar.isDate(record.date, equalTo: now, toGranularity: .weekOfYear)
            case 2: // 本月
                return calendar.isDate(record.date, equalTo: now, toGranularity: .month)
            case 3: // 本年
                return calendar.isDate(record.date, equalTo: now, toGranularity: .year)
            default:
                return true
            }
        }
    }
    
    private func filterGroupRecords(_ groupRecords: [ArcheryGroupRecord], by timeRange: Int) -> [ArcheryGroupRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        return groupRecords.filter { record in
            switch timeRange {
            case 0: // 今天
                return calendar.isDate(record.date, inSameDayAs: now)
            case 1: // 本周
                return calendar.isDate(record.date, equalTo: now, toGranularity: .weekOfYear)
            case 2: // 本月
                return calendar.isDate(record.date, equalTo: now, toGranularity: .month)
            case 3: // 本年
                return calendar.isDate(record.date, equalTo: now, toGranularity: .year)
            default:
                return true
            }
        }
    }
    
    /// 总成绩卡片
    private func totalScoreCard(_ records: [ArcheryRecord], _ groupRecords: [ArcheryGroupRecord]) -> some View {
        let totalScore = calculateTotalScore(records, groupRecords)
        let totalShots = calculateTotalShots(records, groupRecords)
        let averageScore = totalShots > 0 ? Double(totalScore) / Double(totalShots) : 0.0
        let completionRate = averageScore * 10 // 转换为百分比
        
        return VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.3, blue: 0.8),
                        Color(red: 0.6, green: 0.4, blue: 0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(16)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("综合成绩")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        Text("平均环数")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    VStack(spacing: 8) {
                        Text(String(format: "%.1f", averageScore))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(String(format: "%.1f%%", completionRate))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack {
                        Text("总箭数: \(totalShots)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("总分: \(totalScore)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(20)
            }
        }
    }
    
    /// 核心指标区域
    private func coreMetricsSection(_ records: [ArcheryRecord], _ groupRecords: [ArcheryGroupRecord]) -> some View {
        let analytics = calculateAnalytics(records, groupRecords)
        
        return VStack(spacing: 16) {
            HStack {
                Text("核心指标")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // 平均环数
                MetricCard(
                    icon: "target",
                    title: "平均环数",
                    value: String(format: "%.1f", analytics.averageRing),
                    subtitle: "环",
                    color: .blue
                )
                
                // 稳定性评分
                MetricCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "稳定性",
                    value: String(format: "%.0f", analytics.stabilityScore),
                    subtitle: "分",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                // 疲劳指数
                MetricCard(
                    icon: "bolt.fill",
                    title: "疲劳指数",
                    value: String(format: "%.0f%%", analytics.fatigueIndex),
                    subtitle: "",
                    color: .orange
                )
                
                // 10环率
                MetricCard(
                    icon: "scope",
                    title: "10环率",
                    value: String(format: "%.0f%%", analytics.tenRingRate),
                    subtitle: "",
                    color: .purple
                )
            }
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
        
        return VStack(spacing: 16) {
            HStack {
                Text("环数分析")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(Array(ringStats.sorted(by: { $0.key > $1.key })), id: \.key) { ring, count in
                    let totalShots = calculateTotalShots(records, groupRecords)
                    let percentage = totalShots > 0 ? Double(count) / Double(totalShots) * 100 : 0.0
                    
                    RingStatCard(
                        ring: "\(ring)环",
                        count: count,
                        total: totalShots,
                        color: ringColor(for: ring)
                    )
                }
            }
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
        
        return VStack(spacing: 16) {
            HStack {
                Text("综合评估")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(evaluation)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
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
        var evaluation = ""
        
        // 平均环数评估
        if analytics.averageRing >= 9.0 {
            evaluation += "您的平均环数表现优秀，射击精度很高。"
        } else if analytics.averageRing >= 8.0 {
            evaluation += "您的平均环数表现良好，还有提升空间。"
        } else {
            evaluation += "您的平均环数需要加强练习，建议重点提升射击精度。"
        }
        
        evaluation += " "
        
        // 稳定性评估
        if analytics.stabilityScore >= 80 {
            evaluation += "稳定性表现出色，成绩波动较小。"
        } else if analytics.stabilityScore >= 60 {
            evaluation += "稳定性中等，建议加强一致性训练。"
        } else {
            evaluation += "稳定性需要改善，建议重点练习动作一致性。"
        }
        
        evaluation += " "
        
        // 疲劳指数评估
        if analytics.fatigueIndex <= 5 {
            evaluation += "疲劳控制良好，能够保持持续的高水平表现。"
        } else if analytics.fatigueIndex <= 15 {
            evaluation += "存在轻微疲劳影响，建议适当调整训练强度。"
        } else {
            evaluation += "疲劳影响较明显，建议加强体能训练和休息调整。"
        }
        
        return evaluation
    }
}

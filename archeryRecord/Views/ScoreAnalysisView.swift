import SwiftUI
import Charts
import Foundation
import SwiftData

struct ScoreAnalysisView: View {
    @EnvironmentObject var archeryStore: ArcheryStore
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            Picker("分析类型", selection: $selectedTab) {
                Text("综合分析").tag(0)
                Text("精准度分析").tag(1)
                Text("稳定性分析").tag(2)
                Text("疲劳分析").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            #if os(iOS)
            TabView(selection: $selectedTab) {
                ComprehensiveAnalysisView(records: archeryStore.records, groupRecords: archeryStore.groupRecords)
                    .tag(0)
                AccuracyAnalysisView(records: archeryStore.records, groupRecords: archeryStore.groupRecords)
                    .tag(1)
                StabilityAnalysisView(records: archeryStore.records, groupRecords: archeryStore.groupRecords)
                    .tag(2)
                FatigueAnalysisView(records: archeryStore.records, groupRecords: archeryStore.groupRecords)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            Group {
                switch selectedTab {
                case 0:
                    ComprehensiveAnalysisView(records: archeryStore.records, groupRecords: archeryStore.groupRecords)
                case 1:
                    AccuracyAnalysisView(records: archeryStore.records, groupRecords: archeryStore.groupRecords)
                case 2:
                    StabilityAnalysisView(records: archeryStore.records, groupRecords: archeryStore.groupRecords)
                case 3:
                    FatigueAnalysisView(records: archeryStore.records, groupRecords: archeryStore.groupRecords)
                default:
                    ComprehensiveAnalysisView(records: archeryStore.records, groupRecords: archeryStore.groupRecords)
                }
            }
            #endif
        }
        #if os(iOS)
        .navigationBarTitle("成绩分析", displayMode: .inline)
        #else
        .navigationTitle("成绩分析")
        #endif
        .onAppear {
            archeryStore.loadRecords()
        }
    }
}

// MARK: - 简化的分析视图

struct AccuracyAnalysisView: View {
    let records: [ArcheryRecord]
    let groupRecords: [ArcheryGroupRecord]
    @State private var timeRange = 0
    
    var body: some View {
        VStack {
            Picker("时间范围", selection: $timeRange) {
                Text("今天").tag(0)
                Text("本周").tag(1)
                Text("本月").tag(2)
                Text("本年").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if records.isEmpty && groupRecords.isEmpty {
                EmptyAnalysisView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // 精准度评分卡片
                        accuracyScoreCard
                        
                        // 命中分布图
                        ringDistributionChart
                        
                        // 精准度指标
                        accuracyMetrics
                        
                        // 分析建议
                        analysisAdvice
                    }
                    .padding()
                }
            }
        }
    }
    
    private var accuracyScoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("精准度评分")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f", accuracyStats.averageScore))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("平均环数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(accuracyStats.accuracyGrade)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(gradeColor(accuracyStats.accuracyGrade))
                    
                    Text("精准度等级")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f%%", accuracyStats.tenRingRate))")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("10环率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(accuracyStats.groupTightness)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("组别紧密度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var ringDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("环数分布")
                .font(.headline)
                .fontWeight(.bold)
            
            if !ringDistribution.isEmpty {
                Chart(ringDistribution, id: \.ring) { item in
                    BarMark(
                        x: .value("环数", item.ring),
                        y: .value("次数", item.count)
                    )
                    .foregroundStyle(item.color)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            } else {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var accuracyMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("精准度指标")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(icon: "target", title: "散布半径", value: String(format: "%.2f", accuracyStats.spreadRadius), subtitle: "环", color: .blue)
                MetricCard(icon: "star.fill", title: "X环数", value: "\(accuracyStats.xRingCount)", subtitle: "支", color: .red)
                MetricCard(icon: "10.circle.fill", title: "10环数", value: "\(accuracyStats.tenRingCount)", subtitle: "支", color: .orange)
                MetricCard(icon: "9.circle.fill", title: "9环数", value: "\(accuracyStats.nineRingCount)", subtitle: "支", color: .yellow)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var analysisAdvice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分析建议")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(ScoreAnalytics.generateAccuracyAnalysis(stats: (spreadRadius: accuracyStats.spreadRadius, groupTightness: accuracyStats.groupTightness, accuracyGrade: accuracyStats.accuracyGrade)))
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(nil)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var accuracyStats: (averageScore: Double, tenRingRate: Double, spreadRadius: Double, groupTightness: String, accuracyGrade: String, xRingCount: Int, tenRingCount: Int, nineRingCount: Int) {
        // 使用时间过滤后的数据
        let filteredData = ScoreAnalytics.processScores(records: records, groupRecords: groupRecords, timeRange: timeRange)
        let filteredRecords = getFilteredRecords()
        let filteredGroupRecords = getFilteredGroupRecords()
        
        let allRecords = filteredRecords + filteredGroupRecords.map { groupRecord in
            ArcheryRecord(
                id: groupRecord.id,
                bowType: groupRecord.bowType,
                distance: groupRecord.distance,
                targetType: groupRecord.targetType,
                scores: groupRecord.groupScores.flatMap { $0 },
                date: groupRecord.date,
                numberOfArrows: groupRecord.groupScores.flatMap { $0 }.count
            )
        }
        
        if allRecords.isEmpty {
            return (0, 0, 0, "无数据", "无数据", 0, 0, 0)
        }
        
        let analytics = ScoreAnalytics.calculateAccuracyStats(records: filteredRecords, groupRecords: filteredGroupRecords, timeRange: timeRange)
        let firstRecord = allRecords.first!
        let accuracyData = ScoreAnalytics.calculateSingleRecordAccuracyStats(firstRecord)
        
        let allScores = allRecords.flatMap { $0.scores }
        let xCount = allScores.filter { $0 == "X" }.count
        let tenCount = allScores.filter { $0 == "10" }.count
        let nineCount = allScores.filter { $0 == "9" }.count
        let tenRingCount = allScores.filter { $0 == "10" || $0 == "X" }.count
        let tenRingRate = allScores.isEmpty ? 0 : Double(tenRingCount) / Double(allScores.count) * 100
        
        let totalScore = allScores.compactMap { score -> Int? in
            if score == "X" { return 10 }
            if score == "M" { return 0 }
            return Int(score)
        }.reduce(0, +)
        let averageScore = allScores.isEmpty ? 0 : Double(totalScore) / Double(allScores.count)
        
        return (averageScore, tenRingRate, accuracyData.spreadRadius, accuracyData.groupTightness, accuracyData.accuracyGrade, xCount, tenCount, nineCount)
    }
    
    private var ringDistribution: [(ring: String, count: Int, color: Color)] {
        let filteredRecords = getFilteredRecords()
        let filteredGroupRecords = getFilteredGroupRecords()
        let allScores = (filteredRecords.flatMap { $0.scores } + filteredGroupRecords.flatMap { $0.groupScores.flatMap { $0 } })
        let ringCounts = Dictionary(grouping: allScores) { $0 }.mapValues { $0.count }
        
        let rings = ["X", "10", "9", "8", "7", "6", "5", "4", "3", "2", "1", "M"]
        
        return rings.compactMap { ring in
            let count = ringCounts[ring] ?? 0
            guard count > 0 else { return nil }
            return (ring: ring, count: count, color: ScoreAnalytics.ringColor(for: ring))
        }
    }
    
    private func getFilteredRecords() -> [ArcheryRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        return records.filter { record in
            switch timeRange {
            case 0: // 今天
                return calendar.isDateInToday(record.date)
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
    
    private func getFilteredGroupRecords() -> [ArcheryGroupRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        return groupRecords.filter { record in
            switch timeRange {
            case 0: // 今天
                return calendar.isDateInToday(record.date)
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
    
    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "优秀": return .green
        case "良好": return .blue
        case "一般": return .orange
        case "需改进": return .red
        default: return .gray
        }
    }
}

struct StabilityAnalysisView: View {
    let records: [ArcheryRecord]
    let groupRecords: [ArcheryGroupRecord]
    @State private var timeRange = 0
    
    var body: some View {
        VStack {
            Picker("时间范围", selection: $timeRange) {
                Text("今天").tag(0)
                Text("本周").tag(1)
                Text("本月").tag(2)
                Text("本年").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if records.isEmpty && groupRecords.isEmpty {
                EmptyAnalysisView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // 稳定性评分卡片
                        stabilityScoreCard
                        
                        // 成绩控制图
                        controlChart
                        
                        // 稳定性指标
                        stabilityMetrics
                        
                        // 分析建议
                        stabilityAdvice
                    }
                    .padding()
                }
            }
        }
    }
    
    private var stabilityScoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("稳定性评估")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f", stabilityData.stabilityScore))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("稳定性评分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(ScoreAnalytics.getStabilityLevel(stabilityData.stabilityScore))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(ScoreAnalytics.getStabilityLevelColor(stabilityData.stabilityScore))
                    
                    Text("稳定性等级")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.2f%%", stabilityData.coefficientOfVariation * 100))")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("变异系数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(String(format: "%.1f", stabilityData.standardDeviation))")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("标准差")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var controlChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成绩控制图")
                .font(.headline)
                .fontWeight(.bold)
            
            if !stabilityData.groupScores.isEmpty {
                Chart {
                    // 数据点
                    ForEach(Array(stabilityData.groupScores.enumerated()), id: \.offset) { index, score in
                        LineMark(
                            x: .value("序号", index + 1),
                            y: .value("成绩", score)
                        )
                        .foregroundStyle(.blue)
                        
                        PointMark(
                            x: .value("序号", index + 1),
                            y: .value("成绩", score)
                        )
                        .foregroundStyle(.blue)
                    }
                    
                    // 上控制线
                    RuleMark(y: .value("上控制线", stabilityData.upperLimit))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    
                    // 下控制线
                    RuleMark(y: .value("下控制线", stabilityData.lowerLimit))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    
                    // 平均线
                    RuleMark(y: .value("平均线", stabilityData.groupScores.reduce(0, +) / Double(stabilityData.groupScores.count)))
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
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var stabilityMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("稳定性指标")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(icon: "arrow.up.circle", title: "上控制线", value: String(format: "%.1f", stabilityData.upperLimit), subtitle: "环", color: .green)
                MetricCard(icon: "arrow.down.circle", title: "下控制线", value: String(format: "%.1f", stabilityData.lowerLimit), subtitle: "环", color: .red)
                MetricCard(icon: "arrow.up.arrow.down", title: "控制范围", value: String(format: "%.1f", stabilityData.upperLimit - stabilityData.lowerLimit), subtitle: "环", color: .blue)
                MetricCard(icon: "chart.bar", title: "CV等级", value: ScoreAnalytics.getCVLevel(stabilityData.coefficientOfVariation * 100), subtitle: "", color: .purple)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var stabilityAdvice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分析建议")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(ScoreAnalytics.generateStabilityAnalysisForGroup(score: stabilityData.stabilityScore, cv: stabilityData.coefficientOfVariation * 100))
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(ScoreAnalytics.generateStabilityTrainingAdvice(score: stabilityData.stabilityScore, cv: stabilityData.coefficientOfVariation * 100))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var stabilityData: (stabilityScore: Double, coefficientOfVariation: Double, standardDeviation: Double, groupScores: [Double], upperLimit: Double, lowerLimit: Double) {
        let filteredRecords = getFilteredRecordsForStability()
        let filteredGroupRecords = getFilteredGroupRecordsForStability()
        
        let allRecords = filteredRecords + filteredGroupRecords.map { groupRecord in
            ArcheryRecord(
                id: groupRecord.id,
                bowType: groupRecord.bowType,
                distance: groupRecord.distance,
                targetType: groupRecord.targetType,
                scores: groupRecord.groupScores.flatMap { $0 },
                date: groupRecord.date,
                numberOfArrows: groupRecord.groupScores.flatMap { $0 }.count
            )
        }
        
        if allRecords.isEmpty {
            return (0, 0, 0, [], 0, 0)
        }
        
        let firstRecord = allRecords.first!
        let stabilityResult = ScoreAnalytics.calculateSingleRecordStabilityData(firstRecord)
        
        // 计算稳定性评分
        let scores = allRecords.flatMap { $0.scores }.compactMap { score -> Int? in
            if score == "X" { return 10 }
            if score == "M" { return 0 }
            return Int(score)
        }
        
        let average = scores.isEmpty ? 0 : Double(scores.reduce(0, +)) / Double(scores.count)
        let variance = scores.isEmpty ? 0 : scores.map { pow(Double($0) - average, 2) }.reduce(0, +) / Double(scores.count)
        let standardDeviation = sqrt(variance)
        let stabilityScore = max(0, 100 - standardDeviation * 10)
        
        return (stabilityScore, stabilityResult.coefficientOfVariation, standardDeviation, stabilityResult.groupScores, stabilityResult.upperLimit, stabilityResult.lowerLimit)
    }
    
    private func getFilteredRecordsForStability() -> [ArcheryRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        return records.filter { record in
            switch timeRange {
            case 0: // 今天
                return calendar.isDateInToday(record.date)
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
    
    private func getFilteredGroupRecordsForStability() -> [ArcheryGroupRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        return groupRecords.filter { record in
            switch timeRange {
            case 0: // 今天
                return calendar.isDateInToday(record.date)
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
}

struct FatigueAnalysisView: View {
    let records: [ArcheryRecord]
    let groupRecords: [ArcheryGroupRecord]
    @State private var timeRange = 0
    
    var body: some View {
        VStack {
            Picker("时间范围", selection: $timeRange) {
                Text("今天").tag(0)
                Text("本周").tag(1)
                Text("本月").tag(2)
                Text("本年").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if records.isEmpty && groupRecords.isEmpty {
                EmptyAnalysisView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // 疲劳指数卡片
                        fatigueIndexCard
                        
                        // 成绩变化趋势图
                        fatigueTrendChart
                        
                        // 疲劳指标
                        fatigueMetrics
                        
                        // 训练建议
                        fatigueAdvice
                    }
                    .padding()
                }
            }
        }
    }
    
    private var fatigueIndexCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("疲劳指数评估")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f", fatigueData.fatigueIndex))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("疲劳指数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(ScoreAnalytics.getFatigueLevel(fatigueData.fatigueIndex))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(ScoreAnalytics.getFatigueIndexColor(fatigueData.fatigueIndex))
                    
                    Text("疲劳等级")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f", fatigueData.firstHalfAverage))")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("前半段平均")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(String(format: "%.1f", fatigueData.secondHalfAverage))")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("后半段平均")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var fatigueTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成绩变化趋势")
                .font(.headline)
                .fontWeight(.bold)
            
            if !fatigueData.scores.isEmpty {
                Chart {
                    ForEach(Array(fatigueData.scores.enumerated()), id: \.offset) { index, score in
                        LineMark(
                            x: .value("箭数", index + 1),
                            y: .value("环数", score)
                        )
                        .foregroundStyle(.blue)
                        
                        PointMark(
                            x: .value("箭数", index + 1),
                            y: .value("环数", score)
                        )
                        .foregroundStyle(.blue)
                    }
                    
                    // 前半段平均线
                    if fatigueData.scores.count > 1 {
                        RuleMark(y: .value("前半段平均", fatigueData.firstHalfAverage))
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        
                        // 后半段平均线
                        RuleMark(y: .value("后半段平均", fatigueData.secondHalfAverage))
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
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var fatigueMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("疲劳指标")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(icon: "arrow.down", title: "成绩下降", value: String(format: "%.1f", fatigueData.firstHalfAverage - fatigueData.secondHalfAverage), subtitle: "环", color: .red)
                MetricCard(icon: "percent", title: "下降比例", value: String(format: "%.1f%%", fatigueData.fatigueIndex), subtitle: "", color: .orange)
                MetricCard(icon: "arrow.right", title: "总箭数", value: "\(fatigueData.scores.count)", subtitle: "支", color: .blue)
                MetricCard(icon: "battery.25", title: "疲劳等级", value: ScoreAnalytics.getFatigueLevel(fatigueData.fatigueIndex), subtitle: "", color: .purple)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var fatigueAdvice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("训练建议")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(ScoreAnalytics.generateFatigueAnalysis(index: fatigueData.fatigueIndex))
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(ScoreAnalytics.generateFatigueTrainingAdvice(index: fatigueData.fatigueIndex))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var fatigueData: (fatigueIndex: Double, firstHalfAverage: Double, secondHalfAverage: Double, scores: [Int]) {
        let filteredRecords = getFilteredRecordsForFatigue()
        let filteredGroupRecords = getFilteredGroupRecordsForFatigue()
        
        let allRecords = filteredRecords + filteredGroupRecords.map { groupRecord in
            ArcheryRecord(
                id: groupRecord.id,
                bowType: groupRecord.bowType,
                distance: groupRecord.distance,
                targetType: groupRecord.targetType,
                scores: groupRecord.groupScores.flatMap { $0 },
                date: groupRecord.date,
                numberOfArrows: groupRecord.groupScores.flatMap { $0 }.count
            )
        }
        
        if allRecords.isEmpty {
            return (0, 0, 0, [])
        }
        
        let allScores = allRecords.flatMap { $0.scores }.compactMap { score -> Int? in
            if score == "X" { return 10 }
            if score == "M" { return 0 }
            return Int(score)
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
    
    private func getFilteredRecordsForFatigue() -> [ArcheryRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case 0: // 今天
            return records.filter { calendar.isDate($0.date, inSameDayAs: now) }
        case 1: // 本周
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return records.filter { $0.date >= startOfWeek }
        case 2: // 本月
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return records.filter { $0.date >= startOfMonth }
        case 3: // 本年
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return records.filter { $0.date >= startOfYear }
        default:
            return records
        }
    }
    
    private func getFilteredGroupRecordsForFatigue() -> [ArcheryGroupRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case 0: // 今天
            return groupRecords.filter { calendar.isDate($0.date, inSameDayAs: now) }
        case 1: // 本周
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return groupRecords.filter { $0.date >= startOfWeek }
        case 2: // 本月
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return groupRecords.filter { $0.date >= startOfMonth }
        case 3: // 本年
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return groupRecords.filter { $0.date >= startOfYear }
        default:
            return groupRecords
        }
    }
}

struct EmptyAnalysisView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("没有数据，快去记录")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    ScoreAnalysisView()
}

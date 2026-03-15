import SwiftUI
import Charts

struct ScoreDetailView: View {
    let recordId: UUID
    let recordType: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var archeryStore: ArcheryStore
    @State private var showDeleteAlert = false
    @State private var trainingAdvice: TrainingAdvice?
    @State private var isLoadingAdvice = false
    @State private var adviceError: Error?
    @State private var record: ArcheryRecord?
    @State private var selectedTab = 0
    @State private var showEditView = false
    @State private var trendViewMode: TrendViewMode = .arrow
    @EnvironmentObject private var tabBarManager: TabBarManager

    
    enum TrendViewMode {
        case arrow
        case cumulative
    }
    
    private let cozeService = CozeService()
    
    private var backgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    if let record = record {
                        VStack(spacing: 16) {
                            // Header info bar
                            headerInfoBar(record)
                            
                            // Total score card
                            totalScoreCard(record, scrollProxy: proxy)
                            
                            // Core metrics section
                            coreMetricsSection(record)
                            
                            // Score trend chart
                            scoreTrendChart(record)
                            
                            // Quick statistics section
                            quickStatsSection(record)
                            
                            // Detailed analysis tabs
                            detailedAnalysisTabs(record)
                                .id("scoreDetails")
                            
                            // Raw data section
                            rawDataSection(record)
                        }
                        .padding(.vertical)
                        .padding(.bottom, 80) // 为底部按钮留出空间
                        .task {
                            if let stored = TrainingAdviceStorage.get(for: recordId, type: .single) {
                                await MainActor.run {
                                    trainingAdvice = stored
                                }
                            } else {
                                await loadTrainingAdvice(for: record)
                            }
                        }
                    }
                }
                .background(backgroundColor)
            }
            
            // 底部固定按钮
            HStack(spacing: 16) {
                Button(action: {
                    showDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text(L10n.Common.delete)
                            .foregroundColor(.red)
                    }
                    .font(.system(size: 17, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                
                NavigationLink(destination: ScoreInputView()) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10n.Common.addmore)
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.purple.opacity(0.9))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
        }
        #if os(iOS)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        #endif
        .customNavigationBar(
            title: L10n.Detail.title,
            leadingButton: {
                tabBarManager.show()
                dismiss()
            },
            trailingButton: nil,
            trailingTitle: nil,
            backgroundColor: .white,
            foregroundColor: .black
        )
        .alert(L10n.Detail.deleteConfirmTitle, isPresented: $showDeleteAlert) {
            Button(L10n.Detail.deleteCancel, role: .cancel) { }
            Button(L10n.Detail.deleteConfirm, role: .destructive) {
                archeryStore.deleteRecord(id: recordId)
                dismiss()
            }
        } message: {
            Text(L10n.Detail.deleteConfirmMessage)
        }
        .onAppear {
            loadRecord()
            tabBarManager.hide()
        }
        .navigationDestination(isPresented: $showEditView) {
            if let record = record {
                ScoreInputView(editingRecord: record)
                    .environmentObject(archeryStore)
                    .environmentObject(tabBarManager)
            }
        }
    }
    
    // MARK: - Header Info Bar
    private func headerInfoBar(_ record: ArcheryRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(record.date))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(record.bowType)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(record.distance)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(record.targetType)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    Spacer(minLength: 0)
                }
            }
            
            Spacer()
            
            Button(action: {
                showEditView = true
            }) {
                Text("编辑")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.purple)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Total Score Card
    private func totalScoreCard(_ record: ArcheryRecord, scrollProxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
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
                        Text("总成绩")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        Text("\(calculateTotalScore(record))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("共\(record.scores.count)箭")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("训练时长: 45分钟")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                            Text("消耗卡路里: 120千卡")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                scrollProxy.scrollTo("scoreDetails", anchor: .top)
                            }
                        }) {
                            Text("点击查看详情 →")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(20)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Core Metrics Section
    private func coreMetricsSection(_ record: ArcheryRecord) -> some View {
        let analytics = calculateAnalytics(record)
        
        return VStack(spacing: 16) {
            HStack {
                Text("核心指标")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal, 16)
            
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
            .padding(.horizontal, 16)
            
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
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Score Trend Chart
    private func scoreTrendChart(_ record: ArcheryRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("成绩趋势分析")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                
                HStack(spacing: 8) {
                    Button("箭支") {
                        trendViewMode = .arrow
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(trendViewMode == .arrow ? .white : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(trendViewMode == .arrow ? Color.purple : Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("累计") {
                        trendViewMode = .cumulative
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(trendViewMode == .cumulative ? .white : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(trendViewMode == .cumulative ? Color.purple : Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            
            // 趋势图表
            Chart {
                if trendViewMode == .arrow {
                    ForEach(Array(record.scores.enumerated()), id: \.offset) { index, score in
                        let scoreValue = scoreToInt(score)
                        LineMark(
                            x: .value("箭支", index + 1),
                            y: .value("分数", scoreValue)
                        )
                        .foregroundStyle(Color.purple)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("箭支", index + 1),
                            y: .value("分数", scoreValue)
                        )
                        .foregroundStyle(Color.purple)
                        .symbolSize(50)
                    }
                } else {
                    let cumulativeScores = record.scores.enumerated().map { index, _ in
                        let currentScores = Array(record.scores.prefix(index + 1))
                        return currentScores.reduce(0) { sum, score in
                            sum + scoreToInt(score)
                        }
                    }
                    
                    ForEach(Array(cumulativeScores.enumerated()), id: \.offset) { index, cumulativeScore in
                        LineMark(
                            x: .value("箭支", index + 1),
                            y: .value("累计分数", cumulativeScore)
                        )
                        .foregroundStyle(Color.purple)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("箭支", index + 1),
                            y: .value("累计分数", cumulativeScore)
                        )
                        .foregroundStyle(Color.purple)
                        .symbolSize(50)
                    }
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 16)
            .chartYScale(domain: trendViewMode == .arrow ? 0...12 : 0...Int(Double(record.scores.count * 10) * 1.1))
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Quick Statistics Section
    private func quickStatsSection(_ record: ArcheryRecord) -> some View {
        let analytics = calculateAnalytics(record)
        let trends = calculateTrends(for: record)
        
        return VStack(spacing: 16) {
            HStack {
                Text("快速统计")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            HStack(spacing: 12) {
                QuickStatCard(
                    icon: "🎯",
                    title: "平均分",
                    value: String(format: "%.1f", analytics.averageRing),
                    trend: trends.averageTrend
                )
                
                QuickStatCard(
                    icon: "📈",
                    title: "稳定性",
                    value: String(format: "%.0f%%", analytics.stabilityScore),
                    trend: trends.stabilityTrend
                )
                
                QuickStatCard(
                    icon: "⚡",
                    title: "疲劳度",
                    value: String(format: "%.0f%%", analytics.fatigueIndex),
                    trend: trends.fatigueTrend
                )
                
                QuickStatCard(
                    icon: "🏆",
                    title: "10环率",
                    value: String(format: "%.0f%%", analytics.tenRingRate),
                    trend: trends.tenRingTrend
                )
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Detailed Analysis Tabs
    private func detailedAnalysisTabs(_ record: ArcheryRecord) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabButton(title: "环数分析", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "精准度分析", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabButton(title: "稳定性分析", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                TabButton(title: "疲劳分析", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            VStack {
                switch selectedTab {
                case 0:
                    shootingAnalysisTab(record)
                case 1:
                    accuracyAnalysisTab(record)
                case 2:
                    stabilityAnalysisTab(record)
                case 3:
                    fatigueAnalysisTab(record)
                default:
                    shootingAnalysisTab(record)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Raw Data Section
    private func rawDataSection(_ record: ArcheryRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("成绩详情")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                ForEach(Array(record.scores.enumerated()), id: \.offset) { index, score in
                    HStack {
                        Text("第\(index + 1)箭")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 60, alignment: .leading)
                        
                        Spacer()
                        
                        ScoreRingView(score: score)
                        
                        Spacer()
                        
                        Text("\(scoreToInt(score))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 40, alignment: .trailing)
                    }
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Analysis Tab Functions
    private func shootingAnalysisTab(_ record: ArcheryRecord) -> some View {
        let analytics = calculateAnalytics(record)
        let ringDistribution = calculateRingDistribution(record)
        
        return VStack(alignment: .leading, spacing: 20) {
            // 环数分布图表
            VStack(alignment: .leading, spacing: 12) {
                Text("环数分布")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Chart {
                    ForEach(ringDistribution, id: \.ring) { item in
                        BarMark(
                            x: .value("环数", item.ring),
                            y: .value("数量", item.count)
                        )
                        .foregroundStyle(item.color)
                    }
                }
                .frame(height: 150)
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
            
            // 详细统计
            VStack(alignment: .leading, spacing: 12) {
                Text("详细统计")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(ringDistribution, id: \.ring) { item in
                        RingStatCard(
                            ring: item.ring,
                            count: item.count,
                            total: record.scores.count,
                            color: item.color
                        )
                    }
                }
            }
            
            // 分析建议
            VStack(alignment: .leading, spacing: 8) {
                Text("分析建议")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(generateShootingAnalysis(analytics: analytics))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(nil)
            }
        }
        .padding(16)
    }
    
    private func accuracyAnalysisTab(_ record: ArcheryRecord) -> some View {
        let stats = calculateAccuracyStats(record)
        
        return VStack(alignment: .leading, spacing: 20) {
            // 精准度评估
            VStack(alignment: .leading, spacing: 12) {
                Text("精准度评估")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                HStack(spacing: 20) {
                    VStack {
                        Text(String(format: "%.1f", stats.spreadRadius))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.blue)
                        Text("散布半径")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    VStack {
                        Text(stats.groupTightness)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                        Text("组别紧密度")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    VStack {
                        Text(stats.accuracyGrade)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.orange)
                        Text("精准度等级")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // 分析建议
            VStack(alignment: .leading, spacing: 8) {
                Text("分析建议")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(generateAccuracyAnalysis(stats: stats))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(nil)
            }
        }
        .padding(16)
    }
    
    private func stabilityAnalysisTab(_ record: ArcheryRecord) -> some View {
        let analytics = calculateAnalytics(record)
        let stabilityData = calculateStabilityData(record)
        
        return VStack(alignment: .leading, spacing: 20) {
            // 稳定性指标
            VStack(alignment: .leading, spacing: 12) {
                Text("稳定性指标")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                HStack(spacing: 20) {
                    VStack {
                        Text(String(format: "%.0f", analytics.stabilityScore))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(getStabilityLevelColor(analytics.stabilityScore))
                        Text("稳定性评分")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    VStack {
                        Text(String(format: "%.2f", stabilityData.coefficientOfVariation))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.blue)
                        Text("变异系数")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    VStack {
                        Text(getStabilityLevel(analytics.stabilityScore))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(getStabilityLevelColor(analytics.stabilityScore))
                        Text("稳定性等级")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // 分析建议
            VStack(alignment: .leading, spacing: 8) {
                Text("分析建议")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(generateStabilityAnalysis(analytics: analytics, stabilityData: stabilityData))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(nil)
            }
        }
        .padding(16)
    }
    
    private func fatigueAnalysisTab(_ record: ArcheryRecord) -> some View {
        let analytics = calculateAnalytics(record)
        let fatigueData = calculateFatigueData(record)
        
        return VStack(alignment: .leading, spacing: 20) {
            // 疲劳度指标
            VStack(alignment: .leading, spacing: 12) {
                Text("疲劳度指标")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                HStack(spacing: 20) {
                    VStack {
                        Text(String(format: "%.0f%%", analytics.fatigueIndex))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(getFatigueIndexColor(analytics.fatigueIndex))
                        Text("疲劳指数")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    VStack {
                        Text(getFatigueLevel(analytics.fatigueIndex))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(getFatigueIndexColor(analytics.fatigueIndex))
                        Text("疲劳等级")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // 疲劳趋势图
            VStack(alignment: .leading, spacing: 12) {
                Text("疲劳趋势")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Chart {
                    ForEach(Array(fatigueData.enumerated()), id: \.offset) { index, score in
                        LineMark(
                            x: .value("箭支", index + 1),
                            y: .value("分数", score)
                        )
                        .foregroundStyle(Color.orange)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        PointMark(
                            x: .value("箭支", index + 1),
                            y: .value("分数", score)
                        )
                        .foregroundStyle(Color.orange)
                        .symbolSize(30)
                    }
                }
                .frame(height: 120)
                .chartYScale(domain: 0...10)
            }
            
            // 训练建议
            VStack(alignment: .leading, spacing: 8) {
                Text("训练建议")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(generateFatigueTrainingAdvice(index: analytics.fatigueIndex))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(nil)
            }
        }
        .padding(16)
    }
    
    // MARK: - Helper Functions
    private func loadRecord() {
        record = archeryStore.getRecord(id: recordId, type: recordType)
    }
    
    private func calculateTotalScore(_ record: ArcheryRecord) -> Int {
        return record.scores.compactMap { scoreToInt($0) }.reduce(0, +)
    }
    
    private func scoreToInt(_ score: String) -> Int {
        switch score.lowercased() {
        case "x":
            return 10
        case "10":
            return 10
        case "9":
            return 9
        case "8":
            return 8
        case "7":
            return 7
        case "6":
            return 6
        case "5":
            return 5
        case "4":
            return 4
        case "3":
            return 3
        case "2":
            return 2
        case "1":
            return 1
        case "0", "m":
            return 0
        default:
            return 0
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    private func loadTrainingAdvice(for record: ArcheryRecord, forceRefresh: Bool = false) async {
        guard !isLoadingAdvice else { return }
        
        await MainActor.run {
            isLoadingAdvice = true
            adviceError = nil
        }
        
        do {
            let trainingData = cozeService.prepareTrainingData(record: record)
            let advice = try await cozeService.getTrainingAdvice(data: trainingData)
            await MainActor.run {
                trainingAdvice = advice
                isLoadingAdvice = false
                TrainingAdviceStorage.save(advice)
            }
        } catch {
            await MainActor.run {
                adviceError = error
                isLoadingAdvice = false
            }
        }
    }
    
    private func calculateAnalytics(_ record: ArcheryRecord) -> ArcheryAnalytics {
        return ScoreAnalytics.calculateSingleRecordAnalytics(record)
    }
    
    private func calculateRingDistribution(_ record: ArcheryRecord) -> [(ring: String, count: Int, color: Color)] {
        return ScoreAnalytics.calculateSingleRecordRingDistribution(record)
    }
    
    private func calculateAccuracyStats(_ record: ArcheryRecord) -> (spreadRadius: Double, groupTightness: String, accuracyGrade: String) {
        return ScoreAnalytics.calculateSingleRecordAccuracyStats(record)
    }
    
    private func calculateStabilityData(_ record: ArcheryRecord) -> (groupScores: [Double], upperLimit: Double, lowerLimit: Double, coefficientOfVariation: Double) {
        return ScoreAnalytics.calculateSingleRecordStabilityData(record)
    }
    
    private func calculateFatigueData(_ record: ArcheryRecord) -> [Int] {
        return ScoreAnalytics.calculateSingleRecordFatigueData(record)
    }
    
    private func ringColor(for ring: String) -> Color {
        return ScoreAnalytics.ringColor(for: ring)
    }
    
    private func generateShootingAnalysis(analytics: ArcheryAnalytics) -> String {
        return ScoreAnalytics.generateShootingAnalysis(analytics: analytics)
    }
    
    private func generateAccuracyAnalysis(stats: (spreadRadius: Double, groupTightness: String, accuracyGrade: String)) -> String {
        return ScoreAnalytics.generateAccuracyAnalysis(stats: stats)
    }
    
    private func generateStabilityAnalysis(analytics: ArcheryAnalytics, stabilityData: (groupScores: [Double], upperLimit: Double, lowerLimit: Double, coefficientOfVariation: Double)) -> String {
        return ScoreAnalytics.generateStabilityAnalysis(analytics: analytics, stabilityData: stabilityData)
    }
    
    private func getFatigueLevel(_ index: Double) -> String {
        return ScoreAnalytics.getFatigueLevel(index)
    }
    
    private func getFatigueIndexColor(_ index: Double) -> Color {
        return ScoreAnalytics.getFatigueIndexColor(index)
    }
    
    private func generateFatigueTrainingAdvice(index: Double) -> String {
        return ScoreAnalytics.generateFatigueTrainingAdvice(index: index)
    }
    
    private func getStabilityLevel(_ score: Double) -> String {
        return ScoreAnalytics.getStabilityLevel(score)
    }
    
    private func getStabilityLevelColor(_ score: Double) -> Color {
        return ScoreAnalytics.getStabilityLevelColor(score)
    }
    
    private func calculateTrends(for record: ArcheryRecord) -> (averageTrend: String, stabilityTrend: String, fatigueTrend: String, tenRingTrend: String) {
        return ScoreAnalytics.calculateSingleRecordTrends(for: record)
    }
}

// MARK: - Supporting Views



#Preview {
    NavigationStack {
        ScoreDetailView(
            recordId: UUID(),
            recordType: "single"
        )
        .environmentObject(ArcheryStore())
        .environmentObject(TabBarManager())
    }
}

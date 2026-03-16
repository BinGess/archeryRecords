import SwiftUI
import Charts

struct ScoreDetailView: View {
    let recordId: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.revealAppTabBar) private var revealAppTabBar
    @EnvironmentObject var archeryStore: ArcheryStore
    @State private var showDeleteAlert = false
    @State private var trainingAdvice: TrainingAdvice?
    @State private var isLoadingAdvice = false
    @State private var adviceError: Error?
    @State private var record: ArcheryRecord?
    @State private var selectedTab = 0
    @State private var showEditView = false
    @State private var trendViewMode: TrendViewMode = .arrow

    
    enum TrendViewMode {
        case arrow
        case cumulative
    }
    
    private let cozeService = CozeService()
    
    private var backgroundColor: Color {
        SharedStyles.backgroundColor
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    if let record = record {
                        VStack(spacing: SharedStyles.Spacing.section) {
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
                                // 已按需求关闭 AI 教练自动请求，避免详情页进入时触发服务端智能体调用。
                                // await loadTrainingAdvice(for: record)
                            }
                        }
                    }
                }
                .vibrantCanvasBackground()
            }
            
            // 底部固定按钮
            HStack(spacing: SharedStyles.Spacing.section) {
                Button(action: {
                    showDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text(L10n.Common.delete)
                            .foregroundColor(.red)
                    }
                    .font(SharedStyles.Text.bodyEmphasis)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .clayCard(tint: SharedStyles.Accent.coral, radius: 16)
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
                    .font(SharedStyles.Text.bodyEmphasis)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .blockSurface(colors: SharedStyles.GradientSet.sunrise, radius: 16)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, SharedStyles.Spacing.dense)
            .clayCard(tint: SharedStyles.Accent.sky, radius: 24)
        }
        #if os(iOS)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        #endif
        .customNavigationBar(
            title: L10n.Detail.title,
            leadingButton: {
                revealAppTabBar?()
                dismiss()
            },
            trailingButton: nil,
            trailingTitle: nil,
            backgroundColor: SharedStyles.backgroundColor,
            foregroundColor: SharedStyles.primaryTextColor
        )
        .alert(L10n.Detail.deleteConfirmTitle, isPresented: $showDeleteAlert) {
            Button(L10n.Detail.deleteCancel, role: .cancel) { }
            Button(L10n.Detail.deleteConfirm, role: .destructive) {
                archeryStore.deleteRecord(id: recordId)
                revealAppTabBar?()
                dismiss()
            }
        } message: {
            Text(L10n.Detail.deleteConfirmMessage)
        }
        .hiddenAppTabBar()
        .onAppear {
            loadRecord()
        }
        .navigationDestination(isPresented: $showEditView) {
            if let record = record {
                ScoreInputView(editingRecord: record)
                    .environmentObject(archeryStore)
            }
        }
    }
    
    // MARK: - Header Info Bar
    private func headerInfoBar(_ record: ArcheryRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(record.date))
                    .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
                
                HStack(spacing: SharedStyles.Spacing.medium) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(SharedStyles.Text.footnote)
                            .foregroundColor(SharedStyles.secondaryTextColor)
                        Text(record.bowType)
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(SharedStyles.Text.footnote)
                            .foregroundColor(SharedStyles.secondaryTextColor)
                        Text(record.distance)
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(SharedStyles.Text.footnote)
                            .foregroundColor(SharedStyles.secondaryTextColor)
                        Text(TargetTypeDisplay.primaryTitle(for: record.targetType))
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
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
                    .sharedTextStyle(SharedStyles.Text.bodyEmphasis, color: SharedStyles.secondaryColor)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Total Score Card
    private func totalScoreCard(_ record: ArcheryRecord, scrollProxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: SharedStyles.Spacing.section) {
                HStack {
                    Text("总成绩")
                        .sharedTextStyle(SharedStyles.Text.bodyEmphasis, color: .white.opacity(0.92))
                    
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    Text("\(calculateTotalScore(record))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("共\(record.scores.count)箭")
                        .sharedTextStyle(SharedStyles.Text.bodyEmphasis, color: .white.opacity(0.9))
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("训练时长: 45分钟")
                            .sharedTextStyle(SharedStyles.Text.caption, color: .white.opacity(0.82))
                        Text("消耗卡路里: 120千卡")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: .white.opacity(0.68))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            scrollProxy.scrollTo("scoreDetails", anchor: .top)
                        }
                    }) {
                        Text("点击查看详情 →")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: .white.opacity(0.76))
                    }
                }
            }
            .padding(18)
            .blockSurface(colors: [SharedStyles.Accent.sky, SharedStyles.secondaryColor], radius: 24)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Core Metrics Section
    private func coreMetricsSection(_ record: ArcheryRecord) -> some View {
        let analytics = calculateAnalytics(record)
        
        return VStack(spacing: SharedStyles.Spacing.section) {
            HStack {
                Text("核心指标")
                    .sharedTextStyle(SharedStyles.Text.title)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            HStack(spacing: SharedStyles.Spacing.medium) {
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
            
            HStack(spacing: SharedStyles.Spacing.medium) {
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
        VStack(alignment: .leading, spacing: SharedStyles.Spacing.section) {
            HStack {
                Text("成绩趋势分析")
                    .sharedTextStyle(SharedStyles.Text.title)
                Spacer()
                
                HStack(spacing: 8) {
                    Button("箭支") {
                        trendViewMode = .arrow
                    }
                    .font(SharedStyles.Text.caption)
                    .foregroundColor(trendViewMode == .arrow ? .white : SharedStyles.secondaryTextColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(trendViewMode == .arrow ? SharedStyles.secondaryColor : SharedStyles.elevatedSurfaceColor)
                    .cornerRadius(8)
                    
                    Button("累计") {
                        trendViewMode = .cumulative
                    }
                    .font(SharedStyles.Text.caption)
                    .foregroundColor(trendViewMode == .cumulative ? .white : SharedStyles.secondaryTextColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(trendViewMode == .cumulative ? SharedStyles.secondaryColor : SharedStyles.elevatedSurfaceColor)
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
                        .foregroundStyle(SharedStyles.secondaryColor)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("箭支", index + 1),
                            y: .value("分数", scoreValue)
                        )
                        .foregroundStyle(SharedStyles.secondaryColor)
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
                        .foregroundStyle(SharedStyles.secondaryColor)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("箭支", index + 1),
                            y: .value("累计分数", cumulativeScore)
                        )
                        .foregroundStyle(SharedStyles.secondaryColor)
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
        .padding(.vertical, SharedStyles.Spacing.section)
        .clayCard(tint: SharedStyles.secondaryColor, radius: 18)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Quick Statistics Section
    private func quickStatsSection(_ record: ArcheryRecord) -> some View {
        let analytics = calculateAnalytics(record)
        let trends = calculateTrends(for: record)
        
        return VStack(spacing: SharedStyles.Spacing.section) {
            HStack {
                Text("快速统计")
                    .sharedTextStyle(SharedStyles.Text.title)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            HStack(spacing: SharedStyles.Spacing.medium) {
                QuickStatCard(
                    iconSystemName: "target",
                    title: "平均分",
                    value: String(format: "%.1f", analytics.averageRing),
                    trend: trends.averageTrend
                )
                
                QuickStatCard(
                    iconSystemName: "chart.line.uptrend.xyaxis",
                    title: "稳定性",
                    value: String(format: "%.0f%%", analytics.stabilityScore),
                    trend: trends.stabilityTrend
                )
                
                QuickStatCard(
                    iconSystemName: "bolt.fill",
                    title: "疲劳度",
                    value: String(format: "%.0f%%", analytics.fatigueIndex),
                    trend: trends.fatigueTrend
                )
                
                QuickStatCard(
                    iconSystemName: "scope",
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
            .padding(.top, SharedStyles.Spacing.section)
            
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
        .clayCard(tint: SharedStyles.Accent.sky, radius: 18)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Raw Data Section
    private func rawDataSection(_ record: ArcheryRecord) -> some View {
        VStack(alignment: .leading, spacing: SharedStyles.Spacing.section) {
            HStack {
                Text("成绩详情")
                    .sharedTextStyle(SharedStyles.Text.title)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: SharedStyles.Spacing.medium) {
                ForEach(Array(record.scores.enumerated()), id: \.offset) { index, score in
                    HStack {
                        Text("第\(index + 1)箭")
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryTextColor)
                            .frame(width: 60, alignment: .leading)
                        
                        Spacer()
                        
                        ScoreRingView(score: score)
                        
                        Spacer()
                        
                        Text("\(scoreToInt(score))")
                            .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
                            .frame(width: 40, alignment: .trailing)
                    }
                    .padding(.vertical, SharedStyles.Spacing.dense)
                    .background(SharedStyles.elevatedSurfaceColor.opacity(0.82))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, SharedStyles.Spacing.section)
        .clayCard(tint: SharedStyles.primaryColor, radius: 18)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Analysis Tab Functions
    private func shootingAnalysisTab(_ record: ArcheryRecord) -> some View {
        let analytics = calculateAnalytics(record)
        let ringDistribution = calculateRingDistribution(record)
        
        return VStack(alignment: .leading, spacing: SharedStyles.Spacing.extraLarge) {
            // 环数分布图表
            VStack(alignment: .leading, spacing: 12) {
                Text("环数分布")
                    .sharedTextStyle(SharedStyles.Text.title)
                
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
                    .sharedTextStyle(SharedStyles.Text.title)
                
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
                    .sharedTextStyle(SharedStyles.Text.title)
                
                Text(generateShootingAnalysis(analytics: analytics))
                    .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.bodyLineSpacing)
                    .lineLimit(nil)
            }
        }
        .padding(14)
    }
    
    private func accuracyAnalysisTab(_ record: ArcheryRecord) -> some View {
        let stats = calculateAccuracyStats(record)
        
        return VStack(alignment: .leading, spacing: SharedStyles.Spacing.extraLarge) {
            // 精准度评估
            VStack(alignment: .leading, spacing: 12) {
                Text("精准度评估")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                HStack(spacing: 20) {
                    VStack {
                        Text(String(format: "%.1f", stats.spreadRadius))
                            .sharedTextStyle(SharedStyles.Text.compactValue, color: .blue)
                        Text("散布半径")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                    }
                    
                    VStack {
                        Text(stats.groupTightness)
                            .sharedTextStyle(SharedStyles.Text.compactValue, color: .green)
                        Text("组别紧密度")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                    }
                    
                    VStack {
                        Text(stats.accuracyGrade)
                            .sharedTextStyle(SharedStyles.Text.compactValue, color: .orange)
                        Text("精准度等级")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // 分析建议
            VStack(alignment: .leading, spacing: 8) {
                Text("分析建议")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                Text(generateAccuracyAnalysis(stats: stats))
                    .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.bodyLineSpacing)
                    .lineLimit(nil)
            }
        }
        .padding(14)
    }
    
    private func stabilityAnalysisTab(_ record: ArcheryRecord) -> some View {
        let analytics = calculateAnalytics(record)
        let stabilityData = calculateStabilityData(record)
        
        return VStack(alignment: .leading, spacing: SharedStyles.Spacing.extraLarge) {
            // 稳定性指标
            VStack(alignment: .leading, spacing: 12) {
                Text("稳定性指标")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                HStack(spacing: 20) {
                    VStack {
                        Text(String(format: "%.0f", analytics.stabilityScore))
                            .sharedTextStyle(SharedStyles.Text.compactValue, color: getStabilityLevelColor(analytics.stabilityScore))
                        Text("稳定性评分")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                    }
                    
                    VStack {
                        Text(String(format: "%.2f", stabilityData.coefficientOfVariation))
                            .sharedTextStyle(SharedStyles.Text.compactValue, color: .blue)
                        Text("变异系数")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                    }
                    
                    VStack {
                        Text(getStabilityLevel(analytics.stabilityScore))
                            .sharedTextStyle(SharedStyles.Text.compactValue, color: getStabilityLevelColor(analytics.stabilityScore))
                        Text("稳定性等级")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // 分析建议
            VStack(alignment: .leading, spacing: 8) {
                Text("分析建议")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                Text(generateStabilityAnalysis(analytics: analytics, stabilityData: stabilityData))
                    .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.bodyLineSpacing)
                    .lineLimit(nil)
            }
        }
        .padding(14)
    }
    
    private func fatigueAnalysisTab(_ record: ArcheryRecord) -> some View {
        let analytics = calculateAnalytics(record)
        let fatigueData = calculateFatigueData(record)
        
        return VStack(alignment: .leading, spacing: SharedStyles.Spacing.extraLarge) {
            // 疲劳度指标
            VStack(alignment: .leading, spacing: 12) {
                Text("疲劳度指标")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                HStack(spacing: 20) {
                    VStack {
                        Text(String(format: "%.0f%%", analytics.fatigueIndex))
                            .sharedTextStyle(SharedStyles.Text.compactValue, color: getFatigueIndexColor(analytics.fatigueIndex))
                        Text("疲劳指数")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                    }
                    
                    VStack {
                        Text(getFatigueLevel(analytics.fatigueIndex))
                            .sharedTextStyle(SharedStyles.Text.compactValue, color: getFatigueIndexColor(analytics.fatigueIndex))
                        Text("疲劳等级")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // 疲劳趋势图
            VStack(alignment: .leading, spacing: 12) {
                Text("疲劳趋势")
                    .sharedTextStyle(SharedStyles.Text.title)
                
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
                    .sharedTextStyle(SharedStyles.Text.title)
                
                Text(generateFatigueTrainingAdvice(index: analytics.fatigueIndex))
                    .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.bodyLineSpacing)
                    .lineLimit(nil)
            }
        }
        .padding(14)
    }
    
    // MARK: - Helper Functions
    private func loadRecord() {
        record = archeryStore.getRecord(id: recordId)
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
            isLoadingAdvice = false
            adviceError = NSError(
                domain: "AICoach",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "AI教练功能已关闭"]
            )
        }

        // 已按需求关闭服务端 AI 教练请求，保留原逻辑注释以便后续恢复。
        // await MainActor.run {
        //     isLoadingAdvice = true
        //     adviceError = nil
        // }
        //
        // do {
        //     let trainingData = cozeService.prepareTrainingData(record: record)
        //     let advice = try await cozeService.getTrainingAdvice(data: trainingData)
        //     await MainActor.run {
        //         trainingAdvice = advice
        //         isLoadingAdvice = false
        //         TrainingAdviceStorage.save(advice)
        //     }
        // } catch {
        //     await MainActor.run {
        //         adviceError = error
        //         isLoadingAdvice = false
        //     }
        // }
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
        ScoreDetailView(recordId: UUID())
            .environmentObject(ArcheryStore())
            .environmentObject(TabBarManager())
    }
}

import SwiftUI
import Charts

enum RecordType {
    case group
    case single
}

// MARK: - 核心数据结构
struct ScoreGroupDetailView: View {
    let recordId: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.revealAppTabBar) private var revealAppTabBar
    @EnvironmentObject var archeryStore: ArcheryStore
    @State private var showDeleteAlert = false
    @State private var trainingAdvice: TrainingAdvice?
    @State private var isLoadingAdvice = false
    @State private var adviceError: Error?
    @State private var selectedTab = 0
    @State private var showEditView = false
    @State private var trendViewMode: TrendViewMode = .group

    
    enum TrendViewMode {
        case group
        case arrow
    }
    
    private let cozeService = CozeService()
    
    private var backgroundColor: Color {
        SharedStyles.backgroundColor
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    if let record = archeryStore.getGroupRecord(id: recordId) {
                        VStack(spacing: SharedStyles.Spacing.section) {
                            // L1 核心层：头部信息栏
                            headerInfoBar(record)
                            
                            // L1 核心层：总成绩卡片
                            totalScoreCard(record, scrollProxy: proxy)
                            
                            // L2 分析层：核心指标
                            coreMetricsSection(record)
                            
                            // L2 分析层：成绩趋势图
                            scoreTrendChart(record)
                            
                            // L2 分析层：快速统计
                            quickStatsSection(record)
                            
                            // L3 详细层：标签页分析
                            detailedAnalysisTabs(record)
                                .id("scoreDetails")
                            
                            // L4 辅助层：原始数据
                            rawDataSection(record)
                        }
                        .padding(.vertical)
                        .padding(.bottom, 90) // 为底部按钮留出空间
                        .task {
                            if archeryStore.getGroupRecord(id: recordId) != nil {
                                if let stored = TrainingAdviceStorage.get(for: recordId, type: .group) {
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
                }
            }
            .vibrantCanvasBackground()
            
            // 底部按钮 - 固定在界面底部
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
                
                NavigationLink(destination: ScoreGroupInputView()) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10n.Common.addmore)
                    }
                    .font(SharedStyles.Text.bodyEmphasis)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .blockSurface(colors: SharedStyles.GradientSet.violet, radius: 16)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
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
                archeryStore.deleteGroupRecord(id: recordId)
                revealAppTabBar?()
                dismiss()
            }
        } message: {
            Text(L10n.Detail.deleteConfirmMessage)
        }
        .hiddenAppTabBar()
        .navigationDestination(isPresented: $showEditView) {
            if let record = archeryStore.getGroupRecord(id: recordId) {
                ScoreGroupInputView(editingRecord: record)
                    .environmentObject(archeryStore)
            }
        }
    }
    
    // MARK: - L1 核心层组件
    
    /// 头部信息栏
    private func headerInfoBar(_ record: ArcheryGroupRecord) -> some View {
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
    
    /// 总成绩卡片
    private func totalScoreCard(_ record: ArcheryGroupRecord, scrollProxy: ScrollViewProxy) -> some View {
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
                    
                    Text("共\(record.numberOfGroups * record.arrowsPerGroup)箭")
                        .sharedTextStyle(SharedStyles.Text.bodyEmphasis, color: .white.opacity(0.9))
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("训练时长: 60分钟")
                            .sharedTextStyle(SharedStyles.Text.caption, color: .white.opacity(0.82))
                        Text("消耗卡路里: 180千卡")
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
            .blockSurface(colors: SharedStyles.GradientSet.violet, radius: 24)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - L2 分析层组件
    
    /// 核心指标区域
    private func coreMetricsSection(_ record: ArcheryGroupRecord) -> some View {
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
    
    /// 成绩趋势图
    private func scoreTrendChart(_ record: ArcheryGroupRecord) -> some View {
        VStack(alignment: .leading, spacing: SharedStyles.Spacing.section) {
            HStack {
                Text("成绩趋势分析")
                    .sharedTextStyle(SharedStyles.Text.title)
                Spacer()
                
                HStack(spacing: 8) {
                    Button("组") {
                        trendViewMode = .group
                    }
                    .font(SharedStyles.Text.caption)
                    .foregroundColor(trendViewMode == .group ? .white : SharedStyles.secondaryTextColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(trendViewMode == .group ? SharedStyles.secondaryColor : SharedStyles.elevatedSurfaceColor)
                    .cornerRadius(8)
                    
                    Button("箭支") {
                        trendViewMode = .arrow
                    }
                    .font(SharedStyles.Text.caption)
                    .foregroundColor(trendViewMode == .arrow ? .white : SharedStyles.secondaryTextColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(trendViewMode == .arrow ? SharedStyles.secondaryColor : SharedStyles.elevatedSurfaceColor)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            
            // 趋势图表
            Chart {
                if trendViewMode == .group {
                    ForEach(Array(record.groupScores.enumerated()), id: \.offset) { index, scores in
                        LineMark(
                            x: .value("组", index + 1),
                            y: .value("分数", calculateGroupScore(scores))
                        )
                        .foregroundStyle(SharedStyles.secondaryColor)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("组", index + 1),
                            y: .value("分数", calculateGroupScore(scores))
                        )
                        .foregroundStyle(SharedStyles.secondaryColor)
                        .symbolSize(50)
                    }
                } else {
                    let allScores = record.groupScores.flatMap { $0 }
                    ForEach(Array(allScores.enumerated()), id: \.offset) { index, score in
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
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 16)
            .chartYScale(domain: trendViewMode == .group ? 
                0...Int((Double(record.groupScores.map { calculateGroupScore($0) }.max() ?? 60) * 1.2)) : 
                0...12)
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
    
    /// 快速统计区域
    private func quickStatsSection(_ record: ArcheryGroupRecord) -> some View {
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
    
    // MARK: - L3 详细层组件
    
    /// 详细分析标签页
    private func detailedAnalysisTabs(_ record: ArcheryGroupRecord) -> some View {
        VStack(spacing: 0) {
            // 标签页头部
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
                // TabButton(title: "建议优化", isSelected: selectedTab == 4) {
                //     selectedTab = 4
                // }
            }
            .padding(.horizontal, 16)
            
            // 标签页内容
            Group {
                switch selectedTab {
                case 0:
                    shootingAnalysisTab(record)
                case 1:
                    accuracyAnalysisTab(record)
                case 2:
                    stabilityAnalysisTab(record)
                case 3:
                    fatigueAnalysisTab(record)
                case 4:
                    optimizationTab(record)
                default:
                    EmptyView()
                }
            }
            .padding(14)
            .background(Color.clear)
        }
        .clayCard(tint: SharedStyles.Accent.sky, radius: 18)
        .padding(.horizontal, 16)
    }
    
    /// 精准度分析标签页
    private func accuracyAnalysisTab(_ record: ArcheryGroupRecord) -> some View {
        let accuracyStats = ScoreAnalytics.calculateGroupRecordAccuracyStats(record)
        let impactSummary = ScoreAnalytics.calculateGroupRecordImpactAnalysis(record)
        let primaryBias = impactSummary.biasDirection
        
        return VStack(alignment: .leading, spacing: SharedStyles.Spacing.extraLarge) {
            // 精准度评估
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.blue)
                        .font(SharedStyles.Text.body)
                    Text("精准度评估")
                        .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
                }
                
                Text(ScoreAnalytics.generateAccuracyAnalysis(stats: accuracyStats))
                    .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.bodyLineSpacing)
                    .padding(SharedStyles.Spacing.medium)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
            }
            
            // 箭着点分布图
            VStack(alignment: .leading, spacing: 12) {
                Text("箭着点分布图")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                ZStack {
                    // 靶面背景
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    // 内环
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.orange, lineWidth: 2)
                        )
                    
                    // 中心环
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                        )
                    
                    // 箭着点（优先使用真实数据）
                    ForEach(ScoreAnalytics.generateArrowPoints(from: impactSummary), id: \.id) { point in
                        Circle()
                            .fill(point.color)
                            .frame(width: 6, height: 6)
                            .offset(point.offset)
                    }
                    
                    // 95%置信圆
                    Circle()
                        .stroke(Color.blue.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .frame(width: accuracyStats.spreadRadius * 10, height: accuracyStats.spreadRadius * 10)
                }
                .frame(maxWidth: .infinity)
                
                            Text("虚线圆为95%箭着点的最小包围圆 (散布圆)")
                    .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // 偏移方向分析
            VStack(alignment: .leading, spacing: 12) {
                Text("偏移方向分析")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                let offsetAnalysis = impactSummary.quadrants
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(offsetAnalysis) { analysis in
                        VStack(spacing: 8) {
                            Text(analysis.direction.localizedLabel)
                                .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                            Text("\(analysis.count)")
                                .sharedTextStyle(SharedStyles.Text.title)
                            Text(String(format: "%.1f%%", analysis.percentage))
                                .sharedTextStyle(SharedStyles.Text.microCaption, color: SharedStyles.secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SharedStyles.Spacing.dense)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
            
            // 精准度指标
            VStack(alignment: .leading, spacing: 12) {
                Text("精准度指标")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                VStack(spacing: SharedStyles.Spacing.medium) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("散布半径")
                                .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                            Text("10-20cm为良好，<10cm为优秀")
                                .sharedTextStyle(SharedStyles.Text.microCaption, color: SharedStyles.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f", accuracyStats.spreadRadius))cm")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .padding(14)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("中心偏移")
                                .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                            Text("距离中心靶心的偏心距离")
                                .sharedTextStyle(SharedStyles.Text.microCaption, color: SharedStyles.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f", impactSummary.centerOffset))cm")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .padding(14)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
            }
            
            // 主要偏向
            VStack(alignment: .leading, spacing: 12) {
                Text("主要偏向")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                HStack {
                    Image(systemName: primaryBias.symbolName)
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(primaryBias.localizedLabel)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                        Text("往这个方向偏移趋势")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                    }
                    
                    Spacer()
                }
                .padding(14)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - L4 辅助层组件
    
    /// 原始数据展示
    private func rawDataSection(_ record: ArcheryGroupRecord) -> some View {
        VStack(alignment: .leading, spacing: SharedStyles.Spacing.section) {
            HStack {
                Text("团体成绩详情")
                    .sharedTextStyle(SharedStyles.Text.title)
                Spacer()
                
                Button("展开全部") {
                    // 展开/收起逻辑
                }
                .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryColor)
            }
            .padding(.horizontal, 16)
            
            LazyVStack(spacing: SharedStyles.Spacing.medium) {
                ForEach(Array(record.groupScores.enumerated()), id: \.offset) { index, scores in
                    GroupScoreRow(
                        groupNumber: index + 1,
                        scores: scores,
                        totalScore: calculateGroupScore(scores)
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, SharedStyles.Spacing.section)
        .clayCard(tint: SharedStyles.secondaryColor, radius: 18)
        .padding(.horizontal, 16)
    }
    
    // MARK: - 计算逻辑
    
    /// 计算核心分析数据
    private func calculateAnalytics(_ record: ArcheryGroupRecord) -> ArcheryAnalytics {
        return ScoreAnalytics.calculateGroupRecordAnalytics(record)
    }
    
    // MARK: - 标签页内容
    
    /// 环数分析标签页
    private func shootingAnalysisTab(_ record: ArcheryGroupRecord) -> some View {
        let analytics = calculateAnalytics(record)
        let ringDistribution = calculateRingDistribution(record)
        
        return VStack(alignment: .leading, spacing: SharedStyles.Spacing.extraLarge) {
            // 环数分布图表
            VStack(alignment: .leading, spacing: 12) {
                Text("环数分布")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                Chart {
                    ForEach(ringDistribution.sorted(by: { $0.key > $1.key }), id: \.key) { ring, count in
                        BarMark(
                            x: .value("环数", ring),
                            y: .value("数量", count)
                        )
                        .foregroundStyle(ringColor(for: ring))
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel() {
                            if let ring = value.as(String.self) {
                                Text(ring)
                                    .font(SharedStyles.Text.footnote)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel() {
                            if let count = value.as(Int.self) {
                                Text("\(count)")
                                    .font(SharedStyles.Text.footnote)
                            }
                        }
                    }
                }
            }
            
            // 环数统计卡片
            VStack(alignment: .leading, spacing: 12) {
                Text("详细统计")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    RingStatCard(ring: "X", count: analytics.xRingCount, total: analytics.totalArrows, color: .red)
                    RingStatCard(ring: "10", count: analytics.tenRingCount, total: analytics.totalArrows, color: .orange)
                    RingStatCard(ring: "9", count: analytics.nineRingCount, total: analytics.totalArrows, color: .yellow)
                }
            }
            
            // 成绩占比分析
            VStack(alignment: .leading, spacing: 12) {
                Text("成绩分析")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("金环率 (9-X环)")
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                        Text(String(format: "%.1f%%", calculateGoldRingRate(record)))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("平均环数")
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                        Text(String(format: "%.2f", analytics.averageRing))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .padding(14)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
    
    /// 稳定性分析标签页（优化版）
    private func stabilityAnalysisTab(_ record: ArcheryGroupRecord) -> some View {
        let analytics = calculateAnalytics(record)
        let stabilityData = calculateStabilityData(record)
        
        return VStack(alignment: .leading, spacing: SharedStyles.Spacing.extraLarge) {
            // 组成绩控制图
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("组成绩控制图")
                        .sharedTextStyle(SharedStyles.Text.title)
                    
                    Spacer()
                    
                    Text("σ控制限")
                        .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                }
                
                Chart {
                    // 控制区域背景
                    RectangleMark(
                        xStart: .value("开始", 0.5),
                        xEnd: .value("结束", Double(stabilityData.groupScores.count) + 0.5),
                        yStart: .value("下限", stabilityData.lowerLimit),
                        yEnd: .value("上限", stabilityData.upperLimit)
                    )
                    .foregroundStyle(.green.opacity(0.1))
                    
                    // 平均线
                    RuleMark(y: .value("平均分", analytics.averageRing))
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("μ = \(String(format: "%.1f", analytics.averageRing))")
                                .sharedTextStyle(SharedStyles.Text.microCaption, color: .blue)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    
                    // 上控制线
                    RuleMark(y: .value("上限", stabilityData.upperLimit))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [3, 3]))
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("UCL = \(String(format: "%.1f", stabilityData.upperLimit))")
                                .sharedTextStyle(SharedStyles.Text.microCaption, color: .red)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                        }
                    
                    // 下控制线
                    RuleMark(y: .value("下限", stabilityData.lowerLimit))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [3, 3]))
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("LCL = \(String(format: "%.1f", stabilityData.lowerLimit))")
                                .sharedTextStyle(SharedStyles.Text.microCaption, color: .red)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                        }
                    
                    // 连接线
                    ForEach(Array(stabilityData.groupScores.enumerated()), id: \.offset) { index, score in
                        if index < stabilityData.groupScores.count - 1 {
                            LineMark(
                                x: .value("组数", index + 1),
                                y: .value("得分", score)
                            )
                            .foregroundStyle(.gray.opacity(0.8))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                    
                    // 实际数据点
                    ForEach(Array(stabilityData.groupScores.enumerated()), id: \.offset) { index, score in
                        let isOutOfControl = score > stabilityData.upperLimit || score < stabilityData.lowerLimit
                        PointMark(
                            x: .value("组数", index + 1),
                            y: .value("得分", score)
                        )
                        .foregroundStyle(isOutOfControl ? .red : .green)
                        .symbolSize(isOutOfControl ? 60 : 50)
                        .symbol(isOutOfControl ? .triangle : .circle)
                        .annotation(position: .top, alignment: .center) {
                            if isOutOfControl {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(SharedStyles.Text.microCaption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(.gray.opacity(0.3))
                        AxisTick()
                        AxisValueLabel() {
                            if let group = value.as(Int.self) {
                                Text("第\(group)组")
                                    .sharedTextStyle(SharedStyles.Text.microCaption, color: SharedStyles.secondaryTextColor)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(.gray.opacity(0.3))
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            }
            
            // 稳定性指标
            VStack(alignment: .leading, spacing: 12) {
                Text("稳定性指标")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                // 主要指标卡片
                VStack(spacing: SharedStyles.Spacing.medium) {
                    HStack(spacing: SharedStyles.Spacing.medium) {
                        // 稳定性评分
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(SharedStyles.Text.body)
                                    .foregroundColor(.green)
                                Text("稳定性评分")
                                    .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                                Spacer()
                            }
                            
                            HStack {
                                Text(String(format: "%.0f", analytics.stabilityScore))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.green)
                                Text("分")
                                    .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                                Spacer()
                                Text(getStabilityLevel(analytics.stabilityScore))
                                    .font(SharedStyles.Text.footnote.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(getStabilityLevelColor(analytics.stabilityScore))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(14)
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        )
                        
                        // 变异系数
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "waveform.path.ecg")
                                    .font(SharedStyles.Text.body)
                                    .foregroundColor(.blue)
                                Text("变异系数")
                                    .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                                Spacer()
                            }
                            
                            HStack {
                                Text(String(format: "%.2f", stabilityData.coefficientOfVariation))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.blue)
                                Text("%")
                                    .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                                Spacer()
                                Text(getCVLevel(stabilityData.coefficientOfVariation))
                                    .font(SharedStyles.Text.footnote.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(getCVLevelColor(stabilityData.coefficientOfVariation))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(14)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // 详细统计信息
                    VStack(spacing: SharedStyles.Spacing.small) {
                        HStack {
                            Text("详细统计")
                                .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryTextColor)
                            Spacer()
                        }
                        
                        HStack(spacing: SharedStyles.Spacing.large) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("标准差")
                                    .font(.system(size: 11))
                                    .foregroundColor(SharedStyles.secondaryTextColor)
                                Text(String(format: "%.2f", sqrt(stabilityData.groupScores.map { pow($0 - analytics.averageRing, 2) }.reduce(0, +) / Double(stabilityData.groupScores.count))))
                                    .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryTextColor)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text("极差")
                                    .font(.system(size: 11))
                                    .foregroundColor(SharedStyles.secondaryTextColor)
                                Text(String(format: "%.1f", (stabilityData.groupScores.max() ?? 0) - (stabilityData.groupScores.min() ?? 0)))
                                    .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryTextColor)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("失控点")
                                    .font(.system(size: 11))
                                    .foregroundColor(SharedStyles.secondaryTextColor)
                                let outOfControlCount = stabilityData.groupScores.filter { $0 > stabilityData.upperLimit || $0 < stabilityData.lowerLimit }.count
                                Text("\(outOfControlCount)/\(stabilityData.groupScores.count)")
                                    .font(SharedStyles.Text.caption.weight(.semibold))
                                    .foregroundColor(outOfControlCount > 0 ? .red : .green)
                            }
                        }
                    }
                    .padding(SharedStyles.Spacing.medium)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            // 稳定性评估与建议
            VStack(alignment: .leading, spacing: 12) {
                Text("稳定性评估与建议")
                    .sharedTextStyle(SharedStyles.Text.title)
                
                VStack(spacing: SharedStyles.Spacing.medium) {
                    // 综合评估
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(SharedStyles.Text.caption)
                                .foregroundColor(.green)
                            Text("综合评估")
                                .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryTextColor)
                        }
                        
                        Text(generateStabilityAnalysis(score: analytics.stabilityScore, cv: stabilityData.coefficientOfVariation))
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.captionLineSpacing)
                            .lineLimit(nil)
                    }
                    .padding(SharedStyles.Spacing.medium)
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
                    
                    // 训练建议
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(SharedStyles.Text.caption)
                                .foregroundColor(.orange)
                            Text("训练建议")
                                .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryTextColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(generateStabilityTrainingAdvice(score: analytics.stabilityScore, cv: stabilityData.coefficientOfVariation).components(separatedBy: "\n"), id: \.self) { advice in
                                if !advice.isEmpty {
                                    HStack(alignment: .top, spacing: 8) {
                                        Text(advice.hasPrefix("•") ? "" : "•")
                                            .font(SharedStyles.Text.caption.weight(.bold))
                                            .foregroundColor(.orange)
                                        Text(advice)
                                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.captionLineSpacing)
                                            .lineLimit(nil)
                                    }
                                }
                            }
                        }
                    }
                    .padding(SharedStyles.Spacing.medium)
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                    
                    // 失控点分析（如果有的话）
                    let outOfControlCount = stabilityData.groupScores.filter { $0 > stabilityData.upperLimit || $0 < stabilityData.lowerLimit }.count
                    if outOfControlCount > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(SharedStyles.Text.caption)
                                    .foregroundColor(.red)
                                Text("失控点分析")
                                    .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryTextColor)
                            }
                            
                            Text("检测到 \(outOfControlCount) 个失控点，这些数据点超出了统计控制限。建议分析这些异常表现的原因，可能与射击技术、心理状态或外部环境有关。")
                                .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.captionLineSpacing)
                                .lineLimit(nil)
                        }
                        .padding(SharedStyles.Spacing.medium)
                        .background(Color.red.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    /// 疲劳曲线标签页（优化版）
    private func fatigueAnalysisTab(_ record: ArcheryGroupRecord) -> some View {
        let analytics = calculateAnalytics(record)
        let fatigueData = calculateFatigueData(record)
        let averageScore = Double(fatigueData.reduce(0, +)) / Double(fatigueData.count)
        
        return VStack(alignment: .leading, spacing: SharedStyles.Spacing.extraLarge) {
            // 成绩变化趋势图
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("成绩变化趋势")
                        .sharedTextStyle(SharedStyles.Text.title)
                    
                    Spacer()
                    
                    Label("疲劳分析", systemImage: "waveform.path.ecg.rectangle")
                        .font(SharedStyles.Text.footnote)
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Chart {
                    // 平均线
                    RuleMark(y: .value("平均分", averageScore))
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .topTrailing, alignment: .leading) {
                            Text("平均分: \(String(format: "%.1f", averageScore))")
                                .sharedTextStyle(SharedStyles.Text.microCaption, color: SharedStyles.secondaryTextColor)
                                .padding(.horizontal, 4)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(4)
                        }
                    
                    // 趋势线和数据点
                    ForEach(Array(fatigueData.enumerated()), id: \.offset) { index, score in
                        LineMark(
                            x: .value("组数", index + 1),
                            y: .value("得分", score)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("组数", index + 1),
                            y: .value("得分", score)
                        )
                        .foregroundStyle(Double(score) < averageScore ? .red : .blue)
                        .symbolSize(Double(score) < averageScore ? 60 : 40)
                        .symbol(Double(score) < averageScore ? .triangle : .circle)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        AxisTick()
                        AxisValueLabel() {
                            if let group = value.as(Int.self) {
                                Text("第\(group)组")
                                    .sharedTextStyle(SharedStyles.Text.microCaption, color: SharedStyles.secondaryTextColor)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        AxisTick()
                        AxisValueLabel() {
                            if let score = value.as(Int.self) {
                                Text("\(score)")
                                    .sharedTextStyle(SharedStyles.Text.microCaption, color: SharedStyles.secondaryTextColor)
                            }
                        }
                    }
                }
            }
            
            // 疲劳指标卡片
            HStack(spacing: SharedStyles.Spacing.medium) {
                // 疲劳指数
                VStack(spacing: SharedStyles.Spacing.small) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(getFatigueIndexColor(analytics.fatigueIndex))
                            .font(SharedStyles.Text.body)
                        Text("疲劳指数")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                        Spacer()
                    }
                    
                    Text(String(format: "%.1f%%", analytics.fatigueIndex))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(getFatigueIndexColor(analytics.fatigueIndex))
                    
                    Text(getFatigueLevel(analytics.fatigueIndex))
                        .font(SharedStyles.Text.footnote.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(getFatigueIndexColor(analytics.fatigueIndex))
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(getFatigueIndexColor(analytics.fatigueIndex).opacity(0.1))
                .cornerRadius(12)
                
                // 成绩下降幅度
                VStack(spacing: SharedStyles.Spacing.small) {
                    HStack {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .foregroundColor(.orange)
                            .font(SharedStyles.Text.body)
                        Text("下降幅度")
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                        Spacer()
                    }
                    
                    let maxScore = fatigueData.max() ?? 0
                    let minScore = fatigueData.min() ?? 0
                    let decline = maxScore - minScore
                    
                    Text("\(decline)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    
                    Text("环数差")
                        .font(SharedStyles.Text.footnote.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            // 疲劳分析
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                        .font(SharedStyles.Text.body)
                    Text("疲劳分析")
                        .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    let analysis = generateFatigueAnalysis(index: analytics.fatigueIndex)
                    ForEach(analysis.components(separatedBy: "\n").filter { !$0.isEmpty }, id: \.self) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.purple)
                                .font(SharedStyles.Text.caption.weight(.bold))
                            Text(line)
                                .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.bodyLineSpacing)
                                .lineLimit(nil)
                        }
                    }
                }
                .padding(14)
                .background(Color.purple.opacity(0.05))
                .cornerRadius(12)
            }
            
            // 训练建议
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.green)
                        .font(SharedStyles.Text.body)
                    Text("训练建议")
                        .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    let advice = generateFatigueTrainingAdvice(index: analytics.fatigueIndex)
                    ForEach(advice.components(separatedBy: "\n").filter { !$0.isEmpty }, id: \.self) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(SharedStyles.Text.footnote)
                                .foregroundStyle(.green)
                            Text(line)
                                .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.bodyLineSpacing)
                                .lineLimit(nil)
                        }
                    }
                }
                .padding(14)
                .background(Color.green.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
    
    private func optimizationTab(_ record: ArcheryGroupRecord) -> some View {
        VStack(alignment: .leading, spacing: SharedStyles.Spacing.section) {
            Text("训练建议")
                .sharedTextStyle(SharedStyles.Text.title)
            
            if let advice = trainingAdvice {
                VStack(alignment: .leading, spacing: 12) {
                    // 显示水平评估
                    Text(advice.performanceLevel)
                        .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.bodyLineSpacing)
                    
                    // 显示问题分析
                    if !advice.issues.isEmpty {
                        Text("主要问题：")
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryTextColor)
                        
                        ForEach(advice.issues, id: \.self) { issue in
                            Text("• \(issue)")
                                .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.bodyLineSpacing)
                        }
                    }
                    
                    // 显示改进建议
                    if !advice.suggestions.isEmpty {
                        Text("改进建议：")
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryTextColor)
                        
                        ForEach(advice.suggestions, id: \.self) { suggestion in
                            Text("• \(suggestion)")
                                .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.bodyLineSpacing)
                        }
                    }
                }
                .lineLimit(nil)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• 保持当前的射击节奏和姿势")
                    Text("• 加强瞄准稳定性训练")
                    Text("• 注意呼吸控制和心理调节")
                    Text("• 适当增加体能训练")
                }
                .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor, lineSpacing: SharedStyles.bodyLineSpacing)
            }
        }
    }
    
    // MARK: - 辅助方法（保持原有方法）
    
    private func calculateTotalScore(_ record: ArcheryGroupRecord) -> Int {
        record.groupScores.reduce(0) { sum, scores in
            sum + scores.calculateScore()
        }
    }
    
    private func calculateGroupScore(_ scores: [String]) -> Int {
        scores.calculateScore()
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
            return Int(score) ?? 0
        }
    }
    
    private func countXForGroup(_ record: ArcheryGroupRecord) -> Int {
        record.groupScores.flatMap { $0 }.filter { $0.lowercased() == "x" }.count
    }
    
    private func count10ForGroup(_ record: ArcheryGroupRecord) -> Int {
        record.groupScores.flatMap { $0 }.filter { $0 == "10" }.count
    }
    
    private func count9ForGroup(_ record: ArcheryGroupRecord) -> Int {
        record.groupScores.flatMap { $0 }.filter { $0 == "9" }.count
    }
    
    private func calculateAverage(_ record: ArcheryGroupRecord) -> Double {
        let allScores = record.groupScores.flatMap { $0 }
        let totalScore = allScores.calculateScore()
        return Double(totalScore) / Double(allScores.count)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func loadTrainingAdvice(for record: ArcheryGroupRecord, forceRefresh: Bool = false) async {
        // 如果不是强制刷新，且已经有数据，直接返回
        if !forceRefresh && trainingAdvice != nil {
            return
        }
        
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
        //     let trainingData = cozeService.prepareGroupTrainingData(record: record)
        //     let advice = try await cozeService.getTrainingAdvice(data: trainingData)
        //
        //     let adviceWithMeta = TrainingAdvice(
        //         performanceLevel: advice.performanceLevel,
        //         issues: advice.issues,
        //         suggestions: advice.suggestions,
        //         improvements: advice.improvements,
        //         recordId: recordId,
        //         recordType: .group,
        //         timestamp: Date()
        //     )
        //
        //     TrainingAdviceStorage.save(adviceWithMeta)
        //
        //     await MainActor.run {
        //         trainingAdvice = adviceWithMeta
        //         isLoadingAdvice = false
        //     }
        // } catch {
        //     await MainActor.run {
        //         adviceError = error
        //         isLoadingAdvice = false
        //     }
        // }
    }
    
    // 获取分数分布
    private func getScoreDistribution(from scores: [String]) -> [String: Int] {
        var distribution: [String: Int] = [:]
        for score in scores {
            distribution[score, default: 0] += 1
        }
        return distribution
    }
    
    
    // 添加一个辅助方法来处理 Markdown 文本
    private func markdownText(_ text: String) -> Text {
        let components = text.components(separatedBy: "**")
        return components.enumerated().reduce(Text("")) { result, pair in
            let (index, component) = pair
            if index % 2 == 0 {
                return result + Text(component)
            } else {
                return result + Text(component).bold()
            }
        }
    }
    
    private func aiCoachCard(_ record: ArcheryGroupRecord) -> some View {
        AiCoachGroupContent(record: record)
    }
    
    // MARK: - 历史数据比较和分析方法
    
    private func calculateTrends(for record: ArcheryGroupRecord) -> (averageTrend: String, stabilityTrend: String, fatigueTrend: String, tenRingTrend: String) {
        let currentAnalytics = calculateAnalytics(record)
        
        // 获取历史记录（相同弓型、距离、靶型的前几次记录）
        let historicalRecords = archeryStore.groupRecords
            .filter { $0.bowType == record.bowType && $0.distance == record.distance && $0.targetType == record.targetType && $0.id != record.id }
            .sorted { $0.date > $1.date }
            .prefix(5) // 取最近5次记录
        
        guard !historicalRecords.isEmpty else {
            return ("--", "--", "--", "--")
        }
        
        // 计算历史平均值
        let historicalAnalytics = historicalRecords.map { calculateAnalytics($0) }
        let avgHistoricalAverage = historicalAnalytics.map { $0.averageRing }.reduce(0, +) / Double(historicalAnalytics.count)
        let avgHistoricalStability = historicalAnalytics.map { $0.stabilityScore }.reduce(0, +) / Double(historicalAnalytics.count)
        let avgHistoricalFatigue = historicalAnalytics.map { $0.fatigueIndex }.reduce(0, +) / Double(historicalAnalytics.count)
        let avgHistoricalTenRing = historicalAnalytics.map { $0.tenRingRate }.reduce(0, +) / Double(historicalAnalytics.count)
        
        // 计算趋势
        let averageDiff = currentAnalytics.averageRing - avgHistoricalAverage
        let stabilityDiff = currentAnalytics.stabilityScore - avgHistoricalStability
        let fatigueDiff = avgHistoricalFatigue - currentAnalytics.fatigueIndex // 疲劳度越低越好
        let tenRingDiff = currentAnalytics.tenRingRate - avgHistoricalTenRing
        
        return (
            averageTrend: formatTrend(averageDiff, isPercentage: false),
            stabilityTrend: formatTrend(stabilityDiff, isPercentage: true),
            fatigueTrend: formatTrend(fatigueDiff, isPercentage: true),
            tenRingTrend: formatTrend(tenRingDiff, isPercentage: true)
        )
    }
    
    private func formatTrend(_ diff: Double, isPercentage: Bool) -> String {
        if abs(diff) < 0.01 { return "--" }
        let sign = diff > 0 ? "+" : ""
        if isPercentage {
            return "\(sign)\(String(format: "%.0f", diff))%"
        } else {
            return "\(sign)\(String(format: "%.1f", diff))"
        }
    }
    
    private func generateShootingAnalysis(analytics: ArcheryAnalytics) -> String {
        let highRingRate = (Double(analytics.xRingCount + analytics.tenRingCount) / Double(analytics.totalArrows)) * 100
        
        if highRingRate >= 70 {
            return "射击精度表现优秀，X环和10环命中率达到\(String(format: "%.0f", highRingRate))%，建议继续保持当前的射击节奏和技术动作。"
        } else if highRingRate >= 50 {
            return "射击精度表现良好，高环命中率为\(String(format: "%.0f", highRingRate))%，可以通过加强瞄准稳定性训练来进一步提升。"
        } else if highRingRate >= 30 {
            return "射击精度有提升空间，建议重点练习基础动作，特别是瞄准和撒放的一致性。"
        } else {
            return "建议回到基础训练，重点练习站姿、瞄准和撒放动作，逐步提高射击稳定性。"
        }
    }
    
    private func generateStabilityAnalysis(score: Double, cv: Double) -> String {
        if score >= 85 {
            return "稳定性表现优秀，各组成绩波动很小，说明技术动作已经形成良好的肌肉记忆。变异系数为\(String(format: "%.1f%%", cv))，表现出色。"
        } else if score >= 70 {
            return "稳定性表现良好，偶有波动属于正常范围，继续保持训练频率即可。变异系数为\(String(format: "%.1f%%", cv))，处于合理区间。"
        } else if score >= 55 {
            return "稳定性有待提升，建议加强基础动作训练，重点关注动作的一致性。变异系数为\(String(format: "%.1f%%", cv))，需要改善。"
        } else {
            return "稳定性需要重点改善，建议降低训练强度，专注于基础动作的标准化练习。变异系数为\(String(format: "%.1f%%", cv))，波动较大。"
        }
    }
    
    private func generateStabilityTrainingAdvice(score: Double, cv: Double) -> String {
        var advice: [String] = []
        
        if score < 70 {
            advice.append("• 加强基础动作训练，重点练习站姿、握弓、拉弓的一致性")
            advice.append("• 每次训练前进行充分的热身和瞄准练习")
        }
        
        if cv > 15 {
            advice.append("• 降低训练强度，专注于动作质量而非数量")
            advice.append("• 增加空拉练习，强化肌肉记忆")
        }
        
        if score >= 70 && cv <= 10 {
            advice.append("• 保持当前训练节奏，可适当增加训练距离")
            advice.append("• 尝试在不同环境条件下训练，提升适应性")
        }
        
        advice.append("• 建议每组射击后进行短暂休息，避免疲劳影响稳定性")
        
        return advice.joined(separator: "\n")
    }
    
    private func generateFatigueAnalysis(index: Double) -> String {
        if index <= 10 {
            return "疲劳控制优秀，全程保持稳定的射击状态，体能和专注力都很好。"
        } else if index <= 20 {
            return "疲劳控制良好，后半段略有下降但在可接受范围内。"
        } else if index <= 35 {
            return "后半段成绩下降较明显，建议适当调整训练强度或增加休息间隔。"
        } else {
            return "疲劳度较高，建议缩短训练时间，重点提升体能和专注力持久度。"
        }
    }
    
    // MARK: - 新增辅助计算方法
    
    private func calculateRingDistribution(_ record: ArcheryGroupRecord) -> [String: Int] {
        return ScoreAnalytics.calculateGroupRecordRingDistribution(record)
    }
    
    private func ringColor(for ring: String) -> Color {
        return ScoreAnalytics.ringColorForGroup(for: ring)
    }
    
    private func calculateGoldRingRate(_ record: ArcheryGroupRecord) -> Double {
        return ScoreAnalytics.calculateGroupRecordGoldRingRate(record)
    }
    
    private func calculateFatigueData(_ record: ArcheryGroupRecord) -> [Int] {
        return ScoreAnalytics.calculateGroupRecordFatigueData(record).map { Int($0) }
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
    
    private func calculateStabilityData(_ record: ArcheryGroupRecord) -> (groupScores: [Double], upperLimit: Double, lowerLimit: Double, coefficientOfVariation: Double) {
        return ScoreAnalytics.calculateGroupRecordStabilityData(record)
    }
    
    private func getStabilityLevel(_ score: Double) -> String {
        return ScoreAnalytics.getStabilityLevel(score)
    }
    
    private func getStabilityLevelColor(_ score: Double) -> Color {
        return ScoreAnalytics.getStabilityLevelColor(score)
    }
    
    private func getCVLevel(_ cv: Double) -> String {
        return ScoreAnalytics.getCVLevel(cv)
    }
    
    private func getCVLevelColor(_ cv: Double) -> Color {
        return ScoreAnalytics.getCVLevelColor(cv)
    }
    
}

// MARK: - 辅助视图组件

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(title)
                .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
            
            HStack(spacing: 2) {
                Text(value)
                    .sharedTextStyle(SharedStyles.Text.title)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SharedStyles.Spacing.section)
        .clayCard(tint: color, radius: 14)
    }
}

struct QuickStatCard: View {
    let iconSystemName: String
    let title: String
    let value: String
    let trend: String
    
    var body: some View {
        VStack(spacing: SharedStyles.Spacing.small) {
            Image(systemName: iconSystemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(SharedStyles.primaryTextColor.opacity(0.85))
            
            Text(title)
                .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
            
            Text(value)
                .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
            
            Text(trend)
                .font(SharedStyles.Text.footnote)
                .foregroundColor(trend.hasPrefix("+") ? .green : .red)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SharedStyles.Spacing.dense)
        .clayCard(tint: SharedStyles.Accent.sky, radius: 12)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: SharedStyles.Spacing.small) {
                Text(title)
                    .font(isSelected ? SharedStyles.Text.caption.weight(.bold) : SharedStyles.Text.caption)
                    .foregroundColor(isSelected ? SharedStyles.primaryTextColor : SharedStyles.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SharedStyles.Spacing.dense)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? SharedStyles.secondaryColor.opacity(0.18) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct GroupScoreRow: View {
    let groupNumber: Int
    let scores: [String]
    let totalScore: Int
    
    var body: some View {
        HStack {
            // 组号
            Text("第\(groupNumber)组")
                .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryTextColor)
                .frame(width: 60, alignment: .leading)
            
            // 靶面图标和分数
            HStack(spacing: 4) {
                ForEach(Array(scores.enumerated()), id: \.offset) { index, score in
                    ScoreRingView(score: score)
                }
            }
            
            Spacer()
            
            // 总分
            Text("\(totalScore)")
                .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, SharedStyles.Spacing.dense)
        .background(SharedStyles.elevatedSurfaceColor.opacity(0.82))
        .cornerRadius(8)
    }
}

struct ScoreRingView: View {
    let score: String
    
    var body: some View {
        Text(score)
            .font(SharedStyles.Text.footnote)
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background(ringColor)
            .clipShape(Circle())
    }
    
    private var ringColor: Color {
        switch score.lowercased() {
        case "x":
            return SharedStyles.Accent.coral
        case "10":
            return SharedStyles.Accent.orange
        case "9":
            return SharedStyles.Accent.lemon
        case "8":
            return SharedStyles.Accent.mint
        case "7":
            return SharedStyles.Accent.sky
        default:
            return SharedStyles.tertiaryTextColor
        }
    }
}

struct RingStatCard: View {
    let ring: String
    let count: Int
    let total: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(ring)
                .sharedTextStyle(SharedStyles.Text.bodyEmphasis, color: color)
            
            Text("\(count)")
                .sharedTextStyle(SharedStyles.Text.title)
            
            Text(String(format: "%.1f%%", Double(count) / Double(total) * 100))
                .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SharedStyles.Spacing.dense)
        .clayCard(tint: color, radius: 12)
    }
}

// MARK: - 扩展

extension Array where Element == String {
    func calculateScore() -> Int {
        return self.reduce(0) { sum, score in
            if score.lowercased() == "x" {
                return sum + 10
            } else if let intScore = Int(score) {
                return sum + intScore
            }
            return sum
        }
    }
}

#Preview {
    ScoreGroupDetailView(recordId: UUID())
}

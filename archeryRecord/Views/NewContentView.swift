import SwiftUI

final class TabBarManager: ObservableObject {
    @Published private var hiddenTokens: Set<String> = []
    
    var isVisible: Bool {
        hiddenTokens.isEmpty
    }
    
    func hide(_ token: String) {
        hiddenTokens.insert(token)
    }
    
    func show(_ token: String) {
        hiddenTokens.remove(token)
    }
}

private struct RevealAppTabBarKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var revealAppTabBar: (() -> Void)? {
        get { self[RevealAppTabBarKey.self] }
        set { self[RevealAppTabBarKey.self] = newValue }
    }
}

struct NewContentView: View {
    @EnvironmentObject private var archeryStore: ArcheryStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @StateObject private var tabBarManager = TabBarManager()
    @State private var selectedTab = 0
    @State private var showProPaywall = false
    
    var body: some View {
        ZStack {
            recordTab
                .opacity(selectedTab == 0 ? 1 : 0)
                .allowsHitTesting(selectedTab == 0)
            
            analysisTab
                .opacity(selectedTab == 1 ? 1 : 0)
                .allowsHitTesting(selectedTab == 1)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if tabBarManager.isVisible {
                AppTabBar(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.18), value: tabBarManager.isVisible)
        .environmentObject(tabBarManager)
        .sheet(isPresented: $showProPaywall) {
            ProPaywallView()
                .environmentObject(purchaseManager)
        }
    }

    private var recordTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // 顶部标题和设置按钮
                    HStack {
                        Text(L10n.Content.appTitle)
                            .sharedTextStyle(SharedStyles.Text.screenTitle)
                        
                        Spacer()

                        Button {
                            showProPaywall = true
                        } label: {
                            VStack(spacing: 1) {
                                if purchaseManager.isProUnlocked {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [SharedStyles.Accent.mint, SharedStyles.Accent.teal],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                } else {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 17, weight: .black))
                                        .foregroundStyle(SharedStyles.Accent.orange)
                                }

                                Text(purchaseManager.isProUnlocked ? L10n.Pro.cornerUnlockedLabel : L10n.Pro.badge)
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: purchaseManager.isProUnlocked
                                                ? [SharedStyles.Accent.teal, SharedStyles.Accent.mint]
                                                : [
                                                    Color(red: 0.99, green: 0.86, blue: 0.34),
                                                    Color(red: 0.88, green: 0.64, blue: 0.08)
                                                ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .tracking(0.3)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                            }
                            .frame(width: 46, height: 52)
                            .clayCard(
                                tint: purchaseManager.isProUnlocked ? SharedStyles.Accent.mint : SharedStyles.Accent.orange,
                                radius: 18
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(SharedStyles.primaryTextColor)
                                .frame(width: 46, height: 46)
                                .clayCard(tint: SharedStyles.Accent.sky, radius: 18)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // 快捷操作卡片
                    HStack(spacing: 16) {
                        // 记一组卡片
                        NavigationLink {
                            ScoreInputView()
                        } label: {
                            RecordCard(
                                title: L10n.Nav.record,
                                subtitle: L10n.tr("content_record_count", archeryStore.records.count),
                                icon: "record_info",
                                colors: SharedStyles.GradientSet.sunrise
                            )
                        }
                        
                        // 记一场卡片
                        NavigationLink {
                            ScoreGroupInputView()
                        } label: {
                            RecordCard(
                                title: L10n.Nav.groupRecord,
                                subtitle: L10n.tr("content_record_count", archeryStore.groupRecords.count),
                                icon: "record_match",
                                colors: SharedStyles.GradientSet.violet
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // 成绩列表标题
                    Text(L10n.tr("content_record_list"))
                        .sharedTextStyle(SharedStyles.Text.sectionTitle)
                        .padding(.horizontal)
                        .padding(.top, 4)
                    
                    // 记录列表
                    if archeryStore.records.isEmpty && archeryStore.groupRecords.isEmpty {
                        EmptyStateView()
                    } else {
                        VStack(spacing: -20) {
                            ForEach(getSortedRecords(), id: \.id) { record in
                                switch record {
                                case .single(let singleRecord):
                                    NavigationLink(destination:
                                        ScoreDetailView(recordId: singleRecord.id)
                                            .environmentObject(archeryStore)
                                    ) {
                                        SingleRecordCard(record: singleRecord)
                                    }
                                case .group(let groupRecord):
                                    NavigationLink(destination:
                                        ScoreGroupDetailView(recordId: groupRecord.id)
                                            .environmentObject(archeryStore)
                                    ) {
                                        GroupRecordCard(record: groupRecord)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 16)
            }
            .vibrantCanvasBackground(showsDecorations: false)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private var analysisTab: some View {
        NavigationStack {
            ScoreAnalysisView()
        }
    }
    
    // 添加一个枚举来处理不同类型的记录
    private enum RecordType: Identifiable {
        case single(ArcheryRecord)
        case group(ArcheryGroupRecord)
        
        var id: UUID {
            switch self {
            case .single(let record): return record.id
            case .group(let record): return record.id
            }
        }
        
        var date: Date {
            switch self {
            case .single(let record): return record.date
            case .group(let record): return record.date
            }
        }
    }
    
    // 获取排序后的记录
    private func getSortedRecords() -> [RecordType] {
        let singleRecords = archeryStore.records.map { RecordType.single($0) }
        let groupRecords = archeryStore.groupRecords.map { RecordType.group($0) }
        
        return (singleRecords + groupRecords)
            .sorted { $0.date > $1.date } // 按日期降序排序（最新的在前）
    }
}

private struct AppTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 6) {
            tabButton(index: 0, title: L10n.Tab.record, systemImage: "list.bullet")
            tabButton(index: 1, title: L10n.Tab.analysis, systemImage: "chart.xyaxis.line")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tabBarBackground)
        .overlay(tabBarBorder)
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
        .shadow(color: Color.white.opacity(0.28), radius: 6, x: 0, y: -1)
        .frame(width: tabBarWidth)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 6)
    }

    private var tabBarWidth: CGFloat {
        #if os(iOS)
        min(UIScreen.main.bounds.width * 0.76, 320)
        #else
        300
        #endif
    }

    private var tabBarShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }

    private var tabBarBackground: some View {
        tabBarShape
            .fill(Color.white.opacity(0.70))
            .background(.ultraThinMaterial, in: tabBarShape)
    }

    private var tabBarBorder: some View {
        tabBarShape
            .stroke(Color.white.opacity(0.72), lineWidth: 1)
            .overlay {
                tabBarShape
                    .stroke(SharedStyles.primaryTextColor.opacity(0.08), lineWidth: 0.6)
                    .blur(radius: 0.2)
            }
    }
    
    private func tabButton(index: Int, title: String, systemImage: String) -> some View {
        let isSelected = selectedTab == index
        
        return Button {
            selectedTab = index
        } label: {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .medium))
                Text(title)
                    .font(SharedStyles.Text.microCaption)
            }
            .foregroundStyle(isSelected ? SharedStyles.primaryTextColor : SharedStyles.secondaryTextColor.opacity(0.82))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? SharedStyles.primaryColor.opacity(0.14) : Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? SharedStyles.primaryColor.opacity(0.10) : Color.clear, lineWidth: 0.8)
                    }
            )
        }
        .buttonStyle(.plain)
    }
}

private struct HiddenAppTabBarModifier: ViewModifier {
    @EnvironmentObject private var tabBarManager: TabBarManager
    @State private var token = UUID().uuidString
    
    func body(content: Content) -> some View {
        content
            .environment(\.revealAppTabBar) {
                tabBarManager.show(token)
            }
            .onAppear {
                tabBarManager.hide(token)
            }
            .onDisappear {
                tabBarManager.show(token)
            }
    }
}

extension View {
    func hiddenAppTabBar() -> some View {
        modifier(HiddenAppTabBarModifier())
    }
}

// 记录卡片组件
struct RecordCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 52, height: 52)

                    if icon.starts(with: "system:") {
                        Image(systemName: icon.replacingOccurrences(of: "system:", with: ""))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.18))
                    )
            }

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .sharedTextStyle(SharedStyles.Text.title, color: .white)
                
                Text(subtitle)
                    .sharedTextStyle(
                        SharedStyles.Text.body,
                        color: Color.white.opacity(0.82),
                        lineSpacing: SharedStyles.captionLineSpacing
                    )
            }
        }
        .padding(20)
        .frame(height: 180)
        .blockSurface(colors: colors, radius: 28)
        .frame(maxWidth: .infinity)
    }
}

// 单次记录卡片
struct SingleRecordCard: View {
    let record: ArcheryRecord
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 12) {
                // 顶部日期和组数信息
                HStack {
                    Text(formatDate(record.date))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                    
                    Spacer()
                    
                    Text(L10n.tr("content_round_summary", 1, record.scores.count))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
                
                // 弓种和靶距信息
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(SharedStyles.Text.caption)
                            .foregroundColor(SharedStyles.primaryColor)
                        Text(record.bowType)
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.3x3")
                            .font(SharedStyles.Text.caption)
                            .foregroundColor(SharedStyles.primaryColor)
                        Text(record.distance)
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "circle.circle")
                            .font(SharedStyles.Text.caption)
                            .foregroundColor(SharedStyles.primaryColor)
                        Text(TargetTypeDisplay.primaryTitle(for: record.targetType))
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                    }
                }
                
                // 分数网格部分
                HStack(spacing: 6) {
                    let scoreWidth = min((geometry.size.width - 100) / 6, 32)
                    
                    ForEach(0..<record.scores.count, id: \.self) { index in
                        Text(record.scores[index])
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryColor)
                            .frame(width: scoreWidth, height: scoreWidth)
                            .background(scoreBackground(for: record.scores[index]))
                            .cornerRadius(6)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // 总分
                    HStack(spacing: 2) {
                        Text("\(record.totalScore)")
                            .sharedTextStyle(SharedStyles.Text.compactValue, color: SharedStyles.primaryColor)
                        Text(L10n.tr("content_points_unit"))
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.primaryColor)
                    }
                    .frame(minWidth: 80, alignment: .trailing)
                }
            }
            .padding(16)
            .clayCard(tint: SharedStyles.primaryColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(SharedStyles.singleRecordOutlineColor.opacity(0.95), lineWidth: 1.4)
                    .padding(1)
            )
        }
        .frame(height: 160)
    }
    
    private func scoreBackground(for score: String) -> Color {
        if score == "X" || score == "10" {
            return SharedStyles.Accent.peach.opacity(0.36)
        } else if score == "9" {
            return SharedStyles.Accent.lemon.opacity(0.30)
        } else if score == "8" {
            return SharedStyles.Accent.sky.opacity(0.24)
        }
        return SharedStyles.groupBackgroundColor
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.persistedLanguageCode())
        formatter.dateFormat = L10n.Format.dateTime
        return formatter.string(from: date)
    }
}

// 组记录卡片
struct GroupRecordCard: View {
    let record: ArcheryGroupRecord
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 12) {
                // 顶部日期和组数信息
                HStack {
                    Text(formatDate(record.date))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                    
                    Spacer()
                    
                    Text(L10n.tr("content_round_summary", record.groupScores.count, record.groupScores.first?.count ?? 0))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
                
                // 弓种和靶距信息
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(SharedStyles.Text.caption)
                            .foregroundColor(SharedStyles.secondaryColor)
                        Text(record.bowType)
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.3x3")
                            .font(SharedStyles.Text.caption)
                            .foregroundColor(SharedStyles.secondaryColor)
                        Text(record.distance)
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "circle.circle")
                            .font(SharedStyles.Text.caption)
                            .foregroundColor(SharedStyles.secondaryColor)
                        Text(TargetTypeDisplay.primaryTitle(for: record.targetType))
                            .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                    }
                }
                
                // 修改分数网格部分
                HStack(spacing: 8) {
                    let availableWidth = geometry.size.width - 120
                    let groupWidth = min(availableWidth / CGFloat(min(5, record.groupScores.count)), 36)
                    
                    ForEach(0..<min(5, record.groupScores.count), id: \.self) { groupIndex in
                        VStack(spacing: 2) {
                            Text(L10n.GroupDetail.groupNumber(groupIndex + 1))
                                .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                            
                            Text("\(calculateGroupScore(for: groupIndex))")
                                .sharedTextStyle(SharedStyles.Text.bodyEmphasis, color: SharedStyles.secondaryColor)
                        }
                        .frame(width: groupWidth)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // 总分
                    HStack(spacing: 2) {
                        Text("\(calculateTotalScore())")
                            .sharedTextStyle(SharedStyles.Text.compactValue, color: SharedStyles.secondaryColor)
                        Text(L10n.tr("content_points_unit"))
                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryColor)
                    }
                    .frame(minWidth: 80, alignment: .trailing)
                }
            }
            .padding()
            .clayCard(tint: SharedStyles.secondaryColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(SharedStyles.groupRecordOutlineColor.opacity(0.95), lineWidth: 1.4)
                    .padding(1)
            )
        }
        .frame(height: 160)
    }
    
    private func calculateTotalScore() -> Int {
        record.groupScores.reduce(0) { sum, group in
            sum + group.reduce(0) { groupSum, score in
                if score == "X" { return groupSum + 10 }
                if score == "M" { return groupSum + 0 }
                return groupSum + (Int(score) ?? 0)
            }
        }
    }
    
    private func calculateGroupScore(for groupIndex: Int) -> Int {
        record.groupScores[groupIndex].reduce(0) { sum, score in
            if score == "X" { return sum + 10 }
            if score == "M" { return sum + 0 }
            return sum + (Int(score) ?? 0)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.persistedLanguageCode())
        formatter.dateFormat = L10n.Format.dateTime
        return formatter.string(from: date)
    }
}

// 预览
struct NewContentView_Previews: PreviewProvider {
    static var previews: some View {
        NewContentView()
            .environmentObject(ArcheryStore())
            .environmentObject(PurchaseManager())
    }
}

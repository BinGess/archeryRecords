import SwiftUI

class TabBarManager: ObservableObject {
    @Published var isVisible = true
    
    func show() {
        DispatchQueue.main.async {
            self.isVisible = true
        }
    }
    
    func hide() {
        DispatchQueue.main.async {
            self.isVisible = false
        }
    }
}

struct NewContentView: View {
    @EnvironmentObject private var archeryStore: ArcheryStore
    @StateObject private var tabBarManager = TabBarManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 记录页面
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 顶部标题和设置按钮
                        HStack {
                            Text("射箭记录本")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            NavigationLink {
                                SettingsView()
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.title2)
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // 快捷操作卡片
                        HStack(spacing: 16) {
                            // 记一组卡片
                            NavigationLink {
                                ScoreInputView()
                            } label: {
                                RecordCard(
                                    title: "记一组",
                                    subtitle: "\(archeryStore.records.count)组记录",
                                    icon: "record_info",
                                    color: .orange
                                )
                            }
                            
                            // 记一场卡片
                            NavigationLink {
                                ScoreGroupInputView()
                            } label: {
                                RecordCard(
                                    title: "记一场",
                                    subtitle: "\(archeryStore.groupRecords.count)组记录",
                                    icon: "record_match",
                                    color: .purple
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // 成绩列表标题
                        Text("成绩列表")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        // 记录列表
                        if archeryStore.records.isEmpty && archeryStore.groupRecords.isEmpty {
                            EmptyStateView()
                        } else {
                            VStack(spacing: -20) {
                                ForEach(getSortedRecords(), id: \.id) { record in
                                    switch record {
                                    case .single(let singleRecord):
                                        NavigationLink(destination: 
                                            ScoreDetailView(recordId: singleRecord.id, recordType: "single")
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
                }
                .background(Color.white)
                .edgesIgnoringSafeArea(.bottom)
            }
            .navigationTitle("射箭记录本")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .tabItem {
                Image(systemName: "list.bullet")
                Text("记录")
            }
            .tag(0)
            
            // 分析页面
            NavigationStack {
                ScoreAnalysisView()
            }
            .tabItem {
                Image(systemName: "chart.xyaxis.line")
                Text("分析")
            }
            .tag(1)
        }
        .accentColor(.orange)
        #if os(iOS)
        .toolbar(tabBarManager.isVisible ? .visible : .hidden, for: .tabBar)
        #endif
        .environmentObject(tabBarManager)
        .onAppear {
            archeryStore.loadRecords()
            tabBarManager.show()
        }
        .onReceive(NotificationCenter.default.publisher(for: .recordsDidChange)) { _ in
            archeryStore.loadRecords()
            tabBarManager.show()
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

// 记录卡片组件
struct RecordCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 图标 - 修改这里以支持自定义图片
            if icon.starts(with: "system:") {
                // 系统图标
                Image(systemName: icon.replacingOccurrences(of: "system:", with: ""))
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .padding(.top, 24)
                    .padding(.leading, 24)
            } else {
                // 自定义图标
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
                    .padding(.top, 24)
                    .padding(.leading, 24)
            }
            
            Spacer()
            
            // 标题和副标题
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.leading, 24)
            .padding(.bottom, 16)
            
            // 箭头按钮 - 放在右下角
            HStack {
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.white.opacity(0.3)))
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
            }
        }
        .frame(height: 180)
        .background(color)
        .cornerRadius(20)
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
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("1组 × 6箭")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 弓种和靶距信息
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(record.bowType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.3x3")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(record.distance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "circle.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(record.targetType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 分数网格部分
                HStack(spacing: 6) {
                    let scoreWidth = min((geometry.size.width - 100) / 6, 32)
                    
                    ForEach(0..<record.scores.count, id: \.self) { index in
                        Text(record.scores[index])
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: scoreWidth, height: scoreWidth)
                            .foregroundColor(.orange)
                            .background(scoreBackground(for: record.scores[index]))
                            .cornerRadius(6)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // 总分
                    HStack(spacing: 2) {
                        Text("\(record.totalScore)")
                            .font(.system(size: 24, weight: .bold))
                        Text("分")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.orange)
                    .frame(minWidth: 80, alignment: .trailing)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange, lineWidth: 2)
                    .opacity(0.5)
                    .padding(1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                   .fill(Color.orange)
                    .frame(width: 6)
                    .padding(.vertical, 8),
                alignment: .leading
            )
        }
        .frame(height: 160)
    }
    
    private func scoreBackground(for score: String) -> Color {
        #if os(iOS)
        let baseColor = Color(UIColor.systemBackground)
        #else
        let baseColor = Color.white
        #endif
        
        if score == "X" || score == "10" {
            return baseColor.opacity(0.8)
        } else if score == "9" {
            return baseColor.opacity(0.8)
        } else if score == "8" {
            return baseColor.opacity(0.8)
        }
        return baseColor.opacity(0.8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
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
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(record.groupScores.count)组 × \(record.groupScores.first?.count ?? 0)箭")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 弓种和靶距信息
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .foregroundColor(.purple)
                        Text(record.bowType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.3x3")
                            .foregroundColor(.purple)
                        Text(record.distance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "circle.circle")
                            .foregroundColor(.purple)
                        Text(record.targetType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 修改分数网格部分
                HStack(spacing: 8) {
                    let availableWidth = geometry.size.width - 120
                    let groupWidth = min(availableWidth / CGFloat(min(5, record.groupScores.count)), 36)
                    
                    ForEach(0..<min(5, record.groupScores.count), id: \.self) { groupIndex in
                        VStack(spacing: 2) {
                            Text("\(groupIndex + 1)组")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("\(calculateGroupScore(for: groupIndex))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.purple)
                        }
                        .frame(width: groupWidth)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // 总分
                    HStack(spacing: 2) {
                        Text("\(calculateTotalScore())")
                            .font(.system(size: 24, weight: .bold))
                        Text("分")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.purple)
                    .frame(minWidth: 80, alignment: .trailing)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple, lineWidth: 2)
                    .opacity(0.5)
                    .padding(1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple)
                    .frame(width: 6)
                    .padding(.vertical, 8),
                alignment: .leading
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
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// 预览
struct NewContentView_Previews: PreviewProvider {
    static var previews: some View {
        NewContentView()
            .environmentObject(ArcheryStore())
    }
}

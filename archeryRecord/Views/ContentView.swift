import SwiftUI

// 主视图，作为应用的根视图
struct MainView: View {
    @StateObject private var archeryStore = ArcheryStore()
    
    
    var body: some View {
        //TabView {
            // 使用 NewContentView 作为默认启动页面
            NewContentView()
                .environmentObject(archeryStore)  // 确保传递环境对象
                //.tabItem {
                  //  Image(systemName: "list.bullet")
                    //Text(L10n.Tab.record)
          //      }
            
            /* 原来的 RecordsListView 代码，注释掉但保留
            NavigationStack {
                RecordsListView()
                    .navigationBarTitle(L10n.Content.appTitle, displayMode: .inline)
                    #if os(iOS)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .navigationBarItems(trailing: 
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                        }
                    )
                    .toolbarBackground(Color.blue, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    #else
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            NavigationLink {
                                SettingsView()
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    #endif
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text(L10n.Tab.record)
            }
            */
            
            // NavigationStack {
            //     ScoreAnalysisView()
            //         .navigationBarTitle(L10n.Tab.analysis, displayMode: .inline)
            //         .toolbarBackground(Color.blue, for: .navigationBar)
            //         .toolbarBackground(.visible, for: .navigationBar)
            // }
            // .tabItem {
            //     Image(systemName: "chart.xyaxis.line")
            //     Text(L10n.Tab.analysis)
            // }
        }
       // .environmentObject(archeryStore)
       //onAppear {
       //     configureAppearance()
       // }
    //}
    
    private func configureAppearance() {
        #if os(iOS)
        // 配置导航栏
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemBlue
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // 配置标签栏
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()  // 确保背景不透明
        tabBarAppearance.backgroundColor = .systemBackground  // 设置白色背景
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        #endif
    }
}

// 记录列表视图
struct RecordsListView: View {
    @EnvironmentObject private var archeryStore: ArcheryStore
    @State private var needsRefresh = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部操作区
                HStack(spacing: 20) {
                    NavigationLink {
                        ScoreInputView()
                    } label: {
                        ActionButton(
                            icon: "square.and.pencil",
                            title: L10n.Nav.record,
                            gradient: [Color.blue, Color.blue.opacity(0.8)]
                        )
                    }
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 1, height: 70)
                    
                    NavigationLink {
                        ScoreGroupInputView()
                    } label: {
                        ActionButton(
                            icon: "doc.on.doc",
                            title: L10n.Nav.groupRecord,
                            gradient: [Color.orange, Color.orange.opacity(0.8)]
                        )
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                .padding(.horizontal)
                .padding(.top, 20)
                
                // 记录列表
                if archeryStore.records.isEmpty && archeryStore.groupRecords.isEmpty {
                    EmptyStateView()
                } else {
                    LazyVStack(spacing: 16) {
                        // 合并并排序所有记录
                        ForEach(getSortedRecords(), id: \.id) { record in
                            switch record {
                            case .single(let singleRecord):
                                NavigationLink {
                                    ScoreDetailView(recordId: singleRecord.id, recordType: "single")
                                } label: {
                                    RecordRow(record: singleRecord)
                                }
                            case .group(let groupRecord):
                                NavigationLink {
                                    ScoreGroupDetailView(recordId: groupRecord.id)
                                } label: {
                                    GroupRecordRow(record: groupRecord)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        #if os(iOS)
        .background(Color(UIColor.systemGroupedBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        .onAppear {
            archeryStore.loadRecords()
        }
        .onReceive(NotificationCenter.default.publisher(for: .recordsDidChange)) { _ in
            archeryStore.loadRecords()
        }
        .refreshable {
            archeryStore.loadRecords()
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

// 空状态视图
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("empty")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(LinearGradient(
                    colors: [.blue, .blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .padding(.bottom, 8)
            
            Text(L10n.Content.emptyStatePrompt)
                .font(.system(size: 16))
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.5))
        .cornerRadius(20)
        .padding(.horizontal, 16)
    }
}

// 记录列表组件
struct RecordsList: View {
    let records: [ArcheryRecord]
    let groupRecords: [ArcheryGroupRecord]
    
    var body: some View {
        List {
            RecordListView(records: records, groupRecords: groupRecords) { id, type in
                // ... existing delete logic ...
            }
        }
        .listStyle(PlainListStyle())
        .padding(.horizontal, 16)
    }
}

struct GroupRecordRow: View {
    let record: ArcheryGroupRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部日期和分数
            HStack {
                Text(formatDate(record.date))
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.8))
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(calculateTotalScore())")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.blue)
                    Text(L10n.Content.score)
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            
            // 信息图标行
            HStack(spacing: 20) {
                InfoItem(icon: "arrow.up.and.down.and.arrow.left.and.right", text: record.bowType)
                InfoItem(icon: "triangle", text: record.distance)
                InfoItem(icon: "square.grid.3x3", text: record.targetType)
            }
            
            // 分数网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(0..<record.groupScores.count, id: \.self) { groupIndex in
                    VStack(spacing: 4) {
                        Text("第\(groupIndex + 1)组")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        ForEach(Array(record.groupScores[groupIndex].enumerated()), id: \.offset) { index, score in
                            Text(score)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 30, height: 30)
                                .background(scoreBackground(for: score))
                                .cornerRadius(6)
                        }
                        
                        Text("\(calculateGroupScore(for: groupIndex))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
    
    private func scoreBackground(for score: String) -> Color {
        if score == "X" || score == "10" {
            return .yellow.opacity(0.15)
        } else if score == "9" {
            return .orange.opacity(0.15)
        } else if score == "8" {
            return .red.opacity(0.15)
        }
        return .gray.opacity(0.1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = L10n.Format.dateTime
        return formatter.string(from: date)
    }
}

struct RecordRow: View {
    let record: ArcheryRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部日期和分数
            HStack {
                Text(formatDate(record.date))
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.8))
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(record.totalScore)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.blue)
                    Text(L10n.Content.score)
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            
            // 信息图标行
            HStack(spacing: 20) {
                InfoItem(icon: "arrow.up.and.down.and.arrow.left.and.right", text: record.bowType)
                InfoItem(icon: "triangle", text: record.distance)
                InfoItem(icon: "square.grid.3x3", text: record.targetType)
            }
            
            // 分数网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(0..<6) { index in
                    Text(record.scores[index])
                        .font(.system(size: 16, weight: .medium))
                        .frame(height: 36)
                        .frame(maxWidth: .infinity)
                        .background(scoreBackground(for: record.scores[index]))
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func scoreBackground(for score: String) -> Color {
        if score == "X" || score == "10" {
            return .yellow.opacity(0.15)
        } else if score == "9" {
            return .orange.opacity(0.15)
        } else if score == "8" {
            return .red.opacity(0.15)
        }
        return .gray.opacity(0.1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = L10n.Format.dateTime
        return formatter.string(from: date)
    }
}

struct InfoItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.blue.opacity(0.7))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.7))
        }
    }
}

struct RecordListView: View {
    @Environment(\.dismiss) private var dismiss
    let records: [ArcheryRecord]
    let groupRecords: [ArcheryGroupRecord]
    let onDelete: (UUID, String) -> Void
    
    var body: some View {
        let sortedRecords = getSortedRecords()
        
        ForEach(sortedRecords, id: \.id) { record in
            ZStack {
                record.view
                
                if record.type == "single" {
                    NavigationLink(
                        destination: ScoreDetailView(recordId: record.id, recordType: "single")
                    ) {
                        EmptyView()
                    }
                    .opacity(0)
                } else {
                    NavigationLink(
                        destination: ScoreGroupDetailView(recordId: record.id)
                    ) {
                        EmptyView()
                    }
                    .opacity(0)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    onDelete(record.id, record.type)
                } label: {
                    Label(L10n.Content.delete, systemImage: "trash.fill")
                }
                .tint(.red)
            }
        }
    }
    
    private func getSortedRecords() -> [(date: Date, view: AnyView, type: String, id: UUID)] {
        let singleRecords = records.map { record -> (date: Date, view: AnyView, type: String, id: UUID) in
            (record.date, AnyView(RecordRow(record: record)), "single", record.id)
        }
        
        let groupRecords = groupRecords.map { record -> (date: Date, view: AnyView, type: String, id: UUID) in
            (record.date, AnyView(GroupRecordRow(record: record)), "group", record.id)
        }
        
        return (singleRecords + groupRecords).sorted(by: { $0.date > $1.date })
    }
}

// 操作按钮组件
struct ActionButton: View {
    let icon: String
    let title: String
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

// 移除不必要的包装视图


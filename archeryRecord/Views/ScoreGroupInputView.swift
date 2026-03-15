import SwiftUI
import Foundation

enum InputMode {
    case keyboard
    case visualTarget
}

struct ScoreGroupInputView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var archeryStore: ArcheryStore
    
    // 编辑模式相关
    private let editingRecord: ArcheryGroupRecord?
    
    // 基本信息
    @State private var selectedBowType: String
    @State private var selectedDistance: String
    @State private var selectedTarget: String
    
    init() {
        self.editingRecord = nil
        let lastOptions = ArcheryStore().getLastUsedOptions()
        _selectedBowType = State(initialValue: lastOptions.bowType)
        _selectedDistance = State(initialValue: lastOptions.distance)
        _selectedTarget = State(initialValue: lastOptions.targetType)
    }
    
    init(editingRecord: ArcheryGroupRecord) {
        self.editingRecord = editingRecord
        _selectedBowType = State(initialValue: editingRecord.bowType)
        _selectedDistance = State(initialValue: editingRecord.distance)
        _selectedTarget = State(initialValue: editingRecord.targetType)
        
        // 设置组数和每组箭数
        _numberOfGroups = State(initialValue: editingRecord.numberOfGroups)
        _arrowsPerGroup = State(initialValue: editingRecord.arrowsPerGroup)
        
        // 初始化成绩数据
        _groupScores = State(initialValue: editingRecord.groupScores)
        _groupArrowHits = State(initialValue: editingRecord.groupArrowHits ?? [])
    }
    
    @State private var numberOfGroups = 3
    @State private var arrowsPerGroup = 3
    
    // 成绩录入
    @State private var groupScores: [[String]] = []
    @State private var selectedGroupIndex = 0
    @State private var selectedScoreIndex = 0
    @State private var inputMode: InputMode = .keyboard
    @State private var groupArrowHits: [[ArrowHit]] = []
    
    // 选项面板
    @State private var showingBowTypeSheet = false
    @State private var showingDistanceSheet = false
    @State private var showingTargetSheet = false
    @State private var showingMatchTypeSheet = false
    
    var totalArrows: Int {
        numberOfGroups * arrowsPerGroup
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 主内容区域 - 可滚动
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // 基本选项卡片
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("基本选项")
                                    .font(.headline)
                                Spacer()
                                
                                // 输入模式切换开关
                                HStack(spacing: 8) {
                                    Image(systemName: inputMode == .keyboard ? "keyboard" : "target")
                                        .font(.system(size: 14))
                                        .foregroundColor(.purple)
                                    
                                    Toggle("", isOn: Binding(
                                        get: { inputMode == .visualTarget },
                                        set: { newValue in
                                            inputMode = newValue ? .visualTarget : .keyboard
                                        }
                                    ))
                                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                                    .scaleEffect(0.8)
                                    
                                    Text(inputMode == .visualTarget ? "靶面" : "键盘")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                            
                            // 选项网格
                            VStack(spacing: 0) {
                                // 第一行
                                HStack(spacing: 0) {
                                    // 弓种类型按钮
                                    Button(action: { showingBowTypeSheet = true }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                                .font(.system(size: 24))
                                                .foregroundColor(.purple)
                                            Text(selectedBowType)
                                                .font(.system(size: 14))
                                                .foregroundColor(.black)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                    }
                                    
                                    Divider()
                                        .frame(width: 1, height: 40)
                                        .background(Color.gray.opacity(0.2))
                                    
                                    // 距离按钮
                                    Button(action: { showingDistanceSheet = true }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "triangle")
                                                .font(.system(size: 24))
                                                .foregroundColor(.purple)
                                            Text(selectedDistance)
                                                .font(.system(size: 14))
                                                .foregroundColor(.black)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                    }
                                }
                                
                                Divider()
                                    .frame(height: 1)
                                    .background(Color.gray.opacity(0.2))
                                
                                // 第二行
                                HStack(spacing: 0) {
                                    // 靶型按钮
                                    Button(action: { showingTargetSheet = true }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "target")
                                                .font(.system(size: 24))
                                                .foregroundColor(.purple)
                                            Text(selectedTarget)
                                                .font(.system(size: 14))
                                                .foregroundColor(.black)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                    }
                                    
                                    Divider()
                                        .frame(width: 1, height: 40)
                                        .background(Color.gray.opacity(0.2))
                                    
                                    // 比赛类型按钮
                                    Button(action: { showingMatchTypeSheet = true }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "target")
                                                .font(.system(size: 24))
                                                .foregroundColor(.purple)
                                            Text("\(numberOfGroups)组/每组\(arrowsPerGroup)支/共\(totalArrows)箭")
                                                .font(.system(size: 14))
                                                .foregroundColor(.black)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                    }
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        
                        // 成绩录入卡片 - 为每个组创建一个卡片
                        ForEach(0..<groupScores.count, id: \.self) { groupIndex in
                            GroupScoreCard(
                                groupIndex: groupIndex,
                                groupScores: groupScores[groupIndex],
                                selectedGroupIndex: $selectedGroupIndex,
                                selectedScoreIndex: $selectedScoreIndex,
                                inputMode: .keyboard, // 强制使用键盘模式，不显示靶面
                                targetFaceType: getTargetFaceType(from: selectedTarget),
                                groupArrowHits: $groupArrowHits[groupIndex],
                                onScoreSelected: { scoreIndex in
                                    selectedGroupIndex = groupIndex
                                    selectedScoreIndex = scoreIndex
                                },
                                onVisualTargetInput: { groupIdx, arrowIdx, hit in
                                    handleVisualTargetInput(groupIndex: groupIdx, arrowIndex: arrowIdx, hit: hit)
                                },
                                onAddGroup: addNewGroup,
                                isLastGroup: groupIndex == groupScores.count - 1
                            )
                            .id("group_\(groupIndex)")
                        }
                        

                    }
                    .padding(.vertical, 16)
                }
                .onChange(of: selectedGroupIndex) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("group_\(newValue)", anchor: .top)
                    }
                }
                .onChange(of: selectedScoreIndex) { _, newValue in
                    let currentGroup = selectedGroupIndex
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("group_\(currentGroup)", anchor: .top)
                        }
                    }
                }
            }
            .background(SharedStyles.groupBackgroundColor)
            
            // 底部输入区域 - 固定在底部
            if inputMode == .keyboard {
                bottomKeyboardView
            } else {
                // 靶面输入区域 - 固定在底部
                bottomTargetInputView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("记一场")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text(L10n.Common.back)
                    }
                    .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            // 只有在非编辑模式下才初始化空的分数数组
            if editingRecord == nil {
                initializeGroupScores()
            }
        }
        .sheet(isPresented: $showingBowTypeSheet) {
            SelectionSheet(title: L10n.GroupInput.selectBowType,
                         options: L10n.Options.BowType.all,
                         selectedOption: $selectedBowType,
                         isFromScoreInput: false)
        }
        .sheet(isPresented: $showingMatchTypeSheet) {
            NavigationView {
                Form {
                    Section(header: Text("预设比赛类型")) {
                        Button("室内18米（10组/每组3支）") {
                            numberOfGroups = 10
                            arrowsPerGroup = 3
                            showingMatchTypeSheet = false
                        }
                        
                        Button("室外70米（12组/每组6支）") {
                            numberOfGroups = 12
                            arrowsPerGroup = 6
                            showingMatchTypeSheet = false
                        }
                        
                        Button("室内25米（12组/每组3支）") {
                            numberOfGroups = 12
                            arrowsPerGroup = 3
                            showingMatchTypeSheet = false
                        }
                    }
                    
                    Section(header: Text("自定义设置")) {
                        Stepper(value: $numberOfGroups, in: 1...30) {
                            HStack {
                                Text("组数")
                                Spacer()
                                Text("\(numberOfGroups)组")
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        Stepper(value: $arrowsPerGroup, in: 1...12) {
                            HStack {
                                Text("每组箭数")
                                Spacer()
                                Text("\(arrowsPerGroup)支")
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        Text("总计: \(totalArrows)支箭")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("比赛类型设置")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            showingMatchTypeSheet = false
                            // 重新初始化分数数组以匹配新的组数和箭数
                            // 在编辑模式下不要重新初始化，保持原有数据
                            if editingRecord == nil {
                                initializeGroupScores()
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingDistanceSheet) {
            SelectionSheet(title: L10n.GroupInput.selectDistance,
                         options: L10n.Options.Distance.all,
                         selectedOption: $selectedDistance,
                         isFromScoreInput: false)
        }
        .sheet(isPresented: $showingTargetSheet) {
            SelectionSheet(title: L10n.GroupInput.selectTargetType,
                         options: L10n.Options.TargetType.all,
                         selectedOption: $selectedTarget,
                         isFromScoreInput: false)
        }
    }
    
    private func handleVisualTargetInput(groupIndex: Int, arrowIndex: Int, hit: ArrowHit) {
        // 确保索引有效
        guard groupIndex < groupScores.count && arrowIndex < groupScores[groupIndex].count else {
            return
        }
        
        // 更新分数
        // X环是ringNumber为11的环，外10环是ringNumber为10的环
        let scoreString = hit.score == 10 && hit.ringNumber == 11 ? "X" : "\(hit.score)"
        groupScores[groupIndex][arrowIndex] = scoreString
        
        // 更新箭着点数据
        if groupIndex < groupArrowHits.count {
            // 检查是否已存在该箭的记录
            if let existingIndex = groupArrowHits[groupIndex].firstIndex(where: { $0.arrowIndex == arrowIndex }) {
                groupArrowHits[groupIndex][existingIndex] = hit
            } else {
                groupArrowHits[groupIndex].append(hit)
            }
        }
    }
    
    private func getTargetFaceType(from targetString: String) -> TargetFaceType {
        switch targetString {
        case L10n.Options.TargetType.t122cmStandard:
            return .standard122cm
        case L10n.Options.TargetType.t80cmFull:
            return .full80cm
        case L10n.Options.TargetType.t40cmFull:
            return .full40cm
        case L10n.Options.TargetType.t40cmTripleVertical:
            return .triple40cmVertical
        case L10n.Options.TargetType.t40cmTripleTriangle:
            return .triple40cmTriangle
        case L10n.Options.TargetType.t60cmIndoor:
            return .indoor60cm
        case L10n.Options.TargetType.tCompoundInner10:
            return .compoundInner10
        default:
            return .standard122cm
        }
    }

    private var bottomTargetInputView: some View {
        VStack(spacing: 0) {
            // 靶面输入区域
            if selectedGroupIndex < groupArrowHits.count {
                VisualTargetInputView(
                    targetFaceType: getTargetFaceType(from: selectedTarget),
                    selectedScoreIndex: selectedScoreIndex,
                    groupIndex: selectedGroupIndex,
                    groupArrowHits: $groupArrowHits[selectedGroupIndex],
                    onVisualTargetInput: { groupIdx, arrowIdx, hit in
                        handleVisualTargetInput(groupIndex: groupIdx, arrowIndex: arrowIdx, hit: hit)
                        // 自动移动到下一个输入位置
                        moveToNextInput()
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            
            // 底部按钮区域
            HStack(spacing: 12) {
                Button(action: handleScoreDelete) {
                    Text("移除成绩")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.purple, lineWidth: 1)
                )
                
                Button(action: saveRecord) {
                    Text("完成成绩")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .background(Color.purple)
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -3)
    }
    
    private var bottomKeyboardView: some View {
        HStack(spacing: 8) {
                // 左侧数字键盘
                VStack(spacing: 6) {
                    // 第一行按钮
                    HStack(spacing: 6) {
                        GroupCircleScoreButton(score: "X", onTap: { handleScoreInput("X") })
                        GroupCircleScoreButton(score: "10", onTap: { handleScoreInput("10") })
                        GroupCircleScoreButton(score: "9", onTap: { handleScoreInput("9") })
                        GroupCircleScoreButton(score: "8", onTap: { handleScoreInput("8") })
                    }
                    
                    // 第二行按钮
                    HStack(spacing: 6) {
                        GroupCircleScoreButton(score: "7", onTap: { handleScoreInput("7") })
                        GroupCircleScoreButton(score: "6", onTap: { handleScoreInput("6") })
                        GroupCircleScoreButton(score: "5", onTap: { handleScoreInput("5") })
                        GroupCircleScoreButton(score: "4", onTap: { handleScoreInput("4") })
                    }
                    
                    // 第三行按钮
                    HStack(spacing: 6) {
                        GroupCircleScoreButton(score: "3", onTap: { handleScoreInput("3") })
                        GroupCircleScoreButton(score: "2", onTap: { handleScoreInput("2") })
                        GroupCircleScoreButton(score: "1", onTap: { handleScoreInput("1") })
                        GroupCircleScoreButton(score: "M", isSpecial: true, onTap: { handleScoreInput("M") })
                    }
                }
                .frame(maxWidth: .infinity)
                
                // 右侧操作按钮
                VStack(spacing: 6) {
                    Button(action: handleScoreDelete) {
                        Text("移除")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: 68, height: 72)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.purple, lineWidth: 1)
                    )
                    
                    Button(action: saveRecord) {
                        Text("保存")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: 68, height: 72)
                    .background(Color.purple)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -3)
    }
    
    private func handleScoreInput(_ score: String) {
        if selectedGroupIndex < groupScores.count && selectedScoreIndex < groupScores[selectedGroupIndex].count {
            groupScores[selectedGroupIndex][selectedScoreIndex] = score
            
            // 使用统一的移动逻辑
            moveToNextInput()
        }
    }
    
    private func handleScoreDelete() {
        if selectedGroupIndex < groupScores.count && selectedScoreIndex < groupScores[selectedGroupIndex].count {
            groupScores[selectedGroupIndex][selectedScoreIndex] = ""
            
            // 自动移动到上一个输入框
            if selectedScoreIndex > 0 {
                selectedScoreIndex -= 1
            } else if selectedGroupIndex > 0 {
                selectedGroupIndex -= 1
                selectedScoreIndex = groupScores[selectedGroupIndex].count - 1
            }
        }
    }
    
    private func saveRecord() {
        if let editingRecord = editingRecord {
            // 编辑模式：更新现有记录
            let updatedRecord = ArcheryGroupRecord(
                id: editingRecord.id, // 保持原有ID
                bowType: selectedBowType,
                distance: selectedDistance,
                targetType: selectedTarget,
                groupScores: groupScores,
                date: editingRecord.date, // 保持原有日期
                numberOfGroups: numberOfGroups,
                arrowsPerGroup: arrowsPerGroup,
                groupArrowHits: groupArrowHits
            )
            
            // 更新记录
            archeryStore.updateGroupRecord(updatedRecord)
        } else {
            // 新建模式：创建新记录
            let record = ArcheryGroupRecord(
                id: UUID(),
                bowType: selectedBowType,
                distance: selectedDistance,
                targetType: selectedTarget,
                groupScores: groupScores,
                date: Date(),
                numberOfGroups: numberOfGroups,
                arrowsPerGroup: arrowsPerGroup,
                groupArrowHits: groupArrowHits
            )
            
            // 保存记录
            archeryStore.addGroupRecord(record)
        }
        
        // 保存最后使用的选项
        archeryStore.saveLastUsedOptions(
            bowType: selectedBowType,
            distance: selectedDistance,
            targetType: selectedTarget
        )
        
        // 返回上一级
        dismiss()
    }
    
    private func initializeGroupScores() {
        // 如果是编辑模式，完全不要重新初始化
        if editingRecord != nil {
            return
        }
        
        // 保存现有的分数
        let existingScores = groupScores
        let existingArrowHits = groupArrowHits
        
        // 创建新的分数数组
        groupScores = Array(repeating: Array(repeating: "", count: arrowsPerGroup), count: numberOfGroups)
        groupArrowHits = Array(repeating: [], count: numberOfGroups)
        
        // 复制现有的分数到新数组（如果可能）
        for i in 0..<min(existingScores.count, groupScores.count) {
            for j in 0..<min(existingScores[i].count, groupScores[i].count) {
                groupScores[i][j] = existingScores[i][j]
            }
        }
        
        // 复制现有的箭支命中数据到新数组（如果可能）
        for i in 0..<min(existingArrowHits.count, groupArrowHits.count) {
            groupArrowHits[i] = existingArrowHits[i]
        }
    }
    
    private func addNewGroup() {
        let newGroupScores = Array(repeating: "", count: arrowsPerGroup)
        groupScores.append(newGroupScores)
        groupArrowHits.append([])
        
        // 更新组数，确保moveToNextInput函数能正确判断
        numberOfGroups = groupScores.count
        
        // 自动选择新组的第一个位置
        selectedGroupIndex = groupScores.count - 1
        selectedScoreIndex = 0
        
        // 如果当前是可视化输入模式，保持在可视化模式
        if inputMode == .visualTarget {
            // 可以在这里添加一些特定的逻辑
        }
    }
    
    private func moveToNextInput() {
        // 移动到下一个输入位置
        if selectedScoreIndex < arrowsPerGroup - 1 {
            // 当前组还有空位，移动到下一支箭
            selectedScoreIndex += 1
        } else if selectedGroupIndex < numberOfGroups - 1 {
            // 当前组已满，移动到下一组的第一支箭
            selectedGroupIndex += 1
            selectedScoreIndex = 0
        }
        // 如果已经是最后一组的最后一支箭，保持当前位置
    }

// 组分数卡片
struct GroupScoreCard: View {
    let groupIndex: Int
    let groupScores: [String]
    @Binding var selectedGroupIndex: Int
    @Binding var selectedScoreIndex: Int
    let inputMode: InputMode
    let targetFaceType: TargetFaceType
    @Binding var groupArrowHits: [ArrowHit]
    let onScoreSelected: (Int) -> Void
    let onVisualTargetInput: (Int, Int, ArrowHit) -> Void
    let onAddGroup: () -> Void
    let isLastGroup: Bool  // 新增属性，标识是否为最后一组
    
    var groupScore: Int {
        groupScores.reduce(0) { sum, score in
            if score == "X" { return sum + 10 }
            if score == "M" { return sum + 0 }
            return sum + (Int(score) ?? 0)
        }
    }

    var body: some View {
        GroupScoreCardContent(
            groupIndex: groupIndex,
            groupScores: groupScores,
            selectedGroupIndex: $selectedGroupIndex,
            selectedScoreIndex: $selectedScoreIndex,
            inputMode: inputMode,
            targetFaceType: targetFaceType,
            groupArrowHits: $groupArrowHits,
            onScoreSelected: onScoreSelected,
            onVisualTargetInput: onVisualTargetInput,
            onAddGroup: onAddGroup,
            isLastGroup: isLastGroup,
            groupScore: groupScore
        )
    }
}

// 组圆角矩形分数按钮
struct GroupCircleScoreButton: View {
    let score: String
    let isSpecial: Bool
    let onTap: () -> Void
    
    init(score: String, isSpecial: Bool = false, onTap: @escaping () -> Void) {
        self.score = score
        self.isSpecial = isSpecial
        self.onTap = onTap
    }
    
    // 判断是否为高分按钮（X、10、9）
    private var isHighScore: Bool {
        return score == "X" || score == "10" || score == "9"
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(score)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSpecial ? .white : .black)
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSpecial ? Color.red : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSpecial ? Color.red : (isHighScore ? Color.purple : Color.black), lineWidth: 1)
        )
    }
    }
}

#Preview {
    NavigationStack {
        ScoreGroupInputView()
            .environmentObject(ArcheryStore())
    }
}

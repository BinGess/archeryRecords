import SwiftUI
import Foundation

enum InputMode {
    case keyboard
    case visualTarget
}

struct ScoreGroupInputView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.revealAppTabBar) private var revealAppTabBar
    @EnvironmentObject private var archeryStore: ArcheryStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
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

    init(
        prefillBowType bowType: String,
        distance: String,
        targetType: String,
        numberOfGroups: Int,
        arrowsPerGroup: Int
    ) {
        self.editingRecord = nil
        _selectedBowType = State(initialValue: bowType)
        _selectedDistance = State(initialValue: distance)
        _selectedTarget = State(initialValue: targetType)
        _numberOfGroups = State(initialValue: numberOfGroups)
        _arrowsPerGroup = State(initialValue: arrowsPerGroup)
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
    @State private var completedRecord: ArcheryGroupRecord?
    
    // 选项面板
    @State private var showingBowTypeSheet = false
    @State private var showingDistanceSheet = false
    @State private var showingTargetSheet = false
    @State private var showingMatchTypeSheet = false
    @State private var activePaywallFeature: ProFeature?
    
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
                                Text(L10n.GroupInput.basicOptions)
                                    .font(.headline)
                                Spacer()
                                
                                inputModeToggle
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
                                                .foregroundColor(SharedStyles.secondaryColor)
                                            Text(selectedBowType)
                                                .font(SharedStyles.Text.caption)
                                                .foregroundColor(SharedStyles.primaryTextColor)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                    }
                                    
                                    Divider()
                                        .frame(width: 1, height: 40)
                                        .background(SharedStyles.tertiaryTextColor.opacity(0.18))
                                    
                                    // 距离按钮
                                    Button(action: { showingDistanceSheet = true }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "triangle")
                                                .font(.system(size: 24))
                                                .foregroundColor(SharedStyles.secondaryColor)
                                            Text(selectedDistance)
                                                .font(SharedStyles.Text.caption)
                                                .foregroundColor(SharedStyles.primaryTextColor)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                    }
                                }
                                
                                Divider()
                                    .frame(height: 1)
                                    .background(SharedStyles.tertiaryTextColor.opacity(0.18))
                                
                                // 第二行
                                HStack(spacing: 0) {
                                    // 靶型按钮
                                    Button(action: { showingTargetSheet = true }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "target")
                                                .font(.system(size: 24))
                                                .foregroundColor(SharedStyles.secondaryColor)
                                            Text(TargetTypeDisplay.primaryTitle(for: selectedTarget))
                                                .font(SharedStyles.Text.caption)
                                                .foregroundColor(SharedStyles.primaryTextColor)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                    }
                                    
                                    Divider()
                                        .frame(width: 1, height: 40)
                                        .background(SharedStyles.tertiaryTextColor.opacity(0.18))
                                    
                                    // 比赛类型按钮
                                    Button(action: { showingMatchTypeSheet = true }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "target")
                                                .font(.system(size: 24))
                                                .foregroundColor(SharedStyles.secondaryColor)
                                            Text(L10n.Match.type(groups: numberOfGroups, arrowsPerGroup: arrowsPerGroup, totalArrows: totalArrows))
                                                .font(SharedStyles.Text.caption)
                                                .foregroundColor(SharedStyles.primaryTextColor)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                    }
                                }
                            }
                        }
                        .clayCard(tint: SharedStyles.secondaryColor)
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
            .vibrantCanvasBackground()
            
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
        .toolbarBackground(SharedStyles.backgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(L10n.Nav.groupRecord)
                    .font(SharedStyles.Text.title)
                    .foregroundColor(SharedStyles.primaryTextColor)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    revealAppTabBar?()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text(L10n.Common.back)
                    }
                    .foregroundColor(SharedStyles.primaryTextColor)
                }
            }
        }
        .hiddenAppTabBar()
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
                    Section(header: Text(L10n.tr("group_input_preset_section_title"))) {
                        Button(L10n.tr("group_input_preset_indoor_18m")) {
                            numberOfGroups = 10
                            arrowsPerGroup = 3
                            showingMatchTypeSheet = false
                        }
                        
                        Button(L10n.tr("group_input_preset_outdoor_70m")) {
                            numberOfGroups = 12
                            arrowsPerGroup = 6
                            showingMatchTypeSheet = false
                        }
                        
                        Button(L10n.tr("group_input_preset_indoor_25m")) {
                            numberOfGroups = 12
                            arrowsPerGroup = 3
                            showingMatchTypeSheet = false
                        }
                    }
                    
                    Section(header: Text(L10n.tr("group_input_custom_section_title"))) {
                        Stepper(value: $numberOfGroups, in: 1...30) {
                            HStack {
                                Text(L10n.GroupInput.numberOfGroups)
                                Spacer()
                                Text(L10n.tr("group_input_number_of_groups_value", numberOfGroups))
                                    .foregroundColor(SharedStyles.secondaryColor)
                            }
                        }
                        
                        Stepper(value: $arrowsPerGroup, in: 1...12) {
                            HStack {
                                Text(L10n.GroupInput.arrowsPerGroup)
                                Spacer()
                                Text(L10n.tr("group_input_arrows_per_group_value", arrowsPerGroup))
                                    .foregroundColor(SharedStyles.secondaryColor)
                            }
                        }
                        
                        Text(L10n.tr("group_input_total_arrows", totalArrows))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle(L10n.tr("group_input_match_settings_title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(L10n.Common.done) {
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
        .sheet(item: $activePaywallFeature) { feature in
            ProPaywallView {
                inputMode = .visualTarget
            }
            .environmentObject(purchaseManager)
        }
        .navigationDestination(item: $completedRecord) { record in
            GroupRecordCompletionView(
                record: record,
                onDone: closeInputFlow
            )
            .environmentObject(archeryStore)
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

    private func handleVisualModeToggleChange(_ enabled: Bool) {
        if enabled && !purchaseManager.isProUnlocked {
            activePaywallFeature = .visualTargetInput
            return
        }

        inputMode = enabled ? .visualTarget : .keyboard
    }

    private var inputModeToggle: some View {
        HStack(spacing: 4) {
            inputModeButton(
                title: L10n.CommonAction.visualTarget,
                systemImage: "target",
                isActive: inputMode == .visualTarget,
                showsProBadge: !purchaseManager.isProUnlocked
            ) {
                handleVisualModeToggleChange(true)
            }

            inputModeButton(
                title: L10n.CommonAction.keyboard,
                systemImage: "keyboard",
                isActive: inputMode == .keyboard,
                showsProBadge: false
            ) {
                inputMode = .keyboard
            }
        }
        .padding(4)
        .background(TargetInputPalette.track)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.65), lineWidth: 1)
        )
    }

    private func inputModeButton(
        title: String,
        systemImage: String,
        isActive: Bool,
        showsProBadge: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)

                if showsProBadge {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color(red: 0.92, green: 0.72, blue: 0.12))
                }
            }
            .foregroundColor(isActive ? TargetInputPalette.primary : .secondary)
            .frame(minWidth: showsProBadge ? 82 : 70)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isActive ? SharedStyles.elevatedSurfaceColor : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .shadow(color: isActive ? SharedStyles.Shadow.light : .clear, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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
                    Text(L10n.tr("group_input_remove_score"))
                        .font(SharedStyles.Text.bodyEmphasis)
                        .foregroundColor(SharedStyles.secondaryTextColor)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .clayCard(tint: SharedStyles.Accent.sky, radius: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(SharedStyles.secondaryColor.opacity(0.55), lineWidth: 1)
                )
                
                Button(action: saveRecord) {
                    Text(L10n.tr("group_input_complete_score"))
                        .font(SharedStyles.Text.bodyEmphasis)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .blockSurface(colors: SharedStyles.GradientSet.violet, radius: 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .clayCard(tint: SharedStyles.secondaryColor, radius: 24)
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
                    Text(L10n.CommonAction.remove)
                        .font(SharedStyles.Text.bodyEmphasis)
                        .foregroundColor(SharedStyles.secondaryTextColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 68, height: 72)
                .clayCard(tint: SharedStyles.Accent.sky, radius: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(SharedStyles.secondaryColor.opacity(0.55), lineWidth: 1)
                )
                
                Button(action: saveRecord) {
                    Text(L10n.Common.save)
                        .font(SharedStyles.Text.bodyEmphasis)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 68, height: 72)
                .blockSurface(colors: SharedStyles.GradientSet.violet, radius: 16)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .clayCard(tint: SharedStyles.secondaryColor, radius: 24)
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
            archeryStore.saveLastUsedOptions(
                bowType: selectedBowType,
                distance: selectedDistance,
                targetType: selectedTarget
            )
            closeInputFlow()
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
            archeryStore.saveLastUsedOptions(
                bowType: selectedBowType,
                distance: selectedDistance,
                targetType: selectedTarget
            )
            completedRecord = record
        }

    }

    private func closeInputFlow() {
        completedRecord = nil
        revealAppTabBar?()
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
                    .font(SharedStyles.Text.bodyEmphasis)
                    .foregroundColor(isSpecial ? .white : SharedStyles.primaryTextColor)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSpecial ? SharedStyles.Accent.coral : SharedStyles.elevatedSurfaceColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSpecial ? SharedStyles.Accent.coral : (isHighScore ? SharedStyles.secondaryColor : SharedStyles.primaryTextColor.opacity(0.28)),
                        lineWidth: 1
                    )
            )
            .shadow(color: SharedStyles.Shadow.highlight, radius: 8, x: -3, y: -3)
            .shadow(color: SharedStyles.Shadow.light, radius: 10, x: 5, y: 6)
        }
    }
    
    #Preview {
        NavigationStack {
            ScoreGroupInputView()
                .environmentObject(ArcheryStore())
                .environmentObject(PurchaseManager())
                .environmentObject(TabBarManager())
        }
    }
}

private enum TargetInputPalette {
    static let primary = SharedStyles.Accent.teal
    static let track = Color.white.opacity(0.52)
    static let border = SharedStyles.tertiaryTextColor.opacity(0.18)
    static let text = SharedStyles.primaryTextColor
    static let mutedText = SharedStyles.secondaryTextColor
    static let paper = SharedStyles.elevatedSurfaceColor
    static let gold = SharedStyles.Accent.lemon
    static let red = SharedStyles.Accent.coral
    static let blue = SharedStyles.Accent.sky
    static let black = SharedStyles.primaryTextColor
}

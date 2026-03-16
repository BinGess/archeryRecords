import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import Foundation

struct ScoreInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.revealAppTabBar) private var revealAppTabBar
    @EnvironmentObject private var archeryStore: ArcheryStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
    // 编辑模式相关
    private let editingRecord: ArcheryRecord?
    
    // 基本信息状态
    @State private var selectedBowType: String
    @State private var selectedDistance: String
    @State private var selectedTarget: String
    
    init() {
        self.editingRecord = nil
        _selectedBowType = State(initialValue: L10n.Options.BowType.recurve)
        _selectedDistance = State(initialValue: L10n.Options.Distance.d18m)
        _selectedTarget = State(initialValue: L10n.Options.TargetType.t122cmStandard)
    }

    init(prefillBowType bowType: String, distance: String, targetType: String) {
        self.editingRecord = nil
        _selectedBowType = State(initialValue: bowType)
        _selectedDistance = State(initialValue: distance)
        _selectedTarget = State(initialValue: targetType)
    }
    
    init(editingRecord: ArcheryRecord) {
        self.editingRecord = editingRecord
        _selectedBowType = State(initialValue: editingRecord.bowType)
        _selectedDistance = State(initialValue: editingRecord.distance)
        _selectedTarget = State(initialValue: editingRecord.targetType)
        
        // 初始化成绩数据
        // 确保数组长度为6
        var initialScores = Array(repeating: "", count: 6)
        for i in 0..<min(editingRecord.scores.count, 6) {
            initialScores[i] = editingRecord.scores[i]
        }
        
        _scores = State(initialValue: initialScores)
        _arrowHits = State(initialValue: [])
    }
    
    // 成绩录入状态
    @State private var scores = Array(repeating: "", count: 6)
    @State private var selectedScoreIndex = 0
    @State private var inputMode: InputMode = .keyboard
    @State private var arrowHits: [ArrowHit] = []
    @State private var completedRecord: ArcheryRecord?
    @State private var activePaywallFeature: ProFeature?
    
    enum InputMode {
        case keyboard
        case visualTarget
    }
    
    // Sheet状态
    private enum ActiveSheet: Identifiable {
        case bowType, distance, target
        
        var id: Int {
            switch self {
            case .bowType: return 0
            case .distance: return 1
            case .target: return 2
            }
        }
    }
    
    @State private var activeSheet: ActiveSheet?
    
    var totalScore: Int {
        scores.reduce(0) { sum, score in
            if score == "X" { return sum + 10 }
            if score == "M" { return sum + 0 }
            return sum + (Int(score) ?? 0)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            mainContentView
            if inputMode == .keyboard {
                bottomKeyboardView
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(L10n.Nav.record)
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
        #if os(iOS)
        .toolbarBackground(SharedStyles.backgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        #endif
        #else
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(L10n.Nav.record)
                    .font(SharedStyles.Text.title)
                    .foregroundColor(SharedStyles.primaryTextColor)
            }
            ToolbarItem(placement: .automatic) {
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
        #endif
        .hiddenAppTabBar()
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .bowType:
                SelectionSheet(
                    title: L10n.SingleInput.selectBowType,
                    options: L10n.Options.BowType.all,
                    selectedOption: $selectedBowType,
                    isFromScoreInput: true
                )
            case .distance:
                SelectionSheet(
                    title: L10n.SingleInput.selectDistance,
                    options: L10n.Options.Distance.all,
                    selectedOption: $selectedDistance,
                    isFromScoreInput: true
                )
            case .target:
                SelectionSheet(
                    title: L10n.SingleInput.selectTargetType,
                    options: L10n.Options.TargetType.all,
                    selectedOption: $selectedTarget,
                    isFromScoreInput: true
                )
            }
        }
        .sheet(item: $activePaywallFeature) { feature in
            ProPaywallView {
                inputMode = .visualTarget
            }
            .environmentObject(purchaseManager)
        }
        .navigationDestination(item: $completedRecord) { record in
            SingleRecordCompletionView(
                record: record,
                onDone: closeInputFlow
            )
            .environmentObject(archeryStore)
        }
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                basicOptionsCard
                scoreInputCard
            }
            .padding(.vertical, 16)
        }
        .vibrantCanvasBackground()
    }
    
    private var basicOptionsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L10n.SingleInput.basicOptions)
                    .font(SharedStyles.Text.title)
                Spacer()
                inputModeToggle
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            HStack(spacing: 0) {
                bowTypeButton
                Divider()
                    .frame(width: 1, height: 40)
                    .background(SharedStyles.tertiaryTextColor.opacity(0.18))
                distanceButton
                Divider()
                    .frame(width: 1, height: 40)
                    .background(SharedStyles.tertiaryTextColor.opacity(0.18))
                targetButton
            }
        }
        .clayCard(tint: SharedStyles.primaryColor)
        .padding(.horizontal, 16)
    }
    
    private var bowTypeButton: some View {
        Button(action: { activeSheet = .bowType }) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                    .font(.system(size: 24))
                    .foregroundColor(SharedStyles.primaryColor)
                Text(selectedBowType)
                    .font(SharedStyles.Text.caption)
                    .foregroundColor(SharedStyles.primaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
    
    private var distanceButton: some View {
        Button(action: { activeSheet = .distance }) {
            VStack(spacing: 8) {
                Image(systemName: "triangle")
                    .font(.system(size: 24))
                    .foregroundColor(SharedStyles.primaryColor)
                Text(selectedDistance)
                    .font(SharedStyles.Text.caption)
                    .foregroundColor(SharedStyles.primaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
    
    private var targetButton: some View {
        Button(action: { activeSheet = .target }) {
            VStack(spacing: 8) {
                Image(systemName: "square.grid.3x3")
                    .font(.system(size: 24))
                    .foregroundColor(SharedStyles.primaryColor)
                Text(TargetTypeDisplay.primaryTitle(for: selectedTarget))
                    .font(SharedStyles.Text.caption)
                    .foregroundColor(SharedStyles.primaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
    
    private var scoreInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            scoreInputHeader
            
            // 始终显示成绩输入框
            scoreDisplayGrid
            
            if inputMode == .visualTarget {
                visualTargetInputView
            }
        }
        .clayCard(tint: SharedStyles.Accent.sky)
        .padding(.horizontal, 16)
    }
    
    private var scoreInputHeader: some View {
        HStack {
            Text(L10n.SingleInput.scoreInput)
                .font(SharedStyles.Text.title)
            Spacer()
            
            Text(L10n.SingleInput.totalScore(totalScore))
                .font(SharedStyles.Text.caption)
                .foregroundColor(SharedStyles.primaryColor)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // 成绩显示网格（始终显示）
    private var scoreDisplayGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
            spacing: 12
        ) {
            ForEach(0..<6) { index in
                Button {
                    selectedScoreIndex = index
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedScoreIndex == index ? SharedStyles.primaryColor.opacity(0.16) : Color.white.opacity(0.48))
                            .frame(height: 50)
                        
                        if scores[index].isEmpty {
                            Text("\(index + 1).")
                                .font(SharedStyles.Text.body)
                                .foregroundColor(SharedStyles.tertiaryTextColor)
                        } else {
                            Text(scoreLabel(at: index))
                                .font(SharedStyles.Text.title)
                                .foregroundColor(SharedStyles.primaryTextColor)
                        }
                    }
                }
            }
        }
        .padding([.horizontal, .bottom], 16)
    }
    
    private var visualTargetInputView: some View {
        VStack(spacing: 16) {
            if let targetFace = TargetFaceManager.shared.getTarget(for: getTargetFaceType(from: selectedTarget)) {
                InteractiveTargetView(
                    targetFace: targetFace,
                    size: CGSize(width: 300, height: 300),
                    arrowHits: $arrowHits,
                    currentGroup: 1,
                    currentArrowIndex: selectedScoreIndex,
                    onArrowHit: { arrowHit in
                        handleVisualTargetInput(arrowHit)
                    }
                )
                .padding(.vertical, 8)
            }
            
            targetActionBar
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var inputModeToggle: some View {
        HStack(spacing: 4) {
            inputModeButton(
                title: L10n.CommonAction.visualTarget,
                systemImage: "target",
                isActive: inputMode == .visualTarget,
                showsProBadge: !purchaseManager.isProUnlocked
            ) {
                activateVisualTargetInput()
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

    private func activateVisualTargetInput() {
        guard purchaseManager.isProUnlocked else {
            activePaywallFeature = .visualTargetInput
            return
        }

        inputMode = .visualTarget
    }
    
    private var targetActionBar: some View {
        HStack(spacing: 16) {
            targetActionButton(
                title: L10n.CommonAction.remove,
                systemImage: "xmark",
                foreground: TargetInputPalette.mutedText,
                background: TargetInputPalette.track,
                action: handleScoreDelete
            )
            
            targetActionButton(
                title: L10n.Common.save,
                systemImage: "square.and.arrow.down",
                foreground: .white,
                background: TargetInputPalette.primary,
                action: saveRecord
            )
        }
    }
    
    private func targetActionButton(title: String, systemImage: String, foreground: Color, background: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(background)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var bottomKeyboardView: some View {
        HStack(spacing: 8) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    CircleScoreButton(score: "X", onTap: { handleScoreInput("X") })
                    CircleScoreButton(score: "10", onTap: { handleScoreInput("10") })
                    CircleScoreButton(score: "9", onTap: { handleScoreInput("9") })
                    CircleScoreButton(score: "8", onTap: { handleScoreInput("8") })
                }
                
                HStack(spacing: 6) {
                    CircleScoreButton(score: "7", onTap: { handleScoreInput("7") })
                    CircleScoreButton(score: "6", onTap: { handleScoreInput("6") })
                    CircleScoreButton(score: "5", onTap: { handleScoreInput("5") })
                    CircleScoreButton(score: "4", onTap: { handleScoreInput("4") })
                }
                
                HStack(spacing: 6) {
                    CircleScoreButton(score: "3", onTap: { handleScoreInput("3") })
                    CircleScoreButton(score: "2", onTap: { handleScoreInput("2") })
                    CircleScoreButton(score: "1", onTap: { handleScoreInput("1") })
                    CircleScoreButton(score: "M", isSpecial: true, onTap: { handleScoreInput("M") })
                }
            }
            .frame(maxWidth: .infinity)
            
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
                        .stroke(SharedStyles.primaryColor.opacity(0.55), lineWidth: 1)
                )
                
                Button(action: saveRecord) {
                    Text(L10n.Common.save)
                        .font(SharedStyles.Text.bodyEmphasis)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 68, height: 72)
                .blockSurface(colors: SharedStyles.GradientSet.sunrise, radius: 16)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .clayCard(tint: SharedStyles.primaryColor, radius: 24)
    }
    
    private func handleScoreInput(_ score: String) {
        scores[selectedScoreIndex] = score
        
        // 自动移动到下一个输入位置
        if selectedScoreIndex < 5 {
            selectedScoreIndex += 1
        }
    }
    
    private func handleScoreDelete() {
        if !scores[selectedScoreIndex].isEmpty {
            scores[selectedScoreIndex] = ""
            // 同时移除对应的箭着点标记
            if selectedScoreIndex < arrowHits.count {
                arrowHits.remove(at: selectedScoreIndex)
            }
        } else if selectedScoreIndex > 0 {
            selectedScoreIndex -= 1
            scores[selectedScoreIndex] = ""
            // 同时移除对应的箭着点标记
            if selectedScoreIndex < arrowHits.count {
                arrowHits.remove(at: selectedScoreIndex)
            }
        }
    }
    
    private func handleVisualTargetInput(_ arrowHit: ArrowHit) {
        let currentIndex = selectedScoreIndex
        let score = arrowHit.scoreLabel
        
        scores[currentIndex] = score
        
        if currentIndex < arrowHits.count {
            arrowHits[currentIndex] = arrowHit
        } else {
            arrowHits.append(arrowHit)
        }
        
        if currentIndex < 5 {
            selectedScoreIndex = currentIndex + 1
        }
    }
    
    private func scoreLabel(at index: Int) -> String {
        guard scores.indices.contains(index), !scores[index].isEmpty else {
            return ""
        }
        
        if arrowHits.indices.contains(index) {
            return arrowHits[index].scoreLabel
        }
        
        return scores[index]
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
    
    private func saveRecord() {
        if let editingRecord = editingRecord {
            // 编辑模式：更新现有记录
            let updatedRecord = ArcheryRecord(
                id: editingRecord.id, // 保持原有ID
                bowType: selectedBowType,
                distance: selectedDistance,
                targetType: selectedTarget,
                scores: scores.filter { !$0.isEmpty },
                date: editingRecord.date, // 保持原有日期
                numberOfArrows: scores.filter { !$0.isEmpty }.count
            )
            
            // 更新记录
            archeryStore.updateRecord(updatedRecord)
            closeInputFlow()
        } else {
            // 新建模式：创建新记录
            let record = ArcheryRecord(
                id: UUID(),
                bowType: selectedBowType,
                distance: selectedDistance,
                targetType: selectedTarget,
                scores: scores.filter { !$0.isEmpty },
                date: Date(),
                numberOfArrows: scores.filter { !$0.isEmpty }.count
            )
            
            archeryStore.addRecord(record)
            completedRecord = record
        }
    }

    private func closeInputFlow() {
        completedRecord = nil
        revealAppTabBar?()
        dismiss()
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

struct CircleScoreButton: View {
    let score: String
    let isSpecial: Bool
    let onTap: () -> Void
    
    init(score: String, isSpecial: Bool = false, onTap: @escaping () -> Void) {
        self.score = score
        self.isSpecial = isSpecial
        self.onTap = onTap
    }
    
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
                    isSpecial ? SharedStyles.Accent.coral : (isHighScore ? SharedStyles.primaryColor : SharedStyles.primaryTextColor.opacity(0.28)),
                    lineWidth: 1
                )
        )
        .shadow(color: SharedStyles.Shadow.highlight, radius: 8, x: -3, y: -3)
        .shadow(color: SharedStyles.Shadow.light, radius: 10, x: 5, y: 6)
    }
}

#Preview {
    NavigationStack {
        ScoreInputView()
            .environmentObject(ArcheryStore())
            .environmentObject(PurchaseManager())
            .environmentObject(TabBarManager())
    }
}

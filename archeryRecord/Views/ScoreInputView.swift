import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import Foundation

struct ScoreInputView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var archeryStore: ArcheryStore
    @EnvironmentObject private var tabBarManager: TabBarManager
    
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
                Text("记一组")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        tabBarManager.show()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text(L10n.Common.back)
                    }
                    .foregroundColor(.black)
                }
            }
        }
        #if os(iOS)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        #endif
        #else
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("记一组")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            ToolbarItem(placement: .automatic) {
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
        #endif
        .onAppear {
            tabBarManager.hide()
        }
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
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                basicOptionsCard
                scoreInputCard
            }
            .padding(.vertical, 16)
        }
        #if canImport(UIKit)
        .background(Color(UIColor.systemGroupedBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
    }
    
    private var basicOptionsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("基本选项")
                    .font(.headline)
                Spacer()
                
                // 输入模式切换开关
                HStack(spacing: 8) {
                    Image(systemName: inputMode == .keyboard ? "keyboard" : "target")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    
                    Toggle("", isOn: Binding(
                        get: { inputMode == .visualTarget },
                        set: { newValue in
                            inputMode = newValue ? .visualTarget : .keyboard
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                    .scaleEffect(0.8)
                    
                    Text(inputMode == .visualTarget ? "靶面" : "键盘")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            HStack(spacing: 0) {
                bowTypeButton
                Divider()
                    .frame(width: 1, height: 40)
                    .background(Color.gray.opacity(0.2))
                distanceButton
                Divider()
                    .frame(width: 1, height: 40)
                    .background(Color.gray.opacity(0.2))
                targetButton
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    private var bowTypeButton: some View {
        Button(action: { activeSheet = .bowType }) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                Text(selectedBowType)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
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
                    .foregroundColor(.orange)
                Text(selectedDistance)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
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
                    .foregroundColor(.orange)
                Text(selectedTarget)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    private var scoreInputHeader: some View {
        HStack {
            Text("成绩录入")
                .font(.headline)
            Spacer()
            
            Text("总分：\(totalScore)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.orange)
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
                            .fill(selectedScoreIndex == index ? Color.orange.opacity(0.1) : Color.gray.opacity(0.05))
                            .frame(height: 50)
                        
                        if scores[index].isEmpty {
                            Text("\(index + 1).")
                                .font(.system(size: 16))
                                .foregroundColor(.gray.opacity(0.5))
                        } else {
                            Text(scores[index])
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                        }
                    }
                }
            }
        }
        .padding([.horizontal, .bottom], 16)
    }
    
    private var visualTargetInputView: some View {
        VStack(spacing: 16) {
            // 靶面视图
            if let targetFace = TargetFaceManager.shared.getTarget(for: getTargetFaceType(from: selectedTarget)) {
                InteractiveTargetView(
                    targetFace: targetFace,
                    size: CGSize(width: 280, height: 280),
                    arrowHits: $arrowHits,
                    currentGroup: 1,
                    currentArrowIndex: selectedScoreIndex,
                    onArrowHit: { arrowHit in
                        handleVisualTargetInput(arrowHit)
                    }
                )
            }
            
            // 移除和完成按钮
            HStack(spacing: 16) {
                Button(action: handleScoreDelete) {
                    Text("移除成绩")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                
                Button(action: saveRecord) {
                    Text("完成成绩记录")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
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
                        .stroke(Color.orange, lineWidth: 1)
                )
                
                Button(action: saveRecord) {
                    Text("保存")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 68, height: 72)
                .background(Color.orange)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -3)
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
        // 将箭着点转换为分数
        let score = String(arrowHit.score)
        handleScoreInput(score)
        
        // 更新箭着点数组
        if selectedScoreIndex < arrowHits.count {
            arrowHits[selectedScoreIndex] = arrowHit
        } else {
            arrowHits.append(arrowHit)
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
        }
        
        withAnimation(.easeInOut(duration: 0.1)) {
            tabBarManager.show()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            dismiss()
        }
    }
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
                .stroke(isSpecial ? Color.red : (isHighScore ? Color.orange : Color.black), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        ScoreInputView()
            .environmentObject(ArcheryStore())
            .environmentObject(TabBarManager())
    }
}

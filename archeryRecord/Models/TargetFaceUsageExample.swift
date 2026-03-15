//
//  TargetFaceUsageExample.swift
//  archeryRecord
//
//  射箭靶面数据模型使用示例
//

import SwiftUI

// MARK: - 使用示例
struct TargetFaceUsageExample {
    
    // MARK: - 基本使用
    
    /// 获取靶面管理器实例
    static func getTargetManager() -> TargetFaceManager {
        return TargetFaceManager.shared
    }
    
    /// 根据类型获取靶面
    static func getTargetByType() {
        let manager = TargetFaceManager.shared
        
        // 通过枚举获取
        if let target80cm = manager.getTarget(for: .full80cm) {
            print("80cm全靶面: \(target80cm.description)")
            print("直径: \(target80cm.diameter)cm")
            print("环数: \(target80cm.rings.count)")
        }
        
        // 通过字符串获取（与现有代码兼容）
        if let target40cm = manager.getTarget(for: "40cm全靶面") {
            print("40cm全靶面: \(target40cm.description)")
        }
    }
    
    /// 验证分数
    static func validateScores() {
        let manager = TargetFaceManager.shared
        guard let target = manager.getTarget(for: .full80cm) else { return }
        
        let scores = ["X", "10", "9", "8", "7", "6", "5", "4", "3", "2", "1", "M", "0", "11"]
        
        for score in scores {
            let isValid = target.isValidScore(score)
            let numericValue = target.getNumericScore(score)
            print("分数 \(score): 有效=\(isValid), 数值=\(numericValue)")
        }
    }
    
    /// 获取靶环信息
    static func getRingInfo() {
        let manager = TargetFaceManager.shared
        guard let target = manager.getTarget(for: .compoundInner10) else { return }
        
        print("\n复合弓专用靶面信息:")
        print("分值范围: \(target.minScore)-\(target.maxScore)")
        print("金环数量: \(target.goldRingCount)")
        print("是否全靶面: \(target.isFullTarget)")
        
        // 遍历所有靶环
        for ring in target.rings.sorted(by: { $0.ringNumber > $1.ringNumber }) {
            print("\(ring.ringNumber)环: \(ring.score)分, 颜色=\(ring.color), 半径=\(ring.outerRadius)cm")
        }
    }
    
    /// 计算位置分数
    static func calculatePositionScore() {
        let manager = TargetFaceManager.shared
        guard let target = manager.getTarget(for: .full40cm) else { return }
        
        let positions = [0.5, 1.5, 3.0, 6.0, 10.0, 15.0, 25.0] // 不同半径位置
        
        print("\n40cm全靶面位置分数计算:")
        for position in positions {
            let score = target.getScore(at: position)
            print("半径 \(position)cm 处的分数: \(score)")
        }
    }
    
    // MARK: - UI相关使用
    
    /// 获取UI尺寸
    static func getUISize() {
        let manager = TargetFaceManager.shared
        guard let target = manager.getTarget(for: .full80cm) else { return }
        
        let containerSize = CGSize(width: 300, height: 400)
        let targetSize = target.getUISize(for: containerSize)
        
        print("\n容器尺寸: \(containerSize)")
        print("靶面UI尺寸: \(targetSize)")
        print("比例因子: \(target.scaleFactor)")
    }
    
    /// 获取环线半径
    static func getRingRadius() {
        let manager = TargetFaceManager.shared
        guard let target = manager.getTarget(for: .full80cm) else { return }
        
        let uiSize = CGSize(width: 200, height: 200)
        
        print("\n80cm全靶面在200x200像素下的环线半径:")
        for ringNumber in target.ringRange {
            let radius = target.getRingRadius(for: ringNumber, in: uiSize)
            print("\(ringNumber)环半径: \(radius)像素")
        }
    }
    
    // MARK: - 与现有代码集成
    
    /// 替换现有的靶面类型选择
    static func replaceExistingTargetSelection() {
        let manager = TargetFaceManager.shared
        
        // 获取所有可用的靶面类型名称（与L10n.Options.TargetType.all兼容）
        let targetTypeNames = manager.getAllTargetTypeNames()
        print("\n可用靶面类型:")
        for name in targetTypeNames {
            print("- \(name)")
        }
        
        // 模拟现有代码中的靶面选择
        let selectedTargetType = "80cm全靶面" // 来自用户选择
        if let selectedTarget = manager.getTarget(for: selectedTargetType) {
            print("\n用户选择的靶面: \(selectedTarget.type.rawValue)")
            print("靶面描述: \(selectedTarget.description)")
        }
    }
    
    /// 增强记录保存
    static func enhanceRecordSaving() {
        let manager = TargetFaceManager.shared
        
        // 模拟保存记录时的靶面验证
        let targetType = "40cm三环"
        let scores = ["10", "9", "8", "7", "M"] // 用户输入的分数
        
        guard let target = manager.getTarget(for: targetType) else {
            print("无效的靶面类型: \(targetType)")
            return
        }
        
        print("\n验证分数有效性:")
        var validScores: [String] = []
        var totalScore = 0
        
        for score in scores {
            if target.isValidScore(score) {
                validScores.append(score)
                totalScore += target.getNumericScore(score)
                print("✓ \(score) - 有效")
            } else {
                print("✗ \(score) - 无效（该靶面不支持此分数）")
            }
        }
        
        print("有效分数: \(validScores)")
        print("总分: \(totalScore)")
        print("平均分: \(Double(totalScore) / Double(validScores.count))")
    }
    
    // MARK: - 运行所有示例
    
    static func runAllExamples() {
        print("=== 射箭靶面数据模型使用示例 ===")
        
        getTargetByType()
        validateScores()
        getRingInfo()
        calculatePositionScore()
        getUISize()
        getRingRadius()
        replaceExistingTargetSelection()
        enhanceRecordSaving()
        
        print("\n=== 示例运行完成 ===")
    }
}

// MARK: - SwiftUI预览示例
struct TargetFaceExampleView: View {
    @StateObject private var targetManager = TargetFaceManager.shared
    @State private var selectedTargetType = "80cm靶面"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("射箭靶面示例")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // 靶面选择器
                TargetFaceSelector(selectedTargetType: $selectedTargetType)
                
                // 显示选中的靶面
                if let targetFace = targetManager.getTarget(for: selectedTargetType) {
                    TargetFaceInfoView(targetFace: targetFace)
                }
                
                // 所有靶面预览
                Text("所有可用靶面")
                    .font(.headline)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(targetManager.availableTargets, id: \.id) { targetFace in
                        VStack {
                            TargetFaceView(
                                targetFace: targetFace,
                                size: CGSize(width: 100, height: 100),
                                showLabels: true
                            )
                            Text(targetFace.type.rawValue)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    TargetFaceExampleView()
}
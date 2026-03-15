//
//  TargetFace.swift
//  archeryRecord
//
//  射箭靶面数据模型
//

import Foundation
import SwiftUI

// MARK: - 靶面类型枚举
enum TargetFaceType: String, CaseIterable, Codable {
    case standard122cm = "122cm靶面（标准室外）"
    case full80cm = "80cm靶面"
    case full40cm = "40cm标准靶（完整版）"
    case triple40cmVertical = "40cm三联靶（竖排）"
    case triple40cmTriangle = "40cm三联靶（三角形）"
    case indoor60cm = "60cm室内靶"
    case compoundInner10 = "复合弓专用靶（内10环）"
    
    var identifier: String {
        switch self {
        case .standard122cm: return "target_type_122cm_standard"
        case .full80cm: return "target_type_80cm_full"
        case .full40cm: return "target_type_40cm_full"
        case .triple40cmVertical: return "target_type_40cm_triple_vertical"
        case .triple40cmTriangle: return "target_type_40cm_triple_triangle"
        case .indoor60cm: return "target_type_60cm_indoor"
        case .compoundInner10: return "target_type_compound_inner10"
        }
    }
}

// MARK: - 靶环信息
struct TargetRing: Codable {
    let ringNumber: Int        // 环数 (1-10, X表示为10)
    let score: Int            // 分值
    let color: String         // 颜色名称
    let innerRadius: Double   // 内半径 (cm)
    let outerRadius: Double   // 外半径 (cm)
    
    var isGoldRing: Bool {
        return ringNumber >= 9
    }
    
    var displayScore: String {
        return ringNumber == 11 ? "X" : "\(score)"
    }
}

// MARK: - 靶面数据模型
struct TargetFace: Codable, Identifiable {
    let id = UUID()
    let type: TargetFaceType
    let diameter: Double      // 靶面直径 (cm)
    let rings: [TargetRing]   // 靶环信息
    let centerRadius: Double  // 中心圆半径 (cm)
    let description: String   // 靶面描述
    
    // MARK: - 计算属性
    
    /// 最大分值
    var maxScore: Int {
        return rings.map { $0.score }.max() ?? 10
    }
    
    /// 最小分值
    var minScore: Int {
        return rings.map { $0.score }.min() ?? 1
    }
    
    /// 环数范围
    var ringRange: ClosedRange<Int> {
        let minRing = rings.map { $0.ringNumber }.min() ?? 1
        let maxRing = rings.map { $0.ringNumber }.max() ?? 10
        return minRing...maxRing
    }
    
    /// 金环数量 (9环和10环)
    var goldRingCount: Int {
        return rings.filter { $0.isGoldRing }.count
    }
    
    /// 是否为全靶面
    var isFullTarget: Bool {
        return rings.count == 10
    }
    
    /// 靶面比例因子 (相对于标准122cm靶面)
    var scaleFactor: Double {
        return diameter / 122.0
    }
    
    // MARK: - 方法
    
    /// 根据分值获取对应的靶环信息
    func getRing(for score: Int) -> TargetRing? {
        return rings.first { $0.score == score }
    }
    
    /// 根据环数获取对应的靶环信息
    func getRingByNumber(_ ringNumber: Int) -> TargetRing? {
        return rings.first { $0.ringNumber == ringNumber }
    }
    
    /// 获取指定半径位置的分值
    func getScore(at radius: Double) -> Int {
        for ring in rings.sorted(by: { $0.outerRadius < $1.outerRadius }) {
            if radius <= ring.outerRadius {
                return ring.score
            }
        }
        return 0 // 脱靶
    }
    
    /// 获取靶环颜色
    func getRingColor(for ringNumber: Int) -> Color {
        guard let ring = getRingByNumber(ringNumber) else { return .gray }
        
        switch ring.color {
        case "gold": return .yellow
        case "red": return .red
        case "blue": return .blue
        case "black": return .black
        case "white": return .white
        default: return .gray
        }
    }
    
    /// 计算靶面UI尺寸
    func getUISize(for containerSize: CGSize) -> CGSize {
        let minDimension = min(containerSize.width, containerSize.height)
        let targetSize = minDimension * 0.8 // 留出边距
        return CGSize(width: targetSize, height: targetSize)
    }
    
    /// 获取环线半径 (用于UI绘制)
    func getRingRadius(for ringNumber: Int, in size: CGSize) -> Double {
        guard let ring = getRingByNumber(ringNumber) else { return 0 }
        let radius = size.width / 2
        return (ring.outerRadius / (diameter / 2)) * radius
    }
}

// MARK: - 靶面管理器
class TargetFaceManager: ObservableObject {
    static let shared = TargetFaceManager()
    
    @Published private(set) var availableTargets: [TargetFace] = []
    
    private init() {
        setupTargets()
    }
    
    /// 根据类型获取靶面
    func getTarget(for type: TargetFaceType) -> TargetFace? {
        return availableTargets.first { $0.type == type }
    }
    
    /// 根据字符串获取靶面
    func getTarget(for typeString: String) -> TargetFace? {
        guard let type = TargetFaceType.allCases.first(where: { $0.rawValue == typeString }) else {
            return nil
        }
        return getTarget(for: type)
    }
    
    /// 获取所有靶面类型名称
    func getAllTargetTypeNames() -> [String] {
        return TargetFaceType.allCases.map { $0.rawValue }
    }
    
    /// 设置靶面配置
    private func setupTargets() {
        availableTargets = [
            create122cmStandardTarget(),
            create80cmFullTarget(),
            create40cmFullTarget(),
            create40cmTripleVerticalTarget(),
            create40cmTripleTriangleTarget(),
            create60cmIndoorTarget(),
            createCompoundInner10Target()
        ]
    }
    
    // MARK: - 靶面创建方法
    
    private func create122cmStandardTarget() -> TargetFace {
        let rings = [
            TargetRing(ringNumber: 1, score: 1, color: "white", innerRadius: 55.0, outerRadius: 61.0),
            TargetRing(ringNumber: 2, score: 2, color: "white", innerRadius: 49.0, outerRadius: 55.0),
            TargetRing(ringNumber: 3, score: 3, color: "black", innerRadius: 43.0, outerRadius: 49.0),
            TargetRing(ringNumber: 4, score: 4, color: "black", innerRadius: 37.0, outerRadius: 43.0),
            TargetRing(ringNumber: 5, score: 5, color: "blue", innerRadius: 31.0, outerRadius: 37.0),
            TargetRing(ringNumber: 6, score: 6, color: "blue", innerRadius: 25.0, outerRadius: 31.0),
            TargetRing(ringNumber: 7, score: 7, color: "red", innerRadius: 19.0, outerRadius: 25.0),
            TargetRing(ringNumber: 8, score: 8, color: "red", innerRadius: 13.0, outerRadius: 19.0),
            TargetRing(ringNumber: 9, score: 9, color: "gold", innerRadius: 8.5, outerRadius: 13.0),
            TargetRing(ringNumber: 10, score: 10, color: "gold", innerRadius: 4.5, outerRadius: 8.5),
            TargetRing(ringNumber: 11, score: 10, color: "gold", innerRadius: 0.0, outerRadius: 4.5)
        ]
        
        return TargetFace(
            type: .standard122cm,
            diameter: 122.0,
            rings: rings,
            centerRadius: 3.0,
            description: "122cm标准室外靶面，用于70米等长距离射箭"
        )
    }
    
    private func create80cmFullTarget() -> TargetFace {
        let rings = [
            TargetRing(ringNumber: 1, score: 1, color: "white", innerRadius: 36.0, outerRadius: 40.0),
            TargetRing(ringNumber: 2, score: 2, color: "white", innerRadius: 32.0, outerRadius: 36.0),
            TargetRing(ringNumber: 3, score: 3, color: "black", innerRadius: 28.0, outerRadius: 32.0),
            TargetRing(ringNumber: 4, score: 4, color: "black", innerRadius: 24.0, outerRadius: 28.0),
            TargetRing(ringNumber: 5, score: 5, color: "blue", innerRadius: 20.0, outerRadius: 24.0),
            TargetRing(ringNumber: 6, score: 6, color: "blue", innerRadius: 16.0, outerRadius: 20.0),
            TargetRing(ringNumber: 7, score: 7, color: "red", innerRadius: 12.0, outerRadius: 16.0),
            TargetRing(ringNumber: 8, score: 8, color: "red", innerRadius: 8.0, outerRadius: 12.0),
            TargetRing(ringNumber: 9, score: 9, color: "gold", innerRadius: 5.5, outerRadius: 8.0),
            TargetRing(ringNumber: 10, score: 10, color: "gold", innerRadius: 3.0, outerRadius: 5.5),
            TargetRing(ringNumber: 11, score: 10, color: "gold", innerRadius: 0.0, outerRadius: 3.0)
        ]
        
        return TargetFace(
            type: .full80cm,
            diameter: 80.0,
            rings: rings,
            centerRadius: 2.0,
            description: "标准80cm靶面，用于50米等中距离射箭"
        )
    }
    
    private func create40cmFullTarget() -> TargetFace {
        let rings = [
            TargetRing(ringNumber: 1, score: 1, color: "white", innerRadius: 18.0, outerRadius: 20.0),
            TargetRing(ringNumber: 2, score: 2, color: "white", innerRadius: 16.0, outerRadius: 18.0),
            TargetRing(ringNumber: 3, score: 3, color: "black", innerRadius: 14.0, outerRadius: 16.0),
            TargetRing(ringNumber: 4, score: 4, color: "black", innerRadius: 12.0, outerRadius: 14.0),
            TargetRing(ringNumber: 5, score: 5, color: "blue", innerRadius: 10.0, outerRadius: 12.0),
            TargetRing(ringNumber: 6, score: 6, color: "blue", innerRadius: 8.0, outerRadius: 10.0),
            TargetRing(ringNumber: 7, score: 7, color: "red", innerRadius: 6.0, outerRadius: 8.0),
            TargetRing(ringNumber: 8, score: 8, color: "red", innerRadius: 4.0, outerRadius: 6.0),
            TargetRing(ringNumber: 9, score: 9, color: "gold", innerRadius: 2.8, outerRadius: 4.0),
            TargetRing(ringNumber: 10, score: 10, color: "gold", innerRadius: 1.5, outerRadius: 2.8),
            TargetRing(ringNumber: 11, score: 10, color: "gold", innerRadius: 0.0, outerRadius: 1.5)
        ]
        
        return TargetFace(
            type: .full40cm,
            diameter: 40.0,
            rings: rings,
            centerRadius: 1.0,
            description: "40cm标准靶面完整版，包含1-10环"
        )
    }
    
    private func create40cmTripleVerticalTarget() -> TargetFace {
        let rings = [
            TargetRing(ringNumber: 6, score: 6, color: "blue", innerRadius: 8.0, outerRadius: 10.0),
            TargetRing(ringNumber: 7, score: 7, color: "red", innerRadius: 6.0, outerRadius: 8.0),
            TargetRing(ringNumber: 8, score: 8, color: "red", innerRadius: 4.0, outerRadius: 6.0),
            TargetRing(ringNumber: 9, score: 9, color: "gold", innerRadius: 2.8, outerRadius: 4.0),
            TargetRing(ringNumber: 10, score: 10, color: "gold", innerRadius: 1.5, outerRadius: 2.8),
            TargetRing(ringNumber: 11, score: 10, color: "gold", innerRadius: 0.0, outerRadius: 1.5)
        ]
        
        return TargetFace(
            type: .triple40cmVertical,
            diameter: 40.0,
            rings: rings,
            centerRadius: 1.0,
            description: "40cm三联靶竖排版，包含6-10环，三个靶面垂直排列"
        )
    }
    
    private func create40cmTripleTriangleTarget() -> TargetFace {
        let rings = [
            TargetRing(ringNumber: 6, score: 6, color: "blue", innerRadius: 8.0, outerRadius: 10.0),
            TargetRing(ringNumber: 7, score: 7, color: "red", innerRadius: 6.0, outerRadius: 8.0),
            TargetRing(ringNumber: 8, score: 8, color: "red", innerRadius: 4.0, outerRadius: 6.0),
            TargetRing(ringNumber: 9, score: 9, color: "gold", innerRadius: 2.0, outerRadius: 4.0),
            TargetRing(ringNumber: 10, score: 10, color: "gold", innerRadius: 1.0, outerRadius: 2.0),
            TargetRing(ringNumber: 11, score: 10, color: "gold", innerRadius: 0.0, outerRadius: 1.0)
        ]
        
        return TargetFace(
            type: .triple40cmTriangle,
            diameter: 40.0,
            rings: rings,
            centerRadius: 1.0,
            description: "40cm三联靶三角形版，包含6-10环，三个靶面呈三角形排列"
        )
    }
    
    private func create60cmIndoorTarget() -> TargetFace {
        let rings = [
            TargetRing(ringNumber: 1, score: 1, color: "white", innerRadius: 27.0, outerRadius: 30.0),
            TargetRing(ringNumber: 2, score: 2, color: "white", innerRadius: 24.0, outerRadius: 27.0),
            TargetRing(ringNumber: 3, score: 3, color: "black", innerRadius: 21.0, outerRadius: 24.0),
            TargetRing(ringNumber: 4, score: 4, color: "black", innerRadius: 18.0, outerRadius: 21.0),
            TargetRing(ringNumber: 5, score: 5, color: "blue", innerRadius: 15.0, outerRadius: 18.0),
            TargetRing(ringNumber: 6, score: 6, color: "blue", innerRadius: 12.0, outerRadius: 15.0),
            TargetRing(ringNumber: 7, score: 7, color: "red", innerRadius: 9.0, outerRadius: 12.0),
            TargetRing(ringNumber: 8, score: 8, color: "red", innerRadius: 6.0, outerRadius: 9.0),
            TargetRing(ringNumber: 9, score: 9, color: "gold", innerRadius: 4.2, outerRadius: 6.0),
            TargetRing(ringNumber: 10, score: 10, color: "gold", innerRadius: 2.2, outerRadius: 4.2),
            TargetRing(ringNumber: 11, score: 10, color: "gold", innerRadius: 0.0, outerRadius: 2.2)
        ]
        
        return TargetFace(
            type: .indoor60cm,
            diameter: 60.0,
            rings: rings,
            centerRadius: 1.5,
            description: "60cm室内靶面，用于18米室内射箭"
        )
    }
    
    private func createCompoundInner10Target() -> TargetFace {
        let rings = [
            TargetRing(ringNumber: 6, score: 6, color: "blue", innerRadius: 16.0, outerRadius: 20.0),
            TargetRing(ringNumber: 7, score: 7, color: "red", innerRadius: 12.0, outerRadius: 16.0),
            TargetRing(ringNumber: 8, score: 8, color: "red", innerRadius: 8.0, outerRadius: 12.0),
            TargetRing(ringNumber: 9, score: 9, color: "gold", innerRadius: 5.5, outerRadius: 8.0),
            TargetRing(ringNumber: 10, score: 10, color: "gold", innerRadius: 3.0, outerRadius: 5.5),
            TargetRing(ringNumber: 11, score: 10, color: "gold", innerRadius: 0.0, outerRadius: 3.0)
        ]
        
        return TargetFace(
            type: .compoundInner10,
            diameter: 80.0,
            rings: rings,
            centerRadius: 1.0,
            description: "复合弓专用靶面，内10环分为外10环和内10环(X环)"
        )
    }
}

// MARK: - 扩展方法
extension TargetFace {
    /// 验证分数是否有效
    func isValidScore(_ score: String) -> Bool {
        if score == "X" { return true }
        if score == "M" { return true }
        
        guard let numericScore = Int(score) else { return false }
        return rings.contains { $0.score == numericScore }
    }
    
    /// 获取分数的数值
    func getNumericScore(_ score: String) -> Int {
        if score == "X" { return 10 }
        if score == "M" { return 0 }
        return Int(score) ?? 0
    }
}
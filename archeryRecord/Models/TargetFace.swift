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

struct TargetHitResult {
    let position: CGPoint
    let score: Int
    let ringNumber: Int
    let isMiss: Bool
}

struct TargetLayoutMetrics {
    let containerSize: CGSize
    let boundsSizeCm: CGSize
    let scale: CGFloat
    let spotCentersCm: [CGPoint]
    let spotRadiusCm: Double
    
    var viewCenter: CGPoint {
        CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)
    }
    
    var centerDotSize: CGFloat {
        max(4, scale * 0.9)
    }
    
    func pointInCentimeters(from viewPoint: CGPoint) -> CGPoint {
        guard scale > 0 else { return .zero }
        return CGPoint(
            x: (viewPoint.x - viewCenter.x) / scale,
            y: (viewPoint.y - viewCenter.y) / scale
        )
    }
    
    func pointInView(from pointCm: CGPoint) -> CGPoint {
        CGPoint(
            x: viewCenter.x + pointCm.x * scale,
            y: viewCenter.y + pointCm.y * scale
        )
    }
}

private enum WAIndoorTripleSpotSpec {
    static let centerDistanceCm: Double = 22.0
    static let triangleHeightCm: Double = centerDistanceCm * sqrt(3) / 2
    static let outerTenRadiusCm: Double = 2.0
    static let innerTenRadiusCm: Double = 1.0
}

private enum WAIndoorSingleFaceSpec {
    static let sixtyCmInnerTenRadiusCm: Double = 1.5
    static let sixtyCmOuterTenRadiusCm: Double = 3.0
    static let fortyCmInnerTenRadiusCm: Double = 1.0
    static let fortyCmOuterTenRadiusCm: Double = 2.0
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
        case "gold": return Color(red: 1.0, green: 0.843, blue: 0.0)
        case "red": return Color(red: 0.882, green: 0.192, blue: 0.192)
        case "blue": return Color(red: 0.0, green: 0.573, blue: 1.0)
        case "black": return Color(red: 0.102, green: 0.102, blue: 0.102)
        case "white": return Color(red: 0.973, green: 0.973, blue: 0.973)
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
    
    var spotCentersCm: [CGPoint] {
        switch type {
        case .triple40cmVertical:
            return [
                CGPoint(x: 0, y: -WAIndoorTripleSpotSpec.centerDistanceCm),
                .zero,
                CGPoint(x: 0, y: WAIndoorTripleSpotSpec.centerDistanceCm)
            ]
        case .triple40cmTriangle:
            return [
                CGPoint(x: 0, y: -(WAIndoorTripleSpotSpec.triangleHeightCm * 2 / 3)),
                CGPoint(x: -(WAIndoorTripleSpotSpec.centerDistanceCm / 2), y: WAIndoorTripleSpotSpec.triangleHeightCm / 3),
                CGPoint(x: WAIndoorTripleSpotSpec.centerDistanceCm / 2, y: WAIndoorTripleSpotSpec.triangleHeightCm / 3)
            ]
        default:
            return [.zero]
        }
    }
    
    var layoutBoundsCm: CGSize {
        let radius = diameter / 2
        let maxX = max(spotCentersCm.map { abs($0.x) + radius }.max() ?? radius, radius)
        let maxY = max(spotCentersCm.map { abs($0.y) + radius }.max() ?? radius, radius)
        return CGSize(width: maxX * 2, height: maxY * 2)
    }
    
    func layoutMetrics(in containerSize: CGSize) -> TargetLayoutMetrics {
        let bounds = layoutBoundsCm
        let width = max(bounds.width, 1)
        let height = max(bounds.height, 1)
        let scale = min(containerSize.width / width, containerSize.height / height)
        
        return TargetLayoutMetrics(
            containerSize: containerSize,
            boundsSizeCm: bounds,
            scale: scale,
            spotCentersCm: spotCentersCm,
            spotRadiusCm: diameter / 2
        )
    }
    
    func resolveHit(at pointCm: CGPoint) -> TargetHitResult {
        let spotRadius = diameter / 2
        let nearestSpot = spotCentersCm
            .map { center in
                (center, hypot(pointCm.x - center.x, pointCm.y - center.y))
            }
            .filter { $0.1 <= spotRadius }
            .min { $0.1 < $1.1 }
        
        guard let (spotCenter, _) = nearestSpot else {
            return TargetHitResult(position: pointCm, score: 0, ringNumber: 0, isMiss: true)
        }
        
        let localRadius = hypot(pointCm.x - spotCenter.x, pointCm.y - spotCenter.y)
        let ring = rings
            .sorted(by: { $0.outerRadius < $1.outerRadius })
            .first(where: { localRadius <= $0.outerRadius })
        
        guard let ring else {
            return TargetHitResult(position: pointCm, score: 0, ringNumber: 0, isMiss: true)
        }
        
        return TargetHitResult(
            position: pointCm,
            score: ring.score,
            ringNumber: ring.ringNumber,
            isMiss: false
        )
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
            TargetRing(ringNumber: 9, score: 9, color: "gold", innerRadius: WAIndoorSingleFaceSpec.fortyCmOuterTenRadiusCm, outerRadius: 4.0),
            TargetRing(ringNumber: 10, score: 10, color: "gold", innerRadius: WAIndoorSingleFaceSpec.fortyCmInnerTenRadiusCm, outerRadius: WAIndoorSingleFaceSpec.fortyCmOuterTenRadiusCm),
            TargetRing(ringNumber: 11, score: 10, color: "gold", innerRadius: 0.0, outerRadius: WAIndoorSingleFaceSpec.fortyCmInnerTenRadiusCm)
        ]
        
        return TargetFace(
            type: .full40cm,
            diameter: 40.0,
            rings: rings,
            centerRadius: 1.0,
            description: "40cm室内单靶，采用WA规格，2cm环宽与1cm内10环"
        )
    }
    
    private func create40cmTripleVerticalTarget() -> TargetFace {
        let rings = [
            TargetRing(ringNumber: 6, score: 6, color: "blue", innerRadius: 8.0, outerRadius: 10.0),
            TargetRing(ringNumber: 7, score: 7, color: "red", innerRadius: 6.0, outerRadius: 8.0),
            TargetRing(ringNumber: 8, score: 8, color: "red", innerRadius: 4.0, outerRadius: 6.0),
            TargetRing(ringNumber: 9, score: 9, color: "gold", innerRadius: WAIndoorTripleSpotSpec.outerTenRadiusCm, outerRadius: 4.0),
            TargetRing(ringNumber: 10, score: 10, color: "gold", innerRadius: WAIndoorTripleSpotSpec.innerTenRadiusCm, outerRadius: WAIndoorTripleSpotSpec.outerTenRadiusCm),
            TargetRing(ringNumber: 11, score: 10, color: "gold", innerRadius: 0.0, outerRadius: WAIndoorTripleSpotSpec.innerTenRadiusCm)
        ]
        
        return TargetFace(
            type: .triple40cmVertical,
            diameter: 40.0,
            rings: rings,
            centerRadius: 1.0,
            description: "40cm三联靶竖排版，采用WA室内规格，相邻靶心距22cm"
        )
    }
    
    private func create40cmTripleTriangleTarget() -> TargetFace {
        let rings = [
            TargetRing(ringNumber: 6, score: 6, color: "blue", innerRadius: 8.0, outerRadius: 10.0),
            TargetRing(ringNumber: 7, score: 7, color: "red", innerRadius: 6.0, outerRadius: 8.0),
            TargetRing(ringNumber: 8, score: 8, color: "red", innerRadius: 4.0, outerRadius: 6.0),
            TargetRing(ringNumber: 9, score: 9, color: "gold", innerRadius: WAIndoorTripleSpotSpec.outerTenRadiusCm, outerRadius: 4.0),
            TargetRing(ringNumber: 10, score: 10, color: "gold", innerRadius: WAIndoorTripleSpotSpec.innerTenRadiusCm, outerRadius: WAIndoorTripleSpotSpec.outerTenRadiusCm),
            TargetRing(ringNumber: 11, score: 10, color: "gold", innerRadius: 0.0, outerRadius: WAIndoorTripleSpotSpec.innerTenRadiusCm)
        ]
        
        return TargetFace(
            type: .triple40cmTriangle,
            diameter: 40.0,
            rings: rings,
            centerRadius: 1.0,
            description: "40cm三联靶三角形版，采用WA室内规格，三靶心按22cm边长等边三角形排列"
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
            TargetRing(ringNumber: 9, score: 9, color: "gold", innerRadius: WAIndoorSingleFaceSpec.sixtyCmOuterTenRadiusCm, outerRadius: 6.0),
            TargetRing(ringNumber: 10, score: 10, color: "gold", innerRadius: WAIndoorSingleFaceSpec.sixtyCmInnerTenRadiusCm, outerRadius: WAIndoorSingleFaceSpec.sixtyCmOuterTenRadiusCm),
            TargetRing(ringNumber: 11, score: 10, color: "gold", innerRadius: 0.0, outerRadius: WAIndoorSingleFaceSpec.sixtyCmInnerTenRadiusCm)
        ]
        
        return TargetFace(
            type: .indoor60cm,
            diameter: 60.0,
            rings: rings,
            centerRadius: 1.5,
            description: "60cm室内单靶，采用WA规格，3cm环宽与1.5cm内10环"
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

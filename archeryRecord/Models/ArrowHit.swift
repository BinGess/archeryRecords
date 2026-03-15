//
//  ArrowHit.swift
//  archeryRecord
//
//  箭着点数据模型和管理器
//

import Foundation
import CoreGraphics

// MARK: - 箭着点数据模型
struct ArrowHit: Identifiable, Codable {
    let id = UUID()
    let position: CGPoint // 相对于靶面中心的坐标 (cm)
    let score: Int
    let ringNumber: Int
    let timestamp: Date
    let groupIndex: Int // 组别索引
    let arrowIndex: Int // 箭序号
    let targetFaceType: TargetFaceType
    let isOverlapped: Bool
    
    init(
        position: CGPoint,
        score: Int,
        ringNumber: Int,
        timestamp: Date = Date(),
        groupIndex: Int,
        arrowIndex: Int,
        targetFaceType: TargetFaceType,
        isOverlapped: Bool = false
    ) {
        self.position = position
        self.score = score
        self.ringNumber = ringNumber
        self.timestamp = timestamp
        self.groupIndex = groupIndex
        self.arrowIndex = arrowIndex
        self.targetFaceType = targetFaceType
        self.isOverlapped = isOverlapped
    }
    
    // MARK: - 计算距离中心的距离
    func distanceFromCenter() -> Double {
        return sqrt(position.x * position.x + position.y * position.y)
    }
    
    // MARK: - 计算相对于中心的角度（弧度）
    func angleFromCenter() -> Double {
        return atan2(position.y, position.x)
    }
    
    // MARK: - 计算与另一个箭着点的距离
    func distance(to other: ArrowHit) -> Double {
        let dx = position.x - other.position.x
        let dy = position.y - other.position.y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - 重叠检测结果
struct OverlapResult {
    let isOverlapped: Bool
    let overlappedArrow: ArrowHit?
    let suggestedOffset: CGPoint?
    let overlapCount: Int
    
    init(
        isOverlapped: Bool = false,
        overlappedArrow: ArrowHit? = nil,
        suggestedOffset: CGPoint? = nil,
        overlapCount: Int = 0
    ) {
        self.isOverlapped = isOverlapped
        self.overlappedArrow = overlappedArrow
        self.suggestedOffset = suggestedOffset
        self.overlapCount = overlapCount
    }
}

// MARK: - 箭着点管理器
class ArrowHitManager: ObservableObject {
    // 重叠检测阈值（厘米）
    private let overlapThreshold: Double = 0.5
    // 箭径（厘米）
    private let arrowDiameter: Double = 0.8
    // 偏移距离（1.5倍箭径）
    private let offsetDistance: Double
    
    init() {
        self.offsetDistance = arrowDiameter * 1.5
    }
    
    // MARK: - 检测重叠
    func detectOverlap(newHit: ArrowHit, existingHits: [ArrowHit]) -> OverlapResult {
        // 只检测同组内的箭
        let sameGroupArrows = existingHits.filter { $0.groupIndex == newHit.groupIndex }
        
        for arrow in sameGroupArrows {
            let distance = newHit.distance(to: arrow)
            
            if distance < overlapThreshold {
                // 计算已使用的偏移角度
                let nearbyArrows = sameGroupArrows.filter { otherArrow in
                    arrow.distance(to: otherArrow) < offsetDistance + 0.1
                }
                
                let usedAngles = nearbyArrows.map { otherArrow in
                    getAngle(from: arrow.position, to: otherArrow.position)
                }
                
                // 找到未使用的角度
                let suggestedAngle = getUnusedAngle(usedAngles: usedAngles)
                let suggestedOffset = CGPoint(
                    x: cos(suggestedAngle) * offsetDistance,
                    y: sin(suggestedAngle) * offsetDistance
                )
                
                return OverlapResult(
                    isOverlapped: true,
                    overlappedArrow: arrow,
                    suggestedOffset: suggestedOffset,
                    overlapCount: nearbyArrows.count
                )
            }
        }
        
        return OverlapResult()
    }
    
    // MARK: - 计算两点间角度
    private func getAngle(from point1: CGPoint, to point2: CGPoint) -> Double {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return atan2(dy, dx)
    }
    
    // MARK: - 获取未使用的角度
    private func getUnusedAngle(usedAngles: [Double]) -> Double {
        let preferredAngles: [Double] = [
            0,                    // 右
            .pi / 2,             // 上
            .pi,                 // 左
            3 * .pi / 2,         // 下
            .pi / 4,             // 右上
            3 * .pi / 4,         // 左上
            5 * .pi / 4,         // 左下
            7 * .pi / 4          // 右下
        ]
        
        // 找到与已使用角度差异最大的角度
        for angle in preferredAngles {
            var isAngleAvailable = true
            for usedAngle in usedAngles {
                let angleDiff = abs(angle - usedAngle)
                let normalizedDiff = min(angleDiff, 2 * .pi - angleDiff)
                if normalizedDiff < .pi / 4 { // 45度内认为冲突
                    isAngleAvailable = false
                    break
                }
            }
            if isAngleAvailable {
                return angle
            }
        }
        
        // 如果所有预设角度都被占用，返回随机角度
        return Double.random(in: 0...(2 * .pi))
    }
    
    // MARK: - 分析箭着点分布
    func analyzeDistribution(hits: [ArrowHit]) -> DistributionAnalysis {
        guard !hits.isEmpty else {
            return DistributionAnalysis()
        }
        
        let distances = hits.map { $0.distanceFromCenter() }
        let averageDistance = distances.reduce(0, +) / Double(distances.count)
        let maxDistance = distances.max() ?? 0
        let minDistance = distances.min() ?? 0
        
        // 计算标准差
        let variance = distances.map { pow($0 - averageDistance, 2) }.reduce(0, +) / Double(distances.count)
        let standardDeviation = sqrt(variance)
        
        return DistributionAnalysis(
            averageDistance: averageDistance,
            maxDistance: maxDistance,
            minDistance: minDistance,
            standardDeviation: standardDeviation,
            totalHits: hits.count
        )
    }
}

// MARK: - 分布分析结果
struct DistributionAnalysis {
    let averageDistance: Double
    let maxDistance: Double
    let minDistance: Double
    let standardDeviation: Double
    let totalHits: Int
    
    init(
        averageDistance: Double = 0,
        maxDistance: Double = 0,
        minDistance: Double = 0,
        standardDeviation: Double = 0,
        totalHits: Int = 0
    ) {
        self.averageDistance = averageDistance
        self.maxDistance = maxDistance
        self.minDistance = minDistance
        self.standardDeviation = standardDeviation
        self.totalHits = totalHits
    }
    
    // 稳定性评级（基于标准差）
    var stabilityRating: String {
        switch standardDeviation {
        case 0..<1.0:
            return "优秀"
        case 1.0..<2.0:
            return "良好"
        case 2.0..<3.0:
            return "一般"
        default:
            return "需要改进"
        }
    }
}
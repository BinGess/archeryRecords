import SwiftUI
import Foundation

// MARK: - 箭靶视图组件
struct TargetView: View {
    let stats: AccuracyStats
    
    var body: some View {
        ZStack {
            // 靶环
            ForEach((1...10).reversed(), id: \.self) { ring in
                Circle()
                    .fill(targetColor(for: ring))
                    .frame(width: ringSize(for: ring))
                
                Circle()
                    .stroke(Color.black, lineWidth: 0.5)
                    .frame(width: ringSize(for: ring))
            }
            
            // 箭点
            ForEach(generateArrowPoints(stats: stats), id: \.id) { point in
                Circle()
                    .fill(point.color)
                    .frame(width: 4, height: 4)
                    .offset(point.offset)
                    .shadow(radius: 1)
            }
        }
        .frame(width: 240, height: 240)
    }
    
    private func ringSize(for ring: Int) -> CGFloat {
        CGFloat(240 - (11 - ring) * 24)
    }
    
    private func targetColor(for ring: Int) -> Color {
        let actualRing = 11 - ring
        switch actualRing {
        case 10, 9: return .yellow
        case 8, 7: return .red
        case 6, 5: return .blue
        case 4, 3, 2, 1: return .white
        default: return .white
        }
    }
}

// MARK: - 数据模型
struct TargetArrowPoint: Identifiable {
    let id = UUID()
    let offset: CGSize
    let color: Color
}

// MARK: - 工具方法
extension TargetView {
    func generateArrowPoints(stats: AccuracyStats) -> [TargetArrowPoint] {
        // 添加调试信息
        print("正在生成箭点，统计数据：")
        print("10环: \(stats.tens)")
        print("9环: \(stats.nines)")
        print("8环: \(stats.eights)")
        print("7环: \(stats.sevens)")
        print("6环: \(stats.sixs)")
        print("5环: \(stats.fives)")
        print("4环: \(stats.four)")
        print("3环: \(stats.three)")
        print("2环: \(stats.two)")
        print("1环: \(stats.one)")
       // print("其他: \(stats.others)")
        
        let totalArrows = Int(stats.tens + stats.nines + stats.eights + stats.sevens + stats.sixs + stats.fives + stats.four + stats.three + stats.two + stats.one)
        print("总箭数: \(totalArrows)")
        
        var points: [TargetArrowPoint] = []
        
        // 10环区域（半径0-12）
        points += generatePointsForRing(count: Int(stats.tens), radiusRange: 0...12, color: .black)
        // 9环区域（半径12-24）
        points += generatePointsForRing(count: Int(stats.nines), radiusRange: 12...24, color: .black)
        // 8环区域（半径24-36）
        points += generatePointsForRing(count: Int(stats.eights), radiusRange: 24...36, color: .black)
        // 7环区域（半径36-48）
        points += generatePointsForRing(count: Int(stats.sevens), radiusRange: 36...48, color: .black)
        // 6环区域（半径48-120）
        points += generatePointsForRing(count: Int(stats.sixs), radiusRange: 48...60, color: .black)
        // 5环区域（半径48-120）
        points += generatePointsForRing(count: Int(stats.fives), radiusRange: 60...72, color: .black)
        // 4环区域（半径48-120）
        points += generatePointsForRing(count: Int(stats.four), radiusRange: 72...84, color: .black)
        // 3环区域（半径48-120）
        points += generatePointsForRing(count: Int(stats.three), radiusRange: 84...96, color: .black)
        // 2环区域（半径48-120）
        points += generatePointsForRing(count: Int(stats.two), radiusRange: 86...108, color: .black)
        // 1环区域（半径48-120）
        points += generatePointsForRing(count: Int(stats.one), radiusRange: 108...120, color: .black)

        print("生成的箭点数量: \(points.count)")
        return points
    }
    
    private func generatePointsForRing(count: Int, radiusRange: ClosedRange<CGFloat>, color: Color) -> [TargetArrowPoint] {
        guard count > 0 else { return [] }
        
        print("为环区 \(radiusRange) 生成 \(count) 个箭点")
        return (0..<count).map { _ in
            let angle = Double.random(in: 0..<2 * .pi)
            let distance = Double.random(in: Double(radiusRange.lowerBound)...Double(radiusRange.upperBound))
            return TargetArrowPoint(
                offset: CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                ),
                color: color
            )
        }
    }
}

import SwiftUI
import Foundation

struct RadarChartData {
    let name: String
    let value: Double
    let color: Color
}

struct RadarChartView: View {
    let data: [RadarChartData]
    let maxValue: Double
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
            let radius = min(geometry.size.width, geometry.size.height)/2 * 0.7
            
            ZStack {
                // 使用已定义的背景网格子视图
                BackgroundGrids(center: center, radius: radius, data: data)
                
                // 使用已定义的数据层子视图
                DataLayer(center: center, radius: radius, data: data, maxValue: maxValue)
                
                // 数据点
                DataPoints(center: center, radius: radius, data: data)
                
                // 使用已定义的标签子视图
                Labels(center: center, radius: radius, data: data)
            }
        }
    }
}

// 新增数据点子视图
private struct DataPoints: View {
    let center: CGPoint
    let radius: CGFloat
    let data: [RadarChartData]
    
    var body: some View {
        ForEach(0..<data.count, id: \.self) { index in
            DataPoint(
                data: data[index],
                index: index,
                center: center,
                radius: radius,
                totalCount: data.count
            )
        }
    }
}

private struct DataPoint: View {
    let data: RadarChartData
    let index: Int
    let center: CGPoint
    let radius: CGFloat
    let totalCount: Int
    
    var body: some View {
        let angle = 2 * .pi * Double(index) / Double(totalCount) - .pi / 2
        let xPosition = center.x + cos(angle) * radius * data.value
        let yPosition = center.y + sin(angle) * radius * data.value
        
        Circle()
            .fill(data.color)
            .frame(width: 8, height: 8)
            .position(x: xPosition, y: yPosition)
    }
}

// 背景网格子视图
private struct BackgroundGrids: View {
    let center: CGPoint
    let radius: CGFloat
    let data: [RadarChartData]
    
    var body: some View {
        ForEach(0..<5) { i in
            GridPath(center: center, radius: radius, data: data, scale: Double(5 - i) / 5.0)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        }
    }
}

// 数据层子视图
private struct DataLayer: View {
    let center: CGPoint
    let radius: CGFloat
    let data: [RadarChartData]
    let maxValue: Double
    
    var body: some View {
        ZStack {
            DataPath(center: center, radius: radius, data: data, maxValue: maxValue)
                .fill(Color.blue.opacity(0.2))
            
            DataPath(center: center, radius: radius, data: data, maxValue: maxValue)
                .stroke(Color.blue, lineWidth: 2)
        }
    }
}

// 标签子视图
private struct Labels: View {
    let center: CGPoint
    let radius: CGFloat
    let data: [RadarChartData]
    
    var body: some View {
        ForEach(Array(data.enumerated()), id: \.offset) { index, item in
            LabelView(
                text: item.name,
                center: center,
                radius: radius,
                index: index,
                totalCount: data.count
            )
        }
    }
}

private struct LabelView: View {
    let text: String
    let center: CGPoint
    let radius: CGFloat
    let index: Int
    let totalCount: Int
    
    var body: some View {
        let angle = angleForIndex(index: index, total: totalCount)
        let xOffset = cos(angle) * (radius + 20)
        let yOffset = sin(angle) * (radius + 20)
        let position = CGPoint(
            x: center.x + CGFloat(xOffset),
            y: center.y + CGFloat(yOffset)
        )
        
        Text(text)
            .font(.caption)
            .position(position)
    }
    
    private func angleForIndex(index: Int, total: Int) -> Double {
        return Double(index) * 2 * .pi / Double(total) - .pi / 2
    }
}

// 网格路径
private struct GridPath: Shape {
    let center: CGPoint
    let radius: CGFloat
    let data: [RadarChartData]
    let scale: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let pointCount = data.count
        
        for j in 0..<pointCount {
            let angle = angleForIndex(index: j, total: pointCount)
            let scaledRadius = radius * scale
            let xOffset = cos(angle) * scaledRadius
            let yOffset = sin(angle) * scaledRadius
            
            let point = CGPoint(
                x: center.x + CGFloat(xOffset),
                y: center.y + CGFloat(yOffset)
            )
            
            if j == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
    
    private func angleForIndex(index: Int, total: Int) -> Double {
        return Double(index) * 2 * .pi / Double(total) - .pi / 2
    }
}

// 数据路径
private struct DataPath: Shape {
    let center: CGPoint
    let radius: CGFloat
    let data: [RadarChartData]
    let maxValue: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for (i, item) in data.enumerated() {
            let angle = Double(i) * 2 * .pi / Double(data.count) - .pi / 2
            let scale = item.value / maxValue
            
            // 明确使用 Foundation 的三角函数
            let xOffset = CGFloat(Darwin.cos(angle) * radius * scale)
            let yOffset = CGFloat(Darwin.sin(angle) * radius * scale)
            
            let point = CGPoint(
                x: center.x + xOffset,
                y: center.y + yOffset
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
} 

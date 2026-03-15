//
//  InteractiveTargetView.swift
//  archeryRecord
//
//  可交互的射箭靶面组件，支持点击标记箭着点
//

import SwiftUI

// MARK: - 可交互靶面视图
struct InteractiveTargetView: View {
    let targetFace: TargetFace
    let size: CGSize
    @Binding var arrowHits: [ArrowHit]
    let currentGroup: Int
    let currentArrowIndex: Int
    let onArrowHit: (ArrowHit) -> Void
    
    @State private var showingOverlapAlert = false
    @State private var pendingHit: ArrowHit?
    @State private var suggestedOffset: CGPoint?
    
    init(
        targetFace: TargetFace,
        size: CGSize = CGSize(width: 300, height: 300),
        arrowHits: Binding<[ArrowHit]>,
        currentGroup: Int,
        currentArrowIndex: Int,
        onArrowHit: @escaping (ArrowHit) -> Void
    ) {
        self.targetFace = targetFace
        self.size = size
        self._arrowHits = arrowHits
        self.currentGroup = currentGroup
        self.currentArrowIndex = currentArrowIndex
        self.onArrowHit = onArrowHit
    }
    
    var body: some View {
        ZStack {
            // 靶面背景
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: size.width, height: size.height)
            
            // 绘制靶环（从外到内）
            ForEach(targetFace.rings.sorted(by: { $0.outerRadius > $1.outerRadius }), id: \.ringNumber) { ring in
                InteractiveTargetRingView(
                    ring: ring,
                    targetFace: targetFace,
                    containerSize: size,
                    onTapped: { position in
                        handleTargetTap(at: position)
                    }
                )
            }
            
            // 显示已有的箭着点
            ForEach(arrowHits.indices, id: \.self) { index in
                let hit = arrowHits[index]
                ArrowHitMarker(
                    hit: hit,
                    containerSize: size,
                    targetFace: targetFace,
                    index: index + 1
                )
            }
            
            // 显示建议的偏移位置
            if let offset = suggestedOffset {
                let maxRadius = size.width / 2
                let targetRadius = targetFace.diameter / 2
                let scaleFactor = maxRadius / targetRadius
                
                Circle()
                    .fill(Color.orange.opacity(0.5))
                    .frame(width: 12, height: 12)
                    .position(
                        x: size.width/2 + offset.x * scaleFactor,
                        y: size.height/2 + offset.y * scaleFactor
                    )
                    .animation(.easeInOut(duration: 0.3), value: suggestedOffset)
            }
            
            // 中心点
            Circle()
                .fill(Color.black)
                .frame(width: 4, height: 4)
        }
        .frame(width: size.width, height: size.height)
        .alert("箭支重叠", isPresented: $showingOverlapAlert) {
            Button("使用建议位置") {
                if let hit = pendingHit, let offset = suggestedOffset {
                    let adjustedHit = ArrowHit(
                        position: CGPoint(x: hit.position.x + offset.x, y: hit.position.y + offset.y),
                        score: hit.score,
                        ringNumber: hit.ringNumber,
                        timestamp: hit.timestamp,
                        groupIndex: hit.groupIndex,
                        arrowIndex: hit.arrowIndex,
                        targetFaceType: hit.targetFaceType,
                        isOverlapped: true
                    )
                    onArrowHit(adjustedHit)
                }
                clearPendingState()
            }
            Button("保持原位置") {
                if let hit = pendingHit {
                    let overlappedHit = ArrowHit(
                        position: hit.position,
                        score: hit.score,
                        ringNumber: hit.ringNumber,
                        timestamp: hit.timestamp,
                        groupIndex: hit.groupIndex,
                        arrowIndex: hit.arrowIndex,
                        targetFaceType: hit.targetFaceType,
                        isOverlapped: true
                    )
                    onArrowHit(overlappedHit)
                }
                clearPendingState()
            }
            Button("取消", role: .cancel) {
                clearPendingState()
            }
        } message: {
            Text("检测到箭支重叠，建议使用偏移位置以便区分。")
        }
    }
    
    // MARK: - 处理靶面点击
    private func handleTargetTap(at position: CGPoint) {
        // 计算点击位置到中心的距离（厘米单位）
        let radius = sqrt(position.x * position.x + position.y * position.y)
        
        // 根据半径找到对应的环
        let hitRing = findRingByRadius(radius)
        
        // 创建箭着点
        let hit = ArrowHit(
            position: position,
            score: hitRing.score,
            ringNumber: hitRing.ringNumber,
            timestamp: Date(),
            groupIndex: currentGroup,
            arrowIndex: currentArrowIndex,
            targetFaceType: targetFace.type
        )
        
        // 检测重叠
        let manager = ArrowHitManager()
        let overlapResult = manager.detectOverlap(newHit: hit, existingHits: arrowHits)
        
        if overlapResult.isOverlapped {
            // 显示重叠处理选项
            pendingHit = hit
            suggestedOffset = overlapResult.suggestedOffset
            showingOverlapAlert = true
        } else {
            // 直接添加箭着点
            onArrowHit(hit)
        }
    }
    
    // 根据半径找到对应的环
    private func findRingByRadius(_ radius: Double) -> TargetRing {
        // 按照从内到外的顺序检查环
        for ring in targetFace.rings.sorted(by: { $0.outerRadius < $1.outerRadius }) {
            if radius <= ring.outerRadius {
                return ring
            }
        }
        // 如果超出所有环，返回最外层环
        return targetFace.rings.max(by: { $0.outerRadius < $1.outerRadius }) ?? targetFace.rings.first!
    }
    
    private func clearPendingState() {
        pendingHit = nil
        suggestedOffset = nil
    }
}

// MARK: - 可交互靶环视图
struct InteractiveTargetRingView: View {
    let ring: TargetRing
    let targetFace: TargetFace
    let containerSize: CGSize
    let onTapped: (CGPoint) -> Void
    
    private var ringRadius: Double {
        let maxRadius = containerSize.width / 2
        return (ring.outerRadius / (targetFace.diameter / 2)) * maxRadius
    }
    
    private var ringColor: Color {
        return targetFace.getRingColor(for: ring.ringNumber)
    }
    
    var body: some View {
        Circle()
            .fill(ringColor)
            .frame(width: ringRadius * 2, height: ringRadius * 2)
            .overlay(
                Circle()
                    .stroke(Color.black, lineWidth: 1)
            )
            .overlay(
                // 分数标签
                Text(ring.displayScore)
                    .font(.system(size: min(ringRadius * 0.3, 16), weight: .bold))
                    .foregroundColor(ringColor == .white || ringColor == .yellow ? .black : .white)
            )
            .contentShape(Circle())
            .onTapGesture { location in
                // 将点击位置转换为相对于靶面中心的坐标（厘米单位）
                // location是相对于当前圆环视图的坐标，需要转换为相对于容器中心的坐标
                let ringCenterX = ringRadius
                let ringCenterY = ringRadius
                
                // 计算相对于圆环中心的像素坐标
                let pixelX = location.x - ringCenterX
                let pixelY = location.y - ringCenterY
                
                // 转换为厘米坐标（考虑缩放因子）
                let maxRadius = containerSize.width / 2
                let targetRadius = targetFace.diameter / 2
                let scaleFactor = targetRadius / maxRadius
                
                let relativePosition = CGPoint(
                    x: pixelX * scaleFactor,
                    y: pixelY * scaleFactor
                )
                onTapped(relativePosition)
            }
    }
}

// MARK: - 箭着点标记
struct ArrowHitMarker: View {
    let hit: ArrowHit
    let containerSize: CGSize
    let targetFace: TargetFace
    let index: Int
    
    private var markerPosition: CGPoint {
        let centerX = containerSize.width / 2
        let centerY = containerSize.height / 2
        
        // 将厘米坐标转换为像素坐标
        let maxRadius = containerSize.width / 2
        let targetRadius = targetFace.diameter / 2
        let scaleFactor = maxRadius / targetRadius
        
        return CGPoint(
            x: centerX + hit.position.x * scaleFactor,
            y: centerY + hit.position.y * scaleFactor
        )
    }
    
    var body: some View {
        ZStack {
            // 箭着点圆圈
            Circle()
                .fill(hit.isOverlapped ? Color.orange : Color.red)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            // 箭序号
            Text("\(index)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .position(markerPosition)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: markerPosition)
    }
}

// MARK: - 预览
#Preview {
    if let targetFace = TargetFaceManager.shared.getTarget(for: .full80cm) {
        InteractiveTargetView(
            targetFace: targetFace,
            arrowHits: .constant([]),
            currentGroup: 1,
            currentArrowIndex: 1
        ) { hit in
            print("Arrow hit: \(hit)")
        }
        .padding()
    }
}
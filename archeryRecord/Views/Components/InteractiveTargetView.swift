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
        let metrics = targetFace.layoutMetrics(in: size)
        
        return ZStack {
            ForEach(metrics.spotCentersCm.indices, id: \.self) { index in
                InteractiveTargetSpotView(
                    targetFace: targetFace,
                    metrics: metrics,
                    spotCenterCm: metrics.spotCentersCm[index]
                )
            }
            
            ForEach(Array(arrowHits.enumerated()), id: \.element.id) { index, hit in
                if hit.ringNumber > 0 {
                    ArrowHitMarker(
                        hit: hit,
                        metrics: metrics,
                        index: index + 1
                    )
                }
            }
            
            if let hit = pendingHit, let offset = suggestedOffset {
                Circle()
                    .fill(Color.orange.opacity(0.45))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1.5)
                    )
                    .position(
                        metrics.pointInView(
                            from: CGPoint(
                                x: hit.position.x + offset.x,
                                y: hit.position.y + offset.y
                            )
                        )
                    )
                    .animation(.easeInOut(duration: 0.25), value: suggestedOffset)
            }
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    handleTargetTap(at: metrics.pointInCentimeters(from: value.location))
                }
        )
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
        let resolvedHit = targetFace.resolveHit(at: position)
        
        let hit = ArrowHit(
            position: resolvedHit.position,
            score: resolvedHit.score,
            ringNumber: resolvedHit.ringNumber,
            timestamp: Date(),
            groupIndex: currentGroup,
            arrowIndex: currentArrowIndex,
            targetFaceType: targetFace.type
        )
        
        guard !resolvedHit.isMiss else {
            onArrowHit(hit)
            return
        }
        
        let manager = ArrowHitManager()
        let overlapResult = manager.detectOverlap(newHit: hit, existingHits: arrowHits)
        
        if overlapResult.isOverlapped {
            pendingHit = hit
            suggestedOffset = overlapResult.suggestedOffset
            showingOverlapAlert = true
        } else {
            onArrowHit(hit)
        }
    }
    
    private func clearPendingState() {
        pendingHit = nil
        suggestedOffset = nil
    }
}

private struct InteractiveTargetSpotView: View {
    let targetFace: TargetFace
    let metrics: TargetLayoutMetrics
    let spotCenterCm: CGPoint
    
    var body: some View {
        let spotCenter = metrics.pointInView(from: spotCenterCm)
        
        return ZStack {
            ForEach(targetFace.rings.sorted(by: { $0.outerRadius > $1.outerRadius }), id: \.ringNumber) { ring in
                Circle()
                    .fill(targetFace.getRingColor(for: ring.ringNumber))
                    .frame(
                        width: CGFloat(ring.outerRadius * 2) * metrics.scale,
                        height: CGFloat(ring.outerRadius * 2) * metrics.scale
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.18), lineWidth: 1)
                    )
                    .position(spotCenter)
            }
            
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: metrics.centerDotSize, height: metrics.centerDotSize)
                .position(spotCenter)
        }
    }
}

// MARK: - 箭着点标记
struct ArrowHitMarker: View {
    let hit: ArrowHit
    let metrics: TargetLayoutMetrics
    let index: Int
    
    private var markerPosition: CGPoint {
        metrics.pointInView(from: hit.position)
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

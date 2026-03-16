//
//  TargetFaceView.swift
//  archeryRecord
//
//  射箭靶面UI组件
//

import SwiftUI

// MARK: - 靶面显示组件
struct TargetFaceView: View {
    let targetFace: TargetFace
    let size: CGSize
    let showLabels: Bool
    let interactive: Bool
    let onRingTapped: ((Int) -> Void)?
    
    init(
        targetFace: TargetFace,
        size: CGSize = CGSize(width: 200, height: 200),
        showLabels: Bool = true,
        interactive: Bool = false,
        onRingTapped: ((Int) -> Void)? = nil
    ) {
        self.targetFace = targetFace
        self.size = size
        self.showLabels = showLabels
        self.interactive = interactive
        self.onRingTapped = onRingTapped
    }
    
    var body: some View {
        let metrics = targetFace.layoutMetrics(in: size)
        
        return ZStack {
            ForEach(Array(metrics.spotCentersCm.enumerated()), id: \.offset) { index, spotCenter in
                TargetSpotView(
                    targetFace: targetFace,
                    metrics: metrics,
                    spotCenterCm: spotCenter,
                    showLabel: showLabels && metrics.spotCentersCm.count == 1 && index == 0
                )
            }
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    guard interactive else { return }
                    let pointCm = metrics.pointInCentimeters(from: value.location)
                    let hit = targetFace.resolveHit(at: pointCm)
                    onRingTapped?(hit.ringNumber)
                }
        )
    }
}

private struct TargetSpotView: View {
    let targetFace: TargetFace
    let metrics: TargetLayoutMetrics
    let spotCenterCm: CGPoint
    let showLabel: Bool
    
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
            
            if showLabel {
                VStack(spacing: 4) {
                    ForEach(targetFace.rings.sorted(by: { $0.ringNumber > $1.ringNumber }), id: \.ringNumber) { ring in
                        Text(ring.displayScore)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(ring.color == "white" ? .black : .white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(targetFace.getRingColor(for: ring.ringNumber))
                            .clipShape(Capsule())
                    }
                }
                .position(
                    x: min(spotCenter.x + CGFloat(targetFace.diameter / 2) * metrics.scale + 18, metrics.containerSize.width - 14),
                    y: spotCenter.y
                )
            }
        }
    }
}

// MARK: - 靶面选择器
struct TargetFaceSelector: View {
    @Binding var selectedTargetType: String
    @StateObject private var targetManager = TargetFaceManager.shared
    @State private var showingTargetSheet = false
    
    var body: some View {
        Button(action: { showingTargetSheet = true }) {
            HStack {
                // 靶面预览
                if let targetFace = targetManager.getTarget(for: selectedTargetType) {
                    TargetFaceView(
                        targetFace: targetFace,
                        size: CGSize(width: 40, height: 40),
                        showLabels: false
                    )
                } else {
                    Image(systemName: "target")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("靶面类型")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(TargetTypeDisplay.primaryTitle(for: selectedTargetType))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            #if os(iOS)
            .background(Color(.systemGray6))
            #else
            .background(Color.gray.opacity(0.2))
            #endif
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingTargetSheet) {
            TargetFaceSelectionSheet(
                selectedTargetType: $selectedTargetType,
                isPresented: $showingTargetSheet
            )
        }
    }
}

// MARK: - 靶面选择表单
struct TargetFaceSelectionSheet: View {
    @Binding var selectedTargetType: String
    @Binding var isPresented: Bool
    @StateObject private var targetManager = TargetFaceManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(targetManager.availableTargets, id: \.id) { targetFace in
                        TargetFaceCard(
                            targetFace: targetFace,
                            isSelected: selectedTargetType == targetFace.type.rawValue,
                            onSelect: {
                                selectedTargetType = targetFace.type.rawValue
                                isPresented = false
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("选择靶面类型")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
            #endif
        }
    }
}

// MARK: - 靶面卡片
struct TargetFaceCard: View {
    let targetFace: TargetFace
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // 靶面预览
                TargetFaceView(
                    targetFace: targetFace,
                    size: CGSize(width: 120, height: 120),
                    showLabels: true
                )
                
                // 靶面信息
                VStack(spacing: 4) {
                    Text(TargetTypeDisplay.primaryTitle(for: targetFace.type.rawValue))
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let subtitle = TargetTypeDisplay.subtitle(for: targetFace.type.rawValue) {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(targetFace.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Text("直径: \(Int(targetFace.diameter))cm")
                        Spacer()
                        Text("\(targetFace.rings.count)环")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            #if os(iOS)
            .background(Color(.systemBackground))
            #else
            .background(Color.white)
            #endif
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 靶面信息视图
struct TargetFaceInfoView: View {
    let targetFace: TargetFace
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 靶面预览
            HStack {
                Spacer()
                TargetFaceView(
                    targetFace: targetFace,
                    size: CGSize(width: 200, height: 200),
                    showLabels: true
                )
                Spacer()
            }
            
            // 基本信息
            VStack(alignment: .leading, spacing: 8) {
                Text("基本信息")
                    .font(.headline)
                
                InfoRow(label: "类型", value: targetFace.type.rawValue)
                InfoRow(label: "直径", value: "\(Int(targetFace.diameter))cm")
                InfoRow(label: "环数", value: "\(targetFace.rings.count)环")
                InfoRow(label: "分值范围", value: "\(targetFace.minScore)-\(targetFace.maxScore)分")
                InfoRow(label: "金环数", value: "\(targetFace.goldRingCount)个")
            }
            
            // 环分布
            VStack(alignment: .leading, spacing: 8) {
                Text("环分布")
                    .font(.headline)
                
                ForEach(targetFace.rings.sorted(by: { $0.ringNumber > $1.ringNumber }), id: \.ringNumber) { ring in
                    HStack {
                        Circle()
                            .fill(targetFace.getRingColor(for: ring.ringNumber))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle().stroke(Color.black, lineWidth: 1)
                            )
                        
                        Text("\(ring.ringNumber)环")
                            .font(.system(size: 14))
                        
                        Spacer()
                        
                        Text("\(ring.score)分")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - 信息行组件
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 20) {
        if let target = TargetFaceManager.shared.getTarget(for: .full80cm) {
            TargetFaceView(targetFace: target)
            TargetFaceInfoView(targetFace: target)
        }
    }
    .padding()
}

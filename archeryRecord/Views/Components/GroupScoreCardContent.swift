import SwiftUI

struct GroupScoreCardContent: View {
    let groupIndex: Int
    let groupScores: [String]
    @Binding var selectedGroupIndex: Int
    @Binding var selectedScoreIndex: Int
    let inputMode: InputMode
    let targetFaceType: TargetFaceType
    @Binding var groupArrowHits: [ArrowHit]
    let onScoreSelected: (Int) -> Void
    let onVisualTargetInput: (Int, Int, ArrowHit) -> Void
    let onAddGroup: () -> Void
    let isLastGroup: Bool
    let groupScore: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("第\(groupIndex + 1)组")
                        .font(.headline)
                    Spacer()
                    Text("得分: \(groupScore)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.purple)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // 成绩输入网格
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                    spacing: 12
                ) {
                    ForEach(0..<groupScores.count, id: \.self) { index in
                        Button {
                            onScoreSelected(index)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedGroupIndex == groupIndex && selectedScoreIndex == index ? 
                                          Color.purple.opacity(0.1) : Color.gray.opacity(0.05))
                                    .frame(height: 50)
                                
                                if groupScores[index].isEmpty {
                                    Text("\(index + 1).")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray.opacity(0.5))
                                } else {
                                    Text(groupScores[index])
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                }
                .padding([.horizontal, .bottom], 16)
                
                // 可视化靶面输入（仅在靶面模式下显示）
                if inputMode == .visualTarget {
                    VisualTargetInputView(
                        targetFaceType: targetFaceType,
                        selectedScoreIndex: selectedScoreIndex,
                        groupIndex: groupIndex,
                        groupArrowHits: $groupArrowHits,
                        onVisualTargetInput: onVisualTargetInput
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedGroupIndex == groupIndex ? 
                            Color.purple.opacity(0.3) : Color.clear, 
                            lineWidth: 1.5)
                    .padding(1)
            )
            .padding(.horizontal, 16)
            
            // 添加新组按钮（仅在最后一组显示）
            if isLastGroup {
                Button(action: onAddGroup) {
                    HStack {
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.purple)
                        Text("再来一组")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.purple)
                        Spacer()
                    }
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
}
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
                    Text(L10n.Completion.groupLabel(groupIndex + 1))
                        .sharedTextStyle(SharedStyles.Text.title)
                    Spacer()
                    Text(L10n.GroupDetail.groupScore(groupScore))
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryColor)
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
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        selectedGroupIndex == groupIndex && selectedScoreIndex == index
                                        ? SharedStyles.primaryColor.opacity(0.14)
                                        : SharedStyles.groupBackgroundColor
                                    )
                                    .frame(height: 50)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(
                                                selectedGroupIndex == groupIndex && selectedScoreIndex == index
                                                ? SharedStyles.primaryColor.opacity(0.35)
                                                : Color.white.opacity(0.55),
                                                lineWidth: 1
                                            )
                                    }
                                
                                if groupScores[index].isEmpty {
                                    Text("\(index + 1).")
                                        .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.tertiaryTextColor)
                                } else {
                                    Text(groupScores[index])
                                        .sharedTextStyle(SharedStyles.Text.title, color: SharedStyles.primaryTextColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
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
            .clayCard(tint: SharedStyles.Accent.sky, radius: 18)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        selectedGroupIndex == groupIndex
                        ? SharedStyles.primaryColor.opacity(0.26)
                        : Color.clear,
                        lineWidth: 1.2
                    )
                    .padding(1)
            )
            .padding(.horizontal, 16)
            
            // 添加新组按钮（仅在最后一组显示）
            if isLastGroup {
                Button(action: onAddGroup) {
                    HStack {
                        Spacer()
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SharedStyles.primaryColor)
                        Text(L10n.Completion.groupAgain)
                            .sharedTextStyle(SharedStyles.Text.bodyEmphasis, color: SharedStyles.primaryColor)
                        Spacer()
                    }
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(SharedStyles.groupBackgroundColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(SharedStyles.primaryColor.opacity(0.18), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
}

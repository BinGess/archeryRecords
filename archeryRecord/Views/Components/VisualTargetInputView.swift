import SwiftUI
import Foundation

struct VisualTargetInputView: View {
    let targetFaceType: TargetFaceType
    let selectedScoreIndex: Int
    let groupIndex: Int
    @Binding var groupArrowHits: [ArrowHit]
    let onVisualTargetInput: (Int, Int, ArrowHit) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if let targetFace = TargetFaceManager.shared.getTarget(for: targetFaceType) {
                InteractiveTargetView(
                    targetFace: targetFace,
                    arrowHits: $groupArrowHits,
                    currentGroup: groupIndex,
                    currentArrowIndex: selectedScoreIndex,
                    onArrowHit: { hit in
                        onVisualTargetInput(groupIndex, selectedScoreIndex, hit)
                    }
                )
                .frame(height: 300)
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 16)
    }
}
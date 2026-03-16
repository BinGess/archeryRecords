import SwiftUI

struct GroupScoreSectionView: View {
    let groupIndex: Int
    let scores: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.Completion.groupLabel(groupIndex + 1))
                    .font(SharedStyles.Text.subtitle)
                    .foregroundColor(SharedStyles.secondaryColor)
                Spacer()
                Text(L10n.GroupDetail.groupScore(scores.calculateScore()))
                    .font(SharedStyles.Text.body)
                    .foregroundColor(SharedStyles.primaryColor)
            }
            .padding(.horizontal)
            
            ScoreGrid(scores: scores, columns: 3, showIndex: false)
        }
    }
} 

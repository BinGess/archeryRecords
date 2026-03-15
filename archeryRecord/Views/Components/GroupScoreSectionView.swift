import SwiftUI

struct GroupScoreSectionView: View {
    let groupIndex: Int
    let scores: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("第\(groupIndex + 1)组")
                    .font(SharedStyles.Text.subtitle)
                    .foregroundColor(SharedStyles.secondaryColor)
                Spacer()
                Text("得分：\(scores.calculateScore())")
                    .font(SharedStyles.Text.body)
                    .foregroundColor(SharedStyles.primaryColor)
            }
            .padding(.horizontal)
            
            ScoreGrid(scores: scores, columns: 3, showIndex: false)
        }
    }
} 
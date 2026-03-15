import SwiftUI
import Charts

// 详情页面的基础卡片组件
struct DetailCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: SharedStyles.itemSpacing) {
            Text(title)
                .font(SharedStyles.Text.title)
                .padding(.horizontal)
            
            content
        }
        .padding(.vertical, SharedStyles.Spacing.medium)
        .background(SharedStyles.backgroundColor)
        .cornerRadius(SharedStyles.cornerRadius)
        .shadow(
            color: SharedStyles.Shadow.light,
            radius: 8,
            x: 0,
            y: 2
        )
        .padding(.horizontal)
        .contentShape(Rectangle())  // 确保整个卡片可点击
    }
}

// 基本信息行组件
struct DetailInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(SharedStyles.primaryColor)
            Text(text)
                .font(SharedStyles.Text.body)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

// 分数网格组件
struct ScoreGrid: View {
    let scores: [String]
    let columns: Int
    let showIndex: Bool
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns),
            spacing: 12
        ) {
            ForEach(0..<scores.count, id: \.self) { index in
                VStack(spacing: 4) {
                    if showIndex {
                        Text("\(index + 1)")
                            .font(SharedStyles.Text.caption)
                            .foregroundColor(SharedStyles.secondaryColor)
                    }
                    
                    Text(scores[index])
                        .font(.system(size: 16, weight: .medium))
                        .frame(height: 36)
                        .frame(maxWidth: .infinity)
                        .background(scoreBackground(for: scores[index]))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func scoreBackground(for score: String) -> Color {
        if score == "X" || score == "10" {
            return .yellow.opacity(0.15)
        } else if score == "9" {
            return .orange.opacity(0.15)
        } else if score == "8" {
            return .red.opacity(0.15)
        }
        return .gray.opacity(0.1)
    }
}

// 总分显示组件
struct TotalScoreView: View {
    let score: Int
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(score)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(SharedStyles.primaryColor)
            Text(L10n.Content.score)
                .font(SharedStyles.Text.caption)
                .foregroundColor(SharedStyles.secondaryColor)
        }
    }
}

// 添加底部按钮组件
struct DetailBottomButtons: View {
    @Binding var showDeleteAlert: Bool
    let onRecordAgain: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                showDeleteAlert = true
            }) {
                Text(L10n.Detail.deleteRecord)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red)
                    .cornerRadius(SharedStyles.cornerRadius)
            }
            
            Button(action: onRecordAgain) {
                Text(L10n.Detail.recordAgain)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(SharedStyles.primaryColor)
                    .cornerRadius(SharedStyles.cornerRadius)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white)
        .shadow(color: SharedStyles.Shadow.light, radius: 4, y: -2)
    }
}

// 添加分数分布图表组件
struct ScoreDistributionChart: View {
    let scores: [String]
    
    var body: some View {
        Chart {
            ForEach(getScoreDistribution()) { item in
                BarMark(
                    x: .value(L10n.Analysis.score, item.score),
                    y: .value(L10n.Analysis.count, item.count)
                )
                .foregroundStyle(getBarColor(for: item.score))
            }
        }
        .chartXAxis {
            AxisMarks(values: getScoreDistribution().map { $0.score }) { value in
                AxisValueLabel()
                    .font(SharedStyles.Text.caption)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(SharedStyles.Text.caption)
            }
        }
    }
    
    private func getScoreDistribution() -> [ScoreDistribution] {
        var distribution: [String: Int] = [:]
        let allScores = ["X", "10", "9", "8", "7", "6", "5", "4", "3", "2", "1", "M"]
        
        for score in allScores {
            distribution[score] = 0
        }
        
        for score in scores {
            distribution[score, default: 0] += 1
        }
        
        return allScores.map { score in
            ScoreDistribution(score: score, count: distribution[score] ?? 0)
        }
    }
    
    private func getBarColor(for score: String) -> Color {
        switch score {
        case "X", "10": return .yellow
        case "9": return .orange
        case "8": return .red
        default: return .gray
        }
    }
}

struct ScoreDistribution: Identifiable {
    let id = UUID()  // 添加 Identifiable 协议支持
    let score: String
    let count: Int
}

// 删除这些重复的扩展定义（第210-228行）
// 添加日期格式化工具
extension Date {
    func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = L10n.Format.dateTime
        return formatter.string(from: self)
    }
}

// 添加分数计算工具
//extension Array where Element == String {
//    func calculateScore() -> Int {
//        reduce(0) { sum, score in
//            if score == "X" { return sum + 10 }
//            if score == "M" { return sum + 0 }
//            return sum + (Int(score) ?? 0)
//        }
//    }
//}

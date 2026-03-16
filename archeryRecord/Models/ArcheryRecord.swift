import Foundation

struct ArcheryRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let bowType: String
    let distance: String
    let targetType: String
    let scores: [String]
    let date: Date
    let numberOfArrows: Int


     var totalScore: Int {
        return scores.compactMap { score -> Int? in
            if score == "X" { return 10 }
            if score == "M" { return 0 }
            return Int(score)
        }.reduce(0, +)
    }
    
    func getScore(_ index: Int) -> Int {
        guard index < scores.count else { return 0 }
        if scores[index] == "X" { return 10 }
        if scores[index] == "M" { return 0 }
        return Int(scores[index]) ?? 0
    }
}

import Foundation

struct ArcheryGroupRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let bowType: String
    let distance: String
    let targetType: String
    let groupScores: [[String]]
    let date: Date
    let numberOfGroups: Int
    let arrowsPerGroup: Int
    let groupArrowHits: [[ArrowHit]]? // 存储实际箭着点数据，可选字段用于向后兼容
    
    // 初始化方法，支持带或不带ArrowHit数据
    init(id: UUID = UUID(), bowType: String, distance: String, targetType: String, 
         groupScores: [[String]], date: Date = Date(), numberOfGroups: Int, 
         arrowsPerGroup: Int, groupArrowHits: [[ArrowHit]]? = nil) {
        self.id = id
        self.bowType = bowType
        self.distance = distance
        self.targetType = targetType
        self.groupScores = groupScores
        self.date = date
        self.numberOfGroups = numberOfGroups
        self.arrowsPerGroup = arrowsPerGroup
        self.groupArrowHits = groupArrowHits
    }
    
    var totalScore: Int {
        return groupScores.flatMap { group in
            group.compactMap { score -> Int? in
                if score == "X" { return 10 }
                if score == "M" { return 0 }
                return Int(score)
            }
        }.reduce(0, +)
    }
    
    func getGroupScore(_ groupIndex: Int) -> Int {
        return groupScores[groupIndex].compactMap { score -> Int? in
            if score == "X" { return 10 }
            if score == "M" { return 0 }
            return Int(score)
        }.reduce(0, +)
    }

    static func == (lhs: ArcheryGroupRecord, rhs: ArcheryGroupRecord) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

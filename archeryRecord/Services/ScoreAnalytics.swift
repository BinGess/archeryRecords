import Foundation
import SwiftUI
import Charts

struct ScoreData {
    let date: Date
    let score: Double
}

struct StabilityData {
    let date: Date
    let standardDeviation: Double
}

struct AccuracyStats {
    let tens: Double
    let nines: Double
    let eights: Double
    let sevens: Double
    let sixs: Double
    let fives: Double
    let four: Double
    let three: Double
    let two: Double
    let one: Double

    var totalHits: Double {
        tens + nines + eights + sevens + sixs + fives + four + three + two + one
    }

    var topThreeRate: Double {
        guard totalHits > 0 else { return 0 }
        return (tens + nines + eights) / totalHits * 100
    }
}

struct StabilityStats {
    let avg: Double
    let max: Int
    let min: Int
}

struct StabilityResult {
    let stabilityData: [StabilityData]
    let stats: StabilityStats
}

struct ComprehensiveStats {
    let averageScore: Double
    let stabilityLevel: Double
    let accuracyRate: Double
    let consistencyRate: Double
    let totalShots: Int
    let recentTrend: Double // 最近趋势变化率
}

struct ArcheryAnalytics {
    let averageRing: Double
    let stabilityScore: Double
    let fatigueIndex: Double
    let tenRingRate: Double
    let xRingCount: Int
    let tenRingCount: Int
    let nineRingCount: Int
    let totalArrows: Int
}

struct AggregateAccuracySummary {
    let averageScore: Double
    let tenRingRate: Double
    let spreadRadius: Double
    let groupTightness: String
    let accuracyGrade: String
    let xRingCount: Int
    let tenRingCount: Int
    let nineRingCount: Int
}

enum TrendMomentum {
    case rising
    case stable
    case falling

    var localizedLabel: String {
        switch self {
        case .rising:
            return L10n.tr("analysis_momentum_rising")
        case .stable:
            return L10n.tr("analysis_momentum_stable")
        case .falling:
            return L10n.tr("analysis_momentum_falling")
        }
    }

    var symbolName: String {
        switch self {
        case .rising:
            return "arrow.up.right"
        case .stable:
            return "arrow.left.and.right"
        case .falling:
            return "arrow.down.right"
        }
    }

    var color: Color {
        switch self {
        case .rising:
            return .green
        case .stable:
            return .orange
        case .falling:
            return .red
        }
    }
}

struct ScoreTrendSummary {
    let points: [ScoreData]
    let rollingAveragePoints: [ScoreData]
    let overallAverage: Double
    let latestAverage: Double
    let recentAverage: Double
    let baselineAverage: Double
    let recentChangePercent: Double
    let bestAverage: Double
    let sessionCount: Int
    let recentWindowCount: Int
    let baselineWindowCount: Int
    let momentum: TrendMomentum
    let insight: TrendInsight

    var hasEnoughHistory: Bool {
        sessionCount > 1 && baselineWindowCount > 0
    }
}

struct TrendInsight {
    let title: String
    let message: String
}

enum ImpactDirection: String {
    case centered
    case upperLeft
    case upperRight
    case lowerLeft
    case lowerRight

    var localizedLabel: String {
        switch self {
        case .centered:
            return L10n.tr("analysis_direction_centered")
        case .upperLeft:
            return L10n.tr("analysis_direction_upper_left")
        case .upperRight:
            return L10n.tr("analysis_direction_upper_right")
        case .lowerLeft:
            return L10n.tr("analysis_direction_lower_left")
        case .lowerRight:
            return L10n.tr("analysis_direction_lower_right")
        }
    }

    var symbolName: String {
        switch self {
        case .centered:
            return "scope"
        case .upperLeft:
            return "arrow.up.left"
        case .upperRight:
            return "arrow.up.right"
        case .lowerLeft:
            return "arrow.down.left"
        case .lowerRight:
            return "arrow.down.right"
        }
    }
}

struct ImpactPoint: Identifiable {
    let id: UUID
    let position: CGPoint
    let score: Int
    let ringNumber: Int
}

struct ImpactQuadrantSummary: Identifiable {
    let direction: ImpactDirection
    let count: Int
    let percentage: Double

    var id: String { direction.rawValue }
}

struct ImpactInsight: Identifiable {
    let id: String
    let symbolName: String
    let title: String
    let message: String
}

struct AnalysisArrowPoint: Identifiable {
    let id: UUID
    let offset: CGSize
    let color: Color
}

struct ImpactAnalysisSummary {
    let targetFace: TargetFace?
    let targetTypeName: String?
    let scopeDescription: String?
    let totalHits: Int
    let groupingRadius95: Double
    let centerOffset: Double
    let averageDistanceFromCenter: Double
    let centroid: CGPoint
    let hasRealData: Bool
    let biasDirection: ImpactDirection
    let dominantQuadrantRate: Double
    let points: [ImpactPoint]
    let quadrants: [ImpactQuadrantSummary]
    let insights: [ImpactInsight]

    var hasData: Bool {
        totalHits > 0 && !points.isEmpty
    }
}

class ScoreAnalytics {
    static func filterRecords(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord], timeRange: Int) -> (records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord]) {
        let calendar = Calendar.current
        let now = Date()

        let filteredRecords = records.filter { record in
            switch timeRange {
            case 0:
                return calendar.isDateInToday(record.date)
            case 1:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .weekOfYear)
            case 2:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .month)
            case 3:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .year)
            default:
                return true
            }
        }

        let filteredGroupRecords = groupRecords.filter { record in
            switch timeRange {
            case 0:
                return calendar.isDateInToday(record.date)
            case 1:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .weekOfYear)
            case 2:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .month)
            case 3:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .year)
            default:
                return true
            }
        }

        return (filteredRecords, filteredGroupRecords)
    }

    static func processScores(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord], timeRange: Int) -> [ScoreData] {
        let filteredData = filterRecords(records: records, groupRecords: groupRecords, timeRange: timeRange)
        let filteredRecords = filteredData.records
        let filteredGroupRecords = filteredData.groupRecords
        
        var scoreData: [ScoreData] = []
        
        // 处理单组记录
        for record in filteredRecords {
            let totalScore = record.scores.map(scoreToInt).reduce(0, +)
            let avgScore = Double(totalScore) / Double(record.scores.count)
            scoreData.append(ScoreData(date: record.date, score: avgScore))
        }
        
        // 处理多组记录
        for record in filteredGroupRecords {
            let flattenedScores = record.groupScores.flatMap { $0 }
            let totalScore = flattenedScores.map(scoreToInt).reduce(0, +)
            let avgScore = Double(totalScore) / Double(flattenedScores.count)
            scoreData.append(ScoreData(date: record.date, score: avgScore))
        }
        
        return scoreData.sorted(by: { $0.date < $1.date })
    }
    
    static func calculateStabilityData(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord], timeRange: Int) -> StabilityResult {
        let filteredData = filterRecords(records: records, groupRecords: groupRecords, timeRange: timeRange)
        let filteredRecords = filteredData.records
        let filteredGroupRecords = filteredData.groupRecords
        
        var stabilityData: [StabilityData] = []
        var allScores: [Int] = []
        
        // 处理单组记录
        for record in filteredRecords {
            let scores = record.scores.map(scoreToInt)
            allScores.append(contentsOf: scores)
            
            if !scores.isEmpty {
                let mean = Double(scores.reduce(0, +)) / Double(scores.count)
                let squaredDiffs = scores.map { pow(Double($0) - mean, 2) }
                let standardDeviation = sqrt(squaredDiffs.reduce(0, +) / Double(scores.count))
                stabilityData.append(StabilityData(date: record.date, standardDeviation: standardDeviation))
            }
        }
        
        // 处理多组记录
        for record in filteredGroupRecords {
            let scores = record.groupScores.flatMap { $0 }.map(scoreToInt)
            allScores.append(contentsOf: scores)
            
            if !scores.isEmpty {
                let mean = Double(scores.reduce(0, +)) / Double(scores.count)
                let squaredDiffs = scores.map { pow(Double($0) - mean, 2) }
                let standardDeviation = sqrt(squaredDiffs.reduce(0, +) / Double(scores.count))
                stabilityData.append(StabilityData(date: record.date, standardDeviation: standardDeviation))
            }
        }
        
        let stats = StabilityStats(
            avg: allScores.isEmpty ? 0 : Double(allScores.reduce(0, +)) / Double(allScores.count),
            max: allScores.max() ?? 0,
            min: allScores.min() ?? 0
        )
        
        return StabilityResult(
            stabilityData: stabilityData.sorted(by: { $0.date < $1.date }),
            stats: stats
        )
    }
    
    static func calculateAccuracyStats(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord], timeRange: Int) -> AccuracyStats {
        let filteredData = filterRecords(records: records, groupRecords: groupRecords, timeRange: timeRange)
        return calculateAccuracyStats(records: filteredData.records, groupRecords: filteredData.groupRecords)
    }

    static func aggregateAccuracySummary(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord], timeRange: Int) -> AggregateAccuracySummary {
        let filteredData = filterRecords(records: records, groupRecords: groupRecords, timeRange: timeRange)
        return makeAggregateAccuracySummary(records: filteredData.records, groupRecords: filteredData.groupRecords)
    }

    private static func calculateAccuracyStats(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord]) -> AccuracyStats {
        var scoreCount = [String: Int]() // 使用字典来统计各分数
        
        // 处理单组记录
        for record in records {
            for score in record.scores {
                if score.uppercased() == "M" { continue }
                scoreCount[score, default: 0] += 1
            }
        }
        
        // 处理多组记录
        for record in groupRecords {
            for group in record.groupScores {
                for score in group {
                    if score.uppercased() == "M" { continue }
                    scoreCount[score, default: 0] += 1
                }
            }
        }

        let tensCount = (scoreCount["X"] ?? 0) + (scoreCount["10"] ?? 0)

        return AccuracyStats(
            tens: Double(tensCount),
            nines: Double(scoreCount["9"] ?? 0),
            eights: Double(scoreCount["8"] ?? 0),
            sevens: Double(scoreCount["7"] ?? 0),
            sixs: Double(scoreCount["6"] ?? 0),
            fives: Double(scoreCount["5"] ?? 0),
            four: Double(scoreCount["4"] ?? 0),
            three: Double(scoreCount["3"] ?? 0),
            two: Double(scoreCount["2"] ?? 0),
            one: Double(scoreCount["1"] ?? 0)
        )
    }

    private static func makeAggregateAccuracySummary(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord]) -> AggregateAccuracySummary {
        let allScores = records.flatMap(\.scores) + groupRecords.flatMap { $0.groupScores.flatMap { $0 } }
        let numericScores = allScores.map(scoreToInt)

        guard !numericScores.isEmpty else {
            return AggregateAccuracySummary(
                averageScore: 0,
                tenRingRate: 0,
                spreadRadius: 0,
                groupTightness: L10n.Analysis.noData,
                accuracyGrade: L10n.Analysis.noData,
                xRingCount: 0,
                tenRingCount: 0,
                nineRingCount: 0
            )
        }

        let averageScore = Double(numericScores.reduce(0, +)) / Double(numericScores.count)
        let variance = numericScores
            .map { pow(Double($0) - averageScore, 2) }
            .reduce(0, +) / Double(numericScores.count)
        let spreadRadius = sqrt(variance)

        let groupTightness = accuracyTightness(for: spreadRadius)
        let accuracyGrade = accuracyGrade(for: averageScore)

        let xRingCount = allScores.filter { $0 == "X" }.count
        let tenRingCount = allScores.filter { $0 == "10" }.count
        let nineRingCount = allScores.filter { $0 == "9" }.count
        let tenRingHits = allScores.filter { $0 == "10" || $0 == "X" }.count
        let tenRingRate = allScores.isEmpty ? 0 : Double(tenRingHits) / Double(allScores.count) * 100

        return AggregateAccuracySummary(
            averageScore: averageScore,
            tenRingRate: tenRingRate,
            spreadRadius: spreadRadius,
            groupTightness: groupTightness,
            accuracyGrade: accuracyGrade,
            xRingCount: xRingCount,
            tenRingCount: tenRingCount,
            nineRingCount: nineRingCount
        )
    }
    
    static func calculateComprehensiveStats(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord], timeRange: Int) -> ComprehensiveStats {
        let filteredData = filterRecords(records: records, groupRecords: groupRecords, timeRange: timeRange)
        let filteredRecords = filteredData.records
        let filteredGroupRecords = filteredData.groupRecords
        
        // 1. 计算平均分
        var totalScore = 0
        var totalShots = 0
        
        // 处理单组记录
        for record in filteredRecords {
            let scores = record.scores.map(scoreToInt)
            totalScore += scores.reduce(0, +)
            totalShots += scores.count
        }
        
        // 处理多组记录
        for record in filteredGroupRecords {
            let scores = record.groupScores.flatMap { $0 }.map(scoreToInt)
            totalScore += scores.reduce(0, +)
            totalShots += scores.count
        }
        
        let averageScore = totalShots > 0 ? Double(totalScore) / Double(totalShots) : 0
        
        // 2. 计算稳定性水平（使用标准差的倒数，越小表示越稳定）
        let stabilityResult = calculateStabilityData(records: filteredRecords, groupRecords: filteredGroupRecords, timeRange: timeRange)
        let stabilityLevel: Double
        if stabilityResult.stabilityData.isEmpty {
            stabilityLevel = 0.0
        } else {
            let standardDeviations = stabilityResult.stabilityData.map { $0.standardDeviation }
            let averageStandardDeviation = standardDeviations.reduce(0, +) / Double(stabilityResult.stabilityData.count)
            stabilityLevel = 10 - averageStandardDeviation
        }
        
        // 3. 计算命中率
        let accuracyStats = calculateAccuracyStats(records: filteredRecords, groupRecords: filteredGroupRecords)
        let accuracyRate = accuracyStats.topThreeRate
        
        // 4. 计算一致性（连续得分的能力）
        var consistencyRate = 0.0
        if totalShots > 1 {
            let allScores = (filteredRecords.flatMap { $0.scores } + filteredGroupRecords.flatMap { $0.groupScores.flatMap { $0 } })
                .map(scoreToInt)
            
            var consecutiveCount = 0
            for i in 1..<allScores.count {
                if abs(allScores[i] - allScores[i-1]) <= 1 {
                    consecutiveCount += 1
                }
            }
            consistencyRate = Double(consecutiveCount) / Double(allScores.count - 1) * 100
        }
        
        // 5. 计算最近趋势
        let scoreData = processScores(records: filteredRecords, groupRecords: filteredGroupRecords, timeRange: 4)
        let recentTrend: Double
        if scoreData.count >= 2, scoreData[scoreData.count - 2].score != 0 {
            let lastScore = scoreData.last?.score ?? 0
            let previousScore = scoreData[scoreData.count - 2].score
            recentTrend = ((lastScore - previousScore) / previousScore) * 100
        } else {
            recentTrend = 0
        }
        
        return ComprehensiveStats(
            averageScore: averageScore,
            stabilityLevel: stabilityLevel,
            accuracyRate: accuracyRate,
            consistencyRate: consistencyRate,
            totalShots: totalShots,
            recentTrend: recentTrend
        )
    }
    
    // MARK: - Single Record Analysis
    
    static func calculateSingleRecordAnalytics(_ record: ArcheryRecord) -> ArcheryAnalytics {
        let scores = record.scores.compactMap { scoreToInt($0) }
        let totalArrows = scores.count
        
        // 计算平均环数
        let averageRing = totalArrows > 0 ? Double(scores.reduce(0, +)) / Double(totalArrows) : 0.0
        
        // 计算稳定性评分
        let variance: Double
        if scores.isEmpty {
            variance = 0.0
        } else {
            let squaredDifferences = scores.map { pow(Double($0) - averageRing, 2) }
            variance = squaredDifferences.reduce(0, +) / Double(scores.count)
        }
        let standardDeviation = sqrt(variance)
        let stabilityScore = max(0, 100 - standardDeviation * 10)
        
        // 计算疲劳指数
        let fatigueIndex = calculateFatigueIndex(scores)
        
        // 计算10环率
        let tenRingCount = record.scores.filter { $0 == "10" || $0 == "X" }.count
        let tenRingRate = totalArrows > 0 ? Double(tenRingCount) / Double(totalArrows) * 100 : 0
        
        // 统计各环数
        let xRingCount = record.scores.filter { $0 == "X" }.count
        let tenRingCountOnly = record.scores.filter { $0 == "10" }.count
        let nineRingCount = record.scores.filter { $0 == "9" }.count
        
        return ArcheryAnalytics(
            averageRing: averageRing,
            stabilityScore: stabilityScore,
            fatigueIndex: fatigueIndex,
            tenRingRate: tenRingRate,
            xRingCount: xRingCount,
            tenRingCount: tenRingCountOnly,
            nineRingCount: nineRingCount,
            totalArrows: totalArrows
        )
    }
    
    static func calculateSingleRecordRingDistribution(_ record: ArcheryRecord) -> [(ring: String, count: Int, color: Color)] {
        let ringCounts = Dictionary(grouping: record.scores) { $0 }
            .mapValues { $0.count }
        
        let rings = ["X", "10", "9", "8", "7", "6", "5", "4", "3", "2", "1", "M"]
        
        return rings.compactMap { ring in
            let count = ringCounts[ring] ?? ringCounts[ring.lowercased()] ?? 0
            guard count > 0 else { return nil }
            return (ring: ring, count: count, color: ringColor(for: ring))
        }
    }
    
    static func calculateSingleRecordAccuracyStats(_ record: ArcheryRecord) -> (spreadRadius: Double, groupTightness: String, accuracyGrade: String) {
        let scores = record.scores.compactMap { scoreToInt($0) }
        let averageScore = scores.isEmpty ? 0.0 : Double(scores.reduce(0, +)) / Double(scores.count)
        
        // 简化的散布半径计算
        let variance: Double
        if scores.isEmpty {
            variance = 0.0
        } else {
            let squaredDifferences = scores.map { pow(Double($0) - averageScore, 2) }
            variance = squaredDifferences.reduce(0, +) / Double(scores.count)
        }
        let spreadRadius = sqrt(variance)
        
        let groupTightness = accuracyTightness(for: spreadRadius)
        let accuracyGrade = accuracyGrade(for: averageScore)
        
        return (spreadRadius: spreadRadius, groupTightness: groupTightness, accuracyGrade: accuracyGrade)
    }
    
    static func calculateSingleRecordStabilityData(_ record: ArcheryRecord) -> (groupScores: [Double], upperLimit: Double, lowerLimit: Double, coefficientOfVariation: Double) {
        let scores = record.scores.compactMap { Double(scoreToInt($0)) }
        let average = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
        
        let variance: Double
        if scores.isEmpty {
            variance = 0.0
        } else {
            let squaredDifferences = scores.map { pow($0 - average, 2) }
            variance = squaredDifferences.reduce(0, +) / Double(scores.count)
        }
        let standardDeviation = sqrt(variance)
        
        let upperLimit = average + 2 * standardDeviation
        let lowerLimit = average - 2 * standardDeviation
        
        let coefficientOfVariation = average > 0 ? standardDeviation / average : 0.0
        
        return (groupScores: scores, upperLimit: upperLimit, lowerLimit: lowerLimit, coefficientOfVariation: coefficientOfVariation)
    }
    
    static func calculateSingleRecordFatigueData(_ record: ArcheryRecord) -> [Int] {
        return record.scores.compactMap { scoreToInt($0) }
    }
    
    static func calculateSingleRecordTrends(for record: ArcheryRecord) -> (averageTrend: String, stabilityTrend: String, fatigueTrend: String, tenRingTrend: String) {
        // 简化的趋势计算，实际应该与历史数据比较
        return (
            averageTrend: "+0.5",
            stabilityTrend: "+2%",
            fatigueTrend: "-1%",
            tenRingTrend: "+5%"
        )
    }
    
    // MARK: - Group Record Analysis
    
    static func calculateGroupRecordAnalytics(_ record: ArcheryGroupRecord) -> ArcheryAnalytics {
        let allScores = record.groupScores.flatMap { $0 }.compactMap { scoreToInt($0) }
        let totalArrows = allScores.count
        
        // 计算平均环数
        let averageRing = totalArrows > 0 ? Double(allScores.reduce(0, +)) / Double(totalArrows) : 0
        
        // 计算稳定性评分
        let variance: Double
        if allScores.isEmpty {
            variance = 0.0
        } else {
            let squaredDifferences = allScores.map { pow(Double($0) - averageRing, 2) }
            variance = squaredDifferences.reduce(0, +) / Double(allScores.count)
        }
        let standardDeviation = sqrt(variance)
        let stabilityScore = max(0, 100 - standardDeviation * 10)
        
        // 计算疲劳指数
        let fatigueIndex = calculateFatigueIndex(allScores)
        
        // 计算10环率
        let allScoresFlat = record.groupScores.flatMap { $0 }
        let tenRingCount = allScoresFlat.filter { $0 == "10" || $0 == "X" }.count
        let tenRingRate = totalArrows > 0 ? Double(tenRingCount) / Double(totalArrows) * 100 : 0
        
        // 统计各环数
        let xRingCount = allScoresFlat.filter { $0 == "X" }.count
        let tenRingCountOnly = allScoresFlat.filter { $0 == "10" }.count
        let nineRingCount = allScoresFlat.filter { $0 == "9" }.count
        
        return ArcheryAnalytics(
            averageRing: averageRing,
            stabilityScore: stabilityScore,
            fatigueIndex: fatigueIndex,
            tenRingRate: tenRingRate,
            xRingCount: xRingCount,
            tenRingCount: tenRingCountOnly,
            nineRingCount: nineRingCount,
            totalArrows: totalArrows
        )
    }
    
    static func calculateGroupRecordRingDistribution(_ record: ArcheryGroupRecord) -> [String: Int] {
        let allScores = record.groupScores.flatMap { $0 }
        var distribution: [String: Int] = [:]
        
        for score in allScores {
            distribution[score, default: 0] += 1
        }
        
        return distribution
    }
    
    static func calculateGroupRecordAccuracyStats(_ record: ArcheryGroupRecord) -> (spreadRadius: Double, groupTightness: String, accuracyGrade: String) {
        let allScores = record.groupScores.flatMap { $0 }.compactMap { scoreToInt($0) }
        let averageScore = allScores.isEmpty ? 0.0 : Double(allScores.reduce(0, +)) / Double(allScores.count)

        let impactSummary = calculateGroupRecordImpactAnalysis(record)
        let spreadRadius = impactSummary.groupingRadius95
        let groupTightness = detailedGroupTightness(for: spreadRadius)
        let accuracyGrade = detailedAccuracyGrade(for: averageScore)

        return (spreadRadius: spreadRadius, groupTightness: groupTightness, accuracyGrade: accuracyGrade)
    }
    
    static func calculateGroupRecordStabilityData(_ record: ArcheryGroupRecord) -> (groupScores: [Double], upperLimit: Double, lowerLimit: Double, coefficientOfVariation: Double) {
        let groupAverages = record.groupScores.map { group in
            let scores = group.compactMap { scoreToInt($0) }
            return scores.isEmpty ? 0.0 : Double(scores.reduce(0, +)) / Double(scores.count)
        }
        
        let average = groupAverages.isEmpty ? 0 : groupAverages.reduce(0, +) / Double(groupAverages.count)
        
        let variance: Double
        if groupAverages.isEmpty {
            variance = 0
        } else {
            let squaredDifferences = groupAverages.map { pow($0 - average, 2) }
            variance = squaredDifferences.reduce(0, +) / Double(groupAverages.count)
        }
        let standardDeviation = sqrt(variance)
        
        let upperLimit = average + 2 * standardDeviation
        let lowerLimit = average - 2 * standardDeviation
        
        let coefficientOfVariation = average > 0 ? standardDeviation / average : 0
        
        return (groupScores: groupAverages, upperLimit: upperLimit, lowerLimit: lowerLimit, coefficientOfVariation: coefficientOfVariation)
    }
    
    static func calculateGroupRecordFatigueData(_ record: ArcheryGroupRecord) -> [Int] {
        return record.groupScores.flatMap { $0 }.compactMap { scoreToInt($0) }
    }
    
    static func calculateGroupRecordGoldRingRate(_ record: ArcheryGroupRecord) -> Double {
        let allScores = record.groupScores.flatMap { $0 }
        let goldRingValues = ["X", "10", "9"]
        let goldRings = allScores.filter { goldRingValues.contains($0) }
        return allScores.isEmpty ? 0 : Double(goldRings.count) / Double(allScores.count) * 100
    }

    static func calculateTrendSummary(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord], timeRange: Int) -> ScoreTrendSummary {
        let points = processScores(records: records, groupRecords: groupRecords, timeRange: timeRange)
        let scores = points.map(\.score)

        guard !scores.isEmpty else {
            return ScoreTrendSummary(
                points: [],
                rollingAveragePoints: [],
                overallAverage: 0,
                latestAverage: 0,
                recentAverage: 0,
                baselineAverage: 0,
                recentChangePercent: 0,
                bestAverage: 0,
                sessionCount: 0,
                recentWindowCount: 0,
                baselineWindowCount: 0,
                momentum: .stable,
                insight: TrendInsight(
                    title: L10n.Analysis.trendAnalysis,
                    message: L10n.tr("analysis_trend_insight_insufficient", 0)
                )
            )
        }

        let overallAverage = scores.reduce(0, +) / Double(scores.count)
        let latestAverage = points.last?.score ?? overallAverage
        let bestAverage = scores.max() ?? overallAverage

        let recentWindow = Array(scores.suffix(min(3, scores.count)))
        let recentAverage = recentWindow.reduce(0, +) / Double(recentWindow.count)
        let recentWindowCount = recentWindow.count

        let baselineSource: [Double]
        if scores.count > recentWindow.count {
            baselineSource = Array(scores.dropLast(recentWindow.count).suffix(min(3, scores.count - recentWindow.count)))
        } else if scores.count >= 2 {
            baselineSource = Array(scores.prefix(scores.count - 1))
        } else {
            baselineSource = []
        }

        let baselineAverage = baselineSource.isEmpty
            ? recentAverage
            : baselineSource.reduce(0, +) / Double(baselineSource.count)
        let baselineWindowCount = baselineSource.count

        let recentChangePercent: Double
        if baselineAverage > 0 {
            recentChangePercent = (recentAverage - baselineAverage) / baselineAverage * 100
        } else {
            recentChangePercent = 0
        }

        let momentum: TrendMomentum
        if recentChangePercent >= 1.5 {
            momentum = .rising
        } else if recentChangePercent <= -1.5 {
            momentum = .falling
        } else {
            momentum = .stable
        }

        let rollingAveragePoints = points.indices.map { index in
            let startIndex = max(0, index - 2)
            let window = Array(points[startIndex...index])
            let average = window.map(\.score).reduce(0, +) / Double(window.count)
            return ScoreData(date: points[index].date, score: average)
        }

        let insight = generateTrendInsight(
            sessionCount: points.count,
            recentWindowCount: recentWindowCount,
            baselineWindowCount: baselineWindowCount,
            recentChangePercent: recentChangePercent,
            momentum: momentum
        )

        return ScoreTrendSummary(
            points: points,
            rollingAveragePoints: rollingAveragePoints,
            overallAverage: overallAverage,
            latestAverage: latestAverage,
            recentAverage: recentAverage,
            baselineAverage: baselineAverage,
            recentChangePercent: recentChangePercent,
            bestAverage: bestAverage,
            sessionCount: points.count,
            recentWindowCount: recentWindowCount,
            baselineWindowCount: baselineWindowCount,
            momentum: momentum,
            insight: insight
        )
    }

    static func calculateImpactAnalysis(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord], timeRange: Int) -> ImpactAnalysisSummary {
        let filteredData = filterRecords(records: records, groupRecords: groupRecords, timeRange: timeRange)
        let groupRecordsWithHits = filteredData.groupRecords.compactMap { record -> (String, [ArrowHit])? in
            guard let groupArrowHits = record.groupArrowHits else { return nil }
            let hits = groupArrowHits.flatMap { $0 }
            guard !hits.isEmpty else { return nil }
            return (record.targetType, hits)
        }

        guard !groupRecordsWithHits.isEmpty else {
            return emptyImpactAnalysisSummary()
        }

        let groupedHits = Dictionary(grouping: groupRecordsWithHits, by: \.0)
        let dominantTargetEntry = groupedHits.max { lhs, rhs in
            lhs.value.flatMap(\.1).count < rhs.value.flatMap(\.1).count
        }

        guard let dominantTargetEntry else {
            return emptyImpactAnalysisSummary()
        }

        let targetTypeName = dominantTargetEntry.key
        let hits = dominantTargetEntry.value.flatMap(\.1)
        let uniqueTargetTypes = Set(groupRecordsWithHits.map(\.0))
        let scopeDescription: String?
        if uniqueTargetTypes.count > 1 {
            scopeDescription = L10n.tr("analysis_impact_scope", targetTypeName)
        } else {
            scopeDescription = nil
        }

        return buildImpactAnalysisSummary(
            targetTypeName: targetTypeName,
            hits: hits,
            scopeDescription: scopeDescription,
            hasRealData: true
        )
    }

    static func calculateGroupRecordImpactAnalysis(_ record: ArcheryGroupRecord) -> ImpactAnalysisSummary {
        if let groupArrowHits = record.groupArrowHits {
            let realHits = groupArrowHits.flatMap { $0 }
            if !realHits.isEmpty {
                return buildImpactAnalysisSummary(
                    targetTypeName: record.targetType,
                    hits: realHits,
                    scopeDescription: nil,
                    hasRealData: true
                )
            }
        }

        let simulatedHits = simulatedHits(for: record)
        guard !simulatedHits.isEmpty else {
            return emptyImpactAnalysisSummary(targetTypeName: record.targetType)
        }

        return buildImpactAnalysisSummary(
            targetTypeName: record.targetType,
            hits: simulatedHits,
            scopeDescription: nil,
            hasRealData: false
        )
    }

    static func calculateGroupRecordCenterOffset(_ record: ArcheryGroupRecord) -> Double {
        calculateGroupRecordImpactAnalysis(record).centerOffset
    }

    static func calculateGroupRecordPrimaryBias(_ record: ArcheryGroupRecord) -> ImpactDirection {
        calculateGroupRecordImpactAnalysis(record).biasDirection
    }

    static func calculateGroupRecordOffsetDistribution(_ record: ArcheryGroupRecord) -> [ImpactQuadrantSummary] {
        calculateGroupRecordImpactAnalysis(record).quadrants
    }

    static func generateGroupRecordArrowPoints(_ record: ArcheryGroupRecord, scaleFactor: Double = 2.0) -> [AnalysisArrowPoint] {
        generateArrowPoints(from: calculateGroupRecordImpactAnalysis(record), scaleFactor: scaleFactor)
    }

    static func generateArrowPoints(from summary: ImpactAnalysisSummary, scaleFactor: Double = 2.0) -> [AnalysisArrowPoint] {
        summary.points.map { point in
            AnalysisArrowPoint(
                id: point.id,
                offset: CGSize(
                    width: point.position.x * scaleFactor,
                    height: point.position.y * scaleFactor
                ),
                color: ringColor(for: point.score)
            )
        }
    }
    
    // MARK: - Analysis Text Generation
    
    static func generateShootingAnalysis(analytics: ArcheryAnalytics) -> String {
        var analysisParts: [String] = []
        
        if analytics.tenRingRate >= 70 {
            analysisParts.append(L10n.tr("analysis_shooting_ten_rate_excellent"))
        } else if analytics.tenRingRate >= 50 {
            analysisParts.append(L10n.tr("analysis_shooting_ten_rate_good"))
        } else {
            analysisParts.append(L10n.tr("analysis_shooting_ten_rate_improve"))
        }
        
        if analytics.averageRing >= 9.0 {
            analysisParts.append(L10n.tr("analysis_shooting_average_excellent"))
        } else if analytics.averageRing >= 8.0 {
            analysisParts.append(L10n.tr("analysis_shooting_average_good"))
        } else {
            analysisParts.append(L10n.tr("analysis_shooting_average_improve"))
        }
        
        return analysisParts.joined(separator: " ")
    }
    
    static func generateAccuracyAnalysis(stats: (spreadRadius: Double, groupTightness: String, accuracyGrade: String)) -> String {
        return L10n.tr(
            "analysis_accuracy_advice",
            stats.accuracyGrade,
            stats.groupTightness,
            String(format: "%.1f", stats.spreadRadius)
        )
    }
    
    static func generateStabilityAnalysis(analytics: ArcheryAnalytics, stabilityData: (groupScores: [Double], upperLimit: Double, lowerLimit: Double, coefficientOfVariation: Double)) -> String {
        let level = getStabilityLevel(analytics.stabilityScore)
        return L10n.tr(
            "analysis_stability_advice",
            level,
            String(format: "%.2f", stabilityData.coefficientOfVariation)
        )
    }
    
    static func generateStabilityAnalysisForGroup(score: Double, cv: Double) -> String {
        if score >= 80 {
            return L10n.tr("analysis_stability_group_excellent", String(format: "%.2f", cv))
        } else if score >= 60 {
            return L10n.tr("analysis_stability_group_good", String(format: "%.2f", cv))
        } else {
            return L10n.tr("analysis_stability_group_improve", String(format: "%.2f", cv))
        }
    }
    
    static func generateStabilityTrainingAdvice(score: Double, cv: Double) -> String {
        if score >= 80 {
            return L10n.tr("analysis_stability_training_excellent")
        } else if score >= 60 {
            return L10n.tr("analysis_stability_training_good")
        } else if score >= 40 {
            return L10n.tr("analysis_stability_training_average")
        } else {
            return L10n.tr("analysis_stability_training_improve")
        }
    }
    
    static func generateFatigueAnalysis(index: Double) -> String {
        if index < 10 {
            return L10n.tr("analysis_fatigue_excellent")
        } else if index < 20 {
            return L10n.tr("analysis_fatigue_good")
        } else if index < 30 {
            return L10n.tr("analysis_fatigue_average")
        } else {
            return L10n.tr("analysis_fatigue_improve")
        }
    }
    
    static func generateFatigueTrainingAdvice(index: Double) -> String {
        if index < 10 {
            return L10n.tr("analysis_fatigue_training_excellent")
        } else if index < 20 {
            return L10n.tr("analysis_fatigue_training_good")
        } else if index < 30 {
            return L10n.tr("analysis_fatigue_training_average")
        } else {
            return L10n.tr("analysis_fatigue_training_improve")
        }
    }

    static func ringColor(for score: Int) -> Color {
        switch score {
        case 10:
            return .red
        case 9:
            return .orange
        case 8:
            return .yellow
        case 7:
            return .green
        case 6:
            return .blue
        default:
            return .gray
        }
    }

    // MARK: - Helper Functions
    
    private static func scoreToInt(_ score: String) -> Int {
        switch score.uppercased() {
        case "X":
            return 10
        case "M":
            return 0
        default:
            return Int(score) ?? 0
        }
    }
    
    private static func calculateFatigueIndex(_ scores: [Int]) -> Double {
        guard scores.count > 1 else { return 0 }
        
        let firstHalf = Array(scores.prefix(scores.count / 2))
        let secondHalf = Array(scores.suffix(scores.count / 2))
        
        let firstAvg = firstHalf.isEmpty ? 0 : Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
        let secondAvg = secondHalf.isEmpty ? 0 : Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
        
        return max(0, (firstAvg - secondAvg) / firstAvg * 100)
    }
    
    static func ringColor(for ring: String) -> Color {
        switch ring.lowercased() {
        case "x":
            return .red
        case "10":
            return .orange
        case "9":
            return .yellow
        case "8":
            return .green
        case "7":
            return .blue
        case "6":
            return .purple
        default:
            return .gray
        }
    }
    
    static func getFatigueLevel(_ index: Double) -> String {
        if index < 10 {
            return gradeLabel(.excellent)
        } else if index < 20 {
            return gradeLabel(.good)
        } else if index < 30 {
            return gradeLabel(.average)
        } else {
            return gradeLabel(.needsImprovement)
        }
    }
    
    static func getFatigueIndexColor(_ index: Double) -> Color {
        if index < 10 {
            return .green
        } else if index < 20 {
            return .yellow
        } else if index < 30 {
            return .orange
        } else {
            return .red
        }
    }
    
    static func getStabilityLevel(_ score: Double) -> String {
        if score >= 80 {
            return gradeLabel(.excellent)
        } else if score >= 60 {
            return gradeLabel(.good)
        } else if score >= 40 {
            return gradeLabel(.average)
        } else {
            return gradeLabel(.needsImprovement)
        }
    }
    
    static func getStabilityLevelColor(_ score: Double) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .blue
        } else if score >= 40 {
            return .orange
        } else {
            return .red
        }
    }
    
    static func getCVLevel(_ cv: Double) -> String {
        if cv < 5 {
            return gradeLabel(.excellent)
        } else if cv < 10 {
            return gradeLabel(.good)
        } else if cv < 15 {
            return gradeLabel(.average)
        } else {
            return gradeLabel(.needsImprovement)
        }
    }
    
    static func getCVLevelColor(_ cv: Double) -> Color {
        if cv < 5 {
            return .green
        } else if cv < 10 {
            return .blue
        } else if cv < 15 {
            return .orange
        } else {
            return .red
        }
    }
    
    static func ringColorForGroup(for ring: String) -> Color {
        switch ring.lowercased() {
        case "x":
            return .red
        case "10":
            return .orange
        case "9":
            return .yellow
        case "8":
            return .green
        case "7":
            return .blue
        case "6":
            return .purple
        default:
            return .gray
        }
    }

    private static func emptyImpactAnalysisSummary(targetTypeName: String? = nil) -> ImpactAnalysisSummary {
        ImpactAnalysisSummary(
            targetFace: targetTypeName.flatMap { TargetFaceManager.shared.getTarget(for: $0) },
            targetTypeName: targetTypeName,
            scopeDescription: nil,
            totalHits: 0,
            groupingRadius95: 0,
            centerOffset: 0,
            averageDistanceFromCenter: 0,
            centroid: .zero,
            hasRealData: false,
            biasDirection: .centered,
            dominantQuadrantRate: 0,
            points: [],
            quadrants: [],
            insights: []
        )
    }

    private static func buildImpactAnalysisSummary(targetTypeName: String, hits: [ArrowHit], scopeDescription: String?, hasRealData: Bool) -> ImpactAnalysisSummary {
        guard !hits.isEmpty else { return emptyImpactAnalysisSummary(targetTypeName: targetTypeName) }

        let targetFace = TargetFaceManager.shared.getTarget(for: targetTypeName)
        let centroid = averagePoint(for: hits.map(\.position))
        let groupingDistances = hits.map {
            Double(hypot($0.position.x - centroid.x, $0.position.y - centroid.y))
        }
        let centerDistances = hits.map { $0.distanceFromCenter() }
        let groupingRadius95 = percentile(groupingDistances, at: 0.95)
        let centerOffset = Double(hypot(centroid.x, centroid.y))
        let averageDistanceFromCenter = centerDistances.isEmpty ? 0 : centerDistances.reduce(0, +) / Double(centerDistances.count)

        let points = hits.map {
            ImpactPoint(
                id: $0.id,
                position: $0.position,
                score: $0.score,
                ringNumber: $0.ringNumber
            )
        }

        let quadrants = makeQuadrantSummaries(from: hits)
        let dominantQuadrantRate = quadrants.map(\.percentage).max() ?? 0
        let biasDirection = classifyDirection(for: centroid)

        let draftSummary = ImpactAnalysisSummary(
            targetFace: targetFace,
            targetTypeName: targetTypeName,
            scopeDescription: scopeDescription,
            totalHits: hits.count,
            groupingRadius95: groupingRadius95,
            centerOffset: centerOffset,
            averageDistanceFromCenter: averageDistanceFromCenter,
            centroid: centroid,
            hasRealData: hasRealData,
            biasDirection: biasDirection,
            dominantQuadrantRate: dominantQuadrantRate,
            points: points,
            quadrants: quadrants,
            insights: []
        )

        return ImpactAnalysisSummary(
            targetFace: draftSummary.targetFace,
            targetTypeName: draftSummary.targetTypeName,
            scopeDescription: draftSummary.scopeDescription,
            totalHits: draftSummary.totalHits,
            groupingRadius95: draftSummary.groupingRadius95,
            centerOffset: draftSummary.centerOffset,
            averageDistanceFromCenter: draftSummary.averageDistanceFromCenter,
            centroid: draftSummary.centroid,
            hasRealData: draftSummary.hasRealData,
            biasDirection: draftSummary.biasDirection,
            dominantQuadrantRate: draftSummary.dominantQuadrantRate,
            points: draftSummary.points,
            quadrants: draftSummary.quadrants,
            insights: generateImpactInsights(summary: draftSummary)
        )
    }

    private static func simulatedHits(for record: ArcheryGroupRecord) -> [ArrowHit] {
        let allScores = record.groupScores.flatMap { $0 }
        guard !allScores.isEmpty else { return [] }

        let targetFace = TargetFaceManager.shared.getTarget(for: record.targetType)
        let targetRadius = (targetFace?.diameter ?? 40.0) / 2
        let maxDistance = targetRadius * 0.72

        return allScores.enumerated().map { index, score in
            let numericScore = scoreToInt(score)
            let distanceFactor = max(0.08, Double(10 - numericScore) / 10.0)
            let angleDegrees = (index * 67 + numericScore * 17) % 360
            let angle = Double(angleDegrees) * .pi / 180
            let modulation = 0.72 + Double((index % 5)) * 0.07
            let distance = maxDistance * distanceFactor * modulation
            let position = CGPoint(
                x: CGFloat(cos(angle) * distance),
                y: CGFloat(sin(angle) * distance)
            )

            return ArrowHit(
                position: position,
                score: numericScore,
                ringNumber: numericScore == 10 && score.uppercased() == "X" ? 11 : numericScore,
                groupIndex: index / max(record.arrowsPerGroup, 1),
                arrowIndex: index % max(record.arrowsPerGroup, 1),
                targetFaceType: targetFace?.type ?? .full40cm
            )
        }
    }

    private static func makeQuadrantSummaries(from hits: [ArrowHit]) -> [ImpactQuadrantSummary] {
        guard !hits.isEmpty else { return [] }

        var upperLeft = 0
        var upperRight = 0
        var lowerLeft = 0
        var lowerRight = 0

        for hit in hits {
            if hit.position.x <= 0 && hit.position.y <= 0 {
                upperLeft += 1
            } else if hit.position.x > 0 && hit.position.y <= 0 {
                upperRight += 1
            } else if hit.position.x <= 0 && hit.position.y > 0 {
                lowerLeft += 1
            } else {
                lowerRight += 1
            }
        }

        let total = Double(hits.count)

        return [
            ImpactQuadrantSummary(direction: .upperLeft, count: upperLeft, percentage: Double(upperLeft) / total * 100),
            ImpactQuadrantSummary(direction: .upperRight, count: upperRight, percentage: Double(upperRight) / total * 100),
            ImpactQuadrantSummary(direction: .lowerLeft, count: lowerLeft, percentage: Double(lowerLeft) / total * 100),
            ImpactQuadrantSummary(direction: .lowerRight, count: lowerRight, percentage: Double(lowerRight) / total * 100)
        ]
    }

    private static func classifyDirection(for point: CGPoint) -> ImpactDirection {
        let offset = Double(hypot(point.x, point.y))
        guard offset >= 0.8 else { return .centered }

        if point.x <= 0 && point.y <= 0 {
            return .upperLeft
        } else if point.x > 0 && point.y <= 0 {
            return .upperRight
        } else if point.x <= 0 && point.y > 0 {
            return .lowerLeft
        } else {
            return .lowerRight
        }
    }

    private static func detailedGroupTightness(for spreadRadius: Double) -> String {
        switch spreadRadius {
        case ..<3.0:
            return L10n.tr("analysis_grade_excellent")
        case ..<5.0:
            return L10n.tr("analysis_grade_good")
        case ..<8.0:
            return L10n.tr("analysis_grade_average")
        default:
            return L10n.tr("analysis_grade_improve")
        }
    }

    private static func detailedAccuracyGrade(for averageScore: Double) -> String {
        switch averageScore {
        case 9.5...:
            return "A+"
        case 9.0...:
            return "A"
        case 8.5...:
            return "B+"
        case 8.0...:
            return "B"
        default:
            return "C"
        }
    }

    private static func averagePoint(for points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }

        let totalX = points.map(\.x).reduce(CGFloat.zero, +)
        let totalY = points.map(\.y).reduce(CGFloat.zero, +)

        return CGPoint(
            x: totalX / CGFloat(points.count),
            y: totalY / CGFloat(points.count)
        )
    }

    private static func percentile(_ values: [Double], at percentile: Double) -> Double {
        guard !values.isEmpty else { return 0 }

        let sortedValues = values.sorted()
        let rawIndex = Int(Double(sortedValues.count - 1) * percentile)
        let clampedIndex = min(max(rawIndex, 0), sortedValues.count - 1)
        return sortedValues[clampedIndex]
    }

    private static func generateTrendInsight(
        sessionCount: Int,
        recentWindowCount: Int,
        baselineWindowCount: Int,
        recentChangePercent: Double,
        momentum: TrendMomentum
    ) -> TrendInsight {
        guard sessionCount > 1, baselineWindowCount > 0 else {
            return TrendInsight(
                title: L10n.Analysis.trendAnalysis,
                message: L10n.tr("analysis_trend_insight_insufficient", sessionCount)
            )
        }

        let formattedDelta = String(format: "%.1f%%", abs(recentChangePercent))
        let message: String

        switch momentum {
        case .rising:
            message = L10n.tr(
                "analysis_trend_insight_rising",
                recentWindowCount,
                baselineWindowCount,
                formattedDelta
            )
        case .stable:
            message = L10n.tr(
                "analysis_trend_insight_stable",
                recentWindowCount,
                baselineWindowCount,
                formattedDelta
            )
        case .falling:
            message = L10n.tr(
                "analysis_trend_insight_falling",
                recentWindowCount,
                baselineWindowCount,
                formattedDelta
            )
        }

        return TrendInsight(title: L10n.Analysis.trendAnalysis, message: message)
    }

    private static func generateImpactInsights(summary: ImpactAnalysisSummary) -> [ImpactInsight] {
        let groupingMessage: String
        if summary.groupingRadius95 <= 2.5 {
            groupingMessage = L10n.tr("analysis_grouping_message_excellent")
        } else if summary.groupingRadius95 <= 4.5 {
            groupingMessage = L10n.tr("analysis_grouping_message_good")
        } else {
            groupingMessage = L10n.tr("analysis_grouping_message_improve")
        }

        let adjustmentMessage: String
        if summary.biasDirection == .centered || summary.centerOffset <= 1.0 {
            adjustmentMessage = L10n.tr("analysis_bias_message_centered")
        } else {
            adjustmentMessage = L10n.tr("analysis_bias_message_offset", summary.biasDirection.localizedLabel)
        }

        return [
            ImpactInsight(
                id: "grouping",
                symbolName: "scope",
                title: L10n.tr("analysis_insight_grouping_title"),
                message: groupingMessage
            ),
            ImpactInsight(
                id: "adjustment",
                symbolName: summary.biasDirection.symbolName,
                title: L10n.tr("analysis_insight_adjustment_title"),
                message: adjustmentMessage
            )
        ]
    }

    private enum GradeCategory {
        case excellent
        case good
        case average
        case needsImprovement
    }

    private static func accuracyTightness(for spreadRadius: Double) -> String {
        if spreadRadius < 1.0 {
            return L10n.tr("analysis_group_tightness_tight")
        } else if spreadRadius < 2.0 {
            return L10n.tr("analysis_group_tightness_good")
        } else {
            return L10n.tr("analysis_group_tightness_loose")
        }
    }

    private static func accuracyGrade(for averageScore: Double) -> String {
        if averageScore >= 9.0 {
            return gradeLabel(.excellent)
        } else if averageScore >= 8.0 {
            return gradeLabel(.good)
        } else if averageScore >= 7.0 {
            return gradeLabel(.average)
        } else {
            return gradeLabel(.needsImprovement)
        }
    }

    private static func gradeLabel(_ grade: GradeCategory) -> String {
        switch grade {
        case .excellent:
            return L10n.tr("analysis_grade_excellent")
        case .good:
            return L10n.tr("analysis_grade_good")
        case .average:
            return L10n.tr("analysis_grade_average")
        case .needsImprovement:
            return L10n.tr("analysis_grade_improve")
        }
    }
}

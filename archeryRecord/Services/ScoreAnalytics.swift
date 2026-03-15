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

class ScoreAnalytics {
    static func processScores(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord], timeRange: Int) -> [ScoreData] {
        let calendar = Calendar.current
        let now = Date()
        
        let filteredRecords = records.filter { record in
            switch timeRange {
            case 0: // 今日
                return calendar.isDateInToday(record.date)
            case 1: // 周
                return calendar.isDate(record.date, equalTo: now, toGranularity: .weekOfYear)
            case 2: // 月
                return calendar.isDate(record.date, equalTo: now, toGranularity: .month)
            case 3: // 年
                return calendar.isDate(record.date, equalTo: now, toGranularity: .year)
            default:
                return false
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
                return false
            }
        }
        
        var scoreData: [ScoreData] = []
        
        // 处理单组记录
        for record in filteredRecords {
            let totalScore = record.scores.compactMap { score -> Int? in
                if score == "X" { return 10 }
                if score == "M" { return 0 }
                return Int(score)
            }.reduce(0, +)
            let avgScore = Double(totalScore) / Double(record.scores.count)
            scoreData.append(ScoreData(date: record.date, score: avgScore))
        }
        
        // 处理多组记录
        for record in filteredGroupRecords {
            let totalScore = record.groupScores.flatMap { $0 }.compactMap { score -> Int? in
                if score == "X" { return 10 }
                if score == "M" { return 0 }
                return Int(score)
            }.reduce(0, +)
            let avgScore = Double(totalScore) / Double(record.groupScores.flatMap { $0 }.count)
            scoreData.append(ScoreData(date: record.date, score: avgScore))
        }
        
        return scoreData.sorted(by: { $0.date < $1.date })
    }
    
    static func calculateStabilityData(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord], timeRange: Int) -> StabilityResult {
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
                return false
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
                return false
            }
        }
        
        var stabilityData: [StabilityData] = []
        var allScores: [Int] = []
        
        // 处理单组记录
        for record in filteredRecords {
            let scores = record.scores.compactMap { score -> Int? in
                if score == "X" { return 10 }
                if score == "M" { return 0 }
                return Int(score)
            }
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
            let scores = record.groupScores.flatMap { $0 }.compactMap { score -> Int? in
                if score == "X" { return 10 }
                if score == "M" { return 0 }
                return Int(score)
            }
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
                return false
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
                return false
            }
        }
        
        var scoreCount = [String: Int]() // 使用字典来统计各分数
        var totalShots = 0
        
        // 处理单组记录
        for record in filteredRecords {
            for score in record.scores {
                if score == "M" { continue } // 跳过未中靶的情况
                totalShots += 1
                scoreCount[score, default: 0] += 1
            }
        }
        
        // 处理多组记录
        for record in filteredGroupRecords {
            for group in record.groupScores {
                for score in group {
                    if score == "M" { continue } // 跳过未中靶的情况
                    totalShots += 1
                    scoreCount[score, default: 0] += 1
                }
            }
        }
        
        // 打印调试信息
        print("总射箭数: \(totalShots)")
        print("分数统计: \(scoreCount)")
        
        let totalShotsDouble = Double(totalShots)
        // 合并X和10的计数
        let tensCount = (scoreCount["X"] ?? 0) + (scoreCount["10"] ?? 0)
    
        // 确保每个分数区间只计算一次，这里只需要计算每个分数出现的次数，不是要计算比例
        let stats = AccuracyStats(
            tens: totalShots == 0 ? 0 : (Double(tensCount)),
            nines: totalShots == 0 ? 0 : (Double(scoreCount["9"] ?? 0)),
            eights: totalShots == 0 ? 0 : (Double(scoreCount["8"] ?? 0)),
            sevens: totalShots == 0 ? 0 : (Double(scoreCount["7"] ?? 0)),
            sixs: totalShots == 0 ? 0 : (Double(scoreCount["6"] ?? 0)),
            fives: totalShots == 0 ? 0 : (Double(scoreCount["5"] ?? 0)),
            four: totalShots == 0 ? 0 : (Double(scoreCount["4"] ?? 0)),
            three: totalShots == 0 ? 0 : (Double(scoreCount["3"] ?? 0)),
            two: totalShots == 0 ? 0 : (Double(scoreCount["2"] ?? 0)),
            one: totalShots == 0 ? 0 : (Double(scoreCount["1"] ?? 0))
        )
        
        // 验证总百分比是否接近100%
        let totalPercentage = stats.tens + stats.nines + stats.eights + stats.sevens + 
                             stats.sixs + stats.fives + stats.four + stats.three + 
                             stats.two + stats.one
        print("总百分比: \(totalPercentage)%")
        
        return stats
    }
    
    static func calculateComprehensiveStats(records: [ArcheryRecord], groupRecords: [ArcheryGroupRecord], timeRange: Int) -> ComprehensiveStats {
        let calendar = Calendar.current
        let now = Date()
        
        let filteredRecords = records.filter { record in
            switch timeRange {
            case 0: return calendar.isDateInToday(record.date)
            case 1: return calendar.isDate(record.date, equalTo: now, toGranularity: .weekOfYear)
            case 2: return calendar.isDate(record.date, equalTo: now, toGranularity: .month)
            case 3: return calendar.isDate(record.date, equalTo: now, toGranularity: .year)
            default: return false
            }
        }
        
        let filteredGroupRecords = groupRecords.filter { record in
            switch timeRange {
            case 0: return calendar.isDateInToday(record.date)
            case 1: return calendar.isDate(record.date, equalTo: now, toGranularity: .weekOfYear)
            case 2: return calendar.isDate(record.date, equalTo: now, toGranularity: .month)
            case 3: return calendar.isDate(record.date, equalTo: now, toGranularity: .year)
            default: return false
            }
        }
        
        // 1. 计算平均分
        var totalScore = 0
        var totalShots = 0
        
        // 处理单组记录
        for record in filteredRecords {
            let scores = record.scores.compactMap { score -> Int? in
                if score == "X" { return 10 }
                if score == "M" { return 0 }
                return Int(score)
            }
            totalScore += scores.reduce(0, +)
            totalShots += scores.count
        }
        
        // 处理多组记录
        for record in filteredGroupRecords {
            let scores = record.groupScores.flatMap { $0 }.compactMap { score -> Int? in
                if score == "X" { return 10 }
                if score == "M" { return 0 }
                return Int(score)
            }
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
        let accuracyStats = calculateAccuracyStats(records: filteredRecords, groupRecords: filteredGroupRecords, timeRange: timeRange)
        let accuracyRate = (accuracyStats.tens + accuracyStats.nines + accuracyStats.eights) / 100
        
        // 4. 计算一致性（连续得分的能力）
        var consistencyRate = 0.0
        if totalShots > 0 {
            let allScores = (filteredRecords.flatMap { $0.scores } + filteredGroupRecords.flatMap { $0.groupScores.flatMap { $0 } })
                .compactMap { score -> Int? in
                    if score == "X" { return 10 }
                    if score == "M" { return 0 }
                    return Int(score)
                }
            
            var consecutiveCount = 0
            for i in 1..<allScores.count {
                if abs(allScores[i] - allScores[i-1]) <= 1 {
                    consecutiveCount += 1
                }
            }
            consistencyRate = Double(consecutiveCount) / Double(allScores.count - 1) * 100
        }
        
        // 5. 计算最近趋势
        let scoreData = processScores(records: filteredRecords, groupRecords: filteredGroupRecords, timeRange: timeRange)
        let recentTrend: Double
        if scoreData.count >= 2 {
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
        
        let groupTightness: String
        if spreadRadius < 1.0 {
            groupTightness = "紧密"
        } else if spreadRadius < 2.0 {
            groupTightness = "良好"
        } else {
            groupTightness = "松散"
        }
        
        let accuracyGrade: String
        if averageScore >= 9.0 {
            accuracyGrade = "优秀"
        } else if averageScore >= 8.0 {
            accuracyGrade = "良好"
        } else if averageScore >= 7.0 {
            accuracyGrade = "一般"
        } else {
            accuracyGrade = "需改进"
        }
        
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
        
        // 简化的散布半径计算
        let variance: Double
        if allScores.isEmpty {
            variance = 0.0
        } else {
            let squaredDifferences = allScores.map { pow(Double($0) - averageScore, 2) }
            variance = squaredDifferences.reduce(0, +) / Double(allScores.count)
        }
        let spreadRadius = sqrt(variance)
        
        let groupTightness: String
        if spreadRadius < 1.0 {
            groupTightness = "紧密"
        } else if spreadRadius < 2.0 {
            groupTightness = "良好"
        } else {
            groupTightness = "松散"
        }
        
        let accuracyGrade: String
        if averageScore >= 9.0 {
            accuracyGrade = "优秀"
        } else if averageScore >= 8.0 {
            accuracyGrade = "良好"
        } else if averageScore >= 7.0 {
            accuracyGrade = "一般"
        } else {
            accuracyGrade = "需改进"
        }
        
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
    
    // MARK: - Analysis Text Generation
    
    static func generateShootingAnalysis(analytics: ArcheryAnalytics) -> String {
        var analysis = ""
        
        if analytics.tenRingRate >= 70 {
            analysis += "您的10环率表现优秀，保持当前的瞄准技术。"
        } else if analytics.tenRingRate >= 50 {
            analysis += "您的10环率良好，可以通过加强瞄准练习进一步提升。"
        } else {
            analysis += "建议加强基础瞄准训练，提高10环命中率。"
        }
        
        if analytics.averageRing >= 9.0 {
            analysis += "平均环数很高，技术水平优秀。"
        } else if analytics.averageRing >= 8.0 {
            analysis += "平均环数良好，继续保持。"
        } else {
            analysis += "建议加强基础训练，提高整体水平。"
        }
        
        return analysis
    }
    
    static func generateAccuracyAnalysis(stats: (spreadRadius: Double, groupTightness: String, accuracyGrade: String)) -> String {
        return "您的精准度等级为\(stats.accuracyGrade)，组别紧密度\(stats.groupTightness)。散布半径为\(String(format: "%.1f", stats.spreadRadius))，建议通过稳定射击姿势和呼吸控制来提高精准度。"
    }
    
    static func generateStabilityAnalysis(analytics: ArcheryAnalytics, stabilityData: (groupScores: [Double], upperLimit: Double, lowerLimit: Double, coefficientOfVariation: Double)) -> String {
        let level = getStabilityLevel(analytics.stabilityScore)
        return "您的稳定性等级为\(level)，变异系数为\(String(format: "%.2f", stabilityData.coefficientOfVariation))。建议通过规律训练和技术动作标准化来提高稳定性。"
    }
    
    static func generateStabilityAnalysisForGroup(score: Double, cv: Double) -> String {
        let _ = getStabilityLevel(score)
        if score >= 80 {
            return "您的稳定性表现优秀，变异系数为\(String(format: "%.2f", cv))%。继续保持当前的训练节奏和技术动作。"
        } else if score >= 60 {
            return "您的稳定性良好，变异系数为\(String(format: "%.2f", cv))%。建议通过规律训练进一步提升稳定性。"
        } else {
            return "您的稳定性需要改进，变异系数为\(String(format: "%.2f", cv))%。建议加强基础动作练习，提高技术一致性。"
        }
    }
    
    static func generateStabilityTrainingAdvice(score: Double, cv: Double) -> String {
        if score >= 80 {
            return "保持当前的训练强度和技术动作，可以适当增加训练难度。"
        } else if score >= 60 {
            return "建议增加技术动作的重复练习，注重动作的一致性和规范性。"
        } else if score >= 40 {
            return "需要加强基础训练，重点练习站姿、瞄准和撒放的标准化动作。"
        } else {
            return "建议从基础动作开始，逐步建立正确的射箭技术体系，可考虑寻求专业指导。"
        }
    }
    
    static func generateFatigueAnalysis(index: Double) -> String {
        if index < 10 {
            return "您的疲劳控制很好，射箭过程中保持了良好的体能状态。"
        } else if index < 20 {
            return "存在轻微的疲劳迹象，建议适当调整训练强度。"
        } else if index < 30 {
            return "疲劳程度较为明显，建议加强体能训练和休息调节。"
        } else {
            return "疲劳程度较高，建议充分休息后再进行训练。"
        }
    }
    
    static func generateFatigueTrainingAdvice(index: Double) -> String {
        if index < 10 {
            return "您的疲劳控制很好，保持当前的训练强度和休息节奏。"
        } else if index < 20 {
            return "轻微疲劳迹象，建议适当调整训练强度，增加休息时间。"
        } else if index < 30 {
            return "存在明显疲劳，建议降低训练强度，加强体能训练。"
        } else {
            return "疲劳程度较高，建议充分休息后再进行训练，并检查训练计划。"
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
            return "优秀"
        } else if index < 20 {
            return "良好"
        } else if index < 30 {
            return "一般"
        } else {
            return "需改进"
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
            return "优秀"
        } else if score >= 60 {
            return "良好"
        } else if score >= 40 {
            return "一般"
        } else {
            return "需改进"
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
            return "优秀"
        } else if cv < 10 {
            return "良好"
        } else if cv < 15 {
            return "一般"
        } else {
            return "需改进"
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
}

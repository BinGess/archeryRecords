//
//  archeryRecordTests.swift
//  archeryRecordTests
//
//  Created by ByteDance on 2025/2/8.
//

import Foundation
import CoreGraphics
import Testing
@testable import archeryRecord

struct archeryRecordTests {
    @Test func totalScoreTreatsXAsTenAndMAsZero() {
        let record = ArcheryRecord(
            id: UUID(),
            bowType: "Compound",
            distance: "18",
            targetType: "40cm",
            scores: ["X", "10", "9", "M", "7"],
            date: Date(),
            numberOfArrows: 5
        )

        #expect(record.totalScore == 36)
        #expect(record.getScore(0) == 10)
        #expect(record.getScore(3) == 0)
    }

    @Test func legacyGroupRecordsGainEmptyArrowHitBuckets() {
        let legacyRecord = ArcheryGroupRecord(
            bowType: "Recurve",
            distance: "18",
            targetType: "40cm",
            groupScores: [["10", "9", "8"], ["7", "6", "5"]],
            date: Date(),
            numberOfGroups: 2,
            arrowsPerGroup: 3,
            groupArrowHits: nil
        )

        let migration = ArcheryStore.migrateLegacyGroupRecords([legacyRecord])

        #expect(migration.didMigrate)
        #expect(migration.records.count == 1)
        #expect(migration.records[0].groupArrowHits?.count == 2)
        #expect(migration.records[0].groupArrowHits?.allSatisfy { $0.isEmpty } == true)
    }

    @Test func inferredLastModifiedUsesMostRecentRecordDate() {
        let olderDate = Date(timeIntervalSince1970: 1_700_000_000)
        let newerDate = Date(timeIntervalSince1970: 1_800_000_000)

        let singleRecord = ArcheryRecord(
            id: UUID(),
            bowType: "Compound",
            distance: "18",
            targetType: "40cm",
            scores: ["10"],
            date: olderDate,
            numberOfArrows: 1
        )

        let groupRecord = ArcheryGroupRecord(
            bowType: "Recurve",
            distance: "30",
            targetType: "80cm",
            groupScores: [["9", "9", "9"]],
            date: newerDate,
            numberOfGroups: 1,
            arrowsPerGroup: 3,
            groupArrowHits: [[]]
        )

        let inferredDate = ArcheryStore.inferLastModifiedDate(
            records: [singleRecord],
            groupRecords: [groupRecord]
        )

        #expect(inferredDate == newerDate)
    }

    @Test func aggregateAccuracySummaryUsesAllFilteredRecords() {
        let records = [
            ArcheryRecord(
                id: UUID(),
                bowType: "Compound",
                distance: "18",
                targetType: "40cm",
                scores: ["10", "10", "10"],
                date: Date(),
                numberOfArrows: 3
            )
        ]
        let groupRecords = [
            ArcheryGroupRecord(
                bowType: "Compound",
                distance: "18",
                targetType: "40cm",
                groupScores: [["1", "1", "1"]],
                date: Date(),
                numberOfGroups: 1,
                arrowsPerGroup: 3,
                groupArrowHits: [[]]
            )
        ]

        let summary = ScoreAnalytics.aggregateAccuracySummary(records: records, groupRecords: groupRecords, timeRange: 3)

        #expect(abs(summary.averageScore - 5.5) < 0.0001)
        #expect(summary.accuracyGrade == "需改进")
        #expect(summary.tenRingCount == 3)
        #expect(summary.nineRingCount == 0)
    }

    @Test func comprehensiveAccuracyRateUsesRealShotCounts() {
        let records = [
            ArcheryRecord(
                id: UUID(),
                bowType: "Compound",
                distance: "18",
                targetType: "40cm",
                scores: ["10", "9", "7", "1"],
                date: Date(),
                numberOfArrows: 4
            )
        ]

        let stats = ScoreAnalytics.calculateComprehensiveStats(records: records, groupRecords: [], timeRange: 3)

        #expect(abs(stats.accuracyRate - 50) < 0.0001)
        #expect(stats.totalShots == 4)
    }

    @Test func impactAnalysisUsesRealArrowHitsAndDominantTargetType() {
        let dominantTargetRecord = ArcheryGroupRecord(
            bowType: "Compound",
            distance: "18",
            targetType: TargetFaceType.full40cm.rawValue,
            groupScores: [["10", "9", "9"]],
            date: Date(),
            numberOfGroups: 1,
            arrowsPerGroup: 3,
            groupArrowHits: [[
                ArrowHit(position: CGPoint(x: -2.0, y: 2.0), score: 10, ringNumber: 10, groupIndex: 0, arrowIndex: 0, targetFaceType: .full40cm),
                ArrowHit(position: CGPoint(x: -1.2, y: 1.6), score: 9, ringNumber: 9, groupIndex: 0, arrowIndex: 1, targetFaceType: .full40cm),
                ArrowHit(position: CGPoint(x: -1.8, y: 2.4), score: 9, ringNumber: 9, groupIndex: 0, arrowIndex: 2, targetFaceType: .full40cm)
            ]]
        )

        let secondaryTargetRecord = ArcheryGroupRecord(
            bowType: "Compound",
            distance: "50",
            targetType: TargetFaceType.full80cm.rawValue,
            groupScores: [["10"]],
            date: Date(),
            numberOfGroups: 1,
            arrowsPerGroup: 1,
            groupArrowHits: [[
                ArrowHit(position: CGPoint(x: 0.5, y: -0.5), score: 10, ringNumber: 10, groupIndex: 0, arrowIndex: 0, targetFaceType: .full80cm)
            ]]
        )

        let summary = ScoreAnalytics.calculateImpactAnalysis(
            records: [],
            groupRecords: [dominantTargetRecord, secondaryTargetRecord],
            timeRange: 3
        )

        #expect(summary.totalHits == 3)
        #expect(summary.targetTypeName == TargetFaceType.full40cm.rawValue)
        #expect(summary.scopeDescription != nil)
        #expect(summary.biasDirection == .lowerLeft)
        #expect(summary.centerOffset > 0)
        #expect(summary.groupingRadius95 > 0)
        #expect(summary.insights.count == 2)
    }

    @Test func impactAnalysisReturnsEmptyStateWithoutArrowHits() {
        let summary = ScoreAnalytics.calculateImpactAnalysis(
            records: [],
            groupRecords: [
                ArcheryGroupRecord(
                    bowType: "Recurve",
                    distance: "18",
                    targetType: TargetFaceType.full40cm.rawValue,
                    groupScores: [["10", "9", "8"]],
                    date: Date(),
                    numberOfGroups: 1,
                    arrowsPerGroup: 3,
                    groupArrowHits: [[]]
                )
            ],
            timeRange: 3
        )

        #expect(summary.hasData == false)
        #expect(summary.totalHits == 0)
        #expect(summary.insights.isEmpty)
    }

    @Test func trendSummaryDetectsRisingMomentum() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.startOfDay(for: Date())
        let records = [
            ArcheryRecord(id: UUID(), bowType: "Compound", distance: "18", targetType: "40cm", scores: ["8", "8", "8"], date: start, numberOfArrows: 3),
            ArcheryRecord(id: UUID(), bowType: "Compound", distance: "18", targetType: "40cm", scores: ["8", "8", "9"], date: calendar.date(byAdding: .day, value: 1, to: start)!, numberOfArrows: 3),
            ArcheryRecord(id: UUID(), bowType: "Compound", distance: "18", targetType: "40cm", scores: ["9", "9", "9"], date: calendar.date(byAdding: .day, value: 2, to: start)!, numberOfArrows: 3),
            ArcheryRecord(id: UUID(), bowType: "Compound", distance: "18", targetType: "40cm", scores: ["10", "9", "9"], date: calendar.date(byAdding: .day, value: 3, to: start)!, numberOfArrows: 3)
        ]

        let summary = ScoreAnalytics.calculateTrendSummary(records: records, groupRecords: [], timeRange: 4)

        #expect(summary.sessionCount == 4)
        #expect(summary.recentWindowCount == 3)
        #expect(summary.baselineWindowCount == 1)
        #expect(summary.momentum == .rising)
        #expect(summary.hasEnoughHistory == true)
        #expect(summary.recentChangePercent > 0)
        #expect(summary.bestAverage >= summary.latestAverage)
        #expect(summary.rollingAveragePoints.count == summary.points.count)
        #expect(summary.insight.message.isEmpty == false)
    }

    @Test func trendSummaryUsesInsufficientInsightForSingleSession() {
        let record = ArcheryRecord(
            id: UUID(),
            bowType: "Compound",
            distance: "18",
            targetType: "40cm",
            scores: ["9", "9", "9"],
            date: Date(),
            numberOfArrows: 3
        )

        let summary = ScoreAnalytics.calculateTrendSummary(records: [record], groupRecords: [], timeRange: 4)

        #expect(summary.sessionCount == 1)
        #expect(summary.hasEnoughHistory == false)
        #expect(summary.baselineWindowCount == 0)
        #expect(summary.insight.message.isEmpty == false)
    }
    
    @Test func targetFaceResolveHitUsesInnerXAndMissRules() throws {
        let manager = TargetFaceManager.shared
        let target = try #require(manager.getTarget(for: .full80cm))
        
        let centerHit = target.resolveHit(at: .zero)
        let missHit = target.resolveHit(at: CGPoint(x: 45, y: 0))
        
        #expect(centerHit.ringNumber == 11)
        #expect(centerHit.score == 10)
        #expect(centerHit.isMiss == false)
        #expect(missHit.isMiss == true)
        #expect(missHit.score == 0)
    }
    
    @Test func tripleVerticalTargetUsesIndependentSpotCenters() throws {
        let manager = TargetFaceManager.shared
        let target = try #require(manager.getTarget(for: .triple40cmVertical))
        let topSpotCenter = try #require(target.spotCentersCm.first)
        let centerSpot = target.spotCentersCm[1]
        let bottomSpot = target.spotCentersCm[2]
        
        let topSpotHit = target.resolveHit(at: topSpotCenter)
        let gapHit = target.resolveHit(at: CGPoint(x: 0, y: -11))
        
        #expect(topSpotHit.ringNumber == 11)
        #expect(topSpotHit.isMiss == false)
        #expect(gapHit.isMiss == true)
        #expect(abs(hypot(topSpotCenter.x - centerSpot.x, topSpotCenter.y - centerSpot.y) - 22) < 0.0001)
        #expect(abs(hypot(centerSpot.x - bottomSpot.x, centerSpot.y - bottomSpot.y) - 22) < 0.0001)
    }
    
    @Test func tripleTriangleTargetUsesWAEquilateralSpacing() throws {
        let manager = TargetFaceManager.shared
        let target = try #require(manager.getTarget(for: .triple40cmTriangle))
        #expect(target.spotCentersCm.count == 3)
        
        let a = target.spotCentersCm[0]
        let b = target.spotCentersCm[1]
        let c = target.spotCentersCm[2]
        
        let ab = hypot(a.x - b.x, a.y - b.y)
        let ac = hypot(a.x - c.x, a.y - c.y)
        let bc = hypot(b.x - c.x, b.y - c.y)
        
        #expect(abs(ab - 22) < 0.0001)
        #expect(abs(ac - 22) < 0.0001)
        #expect(abs(bc - 22) < 0.0001)
    }
    
    @Test func indoorSingleFacesUseWAOfficialInnerTenRadii() throws {
        let manager = TargetFaceManager.shared
        let forty = try #require(manager.getTarget(for: .full40cm))
        let sixty = try #require(manager.getTarget(for: .indoor60cm))
        
        let fortyTen = try #require(forty.getRingByNumber(10))
        let fortyX = try #require(forty.getRingByNumber(11))
        let sixtyTen = try #require(sixty.getRingByNumber(10))
        let sixtyX = try #require(sixty.getRingByNumber(11))
        
        #expect(abs(fortyTen.outerRadius - 2.0) < 0.0001)
        #expect(abs(fortyTen.innerRadius - 1.0) < 0.0001)
        #expect(abs(fortyX.outerRadius - 1.0) < 0.0001)
        #expect(abs(sixtyTen.outerRadius - 3.0) < 0.0001)
        #expect(abs(sixtyTen.innerRadius - 1.5) < 0.0001)
        #expect(abs(sixtyX.outerRadius - 1.5) < 0.0001)
    }
}

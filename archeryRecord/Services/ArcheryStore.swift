import Foundation
import SwiftUI

extension UserDefaults: @retroactive @unchecked Sendable {}

@MainActor
final class ArcheryStore: ObservableObject {
    @Published private(set) var records: [ArcheryRecord] = []
    @Published private(set) var groupRecords: [ArcheryGroupRecord] = []
    @Published private(set) var isICloudSyncEnabled: Bool
    
    // 从 Models 版本保留的常量定义
    private let recordsKey = "archeryRecords"
    private let groupRecordsKey = "archeryGroupRecords"
    private let lastBowTypeKey = "lastBowType"
    private let lastDistanceKey = "lastDistance"
    private let lastTargetTypeKey = "lastTargetType"
    private let iCloudSyncEnabledKey = "iCloudSyncEnabled"
    private let lastModifiedKey = "archeryStoreLastModified"
    private let iCloudSnapshotFileName = "ArcheryStoreSnapshot.json"
    private let userDefaults: UserDefaults
    private let persistenceQueue = DispatchQueue(label: "com.timmy.archeryRecord.persistence", qos: .utility)
    private var lastModifiedAt: Date = .distantPast
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.isICloudSyncEnabled = userDefaults.bool(forKey: iCloudSyncEnabledKey)
        loadRecords()
    }
    
    // 保存最后一次使用的选项
    func saveLastUsedOptions(bowType: String, distance: String, targetType: String) {
        userDefaults.set(bowType, forKey: lastBowTypeKey)
        userDefaults.set(distance, forKey: lastDistanceKey)
        userDefaults.set(targetType, forKey: lastTargetTypeKey)
    }
    
    // 获取最后一次使用的选项
    func getLastUsedOptions() -> (bowType: String, distance: String, targetType: String) {
        let bowType = userDefaults.string(forKey: lastBowTypeKey) ?? L10n.Options.BowType.compound
        let distance = userDefaults.string(forKey: lastDistanceKey) ?? L10n.Options.Distance.d18m
        let targetType = userDefaults.string(forKey: lastTargetTypeKey) ?? L10n.Options.TargetType.tCompoundInner10
        return (bowType, distance, targetType)
    }
    
    func loadRecords() {
        let userDefaults = self.userDefaults
        let recordsKey = self.recordsKey
        let groupRecordsKey = self.groupRecordsKey
        let lastModifiedKey = self.lastModifiedKey
        let iCloudSyncEnabledKey = self.iCloudSyncEnabledKey
        
        persistenceQueue.async {
            let decoder = JSONDecoder()
            let records = userDefaults.data(forKey: recordsKey)
                .flatMap { try? decoder.decode([ArcheryRecord].self, from: $0) } ?? []
            
            let storedGroupRecords = userDefaults.data(forKey: groupRecordsKey)
                .flatMap { try? decoder.decode([ArcheryGroupRecord].self, from: $0) } ?? []
            let migration = Self.migrateLegacyGroupRecords(storedGroupRecords)
            let storedModifiedAt = userDefaults.object(forKey: lastModifiedKey) as? Date
            let resolvedModifiedAt = storedModifiedAt
                ?? Self.inferLastModifiedDate(records: records, groupRecords: migration.records)
            let storedICloudEnabled = userDefaults.bool(forKey: iCloudSyncEnabledKey)
            
            Task { @MainActor in
                self.records = records
                self.groupRecords = migration.records
                self.lastModifiedAt = resolvedModifiedAt
                self.isICloudSyncEnabled = storedICloudEnabled

                if migration.didMigrate || storedModifiedAt == nil {
                    self.persistCurrentState(updatedAt: resolvedModifiedAt, syncToICloud: false)
                }

                if storedICloudEnabled {
                    self.synchronizeWithICloudIfNeeded()
                }
            }
        }
    }
    
    func addRecord(_ record: ArcheryRecord) {
        records.append(record)
        persistCurrentState()
    }
    
    func addGroupRecord(_ record: ArcheryGroupRecord) {
        groupRecords.append(record)
        persistCurrentState()
    }
    
    private func persistCurrentState() {
        persistCurrentState(updatedAt: Date(), syncToICloud: true)
    }

    private func persistCurrentState(updatedAt: Date, syncToICloud: Bool) {
        lastModifiedAt = updatedAt
        let snapshot = StoreSnapshot(records: records, groupRecords: groupRecords, updatedAt: updatedAt)
        persistSnapshotToUserDefaults(snapshot)

        guard syncToICloud, isICloudSyncEnabled else { return }
        persistSnapshotToICloud(snapshot)
    }

    private func persistSnapshotToUserDefaults(_ snapshot: StoreSnapshot) {
        Self.persistSnapshotToUserDefaults(
            snapshot,
            userDefaults: userDefaults,
            recordsKey: recordsKey,
            groupRecordsKey: groupRecordsKey,
            lastModifiedKey: lastModifiedKey,
            queue: persistenceQueue
        )
    }
    
    // 合并两个版本的删除方法
    func deleteRecord(id: UUID) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records.remove(at: index)
            persistCurrentState()
        }
    }
    
    func deleteGroupRecord(id: UUID) {
        if let index = groupRecords.firstIndex(where: { $0.id == id }) {
            groupRecords.remove(at: index)
            persistCurrentState()
        }
    }
    
    func getRecord(id: UUID) -> ArcheryRecord? {
        records.first { $0.id == id }
    }
    
    func getGroupRecord(id: UUID) -> ArcheryGroupRecord? {
        groupRecords.first { $0.id == id }
    }
    
    // 更新团体记录
    func updateGroupRecord(_ record: ArcheryGroupRecord) {
        if let index = groupRecords.firstIndex(where: { $0.id == record.id }) {
            groupRecords[index] = record
            persistCurrentState()
        }
    }
    
    // 更新单人记录
    func updateRecord(_ record: ArcheryRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            persistCurrentState()
        }
    }

    func setICloudSyncEnabled(_ enabled: Bool) {
        guard isICloudSyncEnabled != enabled else { return }

        isICloudSyncEnabled = enabled
        userDefaults.set(enabled, forKey: iCloudSyncEnabledKey)

        if enabled {
            synchronizeWithICloudIfNeeded()
        }
    }

    func synchronizeWithICloudIfNeeded() {
        guard isICloudSyncEnabled else { return }

        let localSnapshot = StoreSnapshot(
            records: records,
            groupRecords: groupRecords,
            updatedAt: lastModifiedAt
        )
        let userDefaults = self.userDefaults
        let recordsKey = self.recordsKey
        let groupRecordsKey = self.groupRecordsKey
        let lastModifiedKey = self.lastModifiedKey
        let iCloudSnapshotFileName = self.iCloudSnapshotFileName

        persistenceQueue.async {
            guard let fileURL = Self.cloudSnapshotURL(fileName: iCloudSnapshotFileName) else { return }

            let cloudSnapshot = Self.loadCloudSnapshot(from: fileURL)

            if let cloudSnapshot {
                if cloudSnapshot.updatedAt > localSnapshot.updatedAt {
                    Self.persistSnapshotToUserDefaults(
                        cloudSnapshot,
                        userDefaults: userDefaults,
                        recordsKey: recordsKey,
                        groupRecordsKey: groupRecordsKey,
                        lastModifiedKey: lastModifiedKey,
                        queue: self.persistenceQueue
                    )

                    Task { @MainActor in
                        self.records = cloudSnapshot.records
                        self.groupRecords = cloudSnapshot.groupRecords
                        self.lastModifiedAt = cloudSnapshot.updatedAt
                    }
                } else if localSnapshot.updatedAt > cloudSnapshot.updatedAt || !Self.snapshotsMatch(localSnapshot, cloudSnapshot) {
                    Self.writeCloudSnapshot(localSnapshot, to: fileURL)
                }
            } else {
                Self.writeCloudSnapshot(localSnapshot, to: fileURL)
            }
        }
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        guard phase == .active else { return }
        synchronizeWithICloudIfNeeded()
    }
    
    nonisolated static func migrateLegacyGroupRecords(_ groupRecords: [ArcheryGroupRecord]) -> (records: [ArcheryGroupRecord], didMigrate: Bool) {
        var migratedRecords = groupRecords
        var didMigrate = false
        
        for index in migratedRecords.indices where migratedRecords[index].groupArrowHits == nil {
            let record = migratedRecords[index]
            migratedRecords[index] = ArcheryGroupRecord(
                id: record.id,
                bowType: record.bowType,
                distance: record.distance,
                targetType: record.targetType,
                groupScores: record.groupScores,
                date: record.date,
                numberOfGroups: record.numberOfGroups,
                arrowsPerGroup: record.arrowsPerGroup,
                groupArrowHits: Array(repeating: [], count: record.numberOfGroups)
            )
            didMigrate = true
        }
        
        return (migratedRecords, didMigrate)
    }

    nonisolated static func inferLastModifiedDate(
        records: [ArcheryRecord],
        groupRecords: [ArcheryGroupRecord]
    ) -> Date {
        let latestSingleDate = records.map(\.date).max() ?? .distantPast
        let latestGroupDate = groupRecords.map(\.date).max() ?? .distantPast
        return max(latestSingleDate, latestGroupDate)
    }

    private func persistSnapshotToICloud(_ snapshot: StoreSnapshot) {
        let iCloudSnapshotFileName = self.iCloudSnapshotFileName

        persistenceQueue.async {
            guard let fileURL = Self.cloudSnapshotURL(fileName: iCloudSnapshotFileName) else { return }
            Self.writeCloudSnapshot(snapshot, to: fileURL)
        }
    }

    nonisolated private static func persistSnapshotToUserDefaults(
        _ snapshot: StoreSnapshot,
        userDefaults: UserDefaults,
        recordsKey: String,
        groupRecordsKey: String,
        lastModifiedKey: String,
        queue: DispatchQueue
    ) {
        queue.async {
            let encoder = JSONEncoder()

            if let encodedRecords = try? encoder.encode(snapshot.records) {
                userDefaults.set(encodedRecords, forKey: recordsKey)
            }

            if let encodedGroupRecords = try? encoder.encode(snapshot.groupRecords) {
                userDefaults.set(encodedGroupRecords, forKey: groupRecordsKey)
            }

            userDefaults.set(snapshot.updatedAt, forKey: lastModifiedKey)
        }
    }

    nonisolated private static func cloudSnapshotURL(fileName: String) -> URL? {
        let fileManager = FileManager.default
        guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            return nil
        }

        let documentsURL = containerURL.appendingPathComponent("Documents", isDirectory: true)

        if !fileManager.fileExists(atPath: documentsURL.path) {
            try? fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        }

        return documentsURL.appendingPathComponent(fileName, isDirectory: false)
    }

    nonisolated private static func loadCloudSnapshot(from fileURL: URL) -> StoreSnapshot? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        if fileManager.isUbiquitousItem(at: fileURL) {
            try? fileManager.startDownloadingUbiquitousItem(at: fileURL)
        }

        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var snapshot: StoreSnapshot?

        coordinator.coordinate(readingItemAt: fileURL, options: [], error: &coordinationError) { coordinatedURL in
            guard
                let data = try? Data(contentsOf: coordinatedURL),
                let decodedSnapshot = try? JSONDecoder().decode(StoreSnapshot.self, from: data)
            else {
                return
            }

            snapshot = decodedSnapshot
        }

        return snapshot
    }

    nonisolated private static func writeCloudSnapshot(_ snapshot: StoreSnapshot, to fileURL: URL) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }

        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?

        coordinator.coordinate(writingItemAt: fileURL, options: [], error: &coordinationError) { coordinatedURL in
            try? data.write(to: coordinatedURL, options: Data.WritingOptions.atomic)
        }
    }

    nonisolated private static func snapshotsMatch(_ lhs: StoreSnapshot, _ rhs: StoreSnapshot) -> Bool {
        guard
            let lhsData = try? JSONEncoder().encode(lhs),
            let rhsData = try? JSONEncoder().encode(rhs)
        else {
            return false
        }

        return lhsData == rhsData
    }
    
    private struct StoreSnapshot: Codable {
        let records: [ArcheryRecord]
        let groupRecords: [ArcheryGroupRecord]
        let updatedAt: Date
    }
}

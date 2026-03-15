import Foundation

extension Notification.Name {
    static let recordsDidChange = Notification.Name("recordsDidChange")
}

class ArcheryStore: ObservableObject {
    @Published private(set) var records: [ArcheryRecord] = []
    @Published private(set) var groupRecords: [ArcheryGroupRecord] = []
    
    // 从 Models 版本保留的常量定义
    private let recordsKey = "archeryRecords"
    private let groupRecordsKey = "archeryGroupRecords"
    private let lastBowTypeKey = "lastBowType"
    private let lastDistanceKey = "lastDistance"
    private let lastTargetTypeKey = "lastTargetType"
    
    init() {
        loadRecords()
    }
    
    // 保存最后一次使用的选项
    func saveLastUsedOptions(bowType: String, distance: String, targetType: String) {
        UserDefaults.standard.set(bowType, forKey: lastBowTypeKey)
        UserDefaults.standard.set(distance, forKey: lastDistanceKey)
        UserDefaults.standard.set(targetType, forKey: lastTargetTypeKey)
    }
    
    // 获取最后一次使用的选项
    func getLastUsedOptions() -> (bowType: String, distance: String, targetType: String) {
        let bowType = UserDefaults.standard.string(forKey: lastBowTypeKey) ?? L10n.Options.BowType.compound
        let distance = UserDefaults.standard.string(forKey: lastDistanceKey) ?? L10n.Options.Distance.d18m
        let targetType = UserDefaults.standard.string(forKey: lastTargetTypeKey) ?? L10n.Options.TargetType.tCompoundInner10
        return (bowType, distance, targetType)
    }
    
    func loadRecords() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let records = UserDefaults.standard.data(forKey: self.recordsKey)
                .flatMap { try? JSONDecoder().decode([ArcheryRecord].self, from: $0) } ?? []
            
            var groupRecords = UserDefaults.standard.data(forKey: self.groupRecordsKey)
                .flatMap { try? JSONDecoder().decode([ArcheryGroupRecord].self, from: $0) } ?? []
            
            // 数据迁移：为缺少groupArrowHits的记录添加空数组
            var needsMigration = false
            for i in 0..<groupRecords.count {
                if groupRecords[i].groupArrowHits == nil {
                    // 为每组创建空的ArrowHit数组
                    var groupArrowHits: [[ArrowHit]] = []
                    for _ in 0..<groupRecords[i].numberOfGroups {
                        groupArrowHits.append([])
                    }
                    
                    // 创建新的记录实例，包含迁移的数据
                    groupRecords[i] = ArcheryGroupRecord(
                        id: groupRecords[i].id,
                        bowType: groupRecords[i].bowType,
                        distance: groupRecords[i].distance,
                        targetType: groupRecords[i].targetType,
                        groupScores: groupRecords[i].groupScores,
                        date: groupRecords[i].date,
                        numberOfGroups: groupRecords[i].numberOfGroups,
                        arrowsPerGroup: groupRecords[i].arrowsPerGroup,
                        groupArrowHits: groupArrowHits
                    )
                    needsMigration = true
                }
            }
            
            DispatchQueue.main.async {
                self.records = records
                self.groupRecords = groupRecords
                
                // 如果进行了数据迁移，保存更新后的数据
                if needsMigration {
                    self.saveRecords()
                }
            }
        }
    }
    
    func addRecord(_ record: ArcheryRecord) {
        DispatchQueue.main.async {
            self.records.append(record)
            self.objectWillChange.send()
            self.saveRecords()
            
            // 发送通知
            NotificationCenter.default.post(name: .recordsDidChange, object: nil)
        }
    }
    
    func addGroupRecord(_ record: ArcheryGroupRecord) {
        DispatchQueue.main.async {
            self.groupRecords.append(record)
            self.objectWillChange.send()
            self.saveRecords()
            
            // 发送通知
            NotificationCenter.default.post(name: .recordsDidChange, object: nil)
        }
    }
    
    private func saveRecords() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            if let encodedRecords = try? JSONEncoder().encode(self.records) {
                UserDefaults.standard.set(encodedRecords, forKey: self.recordsKey)
            }
            
            if let encodedGroupRecords = try? JSONEncoder().encode(self.groupRecords) {
                UserDefaults.standard.set(encodedGroupRecords, forKey: self.groupRecordsKey)
            }
            
            DispatchQueue.main.async {
                self.objectWillChange.send()
                // 保存完成后也发送通知
                NotificationCenter.default.post(name: .recordsDidChange, object: nil)
            }
        }
    }
    
    // 合并两个版本的删除方法
    func deleteRecord(id: UUID) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records.remove(at: index)
            objectWillChange.send()
            saveRecords()
            
            // 发送通知
            NotificationCenter.default.post(name: .recordsDidChange, object: nil)
        }
    }
    
    func deleteGroupRecord(id: UUID) {
        if let index = groupRecords.firstIndex(where: { $0.id == id }) {
            groupRecords.remove(at: index)
            objectWillChange.send()
            saveRecords()
            
            // 发送通知
            NotificationCenter.default.post(name: .recordsDidChange, object: nil)
        }
    }
    
    // 改进的获取记录方法
    func getRecord(id: UUID, type: String) -> ArcheryRecord? {
        if type == "single" {
            return records.first { $0.id == id }
        }
        return nil
    }
    
    func getGroupRecord(id: UUID, type: String) -> ArcheryGroupRecord? {
        if type == "group" {
            return groupRecords.first { $0.id == id }
        }
        return nil
    }
    
    // 更新团体记录
    func updateGroupRecord(_ record: ArcheryGroupRecord) {
        DispatchQueue.main.async {
            if let index = self.groupRecords.firstIndex(where: { $0.id == record.id }) {
                self.groupRecords[index] = record
                self.objectWillChange.send()
                self.saveRecords()
                
                // 发送通知
                NotificationCenter.default.post(name: .recordsDidChange, object: nil)
            }
        }
    }
    
    // 更新单人记录
    func updateRecord(_ record: ArcheryRecord) {
        DispatchQueue.main.async {
            if let index = self.records.firstIndex(where: { $0.id == record.id }) {
                self.records[index] = record
                self.objectWillChange.send()
                self.saveRecords()
                
                // 发送通知
                NotificationCenter.default.post(name: .recordsDidChange, object: nil)
            }
        }
    }
}
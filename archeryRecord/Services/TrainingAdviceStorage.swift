import Foundation

class TrainingAdviceStorage {
    private static let key = "training_advice"
    
    static func save(_ advice: TrainingAdvice) {
        var stored = load()
        let key = makeKey(id: advice.recordId, type: advice.recordType)
        stored[key] = advice
        
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: self.key)
        }
    }
    
    static func load() -> [String: TrainingAdvice] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode([String: TrainingAdvice].self, from: data)
        else {
            return [:]
        }
        return stored
    }
    
    static func get(for recordId: UUID, type: ArcheryRecordType) -> TrainingAdvice? {
        let key = makeKey(id: recordId, type: type)
        let stored = load()
        return stored[key]
    }
    
    private static func makeKey(id: UUID, type: ArcheryRecordType) -> String {
        return "\(id.uuidString)_\(type.rawValue)"
    }
    
    // 添加清除方法
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

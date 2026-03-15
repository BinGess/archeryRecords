func loadRecords() {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        // 在后台线程加载数据
        let groupRecords = UserDefaults.standard.data(forKey: self.groupRecordsKey)
            .flatMap { try? JSONDecoder().decode([ArcheryGroupRecord].self, from: $0) } ?? []
        
        DispatchQueue.main.async {
            // 在主线程更新@Published属性
            self.groupRecords = groupRecords
        }
    }
}
import SwiftUI

@main
struct ArcheryRecordApp: App {
    @StateObject private var archeryStore = ArcheryStore()
    
    init() {
        // 初始化语言设置
        if UserDefaults.standard.string(forKey: "AppLanguage") == nil {
            let systemLanguage = Locale.current.languageCode ?? "en"
            if L10n.getSupportedLanguages().contains(systemLanguage) {
                L10n.setLanguage(systemLanguage)
            } else {
                L10n.setLanguage("en")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(archeryStore)
        }
    }
} 
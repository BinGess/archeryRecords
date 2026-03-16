import SwiftUI

@main
struct ArcheryRecordApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var archeryStore = ArcheryStore()
    @StateObject private var localizationManager = LocalizationManager()
    @StateObject private var purchaseManager = PurchaseManager()
    
    var body: some Scene {
        WindowGroup {
            LaunchScreenHostView {
                MainView()
                    .id(localizationManager.currentLanguage)
                    .environment(\.locale, Locale(identifier: localizationManager.currentLanguage))
                    .environmentObject(archeryStore)
                    .environmentObject(localizationManager)
                    .environmentObject(purchaseManager)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            archeryStore.handleScenePhaseChange(newPhase)
        }
    }
} 

//
//  ContractorCashFlowApp.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI
import SwiftData

@main
struct ContractorCashFlowApp: App {
    @State private var appState = AppState()
    @State private var languageManager = LanguageManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Project.self,
            Expense.self,
            Invoice.self,
            Client.self,
            LaborDetails.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema migration failed — delete the old store and recreate
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appState)
                .environment(languageManager)
                .environment(\.locale, languageManager.currentLocale)
                .environment(\.layoutDirection, languageManager.layoutDirection)
                .id(languageManager.currentLanguage.rawValue) // Force view recreation on language change
                .task {
                    // Request notification permission on first launch
                    await NotificationService.shared.requestPermissionIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

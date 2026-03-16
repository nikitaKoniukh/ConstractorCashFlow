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
    @State private var purchaseManager = PurchaseManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Project.self,
            Expense.self,
            Invoice.self,
            Client.self,
            LaborDetails.self
        ])
        
        // Try CloudKit first; fall back to local-only if it fails.
        // IMPORTANT: Never delete the store on failure — that would wipe user data.
        do {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            print("CloudKit ModelContainer failed: \(error). Using local-only storage.")
            // Fall back to local-only so the app doesn't crash and data is preserved.
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
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
                .environment(purchaseManager)
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

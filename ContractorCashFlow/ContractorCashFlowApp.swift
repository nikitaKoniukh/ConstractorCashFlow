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
        
        // Use an in-memory store during UI testing so each test run starts clean.
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            let testConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [testConfig])
            } catch {
                fatalError("Could not create in-memory ModelContainer for UI tests: \(error)")
            }
        }
        
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
                    // Wire appState so notification taps can trigger navigation
                    NotificationService.shared.appState = appState
                    // Request notification permission on first launch
                    await NotificationService.shared.requestPermissionIfNeeded()
                }
                .task {
                    // Reschedule notifications on every launch so overdue invoices
                    // that were created while the app was closed still fire
                    await NotificationService.shared.rescheduleAllInvoiceNotifications(
                        from: sharedModelContainer.mainContext
                    )
                    // Check budget thresholds on every launch
                    await NotificationService.shared.rescheduleAllBudgetNotifications(
                        from: sharedModelContainer.mainContext
                    )
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

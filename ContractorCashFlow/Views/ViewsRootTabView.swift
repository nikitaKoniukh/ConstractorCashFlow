//
//  RootTabView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView(selection: Binding(
            get: { appState.selectedTab },
            set: { appState.selectedTab = $0 }
        )) {
            ProjectsListView()
                .tabItem {
                    Label(AppTab.projects.displayNameKey, systemImage: AppTab.projects.iconName)
                }
                .tag(AppTab.projects)
            
            ExpensesListView()
                .tabItem {
                    Label(AppTab.expenses.displayNameKey, systemImage: AppTab.expenses.iconName)
                }
                .tag(AppTab.expenses)
            
            InvoicesListView()
                .tabItem {
                    Label(AppTab.invoices.displayNameKey, systemImage: AppTab.invoices.iconName)
                }
                .tag(AppTab.invoices)
            
            ClientsListView()
                .tabItem {
                    Label(AppTab.clients.displayNameKey, systemImage: AppTab.clients.iconName)
                }
                .tag(AppTab.clients)

            LaborListView()
                .tabItem {
                    Label(AppTab.labor.displayNameKey, systemImage: AppTab.labor.iconName)
                }
                .tag(AppTab.labor)
            
            AnalyticsView()
                .tabItem {
                    Label(AppTab.analytics.displayNameKey, systemImage: AppTab.analytics.iconName)
                }
                .tag(AppTab.analytics)

            SettingsView()
                .tabItem {
                    Label(AppTab.settings.displayNameKey, systemImage: AppTab.settings.iconName)
                }
                .tag(AppTab.settings)
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self, LaborDetails.self], inMemory: true)
}

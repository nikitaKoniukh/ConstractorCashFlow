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
                    Label(AppTab.projects.displayName, systemImage: AppTab.projects.iconName)
                }
                .tag(AppTab.projects)
            
            ExpensesListView()
                .tabItem {
                    Label(AppTab.expenses.displayName, systemImage: AppTab.expenses.iconName)
                }
                .tag(AppTab.expenses)
            
            InvoicesListView()
                .tabItem {
                    Label(AppTab.invoices.displayName, systemImage: AppTab.invoices.iconName)
                }
                .tag(AppTab.invoices)
            
            ClientsListView()
                .tabItem {
                    Label(AppTab.clients.displayName, systemImage: AppTab.clients.iconName)
                }
                .tag(AppTab.clients)
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

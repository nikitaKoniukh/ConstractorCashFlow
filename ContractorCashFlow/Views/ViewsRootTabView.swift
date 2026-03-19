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
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]
    @Query private var invoices: [Invoice]

    var body: some View {
        TabView(selection: Binding(
            get: { appState.selectedTab },
            set: { newTab in
                if newTab == appState.selectedTab {
                    appState.popToRoot(tab: newTab)
                } else {
                    appState.popToRoot(tab: appState.selectedTab)
                }
                appState.selectedTab = newTab
            }
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

            LaborListView()
                .tabItem {
                    Label(AppTab.labor.displayNameKey, systemImage: AppTab.labor.iconName)
                }
                .tag(AppTab.labor)

            ClientsListView()
                .tabItem {
                    Label(AppTab.clients.displayNameKey, systemImage: AppTab.clients.iconName)
                }
                .tag(AppTab.clients)

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
        .onChange(of: appState.pendingProjectID) { _, projectID in
            navigateToProject(id: projectID)
        }
        .onChange(of: projects) { _, _ in
            // Projects just loaded — handle any pending navigation from a cold launch tap
            if let projectID = appState.pendingProjectID {
                navigateToProject(id: projectID)
            }
        }
        .sheet(item: Binding(
            get: { invoices.first(where: { $0.id == appState.pendingInvoiceID }) },
            set: { if $0 == nil { appState.pendingInvoiceID = nil } }
        )) { invoice in
            EditInvoiceView(invoice: invoice)
        }
    }

    private func navigateToProject(id projectID: UUID?) {
        guard let projectID,
              let project = projects.first(where: { $0.id == projectID }) else { return }
        appState.selectedTab = .projects
        appState.popToRoot(tab: .projects)
        appState.navigationPaths[.projects] = NavigationPath([project])
        appState.pendingProjectID = nil
    }
}

#Preview {
    RootTabView()
        .environment(AppState())
        .environment(LanguageManager.shared)
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self, LaborDetails.self], inMemory: true)
}

//
//  AppState.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI

/// Observable class for managing shared application state
@Observable
@MainActor
final class AppState {
    /// Currently selected tab in the main tab view
    var selectedTab: AppTab = .projects
    
    /// Currently selected project (for navigation and filtering)
    var selectedProject: Project?
    
    /// Flag to show/hide project creation sheet
    var isShowingNewProject: Bool = false
    
    /// Flag to show/hide expense creation sheet
    var isShowingNewExpense: Bool = false
    
    /// Flag to show/hide invoice creation sheet
    var isShowingNewInvoice: Bool = false
    
    /// Flag to show/hide client creation sheet
    var isShowingNewClient: Bool = false

    /// Flag to show/hide labor creation sheet
    var isShowingNewLabor: Bool = false
    
    /// Navigation paths for each tab (to support pop-to-root on tab re-tap)
    var navigationPaths: [AppTab: NavigationPath] = [:]
    
    /// Resets the navigation path for a given tab, popping to root
    func popToRoot(tab: AppTab) {
        navigationPaths[tab] = NavigationPath()
    }
    
    /// Returns a binding to the NavigationPath for the given tab
    func navigationPath(for tab: AppTab) -> Binding<NavigationPath> {
        Binding(
            get: { self.navigationPaths[tab, default: NavigationPath()] },
            set: { self.navigationPaths[tab] = $0 }
        )
    }
    
    /// Search query for filtering
    var searchQuery: String = ""
    
    // MARK: - Error Handling
    
    /// Error message to display in alert
    var errorMessage: String?
    
    /// Flag to show/hide error alert
    var isShowingError: Bool = false
    
    /// Shows an error alert with the given message
    func showError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
    
    /// Project ID to navigate to (set when tapping a budget warning notification)
    var pendingProjectID: UUID?

    /// Invoice ID to open (set when tapping an overdue/upcoming notification)
    var pendingInvoiceID: UUID?

    init() {}
}

/// Enum representing the main tabs in the application
enum AppTab: String, CaseIterable {
    case projects = "Projects"
    case expenses = "Expenses"
    case invoices = "Invoices"
    case clients = "Clients"
    case labor = "Labor"
    case analytics = "Analytics"
    case settings = "Settings"
    
    var iconName: String {
        switch self {
        case .projects:
            return "folder.fill"
        case .expenses:
            return "dollarsign.circle.fill"
        case .invoices:
            return "doc.text.fill"
        case .clients:
            return "person.2.fill"
        case .labor:
            return "person.3.fill"
        case .analytics:
            return "chart.bar.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
    
    var displayNameKey: LocalizedStringKey {
        switch self {
        case .projects:
            return LocalizationKey.Tab.projects
        case .expenses:
            return LocalizationKey.Tab.expenses
        case .invoices:
            return LocalizationKey.Tab.invoices
        case .clients:
            return LocalizationKey.Tab.clients
        case .labor:
            return LocalizationKey.Tab.labor
        case .analytics:
            return LocalizationKey.Tab.analytics
        case .settings:
            return LocalizationKey.Tab.settings
        }
    }
}

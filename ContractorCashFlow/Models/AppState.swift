//
//  AppState.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI

/// Observable class for managing shared application state
@Observable
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
    
    /// Search query for filtering
    var searchQuery: String = ""
    
    init() {}
}

/// Enum representing the main tabs in the application
enum AppTab: String, CaseIterable {
    case projects = "Projects"
    case expenses = "Expenses"
    case invoices = "Invoices"
    case clients = "Clients"
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
        case .analytics:
            return LocalizationKey.Tab.analytics
        case .settings:
            return LocalizationKey.Tab.settings
        }
    }
}

//
//  LocalizationKeys.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI

/// Organized localization keys for type-safe string access
/// All keys correspond to entries in Localizable.xcstrings
enum LocalizationKey {
    
    // MARK: - Dashboard
    enum Dashboard {
        static let title = LocalizedStringKey("dashboard.title")
        static let totalBalance = LocalizedStringKey("dashboard.totalBalance")
        static let income = LocalizedStringKey("dashboard.income")
        static let expenses = LocalizedStringKey("dashboard.expenses")
    }
    
    // MARK: - Projects
    enum Project {
        static let title = LocalizedStringKey("project.title")
        static let add = LocalizedStringKey("project.add")
        static let name = LocalizedStringKey("project.name")
        static let clientName = LocalizedStringKey("project.clientName")
        static let description = LocalizedStringKey("project.description")
        static let budget = LocalizedStringKey("project.budget")
        static let information = LocalizedStringKey("project.information")
        static let active = LocalizedStringKey("project.active")
        static let newTitle = LocalizedStringKey("project.newTitle")
        static let detailTitle = LocalizedStringKey("project.detailTitle")
        static let empty = LocalizedStringKey("project.empty")
        static let emptyDescription = LocalizedStringKey("project.emptyDescription")
        static let balance = LocalizedStringKey("project.balance")
    }
    
    // MARK: - Expenses
    enum Expense {
        static let title = LocalizedStringKey("expense.title")
        static let add = LocalizedStringKey("expense.add")
        static let amount = LocalizedStringKey("expense.amount")
        static let category = LocalizedStringKey("expense.category")
        static let description = LocalizedStringKey("expense.description")
        static let date = LocalizedStringKey("expense.date")
        static let details = LocalizedStringKey("expense.details")
        static let project = LocalizedStringKey("expense.project")
        static let projectOptional = LocalizedStringKey("expense.projectOptional")
        static let none = LocalizedStringKey("expense.none")
        static let newTitle = LocalizedStringKey("expense.newTitle")
        static let empty = LocalizedStringKey("expense.empty")
        static let emptyDescription = LocalizedStringKey("expense.emptyDescription")
        
        // Categories
        static let materials = LocalizedStringKey("expense.category.materials")
        static let labor = LocalizedStringKey("expense.category.labor")
        static let equipment = LocalizedStringKey("expense.category.equipment")
        static let miscellaneous = LocalizedStringKey("expense.category.miscellaneous")
    }
    
    // MARK: - Invoices
    enum Invoice {
        static let title = LocalizedStringKey("invoice.title")
        static let add = LocalizedStringKey("invoice.add")
        static let amount = LocalizedStringKey("invoice.amount")
        static let dueDate = LocalizedStringKey("invoice.dueDate")
        static let clientName = LocalizedStringKey("invoice.clientName")
        static let details = LocalizedStringKey("invoice.details")
        static let project = LocalizedStringKey("invoice.project")
        static let projectOptional = LocalizedStringKey("invoice.projectOptional")
        static let none = LocalizedStringKey("invoice.none")
        static let newTitle = LocalizedStringKey("invoice.newTitle")
        static let pending = LocalizedStringKey("invoice.status.pending")
        static let duePrefix = LocalizedStringKey("invoice.duePrefix")
        static let empty = LocalizedStringKey("invoice.empty")
        static let emptyDescription = LocalizedStringKey("invoice.emptyDescription")
        
        // Status
        static let paid = LocalizedStringKey("invoice.status.paid")
        static let unpaid = LocalizedStringKey("invoice.status.unpaid")
        static let overdue = LocalizedStringKey("invoice.status.overdue")
    }
    
    // MARK: - Clients
    enum Client {
        static let title = LocalizedStringKey("client.title")
        static let add = LocalizedStringKey("client.add")
        static let name = LocalizedStringKey("client.name")
        static let email = LocalizedStringKey("client.email")
        static let phone = LocalizedStringKey("client.phone")
        static let address = LocalizedStringKey("client.address")
        static let notes = LocalizedStringKey("client.notes")
        static let information = LocalizedStringKey("client.information")
        static let newTitle = LocalizedStringKey("client.newTitle")
        static let empty = LocalizedStringKey("client.empty")
        static let emptyDescription = LocalizedStringKey("client.emptyDescription")
    }
    
    // MARK: - Settings
    enum Settings {
        static let title = LocalizedStringKey("settings.title")
        static let language = LocalizedStringKey("settings.language")
        static let languageSection = LocalizedStringKey("settings.languageSection")
        static let languageFooter = LocalizedStringKey("settings.languageFooter")
        static let currency = LocalizedStringKey("settings.currency")
        static let notifications = LocalizedStringKey("settings.notifications")
        static let notificationsFooter = LocalizedStringKey("settings.notificationsFooter")
        static let invoiceReminders = LocalizedStringKey("settings.notifications.invoiceReminders")
        static let overdueAlerts = LocalizedStringKey("settings.notifications.overdueAlerts")
        static let budgetWarnings = LocalizedStringKey("settings.notifications.budgetWarnings")
        static let dataSection = LocalizedStringKey("settings.dataSection")
        static let exportData = LocalizedStringKey("settings.exportData")
        static let exportFooter = LocalizedStringKey("settings.exportFooter")
        static let aboutSection = LocalizedStringKey("settings.aboutSection")
        static let about = LocalizedStringKey("settings.about")
        static let appVersion = LocalizedStringKey("settings.appVersion")
    }
    
    // MARK: - Common Actions
    enum Action {
        static let save = LocalizedStringKey("action.save")
        static let cancel = LocalizedStringKey("action.cancel")
        static let delete = LocalizedStringKey("action.delete")
        static let edit = LocalizedStringKey("action.edit")
        static let search = LocalizedStringKey("action.search")
        static let done = LocalizedStringKey("action.done")
        static let add = LocalizedStringKey("action.add")
    }
    
    // MARK: - Tab Bar
    enum Tab {
        static let projects = LocalizedStringKey("tab.projects")
        static let expenses = LocalizedStringKey("tab.expenses")
        static let invoices = LocalizedStringKey("tab.invoices")
        static let clients = LocalizedStringKey("tab.clients")
        static let settings = LocalizedStringKey("tab.settings")
    }
}

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
        static let editTitle = LocalizedStringKey("invoice.editTitle")
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
    enum ClientS {
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
    
    // MARK: - Labor
    enum Labor {
        static let title = LocalizedStringKey("labor.title")
        static let add = LocalizedStringKey("labor.add")
        static let addTitle = LocalizedStringKey("labor.addTitle")
        static let editTitle = LocalizedStringKey("labor.editTitle")
        static let deleteLabel = LocalizedStringKey("labor.delete")
        static let filtersButton = LocalizedStringKey("labor.filtersButton")
        static let sortButton = LocalizedStringKey("labor.sortButton")
        static let hourUnitShort = LocalizedStringKey("labor.hourUnitShort")
        static let hourlyRateSuffix = LocalizedStringKey("labor.hourlyRateSuffix")
        
        // Basic Information
        static let basicInfo = LocalizedStringKey("labor.basicInfo")
        static let workerNamePlaceholder = LocalizedStringKey("labor.workerName")
        static let typeLabel = LocalizedStringKey("labor.type")
        static let workDateLabel = LocalizedStringKey("labor.workDate")
        static let completedLabel = LocalizedStringKey("labor.completed")
        
        // Labor Types
        static let hourly = LocalizedStringKey("labor.type.hourly")
        static let daily = LocalizedStringKey("labor.type.daily")
        static let contract = LocalizedStringKey("labor.type.contract")
        static let subcontractor = LocalizedStringKey("labor.type.subcontractor")
        
        // Rate and Hours
        static let rateAndHours = LocalizedStringKey("labor.rateAndHours")
        static let hourlyRateLabel = LocalizedStringKey("labor.hourlyRate")
        static let hoursWorkedLabel = LocalizedStringKey("labor.hoursWorked")
        static let calculatedTotal = LocalizedStringKey("labor.calculatedTotal")
        
        // Amount
        static let totalAmount = LocalizedStringKey("labor.totalAmount")
        static let amountLabel = LocalizedStringKey("labor.amount")
        static let manualOverrideHint = LocalizedStringKey("labor.manualOverrideHint")
        
        // Project Association
        static let projectAssociation = LocalizedStringKey("labor.projectAssociation")
        static let selectProject = LocalizedStringKey("labor.selectProject")
        static let noProject = LocalizedStringKey("labor.noProject")
        static let allProjects = LocalizedStringKey("labor.allProjects")
        static let createExpenseToggle = LocalizedStringKey("labor.createExpenseToggle")
        static let createExpenseHint = LocalizedStringKey("labor.createExpenseHint")
        static let linkedToExpense = LocalizedStringKey("labor.linkedToExpense")
        static let expenseLinked = LocalizedStringKey("labor.expenseLinked")
        
        // Notes
        static let notesLabel = LocalizedStringKey("labor.notes")
        static let notesPlaceholder = LocalizedStringKey("labor.notesPlaceholder")
        
        // List View
        static let searchPrompt = LocalizedStringKey("labor.searchPrompt")
        static let sortBy = LocalizedStringKey("labor.sortBy")
        static let noLabor = LocalizedStringKey("labor.noLabor")
        static let noLaborDescription = LocalizedStringKey("labor.noLaborDescription")
        static let noResults = LocalizedStringKey("labor.noResults")
        static let sortDateNewest = LocalizedStringKey("labor.sort.dateNewest")
        static let sortDateOldest = LocalizedStringKey("labor.sort.dateOldest")
        static let sortAmountHighToLow = LocalizedStringKey("labor.sort.amountHighToLow")
        static let sortAmountLowToHigh = LocalizedStringKey("labor.sort.amountLowToHigh")
        static let sortWorkerName = LocalizedStringKey("labor.sort.workerName")
        
        // Summary
        static let totalCost = LocalizedStringKey("labor.totalCost")
        static let totalHours = LocalizedStringKey("labor.totalHours")
        static let totalEntries = LocalizedStringKey("labor.totalEntries")
        static let completedJobs = LocalizedStringKey("labor.completedJobs")
        static let completed = LocalizedStringKey("labor.status.completed")
        
        // Filters
        static let filters = LocalizedStringKey("labor.filters")
        static let laborType = LocalizedStringKey("labor.laborType")
        static let allTypes = LocalizedStringKey("labor.allTypes")
        static let project = LocalizedStringKey("labor.project")
        static let status = LocalizedStringKey("labor.status")
        static let showCompletedOnly = LocalizedStringKey("labor.showCompletedOnly")
        static let dateRange = LocalizedStringKey("labor.dateRange")
        static let useStartDate = LocalizedStringKey("labor.useStartDate")
        static let startDate = LocalizedStringKey("labor.startDate")
        static let useEndDate = LocalizedStringKey("labor.useEndDate")
        static let endDate = LocalizedStringKey("labor.endDate")
        static let clearFilters = LocalizedStringKey("labor.clearFilters")
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
    
    // MARK: - General
    enum General {
        static let save = LocalizedStringKey("action.save")
        static let cancel = LocalizedStringKey("action.cancel")
        static let delete = LocalizedStringKey("action.delete")
        static let edit = LocalizedStringKey("action.edit")
        static let done = LocalizedStringKey("action.done")
        static let add = LocalizedStringKey("action.add")
        static let error = LocalizedStringKey("general.error")
        static let ok = LocalizedStringKey("general.ok")
        static let genericError = LocalizedStringKey("general.genericError")
    }
    
    // MARK: - Analytics
    enum Analytics {
        static let title = LocalizedStringKey("analytics.title")
        static let incomeVsExpenses = LocalizedStringKey("analytics.incomeVsExpenses")
        static let expensesByCategory = LocalizedStringKey("analytics.expensesByCategory")
        static let budgetUtilization = LocalizedStringKey("analytics.budgetUtilization")
        static let netBalance = LocalizedStringKey("analytics.netBalance")
        static let income = LocalizedStringKey("analytics.income")
        static let expenses = LocalizedStringKey("analytics.expenses")
        static let averageUtilization = LocalizedStringKey("analytics.averageUtilization")
        static let noFinancialData = LocalizedStringKey("analytics.noFinancialData")
        static let noExpenseData = LocalizedStringKey("analytics.noExpenseData")
        static let noProjectData = LocalizedStringKey("analytics.noProjectData")
        
        // Chart legend labels
        static let spent = LocalizedStringKey("analytics.spent")
        static let remaining = LocalizedStringKey("analytics.remaining")
        
        // Chart dimension labels (for accessibility)
        static let chartAmount = LocalizedStringKey("analytics.chart.amount")
        static let chartCategory = LocalizedStringKey("analytics.chart.category")
        static let chartProject = LocalizedStringKey("analytics.chart.project")
        static let chartType = LocalizedStringKey("analytics.chart.type")
    }
    
    // MARK: - Tab Bar
    enum Tab {
        static let projects = LocalizedStringKey("tab.projects")
        static let expenses = LocalizedStringKey("tab.expenses")
        static let invoices = LocalizedStringKey("tab.invoices")
        static let clients = LocalizedStringKey("tab.clients")
        static let labor = LocalizedStringKey("tab.labor")
        static let analytics = LocalizedStringKey("tab.analytics")
        static let settings = LocalizedStringKey("tab.settings")
    }
}

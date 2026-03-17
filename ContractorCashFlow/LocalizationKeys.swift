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
        static let balanceString = String(localized: "project.balance.label")
        static let searchPrompt = LocalizedStringKey("Search by name or client")
        static let status = LocalizedStringKey("Status")
        static let inactive = LocalizedStringKey("Inactive")
        static let created = LocalizedStringKey("Created")
        static let budgetUtilizationTitle = LocalizedStringKey("Budget Utilization")
        static let spent = LocalizedStringKey("Spent")
        static let remaining = LocalizedStringKey("Remaining")
        static let noExpensesRecorded = LocalizedStringKey("No expenses recorded")
        static let addFirstExpense = LocalizedStringKey("Add First Expense")
        static let noInvoicesCreated = LocalizedStringKey("No invoices created")
        static let addFirstInvoice = LocalizedStringKey("Add First Invoice")
        static let budgetUsedFormat = String(localized: "%@%% of budget")
        static let invoices = LocalizedStringKey("Invoices")
        static let editProject = LocalizedStringKey("Edit Project")
        static let exportAndShare = LocalizedStringKey("Export & Share")
        static let netBalance = LocalizedStringKey("Net Balance")
        static let profitMargin = LocalizedStringKey("Profit Margin")
        static let invoiceToFormat = String(localized: "Invoice to %@")
        static let dueFormat = String(localized: "Due %@")
        static let paidCountFormat = String(localized: "%lld/%lld paid")
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
        static let searchPrompt = LocalizedStringKey("Search expenses")
        static let filters = LocalizedStringKey("Filters")
        static let noMatchingExpenses = LocalizedStringKey("No matching expenses")
        static let filterCategorySection = LocalizedStringKey("Category")
        static let filterByCategory = LocalizedStringKey("Filter by Category")
        static let allCategories = LocalizedStringKey("All Categories")
        static let dateRange = LocalizedStringKey("Date Range")
        static let startDate = LocalizedStringKey("Start Date")
        static let from = LocalizedStringKey("From")
        static let endDate = LocalizedStringKey("End Date")
        static let to = LocalizedStringKey("To")
        static let clearAllFilters = LocalizedStringKey("Clear All Filters")
        static let filterExpensesTitle = LocalizedStringKey("Filter Expenses")
        static let noResultsSearchFallback = String(localized: "No matching expenses")
        static let decimalPlaceholder = String(localized: "0.00")
        static let editTitle = LocalizedStringKey("Edit Expense")
        static let laborDescriptionFormat = String(localized: "Labor: %@")
        static let materials = LocalizedStringKey("expense.category.materials")
        static let labor = LocalizedStringKey("expense.category.labor")
        static let equipment = LocalizedStringKey("expense.category.equipment")
        static let subcontractor = LocalizedStringKey("expense.category.subcontractor")
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
        static let paid = LocalizedStringKey("invoice.status.paid")
        static let unpaid = LocalizedStringKey("invoice.status.unpaid")
        static let overdue = LocalizedStringKey("invoice.status.overdue")
        static let duePrefix = LocalizedStringKey("invoice.duePrefix")
        static let duePrefixString = String(localized: "invoice.duePrefix.label")
        static let empty = LocalizedStringKey("invoice.empty")
        static let emptyDescription = LocalizedStringKey("invoice.emptyDescription")
        static let searchPrompt = LocalizedStringKey("Search invoices")
        static let filter = LocalizedStringKey("Filter")
        static let filterAll = LocalizedStringKey("All")
        static let noMatchingInvoices = LocalizedStringKey("No matching invoices")
        static let clientSource = LocalizedStringKey("Client Source")
        static let enterName = LocalizedStringKey("Enter Name")
        static let selectExisting = LocalizedStringKey("Select Existing")
        static let selectClient = LocalizedStringKey("Select a client")
        static let existingClientWarning = LocalizedStringKey("A client with this name already exists. Consider selecting from existing clients.")
        static let decimalPlaceholder = String(localized: "0.00")
        static let allLabel = String(localized: "All")
        static let paidLabel = String(localized: "Paid")
        static let unpaidLabel = String(localized: "Unpaid")
        static let overdueLabel = String(localized: "Overdue")
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
        static let editTitle = LocalizedStringKey("client.editTitle")
        static let empty = LocalizedStringKey("client.empty")
        static let emptyDescription = LocalizedStringKey("client.emptyDescription")
        static let searchPrompt = LocalizedStringKey("Search by name, email, or phone")
    }
    
    // MARK: - Settings
    enum Settings {
        static let title = LocalizedStringKey("settings.title")
        static let language = LocalizedStringKey("settings.language")
        static let languageSection = LocalizedStringKey("settings.languageSection")
        static let languageFooter = LocalizedStringKey("settings.languageFooter")
        static let currency = LocalizedStringKey("settings.currency")
        static let currencySection = LocalizedStringKey("settings.currencySection")
        static let currencyFooter = LocalizedStringKey("settings.currencyFooter")
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
        static let languageEnglish = LocalizedStringKey("English")
        static let languageHebrew = LocalizedStringKey("עברית")
        static let languageRussian = LocalizedStringKey("Русский")
        static let currencyUSD = LocalizedStringKey("$ USD")
        static let currencyEUR = LocalizedStringKey("€ EUR")
        static let currencyGBP = LocalizedStringKey("£ GBP")
        static let currencyILS = LocalizedStringKey("₪ ILS")
        static let currencyRUB = LocalizedStringKey("₽ RUB")
        static let currencyJPY = LocalizedStringKey("¥ JPY")
        static let currencyCAD = LocalizedStringKey("C$ CAD")
        static let currencyAUD = LocalizedStringKey("A$ AUD")
        static let appNameFallback = String(localized: "ContractorCashFlow")
    }
    
    // MARK: - Labor (Workers)
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
        
        // Labor Types
        static let hourly = LocalizedStringKey("labor.type.hourly")
        static let daily = LocalizedStringKey("labor.type.daily")
        static let contract = LocalizedStringKey("labor.type.contract")
        static let subcontractor = LocalizedStringKey("labor.type.subcontractor")
        
        // Rate (type-specific)
        static let defaultRate = LocalizedStringKey("labor.defaultRate")
        static let defaultRateHint = LocalizedStringKey("labor.defaultRateHint")
        static let ratePerHour = LocalizedStringKey("labor.ratePerHour")
        static let ratePerDay = LocalizedStringKey("labor.ratePerDay")
        static let contractPrice = LocalizedStringKey("labor.contractPrice")
        static let hourlyRateLabel = LocalizedStringKey("labor.hourlyRate")
        static let hoursWorkedLabel = LocalizedStringKey("labor.hoursWorked")
        static let daysWorkedLabel = LocalizedStringKey("labor.daysWorked")
        static let calculatedTotal = LocalizedStringKey("labor.calculatedTotal")
        
        // Notes
        static let notesLabel = LocalizedStringKey("labor.notes")
        static let notesPlaceholder = LocalizedStringKey("labor.notesPlaceholder")
        
        // Worker Stats
        static let workerStats = LocalizedStringKey("labor.workerStats")
        static let totalEarned = LocalizedStringKey("labor.totalEarned")
        static let totalHours = LocalizedStringKey("labor.totalHours")
        static let totalDaysWorked = LocalizedStringKey("labor.totalDaysWorked")
        static let totalDaysLabel = LocalizedStringKey("labor.totalDaysLabel")
        static let totalWorkers = LocalizedStringKey("labor.totalWorkers")
        static let activeProjects = LocalizedStringKey("labor.activeProjects")
        static let associatedProjects = LocalizedStringKey("labor.associatedProjects")
        static let createdDate = LocalizedStringKey("labor.createdDate")
        static let dayUnit = LocalizedStringKey("labor.dayUnit")
        static let daysUnit = LocalizedStringKey("labor.daysUnit")
        
        // Worker Selection (in expenses)
        static let selectWorker = LocalizedStringKey("labor.selectWorker")
        static let selectWorkerPrompt = LocalizedStringKey("labor.selectWorkerPrompt")
        
        // List View
        static let searchPrompt = LocalizedStringKey("labor.searchPrompt")
        static let sortBy = LocalizedStringKey("labor.sortBy")
        static let noLabor = LocalizedStringKey("labor.noLabor")
        static let noLaborDescription = LocalizedStringKey("labor.noLaborDescription")
        static let noResults = LocalizedStringKey("labor.noResults")
        static let sortRecentlyAdded = LocalizedStringKey("labor.sort.recentlyAdded")
        static let sortAmountHighToLow = LocalizedStringKey("labor.sort.amountHighToLow")
        static let sortAmountLowToHigh = LocalizedStringKey("labor.sort.amountLowToHigh")
        static let sortWorkerName = LocalizedStringKey("labor.sort.workerName")
        
        // Filters
        static let filters = LocalizedStringKey("labor.filters")
        static let laborType = LocalizedStringKey("labor.laborType")
        static let allTypes = LocalizedStringKey("labor.allTypes")
        static let clearFilters = LocalizedStringKey("labor.clearFilters")
        static let filterByProject = LocalizedStringKey("labor.filterByProject")
        static let projectLabel = LocalizedStringKey("labor.projectLabel")
        static let allProjects = LocalizedStringKey("labor.allProjects")
        static let filterByMonth = LocalizedStringKey("labor.filterByMonth")
        static let filterByMonthToggle = LocalizedStringKey("labor.filterByMonthToggle")
        static let selectMonth = LocalizedStringKey("labor.selectMonth")
        static let totalLaborCost = LocalizedStringKey("labor.totalLaborCost")
        static let avgDailyCost = LocalizedStringKey("labor.avgDailyCost")
        static let summaryAllTime = LocalizedStringKey("labor.summaryAllTime")
        
        // String variants for APIs requiring String (Charts, string interpolation)
        static let hourlyString = String(localized: "labor.type.hourly")
        static let dailyString = String(localized: "labor.type.daily")
        static let contractString = String(localized: "labor.type.contract")
        static let subcontractorString = String(localized: "labor.type.subcontractor")
        static let rateSuffixHourly = String(localized: "labor.rateSuffix.hourly")
        static let rateSuffixDaily = String(localized: "labor.rateSuffix.daily")
        static let unitHours = String(localized: "labor.unit.hours")
        static let unitDays = String(localized: "labor.unit.days")
        static let duplicateWorkerWarning = LocalizedStringKey("A worker with this name already exists")
        static let deleteWorkerTitle = LocalizedStringKey("Delete Worker")
        static let deleteWorkerConfirmation = LocalizedStringKey("Are you sure you want to delete this worker?")
        static let decimalPlaceholder = String(localized: "0.00")
        static let linkedExpensesMessage = String(localized: "This worker has %lld linked expense(s). The expenses will remain but won't be linked to a worker.")
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
        static let unexpectedError = LocalizedStringKey("An unexpected error occurred")
        static let failedToLoadProducts = String(localized: "Failed to load products: %@")
        static let failedToRestorePurchases = String(localized: "Failed to restore purchases: %@")
        static let failedToDeleteProject = String(localized: "Failed to delete project: %@")
        static let failedToDeleteInvoice = String(localized: "Failed to delete invoice: %@")
        static let failedToDeleteClient = String(localized: "Failed to delete client: %@")
        static let failedToUpdateClient = String(localized: "Failed to update client: %@")
        static let failedToSaveWorker = String(localized: "Failed to save worker: %@")
        static let failedToUpdateWorker = String(localized: "Failed to update worker: %@")
        static let failedToDeleteWorker = String(localized: "Failed to delete worker: %@")
        static let failedToDeleteExpense = String(localized: "Failed to delete expense: %@")
        static let failedToSaveExpense = String(localized: "Failed to save expense: %@")
        static let failedToUpdateInvoice = String(localized: "Failed to update invoice: %@")
        static let failedToSaveInvoice = String(localized: "Failed to save invoice: %@")
        static let failedToSaveClient = String(localized: "Failed to save client: %@")
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
        
        // String variants for Charts API (requires String, not LocalizedStringKey)
        static let spentString = String(localized: "analytics.spent")
        static let remainingString = String(localized: "analytics.remaining")
        static let chartAmountString = String(localized: "analytics.chart.amount")
        static let chartCategoryString = String(localized: "analytics.chart.category")
        static let chartProjectString = String(localized: "analytics.chart.project")
        static let chartTypeString = String(localized: "analytics.chart.type")
    }
    
    // MARK: - Subscription
    enum Subscription {
        static let upgradeTitle = LocalizedStringKey("subscription.upgradeTitle")
        static let upgradeSubtitle = LocalizedStringKey("subscription.upgradeSubtitle")
        static let subscribe = LocalizedStringKey("subscription.subscribe")
        static let restore = LocalizedStringKey("subscription.restore")
        static let managePlan = LocalizedStringKey("subscription.managePlan")
        static let currentPlan = LocalizedStringKey("subscription.currentPlan")
        static let freePlan = LocalizedStringKey("subscription.freePlan")
        static let proPlan = LocalizedStringKey("subscription.proPlan")
        static let proMonthly = LocalizedStringKey("subscription.proMonthly")
        static let proYearly = LocalizedStringKey("subscription.proYearly")
        static let unlimited = LocalizedStringKey("subscription.unlimited")
        static let unlimitedProjects = LocalizedStringKey("subscription.unlimitedProjects")
        static let unlimitedExpenses = LocalizedStringKey("subscription.unlimitedExpenses")
        static let unlimitedInvoices = LocalizedStringKey("subscription.unlimitedInvoices")
        static let unlimitedWorkers = LocalizedStringKey("subscription.unlimitedWorkers")
        static let projectLimitReached = LocalizedStringKey("subscription.projectLimitReached")
        static let expenseLimitReached = LocalizedStringKey("subscription.expenseLimitReached")
        static let invoiceLimitReached = LocalizedStringKey("subscription.invoiceLimitReached")
        static let workerLimitReached = LocalizedStringKey("subscription.workerLimitReached")
        static let renewsOn = LocalizedStringKey("subscription.renewsOn")
        static let perMonth = LocalizedStringKey("subscription.perMonth")
        static let perYear = LocalizedStringKey("subscription.perYear")
        static let saveBadge = LocalizedStringKey("subscription.saveBadge")
        static let termsOfService = LocalizedStringKey("subscription.termsOfService")
        static let privacyPolicy = LocalizedStringKey("subscription.privacyPolicy")
        static let subscriptionSection = LocalizedStringKey("subscription.section")
        static let freeLimitFormat = String(localized: "Free: %@")
    }
    
    // MARK: - Notification
    enum Notification {
        static let invoiceDueSoonTitle = String(localized: "Invoice Due Soon")
        static let invoiceDueSoonBody = String(localized: "Invoice for %@ ($%@) is due in 3 days")
        static let invoiceOverdueTitle = String(localized: "Invoice Overdue")
        static let invoiceOverdueBody = String(localized: "Invoice for %@ ($%@) is now overdue")
        static let budgetWarning80Title = String(localized: "Budget Warning: 80%")
        static let budgetWarning80Body = String(localized: "Project '%@' has reached 80%% of budget ($%@ of $%@)")
        static let budgetWarning100Title = String(localized: "Budget Alert: 100%")
        static let budgetWarning100Body = String(localized: "Project '%@' has exceeded budget! Spent $%@ of $%@")
    }
    
    // MARK: - Content
    enum Content {
        static let itemAt = String(localized: "Item at %@")
        static let addItem = LocalizedStringKey("Add Item")
        static let selectItem = LocalizedStringKey("Select an item")
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
// MARK: - AppStorage Keys
/// Centralized keys for @AppStorage to avoid hardcoded strings
enum StorageKey {
    static let appLanguage = "AppLanguage"
    static let selectedCurrencyCode = "selectedCurrencyCode"
    static let defaultCurrencyCode = "ILS"
    
    enum Notifications {
        static let invoiceReminders = "settings.notifications.invoiceReminders"
        static let overdueAlerts = "settings.notifications.overdueAlerts"
        static let budgetWarnings = "settings.notifications.budgetWarnings"
    }
}

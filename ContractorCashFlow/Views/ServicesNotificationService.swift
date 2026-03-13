//
//  NotificationService.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import Foundation
import UserNotifications
import SwiftData

/// Service responsible for managing local notifications for invoices and budget warnings
@MainActor
final class NotificationService {
    
    // MARK: - Singleton
    
    static let shared = NotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - UserDefaults Keys
    
    private enum SettingsKey {
        static let invoiceReminders = "settings.notifications.invoiceReminders"
        static let overdueAlerts = "settings.notifications.overdueAlerts"
        static let budgetWarnings = "settings.notifications.budgetWarnings"
        static let hasRequestedPermission = "notifications.hasRequestedPermission"
    }
    
    // MARK: - Notification Categories
    
    private enum NotificationCategory: String {
        case invoiceUpcoming = "INVOICE_UPCOMING"
        case invoiceOverdue = "INVOICE_OVERDUE"
        case budgetWarning = "BUDGET_WARNING"
        
        var identifier: String { rawValue }
    }
    
    // MARK: - Notification Identifiers
    
    private enum NotificationIdentifier {
        static func invoiceUpcoming(invoiceID: UUID) -> String {
            "invoice-upcoming-\(invoiceID.uuidString)"
        }
        
        static func invoiceOverdue(invoiceID: UUID) -> String {
            "invoice-overdue-\(invoiceID.uuidString)"
        }
        
        static func budgetWarning(projectID: UUID, threshold: BudgetThreshold) -> String {
            "budget-\(threshold.rawValue)-\(projectID.uuidString)"
        }
        
        static func allInvoiceNotifications(invoiceID: UUID) -> [String] {
            [
                invoiceUpcoming(invoiceID: invoiceID),
                invoiceOverdue(invoiceID: invoiceID)
            ]
        }
        
        static func allBudgetNotifications(projectID: UUID) -> [String] {
            BudgetThreshold.allCases.map { threshold in
                budgetWarning(projectID: projectID, threshold: threshold)
            }
        }
    }
    
    // MARK: - Budget Thresholds
    
    enum BudgetThreshold: String, CaseIterable {
        case eighty = "80"
        case hundred = "100"
        
        var percentage: Double {
            switch self {
            case .eighty: return 80.0
            case .hundred: return 100.0
            }
        }
    }
    
    // MARK: - Private Init
    
    private init() {}
    
    // MARK: - Permission Management
    
    /// Request notification permission from the user (call on first launch)
    func requestPermissionIfNeeded() async {
        let hasRequested = UserDefaults.standard.bool(forKey: SettingsKey.hasRequestedPermission)
        
        guard !hasRequested else { return }
        
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
            
            UserDefaults.standard.set(true, forKey: SettingsKey.hasRequestedPermission)
        } catch {
            print("⚠️ Error requesting notification permission: \(error)")
        }
    }
    
    /// Check if notifications are authorized
    func checkAuthorizationStatus() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Invoice Notifications
    
    /// Schedule all relevant notifications for an invoice
    func scheduleNotifications(for invoice: Invoice) async {
        // Don't schedule if invoice is already paid
        guard !invoice.isPaid else {
            await cancelNotifications(for: invoice)
            return
        }
        
        // Check if we have permission
        guard await checkAuthorizationStatus() else { return }
        
        // Schedule upcoming reminder (3 days before due date)
        if UserDefaults.standard.bool(forKey: SettingsKey.invoiceReminders) {
            await scheduleUpcomingReminder(for: invoice)
        }
        
        // Schedule overdue alert (1 day after due date)
        if UserDefaults.standard.bool(forKey: SettingsKey.overdueAlerts) {
            await scheduleOverdueAlert(for: invoice)
        }
    }
    
    /// Schedule a reminder 3 days before invoice is due
    private func scheduleUpcomingReminder(for invoice: Invoice) async {
        let reminderDate = Calendar.current.date(byAdding: .day, value: -3, to: invoice.dueDate)
        
        // Only schedule if the reminder date is in the future
        guard let reminderDate = reminderDate, reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Invoice Due Soon"
        content.body = "Invoice for \(invoice.clientName) ($\(String(format: "%.2f", invoice.amount))) is due in 3 days"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.invoiceUpcoming.identifier
        content.userInfo = [
            "invoiceID": invoice.id.uuidString,
            "type": "upcoming"
        ]
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = NotificationIdentifier.invoiceUpcoming(invoiceID: invoice.id)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("✅ Scheduled upcoming reminder for invoice \(invoice.id)")
        } catch {
            print("⚠️ Error scheduling upcoming reminder: \(error)")
        }
    }
    
    /// Schedule an alert 1 day after invoice is overdue
    private func scheduleOverdueAlert(for invoice: Invoice) async {
        let overdueDate = Calendar.current.date(byAdding: .day, value: 1, to: invoice.dueDate)
        
        // Only schedule if the overdue date is in the future
        guard let overdueDate = overdueDate, overdueDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Invoice Overdue"
        content.body = "Invoice for \(invoice.clientName) ($\(String(format: "%.2f", invoice.amount))) is now overdue"
        content.sound = .defaultCritical
        content.categoryIdentifier = NotificationCategory.invoiceOverdue.identifier
        content.userInfo = [
            "invoiceID": invoice.id.uuidString,
            "type": "overdue"
        ]
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: overdueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = NotificationIdentifier.invoiceOverdue(invoiceID: invoice.id)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("✅ Scheduled overdue alert for invoice \(invoice.id)")
        } catch {
            print("⚠️ Error scheduling overdue alert: \(error)")
        }
    }
    
    /// Cancel all notifications for a specific invoice (e.g., when marked as paid)
    func cancelNotifications(for invoice: Invoice) async {
        let identifiers = NotificationIdentifier.allInvoiceNotifications(invoiceID: invoice.id)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Cancelled notifications for invoice \(invoice.id)")
    }
    
    // MARK: - Budget Notifications
    
    /// Check and schedule budget warnings for a project
    func checkBudgetAndScheduleNotifications(for project: Project) async {
        guard UserDefaults.standard.bool(forKey: SettingsKey.budgetWarnings) else {
            await cancelBudgetNotifications(for: project)
            return
        }
        
        guard await checkAuthorizationStatus() else { return }
        
        let utilization = project.budgetUtilization
        
        // Check 80% threshold
        if utilization >= 80.0 && utilization < 100.0 {
            await scheduleBudgetWarning(for: project, threshold: .eighty)
        } else {
            await cancelBudgetNotification(for: project, threshold: .eighty)
        }
        
        // Check 100% threshold
        if utilization >= 100.0 {
            await scheduleBudgetWarning(for: project, threshold: .hundred)
        } else {
            await cancelBudgetNotification(for: project, threshold: .hundred)
        }
    }
    
    /// Schedule a budget warning notification
    private func scheduleBudgetWarning(for project: Project, threshold: BudgetThreshold) async {
        let identifier = NotificationIdentifier.budgetWarning(projectID: project.id, threshold: threshold)
        
        // Check if this notification already exists
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        if pendingRequests.contains(where: { $0.identifier == identifier }) {
            // Already scheduled, don't duplicate
            return
        }
        
        let content = UNMutableNotificationContent()
        
        switch threshold {
        case .eighty:
            content.title = "Budget Warning: 80%"
            content.body = "Project '\(project.name)' has reached 80% of budget ($\(String(format: "%.2f", project.totalExpenses)) of $\(String(format: "%.2f", project.budget)))"
            content.sound = .default
            
        case .hundred:
            content.title = "Budget Alert: 100%"
            content.body = "Project '\(project.name)' has exceeded budget! Spent $\(String(format: "%.2f", project.totalExpenses)) of $\(String(format: "%.2f", project.budget))"
            content.sound = .defaultCritical
        }
        
        content.categoryIdentifier = NotificationCategory.budgetWarning.identifier
        content.userInfo = [
            "projectID": project.id.uuidString,
            "threshold": threshold.rawValue,
            "type": "budget"
        ]
        
        // Trigger immediately for budget warnings
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("✅ Scheduled budget warning (\(threshold.rawValue)%) for project \(project.id)")
        } catch {
            print("⚠️ Error scheduling budget warning: \(error)")
        }
    }
    
    /// Cancel a specific budget notification
    private func cancelBudgetNotification(for project: Project, threshold: BudgetThreshold) async {
        let identifier = NotificationIdentifier.budgetWarning(projectID: project.id, threshold: threshold)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// Cancel all budget notifications for a project
    func cancelBudgetNotifications(for project: Project) async {
        let identifiers = NotificationIdentifier.allBudgetNotifications(projectID: project.id)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Cancelled budget notifications for project \(project.id)")
    }
    
    // MARK: - Bulk Operations
    
    /// Reschedule all invoice notifications based on current ModelContext
    func rescheduleAllInvoiceNotifications(from modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Invoice>(
            predicate: #Predicate<Invoice> { !$0.isPaid }
        )
        
        guard let unpaidInvoices = try? modelContext.fetch(descriptor) else {
            print("⚠️ Failed to fetch invoices for rescheduling")
            return
        }
        
        for invoice in unpaidInvoices {
            await scheduleNotifications(for: invoice)
        }
        
        print("✅ Rescheduled notifications for \(unpaidInvoices.count) invoices")
    }
    
    /// Reschedule all budget notifications based on current ModelContext
    func rescheduleAllBudgetNotifications(from modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { $0.isActive }
        )
        
        guard let activeProjects = try? modelContext.fetch(descriptor) else {
            print("⚠️ Failed to fetch projects for rescheduling")
            return
        }
        
        for project in activeProjects {
            await checkBudgetAndScheduleNotifications(for: project)
        }
        
        print("✅ Rescheduled budget notifications for \(activeProjects.count) projects")
    }
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ Cancelled all pending notifications")
    }
    
    // MARK: - Debug Helpers
    
    /// Get count of pending notifications (useful for debugging)
    func getPendingNotificationCount() async -> Int {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.count
    }
    
    /// Print all pending notifications (useful for debugging)
    func printPendingNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        print("📋 Pending Notifications (\(requests.count)):")
        for request in requests {
            print("  - \(request.identifier): \(request.content.title)")
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                print("    Scheduled for: \(nextTriggerDate)")
            }
        }
    }
}

// MARK: - Settings Observer Extension

extension NotificationService {
    
    /// Update notifications when settings change
    func handleSettingsChange(for key: String, modelContext: ModelContext) async {
        switch key {
        case SettingsKey.invoiceReminders, SettingsKey.overdueAlerts:
            await rescheduleAllInvoiceNotifications(from: modelContext)
            
        case SettingsKey.budgetWarnings:
            await rescheduleAllBudgetNotifications(from: modelContext)
            
        default:
            break
        }
    }
}

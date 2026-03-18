//
//  View+Notifications.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI

/// Convenient view modifiers for handling notifications
extension View {
    
    /// Automatically schedule notifications when an invoice is saved or updated
    /// - Parameter invoice: The invoice to schedule notifications for
    /// - Returns: A view that schedules notifications for the invoice
    func scheduleNotifications(for invoice: Invoice?) -> some View {
        self.task(id: invoice?.id) {
            guard let invoice = invoice else { return }
            await NotificationService.shared.scheduleNotifications(for: invoice)
        }
    }
    
    /// Automatically check budget and schedule notifications when a project is updated
    /// - Parameter project: The project to check budget for
    /// - Returns: A view that schedules budget notifications
    func checkBudget(for project: Project?) -> some View {
        self.task(id: project?.id) {
            guard let project = project else { return }
            await NotificationService.shared.checkBudgetAndScheduleNotifications(for: project)
        }
    }
    
    /// Monitor invoice paid status and cancel notifications when paid
    /// - Parameter invoice: The invoice to monitor
    /// - Returns: A view that cancels notifications when invoice is paid
    func monitorInvoicePaidStatus(_ invoice: Invoice) -> some View {
        self.onChange(of: invoice.isPaid) { oldValue, newValue in
            Task {
                if newValue {
                    // Cancel when marked as paid
                    await NotificationService.shared.cancelNotifications(for: invoice)
                } else {
                    // Reschedule if unmarked as paid
                    await NotificationService.shared.scheduleNotifications(for: invoice)
                }
            }
        }
    }
}

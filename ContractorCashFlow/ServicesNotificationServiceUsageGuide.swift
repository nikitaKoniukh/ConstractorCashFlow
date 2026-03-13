//
//  NotificationServiceUsageGuide.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//
//  USAGE GUIDE: How to integrate NotificationService in your views
//

import SwiftUI
import SwiftData

/*
 
 MARK: - Quick Integration Guide
 
 This file demonstrates how to use NotificationService throughout your app.
 You can delete this file once you've integrated the service into your views.
 
 */

// MARK: - 1. When Creating or Editing Invoices

/*
 In your invoice creation/editing view, schedule notifications after saving:
 */

struct ExampleInvoiceFormView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var invoice: Invoice
    
    var body: some View {
        Form {
            // Your form fields here...
        }
        .navigationTitle("Invoice")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveInvoice()
                }
            }
        }
    }
    
    private func saveInvoice() {
        modelContext.insert(invoice)
        
        // Schedule notifications after saving
        Task {
            await NotificationService.shared.scheduleNotifications(for: invoice)
        }
    }
}

// MARK: - 2. When Marking Invoice as Paid

/*
 When an invoice is marked as paid, cancel its notifications:
 */

struct ExampleInvoiceDetailView: View {
    @Bindable var invoice: Invoice
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack {
            // Invoice details...
            
            Toggle("Paid", isOn: $invoice.isPaid)
                .onChange(of: invoice.isPaid) { oldValue, newValue in
                    if newValue {
                        // Cancel notifications when marked as paid
                        Task {
                            await NotificationService.shared.cancelNotifications(for: invoice)
                        }
                    } else {
                        // Reschedule if unmarked
                        Task {
                            await NotificationService.shared.scheduleNotifications(for: invoice)
                        }
                    }
                }
        }
    }
}

// MARK: - 3. When Adding Expenses to a Project

/*
 After adding an expense, check if budget notifications need updating:
 */

struct ExampleExpenseFormView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var expense: Expense
    var project: Project?
    
    var body: some View {
        Form {
            // Your form fields here...
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveExpense()
                }
            }
        }
    }
    
    private func saveExpense() {
        expense.project = project
        modelContext.insert(expense)
        
        // Check budget after adding expense
        if let project = project {
            Task {
                await NotificationService.shared.checkBudgetAndScheduleNotifications(for: project)
            }
        }
    }
}

// MARK: - 4. Observing Settings Changes

/*
 In your SettingsView, you can add observers to reschedule when toggles change:
 */

struct ExampleSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("settings.notifications.invoiceReminders") private var invoiceRemindersEnabled = true
    @AppStorage("settings.notifications.overdueAlerts") private var overdueAlertsEnabled = true
    @AppStorage("settings.notifications.budgetWarnings") private var budgetWarningsEnabled = true
    
    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Invoice Reminders", isOn: $invoiceRemindersEnabled)
                    .onChange(of: invoiceRemindersEnabled) { _, _ in
                        handleSettingsChange()
                    }
                
                Toggle("Overdue Alerts", isOn: $overdueAlertsEnabled)
                    .onChange(of: overdueAlertsEnabled) { _, _ in
                        handleSettingsChange()
                    }
                
                Toggle("Budget Warnings", isOn: $budgetWarningsEnabled)
                    .onChange(of: budgetWarningsEnabled) { _, _ in
                        handleSettingsChange()
                    }
            }
        }
    }
    
    private func handleSettingsChange() {
        Task {
            // Reschedule all invoice notifications
            await NotificationService.shared.rescheduleAllInvoiceNotifications(from: modelContext)
            // Reschedule all budget notifications
            await NotificationService.shared.rescheduleAllBudgetNotifications(from: modelContext)
        }
    }
}

// MARK: - 5. Debugging Notifications

/*
 You can use these debug helpers to check notification status:
 */

struct ExampleDebugView: View {
    @State private var pendingCount = 0
    
    var body: some View {
        VStack {
            Text("Pending Notifications: \(pendingCount)")
            
            Button("Refresh Count") {
                Task {
                    pendingCount = await NotificationService.shared.getPendingNotificationCount()
                }
            }
            
            Button("Print All Notifications") {
                Task {
                    await NotificationService.shared.printPendingNotifications()
                }
            }
            
            Button("Cancel All") {
                NotificationService.shared.cancelAllNotifications()
            }
        }
        .task {
            pendingCount = await NotificationService.shared.getPendingNotificationCount()
        }
    }
}

// MARK: - 6. Bulk Rescheduling (Optional)

/*
 You might want to reschedule all notifications when the app becomes active,
 in case dates have changed while the app was closed:
 */

struct ExampleRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        TabView {
            // Your tabs...
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Optionally reschedule when app becomes active
                Task {
                    await NotificationService.shared.rescheduleAllInvoiceNotifications(from: modelContext)
                    await NotificationService.shared.rescheduleAllBudgetNotifications(from: modelContext)
                }
            }
        }
    }
}

// MARK: - 7. Testing Notifications (Development Only)

#if DEBUG
struct NotificationTestView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            Section("Test Invoice Notifications") {
                Button("Create Test Invoice (Due in 2 days)") {
                    createTestInvoice(daysUntilDue: 2)
                }
                
                Button("Create Test Invoice (Due in 4 days - will trigger reminder)") {
                    createTestInvoice(daysUntilDue: 4)
                }
                
                Button("Create Test Invoice (Overdue)") {
                    createTestInvoice(daysUntilDue: -2)
                }
            }
            
            Section("Test Budget Notifications") {
                Button("Create Project at 85% Budget") {
                    createTestProjectAtBudget(percentage: 85)
                }
                
                Button("Create Project at 105% Budget") {
                    createTestProjectAtBudget(percentage: 105)
                }
            }
            
            Section("Notification Status") {
                Button("Check Permission Status") {
                    Task {
                        let authorized = await NotificationService.shared.checkAuthorizationStatus()
                        print("Notifications authorized: \(authorized)")
                    }
                }
                
                Button("Print All Pending") {
                    Task {
                        await NotificationService.shared.printPendingNotifications()
                    }
                }
            }
        }
        .navigationTitle("Notification Tests")
    }
    
    private func createTestInvoice(daysUntilDue: Int) {
        let dueDate = Calendar.current.date(byAdding: .day, value: daysUntilDue, to: Date()) ?? Date()
        
        let invoice = Invoice(
            amount: 1000,
            dueDate: dueDate,
            isPaid: false,
            clientName: "Test Client"
        )
        
        modelContext.insert(invoice)
        
        Task {
            await NotificationService.shared.scheduleNotifications(for: invoice)
            print("✅ Created test invoice with due date: \(dueDate)")
        }
    }
    
    private func createTestProjectAtBudget(percentage: Double) {
        let budget = 10000.0
        let targetExpenses = budget * (percentage / 100.0)
        
        let project = Project(
            name: "Test Project \(Int(percentage))%",
            clientName: "Test Client",
            budget: budget
        )
        
        let expense = Expense(
            category: .materials,
            amount: targetExpenses,
            descriptionText: "Test expense to reach \(Int(percentage))%",
            project: project
        )
        
        modelContext.insert(project)
        modelContext.insert(expense)
        
        Task {
            await NotificationService.shared.checkBudgetAndScheduleNotifications(for: project)
            print("✅ Created test project at \(percentage)% budget")
        }
    }
}
#endif

/*
 
 MARK: - Important Notes
 
 1. **Notification Permission**: The app will request permission on first launch.
    Users can always change this in iOS Settings.
 
 2. **UserDefaults Keys**: The service respects these keys:
    - "settings.notifications.invoiceReminders"
    - "settings.notifications.overdueAlerts"
    - "settings.notifications.budgetWarnings"
 
 3. **Automatic Cancellation**: Notifications are automatically cancelled when:
    - An invoice is marked as paid
    - Settings are toggled off
 
 4. **Budget Notifications**: These trigger immediately when threshold is crossed,
    but only fire once per threshold per project.
 
 5. **Date Calculations**:
    - Upcoming reminder: 3 days before due date
    - Overdue alert: 1 day after due date
    - Budget warnings: Immediate when 80% or 100% is reached
 
 6. **Testing**: Use the NotificationTestView (DEBUG only) to test notifications
    without waiting for real dates.
 
 7. **Debugging**: Check Xcode console for notification-related logs with
    emoji indicators: ✅ (success), ⚠️ (warning), 🗑️ (cancellation)
 
 */

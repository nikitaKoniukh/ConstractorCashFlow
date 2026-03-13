# ContractorCashFlow - Features Documentation

## Table of Contents
1. [Search Functionality](#search-functionality)
2. [Notification Service](#notification-service)

---

## Search Functionality

### Overview

Comprehensive search and filtering capabilities across all major list views using SwiftUI's `.searchable()` and SwiftData's `#Predicate`.

### Features by View

#### Projects
- **Search:** Filter by project name or client name
- **Empty State:** Shows appropriate message when no results found

#### Expenses
- **Search:** Filter by expense description
- **Filters:**
  - Category (Materials, Labor, Equipment, Miscellaneous)
  - Date Range (start date, end date, or both)
- **UI:** Filter button with active state indicator

#### Invoices
- **Search:** Filter by client name
- **Filters:** Payment status (All, Paid, Unpaid, Overdue)
- **UI:** Quick status menu in toolbar

#### Clients
- **Search:** Filter by name, email, or phone number
- **Handles:** Optional fields gracefully

### Documentation
- 📖 **Full Guide:** `SearchImplementationGuide.md`
- 🚀 **Quick Reference:** `SearchQuickReference.md`

---

## Notification Service

### Overview

The `NotificationService` provides comprehensive local notification support for the ContractorCashFlow app. It handles invoice reminders, overdue alerts, and budget warnings automatically.

## Features

✅ **Invoice Notifications**
- Reminder 3 days before invoice due date
- Alert 1 day after invoice becomes overdue
- Automatic cancellation when invoice is paid
- Respects user preferences from Settings

✅ **Budget Notifications**
- Warning when project reaches 80% of budget
- Critical alert when project reaches/exceeds 100% of budget
- Automatic scheduling when expenses are added
- Respects user preferences from Settings

✅ **Permission Management**
- Requests notification permission on first launch
- Checks authorization status before scheduling
- Respects iOS system settings

✅ **Settings Integration**
- Three toggles in Settings: Invoice Reminders, Overdue Alerts, Budget Warnings
- Automatic rescheduling when settings change
- Preferences stored in UserDefaults

## Files Created

1. **`Services/NotificationService.swift`** - Main notification service implementation
2. **`Services/View+Notifications.swift`** - Convenient SwiftUI view modifiers
3. **`Services/NotificationServiceUsageGuide.swift`** - Comprehensive usage examples

## Quick Start

### 1. Basic Integration (Invoice Views)

When creating or editing an invoice:

```swift
struct InvoiceFormView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var invoice: Invoice
    
    var body: some View {
        Form {
            // Your form fields
        }
        .toolbar {
            Button("Save") {
                saveInvoice()
            }
        }
    }
    
    private func saveInvoice() {
        modelContext.insert(invoice)
        
        // Schedule notifications
        Task {
            await NotificationService.shared.scheduleNotifications(for: invoice)
        }
    }
}
```

### 2. Monitor Invoice Paid Status

When displaying an invoice with a paid toggle:

```swift
struct InvoiceDetailView: View {
    @Bindable var invoice: Invoice
    
    var body: some View {
        Form {
            Toggle("Paid", isOn: $invoice.isPaid)
        }
        .monitorInvoicePaidStatus(invoice) // Convenience modifier
    }
}
```

Or manually:

```swift
.onChange(of: invoice.isPaid) { _, isPaid in
    Task {
        if isPaid {
            await NotificationService.shared.cancelNotifications(for: invoice)
        } else {
            await NotificationService.shared.scheduleNotifications(for: invoice)
        }
    }
}
```

### 3. Budget Tracking (Expense Views)

When adding expenses to a project:

```swift
struct ExpenseFormView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var expense: Expense
    var project: Project?
    
    var body: some View {
        Form {
            // Your form fields
        }
        .toolbar {
            Button("Save") {
                saveExpense()
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
```

Or use the convenience modifier:

```swift
.checkBudget(for: project)
```

## Settings Integration

The service is already integrated with your SettingsView. When users toggle notification preferences, all notifications are automatically rescheduled.

**UserDefaults Keys:**
- `settings.notifications.invoiceReminders`
- `settings.notifications.overdueAlerts`
- `settings.notifications.budgetWarnings`

## Notification Schedule

### Invoice Notifications

| Type | Trigger | Sound | Cancellation |
|------|---------|-------|--------------|
| Upcoming Reminder | 3 days before due date | Default | When invoice is paid |
| Overdue Alert | 1 day after due date | Critical | When invoice is paid |

### Budget Notifications

| Type | Trigger | Sound | Cancellation |
|------|---------|-------|--------------|
| 80% Warning | When expenses reach 80% of budget | Default | When budget drops below 80% |
| 100% Alert | When expenses reach 100% of budget | Critical | When budget drops below 100% |

## Permission Flow

1. **First Launch**: App requests notification permission via alert
2. **User Response**: Stored in UserDefaults to avoid asking again
3. **Status Check**: Service checks authorization before scheduling
4. **Settings**: Users can always change permission in iOS Settings

## Testing

### Debug Helpers

```swift
// Get count of pending notifications
let count = await NotificationService.shared.getPendingNotificationCount()

// Print all pending notifications with dates
await NotificationService.shared.printPendingNotifications()

// Cancel all notifications
NotificationService.shared.cancelAllNotifications()
```

### Test Notifications (DEBUG mode)

See `NotificationServiceUsageGuide.swift` for a complete test view that lets you:
- Create test invoices at various dates
- Create test projects at different budget percentages
- Check permission status
- View pending notifications

## Architecture

### Singleton Pattern
```swift
NotificationService.shared
```

The service uses a singleton pattern for easy access throughout the app.

### Thread Safety
All methods are marked `@MainActor` and use Swift Concurrency for safe async operations.

### Notification Identifiers
Each notification has a unique identifier based on:
- Invoice ID for invoice notifications
- Project ID + threshold for budget notifications

This allows precise cancellation and prevents duplicates.

## Best Practices

### ✅ DO

- Schedule notifications after inserting/updating invoices
- Cancel notifications when invoices are paid
- Check budget after adding expenses to projects
- Use convenience modifiers for simple cases
- Test with the debug helpers

### ❌ DON'T

- Schedule notifications for paid invoices
- Forget to check user preferences
- Schedule duplicate notifications (service handles this)
- Block the main thread (use Task { await ... })

## Troubleshooting

### Notifications Not Appearing?

1. **Check Permission**: Call `await NotificationService.shared.checkAuthorizationStatus()`
2. **Check Settings**: Verify toggles are enabled in app Settings
3. **Check iOS Settings**: Go to Settings → ContractorCashFlow → Notifications
4. **Check Dates**: Notifications only schedule for future dates
5. **Check Console**: Look for ✅, ⚠️, or 🗑️ emoji logs

### Notifications Firing Multiple Times?

- The service automatically prevents duplicates by checking pending notifications
- Each notification has a unique identifier
- Only one notification per invoice/project/threshold combination

### Testing in Simulator?

- Simulators fully support local notifications
- Use the test view to create invoices due soon
- Check pending notifications with debug helpers
- Watch Xcode console for scheduling confirmations

## Example Integration Checklist

- [ ] Invoice creation/editing schedules notifications
- [ ] Invoice paid toggle cancels notifications
- [ ] Expense creation checks budget for project
- [ ] Settings toggles are connected (already done)
- [ ] App requests permission on launch (already done)
- [ ] Test with various dates and amounts

## Console Log Indicators

The service uses emoji indicators for easy debugging:

- ✅ Success (scheduled, saved, etc.)
- ⚠️ Warning (error, failed operation)
- 🗑️ Cancellation (notifications removed)
- 📋 Information (debug output)

## Additional Resources

- See `NotificationServiceUsageGuide.swift` for detailed examples
- See `View+Notifications.swift` for convenience modifiers
- Check Apple's [UNUserNotificationCenter documentation](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)

## Support

For questions or issues:
1. Check the usage guide examples
2. Use debug helpers to inspect notification state
3. Review console logs for error messages
4. Verify all integration points are connected

---

**Created**: March 13, 2026  
**Version**: 1.0  
**iOS Target**: iOS 17.0+

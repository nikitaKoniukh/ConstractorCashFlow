# Analytics Quick Start Guide

## Setup Checklist

### 1. Add Localization Strings ⚠️ REQUIRED

Open your `Localizable.xcstrings` file and add the entries from `ANALYTICS_LOCALIZATION.md`. Without these, the app won't build.

**Quick Method:**
1. Open `Localizable.xcstrings` in Xcode
2. Click the `+` button for each new key
3. Add the key name (e.g., `analytics.title`)
4. Add the English value (e.g., `Analytics`)
5. Repeat for all analytics keys

**Keys to add:**
- `analytics.title`
- `analytics.incomeVsExpenses`
- `analytics.expensesByCategory`
- `analytics.budgetUtilization`
- `analytics.netBalance`
- `analytics.income`
- `analytics.expenses`
- `analytics.averageUtilization`
- `analytics.noFinancialData`
- `analytics.noExpenseData`
- `analytics.noProjectData`
- `tab.analytics`

### 2. Verify Deployment Target

Make sure your app targets:
- **iOS 16.0** or later
- **macOS 13.0** or later

The Swift Charts framework requires these minimum versions.

**To check:**
1. Select your project in Xcode
2. Go to project settings
3. Under "Deployment Info", verify minimum deployment target

### 3. Build and Run

1. Build your project (⌘B)
2. Run on simulator or device (⌘R)
3. Tap the new "Analytics" tab (chart.bar.fill icon)

## What You'll See

### Empty State (New Installation)
When you first run the app with no data, you'll see empty state messages:
- "No financial data available" on the income/expenses chart
- "No expense data available" on the category chart
- "No project data available" on the budget chart

### With Sample Data (Development)
To preview with sample data during development, use the preview:

1. Open `ViewsAnalyticsView.swift` in Xcode
2. Click "Resume" on the preview canvas
3. Select "Analytics with Sample Data" from the preview selector

### With Real Data
Once you add:
- Projects with budgets
- Expenses in different categories
- Invoices (mark some as paid)

The charts will automatically populate with:

**Chart 1: Income vs Expenses**
- Green = Total from paid invoices
- Red = Total expenses
- Center = Net balance (green if positive, red if negative)

**Chart 2: Expense Breakdown**
- Blue bars = Materials expenses
- Orange bars = Labor expenses  
- Gray bars = Equipment expenses
- Purple bars = Miscellaneous expenses
- Percentages shown at the end of each bar

**Chart 3: Budget Utilization**
- Orange bars = Money spent on each project
- Light blue bars = Budget remaining
- Shows top 10 projects
- Average utilization shown at bottom

## Testing the Analytics

### Quick Test Data

1. **Create a Project**
   - Name: "Test Kitchen"
   - Budget: $10,000
   
2. **Add Some Expenses**
   - Materials: $2,000
   - Labor: $1,500
   - Equipment: $500
   
3. **Create an Invoice**
   - Amount: $5,000
   - Mark as paid
   
4. **Check Analytics**
   - Income: $5,000 (green)
   - Expenses: $4,000 (red)
   - Net: $1,000 (green)
   - Budget used: 40%

## Customization

### Change Chart Colors

Edit `ExpenseCategory` extension in `ViewsAnalyticsView.swift`:

```swift
extension ExpenseCategory {
    var chartColor: Color {
        switch self {
        case .materials: return .blue      // Your color here
        case .labor: return .orange        // Your color here
        case .equipment: return .gray      // Your color here
        case .misc: return .purple         // Your color here
        }
    }
}
```

### Change Currency

Find all instances of `.currency(code: "USD")` and change to your currency:
- `"EUR"` for Euros
- `"GBP"` for British Pounds
- `"CAD"` for Canadian Dollars
- etc.

Better yet, make it dynamic based on user settings!

### Adjust Number of Projects

In `BudgetUtilizationChartCard`, find:
```swift
.prefix(10) // Change this number
```

## Troubleshooting

### "Cannot find type 'LocalizedStringKey'"
- Make sure `import SwiftUI` is at the top of the file
- Clean build folder (Shift+⌘+K) and rebuild

### Charts don't appear
- Check that you have data in SwiftData
- Verify deployment target is iOS 16+ / macOS 13+
- Check console for any SwiftData errors

### Missing localization
- Verify all keys are in `Localizable.xcstrings`
- Check spelling of keys matches exactly
- Clean build and rebuild

### Tab doesn't appear
- Check that `AnalyticsView()` is added to `RootTabView.swift`
- Verify `AppTab.analytics` case exists in `AppState.swift`
- Make sure the tag is set correctly

### Data doesn't update
- SwiftData queries are reactive - they should update automatically
- Try force-closing and reopening the app
- Check that your data is actually being saved to SwiftData

## Advanced Features (Future)

Consider adding:
- 📅 Date range filters (this month, last month, custom range)
- 📊 Line charts for trends over time
- 🔍 Tap charts to drill down into details
- 📤 Export charts as images
- 🎨 User-customizable color schemes
- 💱 Dynamic currency based on user location
- 📈 Profit margin analysis
- 🔔 Budget alerts when approaching limits

## Performance Tips

- Budget chart limited to 10 projects to prevent UI lag
- All calculations done in computed properties (efficient)
- Charts rendered lazily by SwiftUI
- Empty states prevent unnecessary rendering

## Questions?

See the detailed `ANALYTICS_README.md` for:
- Complete technical documentation
- Architecture details
- Testing strategies
- Known limitations
- Future enhancement ideas

---

**Happy analyzing! 📊**

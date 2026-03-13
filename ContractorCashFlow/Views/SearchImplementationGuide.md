# Search Functionality Implementation Guide

## Overview

Comprehensive search and filtering capabilities have been implemented across all major list views in ContractorCashFlow using SwiftUI's `.searchable()` modifier and SwiftData's `#Predicate` for efficient database queries.

## Features by View

### 1. Projects List View

**Search Capabilities:**
- Filter by project name
- Filter by client name
- Case-insensitive, localized search

**Implementation:**
```swift
.searchable(text: $searchText, prompt: "Search by name or client")
```

**Predicate Logic:**
```swift
#Predicate<Project> { project in
    project.name.localizedStandardContains(searchText) ||
    project.clientName.localizedStandardContains(searchText)
}
```

**User Experience:**
- Search bar appears in navigation bar
- Real-time filtering as user types
- Empty state shows `ContentUnavailableView.search` when no results found
- Returns to full list when search is cleared

---

### 2. Expenses List View

**Search Capabilities:**
- Search by expense description
- Filter by category (Materials, Labor, Equipment, Miscellaneous)
- Filter by date range (start date, end date, or both)
- Multiple filters can be combined

**Implementation:**
```swift
.searchable(text: $searchText, prompt: "Search expenses")
```

**Advanced Filters:**
- Filter button in navigation bar (leading position)
- Button shows filled icon when filters are active
- Sheet presentation with filter options

**Predicate Logic:**
```swift
#Predicate<Expense> { expense in
    // Search text filter
    let matchesSearch = searchText.isEmpty || 
        expense.descriptionText.localizedStandardContains(searchText)
    
    // Category filter
    let matchesCategory = selectedCategory == nil || 
        expense.category == selectedCategory!
    
    // Date range filter
    let matchesDateRange: Bool
    if let start = startDate, let end = endDate {
        matchesDateRange = expense.date >= start && expense.date <= end
    } else if let start = startDate {
        matchesDateRange = expense.date >= start
    } else if let end = endDate {
        matchesDateRange = expense.date <= end
    } else {
        matchesDateRange = true
    }
    
    return matchesSearch && matchesCategory && matchesDateRange
}
```

**Filter UI:**
- Category picker (inline style)
- Start date toggle and date picker
- End date toggle and date picker
- "Clear All Filters" button
- "Apply" and "Cancel" actions

**User Experience:**
- Filter icon in toolbar shows active state
- Date pickers only visible when toggles are enabled
- Filters persist while navigating
- Clear all filters returns to default view

---

### 3. Invoices List View

**Search Capabilities:**
- Search by client name
- Filter by payment status (All, Paid, Unpaid, Overdue)

**Implementation:**
```swift
.searchable(text: $searchText, prompt: "Search invoices")
```

**Status Filter Menu:**
- Menu button in navigation bar (leading position)
- Four filter options with icons:
  - All (doc.text)
  - Paid (checkmark.circle.fill)
  - Unpaid (clock.fill)
  - Overdue (exclamationmark.triangle.fill)

**Predicate Logic:**
```swift
#Predicate<Invoice> { invoice in
    // Search text filter (by client name)
    let matchesSearch = searchText.isEmpty || 
        invoice.clientName.localizedStandardContains(searchText)
    
    // Status filter
    let matchesStatus: Bool
    switch statusFilter {
    case .all:
        matchesStatus = true
    case .paid:
        matchesStatus = invoice.isPaid
    case .unpaid:
        matchesStatus = !invoice.isPaid && invoice.dueDate >= now
    case .overdue:
        matchesStatus = !invoice.isPaid && invoice.dueDate < now
    }
    
    return matchesSearch && matchesStatus
}
```

**User Experience:**
- Quick status filtering via toolbar menu
- Icon changes to filled state when filter is active
- Status logic properly distinguishes between unpaid and overdue
- Search and status filter work together

---

### 4. Clients List View

**Search Capabilities:**
- Search by client name
- Search by email address
- Search by phone number
- Handles optional fields (email, phone) gracefully

**Implementation:**
```swift
.searchable(text: $searchText, prompt: "Search by name, email, or phone")
```

**Predicate Logic:**
```swift
#Predicate<Client> { client in
    client.name.localizedStandardContains(searchText) ||
    (client.email != nil && client.email!.localizedStandardContains(searchText)) ||
    (client.phone != nil && client.phone!.localizedStandardContains(searchText))
}
```

**User Experience:**
- Comprehensive search across all contact information
- Safe handling of nil values for optional fields
- Alphabetically sorted by name
- Empty state with search-specific message

---

## Technical Architecture

### Pattern: Query Initialization in Child Views

To enable dynamic predicate building with SwiftData, we use a pattern of separating the main view from the content view:

```swift
struct MainListView: View {
    @State private var searchText: String = ""
    @State private var filterState: FilterType?
    
    var body: some View {
        NavigationStack {
            ContentListView(searchText: searchText, filterState: filterState)
                .searchable(text: $searchText)
        }
    }
}

private struct ContentListView: View {
    let searchText: String
    let filterState: FilterType?
    
    init(searchText: String, filterState: FilterType?) {
        self.searchText = searchText
        self.filterState = filterState
        
        // Build predicate in initializer
        let predicate: Predicate<Model>
        // ... predicate logic
        
        _items = Query(filter: predicate, sort: \.property)
    }
    
    @Query private var items: [Model]
    
    var body: some View {
        List {
            ForEach(items) { item in
                // Row content
            }
        }
    }
}
```

**Why This Pattern?**
- SwiftData's `@Query` macro requires predicates at initialization time
- State changes trigger view recreation, allowing predicate updates
- Clean separation of concerns
- Proper SwiftUI lifecycle management

### SwiftData Predicate Features Used

**1. `localizedStandardContains(_:)`**
- Case-insensitive search
- Diacritic-insensitive (e.g., "cafe" matches "café")
- Locale-aware comparison
- Built-in to String type in SwiftData predicates

**2. Optional Handling**
- Explicit nil checks: `field != nil`
- Force unwrap after check: `field!.contains()`
- Safe because predicate guarantees non-nil after check

**3. Date Comparison**
- Direct comparison operators: `>=`, `<=`, `<`, `>`
- Works with `Date` type directly
- Efficient database-level filtering

**4. Enum Comparison**
- Direct equality: `expense.category == selectedCategory!`
- Works with any `Codable` enum
- Type-safe comparisons

### Empty State Handling

Different empty states based on context:

```swift
.overlay {
    if items.isEmpty {
        if hasNoFilters {
            // Show "Add your first..." message
            ContentUnavailableView(
                "No Items",
                systemImage: "icon",
                description: Text("Description")
            )
        } else {
            // Show search-specific empty state
            ContentUnavailableView.search
            // or
            ContentUnavailableView.search(text: searchText)
        }
    }
}
```

## Performance Considerations

### Database-Level Filtering
All predicates are evaluated at the database level, not in memory:
- SwiftData converts `#Predicate` to SQL WHERE clauses
- Only matching records are loaded into memory
- Excellent performance even with large datasets

### View Efficiency
- Child views only recreate when filter parameters change
- @Query automatically manages data updates
- SwiftUI diffing ensures minimal UI updates

### Best Practices
✅ Build predicates in view initializers
✅ Use immutable filter parameters (let, not @State)
✅ Keep predicate logic simple and readable
✅ Use `localizedStandardContains` for text search
✅ Handle optionals explicitly in predicates

❌ Don't filter in body (causes unnecessary recomputation)
❌ Don't use complex computed properties in predicates
❌ Don't perform filtering in memory after query

## Testing Checklist

### Projects Search
- [ ] Search by project name works
- [ ] Search by client name works
- [ ] Mixed case search works
- [ ] Empty search shows all projects
- [ ] No results shows search empty state

### Expenses Search & Filters
- [ ] Text search works on description
- [ ] Category filter works for each category
- [ ] Start date filter works alone
- [ ] End date filter works alone
- [ ] Date range filter works (both dates)
- [ ] Combined filters work together
- [ ] Filter button shows active state
- [ ] Clear all filters resets everything
- [ ] Cancel preserves previous state
- [ ] Apply commits filter changes

### Invoices Search & Filters
- [ ] Search by client name works
- [ ] "All" status shows everything
- [ ] "Paid" shows only paid invoices
- [ ] "Unpaid" excludes overdue invoices
- [ ] "Overdue" shows correct invoices
- [ ] Status filter icon shows active state
- [ ] Search + status filter work together

### Clients Search
- [ ] Search by name works
- [ ] Search by email works
- [ ] Search by phone works
- [ ] Search works with missing email
- [ ] Search works with missing phone
- [ ] Empty search shows all clients
- [ ] No results shows search empty state

## Usage Examples

### Simple Text Search (Projects, Clients)

```swift
struct MyListView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            FilteredContent(searchText: searchText)
                .searchable(text: $searchText, prompt: "Search...")
        }
    }
}

private struct FilteredContent: View {
    let searchText: String
    
    init(searchText: String) {
        self.searchText = searchText
        let predicate = #Predicate<Model> { item in
            searchText.isEmpty || item.name.localizedStandardContains(searchText)
        }
        _items = Query(filter: predicate, sort: \.name)
    }
    
    @Query private var items: [Model]
    
    var body: some View {
        List(items) { item in
            Text(item.name)
        }
    }
}
```

### Advanced Filtering (Expenses)

```swift
struct MyListView: View {
    @State private var searchText = ""
    @State private var category: Category?
    @State private var startDate: Date?
    
    var body: some View {
        NavigationStack {
            FilteredContent(
                searchText: searchText,
                category: category,
                startDate: startDate
            )
            .searchable(text: $searchText)
            .toolbar {
                Button("Filters") {
                    // Show filter sheet
                }
            }
        }
    }
}

private struct FilteredContent: View {
    let searchText: String
    let category: Category?
    let startDate: Date?
    
    init(searchText: String, category: Category?, startDate: Date?) {
        self.searchText = searchText
        self.category = category
        self.startDate = startDate
        
        let predicate = #Predicate<Model> { item in
            let matchesText = searchText.isEmpty || 
                item.description.localizedStandardContains(searchText)
            let matchesCategory = category == nil || item.category == category!
            let matchesDate = startDate == nil || item.date >= startDate!
            
            return matchesText && matchesCategory && matchesDate
        }
        
        _items = Query(filter: predicate, sort: \.date, order: .reverse)
    }
    
    @Query private var items: [Model]
    
    var body: some View {
        List(items) { item in
            Text(item.description)
        }
    }
}
```

### Status-Based Filtering (Invoices)

```swift
enum StatusFilter: CaseIterable {
    case all, active, inactive
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .inactive: return "Inactive"
        }
    }
}

struct MyListView: View {
    @State private var statusFilter: StatusFilter = .all
    
    var body: some View {
        NavigationStack {
            FilteredContent(statusFilter: statusFilter)
                .toolbar {
                    Menu {
                        Picker("Filter", selection: $statusFilter) {
                            ForEach(StatusFilter.allCases, id: \.self) { filter in
                                Text(filter.displayName).tag(filter)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
        }
    }
}

private struct FilteredContent: View {
    let statusFilter: StatusFilter
    
    init(statusFilter: StatusFilter) {
        self.statusFilter = statusFilter
        
        let predicate = #Predicate<Model> { item in
            switch statusFilter {
            case .all:
                return true
            case .active:
                return item.isActive == true
            case .inactive:
                return item.isActive == false
            }
        }
        
        _items = Query(filter: predicate, sort: \.name)
    }
    
    @Query private var items: [Model]
    
    var body: some View {
        List(items) { item in
            Text(item.name)
        }
    }
}
```

## Troubleshooting

### Predicate Not Updating

**Problem:** Changes to search text or filters don't update the list

**Solution:** Ensure you're using the child view pattern. The parent view holds @State, the child view receives immutable parameters and rebuilds @Query in init.

### Optional Field Search Issues

**Problem:** Search crashes or doesn't work with optional fields

**Solution:** Always check for nil before accessing optional in predicate:
```swift
(client.email != nil && client.email!.localizedStandardContains(searchText))
```

### Switch Statement in Predicate

**Problem:** Compiler error with switch in predicate

**Solution:** SwiftData predicates don't support switch directly. Use if-else or assign to variable first:
```swift
let matchesStatus: Bool
switch statusFilter {
case .all: matchesStatus = true
case .paid: matchesStatus = invoice.isPaid
}
return matchesSearch && matchesStatus
```

### Date Comparison Issues

**Problem:** Date filter not working as expected

**Solution:** Make sure you're using Date() at the time of predicate creation, not in the predicate itself:
```swift
// ✅ Good
let now = Date()
let predicate = #Predicate<Model> { item in
    item.date >= now
}

// ❌ Bad - Date() in predicate
let predicate = #Predicate<Model> { item in
    item.date >= Date() // This won't work in SwiftData
}
```

## Future Enhancements

Potential improvements:

1. **Search History**
   - Store recent searches in UserDefaults
   - Show suggestions under search bar

2. **Search Scopes**
   - `.searchable(text:placement:scope:)` for category tabs
   - Example: Search in "All", "Active", or "Archived" projects

3. **Advanced Text Search**
   - Multi-word search (AND/OR logic)
   - Partial match highlighting
   - Search result ranking

4. **Filter Presets**
   - Save common filter combinations
   - Quick apply from menu

5. **Export Filtered Results**
   - CSV export of visible items
   - Share filtered list

6. **Smart Filters**
   - "This Month", "This Year" date presets
   - "High Value", "Recent" shortcuts

## Related Documentation

- [SwiftData Predicate Documentation](https://developer.apple.com/documentation/swiftdata/predicate)
- [SwiftUI Searchable Modifier](https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:))
- [ContentUnavailableView Guide](https://developer.apple.com/documentation/swiftui/contentunavailableview)

---

**Created**: March 13, 2026  
**Version**: 1.0  
**iOS Target**: iOS 17.0+

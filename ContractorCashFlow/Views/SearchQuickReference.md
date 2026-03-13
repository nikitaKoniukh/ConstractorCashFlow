# Search Functionality - Quick Reference

## Summary of Changes

### Files Modified
1. ✅ **ViewsProjectsListView.swift** - Added search by name and client
2. ✅ **ViewsExpensesListView.swift** - Added search and advanced filtering (category, date range)
3. ✅ **ViewsInvoicesListView.swift** - Added search and status filtering (paid/unpaid/overdue)
4. ✅ **ViewsClientsListView.swift** - Added search by name, email, phone

### Files Created
1. 📄 **SearchImplementationGuide.md** - Comprehensive documentation
2. 📄 **SearchQuickReference.md** - This file

---

## Feature Overview

| View | Search Fields | Filters | Status Indicators |
|------|---------------|---------|-------------------|
| **Projects** | Name, Client Name | None | Active status badge |
| **Expenses** | Description | Category, Date Range | Active filter icon |
| **Invoices** | Client Name | Payment Status | Active filter icon |
| **Clients** | Name, Email, Phone | None | - |

---

## Code Patterns

### Basic Search Pattern

```swift
// Parent View (holds state)
struct ListView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ListContent(searchText: searchText)
                .searchable(text: $searchText, prompt: "Search...")
        }
    }
}

// Child View (contains Query)
private struct ListContent: View {
    let searchText: String
    
    init(searchText: String) {
        self.searchText = searchText
        _items = Query(filter: buildPredicate(searchText), sort: \.name)
    }
    
    @Query private var items: [Model]
    
    var body: some View {
        List(items) { item in /* ... */ }
    }
    
    private func buildPredicate(_ search: String) -> Predicate<Model> {
        if search.isEmpty {
            return #Predicate { _ in true }
        } else {
            return #Predicate { item in
                item.name.localizedStandardContains(search)
            }
        }
    }
}
```

### Multiple Filter Pattern

```swift
struct ListView: View {
    @State private var searchText = ""
    @State private var filterOption: FilterType?
    
    var body: some View {
        NavigationStack {
            ListContent(searchText: searchText, filter: filterOption)
                .searchable(text: $searchText)
                .toolbar {
                    // Filter UI
                }
        }
    }
}

private struct ListContent: View {
    let searchText: String
    let filter: FilterType?
    
    init(searchText: String, filter: FilterType?) {
        self.searchText = searchText
        self.filter = filter
        
        let predicate = #Predicate<Model> { item in
            let matchesSearch = searchText.isEmpty || 
                item.name.localizedStandardContains(searchText)
            let matchesFilter = filter == nil || item.type == filter!
            return matchesSearch && matchesFilter
        }
        
        _items = Query(filter: predicate, sort: \.name)
    }
    
    @Query private var items: [Model]
    
    var body: some View {
        List(items) { item in /* ... */ }
    }
}
```

---

## Predicate Syntax Reference

### Text Search
```swift
// Single field
item.name.localizedStandardContains(searchText)

// Multiple fields (OR)
item.name.localizedStandardContains(searchText) ||
item.description.localizedStandardContains(searchText)
```

### Optional Fields
```swift
// Must check nil first
(item.email != nil && item.email!.localizedStandardContains(searchText))
```

### Enum Comparison
```swift
// Direct equality
item.category == selectedCategory!

// With nil check
selectedCategory == nil || item.category == selectedCategory!
```

### Boolean Fields
```swift
// Direct boolean
item.isActive == true

// Negation
item.isActive == false
// or
!item.isActive
```

### Date Comparison
```swift
// Single boundary
item.date >= startDate!

// Range
item.date >= startDate! && item.date <= endDate!

// With nil checks
let matchesDate: Bool
if let start = startDate, let end = endDate {
    matchesDate = item.date >= start && item.date <= end
} else if let start = startDate {
    matchesDate = item.date >= start
} else if let end = endDate {
    matchesDate = item.date <= end
} else {
    matchesDate = true
}
```

### Combining Conditions
```swift
#Predicate<Model> { item in
    let condition1 = /* ... */
    let condition2 = /* ... */
    let condition3 = /* ... */
    
    return condition1 && condition2 && condition3
}
```

---

## UI Components

### Search Bar
```swift
.searchable(text: $searchText, prompt: "Placeholder text")
```

### Filter Button (Simple Menu)
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Menu {
            Picker("Filter", selection: $filterType) {
                ForEach(FilterType.allCases) { type in
                    Text(type.name).tag(type)
                }
            }
        } label: {
            Label("Filter", systemImage: isFiltered ? "icon.fill" : "icon")
        }
    }
}
```

### Filter Button (Sheet)
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button {
            showingFilters.toggle()
        } label: {
            Label("Filters", systemImage: hasFilters ? "icon.fill" : "icon")
        }
    }
}
.sheet(isPresented: $showingFilters) {
    FilterView(/* ... */)
}
```

### Empty States
```swift
.overlay {
    if items.isEmpty {
        if hasNoActiveFilters {
            // Default empty state
            ContentUnavailableView(
                "No Items",
                systemImage: "icon",
                description: Text("Description")
            )
        } else {
            // Search/filter empty state
            ContentUnavailableView.search
            // or with custom text
            ContentUnavailableView.search(text: searchText)
        }
    }
}
```

---

## Common Predicates

### All Items (No Filter)
```swift
#Predicate<Model> { _ in true }
```

### Text Search (Case-Insensitive)
```swift
#Predicate<Model> { item in
    searchText.isEmpty || item.name.localizedStandardContains(searchText)
}
```

### Multiple Text Fields
```swift
#Predicate<Model> { item in
    searchText.isEmpty ||
    item.name.localizedStandardContains(searchText) ||
    item.description.localizedStandardContains(searchText)
}
```

### Category/Enum Filter
```swift
#Predicate<Model> { item in
    category == nil || item.category == category!
}
```

### Boolean Status
```swift
#Predicate<Model> { item in
    item.isActive == true
}
```

### Date Range
```swift
#Predicate<Model> { item in
    let matchesDate: Bool
    if let start = startDate, let end = endDate {
        matchesDate = item.date >= start && item.date <= end
    } else if let start = startDate {
        matchesDate = item.date >= start
    } else if let end = endDate {
        matchesDate = item.date <= end
    } else {
        matchesDate = true
    }
    return matchesDate
}
```

### Complex Multi-Filter
```swift
#Predicate<Model> { item in
    // Text search
    let matchesSearch = searchText.isEmpty || 
        item.name.localizedStandardContains(searchText)
    
    // Category filter
    let matchesCategory = category == nil || item.category == category!
    
    // Status filter
    let matchesStatus = item.isActive == showActiveOnly
    
    // Date filter
    let matchesDate = startDate == nil || item.date >= startDate!
    
    return matchesSearch && matchesCategory && matchesStatus && matchesDate
}
```

---

## Testing Checklist

### Basic Functionality
- [ ] Search bar appears in navigation
- [ ] Typing filters results in real-time
- [ ] Clearing search shows all items
- [ ] Case-insensitive search works
- [ ] Empty state appears for no results

### Advanced Filters
- [ ] Filter button appears in toolbar
- [ ] Filter button shows active state
- [ ] Filters combine with search correctly
- [ ] Clearing filters returns to default
- [ ] Cancel preserves previous state
- [ ] Apply commits changes

### Edge Cases
- [ ] Empty database shows correct message
- [ ] Search with special characters works
- [ ] Optional fields handle nil correctly
- [ ] Date boundaries are inclusive/exclusive as intended
- [ ] Multiple filters work together

### Performance
- [ ] Large datasets filter quickly
- [ ] No lag when typing
- [ ] Smooth scrolling after filter
- [ ] Memory usage remains stable

---

## Tips & Best Practices

### ✅ DO

- Use `localizedStandardContains` for text search (handles case, diacritics, locale)
- Build predicates in view initializer
- Check optionals explicitly (`!= nil` then `!`)
- Use immutable filter parameters in child view
- Provide clear empty states
- Show active filter state in UI
- Combine search with other filters
- Test with various data sets

### ❌ DON'T

- Filter in view body (causes unnecessary work)
- Use `.filter { }` on Query results (defeats database optimization)
- Call Date() inside predicates (won't work in SwiftData)
- Use switch statements in predicates (use if/let/variables)
- Force unwrap without nil check
- Forget empty state variations

---

## Troubleshooting

### Search Not Working
**Check:** Is the child view pattern used? Does init receive searchText?

### Predicate Compile Error
**Check:** Are optionals handled with `!= nil` check first?

### Performance Issues
**Check:** Is filtering done in predicate, not after query?

### Filter Not Showing Active State
**Check:** Is the computed property or condition correct?

### Empty State Wrong
**Check:** Are you checking all filter conditions for "has filters" logic?

---

## Example: Adding Search to New View

```swift
// 1. Create parent view with state
struct NewListView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            // 2. Pass search to child
            NewListContent(searchText: searchText)
                // 3. Add searchable modifier
                .searchable(text: $searchText, prompt: "Search...")
                .navigationTitle("Items")
        }
    }
}

// 4. Create child view with Query
private struct NewListContent: View {
    let searchText: String
    
    init(searchText: String) {
        self.searchText = searchText
        
        // 5. Build predicate
        let predicate: Predicate<MyModel>
        if searchText.isEmpty {
            predicate = #Predicate { _ in true }
        } else {
            predicate = #Predicate { item in
                item.name.localizedStandardContains(searchText)
            }
        }
        
        // 6. Initialize Query with predicate
        _items = Query(filter: predicate, sort: \.name)
    }
    
    @Query private var items: [MyModel]
    
    var body: some View {
        List(items) { item in
            Text(item.name)
        }
        // 7. Add empty states
        .overlay {
            if items.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView("No Items", systemImage: "tray")
                } else {
                    ContentUnavailableView.search
                }
            }
        }
    }
}
```

---

**Created**: March 13, 2026  
**Version**: 1.0  
**iOS Target**: iOS 17.0+

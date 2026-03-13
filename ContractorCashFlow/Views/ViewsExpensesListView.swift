//
//  ExpensesListView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI
import SwiftData

struct ExpensesListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchText: String = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var isShowingFilters = false
    
    var body: some View {
        NavigationStack {
            ExpensesListContent(
                searchText: searchText,
                selectedCategory: selectedCategory,
                startDate: startDate,
                endDate: endDate
            )
            .navigationTitle(LocalizationKey.Expense.title)
            .searchable(text: $searchText, prompt: "Search expenses")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingFilters.toggle()
                    } label: {
                        Label("Filters", systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.isShowingNewExpense = true
                    } label: {
                        Label(LocalizationKey.Expense.add, systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.isShowingNewExpense },
                set: { appState.isShowingNewExpense = $0 }
            )) {
                NewExpenseView()
            }
            .sheet(isPresented: $isShowingFilters) {
                ExpenseFiltersView(
                    selectedCategory: $selectedCategory,
                    startDate: $startDate,
                    endDate: $endDate
                )
            }
            .alert("Error", isPresented: Binding(
                get: { appState.isShowingError },
                set: { appState.isShowingError = $0 }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(appState.errorMessage ?? "An error occurred")
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedCategory != nil || startDate != nil || endDate != nil
    }
}

// MARK: - Expenses List Content (with filtering)
private struct ExpensesListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    let searchText: String
    let selectedCategory: ExpenseCategory?
    let startDate: Date?
    let endDate: Date?
    
    init(searchText: String, selectedCategory: ExpenseCategory?, startDate: Date?, endDate: Date?) {
        self.searchText = searchText
        self.selectedCategory = selectedCategory
        self.startDate = startDate
        self.endDate = endDate
        
        // Build complex predicate with all filters
        let predicate: Predicate<Expense>
        
        // Capture values outside the predicate to simplify the expression
        let hasStart = startDate != nil
        let hasEnd = endDate != nil
        let hasCategory = selectedCategory != nil
        let searchEmpty = searchText.isEmpty
        
        predicate = #Predicate<Expense> { expense in
            // All conditions combined into ONE single expression
            (searchEmpty || expense.descriptionText.localizedStandardContains(searchText)) &&
            (!hasCategory || expense.category == selectedCategory!) &&
            (
                (!hasStart && !hasEnd) ||
                (hasStart && hasEnd && expense.date >= startDate! && expense.date <= endDate!) ||
                (hasStart && !hasEnd && expense.date >= startDate!) ||
                (!hasStart && hasEnd && expense.date <= endDate!)
            )
        }
        
        _expenses = Query(filter: predicate, sort: \Expense.date, order: .reverse)
    }
    
    @Query private var expenses: [Expense]
    
    var body: some View {
        List {
            ForEach(expenses) { expense in
                ExpenseRow(expense: expense)
            }
            .onDelete(perform: deleteExpenses)
        }
        .overlay {
            if expenses.isEmpty {
                if searchText.isEmpty && selectedCategory == nil && startDate == nil && endDate == nil {
                    // Enhanced empty state with CTA button
                    ContentUnavailableView {
                        Label("No Expenses", systemImage: "dollarsign.circle")
                    } description: {
                        Text("No expenses recorded yet. Start tracking your project costs")
                    } actions: {
                        Button {
                            appState.isShowingNewExpense = true
                        } label: {
                            Text("Add Expense")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView.search(text: searchText.isEmpty ? "No matching expenses" : searchText)
                }
            }
        }
    }
    
    private func deleteExpenses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                do {
                    modelContext.delete(expenses[index])
                    try modelContext.save()
                } catch {
                    appState.showError("Failed to delete expense: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Expense Filters View
private struct ExpenseFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedCategory: ExpenseCategory?
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    
    @State private var isUsingStartDate = false
    @State private var isUsingEndDate = false
    @State private var tempStartDate = Date()
    @State private var tempEndDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Filter by Category", selection: $selectedCategory) {
                        Text("All Categories").tag(nil as ExpenseCategory?)
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category as ExpenseCategory?)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                Section("Date Range") {
                    Toggle("Start Date", isOn: $isUsingStartDate)
                    if isUsingStartDate {
                        DatePicker("From", selection: $tempStartDate, displayedComponents: .date)
                    }
                    
                    Toggle("End Date", isOn: $isUsingEndDate)
                    if isUsingEndDate {
                        DatePicker("To", selection: $tempEndDate, displayedComponents: .date)
                    }
                }
                
                Section {
                    Button("Clear All Filters", role: .destructive) {
                        clearFilters()
                    }
                }
            }
            .navigationTitle("Filter Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                }
            }
            .onAppear {
                isUsingStartDate = startDate != nil
                isUsingEndDate = endDate != nil
                if let start = startDate {
                    tempStartDate = start
                }
                if let end = endDate {
                    tempEndDate = end
                }
            }
        }
    }
    
    private func applyFilters() {
        startDate = isUsingStartDate ? tempStartDate : nil
        endDate = isUsingEndDate ? tempEndDate : nil
    }
    
    private func clearFilters() {
        selectedCategory = nil
        startDate = nil
        endDate = nil
        isUsingStartDate = false
        isUsingEndDate = false
        dismiss()
    }
}

// MARK: - Expense Row Component
struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.descriptionText)
                    .font(.headline)
                
                HStack {
                    Text(expense.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    
                    if let project = expense.project {
                        Text(project.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(expense.date, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(expense.amount, format: .currency(code: "USD"))
                .font(.headline)
                .foregroundStyle(.red)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Placeholder View
struct NewExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var projects: [Project]
    
    @State private var category: ExpenseCategory = .materials
    @State private var amount: Double = 0
    @State private var descriptionText: String = ""
    @State private var date: Date = Date()
    @State private var selectedProject: Project?
    @State private var isSaving: Bool = false
    
    private var isValid: Bool {
        !descriptionText.isEmpty && amount > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(LocalizationKey.Expense.category, selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            Text(category.localizedDisplayName).tag(category)
                        }
                    }
                    
                    TextField(LocalizationKey.Expense.amount, value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    
                    TextField(LocalizationKey.Expense.description, text: $descriptionText)
                    
                    DatePicker(LocalizationKey.Expense.date, selection: $date, displayedComponents: .date)
                } header: {
                    Text(LocalizationKey.Expense.details)
                }
                
                Section {
                    Picker(LocalizationKey.Expense.projectOptional, selection: $selectedProject) {
                        Text(LocalizationKey.Expense.none).tag(nil as Project?)
                        ForEach(projects.filter { $0.isActive }) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }
                } header: {
                    Text(LocalizationKey.Expense.project)
                }
            }
            .navigationTitle(LocalizationKey.Expense.newTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationKey.Action.cancel) {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKey.Action.save) {
                        saveExpense()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }
    
    private func saveExpense() {
        isSaving = true
        
        let expense = Expense(
            category: category,
            amount: amount,
            descriptionText: descriptionText,
            date: date,
            project: selectedProject
        )
        
        do {
            modelContext.insert(expense)
            try modelContext.save()
            
            // Check budget notifications if associated with a project
            if let project = selectedProject {
                Task {
                    await NotificationService.shared.checkBudgetAndScheduleNotifications(for: project)
                }
            }
            
            dismiss()
        } catch {
            appState.showError("Failed to save expense: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

#Preview {
    ExpensesListView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

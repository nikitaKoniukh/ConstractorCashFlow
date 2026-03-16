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
        NavigationStack(path: appState.navigationPath(for: .expenses)) {
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
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    
    let searchText: String
    let selectedCategory: ExpenseCategory?
    let startDate: Date?
    let endDate: Date?
    
    @State private var expenseToEdit: Expense?
    
    private var filteredExpenses: [Expense] {
        var result = allExpenses
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.descriptionText.localizedStandardContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        if let start = startDate {
            let startOfDay = Calendar.current.startOfDay(for: start)
            result = result.filter { $0.date >= startOfDay }
        }
        
        if let end = endDate {
            if let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: Calendar.current.startOfDay(for: end)) {
                result = result.filter { $0.date <= endOfDay }
            }
        }
        
        return result
    }
    
    var body: some View {
        List {
            ForEach(filteredExpenses) { expense in
                ExpenseRow(expense: expense)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        expenseToEdit = expense
                    }
            }
            .onDelete(perform: deleteExpenses)
        }
        .sheet(item: $expenseToEdit) { expense in
            EditExpenseView(expense: expense)
        }
        .overlay {
            if filteredExpenses.isEmpty {
                if searchText.isEmpty && selectedCategory == nil && startDate == nil && endDate == nil {
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
                let expense = filteredExpenses[index]
                modelContext.delete(expense)
            }
            try? modelContext.save()
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
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
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
            
            Text(expense.amount, format: .currency(code: currencyCode))
                .font(.headline)
                .foregroundStyle(.red)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - New Expense View
struct NewExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    @Query private var projects: [Project]
    @Query(sort: \LaborDetails.workerName) private var allWorkers: [LaborDetails]
    
    @State private var category: ExpenseCategory = .materials
    @State private var amount: Double?
    @State private var descriptionText: String = ""
    @State private var date: Date = Date()
    @State private var selectedProject: Project?
    @State private var isSaving: Bool = false
    
    // Labor-specific fields
    @State private var selectedWorker: LaborDetails?
    @State private var unitsWorked: String = ""
    
    private var isValid: Bool {
        !descriptionText.isEmpty && (amount ?? 0) > 0
    }
    
    /// Auto-calculated amount from worker rate * units (hours or days)
    private var calculatedAmount: Double? {
        guard let worker = selectedWorker,
              let rate = worker.rate,
              rate > 0 else { return nil }
        
        if worker.laborType.usesQuantity {
            // Hourly or Daily: rate × units
            guard let units = Double(unitsWorked), units > 0 else { return nil }
            return rate * units
        } else {
            // Contract / Subcontractor: fixed price
            return rate
        }
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
                    
                    // Show worker picker when labor category is chosen
                    if category == .labor && !allWorkers.isEmpty {
                        Picker(LocalizationKey.Labor.selectWorker, selection: $selectedWorker) {
                            Text(LocalizationKey.Labor.selectWorkerPrompt).tag(nil as LaborDetails?)
                            ForEach(allWorkers) { worker in
                                HStack {
                                    Text(worker.workerName)
                                    if let rate = worker.rate {
                                        Text("(\(rate.formatted(.currency(code: currencyCode)))\(worker.laborType.rateSuffix))")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(worker as LaborDetails?)
                            }
                        }
                        .onChange(of: selectedWorker) {
                            updateFromWorkerSelection()
                        }
                        
                        if let worker = selectedWorker {
                            if worker.laborType.usesQuantity {
                                // Hourly / Daily: show quantity input
                                HStack {
                                    Text(worker.laborType.quantityLabel)
                                    Spacer()
                                    TextField("0.0", text: $unitsWorked)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .onChange(of: unitsWorked) {
                                            if let calc = calculatedAmount {
                                                amount = calc
                                            }
                                        }
                                }
                                
                                if let calc = calculatedAmount {
                                    HStack {
                                        Text(LocalizationKey.Labor.calculatedTotal)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(calc.formatted(.currency(code: currencyCode)))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.subheadline)
                                }
                            } else {
                                // Contract / Subcontractor: show the fixed price
                                if let rate = worker.rate {
                                    HStack {
                                        Text(LocalizationKey.Labor.contractPrice)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(rate.formatted(.currency(code: currencyCode)))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.subheadline)
                                }
                            }
                        }
                    }
                    
                    TextField(LocalizationKey.Expense.amount, value: $amount, format: .currency(code: currencyCode))
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
            .onChange(of: category) {
                // Reset labor fields when switching away from labor category
                if category != .labor {
                    selectedWorker = nil
                    unitsWorked = ""
                }
            }
        }
    }
    
    /// Updates description and amount when a worker is selected
    private func updateFromWorkerSelection() {
        if let worker = selectedWorker {
            descriptionText = "Labor: \(worker.workerName)"
            unitsWorked = ""
            // For contract/subcontractor, auto-fill the amount from the fixed rate
            if !worker.laborType.usesQuantity, let rate = worker.rate {
                amount = rate
            }
        }
    }
    
    private func saveExpense() {
        isSaving = true
        
        let units = Double(unitsWorked)
        
        let expense = Expense(
            category: category,
            amount: amount ?? 0,
            descriptionText: descriptionText,
            date: date,
            project: selectedProject,
            worker: category == .labor ? selectedWorker : nil,
            unitsWorked: category == .labor ? units : nil
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

// MARK: - Edit Expense View
struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    @Query private var projects: [Project]
    @Query(sort: \LaborDetails.workerName) private var allWorkers: [LaborDetails]
    
    let expense: Expense
    
    @State private var category: ExpenseCategory
    @State private var amount: Double?
    @State private var descriptionText: String
    @State private var date: Date
    @State private var selectedProject: Project?
    @State private var isSaving: Bool = false
    
    // Labor-specific fields
    @State private var selectedWorker: LaborDetails?
    @State private var unitsWorked: String
    
    init(expense: Expense) {
        self.expense = expense
        _category = State(initialValue: expense.category)
        _amount = State(initialValue: expense.amount)
        _descriptionText = State(initialValue: expense.descriptionText)
        _date = State(initialValue: expense.date)
        _selectedProject = State(initialValue: expense.project)
        _selectedWorker = State(initialValue: expense.worker)
        _unitsWorked = State(initialValue: expense.unitsWorked.map { String($0) } ?? "")
    }
    
    private var isValid: Bool {
        !descriptionText.isEmpty && (amount ?? 0) > 0
    }
    
    private var calculatedAmount: Double? {
        guard let worker = selectedWorker,
              let rate = worker.rate,
              rate > 0 else { return nil }
        
        if worker.laborType.usesQuantity {
            guard let units = Double(unitsWorked), units > 0 else { return nil }
            return rate * units
        } else {
            return rate
        }
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
                    
                    if category == .labor && !allWorkers.isEmpty {
                        Picker(LocalizationKey.Labor.selectWorker, selection: $selectedWorker) {
                            Text(LocalizationKey.Labor.selectWorkerPrompt).tag(nil as LaborDetails?)
                            ForEach(allWorkers) { worker in
                                HStack {
                                    Text(worker.workerName)
                                    if let rate = worker.rate {
                                        Text("(\(rate.formatted(.currency(code: currencyCode)))\(worker.laborType.rateSuffix))")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(worker as LaborDetails?)
                            }
                        }
                        .onChange(of: selectedWorker) {
                            updateFromWorkerSelection()
                        }
                        
                        if let worker = selectedWorker {
                            if worker.laborType.usesQuantity {
                                HStack {
                                    Text(worker.laborType.quantityLabel)
                                    Spacer()
                                    TextField("0.0", text: $unitsWorked)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .onChange(of: unitsWorked) {
                                            if let calc = calculatedAmount {
                                                amount = calc
                                            }
                                        }
                                }
                                
                                if let calc = calculatedAmount {
                                    HStack {
                                        Text(LocalizationKey.Labor.calculatedTotal)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(calc.formatted(.currency(code: currencyCode)))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.subheadline)
                                }
                            } else {
                                if let rate = worker.rate {
                                    HStack {
                                        Text(LocalizationKey.Labor.contractPrice)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(rate.formatted(.currency(code: currencyCode)))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.subheadline)
                                }
                            }
                        }
                    }
                    
                    TextField(LocalizationKey.Expense.amount, value: $amount, format: .currency(code: currencyCode))
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
            .navigationTitle("Edit Expense")
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
                        saveChanges()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .onChange(of: category) {
                if category != .labor {
                    selectedWorker = nil
                    unitsWorked = ""
                }
            }
        }
    }
    
    private func updateFromWorkerSelection() {
        if let worker = selectedWorker {
            descriptionText = "Labor: \(worker.workerName)"
            unitsWorked = ""
            if !worker.laborType.usesQuantity, let rate = worker.rate {
                amount = rate
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        expense.category = category
        expense.amount = amount ?? 0
        expense.descriptionText = descriptionText
        expense.date = date
        expense.project = selectedProject
        expense.worker = category == .labor ? selectedWorker : nil
        expense.unitsWorked = category == .labor ? Double(unitsWorked) : nil
        
        do {
            try modelContext.save()
            
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

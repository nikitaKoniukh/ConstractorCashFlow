//
//  ProjectsListView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI
import SwiftData

struct ProjectsListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchaseManager
    @Query private var allProjects: [Project]
    @State private var searchText: String = ""
    @State private var isShowingPaywall = false
    
    var body: some View {
        NavigationStack(path: appState.navigationPath(for: .projects)) {
            ProjectsListContent(searchText: searchText)
            .navigationTitle(LocalizationKey.Project.title)
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(project: project)
            }
            .searchable(text: $searchText, prompt: "Search by name or client")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if purchaseManager.canCreateProject(currentCount: allProjects.count) {
                            appState.isShowingNewProject = true
                        } else {
                            isShowingPaywall = true
                        }
                    } label: {
                        Label(LocalizationKey.Project.add, systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.isShowingNewProject },
                set: { appState.isShowingNewProject = $0 }
            )) {
                NewProjectView()
            }
            .alert("Error", isPresented: Binding(
                get: { appState.isShowingError },
                set: { appState.isShowingError = $0 }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(appState.errorMessage ?? "An error occurred")
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView(limitReachedMessage: String(localized: "subscription.projectLimitReached"))
            }
        }
    }
}

// MARK: - Projects List Content (with filtering)
private struct ProjectsListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(PurchaseManager.self) private var purchaseManager
    let searchText: String
    
    init(searchText: String) {
        self.searchText = searchText
        
        // Build predicate based on search text
        let predicate: Predicate<Project>
        if searchText.isEmpty {
            predicate = #Predicate<Project> { _ in true }
        } else {
            predicate = #Predicate<Project> { project in
                project.name.localizedStandardContains(searchText) ||
                project.clientName.localizedStandardContains(searchText)
            }
        }
        
        _projects = Query(filter: predicate, sort: \Project.createdDate, order: .reverse)
    }
    
    @Query private var projects: [Project]
    
    var body: some View {
        List {
            ForEach(projects) { project in
                NavigationLink(value: project) {
                    ProjectRow(project: project)
                }
            }
            .onDelete(perform: deleteProjects)
        }
        .overlay {
            if projects.isEmpty {
                if searchText.isEmpty {
                    // Enhanced empty state with CTA button
                    ContentUnavailableView {
                        Label("No Projects", systemImage: "folder.badge.plus")
                    } description: {
                        Text("Add your first project to get started tracking expenses and invoices")
                    } actions: {
                        Button {
                            appState.isShowingNewProject = true
                        } label: {
                            Text("Add Project")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
    
    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                do {
                    modelContext.delete(projects[index])
                    try modelContext.save()
                } catch {
                    appState.showError("Failed to delete project: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Project Row Component
struct ProjectRow: View {
    let project: Project
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(project.name)
                    .font(.headline)
                Spacer()
                if project.isActive {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
            
            Text(project.clientName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Label("\(project.totalExpenses, format: .currency(code: currencyCode))", systemImage: "arrow.down")
                    .font(.caption)
                    .foregroundStyle(.red)
                
                Spacer()
                
                Label("\(project.totalIncome, format: .currency(code: currencyCode))", systemImage: "arrow.up")
                    .font(.caption)
                    .foregroundStyle(.green)
                
                Spacer()
                
                Text("\(String(localized: "project.balance.label")): \(project.balance, format: .currency(code: currencyCode))")
                    .font(.caption)
                    .foregroundStyle(project.balance >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Project Detail View
struct ProjectDetailView: View {
    let project: Project
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(PurchaseManager.self) private var purchaseManager
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    @Query private var allExpenses: [Expense]
    @Query private var allInvoices: [Invoice]
    
    @State private var isShowingEditSheet = false
    @State private var isShowingAddExpense = false
    @State private var isShowingAddInvoice = false
    @State private var isShowingShareSheet = false
    @State private var expenseToEdit: Expense?
    @State private var isShowingPaywall = false
    @State private var paywallMessage: String? = nil
    
    var body: some View {
        List {
            // Financial Summary Section
            Section {
                FinancialSummaryCard(project: project)
            }
            
            // Project Information Section
            Section(String(localized: "project.information")) {
                LabeledContent(LocalizationKey.Project.name, value: project.name)
                
                // Clickable client name
                LabeledContent(LocalizationKey.Project.clientName) {
                    if let client = findClient(named: project.clientName) {
                        NavigationLink(value: client) {
                            Text(project.clientName)
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Text(project.clientName)
                    }
                }
                
                LabeledContent(LocalizationKey.Project.budget) {
                    Text(project.budget, format: .currency(code: currencyCode))
                }
                LabeledContent("Status") {
                    HStack {
                        Circle()
                            .fill(project.isActive ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(project.isActive ? "Active" : "Inactive")
                            .foregroundStyle(project.isActive ? .primary : .secondary)
                    }
                }
                LabeledContent("Created") {
                    Text(project.createdDate, style: .date)
                }
            }
            
            // Budget Utilization Section
            Section("Budget Utilization") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Spent")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(project.totalExpenses, format: .currency(code: currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    ProgressView(value: min(project.budgetUtilization, 100), total: 100) {
                        Text("\(project.budgetUtilization, format: .number.precision(.fractionLength(1)))% of budget")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tint(budgetColor(for: project.budgetUtilization))
                    
                    HStack {
                        Text("Remaining")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(max(0, project.budget - project.totalExpenses), format: .currency(code: currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(project.totalExpenses > project.budget ? .red : .green)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Expenses by Category Chart
            if !project.safeExpenses.isEmpty {
                Section("Expenses by Category") {
                    ExpenseCategoryChart(expenses: project.safeExpenses)
                        .frame(height: 200)
                }
            }
            
            // Expenses Section
            Section {
                if project.safeExpenses.isEmpty {
                    VStack(spacing: 12) {
                        Text("No expenses recorded")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            if purchaseManager.canCreateExpense(currentCount: allExpenses.count) {
                                isShowingAddExpense = true
                            } else {
                                paywallMessage = String(localized: "subscription.expenseLimitReached")
                                isShowingPaywall = true
                            }
                        } label: {
                            Label("Add First Expense", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                } else {
                    ForEach(project.safeExpenses.sorted(by: { $0.date > $1.date })) { expense in
                        ExpenseRowView(expense: expense)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                expenseToEdit = expense
                            }
                    }
                    .onDelete(perform: deleteExpenses)
                }
            } header: {
                HStack {
                    Text("Expenses")
                    Spacer()
                    if !project.safeExpenses.isEmpty {
                        Button {
                            if purchaseManager.canCreateExpense(currentCount: allExpenses.count) {
                                isShowingAddExpense = true
                            } else {
                                paywallMessage = String(localized: "subscription.expenseLimitReached")
                                isShowingPaywall = true
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    Text(project.totalExpenses, format: .currency(code: currencyCode))
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            
            // Invoices Section
            Section {
                if project.safeInvoices.isEmpty {
                    VStack(spacing: 12) {
                        Text("No invoices created")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            if purchaseManager.canCreateInvoice(currentCount: allInvoices.count) {
                                isShowingAddInvoice = true
                            } else {
                                paywallMessage = String(localized: "subscription.invoiceLimitReached")
                                isShowingPaywall = true
                            }
                        } label: {
                            Label("Add First Invoice", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                } else {
                    ForEach(project.safeInvoices.sorted(by: { $0.createdDate > $1.createdDate })) { invoice in
                        InvoiceRowView(invoice: invoice)
                    }
                    .onDelete(perform: deleteInvoices)
                }
            } header: {
                HStack {
                    Text("Invoices")
                    Spacer()
                    if !project.safeInvoices.isEmpty {
                        Button {
                            if purchaseManager.canCreateInvoice(currentCount: allInvoices.count) {
                                isShowingAddInvoice = true
                            } else {
                                paywallMessage = String(localized: "subscription.invoiceLimitReached")
                                isShowingPaywall = true
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(project.totalIncome, format: .currency(code: currencyCode))
                            .font(.subheadline)
                            .foregroundStyle(.green)
                        if project.safeInvoices.count > 0 {
                            let paidCount = project.safeInvoices.filter { $0.isPaid }.count
                            Text("\(paidCount)/\(project.safeInvoices.count) paid")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Client.self) { client in
            ClientDetailView(client: client)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isShowingEditSheet = true
                    } label: {
                        Label("Edit Project", systemImage: "pencil")
                    }
                    
                    Button {
                        isShowingShareSheet = true
                    } label: {
                        Label("Export & Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button {
                        if purchaseManager.canCreateExpense(currentCount: allExpenses.count) {
                            isShowingAddExpense = true
                        } else {
                            paywallMessage = String(localized: "subscription.expenseLimitReached")
                            isShowingPaywall = true
                        }
                    } label: {
                        Label("Add Expense", systemImage: "arrow.down.circle")
                    }
                    
                    Button {
                        if purchaseManager.canCreateInvoice(currentCount: allInvoices.count) {
                            isShowingAddInvoice = true
                        } else {
                            paywallMessage = String(localized: "subscription.invoiceLimitReached")
                            isShowingPaywall = true
                        }
                    } label: {
                        Label("Add Invoice", systemImage: "arrow.up.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EditProjectView(project: project)
        }
        .sheet(isPresented: $isShowingAddExpense) {
            NewExpenseView()
        }
        .sheet(item: $expenseToEdit) { expense in
            EditExpenseView(expense: expense)
        }
        .sheet(isPresented: $isShowingAddInvoice) {
            NewInvoiceView()
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView(limitReachedMessage: paywallMessage)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ProjectExportView(project: project)
        }
    }
    
    private func budgetColor(for utilization: Double) -> Color {
        if utilization < 50 { return .green }
        if utilization < 80 { return .orange }
        return .red
    }
    
    private func findClient(named name: String) -> Client? {
        let descriptor = FetchDescriptor<Client>(
            predicate: #Predicate { $0.name == name }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    private func deleteExpenses(at offsets: IndexSet) {
        let sortedExpenses = project.safeExpenses.sorted(by: { $0.date > $1.date })
        
        for index in offsets {
            let expense = sortedExpenses[index]
            do {
                modelContext.delete(expense)
                try modelContext.save()
            } catch {
                appState.showError("Failed to delete expense: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteInvoices(at offsets: IndexSet) {
        let sortedInvoices = project.safeInvoices.sorted(by: { $0.createdDate > $1.createdDate })
        
        for index in offsets {
            let invoice = sortedInvoices[index]
            
            // Cancel notifications for this invoice
            Task {
                await NotificationService.shared.cancelNotifications(for: invoice)
            }
            
            do {
                modelContext.delete(invoice)
                try modelContext.save()
            } catch {
                appState.showError("Failed to delete invoice: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Financial Summary Card
struct FinancialSummaryCard: View {
    let project: Project
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
    var body: some View {
        VStack(spacing: 16) {
            // Balance
            VStack(spacing: 4) {
                Text("Net Balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(project.balance, format: .currency(code: currencyCode))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(project.balance >= 0 ? .green : .red)
            }
            
            Divider()
            
            // Income and Expenses
            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    Label {
                        Text("Income")
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Text(project.totalIncome, format: .currency(code: currencyCode))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 8) {
                    Label {
                        Text("Expenses")
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.red)
                    }
                    Text(project.totalExpenses, format: .currency(code: currencyCode))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Profit Margin (if has income)
            if project.totalIncome > 0 {
                Divider()
                
                HStack {
                    Text("Profit Margin")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(project.profitMargin, format: .number.precision(.fractionLength(1)))
                        .font(.headline)
                        + Text("%")
                        .font(.headline)
                }
                .foregroundStyle(project.profitMargin >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Expense Row View
struct ExpenseRowView: View {
    let expense: Expense
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: expense.category.iconName)
                .font(.title3)
                .foregroundStyle(expense.category.chartColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.descriptionText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    Text(expense.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expense.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(expense.amount, format: .currency(code: currencyCode))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Invoice Row View
struct InvoiceRowView: View {
    let invoice: Invoice
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
    private var statusColor: Color {
        if invoice.isPaid { return .green }
        if invoice.isOverdue { return .red }
        return .orange
    }
    
    private var statusText: String {
        if invoice.isPaid { return "Paid" }
        if invoice.isOverdue { return "Overdue" }
        return "Pending"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            VStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
            }
            .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Invoice to \(invoice.clientName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Due \(invoice.dueDate, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(invoice.amount, format: .currency(code: currencyCode))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(invoice.isPaid ? .green : .primary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - ExpenseCategory Extension
extension ExpenseCategory {
    var iconName: String {
        switch self {
        case .materials: return "hammer.fill"
        case .labor: return "person.fill"
        case .equipment: return "wrench.and.screwdriver.fill"
        case .subcontractor: return "person.2.badge.gearshape.fill"
        case .misc: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Edit Project View
struct EditProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
    let project: Project
    
    @State private var name: String
    @State private var clientName: String
    @State private var budget: Double?
    @State private var isActive: Bool
    @State private var isSaving: Bool = false
    
    init(project: Project) {
        self.project = project
        _name = State(initialValue: project.name)
        _clientName = State(initialValue: project.clientName)
        _budget = State(initialValue: project.budget > 0 ? project.budget : nil)
        _isActive = State(initialValue: project.isActive)
    }
    
    private var isValid: Bool {
        !name.isEmpty && !clientName.isEmpty && (budget ?? 0) > 0
    }
    
    private var hasChanges: Bool {
        name != project.name ||
        clientName != project.clientName ||
        (budget ?? 0) != project.budget ||
        isActive != project.isActive
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Information") {
                    TextField("Project Name", text: $name)
                    TextField("Client Name", text: $clientName)
                }
                
                Section("Budget") {
                    TextField("Budget", value: $budget, format: .currency(code: currencyCode))
                        .keyboardType(.decimalPad)
                    
                    if (budget ?? 0) < project.totalExpenses {
                        Label {
                            Text("New budget is less than current expenses (\(project.totalExpenses, format: .currency(code: currencyCode)))")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Toggle("Active Project", isOn: $isActive)
                } footer: {
                    Text("Inactive projects are hidden from some views but data is preserved")
                        .font(.caption)
                }
                
                Section {
                    LabeledContent("Created", value: project.createdDate, format: .dateTime)
                    LabeledContent("Total Expenses") {
                        Text(project.totalExpenses, format: .currency(code: currencyCode))
                    }
                    LabeledContent("Total Income") {
                        Text(project.totalIncome, format: .currency(code: currencyCode))
                    }
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid || !hasChanges || isSaving)
                }
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        project.name = name
        project.clientName = clientName
        project.budget = budget ?? 0
        project.isActive = isActive
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to update project: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

// MARK: - Expense Category Chart
struct ExpenseCategoryChart: View {
    let expenses: [Expense]
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
    private var categoryData: [(category: ExpenseCategory, amount: Double)] {
        let grouped = Dictionary(grouping: expenses) { $0.category }
        return ExpenseCategory.allCases.compactMap { category in
            let amount = grouped[category]?.reduce(0) { $0 + $1.amount } ?? 0
            return amount > 0 ? (category, amount) : nil
        }
        .sorted { $0.amount > $1.amount }
    }
    
    private var total: Double {
        categoryData.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(categoryData, id: \.category) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: item.category.iconName)
                            .foregroundStyle(item.category.chartColor)
                            .frame(width: 20)
                        
                        Text(item.category.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(item.amount, format: .currency(code: currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("(\(Int((item.amount / total) * 100))%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.category.chartColor.opacity(0.3))
                            .frame(width: geometry.size.width)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.category.chartColor)
                                    .frame(width: geometry.size.width * (item.amount / total))
                            }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Project Export View
struct ProjectExportView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    let project: Project
    
    @State private var includeExpenses = true
    @State private var includeInvoices = true
    @State private var shareText = ""
    @State private var isShowingShareSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Export Options") {
                    Toggle("Include Expenses", isOn: $includeExpenses)
                    Toggle("Include Invoices", isOn: $includeInvoices)
                }
                
                Section("Preview") {
                    Text(generateExportText())
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Export Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(
                        item: generateExportText(),
                        subject: Text("Project: \(project.name)"),
                        message: Text("Financial summary for \(project.name)")
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func generateExportText() -> String {
        var text = """
        PROJECT: \(project.name)
        Client: \(project.clientName)
        Status: \(project.isActive ? "Active" : "Inactive")
        Created: \(project.createdDate.formatted(date: .abbreviated, time: .omitted))
        
        FINANCIAL SUMMARY
        Budget: \(project.budget.formatted(.currency(code: currencyCode)))
        Total Expenses: \(project.totalExpenses.formatted(.currency(code: currencyCode)))
        Total Income: \(project.totalIncome.formatted(.currency(code: currencyCode)))
        Net Balance: \(project.balance.formatted(.currency(code: currencyCode)))
        Profit Margin: \(String(format: "%.1f%%", project.profitMargin))
        Budget Utilization: \(String(format: "%.1f%%", project.budgetUtilization))
        """
        
        if includeExpenses && !project.safeExpenses.isEmpty {
            text += "\n\nEXPENSES (\(project.safeExpenses.count))"
            text += "\n" + String(repeating: "-", count: 50)
            
            for expense in project.safeExpenses.sorted(by: { $0.date > $1.date }) {
                text += """
                \n\(expense.date.formatted(date: .abbreviated, time: .omitted)) - \(expense.category.displayName)
                  \(expense.descriptionText)
                  \(expense.amount.formatted(.currency(code: currencyCode)))
                """
            }
        }
        
        if includeInvoices && !project.safeInvoices.isEmpty {
            text += "\n\nINVOICES (\(project.safeInvoices.count))"
            text += "\n" + String(repeating: "-", count: 50)
            
            for invoice in project.safeInvoices.sorted(by: { $0.createdDate > $1.createdDate }) {
                let status = invoice.isPaid ? "PAID" : (invoice.isOverdue ? "OVERDUE" : "PENDING")
                text += """
                \n\(invoice.createdDate.formatted(date: .abbreviated, time: .omitted)) - \(status)
                  Due: \(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))
                  \(invoice.amount.formatted(.currency(code: currencyCode)))
                """
            }
        }
        
        text += "\n\n" + String(repeating: "=", count: 50)
        text += "\nExported: \(Date().formatted(date: .long, time: .shortened))"
        
        return text
    }
}

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
    @Query(sort: \Client.name) private var clients: [Client]
    
    @State private var name: String = ""
    @State private var clientName: String = ""
    @State private var selectedClient: Client?
    @State private var useExistingClient: Bool = false
    @State private var budget: Double?
    @State private var isActive: Bool = true
    @State private var isSaving: Bool = false
    
    // New client details when entering manually
    @State private var showClientDetails: Bool = false
    @State private var newClientEmail: String = ""
    @State private var newClientPhone: String = ""
    @State private var newClientAddress: String = ""
    @State private var newClientNotes: String = ""
    
    private var isValid: Bool {
        !name.isEmpty && !finalClientName.isEmpty && (budget ?? 0) > 0
    }
    
    /// Returns the final client name based on selection mode
    private var finalClientName: String {
        if useExistingClient {
            return selectedClient?.name ?? ""
        } else {
            return clientName
        }
    }
    
    /// Checks if a client with the given name already exists
    private func clientExists(name: String) -> Bool {
        clients.contains { $0.name.lowercased() == name.lowercased() }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "project.information")) {
                    TextField(LocalizationKey.Project.name, text: $name)
                    
                    // Client selection section
                    if !clients.isEmpty {
                        Picker("Client Source", selection: $useExistingClient) {
                            Text("Enter Name").tag(false)
                            Text("Select Existing").tag(true)
                        }
                        .pickerStyle(.segmented)
                        
                        if useExistingClient {
                            Picker(LocalizationKey.Project.clientName, selection: $selectedClient) {
                                Text("Select a client")
                                    .tag(nil as Client?)
                                
                                ForEach(clients) { client in
                                    Text(client.name)
                                        .tag(client as Client?)
                                }
                            }
                            
                            // Show selected client's details
                            if let client = selectedClient {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let email = client.email {
                                        Label(email, systemImage: "envelope")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let phone = client.phone {
                                        Label(phone, systemImage: "phone")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } else {
                            TextField(LocalizationKey.Project.clientName, text: $clientName)
                            
                            // Show warning if client name already exists
                            if !clientName.isEmpty && clientExists(name: clientName) {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text("A client with this name already exists. Consider selecting from existing clients.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        // No clients exist yet, just show text field
                        TextField(LocalizationKey.Project.clientName, text: $clientName)
                    }
                }
                
                // Show expandable client details section when entering new client manually
                if !useExistingClient && !clientName.isEmpty && !clientExists(name: clientName) {
                    Section {
                        DisclosureGroup(
                            isExpanded: $showClientDetails,
                            content: {
                                TextField(LocalizationKey.ClientS.email, text: $newClientEmail)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                
                                TextField(LocalizationKey.ClientS.phone, text: $newClientPhone)
                                    .textContentType(.telephoneNumber)
                                    .keyboardType(.phonePad)
                                
                                TextField(LocalizationKey.ClientS.address, text: $newClientAddress, axis: .vertical)
                                    .lineLimit(2...4)
                                
                                TextField(LocalizationKey.ClientS.notes, text: $newClientNotes, axis: .vertical)
                                    .lineLimit(2...4)
                            },
                            label: {
                                HStack {
                                    Image(systemName: "person.text.rectangle")
                                        .foregroundStyle(.blue)
                                    Text("New Client Details (Optional)")
                                        .font(.subheadline)
                                }
                            }
                        )
                    } header: {
                        Text("Client Information")
                    } footer: {
                        Text("Add contact details for this new client. These details will be saved and can be edited later.")
                            .font(.caption)
                    }
                }
                
                Section(String(localized: "project.budget")) {
                    TextField(LocalizationKey.Project.budget, value: $budget, format: .currency(code: currencyCode))
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Toggle(LocalizationKey.Project.active, isOn: $isActive)
                }
            }
            .navigationTitle(LocalizationKey.Project.newTitle)
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
                        saveProject()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }
    
    private func saveProject() {
        isSaving = true
        
        // Create or get client
        let projectClientName: String
        
        if useExistingClient {
            // Using existing client
            projectClientName = selectedClient?.name ?? ""
        } else {
            // Entering manually - create new client if doesn't exist
            projectClientName = clientName
            
            if !clientExists(name: clientName) {
                // Create new Client record
                let newClient = Client(
                    name: clientName,
                    email: newClientEmail.isEmpty ? nil : newClientEmail,
                    phone: newClientPhone.isEmpty ? nil : newClientPhone,
                    address: newClientAddress.isEmpty ? nil : newClientAddress,
                    notes: newClientNotes.isEmpty ? nil : newClientNotes
                )
                modelContext.insert(newClient)
            }
        }
        
        // Create project
        let project = Project(
            name: name,
            clientName: projectClientName,
            budget: budget ?? 0,
            isActive: isActive
        )
        
        do {
            modelContext.insert(project)
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to save project: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

#Preview {
    ProjectsListView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

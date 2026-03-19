//
//  ProjectDetailView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    let project: Project
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    @Query private var allExpenses: [Expense]
    @Query private var allInvoices: [Invoice]

    @State private var isShowingEditSheet = false
    @State private var isShowingAddExpense = false
    @State private var isShowingAddInvoice = false
    @State private var isShowingShareSheet = false
    @State private var expenseToEdit: Expense?
    @State private var isShowingPaywall = false
    @State private var paywallMessage: LocalizedStringKey? = nil

    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        Group {
            if isIPad {
                iPadLayout
            } else {
                iPhoneLayout
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
                        Label(LocalizationKey.Project.editProject, systemImage: "pencil")
                    }

                    Button {
                        isShowingShareSheet = true
                    } label: {
                        Label(LocalizationKey.Project.exportAndShare, systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button {
                        if purchaseManager.canCreateExpense(currentCount: allExpenses.count) {
                            isShowingAddExpense = true
                        } else {
                            paywallMessage = LocalizationKey.Subscription.expenseLimitReached
                            isShowingPaywall = true
                        }
                    } label: {
                        Label(LocalizationKey.Expense.add, systemImage: "arrow.down.circle")
                    }

                    Button {
                        if purchaseManager.canCreateInvoice(currentCount: allInvoices.count) {
                            isShowingAddInvoice = true
                        } else {
                            paywallMessage = LocalizationKey.Subscription.invoiceLimitReached
                            isShowingPaywall = true
                        }
                    } label: {
                        Label(LocalizationKey.Invoice.add, systemImage: "arrow.up.circle")
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

    // MARK: - iPhone Layout (single-column list)

    private var iPhoneLayout: some View {
        List {
            projectInfoSections
            expensesSection
            invoicesSection
        }
    }

    // MARK: - iPad Layout (two-column)

    private var iPadLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left column: summary + project info + budget + chart
            ScrollView {
                VStack(spacing: 0) {
                    List {
                        projectInfoSections
                    }
                    .listStyle(.insetGrouped)
                    .scrollDisabled(true)
                    // Allow the list to size to its content
                    .frame(minHeight: 600)
                }
            }
            .frame(maxWidth: 380)
            .background(Color(.systemGroupedBackground))

            Divider()

            // Right column: expenses + invoices
            List {
                expensesSection
                invoicesSection
            }
            .listStyle(.insetGrouped)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Shared Sections

    @ViewBuilder
    private var projectInfoSections: some View {
        // Financial Summary Section
        Section {
            FinancialSummaryCard(project: project)
        }

        // Project Information Section
        Section(LocalizationKey.Project.information) {
            LabeledContent(LocalizationKey.Project.name, value: project.name)

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
            LabeledContent(LocalizationKey.Project.status) {
                HStack {
                    Circle()
                        .fill(project.isActive ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(project.isActive ? LocalizationKey.Project.active : LocalizationKey.Project.inactive)
                        .foregroundStyle(project.isActive ? .primary : .secondary)
                }
            }
            LabeledContent(LocalizationKey.Project.created) {
                Text(project.createdDate, style: .date)
            }
        }

        // Budget Utilization Section
        Section(LocalizationKey.Project.budgetUtilizationTitle) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(LocalizationKey.Project.spent)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(project.totalExpenses, format: .currency(code: currencyCode))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                ProgressView(value: min(project.budgetUtilization, 100), total: 100) {
                    Text(String(format: LocalizationKey.Project.budgetUsedFormat, project.budgetUtilization.formatted(.number.precision(.fractionLength(1)))))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tint(budgetColor(for: project.budgetUtilization))

                HStack {
                    Text(LocalizationKey.Project.remaining)
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
            Section(LocalizationKey.Analytics.expensesByCategory) {
                ExpenseCategoryChart(expenses: project.safeExpenses)
                    .frame(height: isIPad ? 260 : 200)
            }
        }
    }

    @ViewBuilder
    private var expensesSection: some View {
        Section {
            if project.safeExpenses.isEmpty {
                VStack(spacing: 12) {
                    Text(LocalizationKey.Project.noExpensesRecorded)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        if purchaseManager.canCreateExpense(currentCount: allExpenses.count) {
                            isShowingAddExpense = true
                        } else {
                            paywallMessage = LocalizationKey.Subscription.expenseLimitReached
                            isShowingPaywall = true
                        }
                    } label: {
                        Label(LocalizationKey.Project.addFirstExpense, systemImage: "plus.circle.fill")
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
                Text(LocalizationKey.Expense.title)
                Spacer()
                if !project.safeExpenses.isEmpty {
                    Button {
                        if purchaseManager.canCreateExpense(currentCount: allExpenses.count) {
                            isShowingAddExpense = true
                        } else {
                            paywallMessage = LocalizationKey.Subscription.expenseLimitReached
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
    }

    @ViewBuilder
    private var invoicesSection: some View {
        Section {
            if project.safeInvoices.isEmpty {
                VStack(spacing: 12) {
                    Text(LocalizationKey.Project.noInvoicesCreated)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        if purchaseManager.canCreateInvoice(currentCount: allInvoices.count) {
                            isShowingAddInvoice = true
                        } else {
                            paywallMessage = LocalizationKey.Subscription.invoiceLimitReached
                            isShowingPaywall = true
                        }
                    } label: {
                        Label(LocalizationKey.Project.addFirstInvoice, systemImage: "plus.circle.fill")
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
                Text(LocalizationKey.Project.invoices)
                Spacer()
                if !project.safeInvoices.isEmpty {
                    Button {
                        if purchaseManager.canCreateInvoice(currentCount: allInvoices.count) {
                            isShowingAddInvoice = true
                        } else {
                            paywallMessage = LocalizationKey.Subscription.invoiceLimitReached
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
                        Text(String(format: LocalizationKey.Project.paidCountFormat, paidCount, project.safeInvoices.count))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
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
                appState.showError(String(format: LocalizationKey.General.failedToDeleteExpense, error.localizedDescription))
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
                appState.showError(String(format: LocalizationKey.General.failedToDeleteInvoice, error.localizedDescription))
            }
        }
    }
}

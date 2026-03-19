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
    @Environment(PurchaseManager.self) private var purchaseManager
    @Query private var allExpensesForCount: [Expense]
    
    @State private var searchText: String = ""
    @State private var isShowingPaywall = false
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
                        if purchaseManager.canCreateExpense(currentCount: allExpensesForCount.count) {
                            appState.isShowingNewExpense = true
                        } else {
                            isShowingPaywall = true
                        }
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
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView(limitReachedMessage: LocalizationKey.Subscription.expenseLimitReached)
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
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]

    let searchText: String
    let selectedCategory: ExpenseCategory?
    let startDate: Date?
    let endDate: Date?

    @State private var expenseToEdit: Expense?
    @State private var isShowingPaywall = false

    private var isIPad: Bool { horizontalSizeClass == .regular }

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
        Group {
            if isIPad {
                iPadGrid
            } else {
                iPhoneList
            }
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
                            if purchaseManager.canCreateExpense(currentCount: allExpenses.count) {
                                appState.isShowingNewExpense = true
                            } else {
                                isShowingPaywall = true
                            }
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
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView(limitReachedMessage: LocalizationKey.Subscription.expenseLimitReached)
        }
    }

    // MARK: iPhone – plain list
    private var iPhoneList: some View {
        List {
            ForEach(filteredExpenses) { expense in
                ExpenseRowView(expense: expense)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        expenseToEdit = expense
                    }
            }
            .onDelete(perform: deleteExpenses)
        }
    }

    // MARK: iPad – card grid
    private var iPadGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 340, maximum: 480), spacing: 16)],
                spacing: 16
            ) {
                ForEach(filteredExpenses) { expense in
                    ExpenseCardView(expense: expense)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            expenseToEdit = expense
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteExpense(expense)
                            } label: {
                                Label(LocalizationKey.General.delete, systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func deleteExpenses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredExpenses[index])
            }
            try? modelContext.save()
        }
    }

    private func deleteExpense(_ expense: Expense) {
        modelContext.delete(expense)
        try? modelContext.save()
    }
}
// MARK: - iPad Expense Card
private struct ExpenseCardView: View {
    let expense: Expense
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: expense.category.iconName)
                    .font(.title2)
                    .foregroundStyle(expense.category.chartColor)
                    .frame(width: 40, height: 40)
                    .background(expense.category.chartColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(expense.descriptionText)
                        .font(.headline)
                        .lineLimit(2)
                    if let project = expense.project {
                        Label(project.name, systemImage: "folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(expense.amount, format: .currency(code: currencyCode))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
            }
            .padding()

            Divider()

            // Footer
            HStack {
                Label(expense.category.displayName, systemImage: expense.category.iconName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(expense.category.chartColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(expense.category.chartColor.opacity(0.12))
                    .clipShape(Capsule())

                Spacer()

                Label {
                    Text(expense.date, format: .dateTime.month(.abbreviated).day().year())
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}


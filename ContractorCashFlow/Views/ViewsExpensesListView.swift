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
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    
    let searchText: String
    let selectedCategory: ExpenseCategory?
    let startDate: Date?
    let endDate: Date?
    
    @State private var expenseToEdit: Expense?
    @State private var isShowingPaywall = false
    
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
                ExpenseRowView(expense: expense)
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

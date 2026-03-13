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
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(expenses) { expense in
                    ExpenseRow(expense: expense)
                }
                .onDelete(perform: deleteExpenses)
            }
            .navigationTitle(LocalizationKey.Expense.title)
            .toolbar {
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
            .overlay {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        LocalizationKey.Expense.empty,
                        systemImage: "dollarsign.circle",
                        description: Text(LocalizationKey.Expense.emptyDescription)
                    )
                }
            }
        }
    }
    
    private func deleteExpenses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(expenses[index])
            }
        }
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
    @Query private var projects: [Project]
    
    @State private var category: ExpenseCategory = .materials
    @State private var amount: Double = 0
    @State private var descriptionText: String = ""
    @State private var date: Date = Date()
    @State private var selectedProject: Project?
    
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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKey.Action.save) {
                        saveExpense()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveExpense() {
        let expense = Expense(
            category: category,
            amount: amount,
            descriptionText: descriptionText,
            date: date,
            project: selectedProject
        )
        modelContext.insert(expense)
        dismiss()
    }
}

#Preview {
    ExpensesListView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

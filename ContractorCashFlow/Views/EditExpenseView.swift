//
//  EditExpenseView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
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
    @State private var selectedLaborType: LaborType
    @State private var unitsWorked: String
    @FocusState private var isAmountFieldFocused: Bool
    
    init(expense: Expense) {
        self.expense = expense
        _category = State(initialValue: expense.category)
        _amount = State(initialValue: expense.amount)
        _descriptionText = State(initialValue: expense.descriptionText)
        _date = State(initialValue: expense.date)
        _selectedProject = State(initialValue: expense.project)
        _selectedWorker = State(initialValue: expense.worker)
        _selectedLaborType = State(initialValue: expense.laborTypeSnapshot ?? expense.worker?.laborType ?? .hourly)
        _unitsWorked = State(initialValue: expense.unitsWorked.map { String($0) } ?? "")
    }
    
    private var isValid: Bool {
        !descriptionText.isEmpty && (amount ?? 0) > 0
    }
    
    private var calculatedAmount: Double? {
        guard let worker = selectedWorker else { return nil }
        
        if selectedLaborType == .subcontractor {
            return worker.rate
        }
        
        guard let rate = worker.effectiveRate(for: selectedLaborType), rate > 0 else { return nil }
        guard let units = Double(unitsWorked), units > 0 else { return nil }
        return rate * units
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
                            // Show type picker when worker supports both hourly and daily
                            if worker.supportsHourly && worker.supportsDaily {
                                Picker(LocalizationKey.Labor.typeLabel, selection: $selectedLaborType) {
                                    Text(LaborType.hourly.localizedDisplayName).tag(LaborType.hourly)
                                    Text(LaborType.daily.localizedDisplayName).tag(LaborType.daily)
                                }
                                .onChange(of: selectedLaborType) {
                                    unitsWorked = ""
                                    amount = nil
                                }
                            }
                            
                            if selectedLaborType.usesQuantity {
                                HStack {
                                    Text(selectedLaborType.quantityLabel)
                                    Spacer()
                                    TextField(LocalizationKey.Expense.decimalPlaceholder, text: $unitsWorked)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .focused($isAmountFieldFocused)
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
                    
                    CurrencyTextField(LocalizationKey.Expense.amount, value: $amount, currencyCode: currencyCode)
                    
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
            .navigationTitle(LocalizationKey.Expense.editTitle)
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocalizationKey.Action.done) {
                        isAmountFieldFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
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
        guard let worker = selectedWorker else { return }
        descriptionText = worker.workerName
        unitsWorked = ""
        amount = nil
        selectedLaborType = worker.laborType
        if worker.laborType == .subcontractor, let rate = worker.rate {
            amount = rate
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
        expense.laborTypeSnapshot = category == .labor ? selectedLaborType : nil
        
        do {
            try modelContext.save()
            
            if let project = selectedProject {
                Task {
                    await NotificationService.shared.checkBudgetAndScheduleNotifications(for: project)
                }
            }
            
            dismiss()
        } catch {
            appState.showError(String(format: LocalizationKey.General.failedToSaveExpense, error.localizedDescription))
            isSaving = false
        }
    }
}

#Preview {
    ExpensesListView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

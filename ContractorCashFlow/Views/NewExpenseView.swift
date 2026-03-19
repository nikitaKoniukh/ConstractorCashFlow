//
//  NewExpenseView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct NewExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
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
    @State private var selectedLaborType: LaborType = .hourly
    @State private var unitsWorked: String = ""
    @FocusState private var isAmountFieldFocused: Bool

    // Multi-day date selection (daily labor with >1 day)
    @State private var selectedDates: Set<DateComponents> = []

    /// Number of days entered (integer) when daily labor is chosen
    private var daysCount: Int {
        // Handle both integer and decimal input (e.g. "2" or "2.0")
        Int(Double(unitsWorked) ?? 0)
    }

    /// True when the multi-date picker should appear
    private var useMultiDatePicker: Bool {
        category == .labor && selectedLaborType == .daily && daysCount >= 2
    }

    private var isValid: Bool {
        // For labor, use calculatedAmount as fallback when amount hasn't been set yet
        let effectiveAmount = amount ?? calculatedAmount ?? 0
        guard !descriptionText.isEmpty && effectiveAmount > 0 else { return false }
        if useMultiDatePicker {
            return selectedDates.count == daysCount
        }
        return true
    }
    
    /// Auto-calculated amount from worker rate * units
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
                            // Show type picker when worker supports both hourly and daily
                            if worker.supportsHourly && worker.supportsDaily {
                                Picker(LocalizationKey.Labor.typeLabel, selection: $selectedLaborType) {
                                    Text(LaborType.hourly.localizedDisplayName).tag(LaborType.hourly)
                                    Text(LaborType.daily.localizedDisplayName).tag(LaborType.daily)
                                }
                                .onChange(of: selectedLaborType) {
                                    unitsWorked = ""
                                    amount = nil
                                    selectedDates = []
                                }
                            }
                            
                            if selectedLaborType.usesQuantity {
                                // Hourly / Daily: show quantity input
                                HStack {
                                    Text(selectedLaborType.quantityLabel)
                                    Spacer()
                                    TextField("0.0", text: $unitsWorked)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .focused($isAmountFieldFocused)
                                        .onChange(of: unitsWorked) {
                                            if let calc = calculatedAmount {
                                                amount = calc
                                            }
                                            // Reset multi-day selection when count changes
                                            selectedDates = []
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
                    
                    CurrencyTextField(LocalizationKey.Expense.amount, value: $amount, currencyCode: currencyCode)

                    TextField(LocalizationKey.Expense.description, text: $descriptionText)

                    if useMultiDatePicker {
                        // Show how many days are still needed
                        let remaining = daysCount - selectedDates.count
                        if remaining > 0 {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.orange)
                                Text("Select \(remaining) more day\(remaining == 1 ? "" : "s") (\(selectedDates.count)/\(daysCount))")
                                    .font(.subheadline)
                                    .foregroundStyle(.orange)
                            }
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("\(daysCount) days selected")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                            }
                        }
                        MultiDatePicker(LocalizationKey.Expense.date, selection: $selectedDates)
                    } else {
                        DatePicker(LocalizationKey.Expense.date, selection: $date, displayedComponents: .date)
                    }
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocalizationKey.Action.done) {
                        isAmountFieldFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .onChange(of: category) {
                // Reset labor fields when switching away from labor category
                if category != .labor {
                    selectedWorker = nil
                    unitsWorked = ""
                    amount = nil
                    selectedDates = []
                }
            }
        }
    }
    
    /// Updates description and type when a worker is selected
    private func updateFromWorkerSelection() {
        guard let worker = selectedWorker else { return }
        descriptionText = worker.workerName
        unitsWorked = ""
        amount = nil
        // Default to the worker's primary type
        selectedLaborType = worker.laborType
        // For subcontractor, auto-fill the fixed rate
        if worker.laborType == .subcontractor, let rate = worker.rate {
            amount = rate
        }
    }
    
    private func saveExpense() {
        isSaving = true
        // Ensure we use the calculated amount if the user never manually edited the field
        let finalAmount = amount ?? calculatedAmount ?? 0

        do {
            if useMultiDatePicker && !selectedDates.isEmpty {
                // Create one expense per selected day
                let dailyRate = finalAmount / Double(daysCount)
                let cal = Calendar.current
                for components in selectedDates {
                    let day = cal.date(from: components) ?? date
                    let expense = Expense(
                        category: category,
                        amount: dailyRate,
                        descriptionText: descriptionText,
                        date: day,
                        project: selectedProject,
                        worker: selectedWorker,
                        unitsWorked: 1,
                        laborTypeSnapshot: selectedLaborType
                    )
                    modelContext.insert(expense)
                }
            } else {
                let units = Double(unitsWorked)
                let expense = Expense(
                    category: category,
                    amount: finalAmount,
                    descriptionText: descriptionText,
                    date: date,
                    project: selectedProject,
                    worker: category == .labor ? selectedWorker : nil,
                    unitsWorked: category == .labor ? units : nil,
                    laborTypeSnapshot: category == .labor ? selectedLaborType : nil
                )
                modelContext.insert(expense)
            }

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

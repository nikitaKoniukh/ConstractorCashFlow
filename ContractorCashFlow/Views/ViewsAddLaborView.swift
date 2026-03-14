//
//  AddLaborView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 14/03/2026.
//

import SwiftUI
import SwiftData

struct AddLaborView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    @Query private var projects: [Project]
    
    // Form state
    @State private var workerName: String = ""
    @State private var laborType: LaborType = .hourly
    @State private var hourlyRate: String = ""
    @State private var hoursWorked: String = ""
    @State private var totalAmount: String = ""
    @State private var workDate: Date = Date()
    @State private var notes: String = ""
    @State private var isCompleted: Bool = false
    @State private var selectedProject: Project?
    @State private var createExpense: Bool = true
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case workerName, hourlyRate, hoursWorked, totalAmount, notes
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information
                Section(header: Text(LocalizationKey.Labor.basicInfo)) {
                    TextField(LocalizationKey.Labor.workerNamePlaceholder, text: $workerName)
                        .focused($focusedField, equals: .workerName)
                    
                    Picker(LocalizationKey.Labor.typeLabel, selection: $laborType) {
                        ForEach(LaborType.allCases, id: \.self) { type in
                            Text(type.localizedDisplayName).tag(type)
                        }
                    }
                    
                    DatePicker(LocalizationKey.Labor.workDateLabel, selection: $workDate, displayedComponents: .date)
                    
                    Toggle(LocalizationKey.Labor.completedLabel, isOn: $isCompleted)
                }
                
                // Rate and Hours Section (for hourly labor)
                if laborType == .hourly {
                    Section(header: Text(LocalizationKey.Labor.rateAndHours)) {
                        HStack {
                            Text(LocalizationKey.Labor.hourlyRateLabel)
                            Spacer()
                            TextField("0.00", text: $hourlyRate)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .hourlyRate)
                                .onChange(of: hourlyRate) {
                                    calculateTotal()
                                }
                        }
                        
                        HStack {
                            Text(LocalizationKey.Labor.hoursWorkedLabel)
                            Spacer()
                            TextField("0.0", text: $hoursWorked)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .hoursWorked)
                                .onChange(of: hoursWorked) {
                                    calculateTotal()
                                }
                        }
                        
                        if let rate = Double(hourlyRate), let hours = Double(hoursWorked), rate > 0, hours > 0 {
                            HStack {
                                Text(LocalizationKey.Labor.calculatedTotal)
                                Spacer()
                                Text((rate * hours).formatted(.currency(code: "USD")))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Total Amount Section
                Section(header: Text(LocalizationKey.Labor.totalAmount)) {
                    HStack {
                        Text(LocalizationKey.Labor.amountLabel)
                        Spacer()
                        TextField("0.00", text: $totalAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .totalAmount)
                    }
                    
                    if laborType == .hourly {
                        Text(LocalizationKey.Labor.manualOverrideHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Project Association
                Section(header: Text(LocalizationKey.Labor.projectAssociation)) {
                    Picker(LocalizationKey.Labor.selectProject, selection: $selectedProject) {
                        Text(LocalizationKey.Labor.noProject).tag(nil as Project?)
                        ForEach(projects.filter { $0.isActive }, id: \.id) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }
                    
                    if selectedProject != nil {
                        Toggle(LocalizationKey.Labor.createExpenseToggle, isOn: $createExpense)
                        
                        if createExpense {
                            Text(LocalizationKey.Labor.createExpenseHint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Notes Section
                Section(header: Text(LocalizationKey.Labor.notesLabel)) {
                    TextField(LocalizationKey.Labor.notesPlaceholder, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .notes)
                }
            }
            .navigationTitle(LocalizationKey.Labor.addTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationKey.General.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKey.General.save) {
                        saveLabor()
                    }
                    .disabled(!isFormValid)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocalizationKey.General.done) {
                        focusedField = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !workerName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !totalAmount.isEmpty &&
        Double(totalAmount) != nil &&
        Double(totalAmount)! > 0
    }
    
    private func calculateTotal() {
        guard laborType == .hourly,
              let rate = Double(hourlyRate),
              let hours = Double(hoursWorked),
              rate > 0, hours > 0 else {
            return
        }
        
        totalAmount = String(format: "%.2f", rate * hours)
    }
    
    private func saveLabor() {
        guard isFormValid else { return }
        
        let amount = Double(totalAmount) ?? 0
        let rate = laborType == .hourly ? Double(hourlyRate) : nil
        let hours = laborType == .hourly ? Double(hoursWorked) : nil
        
        // Create expense if needed
        var associatedExpense: Expense? = nil
        if createExpense && selectedProject != nil {
            let expense = Expense(
                category: .labor,
                amount: amount,
                descriptionText: "Labor: \(workerName)",
                date: workDate,
                project: selectedProject
            )
            modelContext.insert(expense)
            associatedExpense = expense
        }
        
        // Create labor details
        let labor = LaborDetails(
            workerName: workerName.trimmingCharacters(in: .whitespaces),
            laborType: laborType,
            hourlyRate: rate,
            hoursWorked: hours,
            totalAmount: amount,
            workDate: workDate,
            notes: notes.isEmpty ? nil : notes,
            isCompleted: isCompleted,
            expense: associatedExpense,
            project: selectedProject
        )
        
        modelContext.insert(labor)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to save labor details: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AddLaborView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, LaborDetails.self], inMemory: true)
}

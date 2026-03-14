//
//  EditLaborView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 14/03/2026.
//

import SwiftUI
import SwiftData

struct EditLaborView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    @Query private var projects: [Project]
    
    @Bindable var labor: LaborDetails
    
    // Form state
    @State private var workerName: String
    @State private var laborType: LaborType
    @State private var hourlyRate: String
    @State private var hoursWorked: String
    @State private var totalAmount: String
    @State private var workDate: Date
    @State private var notes: String
    @State private var isCompleted: Bool
    @State private var selectedProject: Project?
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case workerName, hourlyRate, hoursWorked, totalAmount, notes
    }
    
    init(labor: LaborDetails) {
        self.labor = labor
        
        // Initialize state from labor details
        _workerName = State(initialValue: labor.workerName)
        _laborType = State(initialValue: labor.laborType)
        _hourlyRate = State(initialValue: labor.hourlyRate.map { String(format: "%.2f", $0) } ?? "")
        _hoursWorked = State(initialValue: labor.hoursWorked.map { String(format: "%.1f", $0) } ?? "")
        _totalAmount = State(initialValue: String(format: "%.2f", labor.totalAmount))
        _workDate = State(initialValue: labor.workDate)
        _notes = State(initialValue: labor.notes ?? "")
        _isCompleted = State(initialValue: labor.isCompleted)
        _selectedProject = State(initialValue: labor.project)
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
                        ForEach(projects, id: \.id) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }
                    
                    if labor.expense != nil {
                        Label(LocalizationKey.Labor.linkedToExpense, systemImage: "link")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Notes Section
                Section(header: Text(LocalizationKey.Labor.notesLabel)) {
                    TextField(LocalizationKey.Labor.notesPlaceholder, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .notes)
                }
                
                // Delete Section
                Section {
                    Button(role: .destructive) {
                        deleteLabor()
                    } label: {
                        HStack {
                            Spacer()
                            Label(LocalizationKey.Labor.deleteLabel, systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(LocalizationKey.Labor.editTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationKey.General.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKey.General.save) {
                        saveChanges()
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
    
    private func saveChanges() {
        guard isFormValid else { return }
        
        labor.workerName = workerName.trimmingCharacters(in: .whitespaces)
        labor.laborType = laborType
        labor.hourlyRate = laborType == .hourly ? Double(hourlyRate) : nil
        labor.hoursWorked = laborType == .hourly ? Double(hoursWorked) : nil
        labor.totalAmount = Double(totalAmount) ?? 0
        labor.workDate = workDate
        labor.notes = notes.isEmpty ? nil : notes
        labor.isCompleted = isCompleted
        labor.project = selectedProject
        
        // Update associated expense if exists
        if let expense = labor.expense {
            expense.amount = labor.totalAmount
            expense.date = workDate
            expense.descriptionText = "Labor: \(labor.workerName)"
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to update labor details: \(error.localizedDescription)")
        }
    }
    
    private func deleteLabor() {
        modelContext.delete(labor)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to delete labor details: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: LaborDetails.self, configurations: config)
    
    let sampleLabor = LaborDetails(
        workerName: "John Doe",
        laborType: .hourly,
        hourlyRate: 50.0,
        hoursWorked: 8.0,
        totalAmount: 400.0
    )
    container.mainContext.insert(sampleLabor)
    
    return EditLaborView(labor: sampleLabor)
        .environment(AppState())
        .modelContainer(container)
}

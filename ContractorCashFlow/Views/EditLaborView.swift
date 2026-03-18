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
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    
    @Bindable var labor: LaborDetails
    
    // Form state
    @State private var workerName: String
    @State private var laborType: LaborType
    @State private var rate: Double?
    @State private var hourlyRate: Double?
    @State private var dailyRate: Double?
    @State private var notes: String
    @State private var showDeleteConfirmation = false
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case workerName, rate, notes
    }
    
    init(labor: LaborDetails) {
        self.labor = labor
        _workerName = State(initialValue: labor.workerName)
        _laborType = State(initialValue: labor.laborType)
        _rate = State(initialValue: labor.rate)
        _hourlyRate = State(initialValue: labor.hourlyRate)
        _dailyRate = State(initialValue: labor.dailyRate)
        _notes = State(initialValue: labor.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Worker Information
                Section(header: Text(LocalizationKey.Labor.basicInfo)) {
                    TextField(LocalizationKey.Labor.workerNamePlaceholder, text: $workerName)
                        .focused($focusedField, equals: .workerName)
                    
                    Picker(LocalizationKey.Labor.typeLabel, selection: $laborType) {
                        ForEach(LaborType.allCases, id: \.self) { type in
                            Text(type.localizedDisplayName).tag(type)
                        }
                    }
                }
                
                // Rate Section
                Section(header: Text(LocalizationKey.Labor.ratesHeader)) {
                    if laborType == .subcontractor {
                        HStack {
                            Text(LocalizationKey.Labor.contractPrice)
                            Spacer()
                            CurrencyTextField("0.00", value: $rate, currencyCode: currencyCode)
                                .multilineTextAlignment(.trailing)
                        }
                    } else {
                        HStack {
                            Text(LocalizationKey.Labor.ratePerHour)
                            Spacer()
                            CurrencyTextField("0.00", value: $hourlyRate, currencyCode: currencyCode)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text(LocalizationKey.Labor.ratePerDay)
                            Spacer()
                            CurrencyTextField("0.00", value: $dailyRate, currencyCode: currencyCode)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                // Notes Section
                Section(header: Text(LocalizationKey.Labor.notesLabel)) {
                    TextField(LocalizationKey.Labor.notesPlaceholder, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .notes)
                }
                
                // Stats Section (aggregated from linked expenses)
                if !labor.safeExpenses.isEmpty {
                    Section(header: Text(LocalizationKey.Labor.workerStats)) {
                        HStack {
                            Text(LocalizationKey.Labor.totalEarned)
                            Spacer()
                            Text(labor.totalAmountEarned.formatted(.currency(code: currencyCode)))
                                .fontWeight(.semibold)
                        }
                        
                        if labor.laborType.usesQuantity && labor.totalUnitsWorked > 0 {
                            HStack {
                                Text(labor.laborType == .hourly ? LocalizationKey.Labor.totalHours : LocalizationKey.Labor.totalDaysLabel)
                                Spacer()
                                Text(String(format: "%.1f", labor.totalUnitsWorked))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if !labor.associatedProjects.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(LocalizationKey.Labor.associatedProjects)
                                    .foregroundStyle(.secondary)
                                ForEach(labor.associatedProjects, id: \.id) { project in
                                    Label(project.name, systemImage: "folder")
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                // Created Date
                Section {
                    HStack {
                        Text(LocalizationKey.Labor.createdDate)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(labor.createdDate, format: .dateTime.month().day().year())
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Delete Section
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
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
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .confirmationDialog(
                "Delete Worker",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteWorker()
                }
            } message: {
                if labor.safeExpenses.isEmpty {
                    Text("Are you sure you want to delete this worker?")
                } else {
                    Text("This worker has \(labor.safeExpenses.count) linked expense(s). The expenses will remain but won't be linked to a worker.")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !workerName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveChanges() {
        guard isFormValid else { return }
        
        labor.workerName = workerName.trimmingCharacters(in: .whitespaces)
        labor.laborType = laborType
        labor.rate = laborType == .subcontractor ? rate : nil
        labor.hourlyRate = laborType != .subcontractor ? hourlyRate : nil
        labor.dailyRate = laborType != .subcontractor ? dailyRate : nil
        labor.notes = notes.isEmpty ? nil : notes
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to update worker: \(error.localizedDescription)")
        }
    }
    
    private func deleteWorker() {
        modelContext.delete(labor)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to delete worker: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: LaborDetails.self, Expense.self, Project.self, configurations: config)
    
    let sampleLabor = LaborDetails(
        workerName: "John Doe",
        laborType: .hourly,
        rate: 50.0
    )
    container.mainContext.insert(sampleLabor)
    
    return EditLaborView(labor: sampleLabor)
        .environment(AppState())
        .modelContainer(container)
}

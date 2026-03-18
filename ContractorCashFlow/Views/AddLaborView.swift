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
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    
    @Query private var existingWorkers: [LaborDetails]
    
    // Form state
    @State private var workerName: String = ""
    @State private var laborType: LaborType = .hourly
    @State private var rate: Double?
    @State private var hourlyRate: Double?
    @State private var dailyRate: Double?
    @State private var notes: String = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case workerName, rate, notes
    }
    
    /// Check if a worker with the same name already exists
    private var duplicateWarning: Bool {
        let trimmed = workerName.trimmingCharacters(in: .whitespaces).lowercased()
        return !trimmed.isEmpty && existingWorkers.contains { $0.workerName.lowercased() == trimmed }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Worker Information
                Section(header: Text(LocalizationKey.Labor.basicInfo)) {
                    TextField(LocalizationKey.Labor.workerNamePlaceholder, text: $workerName)
                        .focused($focusedField, equals: .workerName)
                    
                    if duplicateWarning {
                        Label(LocalizationKey.Labor.duplicateWorkerWarning, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
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
                    
                    Text(LocalizationKey.Labor.defaultRateHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                        saveWorker()
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
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !workerName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveWorker() {
        guard isFormValid else { return }
        
        let worker = LaborDetails(
            workerName: workerName.trimmingCharacters(in: .whitespaces),
            laborType: laborType,
            rate: laborType == .subcontractor ? rate : nil,
            hourlyRate: laborType != .subcontractor ? hourlyRate : nil,
            dailyRate: laborType != .subcontractor ? dailyRate : nil,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(worker)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError(String(format: LocalizationKey.General.failedToSaveWorker, error.localizedDescription))
        }
    }
}

#Preview {
    AddLaborView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, LaborDetails.self], inMemory: true)
}

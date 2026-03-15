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
    
    @Query private var existingWorkers: [LaborDetails]
    
    // Form state
    @State private var workerName: String = ""
    @State private var laborType: LaborType = .hourly
    @State private var hourlyRate: String = ""
    @State private var notes: String = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case workerName, hourlyRate, notes
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
                        Label("A worker with this name already exists", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    Picker(LocalizationKey.Labor.typeLabel, selection: $laborType) {
                        ForEach(LaborType.allCases, id: \.self) { type in
                            Text(type.localizedDisplayName).tag(type)
                        }
                    }
                }
                
                // Default Hourly Rate
                Section(header: Text(LocalizationKey.Labor.defaultRate)) {
                    HStack {
                        Text(LocalizationKey.Labor.hourlyRateLabel)
                        Spacer()
                        TextField("0.00", text: $hourlyRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .hourlyRate)
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
        
        let rate = Double(hourlyRate)
        
        let worker = LaborDetails(
            workerName: workerName.trimmingCharacters(in: .whitespaces),
            laborType: laborType,
            hourlyRate: rate,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(worker)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to save worker: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AddLaborView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, LaborDetails.self], inMemory: true)
}

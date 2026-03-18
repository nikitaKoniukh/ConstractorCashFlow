//
//  EditProjectView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData


struct EditProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    
    let project: Project
    
    @State private var name: String
    @State private var clientName: String
    @State private var budget: Double?
    @State private var isActive: Bool
    @State private var isSaving: Bool = false
    
    init(project: Project) {
        self.project = project
        _name = State(initialValue: project.name)
        _clientName = State(initialValue: project.clientName)
        _budget = State(initialValue: project.budget > 0 ? project.budget : nil)
        _isActive = State(initialValue: project.isActive)
    }
    
    private var isValid: Bool {
        !name.isEmpty && !clientName.isEmpty && (budget ?? 0) > 0
    }
    
    private var hasChanges: Bool {
        name != project.name ||
        clientName != project.clientName ||
        (budget ?? 0) != project.budget ||
        isActive != project.isActive
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Information") {
                    TextField("Project Name", text: $name)
                    TextField("Client Name", text: $clientName)
                }
                
                Section("Budget") {
                    CurrencyTextField("Budget", value: $budget, currencyCode: currencyCode)
                    
                    if (budget ?? 0) < project.totalExpenses {
                        Label {
                            Text("New budget is less than current expenses (\(project.totalExpenses, format: .currency(code: currencyCode)))")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Toggle("Active Project", isOn: $isActive)
                } footer: {
                    Text("Inactive projects are hidden from some views but data is preserved")
                        .font(.caption)
                }
                
                Section {
                    LabeledContent("Created", value: project.createdDate, format: .dateTime)
                    LabeledContent("Total Expenses") {
                        Text(project.totalExpenses, format: .currency(code: currencyCode))
                    }
                    LabeledContent("Total Income") {
                        Text(project.totalIncome, format: .currency(code: currencyCode))
                    }
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid || !hasChanges || isSaving)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocalizationKey.Action.done) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        project.name = name
        project.clientName = clientName
        project.budget = budget ?? 0
        project.isActive = isActive
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to update project: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

//
//  NewClientView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct NewClientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    
    private var isValid: Bool {
        !name.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(LocalizationKey.ClientS.information) {
                    TextField(LocalizationKey.ClientS.name, text: $name)
                    TextField(LocalizationKey.ClientS.email, text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField(LocalizationKey.ClientS.phone, text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(LocalizationKey.ClientS.address) {
                    TextField(LocalizationKey.ClientS.address, text: $address, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section(LocalizationKey.ClientS.notes) {
                    TextField(LocalizationKey.ClientS.notes, text: $notes, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle(LocalizationKey.ClientS.newTitle)
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
                        saveClient()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }
    
    private func saveClient() {
        isSaving = true
        
        let client = Client(
            name: name,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            address: address.isEmpty ? nil : address,
            notes: notes.isEmpty ? nil : notes
        )
        
        do {
            modelContext.insert(client)
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to save client: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

#Preview {
    ClientsListView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

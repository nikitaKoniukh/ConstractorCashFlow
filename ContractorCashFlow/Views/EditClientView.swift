//
//  EditClientView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct EditClientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @Bindable var client: Client
    
    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    @State private var notes: String
    @State private var isSaving: Bool = false
    
    init(client: Client) {
        self.client = client
        _name = State(initialValue: client.name)
        _email = State(initialValue: client.email ?? "")
        _phone = State(initialValue: client.phone ?? "")
        _address = State(initialValue: client.address ?? "")
        _notes = State(initialValue: client.notes ?? "")
    }
    
    private var isValid: Bool {
        !name.isEmpty
    }
    
    private var hasChanges: Bool {
        name != client.name ||
        (email.isEmpty ? nil : email) != client.email ||
        (phone.isEmpty ? nil : phone) != client.phone ||
        (address.isEmpty ? nil : address) != client.address ||
        (notes.isEmpty ? nil : notes) != client.notes
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
            .navigationTitle(LocalizationKey.ClientS.editTitle)
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
                    .disabled(!isValid || !hasChanges || isSaving)
                }
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        client.name = name
        client.email = email.isEmpty ? nil : email
        client.phone = phone.isEmpty ? nil : phone
        client.address = address.isEmpty ? nil : address
        client.notes = notes.isEmpty ? nil : notes
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to update client: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

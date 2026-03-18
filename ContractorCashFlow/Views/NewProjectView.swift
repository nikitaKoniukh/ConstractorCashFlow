//
//  NewProjectView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    
    @Query(sort: \Client.name) private var clients: [Client]
    
    @State private var name: String = ""
    @State private var clientName: String = ""
    @State private var selectedClient: Client?
    @State private var useExistingClient: Bool = false
    @State private var budget: Double?
    @State private var isActive: Bool = true
    @State private var isSaving: Bool = false
    
    // New client details when entering manually
    @State private var showClientDetails: Bool = false
    @State private var newClientEmail: String = ""
    @State private var newClientPhone: String = ""
    @State private var newClientAddress: String = ""
    @State private var newClientNotes: String = ""
    
    private var isValid: Bool {
        !name.isEmpty && !finalClientName.isEmpty && (budget ?? 0) > 0
    }
    
    /// Returns the final client name based on selection mode
    private var finalClientName: String {
        if useExistingClient {
            return selectedClient?.name ?? ""
        } else {
            return clientName
        }
    }
    
    /// Checks if a client with the given name already exists
    private func clientExists(name: String) -> Bool {
        clients.contains { $0.name.lowercased() == name.lowercased() }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(LocalizationKey.Project.information) {
                    TextField(LocalizationKey.Project.name, text: $name)
                    
                    // Client selection section
                    if !clients.isEmpty {
                        Picker("Client Source", selection: $useExistingClient) {
                            Text("Enter Name").tag(false)
                            Text("Select Existing").tag(true)
                        }
                        .pickerStyle(.segmented)
                        
                        if useExistingClient {
                            Picker(LocalizationKey.Project.clientName, selection: $selectedClient) {
                                Text("Select a client")
                                    .tag(nil as Client?)
                                
                                ForEach(clients) { client in
                                    Text(client.name)
                                        .tag(client as Client?)
                                }
                            }
                            
                            // Show selected client's details
                            if let client = selectedClient {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let email = client.email {
                                        Label(email, systemImage: "envelope")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let phone = client.phone {
                                        Label(phone, systemImage: "phone")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } else {
                            TextField(LocalizationKey.Project.clientName, text: $clientName)
                            
                            // Show warning if client name already exists
                            if !clientName.isEmpty && clientExists(name: clientName) {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text("A client with this name already exists. Consider selecting from existing clients.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        // No clients exist yet, just show text field
                        TextField(LocalizationKey.Project.clientName, text: $clientName)
                    }
                }
                
                // Show expandable client details section when entering new client manually
                if !useExistingClient && !clientName.isEmpty && !clientExists(name: clientName) {
                    Section {
                        DisclosureGroup(
                            isExpanded: $showClientDetails,
                            content: {
                                TextField(LocalizationKey.ClientS.email, text: $newClientEmail)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                
                                TextField(LocalizationKey.ClientS.phone, text: $newClientPhone)
                                    .textContentType(.telephoneNumber)
                                    .keyboardType(.phonePad)
                                
                                TextField(LocalizationKey.ClientS.address, text: $newClientAddress, axis: .vertical)
                                    .lineLimit(2...4)
                                
                                TextField(LocalizationKey.ClientS.notes, text: $newClientNotes, axis: .vertical)
                                    .lineLimit(2...4)
                            },
                            label: {
                                HStack {
                                    Image(systemName: "person.text.rectangle")
                                        .foregroundStyle(.blue)
                                    Text("New Client Details (Optional)")
                                        .font(.subheadline)
                                }
                            }
                        )
                    } header: {
                        Text("Client Information")
                    } footer: {
                        Text("Add contact details for this new client. These details will be saved and can be edited later.")
                            .font(.caption)
                    }
                }
                
                Section(LocalizationKey.Project.budget) {
                    CurrencyTextField(LocalizationKey.Project.budget, value: $budget, currencyCode: currencyCode)
                }
                
                Section {
                    Toggle(LocalizationKey.Project.active, isOn: $isActive)
                }
            }
            .navigationTitle(LocalizationKey.Project.newTitle)
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
                        saveProject()
                    }
                    .disabled(!isValid || isSaving)
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
    
    private func saveProject() {
        isSaving = true
        
        // Create or get client
        let projectClientName: String
        
        if useExistingClient {
            // Using existing client
            projectClientName = selectedClient?.name ?? ""
        } else {
            // Entering manually - create new client if doesn't exist
            projectClientName = clientName
            
            if !clientExists(name: clientName) {
                // Create new Client record
                let newClient = Client(
                    name: clientName,
                    email: newClientEmail.isEmpty ? nil : newClientEmail,
                    phone: newClientPhone.isEmpty ? nil : newClientPhone,
                    address: newClientAddress.isEmpty ? nil : newClientAddress,
                    notes: newClientNotes.isEmpty ? nil : newClientNotes
                )
                modelContext.insert(newClient)
            }
        }
        
        // Create project
        let project = Project(
            name: name,
            clientName: projectClientName,
            budget: budget ?? 0,
            isActive: isActive
        )
        
        do {
            modelContext.insert(project)
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to save project: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

#Preview {
    ProjectsListView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

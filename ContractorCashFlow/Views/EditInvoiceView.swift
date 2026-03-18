//
//  EditInvoiceView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct EditInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    @Query private var projects: [Project]
    @Query(sort: \Client.name) private var clients: [Client]
    
    @Bindable var invoice: Invoice
    
    @State private var amount: Double?
    @State private var clientName: String
    @State private var selectedClient: Client?
    @State private var useExistingClient: Bool
    @State private var dueDate: Date
    @State private var isPaid: Bool
    @State private var selectedProject: Project?
    @State private var isSaving: Bool = false
    
    init(invoice: Invoice) {
        self.invoice = invoice
        _amount = State(initialValue: invoice.amount > 0 ? invoice.amount : nil)
        _clientName = State(initialValue: invoice.clientName)
        _selectedClient = State(initialValue: nil)
        _useExistingClient = State(initialValue: false)
        _dueDate = State(initialValue: invoice.dueDate)
        _isPaid = State(initialValue: invoice.isPaid)
        _selectedProject = State(initialValue: invoice.project)
    }
    
    private var finalClientName: String {
        if useExistingClient {
            return selectedClient?.name ?? ""
        } else {
            return clientName
        }
    }
    
    private var isValid: Bool {
        !finalClientName.trimmingCharacters(in: .whitespaces).isEmpty &&
        (amount ?? 0) > 0
    }
    
    private func clientExists(name: String) -> Bool {
        clients.contains { $0.name.lowercased() == name.lowercased() }
    }
    
    var body: some View {
        Form {
            Section(LocalizationKey.Invoice.details) {
                // Client selection
                if !clients.isEmpty {
                    Picker("Client Source", selection: $useExistingClient) {
                        Text("Enter Name").tag(false)
                        Text("Select Existing").tag(true)
                    }
                    .pickerStyle(.segmented)
                    
                    if useExistingClient {
                        Picker(LocalizationKey.Invoice.clientName, selection: $selectedClient) {
                            Text("Select a client")
                                .tag(nil as Client?)
                            
                            ForEach(clients) { client in
                                Text(client.name)
                                    .tag(client as Client?)
                            }
                        }
                        
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
                        TextField(LocalizationKey.Invoice.clientName, text: $clientName)
                        
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
                    TextField(LocalizationKey.Invoice.clientName, text: $clientName)
                }
                
                CurrencyTextField(LocalizationKey.Invoice.amount, value: $amount, currencyCode: currencyCode)
                
                DatePicker(LocalizationKey.Invoice.dueDate, selection: $dueDate, displayedComponents: .date)
                
                Toggle(LocalizationKey.Invoice.paid, isOn: $isPaid)
            }
            
            Section(LocalizationKey.Invoice.project) {
                Picker(LocalizationKey.Invoice.projectOptional, selection: $selectedProject) {
                    Text(LocalizationKey.Invoice.none).tag(nil as Project?)
                    ForEach(projects.filter { $0.isActive }) { project in
                        Text(project.name).tag(project as Project?)
                    }
                }
            }
            
            Section {
                Button(role: .destructive) {
                    deleteInvoice()
                } label: {
                    HStack {
                        Spacer()
                        Label(LocalizationKey.Action.delete, systemImage: "trash")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(LocalizationKey.Invoice.editTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizationKey.Action.save) {
                    saveChanges()
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
        .onAppear {
            // Pre-select existing client if the invoice's clientName matches one
            if let matchingClient = clients.first(where: { $0.name.lowercased() == invoice.clientName.lowercased() }) {
                selectedClient = matchingClient
                useExistingClient = true
            }
        }
    }
    
    private func saveChanges() {
        guard isValid else { return }
        isSaving = true
        
        let wasPaid = invoice.isPaid
        let invoiceClientName = finalClientName.trimmingCharacters(in: .whitespaces)
        
        // Auto-create client if entering manually and doesn't exist
        if !useExistingClient && !clientName.isEmpty && !clientExists(name: clientName) {
            let newClient = Client(name: clientName.trimmingCharacters(in: .whitespaces))
            modelContext.insert(newClient)
        }
        
        invoice.clientName = invoiceClientName
        invoice.amount = amount ?? 0
        invoice.dueDate = dueDate
        invoice.isPaid = isPaid
        invoice.project = selectedProject
        
        do {
            try modelContext.save()
            
            // Update notifications based on paid status change
            Task {
                if isPaid {
                    await NotificationService.shared.cancelNotifications(for: invoice)
                } else if wasPaid && !isPaid {
                    await NotificationService.shared.scheduleNotifications(for: invoice)
                }
            }
            
            dismiss()
        } catch {
            appState.showError("Failed to update invoice: \(error.localizedDescription)")
            isSaving = false
        }
    }
    
    private func deleteInvoice() {
        Task {
            await NotificationService.shared.cancelNotifications(for: invoice)
        }
        modelContext.delete(invoice)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to delete invoice: \(error.localizedDescription)")
        }
    }
}

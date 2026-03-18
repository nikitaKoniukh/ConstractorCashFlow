//
//  NewInvoiceView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct NewInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    @Query private var projects: [Project]
    @Query(sort: \Client.name) private var clients: [Client]
    
    @State private var amount: Double?
    @State private var clientName: String = ""
    @State private var selectedClient: Client?
    @State private var useExistingClient: Bool = false
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var isPaid: Bool = false
    @State private var selectedProject: Project?
    @State private var isSaving: Bool = false
    
    private var finalClientName: String {
        if useExistingClient {
            return selectedClient?.name ?? ""
        } else {
            return clientName
        }
    }
    
    private var isValid: Bool {
        !finalClientName.isEmpty && (amount ?? 0) > 0
    }
    
    private func clientExists(name: String) -> Bool {
        clients.contains { $0.name.lowercased() == name.lowercased() }
    }
    
    var body: some View {
        NavigationStack {
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
            }
            .navigationTitle(LocalizationKey.Invoice.newTitle)
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
                        saveInvoice()
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
    
    private func saveInvoice() {
        isSaving = true
        
        let invoiceClientName = finalClientName
        
        // Auto-create client if entering manually and doesn't exist
        if !useExistingClient && !clientName.isEmpty && !clientExists(name: clientName) {
            let newClient = Client(name: clientName)
            modelContext.insert(newClient)
        }
        
        let invoice = Invoice(
            amount: amount ?? 0,
            dueDate: dueDate,
            isPaid: isPaid,
            clientName: invoiceClientName,
            project: selectedProject
        )
        
        do {
            modelContext.insert(invoice)
            try modelContext.save()
            
            // Schedule notifications if not paid
            if !isPaid {
                Task {
                    await NotificationService.shared.scheduleNotifications(for: invoice)
                }
            }
            
            dismiss()
        } catch {
            appState.showError("Failed to save invoice: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

#Preview {
    InvoicesListView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

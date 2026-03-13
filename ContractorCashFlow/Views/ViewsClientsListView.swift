//
//  ClientsListView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI
import SwiftData

struct ClientsListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Client.name) private var clients: [Client]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(clients) { client in
                    NavigationLink(value: client) {
                        ClientRow(client: client)
                    }
                }
                .onDelete(perform: deleteClients)
            }
            .navigationTitle("Clients")
            .navigationDestination(for: Client.self) { client in
                ClientDetailView(client: client)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.isShowingNewClient = true
                    } label: {
                        Label("Add Client", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.isShowingNewClient },
                set: { appState.isShowingNewClient = $0 }
            )) {
                NewClientView()
            }
            .overlay {
                if clients.isEmpty {
                    ContentUnavailableView(
                        "No Clients",
                        systemImage: "person.2",
                        description: Text("Tap + to add your first client")
                    )
                }
            }
        }
    }
    
    private func deleteClients(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(clients[index])
            }
        }
    }
}

// MARK: - Client Row Component
struct ClientRow: View {
    let client: Client
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(client.name)
                .font(.headline)
            
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
        .padding(.vertical, 4)
    }
}

// MARK: - Placeholder Views
struct ClientDetailView: View {
    let client: Client
    
    var body: some View {
        List {
            Section("Information") {
                LabeledContent("Name", value: client.name)
                
                if let email = client.email {
                    LabeledContent("Email", value: email)
                }
                
                if let phone = client.phone {
                    LabeledContent("Phone", value: phone)
                }
                
                if let address = client.address {
                    LabeledContent("Address") {
                        Text(address)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            
            if let notes = client.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle(client.name)
    }
}

struct NewClientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""
    
    private var isValid: Bool {
        !name.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Client Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section("Address") {
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveClient()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveClient() {
        let client = Client(
            name: name,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            address: address.isEmpty ? nil : address,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(client)
        dismiss()
    }
}

#Preview {
    ClientsListView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

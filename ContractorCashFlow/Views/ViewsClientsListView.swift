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
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack(path: appState.navigationPath(for: .clients)) {
            ClientsListContent(searchText: searchText)
            .navigationTitle(LocalizationKey.ClientS.title)
            .navigationDestination(for: Client.self) { client in
                ClientDetailView(client: client)
            }
            .searchable(text: $searchText, prompt: "Search by name, email, or phone")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.isShowingNewClient = true
                    } label: {
                        Label(LocalizationKey.ClientS.add, systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.isShowingNewClient },
                set: { appState.isShowingNewClient = $0 }
            )) {
                NewClientView()
            }
            .alert("Error", isPresented: Binding(
                get: { appState.isShowingError },
                set: { appState.isShowingError = $0 }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(appState.errorMessage ?? "An error occurred")
            }
        }
    }
}

// MARK: - Clients List Content (with filtering)
private struct ClientsListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    let searchText: String
    
    init(searchText: String) {
        self.searchText = searchText
        
        // Build predicate based on search text
        let predicate: Predicate<Client>
        if searchText.isEmpty {
            predicate = #Predicate<Client> { _ in true }
        } else {
            predicate = #Predicate<Client> { client in
                client.name.localizedStandardContains(searchText) ||
                (client.email != nil && client.email!.localizedStandardContains(searchText)) ||
                (client.phone != nil && client.phone!.localizedStandardContains(searchText))
            }
        }
        
        _clients = Query(filter: predicate, sort: \Client.name)
    }
    
    @Query private var clients: [Client]
    
    var body: some View {
        List {
            ForEach(clients) { client in
                NavigationLink(value: client) {
                    ClientRow(client: client)
                }
            }
            .onDelete(perform: deleteClients)
        }
        .overlay {
            if clients.isEmpty {
                if searchText.isEmpty {
                    // Enhanced empty state with CTA button
                    ContentUnavailableView {
                        Label("No Clients", systemImage: "person.2")
                    } description: {
                        Text("Add your first client to manage contacts and projects")
                    } actions: {
                        Button {
                            appState.isShowingNewClient = true
                        } label: {
                            Text("Add Client")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
    
    private func deleteClients(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                do {
                    modelContext.delete(clients[index])
                    try modelContext.save()
                } catch {
                    appState.showError("Failed to delete client: \(error.localizedDescription)")
                }
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

// MARK: - Client Detail View
struct ClientDetailView: View {
    @Bindable var client: Client
    @State private var isEditing = false
    
    var body: some View {
        List {
            Section(String(localized: "client.information")) {
                LabeledContent(LocalizationKey.ClientS.name, value: client.name)
                
                if let email = client.email {
                    LabeledContent(LocalizationKey.ClientS.email, value: email)
                }
                
                if let phone = client.phone {
                    LabeledContent(LocalizationKey.ClientS.phone, value: phone)
                }
                
                if let address = client.address {
                    LabeledContent(LocalizationKey.ClientS.address) {
                        Text(address)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            
            if let notes = client.notes, !notes.isEmpty {
                Section(String(localized: "client.notes")) {
                    Text(notes)
                }
            }
        }
        .navigationTitle(client.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isEditing = true
                } label: {
                    Text(LocalizationKey.Action.edit)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditClientView(client: client)
        }
    }
}

// MARK: - Edit Client View
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
                Section(String(localized: "client.information")) {
                    TextField(LocalizationKey.ClientS.name, text: $name)
                    TextField(LocalizationKey.ClientS.email, text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField(LocalizationKey.ClientS.phone, text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(String(localized: "client.address")) {
                    TextField(LocalizationKey.ClientS.address, text: $address, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section(String(localized: "client.notes")) {
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
                Section(String(localized: "client.information")) {
                    TextField(LocalizationKey.ClientS.name, text: $name)
                    TextField(LocalizationKey.ClientS.email, text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField(LocalizationKey.ClientS.phone, text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(String(localized: "client.address")) {
                    TextField(LocalizationKey.ClientS.address, text: $address, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section(String(localized: "client.notes")) {
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

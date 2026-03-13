//
//  ProjectsListView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI
import SwiftData

struct ProjectsListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            ProjectsListContent(searchText: searchText)
            .navigationTitle(LocalizationKey.Project.title)
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(project: project)
            }
            .searchable(text: $searchText, prompt: "Search by name or client")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.isShowingNewProject = true
                    } label: {
                        Label(LocalizationKey.Project.add, systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.isShowingNewProject },
                set: { appState.isShowingNewProject = $0 }
            )) {
                NewProjectView()
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

// MARK: - Projects List Content (with filtering)
private struct ProjectsListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    let searchText: String
    
    init(searchText: String) {
        self.searchText = searchText
        
        // Build predicate based on search text
        let predicate: Predicate<Project>
        if searchText.isEmpty {
            predicate = #Predicate<Project> { _ in true }
        } else {
            predicate = #Predicate<Project> { project in
                project.name.localizedStandardContains(searchText) ||
                project.clientName.localizedStandardContains(searchText)
            }
        }
        
        _projects = Query(filter: predicate, sort: \Project.createdDate, order: .reverse)
    }
    
    @Query private var projects: [Project]
    
    var body: some View {
        List {
            ForEach(projects) { project in
                NavigationLink(value: project) {
                    ProjectRow(project: project)
                }
            }
            .onDelete(perform: deleteProjects)
        }
        .overlay {
            if projects.isEmpty {
                if searchText.isEmpty {
                    // Enhanced empty state with CTA button
                    ContentUnavailableView {
                        Label("No Projects", systemImage: "folder.badge.plus")
                    } description: {
                        Text("Add your first project to get started tracking expenses and invoices")
                    } actions: {
                        Button {
                            appState.isShowingNewProject = true
                        } label: {
                            Text("Add Project")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
    
    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                do {
                    modelContext.delete(projects[index])
                    try modelContext.save()
                } catch {
                    appState.showError("Failed to delete project: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Project Row Component
struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(project.name)
                    .font(.headline)
                Spacer()
                if project.isActive {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
            
            Text(project.clientName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Label("\(project.totalExpenses, format: .currency(code: "USD"))", systemImage: "arrow.down")
                    .font(.caption)
                    .foregroundStyle(.red)
                
                Spacer()
                
                Label("\(project.totalIncome, format: .currency(code: "USD"))", systemImage: "arrow.up")
                    .font(.caption)
                    .foregroundStyle(.green)
                
                Spacer()
                
                Text("\(String(localized: "project.balance.label")): \(project.balance, format: .currency(code: "USD"))")
                    .font(.caption)
                    .foregroundStyle(project.balance >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Placeholder Views
struct ProjectDetailView: View {
    let project: Project
    
    var body: some View {
        Text("\(String(localized: "project.detailTitle.label")): \(project.name)")
            .navigationTitle(project.name)
    }
}

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @Query(sort: \Client.name) private var clients: [Client]
    
    @State private var name: String = ""
    @State private var clientName: String = ""
    @State private var selectedClient: Client?
    @State private var useExistingClient: Bool = false
    @State private var budget: Double = 0
    @State private var isActive: Bool = true
    @State private var isSaving: Bool = false
    
    // New client details when entering manually
    @State private var showClientDetails: Bool = false
    @State private var newClientEmail: String = ""
    @State private var newClientPhone: String = ""
    @State private var newClientAddress: String = ""
    @State private var newClientNotes: String = ""
    
    private var isValid: Bool {
        !name.isEmpty && !finalClientName.isEmpty && budget > 0
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
                Section(String(localized: "project.information")) {
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
                
                Section(String(localized: "project.budget")) {
                    TextField(LocalizationKey.Project.budget, value: $budget, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
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
            budget: budget,
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

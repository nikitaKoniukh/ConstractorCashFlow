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
    @Query(sort: \Project.createdDate, order: .reverse) private var projects: [Project]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(projects) { project in
                    NavigationLink(value: project) {
                        ProjectRow(project: project)
                    }
                }
                .onDelete(perform: deleteProjects)
            }
            .navigationTitle("Projects")
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(project: project)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.isShowingNewProject = true
                    } label: {
                        Label("Add Project", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.isShowingNewProject },
                set: { appState.isShowingNewProject = $0 }
            )) {
                NewProjectView()
            }
            .overlay {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "No Projects",
                        systemImage: "folder.badge.plus",
                        description: Text("Tap + to create your first project")
                    )
                }
            }
        }
    }
    
    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(projects[index])
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
                
                Text("Balance: \(project.balance, format: .currency(code: "USD"))")
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
        Text("Project Detail: \(project.name)")
            .navigationTitle(project.name)
    }
}

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = ""
    @State private var clientName: String = ""
    @State private var budget: Double = 0
    @State private var isActive: Bool = true
    
    private var isValid: Bool {
        !name.isEmpty && !clientName.isEmpty && budget > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Information") {
                    TextField("Project Name", text: $name)
                    TextField("Client Name", text: $clientName)
                }
                
                Section("Budget") {
                    TextField("Budget", value: $budget, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Toggle("Active Project", isOn: $isActive)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProject()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveProject() {
        let project = Project(
            name: name,
            clientName: clientName,
            budget: budget,
            isActive: isActive
        )
        modelContext.insert(project)
        dismiss()
    }
}

#Preview {
    ProjectsListView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

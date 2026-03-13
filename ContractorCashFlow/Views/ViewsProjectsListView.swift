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
        }
    }
}

// MARK: - Projects List Content (with filtering)
private struct ProjectsListContent: View {
    @Environment(\.modelContext) private var modelContext
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
                    ContentUnavailableView(
                        LocalizationKey.Project.empty,
                        systemImage: "folder.badge.plus",
                        description: Text(LocalizationKey.Project.emptyDescription)
                    )
                } else {
                    ContentUnavailableView.search
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
                Section(String(localized: "project.information")) {
                    TextField(LocalizationKey.Project.name, text: $name)
                    TextField(LocalizationKey.Project.clientName, text: $clientName)
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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKey.Action.save) {
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

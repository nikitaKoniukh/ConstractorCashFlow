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
    @Environment(PurchaseManager.self) private var purchaseManager
    @Query private var allProjects: [Project]
    @State private var searchText: String = ""
    @State private var isShowingPaywall = false
    
    var body: some View {
        NavigationStack(path: appState.navigationPath(for: .projects)) {
            ProjectsListContent(searchText: searchText)
            .navigationTitle(LocalizationKey.Project.title)
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(project: project)
            }
            .searchable(text: $searchText, prompt: LocalizationKey.Project.searchPrompt)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if purchaseManager.canCreateProject(currentCount: allProjects.count) {
                            appState.isShowingNewProject = true
                        } else {
                            isShowingPaywall = true
                        }
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
            .alert(LocalizationKey.General.error, isPresented: Binding(
                get: { appState.isShowingError },
                set: { appState.isShowingError = $0 }
            )) {
                Button(LocalizationKey.General.ok, role: .cancel) { }
            } message: {
                if let errorMessage = appState.errorMessage {
                    Text(errorMessage)
                } else {
                    Text(LocalizationKey.General.genericError)
                }
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView(limitReachedMessage: LocalizationKey.Subscription.projectLimitReached)
            }
        }
    }
}

// MARK: - Projects List Content (with filtering)
private struct ProjectsListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(PurchaseManager.self) private var purchaseManager
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
                    ProjectRowView(project: project)
                }
            }
            .onDelete(perform: deleteProjects)
        }
        .overlay {
            if projects.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView {
                        Label(LocalizationKey.Project.empty, systemImage: "folder.badge.plus")
                    } description: {
                        Text(LocalizationKey.Project.emptyDescription)
                    } actions: {
                        Button {
                            appState.isShowingNewProject = true
                        } label: {
                            Text(LocalizationKey.Project.add)
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
                    appState.showError(String(format: LocalizationKey.General.failedToDeleteProject, error.localizedDescription))
                }
            }
        }
    }
}

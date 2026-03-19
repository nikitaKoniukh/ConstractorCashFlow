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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let searchText: String

    init(searchText: String) {
        self.searchText = searchText

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

    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        Group {
            if isIPad {
                iPadGrid
            } else {
                iPhoneList
            }
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

    // MARK: iPhone – plain list
    private var iPhoneList: some View {
        List {
            ForEach(projects) { project in
                NavigationLink(value: project) {
                    ProjectRowView(project: project)
                }
            }
            .onDelete(perform: deleteProjects)
        }
    }

    // MARK: iPad – card grid
    private var iPadGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 340, maximum: 480), spacing: 16)],
                spacing: 16
            ) {
                ForEach(projects) { project in
                    NavigationLink(value: project) {
                        ProjectCardView(project: project)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteProject(project)
                        } label: {
                            Label(LocalizationKey.General.delete, systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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

    private func deleteProject(_ project: Project) {
        do {
            modelContext.delete(project)
            try modelContext.save()
        } catch {
            appState.showError(String(format: LocalizationKey.General.failedToDeleteProject, error.localizedDescription))
        }
    }
}
// MARK: - iPad Project Card
private struct ProjectCardView: View {
    let project: Project
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header band
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .lineLimit(2)
                    Label(project.clientName, systemImage: "person")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(project.isActive ? LocalizationKey.Project.active : LocalizationKey.Project.inactive)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(project.isActive ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                    .foregroundStyle(project.isActive ? .green : .gray)
                    .clipShape(Capsule())
            }
            .padding()

            Divider()

            // Financials row
            HStack(spacing: 0) {
                financialColumn(
                    title: LocalizationKey.Analytics.income,
                    value: project.totalIncome,
                    color: .green,
                    icon: "arrow.up.circle.fill"
                )
                Divider().frame(height: 44)
                financialColumn(
                    title: LocalizationKey.Analytics.expenses,
                    value: project.totalExpenses,
                    color: .red,
                    icon: "arrow.down.circle.fill"
                )
                Divider().frame(height: 44)
                financialColumn(
                    title: LocalizationKey.Project.balance,
                    value: project.balance,
                    color: project.balance >= 0 ? .green : .red,
                    icon: "scalemass.fill"
                )
            }
            .padding(.vertical, 8)

            // Budget progress (only when budget is set)
            if project.budget > 0 {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(LocalizationKey.Project.budgetUtilizationTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.0f%%", project.budgetUtilization))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(budgetColor(for: project.budgetUtilization))
                    }
                    ProgressView(value: min(project.budgetUtilization, 100), total: 100)
                        .tint(budgetColor(for: project.budgetUtilization))
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func financialColumn(title: LocalizedStringKey, value: Double, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(value, format: .currency(code: currencyCode))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func budgetColor(for utilization: Double) -> Color {
        if utilization < 50 { return .green }
        if utilization < 80 { return .orange }
        return .red
    }
}


//
//  LaborListView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 14/03/2026.
//

import SwiftUI
import SwiftData

struct LaborListView: View {
    @Environment(AppState.self) private var appState
    
    @State private var searchText: String = ""
    @State private var selectedType: LaborType?
    @State private var selectedProject: Project?
    @State private var currentMonthOnly: Bool = false
    @State private var isShowingFilters = false
    @State private var sortOrder: SortOrder = .recentlyAdded
    
    enum SortOrder: CaseIterable {
        case recentlyAdded
        case workerName
        case totalEarnedHigh
        case totalEarnedLow
        
        var titleKey: LocalizedStringKey {
            switch self {
            case .recentlyAdded:
                return LocalizationKey.Labor.sortRecentlyAdded
            case .workerName:
                return LocalizationKey.Labor.sortWorkerName
            case .totalEarnedHigh:
                return LocalizationKey.Labor.sortAmountHighToLow
            case .totalEarnedLow:
                return LocalizationKey.Labor.sortAmountLowToHigh
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: appState.navigationPath(for: .labor)) {
            LaborListContent(
                searchText: searchText,
                selectedType: selectedType,
                selectedProject: selectedProject,
                currentMonthOnly: currentMonthOnly,
                sortOrder: sortOrder
            )
            .navigationTitle(LocalizationKey.Labor.title)
            .searchable(text: $searchText, prompt: LocalizationKey.Labor.searchPrompt)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingFilters.toggle()
                    } label: {
                        Label(LocalizationKey.Labor.filtersButton, systemImage: (selectedType != nil || selectedProject != nil || currentMonthOnly) ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker(LocalizationKey.Labor.sortBy, selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.titleKey).tag(order)
                            }
                        }
                    } label: {
                        Label(LocalizationKey.Labor.sortButton, systemImage: "arrow.up.arrow.down")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.isShowingNewLabor = true
                    } label: {
                        Label(LocalizationKey.Labor.add, systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.isShowingNewLabor },
                set: { appState.isShowingNewLabor = $0 }
            )) {
                AddLaborView()
            }
            .sheet(isPresented: $isShowingFilters) {
                LaborFiltersView(
                    selectedType: $selectedType,
                    selectedProject: $selectedProject,
                    currentMonthOnly: $currentMonthOnly
                )
            }
            .alert(LocalizationKey.General.error, isPresented: Binding(
                get: { appState.isShowingError },
                set: { appState.isShowingError = $0 }
            )) {
                Button(LocalizationKey.General.ok, role: .cancel) { }
            } message: {
                Text(appState.errorMessage ?? String(localized: "general.genericError"))
            }
        }
    }
}

// MARK: - Labor List Content
private struct LaborListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allWorkers: [LaborDetails]
    
    let searchText: String
    let selectedType: LaborType?
    let selectedProject: Project?
    let currentMonthOnly: Bool
    let sortOrder: LaborListView.SortOrder
    
    @State private var selectedWorker: LaborDetails?
    
    var filteredAndSortedWorkers: [LaborDetails] {
        var result = allWorkers
        
        if !searchText.isEmpty {
            result = result.filter { worker in
                worker.workerName.localizedStandardContains(searchText) ||
                (worker.notes?.localizedStandardContains(searchText) ?? false)
            }
        }
        
        if let type = selectedType {
            result = result.filter { $0.laborType == type }
        }
        
        if let project = selectedProject {
            result = result.filter { worker in
                worker.associatedProjects.contains { $0.id == project.id }
            }
        }
        
        if currentMonthOnly {
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            result = result.filter { worker in
                worker.expenses.contains { $0.date >= startOfMonth && $0.date < endOfMonth }
            }
        }
        
        switch sortOrder {
        case .recentlyAdded:
            result.sort { $0.createdDate > $1.createdDate }
        case .workerName:
            result.sort { $0.workerName.localizedCaseInsensitiveCompare($1.workerName) == .orderedAscending }
        case .totalEarnedHigh:
            result.sort { $0.totalAmountEarned > $1.totalAmountEarned }
        case .totalEarnedLow:
            result.sort { $0.totalAmountEarned < $1.totalAmountEarned }
        }
        
        return result
    }
    
    var body: some View {
        Group {
            if filteredAndSortedWorkers.isEmpty {
                ContentUnavailableView {
                    Label(LocalizationKey.Labor.noLabor, systemImage: "person.2.slash")
                } description: {
                    if searchText.isEmpty {
                        Text(LocalizationKey.Labor.noLaborDescription)
                    } else {
                        Text(LocalizationKey.Labor.noResults)
                    }
                }
            } else {
                List {
                    Section {
                        WorkerSummaryCard(workers: filteredAndSortedWorkers)
                    }
                    
                    Section {
                        ForEach(filteredAndSortedWorkers) { worker in
                            WorkerCardRow(worker: worker)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedWorker = worker
                                }
                        }
                        .onDelete(perform: deleteWorker)
                    }
                }
            }
        }
        .sheet(item: $selectedWorker) { worker in
            EditLaborView(labor: worker)
        }
    }
    
    private func deleteWorker(at offsets: IndexSet) {
        for index in offsets {
            let worker = filteredAndSortedWorkers[index]
            modelContext.delete(worker)
        }
        
        try? modelContext.save()
    }
}

// MARK: - Worker Card Row
private struct WorkerCardRow: View {
    let worker: LaborDetails
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name and type
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(worker.workerName)
                        .font(.headline)
                    
                    Text(worker.laborType.localizedDisplayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(worker.totalAmountEarned.formatted(.currency(code: currencyCode)))
                        .font(.headline)
                        .foregroundStyle(worker.totalAmountEarned > 0 ? .primary : .secondary)
                    
                    if let rate = worker.rate {
                        Text(rate.formatted(.currency(code: currencyCode)) + worker.laborType.rateSuffix)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Stats row
            if worker.totalDaysWorked > 0 || worker.totalUnitsWorked > 0 {
                HStack(spacing: 12) {
                    if worker.totalDaysWorked > 0 {
                        Label {
                            Text("\(worker.totalDaysWorked) \(worker.totalDaysWorked == 1 ? String(localized: "labor.dayUnit") : String(localized: "labor.daysUnit"))")
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    if worker.laborType.usesQuantity && worker.totalUnitsWorked > 0 {
                        Label {
                            Text(String(format: "%.1f %@", worker.totalUnitsWorked, worker.laborType.unitName))
                        } icon: {
                            Image(systemName: "clock")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Associated projects
            if !worker.associatedProjects.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(worker.associatedProjects.map(\.name).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
            }
            
            // Notes
            if let notes = worker.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Worker Summary Card
private struct WorkerSummaryCard: View {
    let workers: [LaborDetails]
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
    var totalEarned: Double {
        workers.reduce(0) { $0 + $1.totalAmountEarned }
    }
    
    var totalHours: Double {
        workers.reduce(0) { $0 + $1.totalUnitsWorked }
    }
    
    var activeProjectCount: Int {
        let allProjects = workers.flatMap { $0.associatedProjects }
        var seen = Set<UUID>()
        return allProjects.filter { seen.insert($0.id).inserted }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatCard(
                    title: LocalizationKey.Labor.totalEarned,
                    value: totalEarned.formatted(.currency(code: currencyCode)),
                    systemImage: "dollarsign.circle.fill",
                    color: .blue
                )
                
                StatCard(
                    title: LocalizationKey.Labor.totalHours,
                    value: String(format: "%.1f", totalHours),
                    systemImage: "clock.fill",
                    color: .orange
                )
            }
            
            HStack {
                StatCard(
                    title: LocalizationKey.Labor.totalWorkers,
                    value: "\(workers.count)",
                    systemImage: "person.2.fill",
                    color: .purple
                )
                
                StatCard(
                    title: LocalizationKey.Labor.activeProjects,
                    value: "\(activeProjectCount)",
                    systemImage: "folder.fill",
                    color: .green
                )
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Stat Card
private struct StatCard: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

// MARK: - Labor Filters View
struct LaborFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.name) private var projects: [Project]
    
    @Binding var selectedType: LaborType?
    @Binding var selectedProject: Project?
    @Binding var currentMonthOnly: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizationKey.Labor.laborType)) {
                    Picker(LocalizationKey.Labor.typeLabel, selection: $selectedType) {
                        Text(LocalizationKey.Labor.allTypes).tag(nil as LaborType?)
                        ForEach(LaborType.allCases, id: \.self) { type in
                            Text(type.localizedDisplayName).tag(type as LaborType?)
                        }
                    }
                }
                
                Section(header: Text(LocalizationKey.Labor.filterByProject)) {
                    Picker(LocalizationKey.Labor.projectLabel, selection: $selectedProject) {
                        Text(LocalizationKey.Labor.allProjects).tag(nil as Project?)
                        ForEach(projects) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }
                }
                
                Section(header: Text(LocalizationKey.Labor.filterByDate)) {
                    Toggle(LocalizationKey.Labor.currentMonthOnly, isOn: $currentMonthOnly)
                }
                
                Section {
                    Button(LocalizationKey.Labor.clearFilters) {
                        selectedType = nil
                        selectedProject = nil
                        currentMonthOnly = false
                        dismiss()
                    }
                }
            }
            .navigationTitle(LocalizationKey.Labor.filters)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKey.General.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LaborListView()
        .environment(AppState())
        .modelContainer(for: [LaborDetails.self, Project.self, Expense.self], inMemory: true)
}

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
    @State private var showCompletedOnly: Bool = false
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var isShowingFilters = false
    @State private var sortOrder: SortOrder = .dateDescending
    
    enum SortOrder: CaseIterable {
        case dateDescending
        case dateAscending
        case amountDescending
        case amountAscending
        case workerName
        
        var titleKey: LocalizedStringKey {
            switch self {
            case .dateDescending:
                return LocalizationKey.Labor.sortDateNewest
            case .dateAscending:
                return LocalizationKey.Labor.sortDateOldest
            case .amountDescending:
                return LocalizationKey.Labor.sortAmountHighToLow
            case .amountAscending:
                return LocalizationKey.Labor.sortAmountLowToHigh
            case .workerName:
                return LocalizationKey.Labor.sortWorkerName
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            LaborListContent(
                searchText: searchText,
                selectedType: selectedType,
                selectedProject: selectedProject,
                showCompletedOnly: showCompletedOnly,
                startDate: startDate,
                endDate: endDate,
                sortOrder: sortOrder
            )
            .navigationTitle(LocalizationKey.Labor.title)
            .searchable(text: $searchText, prompt: LocalizationKey.Labor.searchPrompt)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingFilters.toggle()
                    } label: {
                        Label(LocalizationKey.Labor.filtersButton, systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
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
                    showCompletedOnly: $showCompletedOnly,
                    startDate: $startDate,
                    endDate: $endDate
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
    
    private var hasActiveFilters: Bool {
        selectedType != nil || selectedProject != nil || showCompletedOnly || startDate != nil || endDate != nil
    }
}

// MARK: - Labor List Content
private struct LaborListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLabor: [LaborDetails]
    
    let searchText: String
    let selectedType: LaborType?
    let selectedProject: Project?
    let showCompletedOnly: Bool
    let startDate: Date?
    let endDate: Date?
    let sortOrder: LaborListView.SortOrder
    
    @State private var selectedLabor: LaborDetails?
    
    private var calendar: Calendar { .current }
    
    var filteredAndSortedLabor: [LaborDetails] {
        var result = allLabor
        
        if !searchText.isEmpty {
            result = result.filter { labor in
                labor.workerName.localizedStandardContains(searchText) ||
                (labor.notes?.localizedStandardContains(searchText) ?? false)
            }
        }
        
        if let type = selectedType {
            result = result.filter { $0.laborType == type }
        }
        
        if let project = selectedProject {
            result = result.filter { $0.project?.id == project.id }
        }
        
        if showCompletedOnly {
            result = result.filter { $0.isCompleted }
        }
        
        if let start = startDate {
            let startOfDay = calendar.startOfDay(for: start)
            result = result.filter { $0.workDate >= startOfDay }
        }
        
        if let end = endDate,
           let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: end)) {
            result = result.filter { $0.workDate <= endOfDay }
        }
        
        switch sortOrder {
        case .dateDescending:
            result.sort { $0.workDate > $1.workDate }
        case .dateAscending:
            result.sort { $0.workDate < $1.workDate }
        case .amountDescending:
            result.sort { $0.totalAmount > $1.totalAmount }
        case .amountAscending:
            result.sort { $0.totalAmount < $1.totalAmount }
        case .workerName:
            result.sort { $0.workerName.localizedCaseInsensitiveCompare($1.workerName) == .orderedAscending }
        }
        
        return result
    }
    
    var body: some View {
        Group {
            if filteredAndSortedLabor.isEmpty {
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
                        LaborSummaryCard(labor: filteredAndSortedLabor)
                    }
                    
                    Section {
                        ForEach(filteredAndSortedLabor) { labor in
                            LaborRowView(labor: labor)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedLabor = labor
                                }
                        }
                        .onDelete(perform: deleteLabor)
                    }
                }
            }
        }
        .sheet(item: $selectedLabor) { labor in
            EditLaborView(labor: labor)
        }
    }
    
    private func deleteLabor(at offsets: IndexSet) {
        for index in offsets {
            let labor = filteredAndSortedLabor[index]
            modelContext.delete(labor)
        }
        
        try? modelContext.save()
    }
}

// MARK: - Labor Row View
private struct LaborRowView: View {
    let labor: LaborDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(labor.workerName)
                        .font(.headline)
                    
                    Text(labor.laborType.localizedDisplayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(labor.totalAmount.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(labor.workDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if labor.laborType == .hourly, let hours = labor.hoursWorked, let rate = labor.hourlyRate {
                HStack {
                    Label {
                        Text(String(format: "%.1f %@", hours, String(localized: "labor.hourUnitShort")))
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(rate.formatted(.currency(code: "USD")) + String(localized: "labor.hourlyRateSuffix"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let project = labor.project {
                HStack {
                    Image(systemName: "folder")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(project.name)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            
            HStack {
                if labor.isCompleted {
                    Label(LocalizationKey.Labor.completed, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                
                if labor.expense != nil {
                    Label(LocalizationKey.Labor.expenseLinked, systemImage: "link")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            if let notes = labor.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Labor Summary Card
private struct LaborSummaryCard: View {
    let labor: [LaborDetails]
    
    var totalAmount: Double {
        labor.reduce(0) { $0 + $1.totalAmount }
    }
    
    var totalHours: Double {
        labor.compactMap { $0.hoursWorked }.reduce(0, +)
    }
    
    var completedCount: Int {
        labor.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatCard(
                    title: LocalizationKey.Labor.totalCost,
                    value: totalAmount.formatted(.currency(code: "USD")),
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
                    title: LocalizationKey.Labor.totalEntries,
                    value: "\(labor.count)",
                    systemImage: "person.2.fill",
                    color: .purple
                )
                
                StatCard(
                    title: LocalizationKey.Labor.completedJobs,
                    value: "\(completedCount)",
                    systemImage: "checkmark.circle.fill",
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
    @Query private var projects: [Project]
    
    @Binding var selectedType: LaborType?
    @Binding var selectedProject: Project?
    @Binding var showCompletedOnly: Bool
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    
    @State private var useStartDate = false
    @State private var useEndDate = false
    
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
                
                Section(header: Text(LocalizationKey.Labor.project)) {
                    Picker(LocalizationKey.Labor.selectProject, selection: $selectedProject) {
                        Text(LocalizationKey.Labor.allProjects).tag(nil as Project?)
                        ForEach(projects.filter(\.isActive), id: \.id) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }
                }
                
                Section(header: Text(LocalizationKey.Labor.status)) {
                    Toggle(LocalizationKey.Labor.showCompletedOnly, isOn: $showCompletedOnly)
                }
                
                Section(header: Text(LocalizationKey.Labor.dateRange)) {
                    Toggle(LocalizationKey.Labor.useStartDate, isOn: $useStartDate)
                    if useStartDate {
                        DatePicker(
                            LocalizationKey.Labor.startDate,
                            selection: Binding(
                                get: { startDate ?? Date() },
                                set: { startDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                    
                    Toggle(LocalizationKey.Labor.useEndDate, isOn: $useEndDate)
                    if useEndDate {
                        DatePicker(
                            LocalizationKey.Labor.endDate,
                            selection: Binding(
                                get: { endDate ?? Date() },
                                set: { endDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                }
                
                Section {
                    Button(LocalizationKey.Labor.clearFilters) {
                        clearFilters()
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
            .onAppear {
                useStartDate = startDate != nil
                useEndDate = endDate != nil
            }
            .onChange(of: useStartDate) {
                if !useStartDate {
                    startDate = nil
                }
            }
            .onChange(of: useEndDate) {
                if !useEndDate {
                    endDate = nil
                }
            }
        }
    }
    
    private func clearFilters() {
        selectedType = nil
        selectedProject = nil
        showCompletedOnly = false
        startDate = nil
        endDate = nil
        useStartDate = false
        useEndDate = false
    }
}

#Preview {
    LaborListView()
        .environment(AppState())
        .modelContainer(for: [LaborDetails.self, Project.self, Expense.self], inMemory: true)
}

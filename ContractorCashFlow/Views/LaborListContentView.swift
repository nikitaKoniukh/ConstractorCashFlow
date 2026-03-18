//
//  LaborListContentView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//


import SwiftUI
import SwiftData

struct LaborListContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allWorkers: [LaborDetails]
    
    let searchText: String
    let selectedType: LaborType?
    let selectedProject: Project?
    let selectedMonth: Date?
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
        
        if let month = selectedMonth {
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            result = result.filter { worker in
                worker.safeExpenses.contains { $0.date >= startOfMonth && $0.date < endOfMonth }
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
                        LaborSummaryCard(workers: filteredAndSortedWorkers, selectedMonth: selectedMonth)
                    }
                    
                    Section {
                        ForEach(filteredAndSortedWorkers) { worker in
                            LaborCardRow(worker: worker)
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

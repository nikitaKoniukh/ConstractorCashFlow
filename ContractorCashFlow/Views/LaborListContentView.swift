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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var allWorkers: [LaborDetails]

    let searchText: String
    let selectedType: LaborType?
    let selectedProject: Project?
    let selectedMonth: Date?
    let sortOrder: LaborListView.SortOrder

    @State private var selectedWorker: LaborDetails?

    private var isIPad: Bool { horizontalSizeClass == .regular }

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
            } else if isIPad {
                iPadGrid
            } else {
                iPhoneList
            }
        }
        .sheet(item: $selectedWorker) { worker in
            EditLaborView(labor: worker)
        }
    }

    // MARK: iPhone – plain list
    private var iPhoneList: some View {
        List {
            Section {
                LaborSummaryCard(workers: filteredAndSortedWorkers, selectedMonth: selectedMonth)
            }

            Section {
                ForEach(filteredAndSortedWorkers) { worker in
                    LaborCardRow(worker: worker, selectedMonth: selectedMonth)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedWorker = worker
                        }
                }
                .onDelete(perform: deleteWorker)
            }
        }
    }

    // MARK: iPad – summary bar + card grid
    private var iPadGrid: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary card spans full width
                LaborSummaryCard(workers: filteredAndSortedWorkers, selectedMonth: selectedMonth)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                // Worker cards in adaptive grid
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 340, maximum: 480), spacing: 16)],
                    spacing: 16
                ) {
                    ForEach(filteredAndSortedWorkers) { worker in
                        LaborWorkerCardView(worker: worker, selectedMonth: selectedMonth)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedWorker = worker
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteWorker(worker)
                                } label: {
                                    Label(LocalizationKey.General.delete, systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func deleteWorker(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredAndSortedWorkers[index])
        }
        try? modelContext.save()
    }

    private func deleteWorker(_ worker: LaborDetails) {
        modelContext.delete(worker)
        try? modelContext.save()
    }
}
// MARK: - iPad Worker Card
private struct LaborWorkerCardView: View {
    let worker: LaborDetails
    var selectedMonth: Date? = nil
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode

    private var relevantExpenses: [Expense] {
        guard let month = selectedMonth else { return worker.safeExpenses }
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        return worker.safeExpenses.filter { $0.date >= startOfMonth && $0.date < endOfMonth }
    }

    private func effectiveType(for expense: Expense) -> LaborType {
        expense.laborTypeSnapshot ?? worker.laborType
    }

    private var totalHoursWorked: Double {
        relevantExpenses.filter { effectiveType(for: $0) == .hourly }.compactMap { $0.unitsWorked }.reduce(0, +)
    }

    private var totalDaysWorked: Double {
        relevantExpenses.filter { effectiveType(for: $0) == .daily }.compactMap { $0.unitsWorked }.reduce(0, +)
    }

    private var totalAmountEarned: Double {
        relevantExpenses.reduce(0) { $0 + $1.amount }
    }

    private var relevantProjects: [Project] {
        let projects = relevantExpenses.compactMap { $0.project }
        var seen = Set<UUID>()
        return projects.filter { seen.insert($0.id).inserted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
                    .frame(width: 40, height: 40)
                    .background(Color.purple.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(worker.workerName)
                        .font(.headline)
                        .lineLimit(1)
                    if let rate = worker.rate {
                        Text(rate.formatted(.currency(code: currencyCode)) + worker.laborType.rateSuffix)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(worker.laborType.localizedDisplayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.12))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }
            .padding()

            Divider()

            // Stats row
            HStack(spacing: 0) {
                if totalHoursWorked > 0 {
                    statColumn(
                        value: "\(Int(totalHoursWorked))",
                        label: LaborType.hourly.unitName,
                        icon: "clock.fill",
                        color: .teal
                    )
                    if totalDaysWorked > 0 { Divider().frame(height: 44) }
                }
                if totalDaysWorked > 0 {
                    statColumn(
                        value: "\(Int(totalDaysWorked))",
                        label: LaborType.daily.unitName,
                        icon: "calendar",
                        color: .orange
                    )
                }
                if totalHoursWorked > 0 || totalDaysWorked > 0 {
                    Divider().frame(height: 44)
                }
                statColumn(
                    value: totalAmountEarned.formatted(.currency(code: currencyCode)),
                    label: "Total",
                    icon: "dollarsign.circle.fill",
                    color: .blue
                )
            }
            .padding(.vertical, 8)

            // Projects footer (if any)
            if !relevantProjects.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    let expensesByProject = Dictionary(
                        grouping: relevantExpenses.filter { $0.project != nil },
                        by: { $0.project!.id }
                    )
                    ForEach(relevantProjects, id: \.id) { project in
                        let cost = expensesByProject[project.id]?.reduce(0) { $0 + $1.amount } ?? 0
                        HStack {
                            Label(project.name, systemImage: "folder")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer()
                            Text(cost, format: .currency(code: currencyCode))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func statColumn(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}


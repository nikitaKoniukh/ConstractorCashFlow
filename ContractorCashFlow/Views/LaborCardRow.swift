//
//  LaborCardRow.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI

struct LaborCardRow: View {
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
    
    // Helper: effective labor type for an expense (snapshot or fallback to worker's current type)
    private func effectiveType(for expense: Expense) -> LaborType {
        expense.laborTypeSnapshot ?? worker.laborType
    }
    
    private var totalHoursWorked: Double {
        relevantExpenses
            .filter { effectiveType(for: $0) == .hourly }
            .compactMap { $0.unitsWorked }
            .reduce(0, +)
    }
    
    private var totalDaysWorked: Double {
        relevantExpenses
            .filter { effectiveType(for: $0) == .daily }
            .compactMap { $0.unitsWorked }
            .reduce(0, +)
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
        VStack(alignment: .leading, spacing: 8) {
            // Name and labor type badge (current type)
            HStack(alignment: .center) {
                Text(worker.workerName)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text(worker.laborType.localizedDisplayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.purple.opacity(0.15))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }
            
            // Rate info
            if let rate = worker.rate {
                Label(rate.formatted(.currency(code: currencyCode)) + worker.laborType.rateSuffix, systemImage: "banknote")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            
            // Stats rows — separate line per type
            if totalHoursWorked > 0 {
                HStack(spacing: 16) {
                    Label {
                        Text("\(Int(totalHoursWorked)) \(LaborType.hourly.unitName)")
                            .fontWeight(.medium)
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.teal)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            
            if totalDaysWorked > 0 {
                HStack(spacing: 16) {
                    Label {
                        Text("\(Int(totalDaysWorked)) \(LaborType.daily.unitName)")
                            .fontWeight(.medium)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(.orange)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            
            // Cost per project
            if !relevantProjects.isEmpty {
                let expensesByProject = Dictionary(grouping: relevantExpenses.filter { $0.project != nil }, by: { $0.project!.id })
                ForEach(relevantProjects, id: \.id) { project in
                    let projectCost = expensesByProject[project.id]?.reduce(0) { $0 + $1.amount } ?? 0
                    HStack {
                        Label(project.name, systemImage: "folder")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Text(projectCost, format: .currency(code: currencyCode))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            Divider()
            
            // Total
            HStack {
                Text(LocalizationKey.Labor.totalAmount)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(totalAmountEarned, format: .currency(code: currencyCode))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(totalAmountEarned > 0 ? .primary : .secondary)
            }
            
        }
        .padding(.vertical, 4)
    }
}

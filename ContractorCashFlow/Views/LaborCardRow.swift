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
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Header — avatar + name + type badge
            HStack(spacing: 12) {
                // Avatar circle with initials
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Text(worker.workerName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundStyle(.purple)
                }

                VStack(alignment: .leading, spacing: 2) {
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
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.12))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 12)

            // MARK: Stats pills row
            if totalHoursWorked > 0 || totalDaysWorked > 0 {
                HStack(spacing: 8) {
                    if totalHoursWorked > 0 {
                        statPill(
                            value: "\(Int(totalHoursWorked))",
                            label: LaborType.hourly.unitName,
                            icon: "clock.fill",
                            color: .teal
                        )
                    }
                    if totalDaysWorked > 0 {
                        statPill(
                            value: "\(Int(totalDaysWorked))",
                            label: LaborType.daily.unitName,
                            icon: "calendar",
                            color: .orange
                        )
                    }
                }
                .padding(.bottom, 10)
            }

            // MARK: Projects breakdown
            if !relevantProjects.isEmpty {
                let expensesByProject = Dictionary(
                    grouping: relevantExpenses.filter { $0.project != nil },
                    by: { $0.project!.id }
                )
                VStack(spacing: 6) {
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
                .padding(.bottom, 10)
            }

            // MARK: Total footer
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
            .padding(.top, 10)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color(.separator).opacity(0.5))
                    .frame(height: 1)
            }
        }
        .padding(.vertical, 4)
    }

    private func statPill(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

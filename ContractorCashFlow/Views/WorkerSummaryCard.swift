//
//  WorkerSummaryCard.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//
//

import SwiftUI

struct WorkerSummaryCard: View {
    let workers: [LaborDetails]
    let selectedMonth: Date?
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    
    private var relevantExpenses: [Expense] {
        let allExpenses = workers.flatMap { $0.safeExpenses }
        guard let month = selectedMonth else { return allExpenses }
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        return allExpenses.filter { $0.date >= startOfMonth && $0.date < endOfMonth }
    }
    
    private var totalLaborCost: Double {
        relevantExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var totalDaysWorked: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(relevantExpenses.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }
    
    private var totalHoursWorked: Double {
        relevantExpenses.compactMap { $0.unitsWorked }.reduce(0, +)
    }
    
    private var averageDailyCost: Double {
        totalDaysWorked > 0 ? totalLaborCost / Double(totalDaysWorked) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if let month = selectedMonth {
                    Text(month.formatted(.dateTime.month(.wide).year()))
                } else {
                    Text(LocalizationKey.Labor.summaryAllTime)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            HStack {
                StatCardView(
                    title: LocalizationKey.Labor.totalLaborCost,
                    value: totalLaborCost.formatted(.currency(code: currencyCode)),
                    systemImage: "dollarsign.circle.fill",
                    color: .blue
                )
                
                StatCardView(
                    title: LocalizationKey.Labor.totalWorkers,
                    value: "\(workers.count)",
                    systemImage: "person.2.fill",
                    color: .purple
                )
            }
            
            HStack {
                StatCardView(
                    title: LocalizationKey.Labor.totalDaysWorked,
                    value: "\(totalDaysWorked)",
                    systemImage: "calendar",
                    color: .orange
                )
                
                StatCardView(
                    title: LocalizationKey.Labor.avgDailyCost,
                    value: averageDailyCost.formatted(.currency(code: currencyCode)),
                    systemImage: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }
            
            if totalHoursWorked > 0 {
                HStack {
                    StatCardView(
                        title: LocalizationKey.Labor.totalHours,
                        value: String(format: "%.1f", totalHoursWorked),
                        systemImage: "clock.fill",
                        color: .teal
                    )
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }
}

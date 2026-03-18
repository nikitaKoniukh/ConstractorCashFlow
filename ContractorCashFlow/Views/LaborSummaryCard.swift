//
//  LaborSummaryCard.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//
//

import SwiftUI

struct LaborSummaryCard: View {
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
    
    private var totalHoursWorked: Double {
        relevantExpenses
            .filter { $0.worker?.laborType == .hourly }
            .compactMap { $0.unitsWorked }
            .reduce(0, +)
    }
    
    private var totalDaysWorked: Double {
        relevantExpenses
            .filter { $0.worker?.laborType == .daily }
            .compactMap { $0.unitsWorked }
            .reduce(0, +)
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
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            
            HStack(spacing: 10) {
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
            
            if totalDaysWorked > 0 || totalHoursWorked > 0 {
                HStack(spacing: 10) {
                    if totalDaysWorked > 0 {
                        StatCardView(
                            title: LocalizationKey.Labor.totalDaysLabel,
                            value: "\(Int(totalDaysWorked))",
                            systemImage: "calendar",
                            color: .orange
                        )
                    }
                    
                    if totalHoursWorked > 0 {
                        StatCardView(
                            title: LocalizationKey.Labor.totalHours,
                            value: "\(Int(totalHoursWorked))",
                            systemImage: "clock.fill",
                            color: .teal
                        )
                    }
                    
                    // Fill remaining space if only one card is shown
                    if (totalDaysWorked > 0) != (totalHoursWorked > 0) {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

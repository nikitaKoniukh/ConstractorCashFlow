//
//  LaborCardRow.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI

struct LaborCardRow: View {
    let worker: LaborDetails
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name and labor type badge
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
            
            // Stats row
            if worker.laborType.usesQuantity && worker.totalUnitsWorked > 0 {
                HStack(spacing: 16) {
                    Label {
                        Text("\(Int(worker.totalUnitsWorked)) \(worker.laborType.unitName)")
                            .fontWeight(.medium)
                    } icon: {
                        Image(systemName: worker.laborType == .hourly ? "clock.fill" : "calendar")
                            .foregroundStyle(worker.laborType == .hourly ? .teal : .orange)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
            
            // Cost per project
            if !worker.associatedProjects.isEmpty {
                let expensesByProject = Dictionary(grouping: worker.safeExpenses.filter { $0.project != nil }, by: { $0.project!.id })
                ForEach(worker.associatedProjects, id: \.id) { project in
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
                Text(worker.totalAmountEarned, format: .currency(code: currencyCode))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(worker.totalAmountEarned > 0 ? .primary : .secondary)
            }
            
        }
        .padding(.vertical, 4)
    }
}

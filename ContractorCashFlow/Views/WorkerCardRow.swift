//
//  WorkerCardRow.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI

struct WorkerCardRow: View {
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
                    .foregroundStyle(.secondary)
            }
            
            // Stats row
            if worker.totalDaysWorked > 0 || worker.totalUnitsWorked > 0 {
                HStack(spacing: 16) {
                    if worker.totalDaysWorked > 0 {
                        Label {
                            Text("\(worker.totalDaysWorked) ") + Text(worker.totalDaysWorked == 1 ? LocalizationKey.Labor.dayUnit : LocalizationKey.Labor.daysUnit)
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.orange)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    if worker.laborType.usesQuantity && worker.totalUnitsWorked > 0 {
                        Label {
                            Text(String(format: "%.1f %@", worker.totalUnitsWorked, worker.laborType.unitName))
                        } icon: {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.teal)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Associated projects
            if !worker.associatedProjects.isEmpty {
                Label(worker.associatedProjects.map(\.name).joined(separator: ", "), systemImage: "folder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Total earned and notes
            HStack {
                if let notes = worker.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(worker.totalAmountEarned, format: .currency(code: currencyCode))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(worker.totalAmountEarned > 0 ? .primary : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

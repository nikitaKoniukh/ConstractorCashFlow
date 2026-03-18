//
//  ProjectRowView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI

struct ProjectRowView: View {
    let project: Project
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Project name and status
            HStack(alignment: .center) {
                Text(project.name)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text(project.isActive ? LocalizationKey.Project.active : LocalizationKey.Project.inactive)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(project.isActive ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                    .foregroundStyle(project.isActive ? .green : .gray)
                    .clipShape(Capsule())
            }
            
            // Client name
            Label(project.clientName, systemImage: "person")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            // Financials row
            HStack(spacing: 16) {
                Label {
                    Text(project.totalExpenses, format: .currency(code: currencyCode))
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.red)
                }
                .font(.caption)
                
                Label {
                    Text(project.totalIncome, format: .currency(code: currencyCode))
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.green)
                }
                .font(.caption)
                
                Spacer()
            }
            .foregroundStyle(.secondary)
            
            // Balance
            HStack(spacing: 16) {
                Text(LocalizationKey.Project.balance)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(project.balance, format: .currency(code: currencyCode))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(project.balance >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

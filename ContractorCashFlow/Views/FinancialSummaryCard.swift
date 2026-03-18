//
//  FinancialSummaryCard.swift
//  FinancialSummaryCard
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct FinancialSummaryCard: View {
    let project: Project
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    
    var body: some View {
        VStack(spacing: 16) {
            // Balance
            VStack(spacing: 4) {
                Text(LocalizationKey.Project.netBalance)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(project.balance, format: .currency(code: currencyCode))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(project.balance >= 0 ? .green : .red)
            }
            
            Divider()
            
            // Income and Expenses
            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    Label {
                        Text(LocalizationKey.Analytics.income)
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Text(project.totalIncome, format: .currency(code: currencyCode))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 8) {
                    Label {
                        Text(LocalizationKey.Analytics.expenses)
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.red)
                    }
                    Text(project.totalExpenses, format: .currency(code: currencyCode))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Profit Margin (if has income)
            if project.totalIncome > 0 {
                Divider()
                
                HStack {
                    Text(LocalizationKey.Project.profitMargin)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(project.profitMargin, format: .number.precision(.fractionLength(1)))
                        .font(.headline)
                        + Text("%")
                        .font(.headline)
                }
                .foregroundStyle(project.profitMargin >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 8)
    }
}

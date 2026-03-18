//
//  ExpenseRowView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//


import SwiftUI
import SwiftData

struct ExpenseRowView: View {
    let expense: Expense
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: expense.category.iconName)
                .font(.title3)
                .foregroundStyle(expense.category.chartColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.descriptionText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    Text(expense.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expense.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(expense.amount, format: .currency(code: currencyCode))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
        }
        .padding(.vertical, 2)
    }
}

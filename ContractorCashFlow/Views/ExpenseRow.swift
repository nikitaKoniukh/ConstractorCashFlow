//
//  ExpenseRow.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI

struct ExpenseRow: View {
    let expense: Expense
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    
    private var displayDescription: String {
        expense.descriptionText.hasPrefix("Labor: ")
            ? String(expense.descriptionText.dropFirst(7))
            : expense.descriptionText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Description and category badge
            HStack(alignment: .center) {
                Text(displayDescription)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text(expense.category.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            
            // Project name
            if let project = expense.project {
                Label(project.name, systemImage: "folder")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Date and amount
            HStack {
                Label {
                    Text(expense.date, format: .dateTime.month().day().year())
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(expense.amount, format: .currency(code: currencyCode))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

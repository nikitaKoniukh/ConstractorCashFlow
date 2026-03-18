//
//  ExpenseCategoryChart.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct ExpenseCategoryChart: View {
    let expenses: [Expense]
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    
    private var categoryData: [(category: ExpenseCategory, amount: Double)] {
        let grouped = Dictionary(grouping: expenses) { $0.category }
        return ExpenseCategory.allCases.compactMap { category in
            let amount = grouped[category]?.reduce(0) { $0 + $1.amount } ?? 0
            return amount > 0 ? (category, amount) : nil
        }
        .sorted { $0.amount > $1.amount }
    }
    
    private var total: Double {
        categoryData.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(categoryData, id: \.category) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: item.category.iconName)
                            .foregroundStyle(item.category.chartColor)
                            .frame(width: 20)
                        
                        Text(item.category.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(item.amount, format: .currency(code: currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("(\(Int((item.amount / total) * 100))%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.category.chartColor.opacity(0.3))
                            .frame(width: geometry.size.width)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.category.chartColor)
                                    .frame(width: geometry.size.width * (item.amount / total))
                            }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

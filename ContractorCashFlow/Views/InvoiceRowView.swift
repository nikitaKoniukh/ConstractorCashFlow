//
//  InvoiceRowView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData


struct InvoiceRowView: View {
    let invoice: Invoice
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    
    private var statusColor: Color {
        if invoice.isPaid { return .green }
        if invoice.isOverdue { return .red }
        return .orange
    }
    
    private var statusText: LocalizedStringKey {
        if invoice.isPaid { return LocalizationKey.Invoice.paid }
        if invoice.isOverdue { return LocalizationKey.Invoice.overdue }
        return LocalizationKey.Invoice.pending
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            VStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
            }
            .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: LocalizationKey.Project.invoiceToFormat, invoice.clientName))
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: LocalizationKey.Project.dueFormat, invoice.dueDate.formatted(date: .abbreviated, time: .omitted)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(invoice.amount, format: .currency(code: currencyCode))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(invoice.isPaid ? .green : .primary)
        }
        .padding(.vertical, 2)
    }
}


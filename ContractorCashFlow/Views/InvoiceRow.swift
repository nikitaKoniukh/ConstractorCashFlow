//
//  InvoiceRow.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct InvoiceRow: View {
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
    
    private var statusIcon: String {
        if invoice.isPaid { return "checkmark.circle.fill" }
        if invoice.isOverdue { return "exclamationmark.triangle.fill" }
        return "clock.fill"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Client name and status badge
            HStack(alignment: .center) {
                Text(invoice.clientName)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Label(statusText, systemImage: statusIcon)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }
            
            // Project name
            if let project = invoice.project {
                Label(project.name, systemImage: "folder")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Due date and amount
            HStack {
                Label {
                    Text(invoice.dueDate, format: .dateTime.month().day().year())
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(invoice.amount, format: .currency(code: currencyCode))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(invoice.isPaid ? .green : .primary)
            }
        }
        .padding(.vertical, 4)
    }
}

//
//  ProjectExportView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct ProjectExportView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    let project: Project
    
    @State private var includeExpenses = true
    @State private var includeInvoices = true
    @State private var shareText = ""
    @State private var isShowingShareSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Export Options") {
                    Toggle("Include Expenses", isOn: $includeExpenses)
                    Toggle("Include Invoices", isOn: $includeInvoices)
                }
                
                Section("Preview") {
                    Text(generateExportText())
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Export Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(
                        item: generateExportText(),
                        subject: Text("Project: \(project.name)"),
                        message: Text("Financial summary for \(project.name)")
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func generateExportText() -> String {
        var text = """
        PROJECT: \(project.name)
        Client: \(project.clientName)
        Status: \(project.isActive ? "Active" : "Inactive")
        Created: \(project.createdDate.formatted(date: .abbreviated, time: .omitted))
        
        FINANCIAL SUMMARY
        Budget: \(project.budget.formatted(.currency(code: currencyCode)))
        Total Expenses: \(project.totalExpenses.formatted(.currency(code: currencyCode)))
        Total Income: \(project.totalIncome.formatted(.currency(code: currencyCode)))
        Net Balance: \(project.balance.formatted(.currency(code: currencyCode)))
        Profit Margin: \(String(format: "%.1f%%", project.profitMargin))
        Budget Utilization: \(String(format: "%.1f%%", project.budgetUtilization))
        """
        
        if includeExpenses && !project.safeExpenses.isEmpty {
            text += "\n\nEXPENSES (\(project.safeExpenses.count))"
            text += "\n" + String(repeating: "-", count: 50)
            
            for expense in project.safeExpenses.sorted(by: { $0.date > $1.date }) {
                text += """
                \n\(expense.date.formatted(date: .abbreviated, time: .omitted)) - \(expense.category.displayName)
                  \(expense.descriptionText)
                  \(expense.amount.formatted(.currency(code: currencyCode)))
                """
            }
        }
        
        if includeInvoices && !project.safeInvoices.isEmpty {
            text += "\n\nINVOICES (\(project.safeInvoices.count))"
            text += "\n" + String(repeating: "-", count: 50)
            
            for invoice in project.safeInvoices.sorted(by: { $0.createdDate > $1.createdDate }) {
                let status = invoice.isPaid ? "PAID" : (invoice.isOverdue ? "OVERDUE" : "PENDING")
                text += """
                \n\(invoice.createdDate.formatted(date: .abbreviated, time: .omitted)) - \(status)
                  Due: \(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))
                  \(invoice.amount.formatted(.currency(code: currencyCode)))
                """
            }
        }
        
        text += "\n\n" + String(repeating: "=", count: 50)
        text += "\nExported: \(Date().formatted(date: .long, time: .shortened))"
        
        return text
    }
}

//
//  InvoicesListContent.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//
//

import SwiftUI
import SwiftData


struct InvoicesListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(PurchaseManager.self) private var purchaseManager
    let searchText: String
    let statusFilter: InvoiceStatusFilter
    
    init(searchText: String, statusFilter: InvoiceStatusFilter) {
        self.searchText = searchText
        self.statusFilter = statusFilter
        
        // Build predicate based on search text and status filter
        let predicate: Predicate<Invoice>
        let now = Date()
        let searchEmpty = searchText.isEmpty
        
        // Build single-expression predicate based on status filter
        switch statusFilter {
        case .all:
            predicate = #Predicate<Invoice> { invoice in
                searchEmpty || invoice.clientName.localizedStandardContains(searchText)
            }
        case .paid:
            predicate = #Predicate<Invoice> { invoice in
                (searchEmpty || invoice.clientName.localizedStandardContains(searchText)) &&
                invoice.isPaid
            }
        case .unpaid:
            predicate = #Predicate<Invoice> { invoice in
                (searchEmpty || invoice.clientName.localizedStandardContains(searchText)) &&
                !invoice.isPaid && invoice.dueDate >= now
            }
        case .overdue:
            predicate = #Predicate<Invoice> { invoice in
                (searchEmpty || invoice.clientName.localizedStandardContains(searchText)) &&
                !invoice.isPaid && invoice.dueDate < now
            }
        }
        
        _invoices = Query(filter: predicate, sort: \Invoice.createdDate, order: .reverse)
    }
    
    @Query private var invoices: [Invoice]
    
    var body: some View {
        List {
            ForEach(invoices) { invoice in
                NavigationLink {
                    EditInvoiceView(invoice: invoice)
                } label: {
                    InvoiceRow(invoice: invoice)
                }
            }
            .onDelete(perform: deleteInvoices)
        }
        .overlay {
            if invoices.isEmpty {
                if searchText.isEmpty && statusFilter == .all {
                    // Enhanced empty state with CTA button
                    ContentUnavailableView {
                        Label("No Invoices", systemImage: "doc.text")
                    } description: {
                        Text("No invoices created yet. Start billing your clients")
                    } actions: {
                        Button {
                            appState.isShowingNewInvoice = true
                        } label: {
                            Text("Add Invoice")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView.search(text: searchText.isEmpty ? "No matching invoices" : searchText)
                }
            }
        }
    }
    
    private func deleteInvoices(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let invoice = invoices[index]
                do {
                    // Cancel notifications before deleting
                    Task {
                        await NotificationService.shared.cancelNotifications(for: invoice)
                    }
                    modelContext.delete(invoice)
                    try modelContext.save()
                } catch {
                    appState.showError("Failed to delete invoice: \(error.localizedDescription)")
                }
            }
        }
    }
}

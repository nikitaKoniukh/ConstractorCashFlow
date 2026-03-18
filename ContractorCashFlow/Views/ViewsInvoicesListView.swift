//
//  InvoicesListView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI
import SwiftData

struct InvoicesListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchaseManager
    @Query private var allInvoicesForCount: [Invoice]
    
    @State private var searchText: String = ""
    @State private var selectedStatusFilter: InvoiceStatusFilter = .all
    @State private var isShowingPaywall = false
    
    var body: some View {
        NavigationStack(path: appState.navigationPath(for: .invoices)) {
            InvoicesListContent(
                searchText: searchText,
                statusFilter: selectedStatusFilter
            )
            .navigationTitle(LocalizationKey.Invoice.title)
            .searchable(text: $searchText, prompt: "Search invoices")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filter", selection: $selectedStatusFilter) {
                            ForEach(InvoiceStatusFilter.allCases, id: \.self) { filter in
                                Label(filter.displayName, systemImage: filter.iconName)
                                    .tag(filter)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: selectedStatusFilter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if purchaseManager.canCreateInvoice(currentCount: allInvoicesForCount.count) {
                            appState.isShowingNewInvoice = true
                        } else {
                            isShowingPaywall = true
                        }
                    } label: {
                        Label(LocalizationKey.Invoice.add, systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.isShowingNewInvoice },
                set: { appState.isShowingNewInvoice = $0 }
            )) {
                NewInvoiceView()
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView(limitReachedMessage: LocalizationKey.Subscription.invoiceLimitReached)
            }
        }
    }
}

// MARK: - Invoice Status Filter
enum InvoiceStatusFilter: String, CaseIterable {
    case all = "All"
    case paid = "Paid"
    case unpaid = "Unpaid"
    case overdue = "Overdue"
    
    var displayName: String {
        rawValue
    }
    
    var iconName: String {
        switch self {
        case .all: return "doc.text"
        case .paid: return "checkmark.circle.fill"
        case .unpaid: return "clock.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Invoices List Content (with filtering)
private struct InvoicesListContent: View {
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

// MARK: - Invoice Row Component
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

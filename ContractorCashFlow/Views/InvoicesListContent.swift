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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let searchText: String
    let statusFilter: InvoiceStatusFilter

    init(searchText: String, statusFilter: InvoiceStatusFilter) {
        self.searchText = searchText
        self.statusFilter = statusFilter

        let predicate: Predicate<Invoice>
        let now = Date()
        let searchEmpty = searchText.isEmpty

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

    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        Group {
            if isIPad {
                iPadGrid
            } else {
                iPhoneList
            }
        }
        .overlay {
            if invoices.isEmpty {
                if searchText.isEmpty && statusFilter == .all {
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

    // MARK: iPhone – plain list
    private var iPhoneList: some View {
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
    }

    // MARK: iPad – card grid
    private var iPadGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 340, maximum: 480), spacing: 16)],
                spacing: 16
            ) {
                ForEach(invoices) { invoice in
                    NavigationLink {
                        EditInvoiceView(invoice: invoice)
                    } label: {
                        InvoiceCardView(invoice: invoice)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteInvoice(invoice)
                        } label: {
                            Label(LocalizationKey.General.delete, systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func deleteInvoices(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let invoice = invoices[index]
                Task { await NotificationService.shared.cancelNotifications(for: invoice) }
                do {
                    modelContext.delete(invoice)
                    try modelContext.save()
                } catch {
                    appState.showError("Failed to delete invoice: \(error.localizedDescription)")
                }
            }
        }
    }

    private func deleteInvoice(_ invoice: Invoice) {
        Task { await NotificationService.shared.cancelNotifications(for: invoice) }
        do {
            modelContext.delete(invoice)
            try modelContext.save()
        } catch {
            appState.showError("Failed to delete invoice: \(invoice.clientName)")
        }
    }
}
// MARK: - iPad Invoice Card
private struct InvoiceCardView: View {
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
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundStyle(statusColor)
                    .frame(width: 40, height: 40)
                    .background(statusColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(invoice.clientName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let project = invoice.project {
                        Label(project.name, systemImage: "folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(invoice.amount, format: .currency(code: currencyCode))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(invoice.isPaid ? .green : .primary)
            }
            .padding()

            Divider()

            // Footer
            HStack {
                Label(statusText, systemImage: statusIcon)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())

                Spacer()

                Label {
                    Text(invoice.dueDate, format: .dateTime.month(.abbreviated).day().year())
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}


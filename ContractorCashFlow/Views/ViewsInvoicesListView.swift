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
    
    @State private var searchText: String = ""
    @State private var selectedStatusFilter: InvoiceStatusFilter = .all
    
    var body: some View {
        NavigationStack {
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
                        appState.isShowingNewInvoice = true
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
                InvoiceRow(invoice: invoice)
            }
            .onDelete(perform: deleteInvoices)
        }
        .overlay {
            if invoices.isEmpty {
                if searchText.isEmpty && statusFilter == .all {
                    ContentUnavailableView(
                        LocalizationKey.Invoice.empty,
                        systemImage: "doc.text",
                        description: Text(LocalizationKey.Invoice.emptyDescription)
                    )
                } else {
                    ContentUnavailableView.search(text: searchText.isEmpty ? "No matching invoices" : searchText)
                }
            }
        }
    }
    
    private func deleteInvoices(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(invoices[index])
            }
        }
    }
}

// MARK: - Invoice Row Component
struct InvoiceRow: View {
    let invoice: Invoice
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.clientName)
                    .font(.headline)
                
                HStack {
                    if invoice.isPaid {
                        Label(LocalizationKey.Invoice.paid, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if invoice.isOverdue {
                        Label(LocalizationKey.Invoice.overdue, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Label(LocalizationKey.Invoice.pending, systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    if let project = invoice.project {
                        Text("• \(project.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("\(String(localized: "invoice.duePrefix.label")): \(invoice.dueDate, format: .dateTime.month().day().year())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(invoice.amount, format: .currency(code: "USD"))
                .font(.headline)
                .foregroundStyle(invoice.isPaid ? .green : .primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Placeholder View
struct NewInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]
    
    @State private var amount: Double = 0
    @State private var clientName: String = ""
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var isPaid: Bool = false
    @State private var selectedProject: Project?
    
    private var isValid: Bool {
        !clientName.isEmpty && amount > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "invoice.details")) {
                    TextField(LocalizationKey.Invoice.clientName, text: $clientName)
                    
                    TextField(LocalizationKey.Invoice.amount, value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    
                    DatePicker(LocalizationKey.Invoice.dueDate, selection: $dueDate, displayedComponents: .date)
                    
                    Toggle(LocalizationKey.Invoice.paid, isOn: $isPaid)
                }
                
                Section(String(localized: "invoice.project")) {
                    Picker(LocalizationKey.Invoice.projectOptional, selection: $selectedProject) {
                        Text(LocalizationKey.Invoice.none).tag(nil as Project?)
                        ForEach(projects.filter { $0.isActive }) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }
                }
            }
            .navigationTitle(LocalizationKey.Invoice.newTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationKey.Action.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKey.Action.save) {
                        saveInvoice()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveInvoice() {
        let invoice = Invoice(
            amount: amount,
            dueDate: dueDate,
            isPaid: isPaid,
            clientName: clientName,
            project: selectedProject
        )
        modelContext.insert(invoice)
        dismiss()
    }
}

#Preview {
    InvoicesListView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

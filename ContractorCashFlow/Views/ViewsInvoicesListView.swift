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

// MARK: - Edit Invoice View
struct EditInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    @Query private var projects: [Project]
    @Query(sort: \Client.name) private var clients: [Client]
    
    @Bindable var invoice: Invoice
    
    @State private var amount: Double?
    @State private var clientName: String
    @State private var selectedClient: Client?
    @State private var useExistingClient: Bool
    @State private var dueDate: Date
    @State private var isPaid: Bool
    @State private var selectedProject: Project?
    @State private var isSaving: Bool = false
    
    init(invoice: Invoice) {
        self.invoice = invoice
        _amount = State(initialValue: invoice.amount > 0 ? invoice.amount : nil)
        _clientName = State(initialValue: invoice.clientName)
        _selectedClient = State(initialValue: nil)
        _useExistingClient = State(initialValue: false)
        _dueDate = State(initialValue: invoice.dueDate)
        _isPaid = State(initialValue: invoice.isPaid)
        _selectedProject = State(initialValue: invoice.project)
    }
    
    private var finalClientName: String {
        if useExistingClient {
            return selectedClient?.name ?? ""
        } else {
            return clientName
        }
    }
    
    private var isValid: Bool {
        !finalClientName.trimmingCharacters(in: .whitespaces).isEmpty &&
        (amount ?? 0) > 0
    }
    
    private func clientExists(name: String) -> Bool {
        clients.contains { $0.name.lowercased() == name.lowercased() }
    }
    
    var body: some View {
        Form {
            Section(LocalizationKey.Invoice.details) {
                // Client selection
                if !clients.isEmpty {
                    Picker("Client Source", selection: $useExistingClient) {
                        Text("Enter Name").tag(false)
                        Text("Select Existing").tag(true)
                    }
                    .pickerStyle(.segmented)
                    
                    if useExistingClient {
                        Picker(LocalizationKey.Invoice.clientName, selection: $selectedClient) {
                            Text("Select a client")
                                .tag(nil as Client?)
                            
                            ForEach(clients) { client in
                                Text(client.name)
                                    .tag(client as Client?)
                            }
                        }
                        
                        if let client = selectedClient {
                            VStack(alignment: .leading, spacing: 4) {
                                if let email = client.email {
                                    Label(email, systemImage: "envelope")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let phone = client.phone {
                                    Label(phone, systemImage: "phone")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        TextField(LocalizationKey.Invoice.clientName, text: $clientName)
                        
                        if !clientName.isEmpty && clientExists(name: clientName) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("A client with this name already exists. Consider selecting from existing clients.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    TextField(LocalizationKey.Invoice.clientName, text: $clientName)
                }
                
                CurrencyTextField(LocalizationKey.Invoice.amount, value: $amount, currencyCode: currencyCode)
                
                DatePicker(LocalizationKey.Invoice.dueDate, selection: $dueDate, displayedComponents: .date)
                
                Toggle(LocalizationKey.Invoice.paid, isOn: $isPaid)
            }
            
            Section(LocalizationKey.Invoice.project) {
                Picker(LocalizationKey.Invoice.projectOptional, selection: $selectedProject) {
                    Text(LocalizationKey.Invoice.none).tag(nil as Project?)
                    ForEach(projects.filter { $0.isActive }) { project in
                        Text(project.name).tag(project as Project?)
                    }
                }
            }
            
            Section {
                Button(role: .destructive) {
                    deleteInvoice()
                } label: {
                    HStack {
                        Spacer()
                        Label(LocalizationKey.Action.delete, systemImage: "trash")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(LocalizationKey.Invoice.editTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizationKey.Action.save) {
                    saveChanges()
                }
                .disabled(!isValid || isSaving)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(LocalizationKey.Action.done) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .onAppear {
            // Pre-select existing client if the invoice's clientName matches one
            if let matchingClient = clients.first(where: { $0.name.lowercased() == invoice.clientName.lowercased() }) {
                selectedClient = matchingClient
                useExistingClient = true
            }
        }
    }
    
    private func saveChanges() {
        guard isValid else { return }
        isSaving = true
        
        let wasPaid = invoice.isPaid
        let invoiceClientName = finalClientName.trimmingCharacters(in: .whitespaces)
        
        // Auto-create client if entering manually and doesn't exist
        if !useExistingClient && !clientName.isEmpty && !clientExists(name: clientName) {
            let newClient = Client(name: clientName.trimmingCharacters(in: .whitespaces))
            modelContext.insert(newClient)
        }
        
        invoice.clientName = invoiceClientName
        invoice.amount = amount ?? 0
        invoice.dueDate = dueDate
        invoice.isPaid = isPaid
        invoice.project = selectedProject
        
        do {
            try modelContext.save()
            
            // Update notifications based on paid status change
            Task {
                if isPaid {
                    await NotificationService.shared.cancelNotifications(for: invoice)
                } else if wasPaid && !isPaid {
                    await NotificationService.shared.scheduleNotifications(for: invoice)
                }
            }
            
            dismiss()
        } catch {
            appState.showError("Failed to update invoice: \(error.localizedDescription)")
            isSaving = false
        }
    }
    
    private func deleteInvoice() {
        Task {
            await NotificationService.shared.cancelNotifications(for: invoice)
        }
        modelContext.delete(invoice)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            appState.showError("Failed to delete invoice: \(error.localizedDescription)")
        }
    }
}

// MARK: - New Invoice View
struct NewInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    @Query private var projects: [Project]
    @Query(sort: \Client.name) private var clients: [Client]
    
    @State private var amount: Double?
    @State private var clientName: String = ""
    @State private var selectedClient: Client?
    @State private var useExistingClient: Bool = false
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var isPaid: Bool = false
    @State private var selectedProject: Project?
    @State private var isSaving: Bool = false
    
    private var finalClientName: String {
        if useExistingClient {
            return selectedClient?.name ?? ""
        } else {
            return clientName
        }
    }
    
    private var isValid: Bool {
        !finalClientName.isEmpty && (amount ?? 0) > 0
    }
    
    private func clientExists(name: String) -> Bool {
        clients.contains { $0.name.lowercased() == name.lowercased() }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(LocalizationKey.Invoice.details) {
                    // Client selection
                    if !clients.isEmpty {
                        Picker("Client Source", selection: $useExistingClient) {
                            Text("Enter Name").tag(false)
                            Text("Select Existing").tag(true)
                        }
                        .pickerStyle(.segmented)
                        
                        if useExistingClient {
                            Picker(LocalizationKey.Invoice.clientName, selection: $selectedClient) {
                                Text("Select a client")
                                    .tag(nil as Client?)
                                
                                ForEach(clients) { client in
                                    Text(client.name)
                                        .tag(client as Client?)
                                }
                            }
                            
                            if let client = selectedClient {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let email = client.email {
                                        Label(email, systemImage: "envelope")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let phone = client.phone {
                                        Label(phone, systemImage: "phone")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } else {
                            TextField(LocalizationKey.Invoice.clientName, text: $clientName)
                            
                            if !clientName.isEmpty && clientExists(name: clientName) {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text("A client with this name already exists. Consider selecting from existing clients.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        TextField(LocalizationKey.Invoice.clientName, text: $clientName)
                    }
                    
                    CurrencyTextField(LocalizationKey.Invoice.amount, value: $amount, currencyCode: currencyCode)
                    
                    DatePicker(LocalizationKey.Invoice.dueDate, selection: $dueDate, displayedComponents: .date)
                    
                    Toggle(LocalizationKey.Invoice.paid, isOn: $isPaid)
                }
                
                Section(LocalizationKey.Invoice.project) {
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
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKey.Action.save) {
                        saveInvoice()
                    }
                    .disabled(!isValid || isSaving)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocalizationKey.Action.done) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
    
    private func saveInvoice() {
        isSaving = true
        
        let invoiceClientName = finalClientName
        
        // Auto-create client if entering manually and doesn't exist
        if !useExistingClient && !clientName.isEmpty && !clientExists(name: clientName) {
            let newClient = Client(name: clientName)
            modelContext.insert(newClient)
        }
        
        let invoice = Invoice(
            amount: amount ?? 0,
            dueDate: dueDate,
            isPaid: isPaid,
            clientName: invoiceClientName,
            project: selectedProject
        )
        
        do {
            modelContext.insert(invoice)
            try modelContext.save()
            
            // Schedule notifications if not paid
            if !isPaid {
                Task {
                    await NotificationService.shared.scheduleNotifications(for: invoice)
                }
            }
            
            dismiss()
        } catch {
            appState.showError("Failed to save invoice: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

#Preview {
    InvoicesListView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

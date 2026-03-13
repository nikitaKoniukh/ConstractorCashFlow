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
    @Query(sort: \Invoice.createdDate, order: .reverse) private var invoices: [Invoice]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(invoices) { invoice in
                    InvoiceRow(invoice: invoice)
                }
                .onDelete(perform: deleteInvoices)
            }
            .navigationTitle("Invoices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.isShowingNewInvoice = true
                    } label: {
                        Label("Add Invoice", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.isShowingNewInvoice },
                set: { appState.isShowingNewInvoice = $0 }
            )) {
                NewInvoiceView()
            }
            .overlay {
                if invoices.isEmpty {
                    ContentUnavailableView(
                        "No Invoices",
                        systemImage: "doc.text",
                        description: Text("Tap + to create your first invoice")
                    )
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
                        Label("Paid", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if invoice.isOverdue {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Label("Pending", systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    if let project = invoice.project {
                        Text("• \(project.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("Due: \(invoice.dueDate, format: .dateTime.month().day().year())")
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
                Section("Invoice Details") {
                    TextField("Client Name", text: $clientName)
                    
                    TextField("Amount", value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    
                    Toggle("Paid", isOn: $isPaid)
                }
                
                Section("Project") {
                    Picker("Project (Optional)", selection: $selectedProject) {
                        Text("None").tag(nil as Project?)
                        ForEach(projects.filter { $0.isActive }) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }
                }
            }
            .navigationTitle("New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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

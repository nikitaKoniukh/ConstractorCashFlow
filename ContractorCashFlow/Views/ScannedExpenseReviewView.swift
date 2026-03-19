//
//  ScannedExpenseReviewView.swift
//  ContractorCashFlow
//

import SwiftUI
import SwiftData

struct ScannedExpenseReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode
    @Query private var projects: [Project]

    let scannedData: ScannedInvoiceData
    let onSaved: () -> Void

    // Editable fields pre-filled from OCR
    @State private var amount: Double?
    @State private var descriptionText: String = ""
    @State private var date: Date = Date()
    @State private var category: ExpenseCategory = .misc
    @State private var selectedProject: Project? = nil
    @State private var isSaving = false

    @FocusState private var amountFocused: Bool

    private var isValid: Bool {
        !descriptionText.isEmpty && (amount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // Confidence banner
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text.viewfinder")
                            .foregroundStyle(.blue)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Invoice scanned")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Review and correct the fields below before saving.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Amount") {
                    CurrencyTextField("Amount", value: $amount, currencyCode: currencyCode)
                        .focused($amountFocused)
                }

                Section("Description") {
                    TextField("Description", text: $descriptionText)
                }

                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section("Project (optional)") {
                    Picker("Project", selection: $selectedProject) {
                        Text("None").tag(nil as Project?)
                        ForEach(projects) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }
                }
            }
            .navigationTitle("Review Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onSaved() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid || isSaving)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { amountFocused = false }
                }
            }
            .onAppear {
                // Pre-fill with OCR results
                amount = scannedData.amount
                descriptionText = scannedData.description
                date = scannedData.date ?? Date()

                // Auto-detect category from description keywords
                let lower = scannedData.description.lowercased()
                if lower.contains("labor") || lower.contains("worker") || lower.contains("wages") {
                    category = .labor
                } else if lower.contains("material") || lower.contains("lumber") || lower.contains("supply") || lower.contains("supplies") {
                    category = .materials
                } else if lower.contains("equipment") || lower.contains("rental") || lower.contains("tool") {
                    category = .equipment
                } else {
                    category = .misc
                }
            }
        }
    }

    private func save() {
        isSaving = true
        let expense = Expense(
            category: category,
            amount: amount ?? 0,
            descriptionText: descriptionText,
            date: date,
            project: selectedProject
        )
        modelContext.insert(expense)
        do {
            try modelContext.save()
            if let project = selectedProject {
                Task {
                    await NotificationService.shared.checkBudgetAndScheduleNotifications(for: project)
                }
            }
            onSaved()
        } catch {
            appState.showError("Failed to save expense: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

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
    let scannedImage: UIImage?
    let onSaved: () -> Void

    // Editable fields pre-filled from OCR
    @State private var amount: Double?
    @State private var descriptionText: String = ""
    @State private var date: Date = Date()
    @State private var category: ExpenseCategory = .misc
    @State private var selectedProject: Project? = nil
    @State private var isSaving = false
    @State private var isShowingReceiptFullScreen = false

    @FocusState private var amountFocused: Bool

    private var isValid: Bool {
        !descriptionText.isEmpty && (amount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // Scanned receipt preview
                if let image = scannedImage {
                    Section {
                        HStack(spacing: 12) {
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
                            Spacer()
                            // Thumbnail — tap to view full screen
                            Button {
                                isShowingReceiptFullScreen = true
                            } label: {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 52, height: 52)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
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
                amount = scannedData.amount
                descriptionText = scannedData.description
                date = scannedData.date ?? Date()

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
            .sheet(isPresented: $isShowingReceiptFullScreen) {
                if let image = scannedImage {
                    ReceiptFullScreenView(image: image)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        // Compress image to JPEG before storing
        let imageData = scannedImage.flatMap { $0.jpegData(compressionQuality: 0.7) }
        let expense = Expense(
            category: category,
            amount: amount ?? 0,
            descriptionText: descriptionText,
            date: date,
            project: selectedProject,
            receiptImageData: imageData
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

// MARK: - Full screen receipt viewer

struct ReceiptFullScreenView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geo.size.width * max(scale, 1),
                            height: geo.size.height * max(scale, 1)
                        )
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    scale = lastScale * value.magnification
                                }
                                .onEnded { value in
                                    lastScale = scale
                                    if scale < 1 { scale = 1; lastScale = 1 }
                                    if scale > 5 { scale = 5; lastScale = 5 }
                                }
                        )
                }
            }
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

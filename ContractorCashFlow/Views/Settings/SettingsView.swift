import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @Query(sort: \Project.createdDate, order: .reverse) private var projects: [Project]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \Invoice.createdDate, order: .reverse) private var invoices: [Invoice]
    @Query(sort: \Client.name) private var clients: [Client]

    @AppStorage("settings.notifications.invoiceReminders") private var invoiceRemindersEnabled = true
    @AppStorage("settings.notifications.overdueAlerts") private var overdueAlertsEnabled = true
    @AppStorage("settings.notifications.budgetWarnings") private var budgetWarningsEnabled = true

    @State private var exportDocument: JSONExportDocument?
    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: languageSelectionBinding) {
                        ForEach(LanguageManager.SupportedLanguage.allCases) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    } label: {
                        Label(LocalizationKey.Settings.language, systemImage: "globe")
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text(LocalizationKey.Settings.languageSection)
                } footer: {
                    Text(LocalizationKey.Settings.languageFooter)
                }

                Section {
                    Toggle(isOn: $invoiceRemindersEnabled) {
                        Label(LocalizationKey.Settings.invoiceReminders, systemImage: "calendar.badge.clock")
                    }
                    .onChange(of: invoiceRemindersEnabled) { _, _ in
                        handleNotificationSettingsChange()
                    }

                    Toggle(isOn: $overdueAlertsEnabled) {
                        Label(LocalizationKey.Settings.overdueAlerts, systemImage: "exclamationmark.bubble")
                    }
                    .onChange(of: overdueAlertsEnabled) { _, _ in
                        handleNotificationSettingsChange()
                    }

                    Toggle(isOn: $budgetWarningsEnabled) {
                        Label(LocalizationKey.Settings.budgetWarnings, systemImage: "chart.bar.doc.horizontal")
                    }
                    .onChange(of: budgetWarningsEnabled) { _, _ in
                        handleBudgetSettingsChange()
                    }
                } header: {
                    Text(LocalizationKey.Settings.notifications)
                } footer: {
                    Text(LocalizationKey.Settings.notificationsFooter)
                }

                Section {
                    Button {
                        exportData()
                    } label: {
                        Label(LocalizationKey.Settings.exportData, systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text(LocalizationKey.Settings.dataSection)
                } footer: {
                    Text(LocalizationKey.Settings.exportFooter)
                }

                Section {
                    LabeledContent(LocalizationKey.Settings.about, value: appDisplayName)
                    LabeledContent(LocalizationKey.Settings.appVersion, value: appVersionDescription)
                } header: {
                    Text(LocalizationKey.Settings.aboutSection)
                }
            }
            .navigationTitle(LocalizationKey.Settings.title)
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFileName
        ) { _ in
            exportDocument = nil
        }
    }

    private var languageSelectionBinding: Binding<LanguageManager.SupportedLanguage> {
        Binding(
            get: { languageManager.currentLanguage },
            set: { newValue in
                languageManager.switchLanguage(to: newValue)
            }
        )
    }

    private var appDisplayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "ContractorCashFlow"
    }

    private var appVersionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var exportFileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "contractor-cashflow-\(formatter.string(from: Date()))"
    }

    @MainActor
    private func exportData() {
        let snapshot = ExportSnapshot(
            exportedAt: Date(),
            preferences: ExportPreferences(
                languageCode: languageManager.currentLanguage.rawValue,
                invoiceRemindersEnabled: invoiceRemindersEnabled,
                overdueAlertsEnabled: overdueAlertsEnabled,
                budgetWarningsEnabled: budgetWarningsEnabled
            ),
            projects: projects.map(ExportProject.init),
            expenses: expenses.map(ExportExpense.init),
            invoices: invoices.map(ExportInvoice.init),
            clients: clients.map(ExportClient.init)
        )

        guard let data = try? JSONEncoder.exportEncoder.encode(snapshot) else {
            return
        }

        exportDocument = JSONExportDocument(data: data)
        isExporting = true
    }
    
    // MARK: - Notification Settings Handlers
    
    private func handleNotificationSettingsChange() {
        Task {
            await NotificationService.shared.rescheduleAllInvoiceNotifications(from: modelContext)
        }
    }
    
    private func handleBudgetSettingsChange() {
        Task {
            await NotificationService.shared.rescheduleAllBudgetNotifications(from: modelContext)
        }
    }
}

private extension JSONEncoder {
    static var exportEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private struct JSONExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct ExportSnapshot: Encodable {
    let exportedAt: Date
    let preferences: ExportPreferences
    let projects: [ExportProject]
    let expenses: [ExportExpense]
    let invoices: [ExportInvoice]
    let clients: [ExportClient]
}

private struct ExportPreferences: Encodable {
    let languageCode: String
    let invoiceRemindersEnabled: Bool
    let overdueAlertsEnabled: Bool
    let budgetWarningsEnabled: Bool
}

@MainActor
private struct ExportProject: Encodable {
    let id: UUID
    let name: String
    let clientName: String
    let budget: Double
    let createdDate: Date
    let isActive: Bool
    let totalExpenses: Double
    let totalIncome: Double
    let balance: Double

    init(project: Project) {
        id = project.id
        name = project.name
        clientName = project.clientName
        budget = project.budget
        createdDate = project.createdDate
        isActive = project.isActive
        totalExpenses = project.totalExpenses
        totalIncome = project.totalIncome
        balance = project.balance
    }
}

@MainActor
private struct ExportExpense: Encodable {
    let id: UUID
    let category: String
    let amount: Double
    let description: String
    let date: Date
    let projectID: UUID?
    let projectName: String?

    init(expense: Expense) {
        id = expense.id
        category = expense.category.rawValue
        amount = expense.amount
        description = expense.descriptionText
        date = expense.date
        projectID = expense.project?.id
        projectName = expense.project?.name
    }
}

@MainActor
private struct ExportInvoice: Encodable {
    let id: UUID
    let amount: Double
    let dueDate: Date
    let isPaid: Bool
    let clientName: String
    let createdDate: Date
    let isOverdue: Bool
    let projectID: UUID?
    let projectName: String?

    init(invoice: Invoice) {
        id = invoice.id
        amount = invoice.amount
        dueDate = invoice.dueDate
        isPaid = invoice.isPaid
        clientName = invoice.clientName
        createdDate = invoice.createdDate
        isOverdue = invoice.isOverdue
        projectID = invoice.project?.id
        projectName = invoice.project?.name
    }
}

@MainActor
private struct ExportClient: Encodable {
    let id: UUID
    let name: String
    let email: String?
    let phone: String?
    let address: String?
    let notes: String?

    init(client: Client) {
        id = client.id
        name = client.name
        email = client.email
        phone = client.phone
        address = client.address
        notes = client.notes
    }
}

#Preview {
    SettingsView()
        .environment(LanguageManager.shared)
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

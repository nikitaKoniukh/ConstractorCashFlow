import SwiftUI
import SwiftData
import StoreKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdDate, order: .reverse) private var projects: [Project]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \Invoice.createdDate, order: .reverse) private var invoices: [Invoice]
    @Query(sort: \Client.name) private var clients: [Client]

    @AppStorage(StorageKey.appLanguage) private var appLanguageCode = AppLanguageOption.defaultCode
    @AppStorage(StorageKey.selectedCurrencyCode) private var selectedCurrencyCode = StorageKey.defaultCurrencyCode
    @AppStorage(StorageKey.Notifications.invoiceReminders) private var invoiceRemindersEnabled = true
    @AppStorage(StorageKey.Notifications.overdueAlerts) private var overdueAlertsEnabled = true
    @AppStorage(StorageKey.Notifications.budgetWarnings) private var budgetWarningsEnabled = true

    @State private var exportDocument: JSONExportDocument?
    @State private var isExporting = false
    @State private var isShowingPaywall = false
    @State private var iCloudSyncState: ICloudSyncState = .idle

    private enum ICloudSyncState {
        case idle, syncing, done, failed
    }

    @Environment(AppState.self) private var appState
    @Environment(PurchaseManager.self) private var purchaseManager

    var body: some View {
        NavigationStack(path: appState.navigationPath(for: .settings)) {
            Form {
                // MARK: - Subscription
                Section {
                    if purchaseManager.isProUser {
                        LabeledContent(LocalizationKey.Subscription.currentPlan) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                Text(purchaseManager.subscriptionStatusText)
                                    .foregroundStyle(.green)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if let expirationDate = purchaseManager.expirationDate {
                            LabeledContent(LocalizationKey.Subscription.renewsOn) {
                                Text(expirationDate, style: .date)
                            }
                        }
                        
                        Button {
                            Task {
                                if let windowScene = UIApplication.shared.connectedScenes
                                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                                    try? await AppStore.showManageSubscriptions(in: windowScene)
                                }
                            }
                        } label: {
                            Label(LocalizationKey.Subscription.managePlan, systemImage: "creditcard")
                        }
                    } else {
                        LabeledContent(LocalizationKey.Subscription.currentPlan) {
                            Text(LocalizationKey.Subscription.freePlan)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            isShowingPaywall = true
                        } label: {
                            Label(LocalizationKey.Subscription.upgradeTitle, systemImage: "crown.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                } header: {
                    Text(LocalizationKey.Subscription.subscriptionSection)
                }
                
                Section {
                    Picker(selection: languageSelectionBinding) {
                        ForEach(AppLanguageOption.allCases) { language in
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
                    Picker(selection: $selectedCurrencyCode) {
                        ForEach(CurrencyOption.allCases) { currency in
                            Text(currency.displayName)
                                .tag(currency.code)
                        }
                    } label: {
                        Label(LocalizationKey.Settings.currency, systemImage: "dollarsign.circle")
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text(LocalizationKey.Settings.currencySection)
                } footer: {
                    Text(LocalizationKey.Settings.currencyFooter)
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
                        syncWithICloud()
                    } label: {
                        HStack {
                            switch iCloudSyncState {
                            case .idle:
                                Label("Sync with iCloud", systemImage: "arrow.triangle.2.circlepath.icloud")
                            case .syncing:
                                Label {
                                    Text("Syncing…")
                                } icon: {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                            case .done:
                                Label("Synced", systemImage: "checkmark.icloud")
                                    .foregroundStyle(.green)
                            case .failed:
                                Label("Sync Failed", systemImage: "xmark.icloud")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .disabled(iCloudSyncState == .syncing)

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
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
    }

    private var languageSelectionBinding: Binding<AppLanguageOption> {
        Binding(
            get: { selectedLanguage },
            set: { newLanguage in
                appLanguageCode = newLanguage.rawValue
                if let language = LanguageManager.SupportedLanguage(rawValue: newLanguage.rawValue) {
                    LanguageManager.shared.switchLanguage(to: language)
                }
            }
        )
    }

    private var selectedLanguage: AppLanguageOption {
        AppLanguageOption(rawValue: appLanguageCode) ?? .english
    }

    private var appDisplayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? LocalizationKey.Settings.appNameFallback
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
                languageCode: selectedLanguage.rawValue,
                currencyCode: selectedCurrencyCode,
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
    
    // MARK: - iCloud Sync

    private func syncWithICloud() {
        iCloudSyncState = .syncing
        Task {
            do {
                // Save any pending changes — SwiftData + CloudKit will then
                // automatically push those changes to iCloud on its next cycle.
                try modelContext.save()
                await MainActor.run { iCloudSyncState = .done }
            } catch {
                await MainActor.run { iCloudSyncState = .failed }
            }
            // Reset back to idle after a short delay so the user sees feedback
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { iCloudSyncState = .idle }
        }
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

private enum CurrencyOption: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case ils = "ILS"
    case rub = "RUB"
    case jpy = "JPY"
    case cad = "CAD"
    case aud = "AUD"

    var id: String { rawValue }
    var code: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .usd: return LocalizationKey.Settings.currencyUSD
        case .eur: return LocalizationKey.Settings.currencyEUR
        case .gbp: return LocalizationKey.Settings.currencyGBP
        case .ils: return LocalizationKey.Settings.currencyILS
        case .rub: return LocalizationKey.Settings.currencyRUB
        case .jpy: return LocalizationKey.Settings.currencyJPY
        case .cad: return LocalizationKey.Settings.currencyCAD
        case .aud: return LocalizationKey.Settings.currencyAUD
        }
    }
}

private enum AppLanguageOption: String, CaseIterable, Identifiable {
    case english = "en"
    case hebrew = "he"
    case russian = "ru"

    static let defaultCode = "he"
    static let defaultCurrency = StorageKey.defaultCurrencyCode

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .english:
            return LocalizationKey.Settings.languageEnglish
        case .hebrew:
            return LocalizationKey.Settings.languageHebrew
        case .russian:
            return LocalizationKey.Settings.languageRussian
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
    let currencyCode: String
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
        .modelContainer(for: [Project.self, Expense.self, Invoice.self, Client.self], inMemory: true)
}

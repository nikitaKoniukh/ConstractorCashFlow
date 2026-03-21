# Android Migration Guide: ContractorCashFlow

A step-by-step guide to recreate the ContractorCashFlow iOS app as a native Android app using Kotlin, Jetpack Compose, and Room with Firebase Cloud Firestore for cross-device sync.

---

## Table of Contents

1. [Tech Stack Mapping](#1-tech-stack-mapping)
2. [Project Setup](#2-project-setup)
3. [Phase 1: Data Layer](#phase-1-data-layer)
4. [Phase 2: Navigation & App Shell](#phase-2-navigation--app-shell)
5. [Phase 3: Projects Feature](#phase-3-projects-feature)
6. [Phase 4: Expenses Feature](#phase-4-expenses-feature)
7. [Phase 5: Invoices Feature](#phase-5-invoices-feature)
8. [Phase 6: Clients Feature](#phase-6-clients-feature)
9. [Phase 7: Labor/Workers Feature](#phase-7-laborworkers-feature)
10. [Phase 8: Analytics/Charts](#phase-8-analyticscharts)
11. [Phase 9: Settings & Preferences](#phase-9-settings--preferences)
12. [Phase 10: Notifications](#phase-10-notifications)
13. [Phase 11: Data Export](#phase-11-data-export)
14. [Phase 12: Localization](#phase-12-localization)
15. [Phase 13: Cloud Sync](#phase-13-cloud-sync)
16. [Phase 14: Testing](#phase-14-testing)
17. [Appendix A: Complete Data Models](#appendix-a-complete-data-models)
18. [Appendix B: All Localization Strings](#appendix-b-all-localization-strings)
19. [Appendix C: Prompts for AI-Assisted Implementation](#appendix-c-prompts-for-ai-assisted-implementation)

---

## 1. Tech Stack Mapping

| iOS (Current) | Android (Target) |
|---|---|
| SwiftUI | Jetpack Compose |
| SwiftData (`@Model`) | Room Database (with `@Entity`) |
| CloudKit | Firebase Cloud Firestore |
| Swift Charts | Vico or MPAndroidChart (Compose-compatible) |
| `@Observable` / `@State` | ViewModel + StateFlow / `mutableStateOf` |
| `@Query` | Room `Flow<List<T>>` |
| `@AppStorage` (UserDefaults) | DataStore Preferences |
| `UNUserNotificationCenter` | WorkManager + NotificationCompat |
| `NavigationStack` / `NavigationPath` | Navigation Compose (`NavHost`) |
| `TabView` | `NavigationBar` (Material 3) |
| `Localizable.xcstrings` | `res/values/strings.xml` per locale |
| `LayoutDirection.rightToLeft` | Android automatic RTL via `android:supportsRtl` |
| `ShareLink` / `UIActivityViewController` | `Intent.ACTION_SEND` / `FileProvider` |
| `FileExporter` | `Intent.ACTION_CREATE_DOCUMENT` (SAF) |
| Bundle ID / Entitlements | `applicationId` in `build.gradle.kts` |

---

## 2. Project Setup

### 2.1 Create Project
1. Open Android Studio
2. New Project → Empty Activity (Compose)
3. Name: `ContractorCashFlow`
4. Package: `com.yetzira.contractorcashflow`
5. Minimum SDK: API 26 (Android 8.0)
6. Build configuration language: Kotlin DSL

### 2.2 Dependencies (`build.gradle.kts` app module)

```kotlin
dependencies {
    // Compose BOM
    val composeBom = platform("androidx.compose:compose-bom:2024.09.00")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.activity:activity-compose:1.9.2")

    // Navigation
    implementation("androidx.navigation:navigation-compose:2.8.0")

    // Room Database
    val roomVersion = "2.6.1"
    implementation("androidx.room:room-runtime:$roomVersion")
    implementation("androidx.room:room-ktx:$roomVersion")
    ksp("androidx.room:room-compiler:$roomVersion")

    // DataStore Preferences
    implementation("androidx.datastore:datastore-preferences:1.1.1")

    // ViewModel
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.5")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.5")

    // Charts (Vico)
    implementation("com.patrykandpatrick.vico:compose-m3:1.13.1")

    // WorkManager (Notifications)
    implementation("androidx.work:work-runtime-ktx:2.9.1")

    // Firebase (Cloud Sync)
    implementation(platform("com.google.firebase:firebase-bom:33.2.0"))
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")

    // Gson (JSON export)
    implementation("com.google.code.gson:gson:2.10.1")

    // Testing
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.8.1")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
}
```

### 2.3 Project Package Structure

```
com.yetzira.contractorcashflow/
├── data/
│   ├── local/
│   │   ├── AppDatabase.kt
│   │   ├── dao/
│   │   │   ├── ProjectDao.kt
│   │   │   ├── ExpenseDao.kt
│   │   │   ├── InvoiceDao.kt
│   │   │   ├── ClientDao.kt
│   │   │   └── LaborDetailsDao.kt
│   │   └── entity/
│   │       ├── ProjectEntity.kt
│   │       ├── ExpenseEntity.kt
│   │       ├── InvoiceEntity.kt
│   │       ├── ClientEntity.kt
│   │       └── LaborDetailsEntity.kt
│   ├── preferences/
│   │   └── UserPreferences.kt
│   └── repository/
│       ├── ProjectRepository.kt
│       ├── ExpenseRepository.kt
│       ├── InvoiceRepository.kt
│       ├── ClientRepository.kt
│       └── LaborRepository.kt
│
├── domain/
│   └── model/
│       ├── Project.kt
│       ├── Expense.kt
│       ├── Invoice.kt
│       ├── Client.kt
│       ├── LaborDetails.kt
│       ├── ExpenseCategory.kt
│       └── LaborType.kt
│
├── ui/
│   ├── navigation/
│   │   └── AppNavigation.kt
│   ├── theme/
│   │   ├── Color.kt
│   │   ├── Theme.kt
│   │   └── Type.kt
│   ├── projects/
│   │   ├── ProjectsListScreen.kt
│   │   ├── ProjectDetailScreen.kt
│   │   ├── NewProjectScreen.kt
│   │   ├── EditProjectScreen.kt
│   │   └── ProjectViewModel.kt
│   ├── expenses/
│   │   ├── ExpensesListScreen.kt
│   │   ├── NewExpenseScreen.kt
│   │   ├── EditExpenseScreen.kt
│   │   ├── ExpenseFiltersScreen.kt
│   │   └── ExpenseViewModel.kt
│   ├── invoices/
│   │   ├── InvoicesListScreen.kt
│   │   ├── NewInvoiceScreen.kt
│   │   ├── EditInvoiceScreen.kt
│   │   └── InvoiceViewModel.kt
│   ├── clients/
│   │   ├── ClientsListScreen.kt
│   │   ├── ClientDetailScreen.kt
│   │   ├── NewClientScreen.kt
│   │   ├── EditClientScreen.kt
│   │   └── ClientViewModel.kt
│   ├── labor/
│   │   ├── LaborListScreen.kt
│   │   ├── AddLaborScreen.kt
│   │   ├── EditLaborScreen.kt
│   │   ├── LaborFiltersScreen.kt
│   │   └── LaborViewModel.kt
│   ├── analytics/
│   │   ├── AnalyticsScreen.kt
│   │   └── AnalyticsViewModel.kt
│   ├── settings/
│   │   ├── SettingsScreen.kt
│   │   └── SettingsViewModel.kt
│   └── components/
│       ├── ExpenseRow.kt
│       ├── InvoiceRow.kt
│       ├── ProjectRow.kt
│       ├── ClientRow.kt
│       ├── WorkerCard.kt
│       ├── WorkerSummaryCard.kt
│       ├── FinancialSummaryCard.kt
│       ├── BudgetUtilizationBar.kt
│       └── EmptyStateView.kt
│
├── notification/
│   ├── NotificationService.kt
│   └── NotificationWorker.kt
│
├── sync/
│   └── FirestoreSyncService.kt
│
├── export/
│   └── DataExportService.kt
│
├── di/
│   └── AppModule.kt (if using Hilt)
│
└── ContractorCashFlowApp.kt (Application class)
    MainActivity.kt
```

---

## Phase 1: Data Layer

### Step 1.1: Define Enums

```kotlin
// ExpenseCategory.kt
enum class ExpenseCategory(val displayName: String) {
    MATERIALS("Materials"),
    LABOR("Labor"),
    EQUIPMENT("Equipment"),
    SUBCONTRACTOR("Subcontractor"),
    MISC("Miscellaneous");

    val iconResId: Int get() = when (this) {
        MATERIALS -> R.drawable.ic_hammer
        LABOR -> R.drawable.ic_person
        EQUIPMENT -> R.drawable.ic_wrench
        SUBCONTRACTOR -> R.drawable.ic_people
        MISC -> R.drawable.ic_more
    }

    val chartColor: Color get() = when (this) {
        MATERIALS -> Color.Blue
        LABOR -> Color(0xFFFF9800) // Orange
        EQUIPMENT -> Color.Gray
        SUBCONTRACTOR -> Color(0xFF009688) // Teal
        MISC -> Color(0xFF9C27B0) // Purple
    }
}

// LaborType.kt
enum class LaborType(val displayName: String) {
    HOURLY("Hourly"),
    DAILY("Daily"),
    CONTRACT("Contract"),
    SUBCONTRACTOR("Subcontractor");

    val usesQuantity: Boolean get() = this == HOURLY || this == DAILY

    val rateSuffix: String get() = when (this) {
        HOURLY -> "/hr"
        DAILY -> "/day"
        CONTRACT, SUBCONTRACTOR -> ""
    }
}
```

### Step 1.2: Define Room Entities

```kotlin
// ProjectEntity.kt
@Entity(tableName = "projects")
data class ProjectEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String = "",
    val clientName: String = "",
    val budget: Double = 0.0,
    val createdDate: Long = System.currentTimeMillis(),
    val isActive: Boolean = true
)

// ExpenseEntity.kt
@Entity(
    tableName = "expenses",
    foreignKeys = [
        ForeignKey(
            entity = ProjectEntity::class,
            parentColumns = ["id"],
            childColumns = ["projectId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = LaborDetailsEntity::class,
            parentColumns = ["id"],
            childColumns = ["workerId"],
            onDelete = ForeignKey.SET_NULL
        )
    ],
    indices = [Index("projectId"), Index("workerId")]
)
data class ProjectEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val category: String = ExpenseCategory.MISC.name,
    val amount: Double = 0.0,
    val descriptionText: String = "",
    val date: Long = System.currentTimeMillis(),
    val projectId: String? = null,
    val workerId: String? = null,
    val unitsWorked: Double? = null
)

// InvoiceEntity.kt
@Entity(
    tableName = "invoices",
    foreignKeys = [
        ForeignKey(
            entity = ProjectEntity::class,
            parentColumns = ["id"],
            childColumns = ["projectId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("projectId")]
)
data class InvoiceEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val amount: Double = 0.0,
    val dueDate: Long = System.currentTimeMillis(),
    val isPaid: Boolean = false,
    val clientName: String = "",
    val createdDate: Long = System.currentTimeMillis(),
    val projectId: String? = null
)

// ClientEntity.kt
@Entity(tableName = "clients")
data class ClientEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String = "",
    val email: String? = null,
    val phone: String? = null,
    val address: String? = null,
    val notes: String? = null
)

// LaborDetailsEntity.kt
@Entity(tableName = "labor_details")
data class LaborDetailsEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val workerName: String = "",
    val laborType: String = LaborType.HOURLY.name,
    val rate: Double? = null,
    val notes: String? = null,
    val createdDate: Long = System.currentTimeMillis()
)
```

### Step 1.3: Define DAOs

```kotlin
// ProjectDao.kt
@Dao
interface ProjectDao {
    @Query("SELECT * FROM projects ORDER BY createdDate DESC")
    fun getAllProjects(): Flow<List<ProjectEntity>>

    @Query("SELECT * FROM projects WHERE id = :id")
    suspend fun getProjectById(id: String): ProjectEntity?

    @Query("SELECT * FROM projects WHERE name LIKE '%' || :query || '%' OR clientName LIKE '%' || :query || '%' ORDER BY createdDate DESC")
    fun searchProjects(query: String): Flow<List<ProjectEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(project: ProjectEntity)

    @Update
    suspend fun update(project: ProjectEntity)

    @Delete
    suspend fun delete(project: ProjectEntity)
}

// ExpenseDao.kt
@Dao
interface ExpenseDao {
    @Query("SELECT * FROM expenses ORDER BY date DESC")
    fun getAllExpenses(): Flow<List<ExpenseEntity>>

    @Query("SELECT * FROM expenses WHERE projectId = :projectId ORDER BY date DESC")
    fun getExpensesForProject(projectId: String): Flow<List<ExpenseEntity>>

    @Query("SELECT * FROM expenses WHERE workerId = :workerId ORDER BY date DESC")
    fun getExpensesForWorker(workerId: String): Flow<List<ExpenseEntity>>

    @Query("SELECT SUM(amount) FROM expenses WHERE projectId = :projectId")
    fun getTotalExpensesForProject(projectId: String): Flow<Double?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(expense: ExpenseEntity)

    @Update
    suspend fun update(expense: ExpenseEntity)

    @Delete
    suspend fun delete(expense: ExpenseEntity)
}

// Create similar DAOs for Invoice, Client, LaborDetails
```

### Step 1.4: Define Room Database

```kotlin
@Database(
    entities = [
        ProjectEntity::class,
        ExpenseEntity::class,
        InvoiceEntity::class,
        ClientEntity::class,
        LaborDetailsEntity::class
    ],
    version = 1,
    exportSchema = true
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun projectDao(): ProjectDao
    abstract fun expenseDao(): ExpenseDao
    abstract fun invoiceDao(): InvoiceDao
    abstract fun clientDao(): ClientDao
    abstract fun laborDetailsDao(): LaborDetailsDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "contractor_cashflow_db"
                ).build().also { INSTANCE = it }
            }
        }
    }
}
```

### Step 1.5: Define DataStore Preferences

```kotlin
// UserPreferences.kt
object PreferenceKeys {
    val APP_LANGUAGE = stringPreferencesKey("app_language")
    val CURRENCY_CODE = stringPreferencesKey("selected_currency_code")
    val INVOICE_REMINDERS = booleanPreferencesKey("invoice_reminders_enabled")
    val OVERDUE_ALERTS = booleanPreferencesKey("overdue_alerts_enabled")
    val BUDGET_WARNINGS = booleanPreferencesKey("budget_warnings_enabled")
}

class UserPreferencesRepository(private val dataStore: DataStore<Preferences>) {
    val language: Flow<String> = dataStore.data.map { it[PreferenceKeys.APP_LANGUAGE] ?: "en" }
    val currencyCode: Flow<String> = dataStore.data.map { it[PreferenceKeys.CURRENCY_CODE] ?: "USD" }
    val invoiceReminders: Flow<Boolean> = dataStore.data.map { it[PreferenceKeys.INVOICE_REMINDERS] ?: true }
    val overdueAlerts: Flow<Boolean> = dataStore.data.map { it[PreferenceKeys.OVERDUE_ALERTS] ?: true }
    val budgetWarnings: Flow<Boolean> = dataStore.data.map { it[PreferenceKeys.BUDGET_WARNINGS] ?: true }

    suspend fun setLanguage(lang: String) { dataStore.edit { it[PreferenceKeys.APP_LANGUAGE] = lang } }
    suspend fun setCurrencyCode(code: String) { dataStore.edit { it[PreferenceKeys.CURRENCY_CODE] = code } }
    suspend fun setInvoiceReminders(enabled: Boolean) { dataStore.edit { it[PreferenceKeys.INVOICE_REMINDERS] = enabled } }
    suspend fun setOverdueAlerts(enabled: Boolean) { dataStore.edit { it[PreferenceKeys.OVERDUE_ALERTS] = enabled } }
    suspend fun setBudgetWarnings(enabled: Boolean) { dataStore.edit { it[PreferenceKeys.BUDGET_WARNINGS] = enabled } }
}
```

---

## Phase 2: Navigation & App Shell

### Step 2.1: Define Tab Navigation

```kotlin
// AppNavigation.kt
enum class AppTab(val route: String, val labelResId: Int, val iconResId: Int) {
    PROJECTS("projects", R.string.tab_projects, R.drawable.ic_folder),
    EXPENSES("expenses", R.string.tab_expenses, R.drawable.ic_dollar),
    INVOICES("invoices", R.string.tab_invoices, R.drawable.ic_receipt),
    LABOR("labor", R.string.tab_labor, R.drawable.ic_people),
    CLIENTS("clients", R.string.tab_clients, R.drawable.ic_contacts),
    ANALYTICS("analytics", R.string.tab_analytics, R.drawable.ic_chart),
    SETTINGS("settings", R.string.tab_settings, R.drawable.ic_settings)
}
```

### Step 2.2: Build Main Activity with Bottom Navigation

Build a `Scaffold` with `NavigationBar` (7 tabs) and a `NavHost` for each tab's content. Each tab should maintain its own back stack using `NavGraphBuilder.navigation()`.

---

## Phase 3: Projects Feature

### Step 3.1: Projects List Screen
- Query all projects sorted by `createdDate DESC`
- Search bar filtering by `name` OR `clientName` (case-insensitive)
- FAB button to add new project
- Each row displays: name, client name, active status (green dot), total expenses (red), total income (green), net balance (color-coded)
- Swipe-to-delete with cascade deletion of expenses and invoices
- Tap row to navigate to project detail

### Step 3.2: Project Detail Screen
Sections (in a scrollable column):
1. **Financial Summary Card**: Net balance (large), income, expenses, profit margin %
2. **Project Information**: name, client name (clickable to client detail), budget, status, created date
3. **Budget Utilization**: progress bar (green <50%, orange 50-80%, red >80%), spent/remaining amounts
4. **Expense Category Chart**: horizontal bars grouped by category with percentages
5. **Expenses List**: sorted by date DESC, tap to edit, swipe to delete, "Add Expense" button
6. **Invoices List**: sorted by createdDate DESC, status badges (Paid=green, Overdue=red, Pending=orange), paid count, swipe to delete, "Add Invoice" button
7. **Toolbar menu**: Edit Project, Export & Share, Add Expense, Add Invoice

### Step 3.3: New Project Screen
Form fields:
- Project name (required)
- Client selection: toggle between "Enter Name" and "Select Existing" (picker of existing clients)
- If entering new name and client doesn't exist: optional expandable section for email, phone, address, notes (auto-creates Client record on save)
- Duplicate client name warning
- Budget input (decimal keyboard)

Validation: name not empty, clientName not empty, budget > 0

### Step 3.4: Edit Project Screen
Same form as New, pre-populated. Shows read-only stats (created date, total expenses, total income). Alert if reducing budget below current expenses.

### Step 3.5: Project Export
Options: include expenses toggle, include invoices toggle. Generates formatted plain text with all project data. Share via Android share intent.

---

## Phase 4: Expenses Feature

### Step 4.1: Expenses List Screen
- Query all expenses sorted by `date DESC`
- Search bar filtering by `descriptionText`
- Filter button (filled icon if active) opening filter bottom sheet
- FAB to add new expense
- Each row: description (bold), category badge (blue), project name (if any), date, amount (red)
- Tap to edit, swipe to delete
- Empty state with illustration and "Add Expense" CTA

### Step 4.2: Expense Filters Bottom Sheet
- Category picker (All / Materials / Labor / Equipment / Subcontractor / Miscellaneous)
- Date range: toggle + date pickers for start/end
- "Clear All Filters" button

### Step 4.3: New Expense Screen
Form:
- Category picker
- If Labor category AND workers exist:
  - Worker picker (shows name + rate)
  - On selection: auto-fill description as "Labor: {workerName}"
  - If worker is hourly/daily: show quantity input, auto-calculate amount = rate * units
  - If worker is contract/subcontractor: show fixed rate, auto-fill amount = rate
- Amount input (decimal)
- Description text field
- Date picker
- Project assignment picker (active projects only, optional)

Post-save: trigger budget check notification if project assigned

### Step 4.4: Edit Expense Screen
Same form as New, pre-populated with existing values. Updates in-place.

---

## Phase 5: Invoices Feature

### Step 5.1: Invoices List Screen
- Query all invoices sorted by `createdDate DESC`
- Search by `clientName`
- Status filter menu: All, Paid, Unpaid, Overdue
  - Paid: `isPaid == true`
  - Unpaid: `!isPaid && dueDate >= now`
  - Overdue: `!isPaid && dueDate < now`
- FAB to add new invoice
- Each row: client name (headline), status badge, project name (if any), due date, amount (green if paid)
- Tap to navigate to edit
- Swipe to delete (cancel notifications)

### Step 5.2: New Invoice Screen
Form:
- Client selection (same "Enter Name" / "Select Existing" pattern as projects)
- Amount input
- Due date picker (default: +30 days)
- Paid toggle (default: off)
- Project assignment picker (optional)

Post-save: schedule reminder notification (3 days before) and overdue alert (1 day after)

### Step 5.3: Edit Invoice Screen
Same form, pre-populated. Plus:
- Delete button at bottom (destructive)
- When toggling paid ON: cancel all notifications for this invoice
- When toggling paid OFF: reschedule notifications

---

## Phase 6: Clients Feature

### Step 6.1: Clients List Screen
- Query all clients sorted by `name ASC`
- Search by name, email, or phone
- FAB to add new client
- Each row: name (headline), email (if present, with icon), phone (if present, with icon)
- Tap to navigate to client detail
- Swipe to delete

### Step 6.2: Client Detail Screen
Sections:
- Contact info: name, email, phone, address
- Notes section (if not empty)
- Toolbar: Edit button

### Step 6.3: New Client Screen
Form: name (required), email (optional, email keyboard), phone (optional, phone keyboard), address (optional, multiline), notes (optional, multiline)

### Step 6.4: Edit Client Screen
Same form, pre-populated. Save button disabled if no changes. Empty optional fields saved as null.

---

## Phase 7: Labor/Workers Feature

### Step 7.1: Labor List Screen
- Query all workers
- Search by `workerName` or `notes`
- Filter button opening filter bottom sheet
- Sort menu: Recently Added, Worker Name, Total Earned (High/Low)
- FAB to add new worker
- **Worker Summary Card** at top: total labor cost, worker count, days worked, avg daily cost, total hours (filtered by selected month or all time)
- Each worker card: name + type, total earned, rate with suffix, days worked, units worked, associated projects (comma-separated), notes (2-line limit)
- Tap to edit, swipe to delete (with confirmation)

### Step 7.2: Labor Filters Bottom Sheet
- Labor Type picker (All / Hourly / Daily / Contract / Subcontractor)
- Project filter picker
- Month filter: toggle + month/year picker (last 12 months)
- Clear All button

### Step 7.3: Add Labor Screen
Form:
- Worker name (required) + duplicate name warning
- Labor type picker
- Rate input (decimal), label changes by type ("Rate per Hour", "Rate per Day", "Contract Price")
- Notes (optional, multiline)

### Step 7.4: Edit Labor Screen
Same form, pre-populated. Plus:
- Stats section (if has linked expenses): total earned, total hours/days, days worked, associated projects
- Delete button with confirmation dialog
  - Shows count of linked expenses in warning
  - On delete: expenses preserved but worker link removed (nullified)

---

## Phase 8: Analytics/Charts

### Step 8.1: Analytics Screen Layout
Scrollable column with 3 chart cards on grouped background.

### Step 8.2: Income vs Expenses (Donut Chart)
- Data: sum all paid invoice amounts (income), sum all expense amounts
- Chart: donut/ring chart, green for income, red for expenses
- Center text: net balance (bold, green if positive, red if negative)
- Legend below: income amount, expenses amount
- Empty state: icon + "No financial data" message

### Step 8.3: Expenses by Category (Horizontal Bar Chart)
- Data: group all expenses by category, sum amounts, calculate percentages
- Chart: horizontal bars, color per category (blue/orange/gray/teal/purple)
- Labels: category name with colored dot on Y-axis
- Annotations: percentage at end of each bar
- Sorted by amount descending
- Empty state: icon + "No expense data"

### Step 8.4: Budget Utilization per Project (Grouped Bar Chart)
- Data: projects with budget > 0, max 10 projects
- Per project: spent (totalExpenses) bar in orange, remaining (max(0, budget - spent)) bar in light blue
- X-axis: currency format
- Y-axis: project names
- Legend: Spent (orange), Remaining (blue)
- Summary: "Average Utilization: X%" with color coding (green <50%, orange 50-80%, red >80%)
- Empty state: icon + "No project data"

---

## Phase 9: Settings & Preferences

### Step 9.1: Settings Screen
Form/list sections:
1. **Language**: Picker with English / Hebrew (עברית) / Russian (Русский). On change, update locale and recreate activity.
2. **Currency**: Picker with 8 options: USD ($), EUR (€), GBP (£), ILS (₪), RUB (₽), JPY (¥), CAD (C$), AUD (A$).
3. **Notifications**: Three toggle switches — Invoice Reminders, Overdue Alerts, Budget Warnings. On change, reschedule all relevant notifications.
4. **Data Export**: "Export Data" button that generates JSON file.
5. **About**: App name, version (versionName.versionCode from BuildConfig).

### Step 9.2: Currency Formatting
Use `java.text.NumberFormat.getCurrencyInstance()` with the selected currency code throughout the app.

---

## Phase 10: Notifications

### Step 10.1: Notification Channels
Create on app startup:
- `invoice_reminders` — Invoice Reminders (default importance)
- `invoice_overdue` — Overdue Alerts (high importance)
- `budget_warnings` — Budget Warnings (high importance)

### Step 10.2: Invoice Reminders
- **Upcoming reminder**: scheduled 3 days before `dueDate`
  - Title: "Invoice Due Soon"
  - Body: "Invoice for {clientName} ({amount}) is due in 3 days"
  - Channel: `invoice_reminders`
  - Use `AlarmManager.setExactAndAllowWhileIdle()` or WorkManager

- **Overdue alert**: scheduled 1 day after `dueDate`
  - Title: "Invoice Overdue"
  - Body: "Invoice for {clientName} ({amount}) is now overdue"
  - Channel: `invoice_overdue`

### Step 10.3: Budget Warnings
Triggered immediately when an expense is saved and project reaches threshold:
- **80% threshold**: Title "Budget Warning: 80%", default sound
- **100% threshold**: Title "Budget Alert: 100%", high priority

### Step 10.4: Notification Management
- Cancel invoice notifications when marked as paid
- Reschedule when marked unpaid
- Reschedule all when notification settings toggle changes
- Check for duplicate notifications before scheduling

---

## Phase 11: Data Export

### Step 11.1: JSON Export Structure
```json
{
  "exportedAt": "2026-03-16T12:00:00Z",
  "preferences": {
    "languageCode": "en",
    "currencyCode": "USD",
    "invoiceRemindersEnabled": true,
    "overdueAlertsEnabled": true,
    "budgetWarningsEnabled": true
  },
  "projects": [
    {
      "id": "uuid",
      "name": "Kitchen Remodel",
      "clientName": "John Smith",
      "budget": 15000.0,
      "createdDate": "2026-01-15T00:00:00Z",
      "isActive": true,
      "totalExpenses": 6000.0,
      "totalIncome": 7500.0,
      "balance": 1500.0
    }
  ],
  "expenses": [...],
  "invoices": [...],
  "clients": [...]
}
```

### Step 11.2: Implementation
Use Gson with `setPrettyPrinting()` and ISO 8601 date format. Write to file via `Intent.ACTION_CREATE_DOCUMENT` (Storage Access Framework). Filename: `ContractorCashFlow_Export_{date}.json`.

---

## Phase 12: Localization

### Step 12.1: String Resources Structure
```
res/
├── values/           (English - default)
│   └── strings.xml
├── values-he/        (Hebrew)
│   └── strings.xml
└── values-ru/        (Russian)
    └── strings.xml
```

### Step 12.2: RTL Support
In `AndroidManifest.xml`:
```xml
<application android:supportsRtl="true" ... >
```
Android handles RTL layout automatically for Hebrew when the locale is set. Use `start`/`end` instead of `left`/`right` in all layouts.

### Step 12.3: Runtime Language Switching
Use `AppCompatDelegate.setApplicationLocales()` (AndroidX) or recreate the activity with the new locale configuration. Store selected language in DataStore.

### Step 12.4: Complete String Keys
See [Appendix B](#appendix-b-all-localization-strings) for every string that needs translation.

---

## Phase 13: Cloud Sync

### Step 13.1: Firebase Setup
1. Create Firebase project at console.firebase.google.com
2. Add Android app with package `com.yetzira.contractorcashflow`
3. Download `google-services.json` to `app/` directory
4. Enable Firestore Database in Firebase Console
5. Enable Firebase Authentication (Google Sign-In or Anonymous)

### Step 13.2: Firestore Data Structure
```
users/{userId}/
├── projects/{projectId}     → ProjectEntity fields
├── expenses/{expenseId}     → ExpenseEntity fields
├── invoices/{invoiceId}     → InvoiceEntity fields
├── clients/{clientId}       → ClientEntity fields
└── laborDetails/{laborId}   → LaborDetailsEntity fields
```

### Step 13.3: Sync Strategy
1. **Local-first**: Room is the source of truth. All reads come from Room.
2. **Write-through**: On every Room insert/update/delete, also write to Firestore.
3. **Pull on launch**: On app start (and periodically), fetch Firestore data and merge into Room.
4. **Conflict resolution**: Last-write-wins using a `lastModified` timestamp on each entity.
5. **Offline support**: Firestore has built-in offline persistence — writes queue when offline and sync when online.

### Step 13.4: Authentication
Use Firebase Auth with Google Sign-In to identify the user. All Firestore data lives under `users/{userId}/` for isolation.

---

## Phase 14: Testing

### Step 14.1: Unit Tests (JUnit + Coroutines Test)
Mirror the iOS test suites:

| Suite | Tests | What to Test |
|-------|-------|--------------|
| ProjectModelTests | 7 | Init defaults, totalExpenses, totalIncome, balance, profitMargin, budgetUtilization |
| ExpenseModelTests | 3 | Init, category enum, project relationship |
| InvoiceModelTests | 4 | Init, isOverdue logic |
| ClientModelTests | 2 | Full and minimal init |
| CurrencyFormattingTests | 3 | Positive, zero, large amounts |
| DateCalculationTests | 2 | Comparisons, formatting |
| PercentageCalculationTests | 3 | Valid, zero denominator, over 100% |
| InputValidationTests | 3 | Empty strings, positive numbers, email format |
| BusinessLogicTests | 3 | Profitability, over-budget, payment status |
| EdgeCaseTests | 5 | Empty data, zero amounts, boundary dates, large values, special chars |

### Step 14.2: Room Database Tests
Use `Room.inMemoryDatabaseBuilder()` for DAO tests verifying insert, query, update, delete, cascade behavior.

### Step 14.3: UI Tests (Compose Test)
Use `composeTestRule` to verify each screen renders, forms validate, navigation works.

---

## Appendix A: Complete Data Models

### Relationship Map
```
┌─────────────┐       ┌─────────────┐       ┌──────────────┐
│   Project    │───1:N─│   Expense   │───N:1─│ LaborDetails │
│              │       │             │       │   (Worker)   │
│  id (PK)     │       │  id (PK)    │       │              │
│  name        │       │  category   │       │  id (PK)     │
│  clientName  │       │  amount     │       │  workerName  │
│  budget      │       │  description│       │  laborType   │
│  createdDate │       │  date       │       │  rate         │
│  isActive    │       │  unitsWorked│       │  notes       │
│              │       │  projectId? │       │  createdDate │
│              │       │  workerId?  │       │              │
└──────┬──────┘       └─────────────┘       └──────────────┘
       │
       │1:N
       │
┌──────┴──────┐       ┌─────────────┐
│   Invoice   │       │   Client    │
│             │       │             │
│  id (PK)    │       │  id (PK)    │
│  amount     │       │  name       │
│  dueDate    │       │  email?     │
│  isPaid     │       │  phone?     │
│  clientName │       │  address?   │
│  createdDate│       │  notes?     │
│  projectId? │       └─────────────┘
└─────────────┘
```

### Delete Rules
- Delete Project → CASCADE delete all its Expenses and Invoices
- Delete LaborDetails → SET NULL on `workerId` in Expenses (expenses preserved, worker link removed)
- Client is linked by name (string match), not foreign key

### Computed Properties to Implement in ViewModel/Repository

```kotlin
// For a Project:
fun totalExpenses(expenses: List<ExpenseEntity>): Double =
    expenses.filter { it.projectId == project.id }.sumOf { it.amount }

fun totalIncome(invoices: List<InvoiceEntity>): Double =
    invoices.filter { it.projectId == project.id && it.isPaid }.sumOf { it.amount }

fun balance() = totalIncome - totalExpenses

fun profitMargin(): Double =
    if (totalIncome > 0) ((totalIncome - totalExpenses) / totalIncome) * 100 else 0.0

fun budgetUtilization(): Double =
    if (budget > 0) (totalExpenses / budget) * 100 else 0.0

// For an Invoice:
fun isOverdue(): Boolean = !isPaid && dueDate < System.currentTimeMillis()

// For a LaborDetails:
fun totalAmountEarned(expenses: List<ExpenseEntity>): Double =
    expenses.filter { it.workerId == labor.id }.sumOf { it.amount }

fun totalUnitsWorked(expenses: List<ExpenseEntity>): Double =
    expenses.filter { it.workerId == labor.id }.mapNotNull { it.unitsWorked }.sum()

fun totalDaysWorked(expenses: List<ExpenseEntity>): Int {
    val calendar = Calendar.getInstance()
    return expenses.filter { it.workerId == labor.id }
        .map { calendar.apply { timeInMillis = it.date }; Triple(get(YEAR), get(MONTH), get(DAY_OF_MONTH)) }
        .toSet().size
}
```

---

## Appendix B: All Localization Strings

Below is the complete list of string keys needed. Create matching entries in `values/strings.xml`, `values-he/strings.xml`, and `values-ru/strings.xml`.

```xml
<!-- Tabs -->
<string name="tab_projects">Projects</string>
<string name="tab_expenses">Expenses</string>
<string name="tab_invoices">Invoices</string>
<string name="tab_clients">Clients</string>
<string name="tab_labor">Labor</string>
<string name="tab_analytics">Analytics</string>
<string name="tab_settings">Settings</string>

<!-- Dashboard -->
<string name="dashboard_title">Dashboard</string>
<string name="dashboard_total_balance">Total Balance</string>
<string name="dashboard_income">Income</string>
<string name="dashboard_expenses">Expenses</string>

<!-- Projects -->
<string name="project_title">Projects</string>
<string name="project_add">Add Project</string>
<string name="project_name">Project Name</string>
<string name="project_client_name">Client Name</string>
<string name="project_budget">Budget</string>
<string name="project_information">Project Information</string>
<string name="project_active">Active</string>
<string name="project_new_title">New Project</string>
<string name="project_detail_title">Project Details</string>
<string name="project_empty">No Projects</string>
<string name="project_empty_description">No projects yet. Start tracking your work</string>
<string name="project_balance">Balance</string>

<!-- Expenses -->
<string name="expense_title">Expenses</string>
<string name="expense_add">Add Expense</string>
<string name="expense_amount">Amount</string>
<string name="expense_category">Category</string>
<string name="expense_description">Description</string>
<string name="expense_date">Date</string>
<string name="expense_details">Expense Details</string>
<string name="expense_project">Project</string>
<string name="expense_project_optional">Project (Optional)</string>
<string name="expense_none">None</string>
<string name="expense_new_title">New Expense</string>
<string name="expense_empty">No Expenses</string>
<string name="expense_empty_description">No expenses recorded yet. Start tracking your project costs</string>
<string name="expense_category_materials">Materials</string>
<string name="expense_category_labor">Labor</string>
<string name="expense_category_equipment">Equipment</string>
<string name="expense_category_subcontractor">Subcontractor</string>
<string name="expense_category_miscellaneous">Miscellaneous</string>

<!-- Invoices -->
<string name="invoice_title">Invoices</string>
<string name="invoice_add">Add Invoice</string>
<string name="invoice_amount">Amount</string>
<string name="invoice_due_date">Due Date</string>
<string name="invoice_client_name">Client Name</string>
<string name="invoice_details">Invoice Details</string>
<string name="invoice_project">Project</string>
<string name="invoice_project_optional">Project (Optional)</string>
<string name="invoice_none">None</string>
<string name="invoice_new_title">New Invoice</string>
<string name="invoice_edit_title">Edit Invoice</string>
<string name="invoice_due_prefix">Due</string>
<string name="invoice_empty">No Invoices</string>
<string name="invoice_empty_description">No invoices created yet</string>
<string name="invoice_status_paid">Paid</string>
<string name="invoice_status_unpaid">Unpaid</string>
<string name="invoice_status_overdue">Overdue</string>
<string name="invoice_status_pending">Pending</string>

<!-- Clients -->
<string name="client_title">Clients</string>
<string name="client_add">Add Client</string>
<string name="client_name">Name</string>
<string name="client_email">Email</string>
<string name="client_phone">Phone</string>
<string name="client_address">Address</string>
<string name="client_notes">Notes</string>
<string name="client_information">Client Information</string>
<string name="client_new_title">New Client</string>
<string name="client_edit_title">Edit Client</string>
<string name="client_empty">No Clients</string>
<string name="client_empty_description">No clients added yet</string>

<!-- Labor -->
<string name="labor_title">Labor</string>
<string name="labor_add">Add Worker</string>
<string name="labor_add_title">Add Worker</string>
<string name="labor_edit_title">Edit Worker</string>
<string name="labor_delete_label">Delete Worker</string>
<string name="labor_basic_info">Basic Information</string>
<string name="labor_worker_name_placeholder">Worker Name</string>
<string name="labor_type_label">Worker Type</string>
<string name="labor_type_hourly">Hourly</string>
<string name="labor_type_daily">Daily</string>
<string name="labor_type_contract">Contract</string>
<string name="labor_type_subcontractor">Subcontractor</string>
<string name="labor_default_rate">Rate</string>
<string name="labor_default_rate_hint">Enter rate</string>
<string name="labor_rate_per_hour">Rate per Hour</string>
<string name="labor_rate_per_day">Rate per Day</string>
<string name="labor_contract_price">Contract Price</string>
<string name="labor_hours_worked_label">Hours Worked</string>
<string name="labor_days_worked_label">Days Worked</string>
<string name="labor_calculated_total">Calculated Total</string>
<string name="labor_notes_label">Notes</string>
<string name="labor_notes_placeholder">Add notes about this worker...</string>
<string name="labor_worker_stats">Worker Statistics</string>
<string name="labor_total_earned">Total Earned</string>
<string name="labor_total_hours">Total Hours</string>
<string name="labor_total_days_worked">Days Worked</string>
<string name="labor_total_days_label">Total Days</string>
<string name="labor_total_workers">Total Workers</string>
<string name="labor_associated_projects">Associated Projects</string>
<string name="labor_created_date">Created</string>
<string name="labor_select_worker">Select Worker</string>
<string name="labor_select_worker_prompt">Choose a worker</string>
<string name="labor_search_prompt">Search worker name or notes</string>
<string name="labor_no_labor">No Workers</string>
<string name="labor_no_labor_description">No workers added yet. Start managing your team</string>
<string name="labor_sort_recently_added">Recently Added</string>
<string name="labor_sort_worker_name">Worker Name</string>
<string name="labor_sort_amount_high">Amount: High to Low</string>
<string name="labor_sort_amount_low">Amount: Low to High</string>
<string name="labor_filters">Filters</string>
<string name="labor_all_types">All Types</string>
<string name="labor_clear_filters">Clear Filters</string>
<string name="labor_all_projects">All Projects</string>
<string name="labor_filter_by_month">Filter by Month</string>
<string name="labor_total_labor_cost">Total Labor Cost</string>
<string name="labor_avg_daily_cost">Avg. Daily Cost</string>
<string name="labor_summary_all_time">All Time</string>
<string name="labor_rate_suffix_hourly">/hr</string>
<string name="labor_rate_suffix_daily">/day</string>
<string name="labor_unit_hours">hours</string>
<string name="labor_unit_days">days</string>

<!-- Settings -->
<string name="settings_title">Settings</string>
<string name="settings_language">Language</string>
<string name="settings_language_footer">Select your preferred language</string>
<string name="settings_currency">Currency</string>
<string name="settings_currency_footer">Currency used for all amounts</string>
<string name="settings_notifications">Notifications</string>
<string name="settings_invoice_reminders">Invoice Reminders</string>
<string name="settings_overdue_alerts">Overdue Alerts</string>
<string name="settings_budget_warnings">Budget Warnings</string>
<string name="settings_export_data">Export Data</string>
<string name="settings_export_footer">Export all data as JSON file</string>
<string name="settings_about">About</string>
<string name="settings_app_version">App Version</string>

<!-- Analytics -->
<string name="analytics_title">Analytics</string>
<string name="analytics_income_vs_expenses">Income vs. Expenses</string>
<string name="analytics_expenses_by_category">Expenses by Category</string>
<string name="analytics_budget_utilization">Budget Utilization</string>
<string name="analytics_net_balance">Net Balance</string>
<string name="analytics_income">Income</string>
<string name="analytics_expenses">Expenses</string>
<string name="analytics_average_utilization">Average Utilization</string>
<string name="analytics_no_financial_data">No financial data yet</string>
<string name="analytics_no_expense_data">No expense data yet</string>
<string name="analytics_no_project_data">No project data yet</string>
<string name="analytics_spent">Spent</string>
<string name="analytics_remaining">Remaining</string>

<!-- Actions -->
<string name="action_save">Save</string>
<string name="action_cancel">Cancel</string>
<string name="action_delete">Delete</string>
<string name="action_edit">Edit</string>
<string name="action_done">Done</string>
<string name="action_add">Add</string>
<string name="action_search">Search</string>
<string name="action_ok">OK</string>

<!-- General -->
<string name="error_generic">An error occurred</string>
```

---

## Appendix C: Prompts for AI-Assisted Implementation

Use these prompts sequentially with an AI coding assistant to build each feature. Each prompt is self-contained and references the exact behavior from the iOS app.

---

### Prompt 1: Project Setup

```
Create a new Android project "ContractorCashFlow" using Jetpack Compose with Material 3.
Package name: com.yetzira.contractorcashflow. Minimum SDK: 26.

Set up the following dependencies in build.gradle.kts (app):
- Jetpack Compose BOM (latest stable)
- Navigation Compose
- Room (with KSP)
- DataStore Preferences
- Lifecycle ViewModel Compose
- Vico charts library for Compose
- WorkManager
- Firebase BOM + Firestore + Auth
- Gson
- Testing: JUnit, Coroutines Test, Compose UI Test

Create the package structure:
data/local/dao/, data/local/entity/, data/preferences/, data/repository/
domain/model/
ui/navigation/, ui/theme/, ui/projects/, ui/expenses/, ui/invoices/,
ui/clients/, ui/labor/, ui/analytics/, ui/settings/, ui/components/
notification/, sync/, export/

Build the project and verify it compiles.
```

---

### Prompt 2: Data Layer - Entities & Database

```
Create the Room database for ContractorCashFlow with these 5 entities:

1. ProjectEntity: id (String PK, UUID), name (String, default ""), clientName (String, default ""),
   budget (Double, default 0.0), createdDate (Long, millis), isActive (Boolean, default true)

2. ExpenseEntity: id (String PK, UUID), category (String, default "MISC"), amount (Double, default 0.0),
   descriptionText (String, default ""), date (Long, millis), projectId (String?, FK to projects CASCADE),
   workerId (String?, FK to labor_details SET_NULL), unitsWorked (Double?)

3. InvoiceEntity: id (String PK, UUID), amount (Double, default 0.0), dueDate (Long, millis),
   isPaid (Boolean, default false), clientName (String, default ""), createdDate (Long, millis),
   projectId (String?, FK to projects CASCADE)

4. ClientEntity: id (String PK, UUID), name (String, default ""), email (String?), phone (String?),
   address (String?), notes (String?)

5. LaborDetailsEntity: id (String PK, UUID), workerName (String, default ""), laborType (String, default "HOURLY"),
   rate (Double?), notes (String?), createdDate (Long, millis)

Create DAOs for each entity with:
- getAllX() returning Flow<List<XEntity>> sorted appropriately
- getXById(id) returning suspend XEntity?
- searchX(query) returning Flow with LIKE matching on relevant fields
- insert, update, delete operations
- For expenses: getExpensesForProject(projectId), getExpensesForWorker(workerId)
- For invoices: getInvoicesForProject(projectId), getUnpaidInvoices()

Create AppDatabase class with all 5 DAOs and a singleton companion object.
Create the two enums: ExpenseCategory (MATERIALS, LABOR, EQUIPMENT, SUBCONTRACTOR, MISC)
and LaborType (HOURLY, DAILY, CONTRACT, SUBCONTRACTOR) with display names, icon resources,
colors (for charts), usesQuantity boolean, and rateSuffix strings.
```

---

### Prompt 3: DataStore Preferences

```
Create a UserPreferencesRepository using Jetpack DataStore Preferences for ContractorCashFlow.

Preference keys and defaults:
- app_language: String, default "en" (options: "en", "he", "ru")
- selected_currency_code: String, default "USD" (options: USD, EUR, GBP, ILS, RUB, JPY, CAD, AUD)
- invoice_reminders_enabled: Boolean, default true
- overdue_alerts_enabled: Boolean, default true
- budget_warnings_enabled: Boolean, default true

Each preference should have:
- A Flow<T> getter for reactive reading
- A suspend setter function

Create a CurrencyOption enum with 8 currencies, each having a code (ISO 4217) and
displayName (e.g., "$ USD", "€ EUR", "£ GBP", "₪ ILS", "₽ RUB", "¥ JPY", "C$ CAD", "A$ AUD").

Create an AppLanguageOption enum with english("en"), hebrew("he"), russian("ru") and display names.
```

---

### Prompt 4: Navigation & App Shell

```
Create the main navigation for ContractorCashFlow Android app with 7 bottom tabs using
Jetpack Compose Navigation and Material 3 NavigationBar.

Tabs (in order):
1. Projects (folder icon)
2. Expenses (dollar sign icon)
3. Invoices (receipt icon)
4. Labor (people icon)
5. Clients (contacts icon)
6. Analytics (chart icon)
7. Settings (gear icon)

Requirements:
- Each tab has its own NavGraph so back stacks are independent
- Tapping the already-selected tab pops back to its root
- Tab labels should use string resources for localization
- The selected tab state should survive configuration changes
- Create placeholder screens for each tab that just show the tab name

Set up MainActivity with the Scaffold, NavigationBar, and NavHost.
Use Material 3 theming with dynamic colors.
```

---

### Prompt 5: Projects Feature

```
Implement the complete Projects feature for ContractorCashFlow Android app.

Screens needed:

1. ProjectsListScreen:
   - Query all projects from Room sorted by createdDate DESC
   - Search bar at top filtering by name OR clientName (case-insensitive)
   - FAB to add new project (navigates to NewProjectScreen)
   - Each row shows: project name (bold), client name (secondary), active status green dot,
     total expenses (red with down arrow), total income (green with up arrow),
     net balance (green if positive, red if negative)
   - Swipe-to-dismiss to delete (with undo snackbar)
   - Tap row navigates to ProjectDetailScreen
   - Empty state: icon + "No Projects" + "Start tracking your work" + "Add Project" button

2. ProjectDetailScreen:
   - Financial Summary Card: net balance (large bold), income, expenses, profit margin %
   - Project Info section: name, client name (clickable navigates to ClientDetailScreen),
     budget, active/inactive status with green/gray dot, created date
   - Budget Utilization: progress bar (green <50%, orange 50-80%, red >80%), spent + remaining
   - Expense Category Chart: horizontal bars by category with colors and percentages
   - Expenses section: list sorted by date DESC, tap to edit, swipe to delete, add button
   - Invoices section: list sorted by createdDate DESC, status badges (Paid=green, Overdue=red,
     Pending=orange), paid/total count, swipe to delete, add button
   - Top app bar with overflow menu: Edit, Export, Add Expense, Add Invoice

3. NewProjectScreen:
   - Form: project name (required), client selection with toggle between "Enter Name" and
     "Select Existing" picker, budget input (decimal keyboard)
   - If entering new client name that doesn't exist: expandable section for email, phone,
     address, notes (auto-creates Client on save)
   - Duplicate client name warning banner
   - Validation: name not empty, clientName not empty, budget > 0
   - Save creates Project + optional Client

4. EditProjectScreen:
   - Same form pre-populated with existing values
   - Read-only stats: created date, total expenses, total income
   - Alert dialog if new budget < current total expenses

Use a ProjectViewModel with StateFlow for all state management.
Create a ProjectRepository that wraps the DAO calls.
Calculate totalExpenses, totalIncome, balance, profitMargin, budgetUtilization in the ViewModel.
```

---

### Prompt 6: Expenses Feature

```
Implement the complete Expenses feature for ContractorCashFlow Android app.

Screens needed:

1. ExpensesListScreen:
   - Query all expenses from Room sorted by date DESC
   - Search bar filtering by descriptionText
   - Filter icon button (filled when active) → opens ExpenseFiltersScreen as bottom sheet
   - FAB to add new expense
   - Each row: description (bold), category badge (blue chip), project name if assigned,
     date, amount in red
   - Tap to open EditExpenseScreen as bottom sheet or dialog
   - Swipe-to-dismiss to delete
   - Empty state: "No Expenses" + "Start tracking your project costs" + CTA button

2. ExpenseFiltersScreen (Bottom Sheet):
   - Category picker: "All Categories" + 5 category options
   - Date range section: toggle for start date + DatePicker, toggle for end date + DatePicker
   - "Clear All Filters" button
   - "Apply" and "Cancel" buttons

3. NewExpenseScreen:
   - Category dropdown picker (5 categories)
   - When Labor selected AND workers exist in DB:
     * Worker picker dropdown (shows name + rate with suffix)
     * On worker selection: auto-fill description "Labor: {workerName}"
     * If hourly/daily worker: show quantity input field, display calculated total (rate × units)
     * If contract/subcontractor worker: show fixed rate as read-only, auto-fill amount
   - Amount input (decimal, pre-filled from calculation if labor)
   - Description text field
   - Date picker (default: today)
   - Project picker (optional, only active projects)
   - Validation: description not empty, amount > 0
   - Post-save: if project assigned, check budget utilization and trigger notification if ≥80% or ≥100%

4. EditExpenseScreen:
   - Same form as New, pre-populated with existing expense values
   - Same labor auto-calculation logic
   - Updates existing record (not creating new)
   - Same post-save budget check

Create ExpenseViewModel and ExpenseRepository.
```

---

### Prompt 7: Invoices Feature

```
Implement the complete Invoices feature for ContractorCashFlow Android app.

Screens needed:

1. InvoicesListScreen:
   - Query all invoices from Room sorted by createdDate DESC
   - Search bar filtering by clientName
   - Status filter in top app bar as dropdown: All, Paid, Unpaid, Overdue
     * Paid: isPaid == true
     * Unpaid: !isPaid && dueDate >= now
     * Overdue: !isPaid && dueDate < now
   - FAB to add new invoice
   - Each row: client name (headline), status badge (Paid=green checkmark, Overdue=red exclamation,
     Pending=orange clock), project name if assigned, due date, amount (green if paid)
   - Tap navigates to EditInvoiceScreen
   - Swipe-to-dismiss to delete (also cancel notifications for that invoice)
   - Empty state: "No Invoices" + CTA

2. NewInvoiceScreen:
   - Client selection with "Enter Name" / "Select Existing" toggle (same as projects)
   - Amount input (decimal)
   - Due date picker (default: today + 30 days)
   - Paid toggle (default: off)
   - Project picker (optional, active projects)
   - Validation: clientName not empty, amount > 0
   - Auto-create Client record if doesn't exist
   - Post-save: schedule invoice reminder (3 days before due) and overdue alert (1 day after due)

3. EditInvoiceScreen:
   - Same form pre-populated
   - Delete button at bottom
   - When paid toggled ON → cancel all notifications for this invoice
   - When paid toggled OFF → reschedule notifications
   - Validation same as New

Create InvoiceViewModel and InvoiceRepository.
Implement isOverdue computed property: !isPaid && dueDate < System.currentTimeMillis()
```

---

### Prompt 8: Clients Feature

```
Implement the complete Clients feature for ContractorCashFlow Android app.

Screens needed:

1. ClientsListScreen:
   - Query all clients from Room sorted by name ASC
   - Search bar filtering by name, email, or phone (case-insensitive, any match)
   - FAB to add new client
   - Each row: name (headline), email with envelope icon (if present), phone with phone icon (if present)
   - Tap navigates to ClientDetailScreen
   - Swipe-to-dismiss to delete
   - Empty state: "No Clients" + CTA

2. ClientDetailScreen:
   - Contact info section: name, email, phone, address (each with icon, only shown if not null)
   - Notes section (only shown if notes is not null/empty)
   - Top app bar with Edit action button

3. NewClientScreen:
   - Form: name (required), email (optional, email keyboard), phone (optional, phone keyboard),
     address (optional, multiline 3-5 lines), notes (optional, multiline 4-8 lines)
   - Validation: name not empty (trimmed)
   - Save empty optional strings as null (not "")

4. EditClientScreen:
   - Same form pre-populated
   - Save button disabled if no changes from original values
   - Same null handling for empty optional fields

Create ClientViewModel and ClientRepository.
```

---

### Prompt 9: Labor/Workers Feature

```
Implement the complete Labor/Workers feature for ContractorCashFlow Android app.

Screens needed:

1. LaborListScreen:
   - Query all workers from Room
   - Search bar filtering by workerName OR notes
   - Filter icon → LaborFiltersScreen (bottom sheet)
   - Sort dropdown in top bar: Recently Added, Worker Name, Total Earned High→Low, Total Earned Low→High
   - FAB to add new worker
   - WorkerSummaryCard at top showing aggregated stats for filtered workers:
     * Total Labor Cost, Total Workers, Total Days Worked, Avg Daily Cost, Total Hours
     * If month filter active: show "March 2026" else "All Time"
   - WorkerCard for each worker: name + type badge, total earned, rate + suffix, days worked,
     units worked, associated project names (comma-separated), notes (2 lines max)
   - Tap to edit, swipe to delete with confirmation dialog

2. LaborFiltersScreen (Bottom Sheet):
   - Labor type picker: All Types / Hourly / Daily / Contract / Subcontractor
   - Project filter: All Projects / specific project picker
   - Month filter: toggle + month/year wheel picker (last 12 months)
   - Clear All and Done buttons

3. AddLaborScreen:
   - Worker name (required) + duplicate warning if name already exists
   - Labor type dropdown (4 types)
   - Rate input (decimal), label changes: "Rate per Hour" / "Rate per Day" / "Contract Price"
   - Notes (optional, multiline 3-6 lines)
   - Validation: name not empty (trimmed)

4. EditLaborScreen:
   - Same form pre-populated
   - Worker Statistics section (only if has linked expenses):
     * Total Earned, Total Hours/Days, Days Worked, Associated Projects list
   - Delete button with confirmation dialog:
     * If has expenses: "This worker has X linked expense(s). The expenses will remain but won't be linked to a worker."
     * If no expenses: "Are you sure you want to delete this worker?"
   - On delete: expenses remain but workerId set to null (handled by Room FK SET_NULL)

Computed properties (in ViewModel):
- totalAmountEarned: sum all linked expense amounts
- totalUnitsWorked: sum all unitsWorked from linked expenses
- totalDaysWorked: count unique calendar days from linked expense dates
- associatedProjects: unique project names from linked expenses

Create LaborViewModel and LaborRepository.
```

---

### Prompt 10: Analytics/Charts

```
Implement the Analytics screen for ContractorCashFlow Android app using Vico charts library.

The screen has 3 chart cards in a scrollable column:

1. Income vs Expenses (Donut/Pie Chart):
   - Data: totalIncome = sum of all paid invoice amounts, totalExpenses = sum of all expense amounts
   - Donut chart: green slice for income, red slice for expenses
   - Inner radius ratio ~0.618 (golden ratio)
   - Center text: "Net Balance" label + amount (bold, green if positive, red if negative)
   - Legend below chart: Income amount (green), Expenses amount (red)
   - Empty state if both are 0: chart icon + "No financial data yet"

2. Expenses by Category (Horizontal Bar Chart):
   - Data: group all expenses by category, sum amounts per category, calculate percentage of total
   - Sort categories by amount descending
   - Horizontal bars colored per category: Materials=blue, Labor=orange, Equipment=gray,
     Subcontractor=teal, Miscellaneous=purple
   - Y-axis: category names with colored dots
   - End of each bar: percentage annotation (e.g., "42%")
   - No X-axis labels needed
   - Empty state if no expenses: icon + "No expense data yet"

3. Budget Utilization per Project (Grouped Horizontal Bar Chart):
   - Data: only projects with budget > 0, limit to 10 projects
   - Per project: two bars — Spent (orange, = totalExpenses), Remaining (light blue, = max(0, budget - spent))
   - Y-axis: project names
   - X-axis: currency format
   - Legend: "Spent" (orange), "Remaining" (light blue)
   - Summary line below: "Average Utilization: X%" colored green <50%, orange 50-80%, red >80%
   - Dynamic height: approximately 44dp per project
   - Empty state if no qualifying projects: icon + "No project data yet"

Each chart card should have:
- A header with title
- Rounded corners, slight elevation
- Proper padding

Create AnalyticsViewModel that computes all chart data from Room queries.
```

---

### Prompt 11: Settings Screen

```
Implement the Settings screen for ContractorCashFlow Android app.

Sections:

1. Language:
   - Radio button group or dropdown: English, עברית (Hebrew), Русский (Russian)
   - On selection: save to DataStore, apply new locale using AppCompatDelegate.setApplicationLocales()
   - Footer text: "Select your preferred language"

2. Currency:
   - Dropdown/dialog picker with 8 options showing symbol + code:
     "$ USD", "€ EUR", "£ GBP", "₪ ILS", "₽ RUB", "¥ JPY", "C$ CAD", "A$ AUD"
   - Save to DataStore on selection
   - All amount formatting throughout app reads this preference

3. Notifications:
   - Three switches with labels:
     * "Invoice Reminders" (3 days before due date)
     * "Overdue Alerts" (1 day after due date)
     * "Budget Warnings" (at 80% and 100%)
   - On each toggle change: reschedule all relevant notifications
     * Invoice toggles → reschedule all unpaid invoice notifications
     * Budget toggle → recheck all active project budgets

4. Data Export:
   - "Export Data" button
   - On tap: generates JSON with all projects, expenses, invoices, clients, and preferences
   - Opens Android file picker (ACTION_CREATE_DOCUMENT) to save as
     "ContractorCashFlow_Export_YYYY-MM-DD.json"
   - JSON format: see the export structure in the migration guide

5. About:
   - App name: "ContractorCashFlow"
   - Version: read from BuildConfig.VERSION_NAME + "." + BuildConfig.VERSION_CODE

Create SettingsViewModel using DataStore.
```

---

### Prompt 12: Notifications

```
Implement the notification system for ContractorCashFlow Android app.

1. Create 3 notification channels on app startup (in Application class):
   - "invoice_reminders" (default importance) — for upcoming invoice reminders
   - "invoice_overdue" (high importance) — for overdue invoice alerts
   - "budget_warnings" (high importance) — for budget threshold warnings

2. Invoice Reminders:
   - Schedule with AlarmManager or WorkManager for exact timing
   - Upcoming reminder: 3 days before invoice.dueDate
     Title: "Invoice Due Soon"
     Body: "Invoice for {clientName} ({formatted amount}) is due in 3 days"
   - Overdue alert: 1 day after invoice.dueDate
     Title: "Invoice Overdue"
     Body: "Invoice for {clientName} ({formatted amount}) is now overdue"
   - Cancel both when invoice is marked as paid
   - Reschedule both when invoice is marked unpaid
   - Skip scheduling if the date is already past

3. Budget Warnings:
   - Triggered immediately (not scheduled) when saving an expense linked to a project
   - Check project.budgetUtilization after save
   - If 80% <= utilization < 100%:
     Title: "Budget Warning: 80%"
     Body: "Project '{name}' has reached 80% of its budget ({formatted spent}/{formatted budget})"
   - If utilization >= 100%:
     Title: "Budget Alert: 100%"
     Body: "Project '{name}' has exceeded its budget! ({formatted spent}/{formatted budget})"
   - Prevent duplicate notifications (check before showing)

4. Bulk reschedule:
   - When invoice reminder setting toggles: cancel all and reschedule all unpaid invoices
   - When overdue alert setting toggles: same
   - When budget warning setting toggles: recheck all active projects

5. Foreground handling:
   - Show notifications even when app is in foreground (Android shows them by default with channels)

Create NotificationService class with methods:
- createChannels()
- scheduleInvoiceReminder(invoice)
- scheduleOverdueAlert(invoice)
- cancelInvoiceNotifications(invoiceId)
- showBudgetWarning(project, threshold)
- rescheduleAllInvoiceNotifications(invoices)
- rescheduleAllBudgetNotifications(projects)
```

---

### Prompt 13: Localization

```
Set up multi-language support for ContractorCashFlow Android app with 3 languages:
English (default), Hebrew (RTL), Russian.

1. Enable RTL in AndroidManifest.xml: android:supportsRtl="true"

2. Create string resource files:
   - res/values/strings.xml (English)
   - res/values-he/strings.xml (Hebrew)
   - res/values-ru/strings.xml (Russian)

3. Copy all the string keys from Appendix B of the migration guide into strings.xml.
   For Hebrew and Russian files, translate all strings appropriately.

4. Implement runtime language switching:
   - Use AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags("he"))
   - Save selected language to DataStore
   - On app startup, read saved language and apply locale before setContent

5. Ensure all UI text uses stringResource(R.string.xxx) — no hardcoded strings.

6. Use Modifier.semantics and contentDescription for accessibility.

7. Verify RTL layout works for Hebrew: all start/end padding, text alignment,
   and navigation should flip automatically.
```

---

### Prompt 14: Cloud Sync with Firebase

```
Implement cloud sync for ContractorCashFlow Android app using Firebase Firestore.

1. Setup:
   - Add google-services.json to app/ directory
   - Enable Firestore in Firebase Console
   - Enable Google Sign-In in Firebase Auth

2. Authentication:
   - Add a "Sign in with Google" button in Settings (optional, or on first launch)
   - Use Firebase Auth's Google Sign-In flow
   - Store user UID for Firestore path

3. Firestore structure:
   users/{userId}/projects/{projectId}
   users/{userId}/expenses/{expenseId}
   users/{userId}/invoices/{invoiceId}
   users/{userId}/clients/{clientId}
   users/{userId}/laborDetails/{laborId}

4. Sync strategy (local-first):
   - Room is the source of truth for all UI reads
   - On every Room insert/update/delete, also write to Firestore
   - Add a "lastModified" Long field to every entity
   - On app launch (if authenticated): fetch all Firestore documents and merge into Room
     using last-write-wins conflict resolution
   - Firestore offline persistence is enabled by default — writes queue and sync when online

5. Create FirestoreSyncService with:
   - syncProject(project), syncExpense(expense), etc. — write to Firestore
   - pullAllData() — fetch from Firestore and upsert into Room
   - deleteFromFirestore(collection, id) — remove from Firestore on local delete
   - listenForChanges() — optional real-time listener using snapshots

6. Wrap repository methods to call both Room and Firestore:
   - Repository.insertProject() → dao.insert() + syncService.syncProject()
   - Same for update, delete

7. Handle offline gracefully — Firestore queues writes automatically.
```

---

### Prompt 15: Data Export

```
Implement JSON data export for ContractorCashFlow Android app.

1. Create data classes for export:
   ExportSnapshot: exportedAt, preferences, projects[], expenses[], invoices[], clients[]
   ExportPreferences: languageCode, currencyCode, invoiceReminders, overdueAlerts, budgetWarnings
   ExportProject: id, name, clientName, budget, createdDate (ISO 8601), isActive, totalExpenses, totalIncome, balance
   ExportExpense: id, category, amount, description, date (ISO 8601), projectId?, projectName?
   ExportInvoice: id, amount, dueDate (ISO 8601), isPaid, clientName, createdDate (ISO 8601), isOverdue, projectId?, projectName?
   ExportClient: id, name, email?, phone?, address?, notes?

2. Create DataExportService:
   - generateExportJson(context): String — fetches all data from Room, constructs ExportSnapshot, serializes with Gson (pretty print, ISO 8601 dates)
   - Filename format: "ContractorCashFlow_Export_2026-03-16.json"

3. In SettingsScreen:
   - "Export Data" button triggers ACTION_CREATE_DOCUMENT intent
   - On result, write JSON string to the selected URI using ContentResolver

4. Use Gson with:
   - setPrettyPrinting()
   - registerTypeAdapter for Date → ISO 8601 string
```

---

### Prompt 16: Testing

```
Create comprehensive unit tests for ContractorCashFlow Android app, mirroring the iOS test suites.

Use JUnit 4 + kotlinx-coroutines-test + Room in-memory database.

Test suites:

1. ProjectModelTests (7 tests):
   - testDefaultValues: verify defaults (empty name, 0 budget, isActive true)
   - testTotalExpensesCalculation: 2 expenses → sum amounts
   - testTotalIncomeCalculation: 3 invoices (2 paid, 1 unpaid) → sum only paid
   - testBalanceCalculation: income - expenses
   - testProfitMarginCalculation: ((income - expenses) / income) * 100
   - testBudgetUtilizationCalculation: (expenses / budget) * 100
   - testZeroBudgetUtilization: budget = 0 → returns 0

2. ExpenseModelTests (3 tests):
   - testDefaultValues, testCategoryNames (displayName matches), testProjectRelationship

3. InvoiceModelTests (4 tests):
   - testDefaultValues, testOverdueWhenUnpaidAndPastDue,
     testNotOverdueWhenPaid, testNotOverdueWhenFutureDue

4. ClientModelTests (2 tests):
   - testFullInit (all fields), testMinimalInit (only name, rest null)

5. CurrencyFormattingTests (3 tests):
   - testPositiveAmount, testZeroAmount, testLargeAmount

6. InputValidationTests (3 tests):
   - testEmptyStringInvalid, testPositiveNumberValid, testEmailFormat

7. BusinessLogicTests (3 tests):
   - testProfitability (income > expenses), testOverBudget (expenses > budget),
     testPaymentStatus (paid vs overdue vs pending logic)

8. EdgeCaseTests (5 tests):
   - testEmptyExpensesList, testZeroAmountExpense, testBoundaryDate,
     testLargeValues, testSpecialCharactersInNames

9. Room DAO Tests (with in-memory database):
   - testInsertAndQueryProject, testCascadeDeleteExpenses,
     testSetNullWorkerOnDelete, testSearchByName

Run all tests and verify they pass.
```

---

## Appendix D: Design System (Colors, Typography, Shapes)

This appendix documents all visual design tokens from the iOS app so they can be replicated exactly in Compose Material 3.

### D.1 Color Palette

Map iOS system colors to Compose equivalents. Use `MaterialTheme.colorScheme` where possible and define custom colors for semantic use.

```kotlin
// ui/theme/Color.kt
import androidx.compose.ui.graphics.Color

// Semantic colors (same across light/dark, adapt as needed)
val IncomeGreen       = Color(0xFF34C759)   // iOS .green
val ExpenseRed        = Color(0xFFFF3B30)   // iOS .red
val PendingOrange     = Color(0xFFFF9500)   // iOS .orange
val HourlyTeal        = Color(0xFF30B0C7)   // iOS .teal
val WorkerPurple      = Color(0xFFAF52DE)   // iOS .purple
val BudgetBlue        = Color(0xFF007AFF)   // iOS .blue
val InactiveGray      = Color(0xFF8E8E93)   // iOS .gray

// Category chart colors
val MaterialsBlue     = Color(0xFF007AFF)
val LaborOrange       = Color(0xFFFF9500)
val EquipmentGray     = Color(0xFF8E8E93)
val SubcontractorTeal = Color(0xFF30B0C7)
val MiscPurple        = Color(0xFFAF52DE)

// Background surface colors (use with MaterialTheme in light/dark)
// iOS Color(.systemBackground)          → MaterialTheme.colorScheme.surface
// iOS Color(.secondarySystemGroupedBackground) → MaterialTheme.colorScheme.surfaceVariant
// iOS Color(.systemGroupedBackground)   → MaterialTheme.colorScheme.background
// iOS Color(.separator)                 → MaterialTheme.colorScheme.outlineVariant

// Opacity variants used in iOS (replicate with .copy(alpha = ...)):
// avatar/badge background: WorkerPurple.copy(alpha = 0.12f)
// active status pill bg:   IncomeGreen.copy(alpha = 0.15f)
// inactive status pill bg: InactiveGray.copy(alpha = 0.15f)
// stat pill backgrounds:   color.copy(alpha = 0.10f)
// shadow:                  Color.Black.copy(alpha = 0.05f)
// income area fill:        IncomeGreen.copy(alpha = 0.15f)
// expense area fill:       ExpenseRed.copy(alpha = 0.15f)
// dividers:                outlineVariant.copy(alpha = 0.5f)
```

### D.2 Typography

```kotlin
// ui/theme/Type.kt
// Map iOS font specs to Compose TextStyle

// iOS .system(size: 34, weight: .bold, design: .rounded)
// → large balance/KPI number
val BalanceTextStyle = TextStyle(
    fontSize = 34.sp,
    fontWeight = FontWeight.Bold,
    fontFamily = FontFamily.Default  // use Rounded font if available
)

// iOS .title3 + .fontWeight(.bold)  → KPI card values
val KpiValueStyle = TextStyle(fontSize = 20.sp, fontWeight = FontWeight.Bold)

// iOS .title3 + .fontWeight(.semibold) → secondary KPI values
val KpiValueSemibold = TextStyle(fontSize = 20.sp, fontWeight = FontWeight.SemiBold)

// iOS .headline → worker name, card titles, page headings
// → MaterialTheme.typography.titleMedium (16sp SemiBold)

// iOS .subheadline → secondary titles, period filter labels
// → MaterialTheme.typography.bodyMedium (14sp)

// iOS .caption + .fontWeight(.semibold) → stat pill values
val PillValueStyle = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.SemiBold)

// iOS .caption → stat pill labels, secondary text
// → MaterialTheme.typography.labelSmall (11sp)

// iOS .caption2 + .fontWeight(.semibold) → worker rate, status badge text
val BadgeTextStyle = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.Medium)

// iOS .caption + .fontWeight(.medium) + .textCase(.uppercase) → section headers
val SectionHeaderStyle = TextStyle(
    fontSize = 12.sp,
    fontWeight = FontWeight.Medium,
    letterSpacing = 0.5.sp
    // apply .uppercase() in Compose with text.uppercase()
)
```

### D.3 Shapes & Corner Radii

```kotlin
// ui/theme/Shape.kt
// iOS → Compose mapping

// Card (analytics, KPI, labor):   cornerRadius = 12  → RoundedCornerShape(12.dp)
// StatCard (labor summary stat):  cornerRadius = 10  → RoundedCornerShape(10.dp)
// Period filter selected state:   cornerRadius = 8   → RoundedCornerShape(8.dp)
// Period filter container:        cornerRadius = 12  → RoundedCornerShape(12.dp)
// Invoice/budget bar segment:     cornerRadius = 4   → RoundedCornerShape(4.dp)
// Bar container:                  cornerRadius = 6   → RoundedCornerShape(6.dp)
// Status badges, stat pills:      Capsule            → CircleShape / RoundedCornerShape(50)
// Worker avatar:                  Circle             → CircleShape

val Shapes = Shapes(
    extraSmall = RoundedCornerShape(4.dp),
    small      = RoundedCornerShape(8.dp),
    medium     = RoundedCornerShape(10.dp),
    large      = RoundedCornerShape(12.dp),
    extraLarge = RoundedCornerShape(16.dp)
)
```

### D.4 Elevation & Shadows

```kotlin
// iOS shadow: .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
// In Compose use Card elevation or custom shadow modifier:

// For cards use:
Card(
    modifier = Modifier.shadow(
        elevation = 2.dp,
        shape = RoundedCornerShape(12.dp),
        ambientColor = Color.Black.copy(alpha = 0.05f),
        spotColor = Color.Black.copy(alpha = 0.05f)
    )
)
// Or simply: Card(elevation = CardDefaults.cardElevation(defaultElevation = 2.dp))
```

### D.5 Spacing Constants

```kotlin
object Spacing {
    val xs  = 4.dp    // tight vertical padding in badges
    val sm  = 8.dp    // badge padding, stat pill vertical
    val md  = 10.dp   // stat pill horizontal, stats section
    val lg  = 12.dp   // labor card header spacing, analytics cards inner
    val xl  = 16.dp   // standard card padding, section spacing
    val xxl = 20.dp   // page-level section gaps
}

// HStack/VStack spacing → Arrangement.spacedBy() / Column spacing:
// spacing 2  → Arrangement.spacedBy(2.dp)
// spacing 4  → Arrangement.spacedBy(4.dp)
// spacing 5  → Arrangement.spacedBy(5.dp)  (icon + text in pills)
// spacing 8  → Arrangement.spacedBy(8.dp)  (pill row, general)
// spacing 10 → Arrangement.spacedBy(10.dp) (labor summary stat cards)
// spacing 12 → Arrangement.spacedBy(12.dp) (labor card sections)
// spacing 16 → Arrangement.spacedBy(16.dp) (financial row)
// spacing 32 → Arrangement.spacedBy(32.dp) (income/expenses columns)
```

### D.6 Reusable Component Patterns

#### Status Badge (Active / Inactive / Invoice status)
```kotlin
@Composable
fun StatusBadge(label: String, color: Color) {
    Text(
        text = label.uppercase(),
        style = BadgeTextStyle,
        color = color,
        modifier = Modifier
            .background(color.copy(alpha = 0.15f), shape = CircleShape)
            .padding(horizontal = 8.dp, vertical = 3.dp)
    )
}
// Usage:
StatusBadge("Active", IncomeGreen)
StatusBadge("Overdue", ExpenseRed)
StatusBadge("Pending", PendingOrange)
```

#### Stat Pill (hours/days worked)
```kotlin
@Composable
fun StatPill(value: String, label: String, icon: ImageVector, color: Color) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .background(color.copy(alpha = 0.10f), shape = CircleShape)
            .padding(horizontal = 10.dp, vertical = 5.dp)
    ) {
        Icon(icon, contentDescription = null,
            tint = color, modifier = Modifier.size(12.dp))
        Text(value, style = PillValueStyle)
        Text(label, style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
// Usage: StatPill("8", "hours", Icons.Default.Schedule, HourlyTeal)
//        StatPill("3", "days",  Icons.Default.CalendarToday, PendingOrange)
```

#### Worker Avatar Circle
```kotlin
@Composable
fun WorkerAvatar(name: String, size: Dp = 42.dp) {
    val initials = name.split(" ")
        .take(2).mapNotNull { it.firstOrNull()?.uppercaseChar() }
        .joinToString("")
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(size)
            .background(WorkerPurple.copy(alpha = 0.12f), CircleShape)
    ) {
        Text(initials, style = MaterialTheme.typography.titleMedium,
            color = WorkerPurple)
    }
}
```

#### Analytics Card
```kotlin
@Composable
fun AnalyticsCard(title: String, content: @Composable () -> Unit) {
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium)
            content()
        }
    }
}
```

#### Period Filter Bar
```kotlin
@Composable
fun PeriodFilterBar(selected: AnalyticsPeriod, onSelect: (AnalyticsPeriod) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(12.dp))
            .padding(4.dp)
            .shadow(elevation = 2.dp, shape = RoundedCornerShape(12.dp)),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        AnalyticsPeriod.entries.forEach { period ->
            val isSelected = period == selected
            Text(
                text = period.label,
                style = if (isSelected) MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.SemiBold)
                        else MaterialTheme.typography.labelMedium,
                color = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface,
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(8.dp))
                    .background(if (isSelected) MaterialTheme.colorScheme.primary else Color.Transparent)
                    .clickable { onSelect(period) }
                    .padding(vertical = 8.dp),
                textAlign = TextAlign.Center
            )
        }
    }
}

enum class AnalyticsPeriod(val label: String, val days: Int?) {
    WEEK("7D", 7), MONTH("30D", 30), QUARTER("90D", 90),
    YEAR("1Y", 365), ALL("All", null)
}
```

---

## Appendix E: Missing Features Not in Original Guide

The following iOS features were not covered in the original guide phases. Each must be implemented in Android.

### E.1 Dual Worker Rates (Labor Model)

The iOS `LaborDetails` model supports **two simultaneous rates** — a worker can have both an hourly rate and a daily rate at the same time. This is different from what Phase 1 described (single `rate` field).

**Correct entity:**
```kotlin
@Entity(tableName = "labor_details")
data class LaborDetailsEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val workerName: String = "",
    val laborType: String = LaborType.HOURLY.name,  // default type
    val hourlyRate: Double? = null,   // rate per hour (independent of dailyRate)
    val dailyRate: Double? = null,    // rate per day (independent of hourlyRate)
    val contractPrice: Double? = null, // for CONTRACT and SUBCONTRACTOR types
    val notes: String? = null,
    val createdDate: Long = System.currentTimeMillis()
)
```

**Effective rate logic** — used when auto-calculating expense amount:
```kotlin
fun LaborDetailsEntity.effectiveRate(forType: LaborType): Double? = when (forType) {
    LaborType.HOURLY       -> hourlyRate
    LaborType.DAILY        -> dailyRate
    LaborType.CONTRACT,
    LaborType.SUBCONTRACTOR -> contractPrice
}
```

**In AddLaborScreen and EditLaborScreen:**
- Show separate "Rate per Hour" and "Rate per Day" fields simultaneously (both optional)
- Show "Contract Price" field for CONTRACT / SUBCONTRACTOR types
- Worker type picker selects the **default** billing mode; the dual rates allow the same worker to be billed either way on different expenses

### E.2 laborTypeSnapshot on Expense

Every `ExpenseEntity` must store a **snapshot of the labor type at the time the expense was created**. This preserves the pay-type context even if the worker's type changes later.

```kotlin
@Entity(tableName = "expenses", ...)
data class ExpenseEntity(
    // ... existing fields ...
    val laborTypeSnapshot: String? = null  // LaborType.name, only for Labor category
)
```

When creating a Labor expense with a worker selected:
- Set `laborTypeSnapshot = selectedBillingType.name` (the hourly/daily/contract mode chosen for this expense, not necessarily the worker's default)

When displaying expenses in EditLaborScreen stats or LaborCardRow:
- Use `laborTypeSnapshot` to determine whether to show hours or days icon/label per expense

### E.3 Receipt Image Scanning (OCR)

The iOS app includes full document/receipt scanning using the camera or photo library. This was not covered in the original guide.

**Android equivalent: ML Kit Document Scanner or CameraX + ML Kit Text Recognition**

Add dependencies:
```kotlin
// ML Kit Text Recognition (on-device, no network)
implementation("com.google.mlkit:text-recognition:16.0.1")
implementation("com.google.mlkit:text-recognition-hebrew:16.0.0")

// Document Scanner (Google Play Services)
implementation("com.google.android.gms:play-services-mlkit-document-scanner:16.0.0-beta1")

// Camera (for live camera feed alternative)
implementation("androidx.camera:camera-camera2:1.3.4")
implementation("androidx.camera:camera-lifecycle:1.3.4")
implementation("androidx.camera:camera-view:1.3.4")
```

**Add to ExpenseEntity:**
```kotlin
val receiptImageUri: String? = null  // URI to image stored in app's files dir
// Store as a file in Context.filesDir, save the URI path
// (Android equivalent of iOS @Attribute(.externalStorage))
```

**OcrService.kt:**
```kotlin
object OcrService {
    data class ScannedInvoiceData(
        val amount: Double?,
        val date: Date?,
        val description: String
    )

    suspend fun parse(bitmap: Bitmap, languageCode: String): ScannedInvoiceData {
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        val image = InputImage.fromBitmap(bitmap, 0)
        val result = recognizer.process(image).await()
        val lines = result.textBlocks.flatMap { it.lines }.map { it.text }
        return ScannedInvoiceData(
            amount = extractTotalAmount(lines),
            date = extractDate(lines),
            description = bestDescription(lines)
        )
    }

    // 5-strategy amount extraction (mirror iOS waterfall):
    // 1. Total keyword + decimal on same line
    // 2. Total keyword line, look ahead 1-3 lines for decimal
    // 3. Currency symbol (₪ $ € £ ₽) + decimal
    // 4. Any X.XX decimal pattern
    // 5. Last resort: integer < 10,000
    private fun extractTotalAmount(lines: List<String>): Double? { ... }

    // Total keywords per language:
    // EN: "total due", "amount due", "total to pay", "balance due", "grand total", "total", "amount payable"
    // HE: "סה״כ לתשלום", "לתשלום", "סכום לתשלום", "סה״כ"
    // RU: "итого к оплате", "итого", "к оплате", "сумма"
    private val totalKeywords = listOf(
        "total due", "amount due", "total to pay", "balance due",
        "grand total", "total", "amount payable",
        "סה\u05F4כ לתשלום", "לתשלום", "סכום לתשלום", "סה\u05F4כ",
        "итого к оплате", "итого", "к оплате", "сумма"
    )

    // Date formats to try (12 formats):
    // MM/dd/yyyy, dd/MM/yyyy, yyyy-MM-dd, MMM dd yyyy, dd MMM yyyy,
    // MMMM dd yyyy, MM-dd-yyyy, dd-MM-yyyy, d/M/yyyy, M/d/yyyy,
    // dd.MM.yyyy, d.M.yyyy
    private fun extractDate(lines: List<String>): Date? { ... }

    // Best description: longest non-numeric line under 60 chars
    private fun bestDescription(lines: List<String>): String { ... }
}
```

**ScanExpenseScreen.kt** — two entry points:
```kotlin
// 1. Document scanner (uses GMS Document Scanner API)
val scannerLauncher = rememberLauncherForActivityResult(
    ActivityResultContracts.StartIntentSenderForResult()
) { result -> /* get bitmap from result */ }

// 2. Photo picker (Android 13+ PhotoPicker or legacy gallery intent)
val photoPickerLauncher = rememberLauncherForActivityResult(
    ActivityResultContracts.PickVisualMedia()
) { uri -> /* load bitmap from uri */ }

// Show two buttons:
// "Scan Document" (camera icon) → launches document scanner
// "Choose from Photos" (gallery icon) → launches photo picker
```

**ScannedExpenseReviewScreen.kt** — editable review before saving:
- Receipt image thumbnail (52.dp × 52.dp), tappable for full-screen view
- `CurrencyTextField` for amount (pre-filled from OCR)
- Text field for description (pre-filled from OCR)
- `DatePicker` for date (pre-filled from OCR)
- Category picker (auto-suggested from description keywords):
  - Labor: description contains "labor", "worker", "wages"
  - Materials: contains "material", "lumber", "supply", "supplies"
  - Equipment: contains "equipment", "rental", "tool"
  - Default: Miscellaneous
- Project picker (optional)
- On save: compress image to JPEG (70% quality), store URI, create Expense record

**Add to package structure:**
```
ui/scan/
├── ScanExpenseScreen.kt
├── ScannedExpenseReviewScreen.kt
└── OcrService.kt
```

### E.4 In-App Purchases / Paywall

The iOS app uses StoreKit 2 with a free tier and two subscription plans. The Android equivalent uses Google Play Billing.

**Add dependency:**
```kotlin
implementation("com.android.billingclient:billing-ktx:7.0.0")
```

**Free tier limits (enforce at every creation point):**
```kotlin
object FreeTierLimit {
    const val MAX_PROJECTS = 1
    const val MAX_EXPENSES = 1
    const val MAX_INVOICES = 1
    const val MAX_WORKERS  = 1
}
```

**Product IDs (create in Google Play Console):**
```kotlin
object BillingProduct {
    const val PRO_MONTHLY = "com.yetzira.contractorcashflow.pro.monthly"
    const val PRO_YEARLY  = "com.yetzira.contractorcashflow.pro.yearly"
    // Pricing mirrors iOS: Monthly ~$19.99, Yearly ~$199.99
}
```

**PurchaseManager.kt:**
```kotlin
@Singleton
class PurchaseManager @Inject constructor(private val context: Context) {
    var isProUser: Boolean by mutableStateOf(false)
        private set
    var subscriptionStatusText: String by mutableStateOf("Free")
        private set
    var expirationDate: Date? by mutableStateOf(null)
        private set

    private val billingClient = BillingClient.newBuilder(context)
        .setListener { billingResult, purchases -> handlePurchases(purchases) }
        .enablePendingPurchases()
        .build()

    fun canCreateProject(currentCount: Int) = isProUser || currentCount < FreeTierLimit.MAX_PROJECTS
    fun canCreateExpense(currentCount: Int) = isProUser || currentCount < FreeTierLimit.MAX_EXPENSES
    fun canCreateInvoice(currentCount: Int) = isProUser || currentCount < FreeTierLimit.MAX_INVOICES
    fun canCreateWorker(currentCount: Int)  = isProUser || currentCount < FreeTierLimit.MAX_WORKERS

    suspend fun purchase(productId: String, activity: Activity): BillingResult { ... }
    suspend fun restorePurchases() { ... }
    private fun handlePurchases(purchases: List<Purchase>?) { ... }
}
```

**PaywallScreen.kt:**
- Feature comparison table (Free vs Pro)
- Monthly and Yearly plan cards with price
- "Restore Purchases" text button
- On close: navigates back
- Triggered from any screen where the free tier limit is reached

**Add to SettingsScreen:**
- Subscription section at top:
  - If Pro: show plan name + crown icon, renewal date, "Manage Subscription" button (opens Play Store)
  - If Free: show "Free Plan" + "Upgrade to Pro" button (opens PaywallScreen)

### E.5 Analytics — Missing Charts & Period Filter

The original guide (Phase 8) documented only 3 charts. The actual iOS analytics screen has **7 components**. Add the missing 4:

#### KPI Row (2 cards)
```kotlin
// Positioned above all charts
Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
    KpiCard(
        title = stringResource(R.string.analytics_net_balance),
        value = formatCurrency(netBalance),
        valueColor = if (netBalance >= 0) IncomeGreen else ExpenseRed,
        modifier = Modifier.weight(1f)
    )
    KpiCard(
        title = stringResource(R.string.analytics_overdue),
        value = formatCurrency(overdueAmount),
        valueColor = if (overdueAmount > 0) ExpenseRed else IncomeGreen,
        modifier = Modifier.weight(1f)
    )
}

@Composable
fun KpiCard(title: String, value: String, valueColor: Color, modifier: Modifier) {
    Card(shape = RoundedCornerShape(12.dp), modifier = modifier) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(title, style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(value, style = KpiValueStyle, color = valueColor)
        }
    }
}
```

#### Monthly Trend Chart (hidden for 7D period)
```kotlin
// Multi-series line + area chart using Vico
// X-axis: months (abbreviated + 2-digit year, e.g. "Jan 26")
// Y-axis: currency amounts
// Income series: IncomeGreen line + IncomeGreen.copy(alpha=0.15f) area fill
// Expense series: ExpenseRed line + ExpenseRed.copy(alpha=0.15f) area fill
// Interpolation: Catmull-Rom (smooth curves)
// Hidden entirely when selectedPeriod == AnalyticsPeriod.WEEK

// Build monthly buckets:
data class MonthlyDataPoint(val monthLabel: String, val income: Double, val expenses: Double)
```

#### Invoice Status Chart (stacked bar)
```kotlin
// Single horizontal bar divided into 3 proportional segments:
// [Paid (green)] [Pending (orange)] [Overdue (red)]
// Below bar: legend with label + amount + percentage for each segment
// Height: ~12.dp for the bar itself
// Segments: use Box with weight() for proportional widths
// Corner radii: first segment cornerRadius(start=6), last cornerRadius(end=6), middle none

@Composable
fun InvoiceStatusBar(paid: Double, pending: Double, overdue: Double) {
    val total = paid + pending + overdue
    if (total == 0.0) { /* empty state */ return }
    Row(modifier = Modifier.fillMaxWidth().height(12.dp).clip(RoundedCornerShape(6.dp))) {
        if (paid > 0)    Box(Modifier.weight((paid/total).toFloat()).fillMaxHeight().background(IncomeGreen))
        if (pending > 0) Box(Modifier.weight((pending/total).toFloat()).fillMaxHeight().background(PendingOrange))
        if (overdue > 0) Box(Modifier.weight((overdue/total).toFloat()).fillMaxHeight().background(ExpenseRed))
    }
    // Legend row below
}
```

#### Top Projects List
```kotlin
// Ranked list of top 5 projects by total income (paid invoices)
// Each row: rank number + project name + client name + income (green) + balance delta

@Composable
fun TopProjectsCard(projects: List<ProjectSummary>) {
    AnalyticsCard(title = stringResource(R.string.analytics_top_projects)) {
        projects.take(5).forEachIndexed { index, project ->
            Row(verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()) {
                Text("${index + 1}", style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.width(24.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(project.name, style = MaterialTheme.typography.bodyMedium)
                    Text(project.clientName, style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(formatCurrency(project.income), color = IncomeGreen,
                        style = MaterialTheme.typography.bodyMedium)
                    Text(formatCurrency(project.balance),
                        color = if (project.balance >= 0) IncomeGreen else ExpenseRed,
                        style = MaterialTheme.typography.labelSmall)
                }
            }
            if (index < projects.lastIndex) HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
        }
    }
}
```

#### Period Filter — date range calculation
```kotlin
fun AnalyticsPeriod.dateRange(): Pair<Long, Long>? {
    val now = System.currentTimeMillis()
    val days = this.days ?: return null  // ALL → return null (no filter)
    val start = now - days * 24 * 60 * 60 * 1000L
    return Pair(start, now)
}
// Apply to all chart data queries: filter expenses/invoices by date within range
// Monthly trend chart: hidden when period == WEEK (7D)
```

**Add missing localization strings:**
```xml
<string name="analytics_kpi_row">Key Metrics</string>
<string name="analytics_overdue">Overdue</string>
<string name="analytics_monthly_trend">Monthly Trend</string>
<string name="analytics_invoice_status">Invoice Status</string>
<string name="analytics_top_projects">Top Projects</string>
<string name="analytics_period_7d">7D</string>
<string name="analytics_period_30d">30D</string>
<string name="analytics_period_90d">90D</string>
<string name="analytics_period_1y">1Y</string>
<string name="analytics_period_all">All</string>
```

### E.6 iCloud Sync → Firebase Manual Sync Button

The iOS app has a manual "Sync with iCloud" button in Settings with 4 states: idle, syncing, done, failed.

Add to SettingsScreen (Firebase equivalent):
```kotlin
var syncState by remember { mutableStateOf(SyncState.IDLE) }

enum class SyncState { IDLE, SYNCING, DONE, FAILED }

// In settings list:
ListItem(
    headlineContent = {
        when (syncState) {
            SyncState.IDLE    -> Text(stringResource(R.string.settings_sync_now))
            SyncState.SYNCING -> Text(stringResource(R.string.settings_syncing))
            SyncState.DONE    -> Text(stringResource(R.string.settings_sync_done))
            SyncState.FAILED  -> Text(stringResource(R.string.settings_sync_failed))
        }
    },
    leadingContent = {
        when (syncState) {
            SyncState.IDLE    -> Icon(Icons.Default.CloudSync, null)
            SyncState.SYNCING -> CircularProgressIndicator(modifier = Modifier.size(24.dp))
            SyncState.DONE    -> Icon(Icons.Default.CloudDone, null, tint = IncomeGreen)
            SyncState.FAILED  -> Icon(Icons.Default.CloudOff, null, tint = ExpenseRed)
        }
    },
    modifier = Modifier.clickable {
        coroutineScope.launch {
            syncState = SyncState.SYNCING
            syncState = try {
                firestoreSyncService.pullAllData()
                SyncState.DONE
            } catch (e: Exception) {
                SyncState.FAILED
            }
        }
    }
)
```

**Add localization strings:**
```xml
<string name="settings_sync_now">Sync with Cloud</string>
<string name="settings_syncing">Syncing…</string>
<string name="settings_sync_done">Synced</string>
<string name="settings_sync_failed">Sync Failed</string>
```

### E.7 Project-Level Report Export

Each project has an individual "Export & Share" action (separate from the full JSON export in Settings). This generates a formatted plain-text report for a single project.

```kotlin
// ProjectExportService.kt
fun generateProjectReport(
    project: ProjectEntity,
    expenses: List<ExpenseEntity>,
    invoices: List<InvoiceEntity>,
    includeExpenses: Boolean,
    includeInvoices: Boolean,
    currencyCode: String
): String {
    val sb = StringBuilder()
    sb.appendLine("=== ${project.name} ===")
    sb.appendLine("Client: ${project.clientName}")
    sb.appendLine("Budget: ${formatCurrency(project.budget, currencyCode)}")
    sb.appendLine("Status: ${if (project.isActive) "Active" else "Inactive"}")
    sb.appendLine()
    sb.appendLine("--- Financial Summary ---")
    val totalExpenses = expenses.sumOf { it.amount }
    val totalIncome   = invoices.filter { it.isPaid }.sumOf { it.amount }
    sb.appendLine("Income:   ${formatCurrency(totalIncome, currencyCode)}")
    sb.appendLine("Expenses: ${formatCurrency(totalExpenses, currencyCode)}")
    sb.appendLine("Balance:  ${formatCurrency(totalIncome - totalExpenses, currencyCode)}")
    if (includeExpenses && expenses.isNotEmpty()) {
        sb.appendLine()
        sb.appendLine("--- Expenses ---")
        expenses.forEach { e ->
            sb.appendLine("${e.date.toDisplayDate()} | ${e.category} | ${e.descriptionText} | ${formatCurrency(e.amount, currencyCode)}")
        }
    }
    if (includeInvoices && invoices.isNotEmpty()) {
        sb.appendLine()
        sb.appendLine("--- Invoices ---")
        invoices.forEach { i ->
            val status = when {
                i.isPaid -> "Paid"
                i.dueDate < System.currentTimeMillis() -> "Overdue"
                else -> "Pending"
            }
            sb.appendLine("${i.clientName} | ${formatCurrency(i.amount, currencyCode)} | $status | Due: ${i.dueDate.toDisplayDate()}")
        }
    }
    return sb.toString()
}
```

**In ProjectDetailScreen toolbar:**
- "Export" menu item → shows bottom sheet with two toggles (include expenses, include invoices) + Share button
- Share via `Intent.ACTION_SEND` with `type = "text/plain"`

**Add to ProjectsListScreen toolbar too** (overflow menu on each row).

### E.8 ExpenseCategory — Correct Count

The original guide listed 5 categories (`SUBCONTRACTOR` was included). The iOS app has **4 categories** only:

```kotlin
enum class ExpenseCategory(val displayName: String) {
    MATERIALS("Materials"),
    LABOR("Labor"),
    EQUIPMENT("Equipment"),
    MISC("Miscellaneous")
    // SUBCONTRACTOR does NOT exist as an expense category
    // (Subcontractor is a LaborType, not an ExpenseCategory)
}
```

Remove `SUBCONTRACTOR` from `ExpenseCategory` everywhere in the codebase. `LaborType.SUBCONTRACTOR` is separate and correct.

### E.9 Updated Package Structure

Add the missing packages to the structure from Section 2.3:

```
ui/
├── scan/
│   ├── ScanExpenseScreen.kt          ← NEW (OCR entry)
│   └── ScannedExpenseReviewScreen.kt ← NEW (OCR review)
├── paywall/
│   └── PaywallScreen.kt              ← NEW (subscription)
├── components/
│   ├── StatusBadge.kt                ← NEW
│   ├── StatPill.kt                   ← NEW
│   ├── WorkerAvatar.kt               ← NEW
│   ├── AnalyticsCard.kt              ← NEW
│   ├── PeriodFilterBar.kt            ← NEW
│   ├── KpiCard.kt                    ← NEW
│   └── ... (existing)
│
services/
└── OcrService.kt                     ← NEW (ML Kit OCR)

billing/
└── PurchaseManager.kt                ← NEW (Google Play Billing)

export/
├── DataExportService.kt              ← existing (full JSON)
└── ProjectExportService.kt          ← NEW (per-project text report)
```

### E.10 Updated Dependencies

Add to `build.gradle.kts` beyond what Section 2.2 listed:

```kotlin
// Google Play Billing (in-app subscriptions)
implementation("com.android.billingclient:billing-ktx:7.0.0")

// ML Kit Text Recognition (on-device OCR, no network)
implementation("com.google.mlkit:text-recognition:16.0.1")
implementation("com.google.mlkit:text-recognition-hebrew:16.0.0")
implementation("com.google.mlkit:text-recognition-chinese:16.0.0") // optional

// GMS Document Scanner
implementation("com.google.android.gms:play-services-mlkit-document-scanner:16.0.0-beta1")

// CameraX (for photo capture)
val cameraxVersion = "1.3.4"
implementation("androidx.camera:camera-camera2:$cameraxVersion")
implementation("androidx.camera:camera-lifecycle:$cameraxVersion")
implementation("androidx.camera:camera-view:$cameraxVersion")

// Coroutine adapter for ML Kit Tasks
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.8.1")

// Coil (image loading for receipt thumbnails)
implementation("io.coil-kt:coil-compose:2.7.0")
```

### E.11 Updated Tech Stack Mapping

Add these missing mappings to Section 1:

| iOS (Current) | Android (Target) |
|---|---|
| Vision (`VNRecognizeTextRequest`) | ML Kit Text Recognition (on-device) |
| `VNDocumentCameraViewController` | GMS Document Scanner |
| `UIImagePickerController` | `ActivityResultContracts.PickVisualMedia()` |
| StoreKit 2 (auto-renewable subscriptions) | Google Play Billing 7 (subscriptions) |
| `@Attribute(.externalStorage)` for receipt images | Store JPEG file in `Context.filesDir`, save URI in Room |
| `AppStore.sync()` restore purchases | `BillingClient.queryPurchasesAsync()` |
| `AppStore.showManageSubscriptions()` | `Intent(Intent.ACTION_VIEW, "https://play.google.com/store/account/subscriptions".toUri())` |
| `UIActivityViewController` (text share) | `Intent.ACTION_SEND` with `type = "text/plain"` |

---

## Appendix F: In-App Purchases — Full Google Play Billing 7 Implementation Guide

This appendix is a complete, self-contained implementation guide for replicating the iOS StoreKit 2 subscription system in Android using Google Play Billing Library 7. Every class, interface, and UI component is documented with production-ready Kotlin + Compose code derived directly from the iOS source.

---

### F.0 iOS → Android Concept Mapping

| iOS Concept | Android Equivalent |
|---|---|
| `StoreKit.Product` | `ProductDetails` (from `BillingClient.queryProductDetailsAsync`) |
| `Transaction` | `Purchase` |
| `VerificationResult<Transaction>` | `BillingResult` + server-side receipt validation |
| `Transaction.currentEntitlements` | `BillingClient.queryPurchasesAsync(SUBS)` |
| `Transaction.updates` (listener) | `PurchasesUpdatedListener` set on `BillingClient` |
| `product.purchase()` | `BillingClient.launchBillingFlow(activity, params)` |
| `AppStore.sync()` | `BillingClient.queryPurchasesAsync()` — re-query active purchases |
| `AppStore.showManageSubscriptions()` | Deep link to Play Store subscriptions page |
| `transaction.finish()` | `BillingClient.acknowledgePurchase()` |
| `FreeTierLimit` enum | `FreeTierLimit` object (identical values) |
| `SubscriptionProduct` enum | `BillingProduct` object |
| `PurchaseManager` (singleton) | `PurchaseManager` (singleton `ViewModel` or Hilt singleton) |
| `.isProUser` Boolean | `isProUser: StateFlow<Boolean>` |
| `PaywallView` | `PaywallScreen` (Composable) |
| `PaywallView(limitReachedMessage:)` | `PaywallScreen(limitReachedMessage:)` |

---

### F.1 Gradle Dependencies

Add to **app/build.gradle.kts**:

```kotlin
dependencies {
    // Google Play Billing Library 7
    implementation("com.android.billingclient:billing:7.1.1")
    implementation("com.android.billingclient:billing-ktx:7.1.1")  // Kotlin coroutine extensions
}
```

> **Note:** `billing-ktx` provides `queryProductDetails`, `queryPurchasesAsync`, and `acknowledgePurchase` as suspend functions — the direct equivalent of Swift's `async/await` StoreKit 2 API.

---

### F.2 Product IDs and Free Tier Constants

These must match the product IDs you create in **Google Play Console → Subscriptions**.

```kotlin
// BillingProduct.kt
package com.yetzira.contractorcashflow.billing

object BillingProduct {
    // Must match Google Play Console product IDs exactly
    const val PRO_MONTHLY = "com.yetzira.contractorcashflow.pro.monthly"
    const val PRO_YEARLY  = "com.yetzira.contractorcashflow.pro.yearly"

    val ALL_IDS = listOf(PRO_MONTHLY, PRO_YEARLY)

    // Base plan IDs — set these to match the base plan tag you configure
    // in Google Play Console for each subscription product.
    const val MONTHLY_BASE_PLAN = "monthly"
    const val YEARLY_BASE_PLAN  = "yearly"
}

object FreeTierLimit {
    const val MAX_PROJECTS = 1
    const val MAX_EXPENSES = 1
    const val MAX_INVOICES = 1
    const val MAX_WORKERS  = 1
}
```

---

### F.3 PurchaseManager — Core Billing Class

This is the Android equivalent of `ServicesPurchaseManager.swift`. It is a singleton scoped to the application lifecycle using Hilt. If you are not using Hilt, see the manual singleton pattern in F.3.2.

#### F.3.1 With Hilt Dependency Injection (recommended)

```kotlin
// PurchaseManager.kt
package com.yetzira.contractorcashflow.billing

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.*
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PurchaseManager @Inject constructor(
    @ApplicationContext private val context: Context
) {

    // ─── State ────────────────────────────────────────────────────────────────

    /** True when the user has an active Pro subscription. Equivalent to iOS `isProUser`. */
    private val _isProUser = MutableStateFlow(false)
    val isProUser: StateFlow<Boolean> = _isProUser.asStateFlow()

    /** Available subscription ProductDetails loaded from Play Store. */
    private val _products = MutableStateFlow<List<ProductDetails>>(emptyList())
    val products: StateFlow<List<ProductDetails>> = _products.asStateFlow()

    /** True while products are loading. */
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    /** True while a purchase flow is in progress. */
    private val _isPurchasing = MutableStateFlow(false)
    val isPurchasing: StateFlow<Boolean> = _isPurchasing.asStateFlow()

    /** Non-null when an error has occurred; observe to show error UI. */
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    /** The active purchase object for the current subscription. */
    private val _activePurchase = MutableStateFlow<Purchase?>(null)
    val activePurchase: StateFlow<Purchase?> = _activePurchase.asStateFlow()

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // ─── BillingClient ────────────────────────────────────────────────────────

    /**
     * PurchasesUpdatedListener receives callbacks for purchases made during
     * the current session. Equivalent to StoreKit 2's Transaction.updates listener.
     */
    private val purchasesUpdatedListener = PurchasesUpdatedListener { billingResult, purchases ->
        when (billingResult.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases?.forEach { purchase ->
                    scope.launch { handlePurchase(purchase) }
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {
                // User dismissed the purchase flow — no action needed
            }
            else -> {
                _errorMessage.value = "Purchase failed: ${billingResult.debugMessage}"
            }
        }
        _isPurchasing.value = false
    }

    private val billingClient = BillingClient.newBuilder(context)
        .setListener(purchasesUpdatedListener)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder()
                .enableOneTimeProducts()
                .enablePrepaidPlans()
                .build()
        )
        .build()

    // ─── Init ─────────────────────────────────────────────────────────────────

    init {
        connectAndLoad()
    }

    /**
     * Connects to the Play Store, then checks entitlements and loads products.
     * Equivalent to the init block in iOS PurchaseManager.
     */
    private fun connectAndLoad() {
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    scope.launch {
                        checkCurrentEntitlements()
                        loadProducts()
                    }
                }
            }

            override fun onBillingServiceDisconnected() {
                // Retry connection on next operation
            }
        })
    }

    // ─── Load Products ────────────────────────────────────────────────────────

    /**
     * Loads subscription products from the Play Store.
     * Equivalent to iOS `loadProducts()` using `Product.products(for:)`.
     */
    suspend fun loadProducts() {
        _isLoading.value = true
        try {
            val productList = BillingProduct.ALL_IDS.map { productId ->
                QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(productId)
                    .setProductType(BillingClient.ProductType.SUBS)
                    .build()
            }
            val params = QueryProductDetailsParams.newBuilder()
                .setProductList(productList)
                .build()

            val result = billingClient.queryProductDetails(params)

            if (result.billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val sorted = (result.productDetailsList ?: emptyList()).sortedBy { details ->
                    // Monthly first, yearly second — same order as iOS
                    if (details.productId == BillingProduct.PRO_MONTHLY) 0 else 1
                }
                _products.value = sorted
            } else {
                _errorMessage.value = "Failed to load products: ${result.billingResult.debugMessage}"
            }
        } finally {
            _isLoading.value = false
        }
    }

    // ─── Purchase ─────────────────────────────────────────────────────────────

    /**
     * Launches the Play Store billing flow for the given ProductDetails and base plan.
     * Must be called from an Activity context.
     *
     * Equivalent to iOS `purchase(_ product: Product)`.
     *
     * @param activity      The foreground Activity (required by Play Billing)
     * @param productDetails The ProductDetails to purchase
     * @param basePlanId    The base plan tag from Play Console (e.g. "monthly" or "yearly")
     */
    fun launchPurchaseFlow(
        activity: Activity,
        productDetails: ProductDetails,
        basePlanId: String
    ) {
        val offerToken = productDetails
            .subscriptionOfferDetails
            ?.firstOrNull { it.basePlanId == basePlanId }
            ?.offerToken
            ?: return  // No matching offer — cannot proceed

        val productDetailsParamsList = listOf(
            BillingFlowParams.ProductDetailsParams.newBuilder()
                .setProductDetails(productDetails)
                .setOfferToken(offerToken)
                .build()
        )

        val billingFlowParams = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(productDetailsParamsList)
            .build()

        _isPurchasing.value = true
        billingClient.launchBillingFlow(activity, billingFlowParams)
        // Result is delivered to purchasesUpdatedListener
    }

    // ─── Handle Purchase ─────────────────────────────────────────────────────

    /**
     * Processes a successful purchase:
     *  1. Acknowledges it (required within 3 days or Play Store will refund)
     *  2. Updates entitlement state
     *
     * Equivalent to iOS `transaction.finish()` + `checkCurrentEntitlements()`.
     */
    private suspend fun handlePurchase(purchase: Purchase) {
        if (purchase.purchaseState != Purchase.PurchaseState.PURCHASED) return

        // Acknowledge if not yet done — REQUIRED for subscriptions
        if (!purchase.isAcknowledged) {
            val ackParams = AcknowledgePurchaseParams.newBuilder()
                .setPurchaseToken(purchase.purchaseToken)
                .build()
            val ackResult = billingClient.acknowledgePurchase(ackParams)
            if (ackResult.responseCode != BillingClient.BillingResponseCode.OK) {
                _errorMessage.value = "Acknowledgment failed: ${ackResult.debugMessage}"
                return
            }
        }

        checkCurrentEntitlements()
    }

    // ─── Restore / Check Entitlements ─────────────────────────────────────────

    /**
     * Queries Play Store for all active subscriptions and updates `isProUser`.
     *
     * Call this:
     *  - On app start (from init)
     *  - After a successful purchase
     *  - When the user explicitly taps "Restore Purchases"
     *
     * Equivalent to iOS `checkCurrentEntitlements()` and `restorePurchases()`.
     */
    suspend fun checkCurrentEntitlements() {
        val params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.SUBS)
            .build()

        val result = billingClient.queryPurchasesAsync(params)

        val activeProPurchase = result.purchasesList.firstOrNull { purchase ->
            purchase.purchaseState == Purchase.PurchaseState.PURCHASED &&
            purchase.products.any { it in BillingProduct.ALL_IDS }
        }

        _activePurchase.value = activeProPurchase
        _isProUser.value = activeProPurchase != null

        // Ensure any unacknowledged purchases from previous sessions are acknowledged
        result.purchasesList
            .filter { !it.isAcknowledged && it.purchaseState == Purchase.PurchaseState.PURCHASED }
            .forEach { handlePurchase(it) }
    }

    /**
     * Re-queries purchases — Play Store restore equivalent.
     * Unlike iOS `AppStore.sync()`, Android does not have a dedicated "restore" API;
     * re-querying `queryPurchasesAsync` achieves the same result.
     */
    suspend fun restorePurchases() {
        checkCurrentEntitlements()
    }

    // ─── Entitlement Gate Helpers ─────────────────────────────────────────────

    /** Returns true if the user can create a new project (free tier or Pro). */
    fun canCreateProject(currentCount: Int): Boolean =
        _isProUser.value || currentCount < FreeTierLimit.MAX_PROJECTS

    /** Returns true if the user can create a new expense. */
    fun canCreateExpense(currentCount: Int): Boolean =
        _isProUser.value || currentCount < FreeTierLimit.MAX_EXPENSES

    /** Returns true if the user can create a new invoice. */
    fun canCreateInvoice(currentCount: Int): Boolean =
        _isProUser.value || currentCount < FreeTierLimit.MAX_INVOICES

    /** Returns true if the user can create a new worker record. */
    fun canCreateWorker(currentCount: Int): Boolean =
        _isProUser.value || currentCount < FreeTierLimit.MAX_WORKERS

    // ─── Product Helpers ──────────────────────────────────────────────────────

    val monthlyProduct: ProductDetails?
        get() = _products.value.firstOrNull { it.productId == BillingProduct.PRO_MONTHLY }

    val yearlyProduct: ProductDetails?
        get() = _products.value.firstOrNull { it.productId == BillingProduct.PRO_YEARLY }

    // ─── Manage Subscription ─────────────────────────────────────────────────

    /**
     * Opens the Play Store subscription management screen.
     * Equivalent to iOS `AppStore.showManageSubscriptions(in: windowScene)`.
     */
    fun openManageSubscriptions(context: Context) {
        val intent = android.content.Intent(
            android.content.Intent.ACTION_VIEW,
            android.net.Uri.parse("https://play.google.com/store/account/subscriptions")
        )
        context.startActivity(intent)
    }

    // ─── Cleanup ──────────────────────────────────────────────────────────────

    fun destroy() {
        billingClient.endConnection()
        scope.cancel()
    }
}
```

#### F.3.2 Manual Singleton (without Hilt)

If you are not using Hilt, create the singleton in `Application`:

```kotlin
// ContractorCashFlowApp.kt
class ContractorCashFlowApp : Application() {
    val purchaseManager: PurchaseManager by lazy { PurchaseManager(this) }
}
```

Access it from any `Activity` or `ViewModel`:

```kotlin
val purchaseManager = (application as ContractorCashFlowApp).purchaseManager
```

---

### F.4 Hilt Module

```kotlin
// BillingModule.kt
package com.yetzira.contractorcashflow.di

import com.yetzira.contractorcashflow.billing.PurchaseManager
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

// With @Inject constructor on PurchaseManager, Hilt handles this automatically.
// This module is only needed if PurchaseManager does NOT use @Inject constructor.
@Module
@InstallIn(SingletonComponent::class)
object BillingModule {
    @Provides
    @Singleton
    fun providePurchaseManager(
        @ApplicationContext context: android.content.Context
    ): PurchaseManager = PurchaseManager(context)
}
```

---

### F.5 ViewModel — PurchaseViewModel

Expose `PurchaseManager` state to Compose UI via a ViewModel:

```kotlin
// PurchaseViewModel.kt
package com.yetzira.contractorcashflow.billing

import android.app.Activity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PurchaseViewModel @Inject constructor(
    private val purchaseManager: PurchaseManager
) : ViewModel() {

    // Expose all state flows directly from PurchaseManager
    val isProUser    = purchaseManager.isProUser
    val products     = purchaseManager.products
    val isLoading    = purchaseManager.isLoading
    val isPurchasing = purchaseManager.isPurchasing
    val errorMessage = purchaseManager.errorMessage

    fun launchPurchaseFlow(activity: Activity, productDetails: ProductDetails, basePlanId: String) {
        purchaseManager.launchPurchaseFlow(activity, productDetails, basePlanId)
    }

    fun restorePurchases() {
        viewModelScope.launch {
            purchaseManager.restorePurchases()
        }
    }

    fun clearError() {
        // Reset error state after showing it to the user
    }

    fun openManageSubscriptions(context: android.content.Context) {
        purchaseManager.openManageSubscriptions(context)
    }
}
```

---

### F.6 PaywallScreen — Complete Compose UI

Mirrors `PaywallView.swift` exactly: crown header, feature comparison table, product selection cards, subscribe button, restore button, and legal links.

```kotlin
// PaywallScreen.kt
package com.yetzira.contractorcashflow.ui.paywall

import android.app.Activity
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.android.billingclient.api.ProductDetails
import com.yetzira.contractorcashflow.billing.BillingProduct
import com.yetzira.contractorcashflow.billing.PurchaseViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaywallScreen(
    onDismiss: () -> Unit,
    /** Optional message describing which limit was reached. Shown below the title. */
    limitReachedMessage: String? = null,
    viewModel: PurchaseViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val activity = context as? Activity

    val isProUser    by viewModel.isProUser.collectAsState()
    val products     by viewModel.products.collectAsState()
    val isLoading    by viewModel.isLoading.collectAsState()
    val isPurchasing by viewModel.isPurchasing.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()

    // Pre-select yearly by default (best value) — same as iOS onAppear logic
    val yearlyProduct  = products.firstOrNull { it.productId == BillingProduct.PRO_YEARLY }
    val monthlyProduct = products.firstOrNull { it.productId == BillingProduct.PRO_MONTHLY }
    var selectedProduct by remember(yearlyProduct, monthlyProduct) {
        mutableStateOf(yearlyProduct ?: monthlyProduct)
    }

    var showErrorDialog by remember { mutableStateOf(false) }

    // Auto-dismiss when purchase succeeds — equivalent to iOS .onChange(of: isProUser)
    LaunchedEffect(isProUser) {
        if (isProUser) onDismiss()
    }

    LaunchedEffect(errorMessage) {
        if (errorMessage != null) showErrorDialog = true
    }

    // Error dialog
    if (showErrorDialog && errorMessage != null) {
        AlertDialog(
            onDismissRequest = { showErrorDialog = false },
            title = { Text("Error") },
            text = { Text(errorMessage!!) },
            confirmButton = {
                TextButton(onClick = { showErrorDialog = false }) { Text("OK") }
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {},
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(innerPadding)
                .padding(horizontal = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {

            // ── Crown header ──────────────────────────────────────────────────
            Spacer(modifier = Modifier.height(16.dp))

            Icon(
                imageVector = Icons.Default.Star,  // Use a crown drawable if available
                contentDescription = null,
                tint = Color(0xFFFFCC00),           // Gold
                modifier = Modifier.size(64.dp)
            )

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = "Upgrade to Pro",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = limitReachedMessage ?: "Unlock unlimited projects, expenses, invoices, and workers.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                modifier = Modifier.padding(horizontal = 16.dp)
            )

            Spacer(modifier = Modifier.height(24.dp))

            // ── Feature comparison card ───────────────────────────────────────
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = MaterialTheme.colorScheme.surfaceVariant,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    PaywallFeatureRow(
                        icon = Icons.Default.Folder,
                        title = "Unlimited Projects",
                        freeLimit = "1",
                        proLimit = "Unlimited"
                    )
                    PaywallFeatureRow(
                        icon = Icons.Default.AttachMoney,
                        title = "Unlimited Expenses",
                        freeLimit = "1",
                        proLimit = "Unlimited"
                    )
                    PaywallFeatureRow(
                        icon = Icons.Default.Description,
                        title = "Unlimited Invoices",
                        freeLimit = "1",
                        proLimit = "Unlimited"
                    )
                    PaywallFeatureRow(
                        icon = Icons.Default.Group,
                        title = "Unlimited Workers",
                        freeLimit = "1",
                        proLimit = "Unlimited"
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // ── Product selection ─────────────────────────────────────────────
            if (isLoading) {
                CircularProgressIndicator()
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                    monthlyProduct?.let { product ->
                        PaywallProductCard(
                            product = product,
                            basePlanId = BillingProduct.MONTHLY_BASE_PLAN,
                            isSelected = selectedProduct?.productId == product.productId,
                            savingsBadge = null,
                            onClick = { selectedProduct = product }
                        )
                    }
                    yearlyProduct?.let { product ->
                        PaywallProductCard(
                            product = product,
                            basePlanId = BillingProduct.YEARLY_BASE_PLAN,
                            isSelected = selectedProduct?.productId == product.productId,
                            savingsBadge = "SAVE",      // Equivalent to iOS saveBadge
                            onClick = { selectedProduct = product }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // ── Subscribe button ──────────────────────────────────────────────
            Button(
                onClick = {
                    val product = selectedProduct ?: return@Button
                    val basePlanId = when (product.productId) {
                        BillingProduct.PRO_MONTHLY -> BillingProduct.MONTHLY_BASE_PLAN
                        BillingProduct.PRO_YEARLY  -> BillingProduct.YEARLY_BASE_PLAN
                        else -> return@Button
                    }
                    activity?.let { viewModel.launchPurchaseFlow(it, product, basePlanId) }
                },
                enabled = selectedProduct != null && !isPurchasing,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(14.dp)
            ) {
                if (isPurchasing) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text("Subscribe", fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // ── Restore purchases ─────────────────────────────────────────────
            TextButton(onClick = { viewModel.restorePurchases() }) {
                Text("Restore Purchases", style = MaterialTheme.typography.bodySmall)
            }

            Spacer(modifier = Modifier.height(8.dp))

            // ── Legal links ───────────────────────────────────────────────────
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Text(
                    text = "Terms of Service",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = "Privacy Policy",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

// ─── Feature Row ──────────────────────────────────────────────────────────────

@Composable
private fun PaywallFeatureRow(
    icon: ImageVector,
    title: String,
    freeLimit: String,
    proLimit: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(28.dp)
        )
        Text(text = title, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = proLimit,
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.SemiBold,
                color = Color(0xFF34C759)   // IncomeGreen
            )
            Text(
                text = "Free: $freeLimit",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

@Composable
private fun PaywallProductCard(
    product: ProductDetails,
    basePlanId: String,
    isSelected: Boolean,
    savingsBadge: String?,
    onClick: () -> Unit
) {
    // Extract price from the subscription offer for this base plan
    val pricingPhase = product
        .subscriptionOfferDetails
        ?.firstOrNull { it.basePlanId == basePlanId }
        ?.pricingPhases
        ?.pricingPhaseList
        ?.firstOrNull()

    val displayPrice = pricingPhase?.formattedPrice ?: ""
    val period = when (basePlanId) {
        "monthly" -> "/ month"
        "yearly"  -> "/ year"
        else -> ""
    }

    OutlinedCard(
        onClick = onClick,
        border = BorderStroke(
            width = if (isSelected) 2.dp else 1.dp,
            color = if (isSelected) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.outline.copy(alpha = 0.4f)
        ),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = product.name,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold
                    )
                    if (savingsBadge != null) {
                        Surface(
                            shape = RoundedCornerShape(4.dp),
                            color = Color(0xFF34C759)  // IncomeGreen
                        ) {
                            Text(
                                text = savingsBadge,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = Color.White,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }
                }
                Text(
                    text = "$displayPrice $period",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Icon(
                imageVector = if (isSelected) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
                contentDescription = null,
                tint = if (isSelected) MaterialTheme.colorScheme.primary
                       else MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}
```

---

### F.7 Entitlement Gate Pattern in List Screens

Every list screen gates the "Add" button with a `canCreate*` check before showing it. If the gate fails, `showPaywall = true` opens the paywall sheet. This mirrors iOS exactly.

```kotlin
// ProjectsListScreen.kt — illustrative pattern, apply to all list screens
@Composable
fun ProjectsListScreen(
    viewModel: ProjectsViewModel = hiltViewModel(),
    purchaseViewModel: PurchaseViewModel = hiltViewModel()
) {
    val projects by viewModel.projects.collectAsState()
    val isProUser by purchaseViewModel.isProUser.collectAsState()

    var showPaywall by remember { mutableStateOf(false) }
    var paywallMessage by remember { mutableStateOf<String?>(null) }

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(onClick = {
                if (purchaseViewModel.isProUser.value || projects.size < FreeTierLimit.MAX_PROJECTS) {
                    viewModel.onAddProjectClick()
                } else {
                    paywallMessage = "You've reached the free project limit. Upgrade to Pro for unlimited projects."
                    showPaywall = true
                }
            }) {
                Icon(Icons.Default.Add, contentDescription = "Add project")
            }
        }
    ) { padding ->
        // ... project list UI ...
    }

    if (showPaywall) {
        ModalBottomSheet(onDismissRequest = { showPaywall = false }) {
            PaywallScreen(
                onDismiss = { showPaywall = false },
                limitReachedMessage = paywallMessage
            )
        }
    }
}
```

**Apply the same pattern to:**

| iOS View | Android Screen | Gate Function |
|---|---|---|
| `ViewsProjectsListView` | `ProjectsListScreen` | `canCreateProject(projects.size)` |
| `ViewsExpensesListView` | `ExpensesListScreen` | `canCreateExpense(expenses.size)` |
| `ViewsInvoicesListView` | `InvoicesListScreen` | `canCreateInvoice(invoices.size)` |
| `ViewsLaborListView` | `WorkersListScreen` | `canCreateWorker(workers.size)` |
| `ProjectDetailView` (expense tab) | `ProjectDetailScreen` expense tab | `canCreateExpense(allExpenses.size)` |
| `ProjectDetailView` (invoice tab) | `ProjectDetailScreen` invoice tab | `canCreateInvoice(allInvoices.size)` |

---

### F.8 Subscription Status in SettingsScreen

Mirrors the `SettingsView` subscription section: shows "Pro Monthly" / "Pro Yearly" + renewal date for Pro users, or "Free Plan" + upgrade button for free users.

```kotlin
// SubscriptionSection.kt (composable used inside SettingsScreen)
@Composable
fun SubscriptionSection(
    purchaseViewModel: PurchaseViewModel = hiltViewModel()
) {
    val isProUser    by purchaseViewModel.isProUser.collectAsState()
    val activePurchase = (purchaseViewModel as? PurchaseViewModelImpl)?.activePurchase?.collectAsState()

    var showPaywall by remember { mutableStateOf(false) }
    val context = LocalContext.current

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("Subscription", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            HorizontalDivider()

            if (isProUser) {
                // Current plan row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Current Plan", style = MaterialTheme.typography.bodyMedium)
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Star, contentDescription = null, tint = Color(0xFFFFCC00), modifier = Modifier.size(16.dp))
                        Text(
                            text = "Pro",
                            color = Color(0xFF34C759),
                            fontWeight = FontWeight.SemiBold,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }

                // Manage subscription button
                OutlinedButton(
                    onClick = { purchaseViewModel.openManageSubscriptions(context) },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(Icons.Default.CreditCard, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Manage Plan")
                }

            } else {
                // Free plan row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Current Plan", style = MaterialTheme.typography.bodyMedium)
                    Text("Free", color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodyMedium)
                }

                // Upgrade button
                Button(
                    onClick = { showPaywall = true },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFFCC00))
                ) {
                    Icon(Icons.Default.Star, contentDescription = null, tint = Color.Black, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Upgrade to Pro", color = Color.Black, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }

    if (showPaywall) {
        ModalBottomSheet(onDismissRequest = { showPaywall = false }) {
            PaywallScreen(onDismiss = { showPaywall = false })
        }
    }
}
```

---

### F.9 Google Play Console Configuration

Replicate the iOS `Products.storekit` configuration in Google Play Console:

#### Subscription Group

| Field | Value |
|---|---|
| Group name | `Pro Subscription` |
| Group description | Matches iOS `group.contractorcashflow.pro` |

#### Product: Pro Monthly

| Field | Value |
|---|---|
| Product ID | `com.yetzira.contractorcashflow.pro.monthly` |
| Name | `Pro Monthly` |
| Description | `Unlimited projects, expenses, invoices, and workers` |
| Base plan tag | `monthly` |
| Billing period | `P1M` (1 month) |
| Price | Match iOS pricing (~$19.99/month or local equivalent) |

#### Product: Pro Yearly

| Field | Value |
|---|---|
| Product ID | `com.yetzira.contractorcashflow.pro.yearly` |
| Name | `Pro Yearly` |
| Description | `Unlimited projects, expenses, invoices, and workers — save with annual billing` |
| Base plan tag | `yearly` |
| Billing period | `P1Y` (1 year) |
| Price | Match iOS pricing (~$199.99/year or local equivalent) |

> **Important:** The product IDs in Play Console **must exactly match** the constants in `BillingProduct`. If you change one you must update both.

---

### F.10 Testing In-App Purchases

#### F.10.1 License Testers

Add your Gmail test accounts as **License Testers** in Play Console → Setup → License Testing. License testers can purchase subscriptions without real charges.

#### F.10.2 Internal Testing Track

Upload an APK/AAB to the **Internal Testing** track with billing permission. Subscriptions cannot be tested on a local debug build unless the app has been uploaded at least once.

#### F.10.3 Test Product IDs

For development, Play Console supports `android.test.*` static responses:
- `android.test.purchased` — always succeeds
- `android.test.canceled` — always cancels
- `android.test.item_unavailable` — simulates unavailable product

> **Note:** These are not valid subscription product IDs; they only work for one-time products. For subscription testing, use the License Tester approach above.

#### F.10.4 Checking Entitlements Manually

```kotlin
// Trigger in your debug menu or Settings screen during development
scope.launch {
    purchaseManager.checkCurrentEntitlements()
    Log.d("Billing", "isProUser: ${purchaseManager.isProUser.value}")
}
```

---

### F.11 Critical Implementation Rules

These are requirements from Google Play Billing policies that differ from StoreKit 2 behaviour:

| Rule | Details |
|---|---|
| **Acknowledge within 3 days** | Call `acknowledgePurchase()` within 3 days of a PURCHASED state. If not acknowledged, Play Store automatically refunds and revokes. StoreKit 2 `transaction.finish()` is the equivalent. |
| **Re-check entitlements on resume** | Call `checkCurrentEntitlements()` in `Activity.onResume()` or in `LaunchedEffect(Unit)` on the main screen. StoreKit 2's `Transaction.currentEntitlements` is a live async sequence; Android requires a manual query. |
| **Handle PENDING state** | A purchase can be in `PENDING` state (e.g., cash payment pending). Do not grant entitlement until state is `PURCHASED`. |
| **BillingClient reconnect** | `onBillingServiceDisconnected` means Play Services disconnected. Call `startConnection` again before the next billing operation. |
| **Single BillingClient per app** | Do not create multiple `BillingClient` instances. Use the singleton pattern from F.3. |
| **Activity required for launchBillingFlow** | Unlike StoreKit 2 which uses a window scene, Android billing requires a live `Activity` reference. Never cache the `Activity` in a ViewModel — obtain it from `LocalContext.current as? Activity` in the Compose UI. |

---

### F.12 Full Dependency List for Billing Feature

```kotlin
// app/build.gradle.kts
dependencies {
    // Billing
    implementation("com.android.billingclient:billing:7.1.1")
    implementation("com.android.billingclient:billing-ktx:7.1.1")

    // Hilt (for singleton injection)
    implementation("com.google.dagger:hilt-android:2.51.1")
    kapt("com.google.dagger:hilt-android-compiler:2.51.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")

    // Coroutines (required for billing-ktx suspend functions)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    // ViewModel (for PurchaseViewModel)
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")
}
```

---

*End of Appendix F*

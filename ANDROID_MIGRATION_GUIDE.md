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

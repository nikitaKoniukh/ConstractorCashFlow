# ContractorCashFlow

A comprehensive iOS app for construction contractors to manage projects, track expenses, create invoices, manage clients and workers, and visualize financial analytics — all from one place.

Built with **SwiftUI**, **SwiftData**, **CloudKit**, and **Swift Charts**. Supports **iCloud sync** across devices, **3 languages** (English, Hebrew, Russian), and **8 currencies**.

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Architecture](#architecture)
- [Data Model](#data-model)
- [Project Structure](#project-structure)
- [Localization](#localization)
- [Testing](#testing)
- [License](#license)

---

## Features

### Project Management
- Create and manage construction projects with name, client, budget, and active/inactive status
- Detailed project view with financial summary: net balance, income, expenses, profit margin
- Budget utilization progress bar with color-coded thresholds (green < 50%, orange < 80%, red >= 80%)
- Expense category breakdown chart per project
- Export individual project reports as formatted text via the native share sheet
- Swipe-to-delete with cascade removal of related expenses and invoices

### Expense Tracking
- Log expenses under 4 categories: Materials, Labor, Equipment, Miscellaneous
- **Edit existing expenses** — tap any expense to modify category, amount, description, date, project, or worker assignment
- Assign expenses to projects or track them as general overhead
- Advanced filtering by category, date range, and search text
- Labor expenses auto-calculate amounts from worker rate and hours/days worked
- Budget threshold notifications at 80% and 100% utilization

### Invoice Management
- Create invoices tied to projects and clients
- Track payment status: Paid, Pending, Overdue
- Filter invoices by status (all, paid, unpaid, overdue) and search by client name
- Due dates default to 30 days out
- Edit invoices with inline paid toggle and notification management
- Automatic overdue detection based on due date

### Client Management
- Maintain a client directory with name, email, phone, address, and notes
- Auto-create clients when entering a new name on projects or invoices
- Duplicate name detection with warnings
- Search clients by name, email, or phone
- Clickable client names in project details navigate to client profile

### Labor & Worker Management
- Register workers with type: Hourly, Daily, Contract, or Subcontractor
- Set **dual pay rates** — a worker can have both an hourly rate and a daily rate simultaneously
- Link workers to labor expenses with automatic amount calculation
- `laborTypeSnapshot` stored on each expense preserves the pay-type context at the time of entry
- Summary dashboard: total labor cost, worker count, days/hours worked, average daily cost
- `WorkerSummaryCard` shows total days for daily workers and total hours for hourly workers (as integers)
- `LaborCardRow` shows calendar icon for daily workers, clock icon for hourly; project costs broken out per project
- Filter workers by type, project, or month — month filter scopes costs to only what was paid in that period
- Sort by name, date added, or total earned
- Delete workers with confirmation — linked expenses are preserved but unlinked

### Financial Analytics
Fully redesigned analytics dashboard powered by Swift Charts with **period filtering** (7D / 30D / 90D / 1Y / All):

1. **KPI row** — Net Balance and Overdue amounts as quick-glance cards
2. **Income vs. Expenses** — Donut chart; net balance shown in legend below the chart
3. **Monthly Trend** — Multi-series line + area chart (income in green, expenses in red) with currency Y-axis; hidden for 7D period
4. **Expenses by Category** — Horizontal bar chart with percentage annotations per category
5. **Invoice Status** — Stacked bar showing Paid / Pending / Overdue with per-row percentages
6. **Top Projects** — Ranked list of top 5 projects by revenue with balance delta
7. **Budget Utilization** — Color-coded bars (blue < 80%, orange 80–100%, red > 100%) for up to 8 projects

All charts handle empty states gracefully. All strings fully localized (EN / HE / RU).

### Notifications
Local push notifications for:
- **Invoice reminders** — 3 days before due date
- **Overdue alerts** — fires immediately (staggered 2 s delay) if invoice is already overdue at launch; scheduled for future overdue dates otherwise
- **Budget warnings** — fires immediately at launch if a project is at 80% or 100% utilization; rescheduled on every launch
- Multiple simultaneous notifications are staggered 3 seconds apart so iOS shows each as a separate banner
- Each notification type can be toggled independently in Settings
- Notifications are automatically rescheduled at app launch and when settings change
- **Tap-to-navigate** — tapping a budget warning opens the relevant project detail; tapping an overdue alert opens the invoice edit sheet

### Data Export
- **Full JSON export** — All projects, expenses, invoices, clients, and app preferences exported as a single `.json` file via the system file exporter
- **Project report export** — Formatted plain-text report per project with configurable sections (expenses, invoices), shared via iOS share sheet

### Search
Every major list view supports search:

| Screen | Searchable Fields |
|--------|-------------------|
| Projects | Name, client name |
| Expenses | Description |
| Invoices | Client name |
| Clients | Name, email, phone |
| Labor | Worker name, notes |

### Multi-Language & Multi-Currency
- **Languages:** English, Hebrew (with RTL layout), Russian
- **Currencies:** USD, EUR, GBP, ILS, RUB, JPY, CAD, AUD
- Language switching is instant — the entire UI rebuilds in the selected language
- Type-safe localization keys prevent key typos at compile time

### iCloud Sync
- **Automatic CloudKit sync** — all data (projects, expenses, invoices, clients, workers) syncs across devices via iCloud
- Uses SwiftData's built-in CloudKit integration (`cloudKitDatabase: .automatic`)
- All model attributes have CloudKit-compatible default values; all relationships are optional
- `receiptImageData` stored as a `CKAsset` via `@Attribute(.externalStorage)` to comply with CloudKit record size limits
- **Live sync refresh** — the app listens for `NSPersistentStoreRemoteChange` and immediately refreshes all `@Query` views without requiring an app restart; deletions on one device are reflected instantly on another via `ModelContext.rollback()`
- **Manual sync button** in Settings triggers `modelContext.save()` and shows visual confirmation (`Done` / `Failed`)
- Graceful fallback to local-only storage if CloudKit is unavailable
- Requires iCloud account with iCloud Drive enabled on each device

### Invoice & Receipt Scanning (OCR)
- Scan invoices and receipts using the camera or import from the Photos library
- **`InvoiceOCRService`** uses Apple Vision (`VNRecognizeTextRequest`) for on-device OCR — no network calls
- Supports **English, Hebrew, and Russian** invoices with language-specific keyword extraction
- 5-strategy amount extraction waterfall: keyword + same-line → keyword + lookahead → currency symbol → largest decimal → last-resort integer
- Automatically extracts: total amount, invoice date (12 date formats), and best-match description
- Review screen allows editing all extracted fields before saving as an expense
- All scan UI strings are fully localized (EN / HE / RU)

### In-App Subscriptions (StoreKit 2)
- **Free tier** — 1 project, 1 expense, 1 invoice, 1 worker
- **Pro Monthly** — $19.99/month, unlimited everything
- **Pro Yearly** — $199.99/year, unlimited everything
- StoreKit 2 with transaction verification and real-time updates
- Restore purchases via `AppStore.sync()`
- Paywall UI with feature comparison table and plan selection
- Subscription status displayed in Settings with expiration date
- Limits enforced at all entity creation points across the app

---

## Screenshots

<!-- Add screenshots here -->
*Screenshots coming soon.*

---

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Apple Developer account (for push notifications and CloudKit sync)
- iCloud account with iCloud Drive enabled (for cross-device sync)

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/nikitakoniukh/ConstractorCashFlow.git
   ```

2. Open the project in Xcode:
   ```bash
   cd ConstractorCashFlow
   open ContractorCashFlow.xcodeproj
   ```

3. Select your target device or simulator.

4. Build and run (`Cmd + R`).

> **Note:** Push notifications require a physical device. The simulator will not deliver local notifications reliably.

---

## Architecture

### Tech Stack
| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI |
| Persistence | SwiftData (`@Model`) |
| Cloud Sync | CloudKit (via `ModelConfiguration.cloudKitDatabase`) |
| Charts | Swift Charts (`SectorMark`, `BarMark`, `LineMark`, `AreaMark`) |
| State Management | `@Observable` (Observation framework) |
| Notifications | `UNUserNotificationCenter` |
| In-App Purchases | StoreKit 2 (auto-renewable subscriptions) |
| OCR | Vision framework (`VNRecognizeTextRequest`) |
| Localization | `Localizable.xcstrings` + type-safe `LocalizationKey` enums |

### Patterns
- **Single-module architecture** — All code lives in one target with logical file grouping
- **Observable state** — `AppState` is an `@Observable` class injected via SwiftUI's `@Environment`, managing tab selection, navigation paths, sheet presentation flags, search queries, error display, and pending deep-link IDs (`pendingProjectID`, `pendingInvoiceID`) for notification-tap navigation
- **Per-tab NavigationPath** — Each tab maintains its own `NavigationPath` enabling pop-to-root on tab re-tap
- **SwiftData `@Query`** — Views use `@Query` with `#Predicate` for reactive, filtered data fetching directly from the model store
- **Singleton services** — `NotificationService`, `LanguageManager`, and `PurchaseManager` are `@MainActor` singletons
- **Centralized error handling** — All CRUD operations use do/catch with errors surfaced via `AppState.showError()`

---

## Data Model

```
┌─────────────┐       ┌──────────────────┐       ┌──────────────┐
│   Project    │───1:N─│     Expense      │───N:1─│ LaborDetails │
│              │       │                  │       │   (Worker)   │
│  id          │       │  id              │       │              │
│  name        │       │  category        │       │  id          │
│  clientName  │       │  amount          │       │  workerName  │
│  budget      │       │  description     │       │  laborType   │
│  createdDate │       │  date            │       │  hourlyRate? │
│  isActive    │       │  unitsWorked     │       │  dailyRate?  │
│              │       │  laborTypeSnapshot│      │  contractPrice?│
│  expenses[]  │       │  project?        │       │  notes       │
│  invoices[]  │       │  worker?         │       │  createdDate │
└──────┬──────┘        └──────────────────┘       │  expenses[]  │
       │                                          └──────────────┘
       │1:N
       │
┌──────┴──────┐       ┌─────────────┐
│   Invoice   │       │   Client    │
│             │       │             │
│  id         │       │  id         │
│  amount     │       │  name       │
│  dueDate    │       │  email?     │
│  isPaid     │       │  phone?     │
│  clientName │       │  address?   │
│  createdDate│       │  notes?     │
│  project?   │       └─────────────┘
└─────────────┘
```

**Relationship details:**
- `Project` → `Expense`: one-to-many, cascade delete, bidirectional
- `Project` → `Invoice`: one-to-many, cascade delete, bidirectional
- `LaborDetails` → `Expense`: one-to-many, nullify delete, bidirectional
- `Client` is linked by name (string match) rather than a direct SwiftData relationship

---

## Project Structure

```
ContractorCashFlow/
├── ContractorCashFlowApp.swift           # App entry point, ModelContainer + CloudKit setup
├── LanguageManager.swift                 # Runtime language switching, RTL support
├── LocalizationKeys.swift                # Type-safe localization keys + StorageKey
├── Localizable.xcstrings                 # String catalog (EN, HE, RU)
├── Products.storekit                     # StoreKit configuration for local IAP testing
├── Info.plist                            # Background modes config
├── ContractorCashFlow.entitlements       # CloudKit, APS entitlements
│
├── Models/
│   ├── AppState.swift                    # Observable app state + AppTab enum
│   ├── ModelsProject.swift               # Project model with computed financials
│   ├── ModelsExpense.swift               # Expense model + ExpenseCategory enum; receiptImageData as CKAsset
│   └── ModelsInvoice.swift               # Invoice model
│
├── Views/
│   ├── ViewsRootTabView.swift            # Root 7-tab navigation
│   ├── ViewsProjectsListView.swift       # Projects: list, detail, edit, new, charts, export
│   ├── ViewsExpensesListView.swift       # Expenses: list, new, edit
│   ├── ExpenseFiltersView.swift          # Date range + category filters; contiguousRange fill logic
│   ├── ScanInvoiceView.swift             # Camera/photo OCR import entry point
│   ├── ScannedExpenseReviewView.swift    # Review and edit OCR-extracted fields before saving
│   ├── ViewsInvoicesListView.swift       # Invoices: list, filters, edit, new
│   ├── ViewsClientsListView.swift        # Clients: list, detail, edit, new
│   ├── ViewsLaborListView.swift          # Labor: list, filters, summary cards
│   ├── ViewsAddLaborView.swift           # Add new worker form
│   ├── ViewsEditLaborView.swift          # Edit worker with aggregated stats
│   ├── ModelsLaborDetails.swift          # LaborDetails model + LaborType enum
│   ├── PreviewSampleData.swift           # Sample data for SwiftUI previews + Client model
│   ├── ServicesNotificationService.swift # Local notification service
│   ├── ServicesPurchaseManager.swift     # StoreKit 2 subscription manager
│   ├── Services/InvoiceOCRService.swift  # Vision-based OCR; 5-strategy amount extraction
│   │
│   └── Settings/
│       ├── SettingsView.swift            # Settings: language, currency, notifications, export
│       ├── ViewsAnalyticsView.swift      # Analytics: 3 chart types (Swift Charts)
│       ├── PaywallView.swift             # Subscription paywall with plan selection
│       └── ServicesView+Notifications.swift # Notification view modifiers
│
├── ContractorCashFlowTests/
│   └── ContractorCashFlowTests.swift     # 107+ unit tests across 20 suites
│
└── ContractorCashFlowUITests/
    ├── ContractorCashFlowUITests.swift
    └── ContractorCashFlowUITestsLaunchTests.swift
```

---

## Localization

The app uses Apple's modern `Localizable.xcstrings` string catalog with type-safe key access through the `LocalizationKey` enum hierarchy.

### Supported Languages

| Language | Code | Layout Direction |
|----------|------|-----------------|
| English  | `en` | Left-to-Right    |
| Hebrew   | `he` | Right-to-Left    |
| Russian  | `ru` | Left-to-Right    |

### Adding a New Language

1. Add the language in Xcode's project settings under Localizations
2. Add a new case to `LanguageManager.SupportedLanguage`
3. Add a new case to `AppLanguageOption` in `SettingsView.swift`
4. Translate all entries in `Localizable.xcstrings`

---

## Testing

The project includes a comprehensive test suite using the Swift Testing framework.

### Test Suites (20 suites, 107+ tests)

| Suite | Tests | What It Covers |
|-------|-------|----------------|
| ProjectModelTests | 7 | Init, computed financials (expenses, income, balance, margins) |
| ExpenseModelTests | 3 | Init, project relationship, category names |
| InvoiceModelTests | 4 | Init, overdue detection logic |
| ClientModelTests | 2 | Full and minimal initialization |
| AppStateTests | 3 | Defaults, error handling, toggle flags |
| CurrencyFormattingTests | 3 | Positive, zero, and large amounts |
| DateCalculationTests | 2 | Comparisons and formatting |
| PercentageCalculationTests | 3 | Valid, zero-denominator, over-100% |
| InputValidationTests | 3 | Empty strings, positive numbers, email format |
| CollectionOperationsTests | 4 | Filter, reduce, sort, isEmpty |
| StringManipulationTests | 3 | Case-insensitive, contains, trimming |
| BusinessLogicTests | 3 | Profitability, over-budget, payment status |
| EdgeCaseTests | 5 | Empty data, zero amounts, boundary dates, large values, special chars |
| IntegrationTests | 2 | Full project lifecycle, multi-project client |
| PerformanceTests | 2 | 1000-expense calculation, 100-invoice filtering |
| LaborDetailsModelTests | 23 | Worker init, hourly/daily/contract rates, dual-rate support, `laborTypeSnapshot`, `totalCost` calculations, unit names |
| InvoiceOCRServiceTests | 27 | `extractAmount` (decimal, currency, requireDecimal, bounds), `extractTotalAmount` (all 5 strategies, EN/HE/RU keywords), `extractDate` (4 formats), `isNumericLine`, `bestDescription`, end-to-end `parse` |
| DateFilterLogicTests | 6 | `contiguousRange`: gap filling, single/empty → nil, month boundary, adjacent dates, already-contiguous passthrough |
| LaborExpenseLogicTests | 9 | `daysCount` decimal-pad parsing fix, empty/non-numeric strings, effective amount fallback chain, hourly and daily rate calculations |
| ExpenseReceiptDataTests | 5 | Default nil, store/retrieve, clear, `ScannedInvoiceData` init with and without optional fields |

### Running Tests

```bash
# Via Xcode
Cmd + U

# Via command line
xcodebuild test -scheme ContractorCashFlow -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## License

<!-- Add your license here -->
*License information coming soon.*

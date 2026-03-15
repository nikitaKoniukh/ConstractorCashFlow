# ContractorCashFlow

A comprehensive iOS app for construction contractors to manage projects, track expenses, create invoices, manage clients and workers, and visualize financial analytics — all from one place.

Built with **SwiftUI**, **SwiftData**, and **Swift Charts**. Supports **3 languages** (English, Hebrew, Russian) and **8 currencies**.

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
- Log expenses under 5 categories: Materials, Labor, Equipment, Subcontractor, Miscellaneous
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
- Set pay rates per type ($/hr, $/day, or fixed contract price)
- Link workers to labor expenses with automatic amount calculation
- Summary dashboard: total labor cost, worker count, days worked, average daily cost, total hours
- Filter workers by type, project, or month
- Sort by name, date added, or total earned
- Delete workers with confirmation — linked expenses are preserved but unlinked

### Financial Analytics
Three interactive charts powered by Swift Charts:

1. **Income vs. Expenses** — Donut chart with net balance displayed in the center
2. **Expenses by Category** — Horizontal bar chart with percentage annotations per category
3. **Budget Utilization per Project** — Grouped bar chart showing spent vs. remaining for up to 10 projects, with average utilization summary

All charts handle empty states gracefully.

### Notifications
Local push notifications for:
- **Invoice reminders** — 3 days before due date
- **Overdue alerts** — 1 day after due date (critical sound)
- **Budget warnings** — Immediate alerts at 80% and 100% budget utilization
- Each notification type can be toggled independently in Settings
- Notifications are automatically rescheduled when settings change

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

---

## Screenshots

<!-- Add screenshots here -->
*Screenshots coming soon.*

---

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Apple Developer account (for push notifications on device)

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
| Charts | Swift Charts (`SectorMark`, `BarMark`) |
| State Management | `@Observable` (Observation framework) |
| Notifications | `UNUserNotificationCenter` |
| Localization | `Localizable.xcstrings` + type-safe `LocalizationKey` enums |

### Patterns
- **Single-module architecture** — All code lives in one target with logical file grouping
- **Observable state** — `AppState` is an `@Observable` class injected via SwiftUI's `@Environment`, managing tab selection, navigation paths, sheet presentation flags, search queries, and error display
- **Per-tab NavigationPath** — Each tab maintains its own `NavigationPath` enabling pop-to-root on tab re-tap
- **SwiftData `@Query`** — Views use `@Query` with `#Predicate` for reactive, filtered data fetching directly from the model store
- **Singleton services** — `NotificationService` and `LanguageManager` are `@MainActor` singletons
- **Centralized error handling** — All CRUD operations use do/catch with errors surfaced via `AppState.showError()`

---

## Data Model

```
┌─────────────┐       ┌─────────────┐       ┌──────────────┐
│   Project    │───1:N─│   Expense   │───N:1─│ LaborDetails │
│              │       │             │       │   (Worker)   │
│  id          │       │  id         │       │              │
│  name        │       │  category   │       │  id          │
│  clientName  │       │  amount     │       │  workerName  │
│  budget      │       │  description│       │  laborType   │
│  createdDate │       │  date       │       │  rate        │
│  isActive    │       │  unitsWorked│       │  notes       │
│              │       │  project?   │       │  createdDate │
│  expenses[]  │       │  worker?    │       │  expenses[]  │
│  invoices[]  │       └─────────────┘       └──────────────┘
└──────┬──────┘
       │
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
├── ContractorCashFlowApp.swift          # App entry point, ModelContainer setup
├── ContentView.swift                     # Unused Xcode template
├── LanguageManager.swift                 # Runtime language switching, RTL support
├── LocalizationKeys.swift                # Type-safe localization keys + StorageKey
├── Localizable.xcstrings                 # String catalog (EN, HE, RU)
├── Info.plist                            # Background modes config
├── ContractorCashFlow.entitlements       # CloudKit, APS entitlements
│
├── Models/
│   ├── AppState.swift                    # Observable app state + AppTab enum
│   ├── ModelsProject.swift               # Project model with computed financials
│   ├── ModelsExpense.swift               # Expense model + ExpenseCategory enum
│   ├── ModelsInvoice.swift               # Invoice model
│   └── Item.swift                        # Unused Xcode template model
│
├── Views/
│   ├── ViewsRootTabView.swift            # Root 7-tab navigation
│   ├── ViewsProjectsListView.swift       # Projects: list, detail, edit, new, charts, export
│   ├── ViewsExpensesListView.swift       # Expenses: list, filters, new
│   ├── ViewsInvoicesListView.swift       # Invoices: list, filters, edit, new
│   ├── ViewsClientsListView.swift        # Clients: list, detail, edit, new
│   ├── ViewsLaborListView.swift          # Labor: list, filters, summary cards
│   ├── ViewsAddLaborView.swift           # Add new worker form
│   ├── ViewsEditLaborView.swift          # Edit worker with aggregated stats
│   ├── ModelsLaborDetails.swift          # LaborDetails model + LaborType enum
│   ├── PreviewSampleData.swift           # Sample data for SwiftUI previews + Client model
│   ├── ServicesNotificationService.swift # Local notification service
│   │
│   └── Settings/
│       ├── SettingsView.swift            # Settings: language, currency, notifications, export
│       ├── ViewsAnalyticsView.swift      # Analytics: 3 chart types (Swift Charts)
│       └── ServicesView+Notifications.swift # Notification view modifiers
│
├── ContractorCashFlowTests/
│   └── ContractorCashFlowTests.swift     # 40+ unit tests across 15 suites
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

### Test Suites (15 suites, 40+ tests)

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

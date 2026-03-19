//
//  AnalyticsView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Time Period Filter

enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case week   = "7D"
    case month  = "30D"
    case quarter = "90D"
    case year   = "1Y"
    case all    = "All"

    var id: String { rawValue }

    var startDate: Date? {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .week:    return cal.date(byAdding: .day, value: -7, to: now)
        case .month:   return cal.date(byAdding: .day, value: -30, to: now)
        case .quarter: return cal.date(byAdding: .day, value: -90, to: now)
        case .year:    return cal.date(byAdding: .year, value: -1, to: now)
        case .all:     return nil
        }
    }
}

// MARK: - Main View

struct AnalyticsView: View {
    @Query(sort: \Project.createdDate, order: .reverse) private var projects: [Project]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \Invoice.createdDate, order: .reverse) private var invoices: [Invoice]

    @Environment(AppState.self) private var appState
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode

    @State private var selectedPeriod: AnalyticsPeriod = .month

    private var filteredExpenses: [Expense] {
        guard let start = selectedPeriod.startDate else { return expenses }
        return expenses.filter { $0.date >= start }
    }

    private var filteredInvoices: [Invoice] {
        guard let start = selectedPeriod.startDate else { return invoices }
        return invoices.filter { $0.createdDate >= start }
    }

    private var totalIncome: Double {
        filteredInvoices.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    private var pendingIncome: Double {
        filteredInvoices.filter { !$0.isPaid && !$0.isOverdue }.reduce(0) { $0 + $1.amount }
    }

    private var overdueAmount: Double {
        filteredInvoices.filter { $0.isOverdue }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack(path: appState.navigationPath(for: .analytics)) {
            ScrollView {
                VStack(spacing: 20) {
                    // Period filter
                    periodPicker

                    // KPI summary row
                    kpiRow

                    // Income vs Expenses chart
                    IncomeExpensesChartCard(
                        totalIncome: totalIncome,
                        totalExpenses: totalExpenses
                    )

                    // Monthly trend
                    if selectedPeriod != .week {
                        MonthlyTrendCard(
                            expenses: filteredExpenses,
                            invoices: filteredInvoices,
                            period: selectedPeriod
                        )
                    }

                    // Expense breakdown by category
                    ExpenseByCategoryChartCard(expenses: filteredExpenses)

                    // Invoice status breakdown
                    InvoiceStatusCard(
                        paid: totalIncome,
                        pending: pendingIncome,
                        overdue: overdueAmount
                    )

                    // Budget utilization per project
                    if !projects.isEmpty {
                        BudgetUtilizationChartCard(projects: projects)
                    }

                    // Top projects by revenue
                    TopProjectsCard(projects: projects, period: selectedPeriod)
                }
                .padding()
            }
            .navigationTitle(LocalizationKey.Analytics.title)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsPeriod.allCases) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedPeriod == period ? .semibold : .regular)
                        .foregroundStyle(selectedPeriod == period ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == period
                                ? Color.accentColor
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(4)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - KPI Row

    private var kpiRow: some View {
        HStack(spacing: 12) {
            KPICard(
                title: LocalizationKey.Analytics.netBalance,
                value: totalIncome - totalExpenses,
                color: (totalIncome - totalExpenses) >= 0 ? .green : .red,
                icon: "scalemass.fill"
            )
            KPICard(
                title: LocalizationKey.Invoice.overdue,
                value: overdueAmount,
                color: overdueAmount > 0 ? .red : .secondary,
                icon: "exclamationmark.circle.fill"
            )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - KPI Card

private struct KPICard: View {
    let title: LocalizedStringKey
    let value: Double
    let color: Color
    let icon: String
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value, format: .currency(code: currencyCode))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Monthly Trend Card

struct MonthlyTrendCard: View {
    let expenses: [Expense]
    let invoices: [Invoice]
    let period: AnalyticsPeriod
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode

    struct MonthPoint: Identifiable {
        let id = UUID()
        let month: Date
        let income: Double
        let expense: Double
        var label: String {
            month.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
        }
    }

    private var points: [MonthPoint] {
        let cal = Calendar.current
        var buckets: [Date: (income: Double, expense: Double)] = [:]

        for invoice in invoices where invoice.isPaid {
            let start = cal.dateInterval(of: .month, for: invoice.createdDate)?.start ?? invoice.createdDate
            buckets[start, default: (0, 0)].income += invoice.amount
        }
        for expense in expenses {
            let start = cal.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
            buckets[start, default: (0, 0)].expense += expense.amount
        }

        return buckets
            .map { MonthPoint(month: $0.key, income: $0.value.income, expense: $0.value.expense) }
            .sorted { $0.month < $1.month }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKey.Analytics.monthlyTrend)
                .font(.headline)

            if points.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(points) { point in
                        LineMark(
                            x: .value(LocalizationKey.Analytics.chartMonthString, point.label),
                            y: .value(LocalizationKey.Analytics.chartAmountString, point.income),
                            series: .value(LocalizationKey.Analytics.chartTypeString, LocalizationKey.Analytics.chartIncomeString)
                        )
                        .foregroundStyle(Color.green)
                        .symbol(.circle)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value(LocalizationKey.Analytics.chartMonthString, point.label),
                            y: .value(LocalizationKey.Analytics.chartAmountString, point.income),
                            series: .value(LocalizationKey.Analytics.chartTypeString, LocalizationKey.Analytics.chartIncomeString)
                        )
                        .foregroundStyle(Color.green.opacity(0.15))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value(LocalizationKey.Analytics.chartMonthString, point.label),
                            y: .value(LocalizationKey.Analytics.chartAmountString, point.expense),
                            series: .value(LocalizationKey.Analytics.chartTypeString, LocalizationKey.Analytics.chartExpensesString)
                        )
                        .foregroundStyle(Color.red)
                        .symbol(.circle)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value(LocalizationKey.Analytics.chartMonthString, point.label),
                            y: .value(LocalizationKey.Analytics.chartAmountString, point.expense),
                            series: .value(LocalizationKey.Analytics.chartTypeString, LocalizationKey.Analytics.chartExpensesString)
                        )
                        .foregroundStyle(Color.red.opacity(0.15))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartForegroundStyleScale([
                    LocalizationKey.Analytics.chartIncomeString: Color.green,
                    LocalizationKey.Analytics.chartExpensesString: Color.red
                ])
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(amount, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartLegend(position: .bottom, spacing: 12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(LocalizationKey.Analytics.noTrendData)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Invoice Status Card

struct InvoiceStatusCard: View {
    let paid: Double
    let pending: Double
    let overdue: Double
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode

    private var total: Double { paid + pending + overdue }

    struct StatusItem: Identifiable {
        let id = UUID()
        let label: LocalizedStringKey
        let amount: Double
        let color: Color
    }

    private var items: [StatusItem] {
        [
            StatusItem(label: LocalizationKey.Invoice.paid, amount: paid, color: .green),
            StatusItem(label: LocalizationKey.Invoice.pending, amount: pending, color: .orange),
            StatusItem(label: LocalizationKey.Invoice.overdue, amount: overdue, color: .red)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKey.Analytics.invoiceStatus)
                .font(.headline)

            if total == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(LocalizationKey.Analytics.noInvoices)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Stacked bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(items.filter { $0.amount > 0 }) { item in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color)
                                .frame(width: geo.size.width * (item.amount / total))
                        }
                    }
                }
                .frame(height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Legend rows
                ForEach(items) { item in
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 10, height: 10)
                        Text(item.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(item.amount, format: .currency(code: currencyCode))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if total > 0 {
                            Text(item.amount / total, format: .percent.precision(.fractionLength(0)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Top Projects Card

struct TopProjectsCard: View {
    let projects: [Project]
    let period: AnalyticsPeriod
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode

    private var topProjects: [Project] {
        projects
            .filter { $0.totalIncome > 0 || $0.totalExpenses > 0 }
            .sorted { $0.totalIncome > $1.totalIncome }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKey.Analytics.topProjects)
                .font(.headline)

            if topProjects.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(LocalizationKey.Analytics.noProjectData)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(Array(topProjects.enumerated()), id: \.element.id) { index, project in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text(project.clientName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(project.totalIncome, format: .currency(code: currencyCode))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                            Text((project.balance >= 0 ? "+" : "") + project.balance.formatted(.currency(code: currencyCode)))
                                .font(.caption)
                                .foregroundStyle(project.balance >= 0 ? .green : .red)
                        }
                    }

                    if index < topProjects.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Income vs Expenses Chart

struct IncomeExpensesChartCard: View {
    let totalIncome: Double
    let totalExpenses: Double
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode

    private var netBalance: Double { totalIncome - totalExpenses }

    private var chartData: [FinancialItem] {
        [
            FinancialItem(category: .income, amount: totalIncome),
            FinancialItem(category: .expenses, amount: totalExpenses)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKey.Analytics.incomeVsExpenses)
                .font(.headline)

            if totalIncome == 0 && totalExpenses == 0 {
                emptyStateView
            } else {
                HStack(spacing: 32) {
                    Chart(chartData) { item in
                        SectorMark(
                            angle: .value(LocalizationKey.Analytics.chartAmountString, item.amount),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.category.color)
                        .cornerRadius(4)
                    }
                    .frame(height: 160)

                    VStack(alignment: .leading, spacing: 12) {
                        LegendItem(color: .green, label: LocalizationKey.Analytics.income, value: totalIncome)
                        LegendItem(color: .red, label: LocalizationKey.Analytics.expenses, value: totalExpenses)
                        Divider()
                        LegendItem(
                            color: netBalance >= 0 ? .green : .red,
                            label: LocalizationKey.Analytics.netBalance,
                            value: netBalance
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.pie")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(LocalizationKey.Analytics.noFinancialData)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Expense by Category Chart

struct ExpenseByCategoryChartCard: View {
    let expenses: [Expense]

    private var categoryData: [ExpenseCategoryData] {
        let grouped = Dictionary(grouping: expenses) { $0.category }
        return ExpenseCategory.allCases.map { category in
            let amount = grouped[category]?.reduce(0) { $0 + $1.amount } ?? 0
            return ExpenseCategoryData(category: category, amount: amount)
        }
        .filter { $0.amount > 0 }
        .sorted { $0.amount > $1.amount }
    }

    private var totalAmount: Double {
        categoryData.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKey.Analytics.expensesByCategory)
                .font(.headline)

            if totalAmount == 0 {
                emptyStateView
            } else {
                Chart(categoryData) { item in
                    BarMark(
                        x: .value(LocalizationKey.Analytics.chartAmountString, item.amount),
                        y: .value(LocalizationKey.Analytics.chartCategoryString, item.category.displayName)
                    )
                    .foregroundStyle(item.category.chartColor)
                    .cornerRadius(6)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text(item.percentage(of: totalAmount), format: .percent.precision(.fractionLength(0)))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                    }
                }
                .frame(height: CGFloat(categoryData.count * 44 + 20))
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let category = value.as(String.self) {
                                HStack(spacing: 6) {
                                    if let ec = ExpenseCategory.allCases.first(where: { $0.displayName == category }) {
                                        Circle().fill(ec.chartColor).frame(width: 8, height: 8)
                                    }
                                    Text(category).font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(LocalizationKey.Analytics.noExpenseData)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Budget Utilization Chart

struct BudgetUtilizationChartCard: View {
    let projects: [Project]
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode

    private var projectData: [ProjectBudgetData] {
        projects
            .filter { $0.budget > 0 }
            .sorted { $0.budgetUtilization > $1.budgetUtilization }
            .prefix(8)
            .map { ProjectBudgetData(project: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKey.Analytics.budgetUtilization)
                .font(.headline)

            if projectData.isEmpty {
                emptyStateView
            } else {
                Chart {
                    ForEach(projectData) { data in
                        BarMark(
                            x: .value(LocalizationKey.Analytics.chartAmountString, data.spent),
                            y: .value(LocalizationKey.Analytics.chartProjectString, data.projectName)
                        )
                        .foregroundStyle(data.utilizationPercentage >= 100 ? .red : data.utilizationPercentage >= 80 ? .orange : .blue)
                        .cornerRadius(4)
                    }
                }
                .frame(height: CGFloat(projectData.count * 44 + 40))
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(amount, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name).font(.caption).lineLimit(1)
                            }
                        }
                    }
                }

                // Color legend
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle().fill(.blue).frame(width: 8, height: 8)
                        Text(LocalizationKey.Analytics.budgetUnder80).font(.caption).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(.orange).frame(width: 8, height: 8)
                        Text(LocalizationKey.Analytics.budgetRange80to100).font(.caption).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text(LocalizationKey.Analytics.budgetOver100).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(LocalizationKey.Analytics.noProjectData)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Supporting Views

struct LegendItem: View {
    let color: Color
    let label: LocalizedStringKey
    let value: Double
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = StorageKey.defaultCurrencyCode

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value, format: .currency(code: currencyCode))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Data Models

struct FinancialItem: Identifiable {
    let id = UUID()
    let category: FinancialCategory
    let amount: Double
}

enum FinancialCategory {
    case income
    case expenses

    var color: Color {
        switch self {
        case .income:   return .green
        case .expenses: return .red
        }
    }
}

struct ExpenseCategoryData: Identifiable {
    let id = UUID()
    let category: ExpenseCategory
    let amount: Double

    func percentage(of total: Double) -> Double {
        guard total > 0 else { return 0 }
        return amount / total
    }
}

struct ProjectBudgetData: Identifiable {
    let id: UUID
    let projectName: String
    let budget: Double
    let spent: Double

    init(project: Project) {
        self.id = project.id
        self.projectName = project.name
        self.budget = project.budget
        self.spent = project.totalExpenses
    }

    var remaining: Double { max(0, budget - spent) }

    var utilizationPercentage: Double {
        guard budget > 0 else { return 0 }
        return (spent / budget) * 100
    }
}

// MARK: - ExpenseCategory Extension

extension ExpenseCategory {
    var chartColor: Color {
        switch self {
        case .materials: return .blue
        case .labor:     return .orange
        case .equipment: return .gray
        case .misc:      return .purple
        }
    }
}

// MARK: - Preview

#Preview("Analytics with Sample Data") {
    AnalyticsView()
        .environment(AppState())
        .modelContainer(PreviewSampleData.makePreviewContainer())
}

#Preview("Analytics Empty State") {
    AnalyticsView()
        .environment(AppState())
        .modelContainer(for: [Project.self, Expense.self, Invoice.self], inMemory: true)
}

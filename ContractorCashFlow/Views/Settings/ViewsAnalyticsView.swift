//
//  AnalyticsView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \Project.createdDate, order: .reverse) private var projects: [Project]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \Invoice.createdDate, order: .reverse) private var invoices: [Invoice]
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack(path: appState.navigationPath(for: .analytics)) {
            ScrollView {
                VStack(spacing: 24) {
                    // Income vs Expenses Overview
                    IncomeExpensesChartCard(
                        totalIncome: totalIncome,
                        totalExpenses: totalExpenses
                    )
                    
                    // Expense Breakdown by Category
                    ExpenseByCategoryChartCard(expenses: expenses)
                    
                    // Budget Utilization per Project
                    if !projects.isEmpty {
                        BudgetUtilizationChartCard(projects: projects)
                    }
                }
                .padding()
            }
            .navigationTitle(LocalizationKey.Analytics.title)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var totalIncome: Double {
        invoices.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Income vs Expenses Chart

struct IncomeExpensesChartCard: View {
    let totalIncome: Double
    let totalExpenses: Double
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
    private var netBalance: Double {
        totalIncome - totalExpenses
    }
    
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
                    // Donut Chart
                    Chart(chartData) { item in
                        SectorMark(
                            angle: .value(String(localized: "analytics.chart.amount"), item.amount),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.category.color)
                        .cornerRadius(4)
                    }
                    .frame(height: 180)
                    .chartBackground { _ in
                        VStack(spacing: 4) {
                            Text(netBalance, format: .currency(code: currencyCode))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(netBalance >= 0 ? .green : .red)
                            Text(LocalizationKey.Analytics.netBalance)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Legend with values
                    VStack(alignment: .leading, spacing: 12) {
                        LegendItem(
                            color: .green,
                            label: LocalizationKey.Analytics.income,
                            value: totalIncome
                        )
                        
                        LegendItem(
                            color: .red,
                            label: LocalizationKey.Analytics.expenses,
                            value: totalExpenses
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
                // Horizontal Bar Chart
                Chart(categoryData) { item in
                    BarMark(
                        x: .value(String(localized: "analytics.chart.amount"), item.amount),
                        y: .value(String(localized: "analytics.chart.category"), item.category.displayName)
                    )
                    .foregroundStyle(item.category.chartColor)
                    .cornerRadius(6)
                    .annotation(position: .trailing, alignment: .leading) {
                        if item.amount > 0 {
                            Text(item.percentage(of: totalAmount), format: .percent.precision(.fractionLength(0)))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                        }
                    }
                }
                .frame(height: 200)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let category = value.as(String.self) {
                                HStack(spacing: 8) {
                                    if let expenseCategory = ExpenseCategory.allCases.first(where: { $0.displayName == category }) {
                                        Circle()
                                            .fill(expenseCategory.chartColor)
                                            .frame(width: 8, height: 8)
                                    }
                                    Text(category)
                                        .font(.subheadline)
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
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
    private var projectData: [ProjectBudgetData] {
        projects
            .filter { $0.budget > 0 }
            .prefix(10) // Show top 10 projects
            .map { ProjectBudgetData(project: $0) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKey.Analytics.budgetUtilization)
                .font(.headline)
            
            if projectData.isEmpty {
                emptyStateView
            } else {
                // Grouped Bar Chart
                Chart {
                    ForEach(projectData) { data in
                        BarMark(
                            x: .value(String(localized: "analytics.chart.amount"), data.spent),
                            y: .value(String(localized: "analytics.chart.project"), data.projectName)
                        )
                        .foregroundStyle(.orange)
                        .position(by: .value(
                            String(localized: "analytics.chart.type"),
                            String(localized: "analytics.spent")
                        ))
                        
                        BarMark(
                            x: .value(String(localized: "analytics.chart.amount"), data.remaining),
                            y: .value(String(localized: "analytics.chart.project"), data.projectName)
                        )
                        .foregroundStyle(.blue.opacity(0.3))
                        .position(by: .value(
                            String(localized: "analytics.chart.type"),
                            String(localized: "analytics.remaining")
                        ))
                    }
                }
                .frame(height: CGFloat(projectData.count * 44 + 60))
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(amount, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .chartForegroundStyleScale([
                    String(localized: "analytics.spent"): .orange,
                    String(localized: "analytics.remaining"): .blue.opacity(0.3)
                ])
                .chartLegend(position: .bottom, spacing: 16)
                
                // Summary stats
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(LocalizationKey.Analytics.averageUtilization)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(averageUtilization, format: .percent.precision(.fractionLength(1)))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(utilizationColor)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    private var averageUtilization: Double {
        guard !projectData.isEmpty else { return 0 }
        let total = projectData.reduce(0.0) { $0 + $1.utilizationPercentage }
        return total / Double(projectData.count) / 100
    }
    
    private var utilizationColor: Color {
        let avg = averageUtilization
        if avg < 0.5 { return .green }
        if avg < 0.8 { return .orange }
        return .red
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
    @AppStorage(StorageKey.selectedCurrencyCode) private var currencyCode = "USD"
    
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
        case .income: return .green
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
    
    var remaining: Double {
        max(0, budget - spent)
    }
    
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
        case .labor: return .orange
        case .equipment: return .gray
        case .subcontractor: return .teal
        case .misc: return .purple
        }
    }
}

// MARK: - Preview

#Preview("Analytics with Sample Data") {
    AnalyticsView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}

#Preview("Analytics Empty State") {
    AnalyticsView()
        .modelContainer(for: [Project.self, Expense.self, Invoice.self], inMemory: true)
}

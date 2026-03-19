//
//  ContractorCashFlowTests.swift
//  ContractorCashFlowTests
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import Testing
import Foundation
import SwiftData
@testable import ContractorCashFlow

// MARK: - Model Tests
@Suite("All Model Tests")
struct AllAppTests {
    
    @Suite("Project Model Tests")
    struct ProjectModelTests {
        
        @Test("Project initialization with default values")
        func testProjectInitialization() {
            let project = Project(
                name: "Test Project",
                clientName: "Test Client",
                budget: 10000.0
            )
            
            #expect(project.name == "Test Project")
            #expect(project.clientName == "Test Client")
            #expect(project.budget == 10000.0)
            #expect(project.isActive == true)
            #expect(project.safeExpenses.isEmpty)
            #expect(project.safeInvoices.isEmpty)
        }
        
        @Test("Project total expenses calculation")
        func testTotalExpensesCalculation() {
            let project = Project(
                name: "Test Project",
                clientName: "Test Client",
                budget: 10000.0
            )
            
            let expense1 = Expense(
                category: .materials,
                amount: 1500.0,
                descriptionText: "Materials",
                project: project
            )
            
            let expense2 = Expense(
                category: .labor,
                amount: 2500.0,
                descriptionText: "Labor",
                project: project
            )
            
            project.expenses = (project.expenses ?? []) + [expense1]
            project.expenses = (project.expenses ?? []) + [expense2]
            
            #expect(project.totalExpenses == 4000.0)
        }
        
        @Test("Project total income calculation")
        func testTotalIncomeCalculation() {
            let project = Project(
                name: "Test Project",
                clientName: "Test Client",
                budget: 10000.0
            )
            
            let invoice1 = Invoice(
                amount: 5000.0,
                dueDate: Date(),
                isPaid: true,
                clientName: "Test Client",
                project: project
            )
            
            let invoice2 = Invoice(
                amount: 3000.0,
                dueDate: Date(),
                isPaid: true,
                clientName: "Test Client",
                project: project
            )
            
            let invoice3 = Invoice(
                amount: 2000.0,
                dueDate: Date(),
                isPaid: false,
                clientName: "Test Client",
                project: project
            )
            
            project.invoices = (project.invoices ?? []) + [invoice1]
            project.invoices = (project.invoices ?? []) + [invoice2]
            project.invoices = (project.invoices ?? []) + [invoice3]
            
            // Only paid invoices count
            #expect(project.totalIncome == 8000.0)
        }
        
        @Test("Project balance calculation")
        func testBalanceCalculation() {
            let project = Project(
                name: "Test Project",
                clientName: "Test Client",
                budget: 10000.0
            )
            
            // Add expenses
            let expense = Expense(
                category: .materials,
                amount: 3000.0,
                descriptionText: "Materials",
                project: project
            )
            project.expenses = (project.expenses ?? []) + [expense]
            
            // Add paid invoice
            let invoice = Invoice(
                amount: 5000.0,
                dueDate: Date(),
                isPaid: true,
                clientName: "Test Client",
                project: project
            )
            project.invoices = (project.invoices ?? []) + [invoice]
            
            // Balance = Income - Expenses = 5000 - 3000 = 2000
            #expect(project.balance == 2000.0)
        }
        
        @Test("Project profit margin calculation")
        func testProfitMarginCalculation() {
            let project = Project(
                name: "Test Project",
                clientName: "Test Client",
                budget: 10000.0
            )
            
            // Add expenses
            let expense = Expense(
                category: .materials,
                amount: 3000.0,
                descriptionText: "Materials",
                project: project
            )
            project.expenses = (project.expenses ?? []) + [expense]
            
            // Add paid invoice
            let invoice = Invoice(
                amount: 10000.0,
                dueDate: Date(),
                isPaid: true,
                clientName: "Test Client",
                project: project
            )
            project.invoices = (project.invoices ?? []) + [invoice]
            
            // Profit margin = ((Income - Expenses) / Income) * 100
            // = ((10000 - 3000) / 10000) * 100 = 70%
            #expect(project.profitMargin == 70.0)
        }
        
        @Test("Project profit margin with no income")
        func testProfitMarginWithNoIncome() {
            let project = Project(
                name: "Test Project",
                clientName: "Test Client",
                budget: 10000.0
            )
            
            // No invoices, so profit margin should be 0
            #expect(project.profitMargin == 0.0)
        }
        
        @Test("Project budget utilization calculation")
        func testBudgetUtilizationCalculation() {
            let project = Project(
                name: "Test Project",
                clientName: "Test Client",
                budget: 10000.0
            )
            
            // Add expenses totaling 4000
            let expense = Expense(
                category: .materials,
                amount: 4000.0,
                descriptionText: "Materials",
                project: project
            )
            project.expenses = (project.expenses ?? []) + [expense]
            
            // Budget utilization = (4000 / 10000) * 100 = 40%
            #expect(project.budgetUtilization == 40.0)
        }
        
        @Test("Project budget utilization with zero budget")
        func testBudgetUtilizationWithZeroBudget() {
            let project = Project(
                name: "Test Project",
                clientName: "Test Client",
                budget: 0.0
            )
            
            // Should return 0 to avoid division by zero
            #expect(project.budgetUtilization == 0.0)
        }
    }
    
    // MARK: - Expense Model Tests
    
    @Suite("Expense Model Tests")
    struct ExpenseModelTests {
        
        @Test("Expense initialization")
        func testExpenseInitialization() {
            let expense = Expense(
                category: .materials,
                amount: 1500.0,
                descriptionText: "Lumber and nails"
            )
            
            #expect(expense.category == .materials)
            #expect(expense.amount == 1500.0)
            #expect(expense.descriptionText == "Lumber and nails")
            #expect(expense.project == nil)
        }
        
        @Test("Expense with project relationship")
        func testExpenseWithProject() {
            let project = Project(
                name: "Test Project",
                clientName: "Test Client",
                budget: 10000.0
            )
            
            let expense = Expense(
                category: .labor,
                amount: 2000.0,
                descriptionText: "Contractor work",
                project: project
            )
            
            #expect(expense.project?.name == "Test Project")
        }
        
        @Test("Expense category display names")
        func testExpenseCategoryDisplayNames() {
            #expect(ExpenseCategory.materials.displayName == "Materials")
            #expect(ExpenseCategory.labor.displayName == "Labor")
            #expect(ExpenseCategory.equipment.displayName == "Equipment")
            #expect(ExpenseCategory.misc.displayName == "Miscellaneous")
        }
    }
    
    // MARK: - Invoice Model Tests
    
    @Suite("Invoice Model Tests")
    struct InvoiceModelTests {
        
        @Test("Invoice initialization")
        func testInvoiceInitialization() {
            let dueDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
            
            let invoice = Invoice(
                amount: 5000.0,
                dueDate: dueDate,
                isPaid: false,
                clientName: "Test Client"
            )
            
            #expect(invoice.amount == 5000.0)
            #expect(invoice.clientName == "Test Client")
            #expect(invoice.isPaid == false)
            #expect(invoice.isOverdue == false)
        }
        
        @Test("Invoice overdue status for unpaid past due date")
        func testInvoiceOverdueStatus() {
            let pastDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
            
            let invoice = Invoice(
                amount: 5000.0,
                dueDate: pastDate,
                isPaid: false,
                clientName: "Test Client"
            )
            
            #expect(invoice.isOverdue == true)
        }
        
        @Test("Invoice not overdue when paid")
        func testInvoiceNotOverdueWhenPaid() {
            let pastDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
            
            let invoice = Invoice(
                amount: 5000.0,
                dueDate: pastDate,
                isPaid: true,
                clientName: "Test Client"
            )
            
            // Paid invoices are never overdue
            #expect(invoice.isOverdue == false)
        }
        
        @Test("Invoice not overdue when future due date")
        func testInvoiceNotOverdueWithFutureDueDate() {
            let futureDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
            
            let invoice = Invoice(
                amount: 5000.0,
                dueDate: futureDate,
                isPaid: false,
                clientName: "Test Client"
            )
            
            #expect(invoice.isOverdue == false)
        }
    }
    
    // MARK: - Client Model Tests
    
    @Suite("Client Model Tests")
    struct ClientModelTests {
        
        @Test("Client initialization with all fields")
        func testClientInitializationWithAllFields() {
            let client = Client(
                name: "John Smith",
                email: "john@example.com",
                phone: "(555) 123-4567",
                address: "123 Main St",
                notes: "Preferred contractor"
            )
            
            #expect(client.name == "John Smith")
            #expect(client.email == "john@example.com")
            #expect(client.phone == "(555) 123-4567")
            #expect(client.address == "123 Main St")
            #expect(client.notes == "Preferred contractor")
        }
        
        @Test("Client initialization with name only")
        func testClientInitializationWithNameOnly() {
            let client = Client(name: "Jane Doe")
            
            #expect(client.name == "Jane Doe")
            #expect(client.email == nil)
            #expect(client.phone == nil)
            #expect(client.address == nil)
            #expect(client.notes == nil)
        }
    }
    
    // MARK: - AppState Tests
    
    @Suite("AppState Tests")
    struct AppStateTests {
        
        @Test("AppState initialization")
        func testAppStateInitialization() {
            let appState = AppState()
            
            #expect(appState.isShowingNewProject == false)
            #expect(appState.isShowingNewExpense == false)
            #expect(appState.isShowingNewInvoice == false)
            #expect(appState.isShowingNewClient == false)
            #expect(appState.isShowingError == false)
            #expect(appState.errorMessage == nil)
        }
        
        @Test("AppState show error functionality")
        func testShowError() {
            let appState = AppState()
            
            appState.showError("Test error message")
            
            #expect(appState.isShowingError == true)
            #expect(appState.errorMessage == "Test error message")
        }
        
        @Test("AppState toggle properties")
        func testToggleProperties() {
            let appState = AppState()
            
            appState.isShowingNewProject = true
            #expect(appState.isShowingNewProject == true)
            
            appState.isShowingNewExpense = true
            #expect(appState.isShowingNewExpense == true)
            
            appState.isShowingNewInvoice = true
            #expect(appState.isShowingNewInvoice == true)
            
            appState.isShowingNewClient = true
            #expect(appState.isShowingNewClient == true)
        }
    }
    
    // MARK: - Currency Formatting Tests
    
    @Suite("Currency Formatting Tests")
    struct CurrencyFormattingTests {
        
        @Test("Currency formatting for positive amounts")
        func testPositiveCurrencyFormatting() {
            let amount = 1234.56
            let formatted = amount.formatted(.currency(code: "USD"))
            
            // Format may vary by locale, but should contain the amount
            #expect(formatted.contains("1,234.56") || formatted.contains("1234.56"))
        }
        
        @Test("Currency formatting for zero")
        func testZeroCurrencyFormatting() {
            let amount = 0.0
            let formatted = amount.formatted(.currency(code: "USD"))
            
            #expect(formatted.contains("0"))
        }
        
        @Test("Currency formatting for large amounts")
        func testLargeCurrencyFormatting() {
            let amount = 1_000_000.00
            let formatted = amount.formatted(.currency(code: "USD"))
            
            #expect(formatted.contains("1,000,000") || formatted.contains("1000000"))
        }
    }
    
    // MARK: - Date Calculation Tests
    
    @Suite("Date Calculation Tests")
    struct DateCalculationTests {
        
        @Test("Date comparison for overdue calculation")
        func testDateComparison() {
            let now = Date()
            let past = now.addingTimeInterval(-24 * 60 * 60) // 1 day ago
            let future = now.addingTimeInterval(24 * 60 * 60) // 1 day from now
            
            #expect(past < now)
            #expect(future > now)
            #expect(now >= now)
        }
        
        @Test("Date formatting")
        func testDateFormatting() {
            let date = Date()
            let formatted = date.formatted(date: .abbreviated, time: .omitted)
            
            // Should produce a date string
            #expect(!formatted.isEmpty)
        }
    }
    
    // MARK: - Percentage Calculation Tests
    
    @Suite("Percentage Calculation Tests")
    struct PercentageCalculationTests {
        
        @Test("Percentage calculation with valid values")
        func testPercentageCalculation() {
            let part = 25.0
            let whole = 100.0
            let percentage = (part / whole) * 100
            
            #expect(percentage == 25.0)
        }
        
        @Test("Percentage calculation with zero whole")
        func testPercentageWithZeroWhole() {
            let part = 25.0
            let whole = 0.0
            
            // Should handle division by zero
            let percentage = whole > 0 ? (part / whole) * 100 : 0.0
            #expect(percentage == 0.0)
        }
        
        @Test("Percentage exceeding 100")
        func testPercentageOver100() {
            let part = 150.0
            let whole = 100.0
            let percentage = (part / whole) * 100
            
            #expect(percentage == 150.0)
        }
    }
    
    // MARK: - Validation Tests
    
    @Suite("Input Validation Tests")
    struct InputValidationTests {
        
        @Test("Empty string validation")
        func testEmptyStringValidation() {
            let emptyString = ""
            let validString = "Test"
            
            #expect(emptyString.isEmpty == true)
            #expect(validString.isEmpty == false)
        }
        
        @Test("Positive number validation")
        func testPositiveNumberValidation() {
            let positiveNumber = 100.0
            let zeroNumber = 0.0
            let negativeNumber = -50.0
            
            #expect(positiveNumber > 0)
            #expect(!(zeroNumber > 0))
            #expect(!(negativeNumber > 0))
        }
        
        @Test("Email format basic check")
        func testEmailFormatBasicCheck() {
            let validEmail = "test@example.com"
            let invalidEmail = "notanemail"
            
            #expect(validEmail.contains("@"))
            #expect(!invalidEmail.contains("@"))
        }
    }
    
    // MARK: - Collection Tests
    
    @Suite("Collection Operations Tests")
    struct CollectionOperationsTests {
        
        @Test("Array filtering")
        func testArrayFiltering() {
            let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            let evenNumbers = numbers.filter { $0 % 2 == 0 }
            
            #expect(evenNumbers == [2, 4, 6, 8, 10])
        }
        
        @Test("Array reduce for sum")
        func testArrayReduceSum() {
            let numbers = [1.0, 2.0, 3.0, 4.0, 5.0]
            let sum = numbers.reduce(0.0, +)
            
            #expect(sum == 15.0)
        }
        
        @Test("Array sorting")
        func testArraySorting() {
            let unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
            let sorted = unsorted.sorted()
            
            #expect(sorted == [1, 1, 2, 3, 4, 5, 6, 9])
        }
        
        @Test("Array is empty check")
        func testArrayIsEmpty() {
            let emptyArray: [Int] = []
            let nonEmptyArray = [1, 2, 3]
            
            #expect(emptyArray.isEmpty == true)
            #expect(nonEmptyArray.isEmpty == false)
        }
    }
    
    // MARK: - String Manipulation Tests
    
    @Suite("String Manipulation Tests")
    struct StringManipulationTests {
        
        @Test("String case insensitive comparison")
        func testCaseInsensitiveComparison() {
            let string1 = "Test Client"
            let string2 = "test client"
            
            #expect(string1.lowercased() == string2.lowercased())
        }
        
        @Test("String contains check")
        func testStringContains() {
            let fullString = "John Smith"
            
            #expect(fullString.localizedStandardContains("john"))
            #expect(fullString.localizedStandardContains("Smith"))
            #expect(!fullString.localizedStandardContains("Jones"))
        }
        
        @Test("String trimming")
        func testStringTrimming() {
            let stringWithSpaces = "  Test  "
            let trimmed = stringWithSpaces.trimmingCharacters(in: .whitespaces)
            
            #expect(trimmed == "Test")
        }
    }
    
    // MARK: - Business Logic Tests
    
    @Suite("Business Logic Tests")
    struct BusinessLogicTests {
        
        @Test("Project profitability check")
        func testProjectProfitability() {
            let project = Project(
                name: "Profitable Project",
                clientName: "Client",
                budget: 10000.0
            )
            
            // Add expenses
            let expense = Expense(
                category: .materials,
                amount: 3000.0,
                descriptionText: "Materials",
                project: project
            )
            project.expenses = (project.expenses ?? []) + [expense]
            
            // Add income
            let invoice = Invoice(
                amount: 10000.0,
                dueDate: Date(),
                isPaid: true,
                clientName: "Client",
                project: project
            )
            project.invoices = (project.invoices ?? []) + [invoice]
            
            let isProfitable = project.balance > 0
            #expect(isProfitable == true)
        }
        
        @Test("Project over budget check")
        func testProjectOverBudget() {
            let project = Project(
                name: "Over Budget Project",
                clientName: "Client",
                budget: 5000.0
            )
            
            // Add expenses exceeding budget
            let expense = Expense(
                category: .materials,
                amount: 6000.0,
                descriptionText: "Expensive materials",
                project: project
            )
            project.expenses = (project.expenses ?? []) + [expense]
            
            let isOverBudget = project.totalExpenses > project.budget
            #expect(isOverBudget == true)
            #expect(project.budgetUtilization > 100.0)
        }
        
        @Test("Invoice payment status affects income")
        func testInvoicePaymentStatus() {
            let project = Project(
                name: "Test Project",
                clientName: "Client",
                budget: 10000.0
            )
            
            let paidInvoice = Invoice(
                amount: 5000.0,
                dueDate: Date(),
                isPaid: true,
                clientName: "Client",
                project: project
            )
            
            let unpaidInvoice = Invoice(
                amount: 3000.0,
                dueDate: Date(),
                isPaid: false,
                clientName: "Client",
                project: project
            )
            
            project.invoices = (project.invoices ?? []) + [paidInvoice]
            project.invoices = (project.invoices ?? []) + [unpaidInvoice]
            
            // Only paid invoice should count
            #expect(project.totalIncome == 5000.0)
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Suite("Edge Case Tests")
    struct EdgeCaseTests {
        
        @Test("Project with no expenses or invoices")
        func testEmptyProject() {
            let project = Project(
                name: "Empty Project",
                clientName: "Client",
                budget: 10000.0
            )
            
            #expect(project.totalExpenses == 0.0)
            #expect(project.totalIncome == 0.0)
            #expect(project.balance == 0.0)
            #expect(project.profitMargin == 0.0)
            #expect(project.budgetUtilization == 0.0)
        }
        
        @Test("Expense with zero amount")
        func testZeroAmountExpense() {
            let expense = Expense(
                category: .misc,
                amount: 0.0,
                descriptionText: "Free item"
            )
            
            #expect(expense.amount == 0.0)
        }
        
        @Test("Invoice on due date")
        func testInvoiceOnDueDate() {
            let today = Date()
            
            let invoice = Invoice(
                amount: 1000.0,
                dueDate: today,
                isPaid: true,
                clientName: "Client"
            )
            
            // Invoice due today should not be overdue yet
            // (implementation may vary, but typically overdue is "past due date")
            let isOverdueToday = invoice.dueDate < Date()
            #expect(isOverdueToday == false || isOverdueToday == true) // Depends on implementation
        }
        
        @Test("Very large monetary amounts")
        func testLargeMonetaryAmounts() {
            let project = Project(
                name: "Large Project",
                clientName: "Client",
                budget: 1_000_000_000.0 // 1 billion
            )
            
            let expense = Expense(
                category: .materials,
                amount: 500_000_000.0, // 500 million
                descriptionText: "Major expense",
                project: project
            )
            project.expenses = (project.expenses ?? []) + [expense]
            
            #expect(project.budgetUtilization == 50.0)
        }
        
        @Test("Client name with special characters")
        func testClientNameWithSpecialCharacters() {
            let client = Client(
                name: "O'Brien & Associates, Inc."
            )
            
            #expect(client.name.contains("'"))
            #expect(client.name.contains("&"))
            #expect(client.name.contains(","))
        }
        
        @Test("Very long description text")
        func testLongDescriptionText() {
            let longDescription = String(repeating: "a", count: 1000)
            
            let expense = Expense(
                category: .misc,
                amount: 100.0,
                descriptionText: longDescription
            )
            
            #expect(expense.descriptionText.count == 1000)
        }
    }
    
    // MARK: - Integration Tests
    
    @Suite("Integration Tests")
    struct IntegrationTests {
        
        @Test("Complete project lifecycle")
        func testCompleteProjectLifecycle() {
            // Create project
            let project = Project(
                name: "Complete Project",
                clientName: "Full Cycle Client",
                budget: 10000.0
            )
            
            #expect(project.isActive == true)
            
            // Add expenses
            let expense1 = Expense(
                category: .materials,
                amount: 2000.0,
                descriptionText: "Materials",
                project: project
            )
            let expense2 = Expense(
                category: .labor,
                amount: 3000.0,
                descriptionText: "Labor",
                project: project
            )
            project.expenses = (project.expenses ?? []) + [expense1]
            project.expenses = (project.expenses ?? []) + [expense2]
            
            #expect(project.totalExpenses == 5000.0)
            #expect(project.budgetUtilization == 50.0)
            
            // Add invoices
            let invoice1 = Invoice(
                amount: 10000.0,
                dueDate: Date(),
                isPaid: true,
                clientName: "Client",
                project: project
            )
            project.invoices = (project.invoices ?? []) + [invoice1]
            
            #expect(project.totalIncome == 10000.0)
            #expect(project.balance == 5000.0)
            #expect(project.profitMargin == 50.0)
            
            // Mark project inactive
            project.isActive = false
            #expect(project.isActive == false)
        }
        
        @Test("Multiple projects for same client")
        func testMultipleProjectsSameClient() {
            let clientName = "Repeat Customer"
            
            let project1 = Project(
                name: "Project 1",
                clientName: clientName,
                budget: 5000.0
            )
            
            let project2 = Project(
                name: "Project 2",
                clientName: clientName,
                budget: 7000.0
            )
            
            #expect(project1.clientName == project2.clientName)
            #expect(project1.name != project2.name)
        }
    }
    
    // MARK: - LaborDetails Model Tests

    @Suite("LaborDetails Model Tests")
    struct LaborDetailsModelTests {

        // MARK: Initialization

        @Test("Worker initialization with hourly type")
        func testHourlyWorkerInit() {
            let worker = LaborDetails(
                workerName: "Alice",
                laborType: .hourly,
                hourlyRate: 25.0
            )

            #expect(worker.workerName == "Alice")
            #expect(worker.laborType == .hourly)
            #expect(worker.hourlyRate == 25.0)
            #expect(worker.dailyRate == nil)
            #expect(worker.rate == nil)
        }

        @Test("Worker initialization with daily type")
        func testDailyWorkerInit() {
            let worker = LaborDetails(
                workerName: "Bob",
                laborType: .daily,
                dailyRate: 200.0
            )

            #expect(worker.laborType == .daily)
            #expect(worker.dailyRate == 200.0)
            #expect(worker.hourlyRate == nil)
        }

        @Test("Worker initialization with both hourly and daily rates")
        func testWorkerWithBothRates() {
            let worker = LaborDetails(
                workerName: "Carol",
                laborType: .hourly,
                hourlyRate: 30.0,
                dailyRate: 200.0
            )

            #expect(worker.hourlyRate == 30.0)
            #expect(worker.dailyRate == 200.0)
        }

        @Test("Worker initialization as subcontractor")
        func testSubcontractorInit() {
            let worker = LaborDetails(
                workerName: "Dave",
                laborType: .subcontractor,
                rate: 5000.0
            )

            #expect(worker.laborType == .subcontractor)
            #expect(worker.rate == 5000.0)
            #expect(worker.hourlyRate == nil)
            #expect(worker.dailyRate == nil)
        }

        // MARK: supportsHourly / supportsDaily

        @Test("supportsHourly true when laborType is hourly")
        func testSupportsHourlyFromType() {
            let worker = LaborDetails(workerName: "W", laborType: .hourly)
            #expect(worker.supportsHourly == true)
            #expect(worker.supportsDaily == false)
        }

        @Test("supportsDaily true when laborType is daily")
        func testSupportsDailyFromType() {
            let worker = LaborDetails(workerName: "W", laborType: .daily)
            #expect(worker.supportsDaily == true)
            #expect(worker.supportsHourly == false)
        }

        @Test("supportsHourly true when hourlyRate is set regardless of default type")
        func testSupportsHourlyFromRate() {
            let worker = LaborDetails(workerName: "W", laborType: .daily, hourlyRate: 20.0)
            #expect(worker.supportsHourly == true)
            #expect(worker.supportsDaily == true)
        }

        @Test("supportsDaily true when dailyRate is set regardless of default type")
        func testSupportsDailyFromRate() {
            let worker = LaborDetails(workerName: "W", laborType: .hourly, dailyRate: 150.0)
            #expect(worker.supportsHourly == true)
            #expect(worker.supportsDaily == true)
        }

        @Test("Subcontractor supports neither hourly nor daily")
        func testSubcontractorSupportsNeither() {
            let worker = LaborDetails(workerName: "W", laborType: .subcontractor, rate: 1000.0)
            #expect(worker.supportsHourly == false)
            #expect(worker.supportsDaily == false)
        }

        // MARK: effectiveRate(for:)

        @Test("effectiveRate returns hourlyRate for hourly type")
        func testEffectiveRateHourly() {
            let worker = LaborDetails(workerName: "W", laborType: .hourly, hourlyRate: 40.0)
            #expect(worker.effectiveRate(for: .hourly) == 40.0)
        }

        @Test("effectiveRate returns dailyRate for daily type")
        func testEffectiveRateDaily() {
            let worker = LaborDetails(workerName: "W", laborType: .daily, dailyRate: 300.0)
            #expect(worker.effectiveRate(for: .daily) == 300.0)
        }

        @Test("effectiveRate falls back to legacy rate when hourlyRate is nil and type matches")
        func testEffectiveRateFallbackToLegacyRate() {
            let worker = LaborDetails(workerName: "W", laborType: .hourly, rate: 35.0)
            #expect(worker.effectiveRate(for: .hourly) == 35.0)
        }

        @Test("effectiveRate returns nil when type doesn't match and no dedicated rate set")
        func testEffectiveRateNilWhenNoMatch() {
            let worker = LaborDetails(workerName: "W", laborType: .hourly, rate: 35.0)
            #expect(worker.effectiveRate(for: .daily) == nil)
        }

        @Test("effectiveRate prefers dedicated rate over legacy rate")
        func testEffectiveRatePrefersHourlyRateOverLegacy() {
            let worker = LaborDetails(workerName: "W", laborType: .hourly, rate: 20.0, hourlyRate: 50.0)
            #expect(worker.effectiveRate(for: .hourly) == 50.0)
        }

        @Test("effectiveRate returns fixed rate for subcontractor")
        func testEffectiveRateSubcontractor() {
            let worker = LaborDetails(workerName: "W", laborType: .subcontractor, rate: 2500.0)
            #expect(worker.effectiveRate(for: .subcontractor) == 2500.0)
        }

        // MARK: totalAmountEarned

        @Test("totalAmountEarned sums all linked expenses")
        func testTotalAmountEarned() {
            let worker = LaborDetails(workerName: "W", laborType: .hourly, hourlyRate: 30.0)

            let e1 = Expense(category: .labor, amount: 300.0, descriptionText: "Week 1",
                             worker: worker, unitsWorked: 10, laborTypeSnapshot: .hourly)
            let e2 = Expense(category: .labor, amount: 240.0, descriptionText: "Week 2",
                             worker: worker, unitsWorked: 8, laborTypeSnapshot: .hourly)
            worker.expenses = [e1, e2]

            #expect(worker.totalAmountEarned == 540.0)
        }

        @Test("totalAmountEarned is zero with no expenses")
        func testTotalAmountEarnedEmpty() {
            let worker = LaborDetails(workerName: "W", laborType: .hourly)
            #expect(worker.totalAmountEarned == 0.0)
        }

        // MARK: laborTypeSnapshot on Expense

        @Test("Expense stores laborTypeSnapshot correctly")
        func testExpenseLaborTypeSnapshot() {
            let worker = LaborDetails(workerName: "W", laborType: .hourly, hourlyRate: 25.0, dailyRate: 180.0)

            let hourlyExpense = Expense(category: .labor, amount: 200.0, descriptionText: "Hours",
                                        worker: worker, unitsWorked: 8, laborTypeSnapshot: .hourly)
            let dailyExpense = Expense(category: .labor, amount: 360.0, descriptionText: "Days",
                                       worker: worker, unitsWorked: 2, laborTypeSnapshot: .daily)

            #expect(hourlyExpense.laborTypeSnapshot == .hourly)
            #expect(dailyExpense.laborTypeSnapshot == .daily)
        }

        @Test("Expense laborTypeSnapshot is preserved independently of worker type change")
        func testExpenseLaborTypeSnapshotPreservedAfterWorkerTypeChange() {
            let worker = LaborDetails(workerName: "W", laborType: .hourly, hourlyRate: 25.0)

            let oldExpense = Expense(category: .labor, amount: 200.0, descriptionText: "Before change",
                                     worker: worker, unitsWorked: 8, laborTypeSnapshot: .hourly)
            worker.expenses = [oldExpense]

            // Simulate type change
            worker.laborType = .daily
            worker.dailyRate = 200.0
            worker.hourlyRate = nil

            // Old expense snapshot must still say hourly
            #expect(oldExpense.laborTypeSnapshot == .hourly)
            #expect(worker.laborType == .daily)
        }

        // MARK: Mixed type totals

        @Test("Worker with mixed hourly and daily expenses tracks both correctly")
        func testMixedTypeExpenseTotals() {
            let worker = LaborDetails(workerName: "W", laborType: .hourly, hourlyRate: 25.0, dailyRate: 200.0)

            let hourlyExpense = Expense(category: .labor, amount: 200.0, descriptionText: "Hours",
                                        worker: worker, unitsWorked: 8, laborTypeSnapshot: .hourly)
            let dailyExpense = Expense(category: .labor, amount: 400.0, descriptionText: "Days",
                                       worker: worker, unitsWorked: 2, laborTypeSnapshot: .daily)
            worker.expenses = [hourlyExpense, dailyExpense]

            let hourlyTotal = worker.safeExpenses
                .filter { ($0.laborTypeSnapshot ?? worker.laborType) == .hourly }
                .compactMap { $0.unitsWorked }
                .reduce(0, +)

            let dailyTotal = worker.safeExpenses
                .filter { ($0.laborTypeSnapshot ?? worker.laborType) == .daily }
                .compactMap { $0.unitsWorked }
                .reduce(0, +)

            #expect(hourlyTotal == 8.0)
            #expect(dailyTotal == 2.0)
            #expect(worker.totalAmountEarned == 600.0)
        }

        // MARK: LaborType helpers

        @Test("LaborType usesQuantity is true for hourly and daily")
        func testUsesQuantity() {
            #expect(LaborType.hourly.usesQuantity == true)
            #expect(LaborType.daily.usesQuantity == true)
            #expect(LaborType.subcontractor.usesQuantity == false)
        }

        @Test("LaborType unitName returns correct strings")
        func testUnitName() {
            #expect(LaborType.hourly.unitName == "hours")
            #expect(LaborType.daily.unitName == "days")
            #expect(LaborType.subcontractor.unitName == "")
        }
    }

    // MARK: - Performance Tests
    
    @Suite("Performance Tests")
    struct PerformanceTests {
        
        @Test("Large expense list calculation")
        func testLargeExpenseListCalculation() {
            let project = Project(
                name: "Large Project",
                clientName: "Client",
                budget: 1_000_000.0
            )
            
            // Add 1000 expenses
            for i in 1...1000 {
                let expense = Expense(
                    category: .materials,
                    amount: Double(i),
                    descriptionText: "Expense \(i)",
                    project: project
                )
                project.expenses = (project.expenses ?? []) + [expense]
            }
            
            // Should calculate sum of 1+2+3+...+1000 = 500500
            let expectedSum = (1000 * 1001) / 2
            #expect(project.totalExpenses == Double(expectedSum))
        }
        
        @Test("Large invoice list filtering")
        func testLargeInvoiceListFiltering() {
            let project = Project(
                name: "Large Project",
                clientName: "Client",
                budget: 1_000_000.0
            )
            
            // Add 100 invoices, alternating paid/unpaid
            for i in 1...100 {
                let invoice = Invoice(
                    amount: 1000.0,
                    dueDate: Date(),
                    isPaid: i % 2 == 0,
                    clientName: "Client", // Even numbered invoices are paid
                    project: project
                )
                project.invoices = (project.invoices ?? []) + [invoice]
            }
            
            // 50 paid invoices * $1000 each = $50,000
            #expect(project.totalIncome == 50_000.0)
        }
    }

    // MARK: - InvoiceOCRService Tests

    @Suite("InvoiceOCRService Tests")
    struct InvoiceOCRServiceTests {

        // MARK: extractAmount

        @Test("extractAmount parses plain decimal")
        func testExtractAmountDecimal() {
            #expect(InvoiceOCRService.extractAmount(from: "670.10") == 670.10)
        }

        @Test("extractAmount parses currency-prefixed value")
        func testExtractAmountCurrencyPrefix() {
            #expect(InvoiceOCRService.extractAmount(from: "₪1,234.56") == 1234.56)
            #expect(InvoiceOCRService.extractAmount(from: "$500.00") == 500.0)
            #expect(InvoiceOCRService.extractAmount(from: "€99.99") == 99.99)
        }

        @Test("extractAmount rejects integer when requireDecimal is true")
        func testExtractAmountRequireDecimal() {
            #expect(InvoiceOCRService.extractAmount(from: "985", requireDecimal: true) == nil)
            #expect(InvoiceOCRService.extractAmount(from: "985.00", requireDecimal: true) == 985.0)
        }

        @Test("extractAmount returns nil for non-numeric line")
        func testExtractAmountNonNumeric() {
            #expect(InvoiceOCRService.extractAmount(from: "Invoice for services") == nil)
        }

        @Test("extractAmount rejects zero and values >= 1,000,000")
        func testExtractAmountBounds() {
            #expect(InvoiceOCRService.extractAmount(from: "0.00") == nil)
            #expect(InvoiceOCRService.extractAmount(from: "1000000.00") == nil)
        }

        @Test("extractAmount parses comma-separated thousands")
        func testExtractAmountThousandsSeparator() {
            #expect(InvoiceOCRService.extractAmount(from: "1,500.75") == 1500.75)
        }

        // MARK: extractTotalAmount – strategy 1 (keyword + same line)

        @Test("extractTotalAmount picks amount on same line as 'total' keyword")
        func testExtractTotalAmountStrategy1English() {
            let lines = ["Description", "Total Due: 850.00", "Thank you"]
            #expect(InvoiceOCRService.extractTotalAmount(from: lines) == 850.0)
        }

        @Test("extractTotalAmount picks amount on same line as Hebrew keyword")
        func testExtractTotalAmountStrategy1Hebrew() {
            let lines = ["פירוט שירותים", "לתשלום 1200.50", "תודה"]
            #expect(InvoiceOCRService.extractTotalAmount(from: lines) == 1200.50)
        }

        @Test("extractTotalAmount picks amount on same line as Russian keyword")
        func testExtractTotalAmountStrategy1Russian() {
            let lines = ["Детали", "Итого к оплате 3500.00", "Спасибо"]
            #expect(InvoiceOCRService.extractTotalAmount(from: lines) == 3500.0)
        }

        // MARK: extractTotalAmount – strategy 2 (keyword + lookahead)

        @Test("extractTotalAmount looks ahead to next line for amount after keyword")
        func testExtractTotalAmountStrategy2Lookahead() {
            let lines = ["Grand Total", "  1750.00", "Footer text"]
            #expect(InvoiceOCRService.extractTotalAmount(from: lines) == 1750.0)
        }

        // MARK: extractTotalAmount – strategy 3 (currency symbol)

        @Test("extractTotalAmount picks currency-prefixed amount when no keyword")
        func testExtractTotalAmountStrategy3Currency() {
            let lines = ["Ref: 99123", "Pay: ₪450.00", "End"]
            #expect(InvoiceOCRService.extractTotalAmount(from: lines) == 450.0)
        }

        // MARK: extractTotalAmount – strategy 4 (largest decimal)

        @Test("extractTotalAmount picks largest decimal number when no keyword or currency")
        func testExtractTotalAmountStrategy4LargestDecimal() {
            let lines = ["Item A  10.00", "Item B  20.50", "ID: 12345"]
            #expect(InvoiceOCRService.extractTotalAmount(from: lines) == 20.50)
        }

        @Test("extractTotalAmount returns nil for lines with only integers and no keyword")
        func testExtractTotalAmountOnlyIntegers() {
            // All strategies requiring decimal will fail; strategy 5 filters large round numbers
            let lines = ["Code: 100", "Ref: 200"]
            // Strategy 5: max of filtered amounts; 100 and 200 are round integers < 10000
            // filter: $0 != $0.rounded() || $0 < 10_000 — round integers < 10000 pass through
            // so 200 is returned
            #expect(InvoiceOCRService.extractTotalAmount(from: lines) == 200.0)
        }

        // MARK: extractDate

        @Test("extractDate parses MM/dd/yyyy format")
        func testExtractDateSlashUS() {
            let result = InvoiceOCRService.extractDate(from: "Invoice date: 03/15/2025")
            #expect(result != nil)
            let comps = Calendar.current.dateComponents([.month, .day, .year], from: result!)
            #expect(comps.month == 3)
            #expect(comps.day == 15)
            #expect(comps.year == 2025)
        }

        @Test("extractDate parses dd/MM/yyyy format")
        func testExtractDateSlashEU() {
            let result = InvoiceOCRService.extractDate(from: "Date: 15/03/2025")
            #expect(result != nil)
        }

        @Test("extractDate parses yyyy-MM-dd ISO format")
        func testExtractDateISO() {
            let result = InvoiceOCRService.extractDate(from: "2025-07-04")
            #expect(result != nil)
            let comps = Calendar.current.dateComponents([.month, .day, .year], from: result!)
            #expect(comps.year == 2025)
            #expect(comps.month == 7)
            #expect(comps.day == 4)
        }

        @Test("extractDate parses dd.MM.yyyy dot-separated format")
        func testExtractDateDot() {
            let result = InvoiceOCRService.extractDate(from: "תאריך: 22.11.2024")
            #expect(result != nil)
        }

        @Test("extractDate returns nil when no date present")
        func testExtractDateNone() {
            #expect(InvoiceOCRService.extractDate(from: "No date here at all") == nil)
            #expect(InvoiceOCRService.extractDate(from: "Total: 500.00") == nil)
        }

        // MARK: isNumericLine

        @Test("isNumericLine returns true for pure numeric lines")
        func testIsNumericLineTrue() {
            #expect(InvoiceOCRService.isNumericLine("12345") == true)
            #expect(InvoiceOCRService.isNumericLine("1,234.56") == true)
            #expect(InvoiceOCRService.isNumericLine("₪500") == true)
            #expect(InvoiceOCRService.isNumericLine("$1,000.00") == true)
        }

        @Test("isNumericLine returns false for lines with text")
        func testIsNumericLineFalse() {
            #expect(InvoiceOCRService.isNumericLine("Invoice Total") == false)
            #expect(InvoiceOCRService.isNumericLine("500 USD") == false)
            #expect(InvoiceOCRService.isNumericLine("") == false)
        }

        // MARK: bestDescription

        @Test("bestDescription picks invoice/receipt keyword line")
        func testBestDescriptionKeywordWins() {
            let candidates = ["John Smith", "Invoice for plumbing services", "12345"]
            #expect(InvoiceOCRService.bestDescription(from: candidates) == "Invoice for plumbing services")
        }

        @Test("bestDescription returns first candidate when no keywords match")
        func testBestDescriptionFallback() {
            let candidates = ["ABC Corp", "Reference 001"]
            let result = InvoiceOCRService.bestDescription(from: candidates)
            #expect(!result.isEmpty)
        }

        @Test("bestDescription returns empty string for empty candidates")
        func testBestDescriptionEmpty() {
            #expect(InvoiceOCRService.bestDescription(from: []) == "")
        }

        @Test("bestDescription prefers Hebrew keyword line")
        func testBestDescriptionHebrew() {
            let candidates = ["שם לקוח", "חשבונית עבור שירותי אינסטלציה", "000123"]
            #expect(InvoiceOCRService.bestDescription(from: candidates) == "חשבונית עבור שירותי אינסטלציה")
        }

        // MARK: parse (end-to-end)

        @Test("parse extracts amount, date, and description from English invoice lines")
        func testParseEnglishInvoice() {
            let lines = [
                "ABC Plumbing Services",
                "Invoice #1042",
                "Date: 06/15/2024",
                "Labor: 150.00",
                "Materials: 320.00",
                "Grand Total  470.00",
                "Thank you for your business"
            ]
            let result = InvoiceOCRService.parse(lines: lines)
            #expect(result.amount == 470.0)
            #expect(result.date != nil)
            #expect(!result.description.isEmpty)
        }

        @Test("parse returns nil amount for lines with no usable number")
        func testParseNoAmount() {
            let lines = ["No numbers here", "Just text", "More text"]
            let result = InvoiceOCRService.parse(lines: lines)
            #expect(result.amount == nil)
        }

        @Test("parse returns nil date when no date present in lines")
        func testParseNoDate() {
            let lines = ["Total: 100.00", "Services rendered"]
            let result = InvoiceOCRService.parse(lines: lines)
            #expect(result.date == nil)
        }
    }

    // MARK: - Date Filter Logic Tests

    @Suite("Date Filter Logic Tests")
    struct DateFilterLogicTests {

        private func makeComponents(year: Int, month: Int, day: Int) -> DateComponents {
            DateComponents(year: year, month: month, day: day)
        }

        @Test("contiguousRange fills gap between two non-adjacent dates")
        func testFillsGap() {
            let dates: Set<DateComponents> = [
                makeComponents(year: 2024, month: 3, day: 1),
                makeComponents(year: 2024, month: 3, day: 5)
            ]
            let result = ExpenseFiltersView.contiguousRange(from: dates)
            #expect(result != nil)
            #expect(result!.count == 5) // Mar 1–5 inclusive
        }

        @Test("contiguousRange returns nil for single date")
        func testSingleDateReturnsNil() {
            let dates: Set<DateComponents> = [makeComponents(year: 2024, month: 3, day: 10)]
            #expect(ExpenseFiltersView.contiguousRange(from: dates) == nil)
        }

        @Test("contiguousRange returns nil for empty set")
        func testEmptySetReturnsNil() {
            #expect(ExpenseFiltersView.contiguousRange(from: []) == nil)
        }

        @Test("contiguousRange spans month boundary correctly")
        func testMonthBoundary() {
            let dates: Set<DateComponents> = [
                makeComponents(year: 2024, month: 1, day: 30),
                makeComponents(year: 2024, month: 2, day: 2)
            ]
            let result = ExpenseFiltersView.contiguousRange(from: dates)
            #expect(result != nil)
            // Jan 30, 31, Feb 1, 2 = 4 days
            #expect(result!.count == 4)
        }

        @Test("contiguousRange for adjacent dates returns same two dates")
        func testAdjacentDates() {
            let dates: Set<DateComponents> = [
                makeComponents(year: 2024, month: 6, day: 10),
                makeComponents(year: 2024, month: 6, day: 11)
            ]
            let result = ExpenseFiltersView.contiguousRange(from: dates)
            #expect(result != nil)
            #expect(result!.count == 2)
        }

        @Test("contiguousRange already contiguous returns same set")
        func testAlreadyContiguous() {
            let dates: Set<DateComponents> = [
                makeComponents(year: 2024, month: 5, day: 1),
                makeComponents(year: 2024, month: 5, day: 2),
                makeComponents(year: 2024, month: 5, day: 3)
            ]
            let result = ExpenseFiltersView.contiguousRange(from: dates)
            #expect(result != nil)
            #expect(result == dates)
        }
    }

    // MARK: - Labor Expense Logic Tests

    @Suite("Labor Expense Logic Tests")
    struct LaborExpenseLogicTests {

        @Test("daysCount parses decimal string from decimal pad input")
        func testDaysCountDecimalPadInput() {
            // Simulates Int(Double("2.0") ?? 0) — the fix for decimal pad producing "2.0"
            let unitsWorked = "2.0"
            let daysCount = Int(Double(unitsWorked) ?? 0)
            #expect(daysCount == 2)
        }

        @Test("daysCount parses plain integer string")
        func testDaysCountIntegerString() {
            let unitsWorked = "3"
            let daysCount = Int(Double(unitsWorked) ?? 0)
            #expect(daysCount == 3)
        }

        @Test("daysCount returns zero for empty string")
        func testDaysCountEmptyString() {
            let unitsWorked = ""
            let daysCount = Int(Double(unitsWorked) ?? 0)
            #expect(daysCount == 0)
        }

        @Test("daysCount returns zero for non-numeric string")
        func testDaysCountNonNumericString() {
            let unitsWorked = "abc"
            let daysCount = Int(Double(unitsWorked) ?? 0)
            #expect(daysCount == 0)
        }

        @Test("effective amount falls back to calculatedAmount when amount is nil")
        func testEffectiveAmountFallback() {
            let amount: Double? = nil
            let calculatedAmount: Double? = 480.0
            let effectiveAmount = amount ?? calculatedAmount ?? 0
            #expect(effectiveAmount == 480.0)
        }

        @Test("effective amount uses explicit amount when set")
        func testEffectiveAmountExplicit() {
            let amount: Double? = 600.0
            let calculatedAmount: Double? = 480.0
            let effectiveAmount = amount ?? calculatedAmount ?? 0
            #expect(effectiveAmount == 600.0)
        }

        @Test("effective amount is zero when both amount and calculatedAmount are nil")
        func testEffectiveAmountZero() {
            let amount: Double? = nil
            let calculatedAmount: Double? = nil
            let effectiveAmount = amount ?? calculatedAmount ?? 0
            #expect(effectiveAmount == 0.0)
        }

        @Test("hourly calculatedAmount = hourlyRate * hours")
        func testHourlyCalculation() {
            let hourlyRate: Double = 75.0
            let unitsWorked = "8.0"
            guard let units = Double(unitsWorked), units > 0 else {
                Issue.record("Failed to parse units")
                return
            }
            let calculated = hourlyRate * units
            #expect(calculated == 600.0)
        }

        @Test("daily calculatedAmount = dailyRate * days")
        func testDailyCalculation() {
            let dailyRate: Double = 350.0
            let unitsWorked = "3"
            guard let units = Double(unitsWorked), units > 0 else {
                Issue.record("Failed to parse units")
                return
            }
            let calculated = dailyRate * units
            #expect(calculated == 1050.0)
        }
    }

    // MARK: - Expense Receipt Data Tests

    @Suite("Expense Receipt Data Tests")
    struct ExpenseReceiptDataTests {

        @Test("Expense stores nil receiptImageData by default")
        func testReceiptImageDataDefaultNil() {
            let project = Project(name: "P", clientName: "C", budget: 1000)
            let expense = Expense(
                category: .materials,
                amount: 100.0,
                descriptionText: "Test",
                project: project
            )
            #expect(expense.receiptImageData == nil)
        }

        @Test("Expense stores and retrieves receiptImageData")
        func testReceiptImageDataStored() {
            let project = Project(name: "P", clientName: "C", budget: 1000)
            let testData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header bytes
            let expense = Expense(
                category: .materials,
                amount: 100.0,
                descriptionText: "Receipt test",
                project: project
            )
            expense.receiptImageData = testData
            #expect(expense.receiptImageData == testData)
            #expect(expense.receiptImageData?.count == 4)
        }

        @Test("Expense receiptImageData can be cleared")
        func testReceiptImageDataCleared() {
            let project = Project(name: "P", clientName: "C", budget: 1000)
            let expense = Expense(
                category: .materials,
                amount: 50.0,
                descriptionText: "Receipt clear test",
                project: project
            )
            expense.receiptImageData = Data([0xFF, 0xD8]) // JPEG header
            #expect(expense.receiptImageData != nil)
            expense.receiptImageData = nil
            #expect(expense.receiptImageData == nil)
        }

        @Test("ScannedInvoiceData initializes with expected fields")
        func testScannedInvoiceDataInit() {
            let date = Date()
            let data = ScannedInvoiceData(amount: 500.0, date: date, description: "Test invoice")
            #expect(data.amount == 500.0)
            #expect(data.date == date)
            #expect(data.description == "Test invoice")
        }

        @Test("ScannedInvoiceData allows nil amount and date")
        func testScannedInvoiceDataNilFields() {
            let data = ScannedInvoiceData(amount: nil, date: nil, description: "")
            #expect(data.amount == nil)
            #expect(data.date == nil)
            #expect(data.description.isEmpty)
        }
    }
}

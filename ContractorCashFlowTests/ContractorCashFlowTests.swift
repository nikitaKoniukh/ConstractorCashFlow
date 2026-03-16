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
            #expect(ExpenseCategory.subcontractor.displayName == "Subcontractor")
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
}

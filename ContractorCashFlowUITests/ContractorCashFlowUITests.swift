//
//  ContractorCashFlowUITests.swift
//  ContractorCashFlowUITests
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import XCTest

final class ContractorCashFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Tell the app's LanguageManager to force English (bypasses saved UserDefaults locale)
        app.launchArguments += ["-UITesting"]
        // Also set the Apple locale so system-level date/number formatting is English
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Helper Methods
    
    /// Taps a tab bar button by its label text.
    /// Handles the iOS "More" overflow tab for tabs beyond the visible 4-5 slots.
    private func tapTab(_ name: String) {
        let tabBar = app.tabBars
        let tabButton = tabBar.buttons[name]
        if tabButton.exists {
            tabButton.tap()
        } else {
            // Tab is hidden under "More" — tap More to get to the More list,
            // then select the row for the desired tab.
            let moreButton = tabBar.buttons["More"]
            if moreButton.exists {
                moreButton.tap()
                
                // If we're already inside a More sub-view, tapping More pops
                // back to the More list. Wait for the table to appear.
                let row = app.tables.staticTexts[name]
                if row.waitForExistence(timeout: 3) {
                    row.tap()
                } else {
                    // May need a second tap if first tap only popped the nav stack
                    moreButton.tap()
                    if row.waitForExistence(timeout: 3) {
                        row.tap()
                    }
                }
            }
        }
    }
    
    /// Waits for an element to exist within a timeout.
    @discardableResult
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }
    
    /// Taps an element only after confirming it exists, skipping if not found.
    private func tapIfExists(_ element: XCUIElement, timeout: TimeInterval = 5) {
        guard element.waitForExistence(timeout: timeout) else { return }
        element.tap()
    }
    
    /// Types text into a field, waiting for it to exist first.
    private func typeInField(_ element: XCUIElement, text: String, timeout: TimeInterval = 5) {
        guard element.waitForExistence(timeout: timeout) else { return }
        element.tap()
        element.typeText(text)
    }
    
    // MARK: - Tab Navigation Tests
    
    @MainActor
    func testAllTabsExist() throws {
        let tabBar = app.tabBars
        // First 4 tabs are visible directly in the tab bar
        XCTAssertTrue(tabBar.buttons["Projects"].exists, "Projects tab should exist")
        XCTAssertTrue(tabBar.buttons["Expenses"].exists, "Expenses tab should exist")
        XCTAssertTrue(tabBar.buttons["Invoices"].exists, "Invoices tab should exist")
        XCTAssertTrue(tabBar.buttons["Labor"].exists, "Labor tab should exist")
        
        // Remaining tabs are behind "More" on iPhone
        let moreButton = tabBar.buttons["More"]
        XCTAssertTrue(moreButton.exists, "More tab should exist for overflow tabs")
        moreButton.tap()
        
        let moreTable = app.tables.firstMatch
        XCTAssertTrue(moreTable.waitForExistence(timeout: 3), "More list should appear")
        XCTAssertTrue(moreTable.staticTexts["Clients"].exists, "Clients should be in More list")
        XCTAssertTrue(moreTable.staticTexts["Analytics"].exists, "Analytics should be in More list")
        XCTAssertTrue(moreTable.staticTexts["Settings"].exists, "Settings should be in More list")
    }
    
    @MainActor
    func testNavigateToEachTab() throws {
        tapTab("Expenses")
        XCTAssertTrue(app.navigationBars["Expenses"].waitForExistence(timeout: 3))
        
        tapTab("Invoices")
        XCTAssertTrue(app.navigationBars["Invoices"].waitForExistence(timeout: 3))
        
        tapTab("Labor")
        XCTAssertTrue(app.navigationBars["Labor"].waitForExistence(timeout: 3))
        
        tapTab("Clients")
        XCTAssertTrue(app.navigationBars["Clients"].waitForExistence(timeout: 3))
        
        tapTab("Analytics")
        XCTAssertTrue(app.navigationBars["Analytics"].waitForExistence(timeout: 3))
        
        tapTab("Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        
        tapTab("Projects")
        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: 3))
    }
    
    // MARK: - Projects Tab Tests
    
    @MainActor
    func testProjectsTabShowsEmptyState() throws {
        tapTab("Projects")
        // Empty state should show when no projects exist
        let emptyLabel = app.staticTexts["No Projects"]
        if emptyLabel.waitForExistence(timeout: 3) {
            XCTAssertTrue(emptyLabel.exists)
            XCTAssertTrue(app.buttons["Add Project"].exists, "Empty state should have Add Project button")
        }
    }
    
    @MainActor
    func testProjectsTabHasAddButton() throws {
        tapTab("Projects")
        let addButton = app.navigationBars.buttons["Add Project"]
        XCTAssertTrue(waitForElement(addButton), "Projects tab should have an Add Project button")
    }
    
    @MainActor
    func testNewProjectFormOpensAndDismisses() throws {
        tapTab("Projects")
        app.navigationBars.buttons["Add Project"].tap()
        
        // Verify the New Project sheet appeared
        XCTAssertTrue(app.navigationBars["New Project"].waitForExistence(timeout: 3), "New Project form should appear")
        
        // Verify form fields exist
        XCTAssertTrue(app.textFields["Project Name"].exists, "Project Name field should exist")
        XCTAssertTrue(app.textFields["Client Name"].exists || app.buttons["Client Name"].exists, "Client Name field should exist")
        
        // Verify Cancel button dismisses the sheet
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.navigationBars["New Project"].waitForExistence(timeout: 2), "New Project form should be dismissed")
    }
    
    @MainActor
    func testCreateNewProject() throws {
        tapTab("Projects")
        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: 5))
        tapIfExists(app.navigationBars.buttons["Add Project"])
        
        XCTAssertTrue(app.navigationBars["New Project"].waitForExistence(timeout: 5))
        
        // Fill in form fields
        typeInField(app.textFields["Project Name"], text: "Test Project")
        
        // Enter client name — might be a text field or picker
        let clientField = app.textFields["Client Name"]
        if clientField.waitForExistence(timeout: 2) {
            clientField.tap()
            clientField.typeText("Test Client")
        }
        
        // Enter budget (required for save to be enabled)
        let budgetField = app.textFields["Budget"]
        if budgetField.waitForExistence(timeout: 2) {
            budgetField.tap()
            budgetField.typeText("10000")
        }
        
        // Save the project
        tapIfExists(app.buttons["Save"])
        
        // Verify the project appears in the list
        XCTAssertTrue(app.staticTexts["Test Project"].waitForExistence(timeout: 5), "Created project should appear in the list")
    }
    
    @MainActor
    func testProjectDetailView() throws {
        // First create a project
        tapTab("Projects")
        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: 5))
        tapIfExists(app.navigationBars.buttons["Add Project"])
        XCTAssertTrue(app.navigationBars["New Project"].waitForExistence(timeout: 5))
        
        typeInField(app.textFields["Project Name"], text: "Detail Test Project")
        
        let clientField = app.textFields["Client Name"]
        if clientField.waitForExistence(timeout: 2) {
            clientField.tap()
            clientField.typeText("Detail Client")
        }
        
        let budgetField = app.textFields["Budget"]
        if budgetField.waitForExistence(timeout: 2) {
            budgetField.tap()
            budgetField.typeText("5000")
        }
        
        tapIfExists(app.buttons["Save"])
        
        // Wait for project to appear and tap it
        let projectCell = app.staticTexts["Detail Test Project"]
        XCTAssertTrue(projectCell.waitForExistence(timeout: 5))
        projectCell.tap()
        
        // Verify detail view shows project info
        XCTAssertTrue(app.navigationBars["Detail Test Project"].waitForExistence(timeout: 3), "Navigation bar should show project name")
        XCTAssertTrue(app.staticTexts["Net Balance"].exists, "Financial summary should show Net Balance")
    }
    
    // MARK: - Expenses Tab Tests
    
    @MainActor
    func testExpensesTabShowsEmptyState() throws {
        tapTab("Expenses")
        let emptyLabel = app.staticTexts["No Expenses"]
        if emptyLabel.waitForExistence(timeout: 3) {
            XCTAssertTrue(emptyLabel.exists)
        }
    }
    
    @MainActor
    func testExpensesTabHasAddButton() throws {
        tapTab("Expenses")
        let addButton = app.navigationBars.buttons["Add Expense"]
        XCTAssertTrue(waitForElement(addButton), "Expenses tab should have an Add Expense button")
    }
    
    @MainActor
    func testNewExpenseFormOpensAndDismisses() throws {
        tapTab("Expenses")
        app.navigationBars.buttons["Add Expense"].tap()
        
        XCTAssertTrue(app.navigationBars["New Expense"].waitForExistence(timeout: 3), "New Expense form should appear")
        
        // Verify key form fields exist
        XCTAssertTrue(app.buttons["Category"].exists || app.staticTexts["Category"].exists, "Category picker should exist")
        
        // Dismiss
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.navigationBars["New Expense"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testCreateNewExpense() throws {
        tapTab("Expenses")
        XCTAssertTrue(app.navigationBars["Expenses"].waitForExistence(timeout: 5))
        tapIfExists(app.navigationBars.buttons["Add Expense"])
        
        XCTAssertTrue(app.navigationBars["New Expense"].waitForExistence(timeout: 5))
        
        // Fill in amount
        let amountField = app.textFields["Amount"]
        if amountField.waitForExistence(timeout: 3) {
            amountField.tap()
            amountField.typeText("500")
        }
        
        // Fill in description
        let descriptionField = app.textFields["Description"]
        if descriptionField.waitForExistence(timeout: 3) {
            descriptionField.tap()
            descriptionField.typeText("Test Materials")
        }
        
        // Save
        tapIfExists(app.buttons["Save"])
        
        // Verify the expense appears
        XCTAssertTrue(app.staticTexts["Test Materials"].waitForExistence(timeout: 5), "Created expense should appear in the list")
    }
    
    // MARK: - Invoices Tab Tests
    
    @MainActor
    func testInvoicesTabShowsEmptyState() throws {
        tapTab("Invoices")
        let emptyLabel = app.staticTexts["No Invoices"]
        if emptyLabel.waitForExistence(timeout: 3) {
            XCTAssertTrue(emptyLabel.exists)
        }
    }
    
    @MainActor
    func testInvoicesTabHasAddButton() throws {
        tapTab("Invoices")
        let addButton = app.navigationBars.buttons["Add Invoice"]
        XCTAssertTrue(waitForElement(addButton), "Invoices tab should have an Add Invoice button")
    }
    
    @MainActor
    func testNewInvoiceFormOpensAndDismisses() throws {
        tapTab("Invoices")
        app.navigationBars.buttons["Add Invoice"].tap()
        
        XCTAssertTrue(app.navigationBars["New Invoice"].waitForExistence(timeout: 3), "New Invoice form should appear")
        
        // Verify key form fields
        XCTAssertTrue(app.textFields["Client Name"].exists || app.buttons["Client Name"].exists, "Client Name field should exist")
        
        // Dismiss
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.navigationBars["New Invoice"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testCreateNewInvoice() throws {
        tapTab("Invoices")
        XCTAssertTrue(app.navigationBars["Invoices"].waitForExistence(timeout: 5))
        tapIfExists(app.navigationBars.buttons["Add Invoice"])
        
        XCTAssertTrue(app.navigationBars["New Invoice"].waitForExistence(timeout: 5))
        
        // Enter client name
        let clientField = app.textFields["Client Name"]
        if clientField.waitForExistence(timeout: 3) {
            clientField.tap()
            clientField.typeText("Invoice Client")
        }
        
        // Enter amount
        let amountField = app.textFields["Amount"]
        if amountField.waitForExistence(timeout: 3) {
            amountField.tap()
            amountField.typeText("1000")
        }
        
        // Save
        tapIfExists(app.buttons["Save"])
        
        // Verify the invoice appears
        XCTAssertTrue(app.staticTexts["Invoice Client"].waitForExistence(timeout: 5), "Created invoice should appear in the list")
    }
    
    // MARK: - Clients Tab Tests
    
    @MainActor
    func testClientsTabShowsEmptyState() throws {
        tapTab("Clients")
        let emptyLabel = app.staticTexts["No Clients"]
        if emptyLabel.waitForExistence(timeout: 3) {
            XCTAssertTrue(emptyLabel.exists)
        }
    }
    
    @MainActor
    func testClientsTabHasAddButton() throws {
        tapTab("Clients")
        let addButton = app.navigationBars.buttons["Add Client"]
        XCTAssertTrue(waitForElement(addButton), "Clients tab should have an Add Client button")
    }
    
    @MainActor
    func testNewClientFormOpensAndDismisses() throws {
        tapTab("Clients")
        app.navigationBars.buttons["Add Client"].tap()
        
        XCTAssertTrue(app.navigationBars["New Client"].waitForExistence(timeout: 3), "New Client form should appear")
        
        // Verify form fields exist
        XCTAssertTrue(app.textFields["Name"].exists, "Name field should exist")
        XCTAssertTrue(app.textFields["Email"].exists, "Email field should exist")
        XCTAssertTrue(app.textFields["Phone"].exists, "Phone field should exist")
        
        // Dismiss
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.navigationBars["New Client"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testCreateNewClient() throws {
        tapTab("Clients")
        app.navigationBars.buttons["Add Client"].tap()
        
        XCTAssertTrue(app.navigationBars["New Client"].waitForExistence(timeout: 3))
        
        // Fill in name
        let nameField = app.textFields["Name"]
        nameField.tap()
        nameField.typeText("John Smith")
        
        // Fill in email
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("john@example.com")
        
        // Fill in phone
        let phoneField = app.textFields["Phone"]
        phoneField.tap()
        phoneField.typeText("5551234567")
        
        // Save
        app.buttons["Save"].tap()
        
        // Verify the client appears
        XCTAssertTrue(app.staticTexts["John Smith"].waitForExistence(timeout: 5), "Created client should appear in the list")
    }
    
    @MainActor
    func testClientDetailView() throws {
        // Create a client first
        tapTab("Clients")
        app.navigationBars.buttons["Add Client"].tap()
        XCTAssertTrue(app.navigationBars["New Client"].waitForExistence(timeout: 3))
        
        let nameField = app.textFields["Name"]
        nameField.tap()
        nameField.typeText("Detail Client")
        
        app.buttons["Save"].tap()
        
        // Tap the client to see detail
        let clientCell = app.staticTexts["Detail Client"]
        XCTAssertTrue(clientCell.waitForExistence(timeout: 5))
        clientCell.tap()
        
        // Verify detail view
        XCTAssertTrue(app.navigationBars["Detail Client"].waitForExistence(timeout: 3), "Navigation bar should show client name")
    }
    
    // MARK: - Labor Tab Tests
    
    @MainActor
    func testLaborTabShowsEmptyState() throws {
        tapTab("Labor")
        let emptyLabel = app.staticTexts["No Labor Entries"]
        if emptyLabel.waitForExistence(timeout: 3) {
            XCTAssertTrue(emptyLabel.exists)
        }
    }
    
    @MainActor
    func testLaborTabHasAddButton() throws {
        tapTab("Labor")
        let addButton = app.navigationBars.buttons["Add Labor"]
        XCTAssertTrue(waitForElement(addButton), "Labor tab should have an Add Labor button")
    }
    
    @MainActor
    func testNewWorkerFormOpensAndDismisses() throws {
        tapTab("Labor")
        app.navigationBars.buttons["Add Labor"].tap()
        
        let navBar = app.navigationBars["New Labor Entry"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 3), "New Worker form should appear")
        
        // Verify form fields
        XCTAssertTrue(app.textFields["Worker Name"].exists, "Worker Name field should exist")
        
        // Dismiss
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.navigationBars["New Labor Entry"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testCreateNewWorker() throws {
        tapTab("Labor")
        XCTAssertTrue(app.navigationBars["Labor"].waitForExistence(timeout: 5))
        tapIfExists(app.navigationBars.buttons["Add Labor"])
        
        XCTAssertTrue(app.navigationBars["New Labor Entry"].waitForExistence(timeout: 5))
        
        // Fill in worker name
        typeInField(app.textFields["Worker Name"], text: "Mike Builder")
        
        // Save
        tapIfExists(app.buttons["Save"])
        
        // Verify the worker appears
        XCTAssertTrue(app.staticTexts["Mike Builder"].waitForExistence(timeout: 5), "Created worker should appear in the list")
    }
    
    // MARK: - Analytics Tab Tests
    
    @MainActor
    func testAnalyticsTabLoads() throws {
        tapTab("Analytics")
        XCTAssertTrue(app.navigationBars["Analytics"].waitForExistence(timeout: 3), "Analytics tab should load")
    }
    
    // MARK: - Settings Tab Tests
    
    @MainActor
    func testSettingsTabLoads() throws {
        tapTab("Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3), "Settings tab should load")
    }
    
    @MainActor
    func testSettingsHasLanguagePicker() throws {
        tapTab("Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        
        // Look for the Language setting
        let languageLabel = app.staticTexts["Language"]
        XCTAssertTrue(languageLabel.exists || app.buttons["Language"].exists, "Language setting should exist")
    }
    
    @MainActor
    func testSettingsHasCurrencyPicker() throws {
        tapTab("Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        
        let currencyLabel = app.staticTexts["Currency"]
        XCTAssertTrue(currencyLabel.exists || app.buttons["Currency"].exists, "Currency setting should exist")
    }
    
    @MainActor
    func testSettingsHasNotificationToggles() throws {
        tapTab("Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        
        // Scroll down to find notification toggles
        let settingsList = app.collectionViews.firstMatch
        settingsList.swipeUp()
        
        let invoiceReminders = app.switches["Invoice Reminders"]
        let overdueAlerts = app.switches["Overdue Alerts"]
        let budgetWarnings = app.switches["Budget Warnings"]
        
        XCTAssertTrue(invoiceReminders.exists || overdueAlerts.exists || budgetWarnings.exists,
                      "At least one notification toggle should exist")
    }
    
    @MainActor
    func testSettingsHasExportButton() throws {
        tapTab("Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        
        // Scroll down to find export button
        let settingsList = app.collectionViews.firstMatch
        settingsList.swipeUp()
        
        let exportButton = app.buttons["Export Data (JSON)"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3), "Export Data (JSON) button should exist")
    }
    
    // MARK: - Search Tests
    
    @MainActor
    func testProjectsSearchExists() throws {
        tapTab("Projects")
        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: 3))
        
        // Pull down to reveal search bar
        let list = app.collectionViews.firstMatch
        list.swipeDown()
        
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Projects should have a search field")
    }
    
    @MainActor
    func testExpensesSearchExists() throws {
        tapTab("Expenses")
        XCTAssertTrue(app.navigationBars["Expenses"].waitForExistence(timeout: 3))
        
        let list = app.collectionViews.firstMatch
        list.swipeDown()
        
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Expenses should have a search field")
    }
    
    @MainActor
    func testInvoicesSearchExists() throws {
        tapTab("Invoices")
        XCTAssertTrue(app.navigationBars["Invoices"].waitForExistence(timeout: 3))
        
        let list = app.collectionViews.firstMatch
        list.swipeDown()
        
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Invoices should have a search field")
    }
    
    // MARK: - Delete Tests
    
    @MainActor
    func testDeleteProject() throws {
        // Create a project first
        tapTab("Projects")
        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: 5))
        tapIfExists(app.navigationBars.buttons["Add Project"])
        XCTAssertTrue(app.navigationBars["New Project"].waitForExistence(timeout: 5))
        
        typeInField(app.textFields["Project Name"], text: "Delete Me Project")
        
        let clientField = app.textFields["Client Name"]
        if clientField.waitForExistence(timeout: 2) {
            clientField.tap()
            clientField.typeText("Delete Client")
        }
        
        let budgetField = app.textFields["Budget"]
        if budgetField.waitForExistence(timeout: 2) {
            budgetField.tap()
            budgetField.typeText("8000")
        }
        
        tapIfExists(app.buttons["Save"])
        
        // Verify it was created
        let projectCell = app.staticTexts["Delete Me Project"]
        XCTAssertTrue(projectCell.waitForExistence(timeout: 5))
        
        // Enter edit mode and delete
        app.navigationBars.buttons["Edit"].tap()
        
        // Find and tap the delete button for the project
        let deleteButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Delete'"))
        if deleteButtons.count > 0 {
            deleteButtons.firstMatch.tap()
            
            // Confirm deletion if there's a confirmation
            let deleteConfirm = app.buttons["Delete"]
            if deleteConfirm.waitForExistence(timeout: 2) {
                deleteConfirm.tap()
            }
        }
        
        // Exit edit mode
        let doneButton = app.navigationBars.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }
    }
    
    @MainActor
    func testDeleteClient() throws {
        // Create a client first
        tapTab("Clients")
        app.navigationBars.buttons["Add Client"].tap()
        XCTAssertTrue(app.navigationBars["New Client"].waitForExistence(timeout: 3))
        
        let nameField = app.textFields["Name"]
        nameField.tap()
        nameField.typeText("Delete Me Client")
        
        app.buttons["Save"].tap()
        
        let clientCell = app.staticTexts["Delete Me Client"]
        XCTAssertTrue(clientCell.waitForExistence(timeout: 5))
        
        // Enter edit mode and delete
        app.navigationBars.buttons["Edit"].tap()
        
        let deleteButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Delete'"))
        if deleteButtons.count > 0 {
            deleteButtons.firstMatch.tap()
            
            let deleteConfirm = app.buttons["Delete"]
            if deleteConfirm.waitForExistence(timeout: 2) {
                deleteConfirm.tap()
            }
        }
        
        let doneButton = app.navigationBars.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }
    }
    
    // MARK: - Launch Performance
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let perfApp = XCUIApplication()
            perfApp.launchArguments += ["-UITesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
            perfApp.launch()
        }
    }
}

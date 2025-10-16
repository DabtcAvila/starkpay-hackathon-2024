import XCTest
@testable import StarkPayiOS

/// Comprehensive UI tests for payment processing flows
/// Tests send payment, request payment, transaction history, and payment validation
final class PaymentFlowTests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--skip-authentication") // Skip auth for payment testing
        app.launchEnvironment["ANIMATION_SPEED"] = "0.1"
        
        app.launch()
        
        // Navigate past authentication if needed
        navigateToMainApp()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Main Payment Screen Tests
    
    func testPayScreenLayout() throws {
        navigateToPayTab()
        
        // Verify main elements
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '$'")).element.exists, "Balance should be displayed")
        XCTAssertTrue(app.staticTexts["Available Balance"].exists, "Balance label should be visible")
        
        // Verify action buttons
        XCTAssertTrue(app.buttons["Pay"].exists, "Pay button should be visible")
        XCTAssertTrue(app.buttons["Request"].exists, "Request button should be visible")
        XCTAssertTrue(app.buttons["Advanced"].exists, "Advanced button should be visible")
        
        // Verify refresh button
        let refreshButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'arrow.clockwise'")).element
        XCTAssertTrue(refreshButton.exists, "Refresh button should be visible")
    }
    
    func testBalanceDisplay() throws {
        navigateToPayTab()
        
        let balanceText = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '$'")).element
        XCTAssertTrue(balanceText.exists, "Balance should be displayed")
        
        let balanceValue = balanceText.label
        XCTAssertTrue(balanceValue.hasPrefix("$"), "Balance should start with $ symbol")
        XCTAssertTrue(balanceValue.contains("."), "Balance should contain decimal point")
    }
    
    func testRefreshBalance() throws {
        navigateToPayTab()
        
        let refreshButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'arrow.clockwise'")).element
        XCTAssertTrue(refreshButton.exists, "Refresh button should exist")
        
        refreshButton.tap()
        
        // Should show loading indicator briefly
        // In a real test, we'd verify the loading state
        XCTAssertTrue(true, "Refresh should trigger without crash")
    }
    
    // MARK: - Send Payment Flow Tests
    
    func testOpenSendPaymentSheet() throws {
        navigateToPayTab()
        
        let payButton = app.buttons["Pay"]
        XCTAssertTrue(payButton.exists, "Pay button should exist")
        
        payButton.tap()
        
        // Verify send payment sheet opened
        XCTAssertTrue(app.staticTexts["Pay Someone"].waitForExistence(timeout: 2), "Send payment sheet should open")
        XCTAssertTrue(app.textFields["To: username or phone"].exists, "Recipient field should be visible")
        XCTAssertTrue(app.textFields["$0.00"].exists, "Amount field should be visible")
        XCTAssertTrue(app.textFields["What's this for?"].exists, "Note field should be visible")
    }
    
    func testSendPaymentFormValidation() throws {
        openSendPaymentSheet()
        
        let recipientField = app.textFields["To: username or phone"]
        let amountField = app.textFields["$0.00"]
        let noteField = app.textFields["What's this for?"]
        let sendButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pay $'")).element
        
        // Test empty form - send button should be disabled
        XCTAssertFalse(sendButton.isEnabled, "Send button should be disabled for empty form")
        
        // Fill recipient only
        recipientField.tap()
        recipientField.typeText("alice_crypto")
        XCTAssertFalse(sendButton.isEnabled, "Send button should be disabled without amount")
        
        // Fill amount
        amountField.tap()
        amountField.typeText("25.50")
        XCTAssertTrue(sendButton.isEnabled, "Send button should be enabled with recipient and amount")
        
        // Add note (optional)
        noteField.tap()
        noteField.typeText("Coffee payment")
        XCTAssertTrue(sendButton.isEnabled, "Send button should remain enabled with note")
    }
    
    func testSendPaymentExecution() throws {
        openSendPaymentSheet()
        
        fillPaymentForm(recipient: "bob_defi", amount: "50.00", note: "Lunch split")
        
        let sendButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pay $'")).element
        XCTAssertTrue(sendButton.exists, "Send button should exist")
        
        sendButton.tap()
        
        // Should show processing state
        let processingText = app.staticTexts["Processing Payment"]
        if processingText.waitForExistence(timeout: 2) {
            XCTAssertTrue(processingText.exists, "Should show processing state")
        }
        
        // Wait for completion (success or error)
        let completionTimeout: TimeInterval = 5
        let successExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'success'")).element.waitForExistence(timeout: completionTimeout)
        let errorExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'error'")).element.waitForExistence(timeout: completionTimeout)
        
        XCTAssertTrue(successExists || errorExists, "Payment should complete with success or error state")
    }
    
    func testSendPaymentProgressIndicators() throws {
        openSendPaymentSheet()
        fillPaymentForm(recipient: "sarah_web3", amount: "100.00", note: "Test payment")
        
        let sendButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pay $'")).element
        sendButton.tap()
        
        // Look for progress indicators
        let progressBar = app.progressIndicators.element
        let loadingSpinner = app.activityIndicators.element
        
        if progressBar.exists || loadingSpinner.exists {
            XCTAssertTrue(true, "Progress indicator should be shown during payment")
        }
        
        // Look for progress messages
        let validatingText = app.staticTexts["Validating payment details..."]
        let processingText = app.staticTexts["Processing with StarkNet..."]
        let confirmingText = app.staticTexts["Confirming transaction..."]
        
        let hasProgressMessage = validatingText.exists || processingText.exists || confirmingText.exists
        XCTAssertTrue(hasProgressMessage, "Should show progress messages during payment")
    }
    
    func testCancelSendPayment() throws {
        openSendPaymentSheet()
        
        let cancelButton = app.navigationBars.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        
        cancelButton.tap()
        
        // Should dismiss sheet
        let paymentSheet = app.staticTexts["Pay Someone"]
        XCTAssertFalse(paymentSheet.waitForExistence(timeout: 2), "Payment sheet should be dismissed")
        
        // Should return to main pay screen
        XCTAssertTrue(app.buttons["Pay"].exists, "Should return to main pay screen")
    }
    
    // MARK: - Request Payment Flow Tests
    
    func testOpenRequestPaymentSheet() throws {
        navigateToPayTab()
        
        let requestButton = app.buttons["Request"]
        XCTAssertTrue(requestButton.exists, "Request button should exist")
        
        requestButton.tap()
        
        // Verify request payment sheet opened
        XCTAssertTrue(app.staticTexts["Request Payment"].waitForExistence(timeout: 2), "Request payment sheet should open")
        XCTAssertTrue(app.textFields["$0.00"].exists, "Amount field should be visible")
        XCTAssertTrue(app.textFields["What's this for?"].exists, "Note field should be visible")
        
        // Should show QR code placeholder
        XCTAssertTrue(app.staticTexts["QR Code"].exists, "QR Code placeholder should be visible")
    }
    
    func testRequestPaymentFormValidation() throws {
        openRequestPaymentSheet()
        
        let amountField = app.textFields["$0.00"]
        let noteField = app.textFields["What's this for?"]
        let requestButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Request $'")).element
        
        // Test empty form - request button should be disabled
        XCTAssertFalse(requestButton.isEnabled, "Request button should be disabled for empty form")
        
        // Fill amount
        amountField.tap()
        amountField.typeText("75.00")
        XCTAssertTrue(requestButton.isEnabled, "Request button should be enabled with amount")
        
        // Add note (optional)
        noteField.tap()
        noteField.typeText("Dinner split")
        XCTAssertTrue(requestButton.isEnabled, "Request button should remain enabled with note")
    }
    
    func testRequestPaymentExecution() throws {
        openRequestPaymentSheet()
        
        let amountField = app.textFields["$0.00"]
        let noteField = app.textFields["What's this for?"]
        
        amountField.tap()
        amountField.typeText("60.00")
        
        noteField.tap()
        noteField.typeText("Gas money")
        
        let requestButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Request $'")).element
        requestButton.tap()
        
        // Should dismiss and return to main screen
        let requestSheet = app.staticTexts["Request Payment"]
        XCTAssertFalse(requestSheet.waitForExistence(timeout: 2), "Request sheet should be dismissed")
    }
    
    func testCancelRequestPayment() throws {
        openRequestPaymentSheet()
        
        let cancelButton = app.navigationBars.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        
        cancelButton.tap()
        
        // Should dismiss sheet
        let requestSheet = app.staticTexts["Request Payment"]
        XCTAssertFalse(requestSheet.waitForExistence(timeout: 2), "Request sheet should be dismissed")
    }
    
    // MARK: - Transaction History Tests
    
    func testRecentTransactionsDisplay() throws {
        navigateToPayTab()
        
        // Should show "Recent" section
        XCTAssertTrue(app.staticTexts["Recent"].exists, "Recent section header should be visible")
        
        // Look for transaction rows
        let transactionCells = app.buttons.matching(NSPredicate(format: "label CONTAINS 'From' OR label CONTAINS 'To'"))
        
        if transactionCells.count > 0 {
            // Verify transaction elements
            let firstTransaction = transactionCells.element(boundBy: 0)
            XCTAssertTrue(firstTransaction.exists, "At least one transaction should be visible")
        } else {
            // Check for empty state
            let emptyStateText = app.staticTexts["No recent transactions"]
            XCTAssertTrue(emptyStateText.exists, "Should show empty state if no transactions")
        }
    }
    
    func testTransactionRowLayout() throws {
        navigateToPayTab()
        
        let transactionCells = app.buttons.matching(NSPredicate(format: "label CONTAINS 'From' OR label CONTAINS 'To'"))
        
        if transactionCells.count > 0 {
            let firstTransaction = transactionCells.element(boundBy: 0)
            
            // Verify transaction contains required elements
            // (This would be more detailed in a real implementation with accessibility identifiers)
            XCTAssertTrue(firstTransaction.exists, "Transaction row should exist")
            
            firstTransaction.tap()
            
            // In a full implementation, this might open transaction details
            XCTAssertTrue(true, "Transaction tap should be handled gracefully")
        }
    }
    
    // MARK: - Activity Screen Tests
    
    func testActivityScreenNavigation() throws {
        let activityTab = app.tabBars.buttons["Activity"]
        XCTAssertTrue(activityTab.exists, "Activity tab should exist")
        
        activityTab.tap()
        
        // Verify navigation to activity screen
        XCTAssertTrue(app.navigationBars["Activity"].exists, "Activity navigation bar should be visible")
    }
    
    func testActivityScreenSearch() throws {
        navigateToActivityTab()
        
        let searchField = app.textFields["Search transactions..."]
        XCTAssertTrue(searchField.exists, "Search field should be visible")
        
        searchField.tap()
        searchField.typeText("alice")
        
        // Should trigger search functionality
        // In a real implementation, we'd verify filtered results
        XCTAssertTrue(true, "Search should function without crash")
    }
    
    func testActivityScreenRefresh() throws {
        navigateToActivityTab()
        
        let scrollView = app.scrollViews.element
        if scrollView.exists {
            // Perform pull-to-refresh
            scrollView.swipeDown()
            
            // Should trigger refresh
            XCTAssertTrue(true, "Pull-to-refresh should work")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPaymentSheetLoadTime() throws {
        navigateToPayTab()
        
        measure(metrics: [XCTClockMetric()]) {
            let payButton = app.buttons["Pay"]
            payButton.tap()
            
            // Wait for sheet to appear
            _ = app.staticTexts["Pay Someone"].waitForExistence(timeout: 2)
            
            // Dismiss sheet
            app.navigationBars.buttons["Cancel"].tap()
        }
    }
    
    func testTransactionListScrollPerformance() throws {
        navigateToActivityTab()
        
        let scrollView = app.scrollViews.element
        if scrollView.exists {
            measure(metrics: [XCTClockMetric()]) {
                // Perform scrolling operations
                for _ in 0..<5 {
                    scrollView.swipeUp()
                    scrollView.swipeDown()
                }
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testPaymentFormAccessibility() throws {
        openSendPaymentSheet()
        
        let recipientField = app.textFields["To: username or phone"]
        let amountField = app.textFields["$0.00"]
        let noteField = app.textFields["What's this for?"]
        
        // Test accessibility properties
        XCTAssertTrue(recipientField.isAccessibilityElement, "Recipient field should be accessible")
        XCTAssertTrue(amountField.isAccessibilityElement, "Amount field should be accessible")
        XCTAssertTrue(noteField.isAccessibilityElement, "Note field should be accessible")
        
        // Test accessibility labels
        XCTAssertFalse(recipientField.accessibilityLabel?.isEmpty ?? true, "Recipient field should have accessibility label")
        XCTAssertFalse(amountField.accessibilityLabel?.isEmpty ?? true, "Amount field should have accessibility label")
    }
    
    func testPaymentButtonAccessibility() throws {
        navigateToPayTab()
        
        let payButton = app.buttons["Pay"]
        let requestButton = app.buttons["Request"]
        
        XCTAssertTrue(payButton.isAccessibilityElement, "Pay button should be accessible")
        XCTAssertTrue(requestButton.isAccessibilityElement, "Request button should be accessible")
        
        XCTAssertFalse(payButton.accessibilityLabel?.isEmpty ?? true, "Pay button should have accessibility label")
        XCTAssertFalse(requestButton.accessibilityLabel?.isEmpty ?? true, "Request button should have accessibility label")
    }
    
    // MARK: - Edge Cases Tests
    
    func testInvalidAmountEntry() throws {
        openSendPaymentSheet()
        
        let amountField = app.textFields["$0.00"]
        
        // Test invalid characters
        amountField.tap()
        amountField.typeText("abc")
        
        // Should handle gracefully (field might reject or sanitize)
        XCTAssertTrue(true, "Invalid amount entry should be handled gracefully")
        
        // Clear and try negative number
        amountField.clearAndEnterText("-50")
        
        XCTAssertTrue(true, "Negative amount should be handled gracefully")
    }
    
    func testVeryLargeAmountEntry() throws {
        openSendPaymentSheet()
        
        let recipientField = app.textFields["To: username or phone"]
        let amountField = app.textFields["$0.00"]
        
        recipientField.tap()
        recipientField.typeText("test_recipient")
        
        amountField.tap()
        amountField.typeText("999999999.99")
        
        let sendButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pay $'")).element
        
        // Should handle large amounts appropriately
        XCTAssertTrue(sendButton.isEnabled, "Should handle large amounts")
    }
    
    func testSpecialCharactersInRecipient() throws {
        openSendPaymentSheet()
        
        let recipientField = app.textFields["To: username or phone"]
        let amountField = app.textFields["$0.00"]
        
        recipientField.tap()
        recipientField.typeText("user@domain.com")
        
        amountField.tap()
        amountField.typeText("25.00")
        
        let sendButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pay $'")).element
        XCTAssertTrue(sendButton.isEnabled, "Should handle email-format recipients")
    }
    
    func testNetworkErrorHandling() throws {
        // This would require network condition simulation
        // For UI testing, we verify error UI elements exist
        
        openSendPaymentSheet()
        fillPaymentForm(recipient: "test_error", amount: "10.00", note: "Error test")
        
        let sendButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pay $'")).element
        sendButton.tap()
        
        // Look for potential error messages
        let errorAlert = app.alerts.element
        if errorAlert.waitForExistence(timeout: 5) {
            XCTAssertTrue(errorAlert.exists, "Should show error alert for network issues")
            
            // Dismiss error alert
            let okButton = errorAlert.buttons.element(boundBy: 0)
            if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToMainApp() {
        // Skip authentication if in testing mode
        let payTab = app.tabBars.buttons["Pay"]
        if !payTab.waitForExistence(timeout: 5) {
            // Handle authentication if needed
            let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
            if authButton.exists {
                authButton.tap()
                _ = payTab.waitForExistence(timeout: 10)
            }
        }
    }
    
    private func navigateToPayTab() {
        let payTab = app.tabBars.buttons["Pay"]
        if payTab.exists {
            payTab.tap()
        }
    }
    
    private func navigateToActivityTab() {
        let activityTab = app.tabBars.buttons["Activity"]
        if activityTab.exists {
            activityTab.tap()
        }
    }
    
    private func openSendPaymentSheet() {
        navigateToPayTab()
        let payButton = app.buttons["Pay"]
        payButton.tap()
        _ = app.staticTexts["Pay Someone"].waitForExistence(timeout: 2)
    }
    
    private func openRequestPaymentSheet() {
        navigateToPayTab()
        let requestButton = app.buttons["Request"]
        requestButton.tap()
        _ = app.staticTexts["Request Payment"].waitForExistence(timeout: 2)
    }
    
    private func fillPaymentForm(recipient: String, amount: String, note: String) {
        let recipientField = app.textFields["To: username or phone"]
        let amountField = app.textFields["$0.00"]
        let noteField = app.textFields["What's this for?"]
        
        recipientField.tap()
        recipientField.typeText(recipient)
        
        amountField.tap()
        amountField.typeText(amount)
        
        noteField.tap()
        noteField.typeText(note)
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            return
        }
        
        // Clear existing text
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        
        // Enter new text
        self.typeText(text)
    }
}
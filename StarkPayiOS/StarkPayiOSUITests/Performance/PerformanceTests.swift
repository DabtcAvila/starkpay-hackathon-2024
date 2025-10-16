import XCTest
@testable import StarkPayiOS

/// Comprehensive performance tests for animations and UI responsiveness
/// Tests launch time, animation performance, memory usage, and UI responsiveness
final class PerformanceTests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments.append("--performance-testing")
        app.launchEnvironment["ANIMATION_SPEED"] = "1.0" // Normal speed for performance testing
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - App Launch Performance Tests
    
    func testAppLaunchTime() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    func testAppLaunchMemory() throws {
        let launchOptions = XCTMeasureOptions()
        launchOptions.iterationCount = 5
        
        measure(metrics: [XCTMemoryMetric()], options: launchOptions) {
            app.launch()
            app.terminate()
        }
    }
    
    func testColdLaunchPerformance() throws {
        // Simulate cold launch by terminating and relaunching
        for _ in 0..<3 {
            app.terminate()
            
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                app.launch()
            }
        }
    }
    
    func testWarmLaunchPerformance() throws {
        app.launch()
        
        // Background and foreground to simulate warm launch
        measure(metrics: [XCTClockMetric()]) {
            // Simulate backgrounding
            XCUIDevice.shared.press(.home)
            
            // Return to app
            app.activate()
        }
    }
    
    // MARK: - Splash Screen Animation Performance
    
    func testSplashScreenAnimationPerformance() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [XCTClockMetric()], options: options) {
            app.launch()
            
            // Wait for splash screen elements
            let splashTitle = app.staticTexts["StarkPay"]
            _ = splashTitle.waitForExistence(timeout: 5)
            
            // Wait for splash animations to complete
            let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
            _ = authButton.waitForExistence(timeout: 5)
            
            app.terminate()
        }
    }
    
    func testSplashToAuthTransitionPerformance() throws {
        app.launch()
        
        let splashTitle = app.staticTexts["StarkPay"]
        XCTAssertTrue(splashTitle.waitForExistence(timeout: 2), "Splash should appear")
        
        measure(metrics: [XCTClockMetric()]) {
            // Measure transition from splash to auth screen
            let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
            _ = authButton.waitForExistence(timeout: 5)
        }
    }
    
    // MARK: - Authentication Screen Performance
    
    func testAuthenticationScreenRenderingPerformance() throws {
        navigateToAuthScreen()
        
        measure(metrics: [XCTClockMetric()]) {
            // Test UI responsiveness on auth screen
            let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
            
            for _ in 0..<5 {
                // Tap and wait for response
                if authButton.exists && authButton.isHittable {
                    authButton.tap()
                }
            }
        }
    }
    
    func testAuthenticationAnimationFrameRate() throws {
        navigateToAuthScreen()
        
        // Test animated elements on auth screen
        let logoIcon = app.images.matching(NSPredicate(format: "identifier CONTAINS 'shield' OR identifier CONTAINS 'bolt'")).element
        
        if logoIcon.exists {
            measure(metrics: [XCTClockMetric()]) {
                // Let animations run for a few seconds
                sleep(3)
            }
        }
    }
    
    func testBiometricButtonResponseTime() throws {
        navigateToAuthScreen()
        
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        
        measure(metrics: [XCTClockMetric()]) {
            if authButton.exists && authButton.isHittable {
                authButton.tap()
            }
        }
    }
    
    // MARK: - Main App Performance Tests
    
    func testTabSwitchingPerformance() throws {
        navigateToMainApp()
        
        let payTab = app.tabBars.buttons["Pay"]
        let activityTab = app.tabBars.buttons["Activity"]
        let profileTab = app.tabBars.buttons["You"]
        
        measure(metrics: [XCTClockMetric()]) {
            // Switch between tabs multiple times
            for _ in 0..<5 {
                payTab.tap()
                activityTab.tap()
                profileTab.tap()
            }
        }
    }
    
    func testMainScreenLoadPerformance() throws {
        navigateToMainApp()
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Navigate to each main screen
            app.tabBars.buttons["Pay"].tap()
            sleep(1)
            
            app.tabBars.buttons["Activity"].tap()
            sleep(1)
            
            app.tabBars.buttons["You"].tap()
            sleep(1)
        }
    }
    
    // MARK: - Payment Flow Performance
    
    func testPaymentSheetPresentationPerformance() throws {
        navigateToMainApp()
        app.tabBars.buttons["Pay"].tap()
        
        let payButton = app.buttons["Pay"]
        
        measure(metrics: [XCTClockMetric()]) {
            payButton.tap()
            
            // Wait for sheet to appear
            _ = app.staticTexts["Pay Someone"].waitForExistence(timeout: 2)
            
            // Dismiss sheet
            app.navigationBars.buttons["Cancel"].tap()
            
            // Wait for sheet to dismiss
            _ = payButton.waitForExistence(timeout: 2)
        }
    }
    
    func testPaymentFormInputPerformance() throws {
        openPaymentSheet()
        
        let recipientField = app.textFields["To: username or phone"]
        let amountField = app.textFields["$0.00"]
        let noteField = app.textFields["What's this for?"]
        
        measure(metrics: [XCTClockMetric()]) {
            recipientField.tap()
            recipientField.typeText("performance_test_recipient")
            
            amountField.tap()
            amountField.typeText("123.45")
            
            noteField.tap()
            noteField.typeText("Performance test payment note")
        }
    }
    
    func testPaymentProcessingAnimationPerformance() throws {
        openPaymentSheet()
        
        // Fill form
        fillPaymentForm(recipient: "test_recipient", amount: "50.00", note: "Test")
        
        let sendButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pay $'")).element
        
        measure(metrics: [XCTClockMetric()]) {
            sendButton.tap()
            
            // Wait for processing animations
            sleep(2)
        }
    }
    
    // MARK: - Activity Screen Performance
    
    func testTransactionListScrollPerformance() throws {
        navigateToMainApp()
        app.tabBars.buttons["Activity"].tap()
        
        let scrollView = app.scrollViews.element
        
        if scrollView.exists {
            measure(metrics: [XCTClockMetric()]) {
                // Perform intensive scrolling
                for _ in 0..<10 {
                    scrollView.swipeUp()
                    scrollView.swipeDown()
                }
            }
        }
    }
    
    func testSearchPerformance() throws {
        navigateToMainApp()
        app.tabBars.buttons["Activity"].tap()
        
        let searchField = app.textFields["Search transactions..."]
        
        if searchField.exists {
            measure(metrics: [XCTClockMetric()]) {
                searchField.tap()
                searchField.typeText("test search query")
                
                // Wait for search results
                sleep(1)
                
                // Clear search
                if let clearButton = searchField.buttons.matching(identifier: "Clear text").element.firstMatch.isHittable ? searchField.buttons.matching(identifier: "Clear text").element.firstMatch : nil {
                    clearButton.tap()
                }
            }
        }
    }
    
    func testPullToRefreshPerformance() throws {
        navigateToMainApp()
        app.tabBars.buttons["Activity"].tap()
        
        let scrollView = app.scrollViews.element
        
        if scrollView.exists {
            measure(metrics: [XCTClockMetric()]) {
                // Perform pull-to-refresh multiple times
                for _ in 0..<5 {
                    scrollView.swipeDown()
                    sleep(1) // Wait for refresh to complete
                }
            }
        }
    }
    
    // MARK: - Animation Performance Tests
    
    func testBalanceUpdateAnimationPerformance() throws {
        navigateToMainApp()
        app.tabBars.buttons["Pay"].tap()
        
        let refreshButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'arrow.clockwise'")).element
        
        if refreshButton.exists {
            measure(metrics: [XCTClockMetric()]) {
                // Trigger balance updates and measure animation performance
                for _ in 0..<3 {
                    refreshButton.tap()
                    sleep(1)
                }
            }
        }
    }
    
    func testTransactionRowAnimationPerformance() throws {
        navigateToMainApp()
        app.tabBars.buttons["Pay"].tap()
        
        // Trigger new transaction to test row animation
        let payButton = app.buttons["Pay"]
        
        measure(metrics: [XCTClockMetric()]) {
            payButton.tap()
            
            // Fill and submit payment to trigger new transaction row
            fillPaymentForm(recipient: "animation_test", amount: "10.00", note: "Animation test")
            
            let sendButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pay $'")).element
            if sendButton.exists && sendButton.isEnabled {
                sendButton.tap()
                
                // Wait for animation to complete
                sleep(2)
                
                // Return to main screen to see new transaction
                let cancelButton = app.navigationBars.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageDuringNavigation() throws {
        app.launch()
        
        measure(metrics: [XCTMemoryMetric()]) {
            navigateToMainApp()
            
            // Navigate through all screens
            let tabs = ["Pay", "Activity", "You"]
            
            for _ in 0..<5 {
                for tab in tabs {
                    app.tabBars.buttons[tab].tap()
                    sleep(1)
                }
            }
        }
    }
    
    func testMemoryUsageDuringPaymentFlows() throws {
        navigateToMainApp()
        
        measure(metrics: [XCTMemoryMetric()]) {
            // Perform multiple payment operations
            for _ in 0..<3 {
                openPaymentSheet()
                fillPaymentForm(recipient: "memory_test_\(Date().timeIntervalSince1970)", 
                               amount: "25.00", 
                               note: "Memory test")
                
                let sendButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pay $'")).element
                if sendButton.isEnabled {
                    sendButton.tap()
                    sleep(2)
                }
                
                // Cancel/dismiss
                let cancelButton = app.navigationBars.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }
    
    // MARK: - CPU Performance Tests
    
    func testCPUUsageDuringAnimations() throws {
        navigateToAuthScreen()
        
        measure(metrics: [XCTCPUMetric()]) {
            // Let splash and auth animations run
            sleep(5)
        }
    }
    
    func testCPUUsageDuringScrolling() throws {
        navigateToMainApp()
        app.tabBars.buttons["Activity"].tap()
        
        let scrollView = app.scrollViews.element
        
        if scrollView.exists {
            measure(metrics: [XCTCPUMetric()]) {
                // Intensive scrolling to test CPU usage
                for _ in 0..<20 {
                    scrollView.swipeUp()
                    scrollView.swipeDown()
                }
            }
        }
    }
    
    // MARK: - Disk I/O Performance Tests
    
    func testDiskWritePerformanceDuringTransactions() throws {
        navigateToMainApp()
        
        measure(metrics: [XCTStorageMetric()]) {
            // Create multiple transactions to test data persistence performance
            for i in 0..<5 {
                openPaymentSheet()
                fillPaymentForm(recipient: "disk_test_\(i)", 
                               amount: "\(10 + i).00", 
                               note: "Disk performance test \(i)")
                
                let sendButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pay $'")).element
                if sendButton.isEnabled {
                    sendButton.tap()
                    sleep(1)
                }
                
                // Dismiss
                let cancelButton = app.navigationBars.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }
    
    // MARK: - UI Responsiveness Tests
    
    func testButtonResponseTimes() throws {
        navigateToMainApp()
        
        let buttons = [
            app.tabBars.buttons["Pay"],
            app.tabBars.buttons["Activity"], 
            app.tabBars.buttons["You"]
        ]
        
        measure(metrics: [XCTClockMetric()]) {
            for button in buttons {
                if button.exists && button.isHittable {
                    button.tap()
                }
            }
        }
    }
    
    func testTextInputResponseTimes() throws {
        openPaymentSheet()
        
        let textFields = [
            app.textFields["To: username or phone"],
            app.textFields["$0.00"],
            app.textFields["What's this for?"]
        ]
        
        measure(metrics: [XCTClockMetric()]) {
            for (index, field) in textFields.enumerated() {
                if field.exists {
                    field.tap()
                    field.typeText("test input \(index)")
                }
            }
        }
    }
    
    func testGestureResponseTimes() throws {
        navigateToMainApp()
        app.tabBars.buttons["Activity"].tap()
        
        let scrollView = app.scrollViews.element
        
        if scrollView.exists {
            measure(metrics: [XCTClockMetric()]) {
                // Test various gesture responses
                scrollView.swipeUp()
                scrollView.swipeDown()
                scrollView.swipeLeft()
                scrollView.swipeRight()
            }
        }
    }
    
    // MARK: - Stress Tests
    
    func testRapidTapStressTest() throws {
        navigateToMainApp()
        
        let payButton = app.buttons["Pay"]
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Rapid tapping stress test
            for _ in 0..<50 {
                if payButton.exists && payButton.isHittable {
                    payButton.tap()
                    
                    // Immediately dismiss if sheet opens
                    let cancelButton = app.navigationBars.buttons["Cancel"]
                    if cancelButton.exists {
                        cancelButton.tap()
                    }
                }
            }
        }
    }
    
    func testMemoryPressureRecovery() throws {
        app.launch()
        
        // Generate memory pressure through intensive operations
        measure(metrics: [XCTMemoryMetric()]) {
            for _ in 0..<10 {
                navigateToMainApp()
                
                // Open and close payment sheets rapidly
                for _ in 0..<10 {
                    openPaymentSheet()
                    app.navigationBars.buttons["Cancel"].tap()
                }
                
                // Force app to background and foreground
                XCUIDevice.shared.press(.home)
                app.activate()
            }
        }
    }
    
    // MARK: - Network Performance Simulation
    
    func testSlowNetworkPerformance() throws {
        // This would require network condition simulation in a real environment
        navigateToMainApp()
        
        measure(metrics: [XCTClockMetric()]) {
            // Simulate operations that might involve network calls
            app.tabBars.buttons["Activity"].tap()
            
            let scrollView = app.scrollViews.element
            if scrollView.exists {
                scrollView.swipeDown() // Pull to refresh
                sleep(3) // Wait for potential network operations
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToAuthScreen() {
        app.launch()
        
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        _ = authButton.waitForExistence(timeout: 5)
    }
    
    private func navigateToMainApp() {
        navigateToAuthScreen()
        
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        if authButton.exists {
            authButton.tap()
        }
        
        // Wait for main app to load
        let payTab = app.tabBars.buttons["Pay"]
        _ = payTab.waitForExistence(timeout: 10)
    }
    
    private func openPaymentSheet() {
        navigateToMainApp()
        app.tabBars.buttons["Pay"].tap()
        
        let payButton = app.buttons["Pay"]
        payButton.tap()
        
        _ = app.staticTexts["Pay Someone"].waitForExistence(timeout: 2)
    }
    
    private func fillPaymentForm(recipient: String, amount: String, note: String) {
        let recipientField = app.textFields["To: username or phone"]
        let amountField = app.textFields["$0.00"]
        let noteField = app.textFields["What's this for?"]
        
        if recipientField.exists {
            recipientField.tap()
            recipientField.typeText(recipient)
        }
        
        if amountField.exists {
            amountField.tap()
            amountField.typeText(amount)
        }
        
        if noteField.exists {
            noteField.tap()
            noteField.typeText(note)
        }
    }
}
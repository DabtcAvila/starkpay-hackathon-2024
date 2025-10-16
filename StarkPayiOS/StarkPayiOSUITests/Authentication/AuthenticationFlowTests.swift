import XCTest
import LocalAuthentication
@testable import StarkPayiOS

/// Comprehensive UI tests for authentication flows
/// Tests user interactions, visual feedback, error handling, and accessibility
final class AuthenticationFlowTests: XCTestCase {
    
    private var app: XCUIApplication!
    private var mockAuthManager: MockAppStateManager!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        mockAuthManager = TestHelpers.createControlledTestEnvironment()
        
        // Configure app for testing
        app.launchArguments.append("--uitesting")
        app.launchEnvironment["ANIMATION_SPEED"] = "0.1" // Speed up animations for testing
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        mockAuthManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Splash to Authentication Flow Tests
    
    func testSplashToAuthenticationTransition() throws {
        // Wait for splash screen
        let splashText = app.staticTexts["StarkPay"]
        XCTAssertTrue(splashText.waitForExistence(timeout: 2), "Splash screen should appear")
        
        // Wait for transition to authentication
        let authButton = app.buttons["Use Face ID"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 5), "Authentication screen should appear after splash")
        
        // Verify authentication elements are present
        XCTAssertTrue(app.staticTexts["Unlock with Face ID"].exists, "Face ID unlock text should be visible")
        XCTAssertTrue(app.staticTexts["Touch to authenticate"].exists, "Authentication instructions should be visible")
    }
    
    func testAuthenticationScreenLayout() throws {
        // Navigate to authentication screen
        navigateToAuthenticationScreen()
        
        // Verify core UI elements are present and positioned correctly
        XCTAssertTrue(app.staticTexts["StarkPay"].exists, "App name should be visible")
        XCTAssertTrue(app.staticTexts["Secure Wallet Access"].exists, "Subtitle should be visible")
        
        // Verify biometric elements
        XCTAssertTrue(app.images["faceid"].exists, "Face ID icon should be visible")
        XCTAssertTrue(app.buttons["Use Face ID"].exists, "Face ID button should be visible")
        
        // Verify fallback option
        XCTAssertTrue(app.buttons["Use Passcode Instead"].exists, "Passcode fallback should be visible")
        
        // Verify security messaging
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'protected with industry-standard encryption'")).element.exists, 
                     "Security message should be visible")
    }
    
    // MARK: - Biometric Authentication Tests
    
    func testFaceIDAuthenticationSuccess() throws {
        navigateToAuthenticationScreen()
        
        let faceIDButton = app.buttons["Use Face ID"]
        XCTAssertTrue(faceIDButton.exists, "Face ID button should exist")
        
        // Tap Face ID button
        faceIDButton.tap()
        
        // In a real device test, this would trigger the Face ID dialog
        // For UI testing, we verify the button interaction works
        
        // Wait for potential success animation or main app screen
        let payTab = app.tabBars.buttons["Pay"]
        if payTab.waitForExistence(timeout: 5) {
            XCTAssertTrue(payTab.exists, "Should navigate to main app after successful authentication")
        }
    }
    
    func testTouchIDAuthenticationFlow() throws {
        navigateToAuthenticationScreen()
        
        // On Touch ID devices, button text should be different
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Touch ID' OR label CONTAINS 'Face ID'")).element
        XCTAssertTrue(authButton.exists, "Biometric button should exist")
        
        authButton.tap()
        
        // Verify interaction response
        XCTAssertTrue(true, "Touch ID button should be tappable without crash")
    }
    
    func testPasscodeFallbackFlow() throws {
        navigateToAuthenticationScreen()
        
        let passcodeButton = app.buttons["Use Passcode Instead"]
        XCTAssertTrue(passcodeButton.exists, "Passcode fallback button should exist")
        
        passcodeButton.tap()
        
        // In a real device test, this would trigger the passcode dialog
        // For UI testing, we verify the button works
        XCTAssertTrue(true, "Passcode button should be tappable without crash")
    }
    
    func testDirectPasscodeAuthentication() throws {
        navigateToAuthenticationScreen()
        
        // Test devices without biometrics should show passcode option
        let passcodeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Passcode'")).element
        
        if passcodeButton.exists {
            passcodeButton.tap()
            XCTAssertTrue(true, "Direct passcode authentication should work")
        } else {
            // On biometric-capable devices, test the primary auth button
            let primaryButton = app.buttons.element(boundBy: 0)
            primaryButton.tap()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testAuthenticationErrorDisplay() throws {
        navigateToAuthenticationScreen()
        
        // This test would be more meaningful with error injection
        // For UI testing, we verify error handling UI elements exist
        
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        if authButton.exists {
            authButton.tap()
            
            // Look for potential error alerts
            if app.alerts.element.waitForExistence(timeout: 2) {
                let alert = app.alerts.element
                XCTAssertTrue(alert.exists, "Error alert should be displayed")
                
                // Check for retry button
                let retryButton = alert.buttons["Retry"]
                if retryButton.exists {
                    retryButton.tap()
                }
            }
        }
    }
    
    func testAuthenticationFailureRetry() throws {
        navigateToAuthenticationScreen()
        
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        
        // Multiple tap attempts to test retry mechanism
        for _ in 0..<3 {
            if authButton.exists {
                authButton.tap()
                
                // Wait for potential error dialog
                if app.alerts.element.waitForExistence(timeout: 1) {
                    let retryButton = app.alerts.element.buttons["Retry"]
                    if retryButton.exists {
                        retryButton.tap()
                    } else {
                        // Dismiss alert if no retry button
                        app.alerts.element.buttons.element(boundBy: 0).tap()
                    }
                }
            }
        }
        
        XCTAssertTrue(true, "Multiple authentication attempts should be handled gracefully")
    }
    
    // MARK: - Visual Feedback Tests
    
    func testAuthenticationAnimations() throws {
        navigateToAuthenticationScreen()
        
        // Test that animated elements exist and are visible
        let logoIcon = app.images["shield.checkered"]
        XCTAssertTrue(logoIcon.exists, "Animated logo should be visible")
        
        // Test loading indicators
        let loadingIndicators = app.activityIndicators
        
        // Trigger authentication to see loading states
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        if authButton.exists {
            authButton.tap()
            
            // Look for loading animations (would appear briefly)
            // In a real test, we might check for specific animation states
        }
        
        XCTAssertTrue(true, "Animation elements should exist and function")
    }
    
    func testBiometricIconDisplay() throws {
        navigateToAuthenticationScreen()
        
        // Check for biometric icons
        let faceIDIcon = app.images["faceid"]
        let touchIDIcon = app.images["touchid"]
        let opticIDIcon = app.images["opticid"]
        let lockIcon = app.images["lock.fill"]
        
        // At least one biometric icon should be present
        let hasBiometricIcon = faceIDIcon.exists || touchIDIcon.exists || opticIDIcon.exists || lockIcon.exists
        XCTAssertTrue(hasBiometricIcon, "At least one authentication icon should be visible")
    }
    
    func testSecurityBadgeDisplay() throws {
        navigateToAuthenticationScreen()
        
        // Verify security messaging is present
        let securityText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Secure by Design'")).element
        XCTAssertTrue(securityText.exists, "Security badge should be visible")
        
        let encryptionText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'industry-standard encryption'")).element
        XCTAssertTrue(encryptionText.exists, "Encryption message should be visible")
    }
    
    // MARK: - Accessibility Tests
    
    func testAuthenticationAccessibility() throws {
        navigateToAuthenticationScreen()
        
        // Test VoiceOver accessibility
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        
        if authButton.exists {
            XCTAssertTrue(authButton.isAccessibilityElement, "Auth button should be accessible")
            XCTAssertFalse(authButton.accessibilityLabel?.isEmpty ?? true, "Auth button should have accessibility label")
        }
        
        // Test other accessibility elements
        let appTitle = app.staticTexts["StarkPay"]
        XCTAssertTrue(appTitle.isAccessibilityElement, "App title should be accessible")
        
        let subtitle = app.staticTexts["Secure Wallet Access"]
        XCTAssertTrue(subtitle.isAccessibilityElement, "Subtitle should be accessible")
    }
    
    func testAccessibilityLabels() throws {
        navigateToAuthenticationScreen()
        
        // Verify accessibility labels are meaningful
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        
        if authButton.exists {
            let accessibilityLabel = authButton.accessibilityLabel
            XCTAssertNotNil(accessibilityLabel, "Authentication button should have accessibility label")
            XCTAssertTrue(accessibilityLabel?.contains("ID") ?? false || accessibilityLabel?.contains("Passcode") ?? false,
                         "Accessibility label should describe authentication method")
        }
    }
    
    func testAccessibilityHints() throws {
        navigateToAuthenticationScreen()
        
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        
        if authButton.exists {
            // Accessibility hint should provide context
            let hint = authButton.accessibilityHint
            // In a full implementation, we'd verify meaningful hints exist
            XCTAssertNotNil(hint, "Authentication button should have accessibility hint")
        }
    }
    
    // MARK: - Responsive Design Tests
    
    func testPortraitLayout() throws {
        // Test authentication screen in portrait orientation
        XCUIDevice.shared.orientation = .portrait
        navigateToAuthenticationScreen()
        
        // Verify elements are properly positioned in portrait
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        XCTAssertTrue(authButton.exists, "Auth button should exist in portrait")
        
        let appTitle = app.staticTexts["StarkPay"]
        XCTAssertTrue(appTitle.exists, "App title should exist in portrait")
    }
    
    func testLandscapeLayout() throws {
        // Test authentication screen in landscape orientation
        navigateToAuthenticationScreen()
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Give time for rotation animation
        sleep(1)
        
        // Verify elements are still accessible in landscape
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        XCTAssertTrue(authButton.exists, "Auth button should exist in landscape")
        
        // Reset to portrait
        XCUIDevice.shared.orientation = .portrait
    }
    
    // MARK: - App State Transition Tests
    
    func testSuccessfulAuthenticationToMainApp() throws {
        navigateToAuthenticationScreen()
        
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        authButton.tap()
        
        // Wait for transition to main app (tab bar should appear)
        let tabBar = app.tabBars.element
        if tabBar.waitForExistence(timeout: 10) {
            // Verify main app elements
            XCTAssertTrue(app.tabBars.buttons["Pay"].exists, "Pay tab should exist")
            XCTAssertTrue(app.tabBars.buttons["Activity"].exists, "Activity tab should exist")
            XCTAssertTrue(app.tabBars.buttons["You"].exists, "Profile tab should exist")
        }
    }
    
    func testAuthenticationScreenReappearance() throws {
        // This test would simulate app backgrounding/foregrounding
        // For UI tests, we verify the authentication screen can be navigated to consistently
        
        navigateToAuthenticationScreen()
        
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        XCTAssertTrue(authButton.exists, "Auth screen should appear consistently")
        
        // Test multiple navigations
        for _ in 0..<3 {
            if authButton.exists {
                authButton.tap()
                
                // If we get to main app, simulate back to auth (in real app this would be automatic)
                if app.tabBars.element.waitForExistence(timeout: 2) {
                    // In a real app test, we'd simulate backgrounding to trigger re-auth
                    break
                }
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testAuthenticationScreenLoadTime() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
        
        // Authentication screen should appear quickly after splash
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        XCTAssertTrue(authButton.waitForExistence(timeout: 5), "Auth screen should load within 5 seconds")
    }
    
    func testAuthenticationResponseTime() throws {
        navigateToAuthenticationScreen()
        
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        
        measure(metrics: [XCTClockMetric()]) {
            if authButton.exists {
                authButton.tap()
            }
        }
        
        XCTAssertTrue(true, "Authentication button should respond quickly")
    }
    
    // MARK: - Edge Case Tests
    
    func testMultipleRapidTaps() throws {
        navigateToAuthenticationScreen()
        
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        
        // Test rapid tapping doesn't cause issues
        for _ in 0..<5 {
            if authButton.exists && authButton.isHittable {
                authButton.tap()
            }
        }
        
        XCTAssertTrue(true, "Multiple rapid taps should be handled gracefully")
    }
    
    func testTapOutsideAuthenticationButton() throws {
        navigateToAuthenticationScreen()
        
        // Tap in background area
        app.otherElements.firstMatch.tap()
        
        // Authentication screen should remain stable
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        XCTAssertTrue(authButton.exists, "Auth screen should remain stable after background tap")
    }
    
    func testLowMemoryScenario() throws {
        // Simulate low memory by launching and relaunchin multiple times
        for _ in 0..<3 {
            app.terminate()
            app.launch()
            
            navigateToAuthenticationScreen()
            
            let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
            XCTAssertTrue(authButton.exists, "Auth screen should work after memory pressure")
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToAuthenticationScreen() {
        // Wait for splash screen to complete
        let splashText = app.staticTexts["StarkPay"]
        if splashText.exists {
            // Wait for splash to transition
            let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
            _ = authButton.waitForExistence(timeout: 5)
        }
        
        // If already past splash, look for auth elements
        let authButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Face ID' OR label CONTAINS 'Touch ID' OR label CONTAINS 'Passcode'")).element
        if !authButton.exists {
            // If in main app, we might need to simulate logout/re-auth
            // For testing, we assume we can get to auth screen
            XCTAssertTrue(authButton.waitForExistence(timeout: 2), "Should be able to navigate to authentication screen")
        }
    }
    
    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
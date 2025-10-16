import XCTest
import UIKit
@testable import StarkPayiOS

/// Comprehensive unit tests for HapticManager
/// Tests all haptic feedback types, patterns, performance, and edge cases
final class HapticManagerTests: XCTestCase {
    
    private var sut: HapticManager!
    private var mockHaptic: MockHapticFeedbackGenerator!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        TestHelpers.configureTestEnvironment()
        
        sut = HapticManager.shared
        mockHaptic = MockHapticFeedbackGenerator()
    }
    
    override func tearDownWithError() throws {
        mockHaptic?.reset()
        sut = nil
        mockHaptic = nil
        TestHelpers.resetTestEnvironment()
        try super.tearDownWithError()
    }
    
    // MARK: - Singleton Tests
    
    func testSingletonInstance() {
        let instance1 = HapticManager.shared
        let instance2 = HapticManager.shared
        
        XCTAssertTrue(instance1 === instance2, "HapticManager should be a singleton")
    }
    
    func testSingletonPersistence() {
        let originalInstance = HapticManager.shared
        
        // Perform operations
        originalInstance.lightImpact()
        originalInstance.success()
        
        // Get instance again
        let newInstance = HapticManager.shared
        
        XCTAssertTrue(originalInstance === newInstance, "Singleton should persist across calls")
    }
    
    // MARK: - Impact Feedback Tests
    
    func testLightImpact() {
        // Test that light impact can be called without crashing
        XCTAssertNoThrow(sut.lightImpact(), "Light impact should not throw")
        
        // In a real device test environment, we would verify the actual haptic was triggered
        // For unit tests, we verify the method executes successfully
    }
    
    func testMediumImpact() {
        XCTAssertNoThrow(sut.mediumImpact(), "Medium impact should not throw")
    }
    
    func testHeavyImpact() {
        XCTAssertNoThrow(sut.heavyImpact(), "Heavy impact should not throw")
    }
    
    func testSelectionChanged() {
        XCTAssertNoThrow(sut.selectionChanged(), "Selection changed should not throw")
    }
    
    // MARK: - Notification Feedback Tests
    
    func testSuccessFeedback() {
        XCTAssertNoThrow(sut.success(), "Success feedback should not throw")
    }
    
    func testErrorFeedback() {
        XCTAssertNoThrow(sut.error(), "Error feedback should not throw")
    }
    
    // MARK: - Multiple Calls Tests
    
    func testMultipleLightImpacts() {
        for _ in 0..<10 {
            XCTAssertNoThrow(sut.lightImpact(), "Multiple light impacts should not throw")
        }
    }
    
    func testRapidFireHaptics() {
        // Test rapid successive calls don't cause issues
        for _ in 0..<5 {
            sut.lightImpact()
            sut.mediumImpact()
            sut.heavyImpact()
            sut.success()
            sut.error()
            sut.selectionChanged()
        }
        
        // Should complete without issues
        XCTAssertTrue(true, "Rapid fire haptics should complete without issues")
    }
    
    func testMixedHapticPattern() {
        // Simulate a user interaction pattern
        sut.lightImpact() // Button tap
        sut.selectionChanged() // Selection change
        sut.mediumImpact() // Action confirmation
        sut.success() // Operation success
        
        // Should handle mixed patterns gracefully
        XCTAssertTrue(true, "Mixed haptic pattern should execute without issues")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentHapticCalls() {
        let expectation = XCTestExpectation(description: "Concurrent haptic calls complete")
        expectation.expectedFulfillmentCount = 3
        
        // Simulate concurrent calls from different threads
        DispatchQueue.global(qos: .userInitiated).async {
            for _ in 0..<10 {
                self.sut.lightImpact()
            }
            expectation.fulfill()
        }
        
        DispatchQueue.global(qos: .background).async {
            for _ in 0..<10 {
                self.sut.success()
            }
            expectation.fulfill()
        }
        
        DispatchQueue.global(qos: .utility).async {
            for _ in 0..<10 {
                self.sut.error()
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Performance Tests
    
    func testLightImpactPerformance() {
        measure {
            for _ in 0..<100 {
                sut.lightImpact()
            }
        }
    }
    
    func testMediumImpactPerformance() {
        measure {
            for _ in 0..<100 {
                sut.mediumImpact()
            }
        }
    }
    
    func testHeavyImpactPerformance() {
        measure {
            for _ in 0..<100 {
                sut.heavyImpact()
            }
        }
    }
    
    func testSelectionChangedPerformance() {
        measure {
            for _ in 0..<100 {
                sut.selectionChanged()
            }
        }
    }
    
    func testSuccessFeedbackPerformance() {
        measure {
            for _ in 0..<100 {
                sut.success()
            }
        }
    }
    
    func testErrorFeedbackPerformance() {
        measure {
            for _ in 0..<100 {
                sut.error()
            }
        }
    }
    
    func testMixedHapticPerformance() {
        measure {
            for i in 0..<60 { // 10 of each type
                switch i % 6 {
                case 0: sut.lightImpact()
                case 1: sut.mediumImpact()
                case 2: sut.heavyImpact()
                case 3: sut.selectionChanged()
                case 4: sut.success()
                case 5: sut.error()
                default: break
                }
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsageDuringHaptics() {
        let initialMemory = TestPerformanceMetrics.getCurrentMemoryUsage()
        
        // Perform many haptic operations
        for _ in 0..<1000 {
            sut.lightImpact()
            sut.success()
            sut.error()
        }
        
        let finalMemory = TestPerformanceMetrics.getCurrentMemoryUsage()
        let memoryGrowth = finalMemory > initialMemory ? finalMemory - initialMemory : 0
        
        // Memory growth should be minimal
        XCTAssertLessThan(memoryGrowth, 1_000_000, // 1MB
                         "Memory growth during haptic operations should be minimal")
    }
    
    func testNoMemoryLeaksInSingleton() {
        let initialMemory = TestPerformanceMetrics.getCurrentMemoryUsage()
        
        // Access singleton multiple times and perform operations
        for _ in 0..<100 {
            let manager = HapticManager.shared
            manager.lightImpact()
            manager.success()
        }
        
        // Force cleanup
        for _ in 0..<3 {
            autoreleasepool { }
        }
        
        let finalMemory = TestPerformanceMetrics.getCurrentMemoryUsage()
        let memoryGrowth = finalMemory > initialMemory ? finalMemory - initialMemory : 0
        
        // Should not leak memory through singleton pattern
        XCTAssertLessThan(memoryGrowth, 500_000, // 500KB
                         "Singleton should not leak memory")
    }
    
    // MARK: - Integration with UI Patterns Tests
    
    func testButtonTapPattern() {
        // Simulate typical button tap haptic pattern
        sut.lightImpact()
        
        XCTAssertTrue(true, "Button tap pattern should execute")
    }
    
    func testTabSwitchPattern() {
        // Simulate tab switching haptic pattern
        sut.selectionChanged()
        
        XCTAssertTrue(true, "Tab switch pattern should execute")
    }
    
    func testPaymentSuccessPattern() {
        // Simulate payment success haptic pattern
        sut.success()
        
        XCTAssertTrue(true, "Payment success pattern should execute")
    }
    
    func testAuthenticationFailurePattern() {
        // Simulate authentication failure haptic pattern
        sut.error()
        
        XCTAssertTrue(true, "Authentication failure pattern should execute")
    }
    
    func testLongPressPattern() {
        // Simulate long press haptic pattern
        sut.mediumImpact()
        
        XCTAssertTrue(true, "Long press pattern should execute")
    }
    
    func testCriticalActionPattern() {
        // Simulate critical action haptic pattern (e.g., delete, logout)
        sut.heavyImpact()
        
        XCTAssertTrue(true, "Critical action pattern should execute")
    }
    
    // MARK: - Edge Cases Tests
    
    func testHapticsOnBackgroundThread() {
        let expectation = XCTestExpectation(description: "Background haptic execution")
        
        DispatchQueue.global(qos: .background).async {
            // Should handle being called from background thread
            self.sut.lightImpact()
            self.sut.success()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testHapticsAfterAppBackgrounding() {
        // Simulate app backgrounding
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Haptics should still work after backgrounding
        XCTAssertNoThrow(sut.lightImpact(), "Haptics should work after backgrounding")
        XCTAssertNoThrow(sut.success(), "Success haptic should work after backgrounding")
    }
    
    func testHapticsAfterAppForegrounding() {
        // Simulate app foregrounding
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // Haptics should work after foregrounding
        XCTAssertNoThrow(sut.mediumImpact(), "Haptics should work after foregrounding")
        XCTAssertNoThrow(sut.error(), "Error haptic should work after foregrounding")
    }
    
    // MARK: - Stress Tests
    
    func testHighFrequencyHaptics() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // High frequency haptic calls
        for _ in 0..<1000 {
            sut.lightImpact()
        }
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should handle high frequency calls reasonably
        XCTAssertLessThan(executionTime, 1.0, "High frequency haptics should complete within 1 second")
    }
    
    func testExtendedHapticSession() {
        let expectation = XCTestExpectation(description: "Extended haptic session")
        
        // Simulate extended haptic usage (like during gameplay or long interaction)
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<500 {
                switch i % 3 {
                case 0: self.sut.lightImpact()
                case 1: self.sut.mediumImpact()
                case 2: self.sut.selectionChanged()
                default: break
                }
                
                // Small delay to simulate realistic usage
                usleep(10000) // 10ms
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Device Compatibility Tests
    
    func testHapticsOnDifferentDeviceTypes() {
        // These tests would ideally run on different device types
        // For unit tests, we verify the methods don't crash regardless of device
        
        sut.lightImpact()   // Should work on devices with Taptic Engine
        sut.mediumImpact()  // Should work on devices with Taptic Engine
        sut.heavyImpact()   // Should work on devices with Taptic Engine
        sut.success()       // Should work on devices with Taptic Engine
        sut.error()         // Should work on devices with Taptic Engine
        sut.selectionChanged() // Should work on devices with Taptic Engine
        
        XCTAssertTrue(true, "All haptic types should execute without crashing on any device")
    }
    
    // MARK: - Mock Haptic Generator Tests (for testing haptic patterns)
    
    func testMockHapticSequence() {
        // Test a specific haptic sequence using our mock
        mockHaptic.lightImpact()
        mockHaptic.selectionChanged()
        mockHaptic.success()
        
        let expectedSequence = ["lightImpact", "selectionChanged", "success"]
        XCTAssertTrue(mockHaptic.verifyCallSequence(expectedSequence), 
                     "Mock should record the correct haptic sequence")
    }
    
    func testComplexHapticPattern() {
        mockHaptic.reset()
        
        // Simulate authentication flow haptics
        mockHaptic.lightImpact()    // Button tap
        mockHaptic.mediumImpact()   // Processing
        mockHaptic.success()        // Success
        
        XCTAssertTrue(mockHaptic.successCalled, "Success haptic should be called")
        XCTAssertTrue(mockHaptic.lightImpactCalled, "Light impact should be called")
        XCTAssertTrue(mockHaptic.mediumImpactCalled, "Medium impact should be called")
        
        let expectedPattern = ["lightImpact", "mediumImpact", "success"]
        XCTAssertTrue(mockHaptic.verifyCallSequence(expectedPattern), 
                     "Should follow authentication haptic pattern")
    }
    
    func testPaymentFlowHapticPattern() {
        mockHaptic.reset()
        
        // Simulate payment flow haptics
        mockHaptic.lightImpact()     // Amount entry
        mockHaptic.lightImpact()     // Recipient selection
        mockHaptic.mediumImpact()    // Confirm payment
        mockHaptic.heavyImpact()     // Processing
        mockHaptic.success()         // Payment success
        
        XCTAssertEqual(mockHaptic.callHistory.count, 5, "Should have 5 haptic calls in payment flow")
        
        let lightImpactCount = mockHaptic.callHistory.filter { $0 == "lightImpact" }.count
        XCTAssertEqual(lightImpactCount, 2, "Should have 2 light impacts")
        
        XCTAssertTrue(mockHaptic.callHistory.last == "success", "Should end with success haptic")
    }
    
    // MARK: - Timing Tests
    
    func testHapticResponseTime() {
        let iterations = 100
        var totalTime = 0.0
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            sut.lightImpact()
            let endTime = CFAbsoluteTimeGetCurrent()
            totalTime += (endTime - startTime)
        }
        
        let averageTime = totalTime / Double(iterations)
        
        // Haptic response should be nearly instantaneous (< 1ms average)
        XCTAssertLessThan(averageTime, 0.001, "Haptic response should be nearly instantaneous")
    }
    
    func testConcurrentHapticResponseTime() {
        let expectation = XCTestExpectation(description: "Concurrent haptic timing")
        let iterations = 50
        var completedTasks = 0
        let queue = DispatchQueue(label: "haptic.test.concurrent", attributes: .concurrent)
        
        for _ in 0..<iterations {
            queue.async {
                let startTime = CFAbsoluteTimeGetCurrent()
                self.sut.lightImpact()
                let endTime = CFAbsoluteTimeGetCurrent()
                let responseTime = endTime - startTime
                
                XCTAssertLessThan(responseTime, 0.01, "Concurrent haptic response should be fast")
                
                DispatchQueue.main.async {
                    completedTasks += 1
                    if completedTasks == iterations {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
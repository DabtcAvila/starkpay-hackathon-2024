import XCTest
import SwiftUI
import Combine
@testable import StarkPayiOS

// MARK: - Test Configuration and Setup

/// Centralized test configuration and setup utilities
class TestHelpers {
    
    // MARK: - Test Environment Setup
    
    /// Configure test environment for consistent testing
    static func configureTestEnvironment() {
        // Disable animations for consistent UI testing
        UIView.setAnimationsEnabled(false)
        
        // Set consistent locale for formatting tests
        TimeZone.current = TimeZone(identifier: "UTC")
        Locale.current = Locale(identifier: "en_US")
    }
    
    /// Reset test environment after tests
    static func resetTestEnvironment() {
        UIView.setAnimationsEnabled(true)
    }
    
    // MARK: - Async Testing Utilities
    
    /// Wait for a published value to change with timeout
    static func waitForPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T.Output where T.Failure == Never {
        
        return try await withTimeout(timeout) {
            await withCheckedThrowingContinuation { continuation in
                let cancellable = publisher.sink { value in
                    continuation.resume(returning: value)
                }
                
                // Keep the cancellable alive
                withExtendedLifetime(cancellable) { }
            }
        }
    }
    
    /// Generic timeout utility for async operations
    static func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestTimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TestTimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - SwiftUI Testing Utilities
    
    /// Create a test hosting controller for SwiftUI views
    static func createTestHostingController<Content: View>(for view: Content) -> UIHostingController<Content> {
        let controller = UIHostingController(rootView: view)
        controller.loadViewIfNeeded()
        return controller
    }
    
    /// Wait for SwiftUI view updates to complete
    static func waitForViewUpdates() async {
        await MainActor.run {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
    }
    
    /// Find a SwiftUI view in the hierarchy by type
    static func findView<T: View>(_ viewType: T.Type, in view: UIView) -> T? {
        if let hostingView = view as? UIHostingController<T>.ViewType {
            return hostingView as? T
        }
        
        for subview in view.subviews {
            if let found = findView(viewType, in: subview) {
                return found
            }
        }
        
        return nil
    }
    
    // MARK: - Biometric Testing Utilities
    
    /// Setup mock biometric environment for testing
    static func setupMockBiometricEnvironment(
        biometryType: LABiometryType = .faceID,
        isAvailable: Bool = true,
        authResult: Result<Bool, Error> = .success(true)
    ) -> MockLAContext {
        let mockContext = MockLAContext()
        
        switch biometryType {
        case .faceID:
            mockContext.configureFaceID(available: isAvailable, success: authResult.isSuccess)
        case .touchID:
            mockContext.configureTouchID(available: isAvailable, success: authResult.isSuccess)
        case .opticID:
            mockContext.mockBiometryType = .opticID
            mockContext.mockCanEvaluatePolicy = isAvailable
            mockContext.mockAuthenticationResult = authResult
        default:
            mockContext.configureNoBiometrics()
        }
        
        if case .failure(let error) = authResult {
            mockContext.mockAuthenticationResult = .failure(error)
        }
        
        return mockContext
    }
    
    // MARK: - Transaction Testing Utilities
    
    /// Validate transaction data integrity
    static func validateTransactionIntegrity(_ transactions: [SimpleTransaction]) -> [String] {
        var issues: [String] = []
        
        for (index, transaction) in transactions.enumerated() {
            if transaction.id.isEmpty {
                issues.append("Transaction at index \(index) has empty ID")
            }
            
            if transaction.amount <= 0 {
                issues.append("Transaction at index \(index) has invalid amount: \(transaction.amount)")
            }
            
            if transaction.otherParty.isEmpty {
                issues.append("Transaction at index \(index) has empty other party")
            }
            
            if transaction.date > Date() {
                issues.append("Transaction at index \(index) has future date: \(transaction.date)")
            }
        }
        
        // Check for duplicate IDs
        let ids = transactions.map { $0.id }
        let uniqueIds = Set(ids)
        if ids.count != uniqueIds.count {
            issues.append("Duplicate transaction IDs found")
        }
        
        return issues
    }
    
    /// Generate test transactions with specific characteristics
    static func generateTestTransactions(
        count: Int,
        amountRange: ClosedRange<Double> = 1.0...1000.0,
        dateRange: ClosedRange<TimeInterval> = -86400...0, // Last 24 hours
        includeEdgeCases: Bool = false
    ) -> [SimpleTransaction] {
        var transactions: [SimpleTransaction] = []
        
        for i in 0..<count {
            let amount = includeEdgeCases && i == 0 ? 0.01 : Double.random(in: amountRange)
            let timeOffset = includeEdgeCases && i == 1 ? dateRange.lowerBound : Double.random(in: dateRange)
            
            transactions.append(SimpleTransaction(
                id: "test_txn_\(i)",
                amount: amount,
                otherParty: "test_party_\(i % 5)",
                isReceived: i % 2 == 0,
                date: Date().addingTimeInterval(timeOffset),
                note: includeEdgeCases && i == 2 ? "" : "Test transaction \(i)"
            ))
        }
        
        return transactions
    }
    
    // MARK: - Performance Testing Utilities
    
    /// Measure view rendering performance
    static func measureViewRenderingTime<T: View>(_ view: T) -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        let _ = createTestHostingController(for: view)
        return CFAbsoluteTimeGetCurrent() - startTime
    }
    
    /// Measure animation performance
    static func measureAnimationPerformance(
        duration: TimeInterval,
        animation: @escaping () -> Void
    ) async -> TestPerformanceMetrics.AnimationPerformanceMetrics {
        let startTime = CFAbsoluteTimeGetCurrent()
        let initialMemory = TestPerformanceMetrics.getCurrentMemoryUsage()
        
        var frameCount = 0
        var droppedFrames = 0
        
        await MainActor.run {
            let displayLink = CADisplayLink(target: TestDisplayLinkTarget { frameTime in
                frameCount += 1
                // Consider a frame dropped if it takes more than 16.67ms (60fps threshold)
                if frameTime > 0.01667 {
                    droppedFrames += 1
                }
            }, selector: #selector(TestDisplayLinkTarget.frame(_:)))
            
            displayLink.add(to: .main, forMode: .common)
            
            animation()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                displayLink.invalidate()
            }
        }
        
        // Wait for animation to complete
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let actualDuration = endTime - startTime
        
        return TestPerformanceMetrics.AnimationPerformanceMetrics(
            averageFrameTime: actualDuration / Double(frameCount),
            droppedFrames: droppedFrames,
            totalFrames: frameCount,
            animationDuration: actualDuration
        )
    }
    
    // MARK: - Memory Testing Utilities
    
    /// Measure memory usage during operation
    static func measureMemoryUsage<T>(_ operation: () throws -> T) rethrows -> (result: T, memoryMetrics: TestPerformanceMetrics.MemoryMetrics) {
        let initialMemory = TestPerformanceMetrics.getCurrentMemoryUsage()
        var peakMemory = initialMemory
        
        // Monitor memory during operation
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            let currentMemory = TestPerformanceMetrics.getCurrentMemoryUsage()
            peakMemory = max(peakMemory, currentMemory)
        }
        
        let result = try operation()
        
        timer.invalidate()
        let finalMemory = TestPerformanceMetrics.getCurrentMemoryUsage()
        
        let memoryMetrics = TestPerformanceMetrics.MemoryMetrics(
            initialMemoryUsage: initialMemory,
            peakMemoryUsage: peakMemory,
            finalMemoryUsage: finalMemory
        )
        
        return (result, memoryMetrics)
    }
    
    // MARK: - Error Testing Utilities
    
    /// Generate specific error conditions for testing
    static func generateTestError(_ type: TestErrorType) -> Error {
        switch type {
        case .network:
            return MockNetworkLayer.NetworkError.noConnection
        case .biometric:
            return LAError(.biometryNotAvailable)
        case .timeout:
            return TestTimeoutError()
        case .validation:
            return TestValidationError("Invalid test data")
        case .generic:
            return NSError(domain: "TestDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
    }
    
    // MARK: - State Management Testing
    
    /// Create a test environment with controlled state
    static func createControlledTestEnvironment() -> MockAppStateManager {
        let stateManager = MockAppStateManager()
        stateManager.reset()
        return stateManager
    }
    
    /// Simulate app lifecycle events
    static func simulateAppLifecycleEvent(_ event: AppLifecycleEvent, on stateManager: MockAppStateManager) {
        switch event {
        case .didEnterBackground:
            stateManager.simulateAppDidEnterBackground()
        case .willEnterForeground:
            stateManager.simulateAppWillEnterForeground()
        case .didBecomeActive:
            stateManager.transitionTo(.main)
        case .willResignActive:
            stateManager.transitionTo(.background)
        }
    }
}

// MARK: - Supporting Types

/// Custom error types for testing
enum TestErrorType {
    case network
    case biometric
    case timeout
    case validation
    case generic
}

struct TestTimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "Test operation timed out"
    }
}

struct TestValidationError: Error, LocalizedError {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var errorDescription: String? {
        return message
    }
}

enum AppLifecycleEvent {
    case didEnterBackground
    case willEnterForeground
    case didBecomeActive
    case willResignActive
}

// MARK: - Animation Performance Helper

private class TestDisplayLinkTarget {
    private let frameCallback: (TimeInterval) -> Void
    private var lastFrameTime: CFTimeInterval = 0
    
    init(frameCallback: @escaping (TimeInterval) -> Void) {
        self.frameCallback = frameCallback
    }
    
    @objc func frame(_ displayLink: CADisplayLink) {
        let currentTime = displayLink.timestamp
        if lastFrameTime > 0 {
            let frameTime = currentTime - lastFrameTime
            frameCallback(frameTime)
        }
        lastFrameTime = currentTime
    }
}

// MARK: - Result Extensions for Testing

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
}

// MARK: - XCTestCase Extensions

extension XCTestCase {
    
    /// Wait for condition to be true with timeout
    func waitForCondition(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 1.0,
        description: String = "Condition",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = XCTestExpectation(description: description)
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if condition() {
                expectation.fulfill()
                timer.invalidate()
            }
        }
        
        wait(for: [expectation], timeout: timeout)
        timer.invalidate()
    }
    
    /// Execute test with controlled timing
    func performTimedTest(
        _ operation: @escaping () throws -> Void,
        expectedDuration: TimeInterval,
        tolerance: TimeInterval = 0.1,
        file: StaticString = #file,
        line: UInt = #line
    ) rethrows {
        let (_, executionTime) = TestPerformanceMetrics.measureExecutionTime(operation)
        
        XCTAssertEqual(
            executionTime, expectedDuration, accuracy: tolerance,
            "Operation took \(executionTime)s, expected \(expectedDuration)s ± \(tolerance)s",
            file: file, line: line
        )
    }
    
    /// Assert that async operation completes within time limit
    func assertCompletesWithin<T>(
        _ timeLimit: TimeInterval,
        _ operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows -> T {
        let (result, executionTime) = try await TestPerformanceMetrics.measureAsyncExecutionTime(operation)
        
        XCTAssertLessThanOrEqual(
            executionTime, timeLimit,
            "Async operation took \(executionTime)s, which exceeds limit of \(timeLimit)s",
            file: file, line: line
        )
        
        return result
    }
}
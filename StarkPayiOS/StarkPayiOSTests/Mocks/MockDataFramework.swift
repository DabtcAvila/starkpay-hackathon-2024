import XCTest
import LocalAuthentication
import SwiftUI
import Foundation
@testable import StarkPayiOS

// MARK: - Mock Data Factory

/// A comprehensive mock data factory for generating test data across the StarkPay app
/// Provides consistent, realistic test data for all testing scenarios
class MockDataFactory {
    
    // MARK: - Transaction Mock Data
    
    static let sampleTransactions: [SimpleTransaction] = [
        SimpleTransaction(
            id: "txn_001",
            amount: 25.50,
            otherParty: "alice_crypto",
            isReceived: true,
            date: Date().addingTimeInterval(-3600), // 1 hour ago
            note: "Coffee payment ☕"
        ),
        SimpleTransaction(
            id: "txn_002", 
            amount: 150.00,
            otherParty: "bob_defi",
            isReceived: false,
            date: Date().addingTimeInterval(-7200), // 2 hours ago
            note: "Lunch split 🍕"
        ),
        SimpleTransaction(
            id: "txn_003",
            amount: 75.25,
            otherParty: "sarah_web3",
            isReceived: true,
            date: Date().addingTimeInterval(-86400), // 1 day ago
            note: "Gas money ⛽"
        ),
        SimpleTransaction(
            id: "txn_004",
            amount: 200.00,
            otherParty: "mike_stark",
            isReceived: false,
            date: Date().addingTimeInterval(-172800), // 2 days ago
            note: "Rent contribution 🏠"
        ),
        SimpleTransaction(
            id: "txn_005",
            amount: 12.99,
            otherParty: "crypto_store",
            isReceived: false,
            date: Date().addingTimeInterval(-259200), // 3 days ago
            note: "App subscription 📱"
        )
    ]
    
    static func generateRandomTransaction() -> SimpleTransaction {
        let amounts = [5.00, 12.50, 25.00, 50.00, 75.00, 100.00, 150.00, 200.00]
        let parties = ["alice_crypto", "bob_defi", "sarah_web3", "mike_stark", "crypto_store", "defi_protocol"]
        let notes = ["Coffee ☕", "Lunch 🍕", "Gas money ⛽", "Thanks! 🙏", "Shopping 🛍️", "Transfer 💸"]
        let timeOffsets = [-3600, -7200, -86400, -172800, -259200, -345600] // Various past times
        
        return SimpleTransaction(
            id: "txn_\(UUID().uuidString.prefix(8))",
            amount: amounts.randomElement() ?? 25.00,
            otherParty: parties.randomElement() ?? "test_user",
            isReceived: Bool.random(),
            date: Date().addingTimeInterval(Double(timeOffsets.randomElement() ?? -3600)),
            note: notes.randomElement() ?? "Test payment"
        )
    }
    
    static func generateTransactionBatch(count: Int) -> [SimpleTransaction] {
        return (0..<count).map { _ in generateRandomTransaction() }
    }
    
    // MARK: - Balance Mock Data
    
    static let sampleBalances: [Double] = [
        0.00,      // Empty balance
        1.23,      // Low balance
        150.75,    // Medium balance
        1247.83,   // High balance (default app value)
        10000.00   // Very high balance
    ]
    
    // MARK: - User Profile Mock Data
    
    struct MockUserProfile {
        let username: String
        let email: String
        let displayName: String
        let profileImageName: String
        
        static let samples = [
            MockUserProfile(
                username: "@starkpay_user",
                email: "david@starkpay.com",
                displayName: "David Chen",
                profileImageName: "DC"
            ),
            MockUserProfile(
                username: "@crypto_alice", 
                email: "alice@crypto.com",
                displayName: "Alice Johnson",
                profileImageName: "AJ"
            ),
            MockUserProfile(
                username: "@defi_bob",
                email: "bob@defi.protocol",
                displayName: "Bob Williams",
                profileImageName: "BW"
            )
        ]
    }
    
    // MARK: - Payment Flow Mock Data
    
    struct MockPaymentData {
        let recipient: String
        let amount: Double
        let note: String
        let expectedSuccess: Bool
        
        static let validPayments = [
            MockPaymentData(recipient: "alice_crypto", amount: 25.00, note: "Coffee", expectedSuccess: true),
            MockPaymentData(recipient: "bob_defi", amount: 50.50, note: "Lunch split", expectedSuccess: true),
            MockPaymentData(recipient: "sarah_web3", amount: 100.00, note: "Gas money", expectedSuccess: true)
        ]
        
        static let invalidPayments = [
            MockPaymentData(recipient: "", amount: 25.00, note: "Empty recipient", expectedSuccess: false),
            MockPaymentData(recipient: "alice_crypto", amount: 0.00, note: "Zero amount", expectedSuccess: false),
            MockPaymentData(recipient: "alice_crypto", amount: -10.00, note: "Negative amount", expectedSuccess: false),
            MockPaymentData(recipient: "alice_crypto", amount: 99999.00, note: "Excessive amount", expectedSuccess: false)
        ]
    }
}

// MARK: - Mock Local Authentication Context

/// Mock LAContext for testing biometric authentication without requiring actual hardware
class MockLAContext: LAContext {
    var mockBiometryType: LABiometryType = .faceID
    var mockCanEvaluatePolicy = true
    var mockAuthenticationResult: Result<Bool, Error> = .success(true)
    var mockError: LAError?
    
    // Track method calls for verification
    var evaluatePolicyCalled = false
    var lastEvaluatedPolicy: LAPolicy?
    var lastLocalizedReason: String?
    
    override var biometryType: LABiometryType {
        return mockBiometryType
    }
    
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        if let mockError = mockError {
            error?.pointee = mockError
            return false
        }
        return mockCanEvaluatePolicy
    }
    
    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        evaluatePolicyCalled = true
        lastEvaluatedPolicy = policy
        lastLocalizedReason = localizedReason
        
        // Simulate realistic delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        switch mockAuthenticationResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }
    
    // Helper methods for test setup
    func configureFaceID(available: Bool = true, success: Bool = true) {
        mockBiometryType = .faceID
        mockCanEvaluatePolicy = available
        mockAuthenticationResult = .success(success)
        mockError = nil
    }
    
    func configureTouchID(available: Bool = true, success: Bool = true) {
        mockBiometryType = .touchID
        mockCanEvaluatePolicy = available
        mockAuthenticationResult = .success(success)
        mockError = nil
    }
    
    func configureNoBiometrics() {
        mockBiometryType = .none
        mockCanEvaluatePolicy = false
        mockError = LAError(.biometryNotAvailable)
    }
    
    func configureBiometryLockout() {
        mockBiometryType = .faceID
        mockCanEvaluatePolicy = true
        mockAuthenticationResult = .failure(LAError(.biometryLockout))
    }
    
    func configureUserCancel() {
        mockBiometryType = .faceID
        mockCanEvaluatePolicy = true
        mockAuthenticationResult = .failure(LAError(.userCancel))
    }
    
    func configureAuthenticationFailed() {
        mockBiometryType = .faceID
        mockCanEvaluatePolicy = true
        mockAuthenticationResult = .failure(LAError(.authenticationFailed))
    }
    
    func reset() {
        evaluatePolicyCalled = false
        lastEvaluatedPolicy = nil
        lastLocalizedReason = nil
        mockBiometryType = .faceID
        mockCanEvaluatePolicy = true
        mockAuthenticationResult = .success(true)
        mockError = nil
    }
}

// MARK: - Mock UserDefaults

/// Mock UserDefaults for testing preferences and settings without affecting real user data
class MockUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]
    
    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }
    
    override func bool(forKey defaultName: String) -> Bool {
        return storage[defaultName] as? Bool ?? false
    }
    
    override func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }
    
    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }
    
    func clearAll() {
        storage.removeAll()
    }
    
    func setInitialBiometricState(_ enabled: Bool) {
        set(enabled, forKey: "biometric_enabled")
    }
}

// MARK: - Mock Haptic Feedback Generator

/// Mock haptic feedback for testing without actual device vibration
class MockHapticFeedbackGenerator {
    var lightImpactCalled = false
    var mediumImpactCalled = false
    var heavyImpactCalled = false
    var selectionChangedCalled = false
    var successCalled = false
    var errorCalled = false
    
    var callHistory: [String] = []
    
    func lightImpact() {
        lightImpactCalled = true
        callHistory.append("lightImpact")
    }
    
    func mediumImpact() {
        mediumImpactCalled = true
        callHistory.append("mediumImpact")
    }
    
    func heavyImpact() {
        heavyImpactCalled = true
        callHistory.append("heavyImpact")
    }
    
    func selectionChanged() {
        selectionChangedCalled = true
        callHistory.append("selectionChanged")
    }
    
    func success() {
        successCalled = true
        callHistory.append("success")
    }
    
    func error() {
        errorCalled = true
        callHistory.append("error")
    }
    
    func reset() {
        lightImpactCalled = false
        mediumImpactCalled = false
        heavyImpactCalled = false
        selectionChangedCalled = false
        successCalled = false
        errorCalled = false
        callHistory.removeAll()
    }
    
    func verifyCallSequence(_ expectedSequence: [String]) -> Bool {
        return callHistory == expectedSequence
    }
}

// MARK: - Mock Network Layer

/// Mock network responses for testing payment processing and API calls
class MockNetworkLayer {
    enum NetworkError: Error, LocalizedError {
        case noConnection
        case serverError
        case invalidResponse
        case timeout
        
        var errorDescription: String? {
            switch self {
            case .noConnection: return "No internet connection"
            case .serverError: return "Server error occurred"
            case .invalidResponse: return "Invalid response received"
            case .timeout: return "Request timed out"
            }
        }
    }
    
    var shouldSimulateNetworkDelay = true
    var networkDelay: TimeInterval = 1.0
    var simulateError: NetworkError?
    
    var transactionHistory: [MockDataFactory.MockPaymentData] = []
    
    func processPayment(_ paymentData: MockDataFactory.MockPaymentData) async throws -> Bool {
        if shouldSimulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        }
        
        if let error = simulateError {
            throw error
        }
        
        // Record the transaction
        transactionHistory.append(paymentData)
        
        return paymentData.expectedSuccess
    }
    
    func fetchTransactionHistory() async throws -> [SimpleTransaction] {
        if shouldSimulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        }
        
        if let error = simulateError {
            throw error
        }
        
        return MockDataFactory.sampleTransactions
    }
    
    func reset() {
        simulateError = nil
        transactionHistory.removeAll()
        networkDelay = 1.0
        shouldSimulateNetworkDelay = true
    }
}

// MARK: - Test Performance Metrics

/// Utility for measuring and validating performance metrics in tests
class TestPerformanceMetrics {
    
    struct AnimationPerformanceMetrics {
        let averageFrameTime: TimeInterval
        let droppedFrames: Int
        let totalFrames: Int
        let animationDuration: TimeInterval
        
        var frameRate: Double {
            return Double(totalFrames) / animationDuration
        }
        
        var frameDropPercentage: Double {
            return Double(droppedFrames) / Double(totalFrames) * 100
        }
    }
    
    struct MemoryMetrics {
        let initialMemoryUsage: UInt64
        let peakMemoryUsage: UInt64
        let finalMemoryUsage: UInt64
        
        var memoryGrowth: UInt64 {
            return peakMemoryUsage - initialMemoryUsage
        }
        
        var memoryLeak: UInt64 {
            return finalMemoryUsage > initialMemoryUsage ? finalMemoryUsage - initialMemoryUsage : 0
        }
    }
    
    static func measureExecutionTime<T>(_ operation: () throws -> T) rethrows -> (result: T, executionTime: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        return (result, executionTime)
    }
    
    static func measureAsyncExecutionTime<T>(_ operation: () async throws -> T) async rethrows -> (result: T, executionTime: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        return (result, executionTime)
    }
    
    static func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        return 0
    }
}

// MARK: - Mock App State Manager

/// Mock application state management for testing app lifecycle and state transitions
class MockAppStateManager: ObservableObject {
    @Published var appState: AppState = .splash
    @Published var isAuthenticated = false
    @Published var shouldShowAuth = false
    
    enum AppState {
        case splash
        case authentication
        case main
        case background
    }
    
    var stateTransitions: [AppState] = []
    
    func transitionTo(_ state: AppState) {
        stateTransitions.append(state)
        appState = state
    }
    
    func simulateAppDidEnterBackground() {
        transitionTo(.background)
        isAuthenticated = false
        shouldShowAuth = true
    }
    
    func simulateAppWillEnterForeground() {
        if appState == .background {
            shouldShowAuth = true
        }
    }
    
    func reset() {
        appState = .splash
        isAuthenticated = false
        shouldShowAuth = false
        stateTransitions.removeAll()
    }
}

// MARK: - Test Data Validation Helpers

extension XCTestCase {
    
    /// Verify that a transaction contains valid data
    func assertValidTransaction(_ transaction: SimpleTransaction) {
        XCTAssertFalse(transaction.id.isEmpty, "Transaction ID should not be empty")
        XCTAssertGreaterThan(transaction.amount, 0, "Transaction amount should be positive")
        XCTAssertFalse(transaction.otherParty.isEmpty, "Other party should not be empty")
        XCTAssertLessThanOrEqual(transaction.date, Date(), "Transaction date should not be in the future")
    }
    
    /// Verify that a payment data structure is valid
    func assertValidPaymentData(_ payment: MockDataFactory.MockPaymentData) {
        if payment.expectedSuccess {
            XCTAssertFalse(payment.recipient.isEmpty, "Valid payment should have recipient")
            XCTAssertGreaterThan(payment.amount, 0, "Valid payment should have positive amount")
        }
    }
    
    /// Assert that haptic feedback was called in the expected sequence
    func assertHapticSequence(_ mockHaptic: MockHapticFeedbackGenerator, expectedSequence: [String]) {
        XCTAssertTrue(mockHaptic.verifyCallSequence(expectedSequence), 
                     "Haptic feedback sequence mismatch. Expected: \(expectedSequence), Got: \(mockHaptic.callHistory)")
    }
    
    /// Assert performance metrics meet acceptable thresholds
    func assertPerformanceWithin(_ executionTime: TimeInterval, threshold: TimeInterval, operation: String) {
        XCTAssertLessThanOrEqual(executionTime, threshold, 
                                "\(operation) took \(executionTime)s, which exceeds threshold of \(threshold)s")
    }
}
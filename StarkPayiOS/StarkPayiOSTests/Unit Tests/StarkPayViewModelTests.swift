import XCTest
import Combine
@testable import StarkPayiOS

/// Comprehensive unit tests for StarkPayViewModel
/// Tests all business logic, state management, transaction handling, and edge cases
@MainActor
final class StarkPayViewModelTests: XCTestCase {
    
    private var sut: StarkPayViewModel!
    private var mockNetworkLayer: MockNetworkLayer!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        TestHelpers.configureTestEnvironment()
        
        mockNetworkLayer = MockNetworkLayer()
        cancellables = Set<AnyCancellable>()
        
        sut = StarkPayViewModel()
    }
    
    override func tearDownWithError() throws {
        cancellables?.removeAll()
        sut = nil
        mockNetworkLayer = nil
        TestHelpers.resetTestEnvironment()
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(sut.balance, 1247.83, "Should have default balance")
        XCTAssertTrue(sut.transactions.isEmpty, "Should start with empty transactions")
        XCTAssertTrue(sut.isConnected, "Should default to connected state")
        XCTAssertEqual(sut.paymentState, .idle, "Should start in idle payment state")
        XCTAssertFalse(sut.isLoadingTransactions, "Should not be loading transactions initially")
    }
    
    func testMockDataSetup() {
        // After init() completes, mock data should be loaded
        XCTAssertFalse(sut.transactions.isEmpty, "Should have mock transactions after setup")
        XCTAssertEqual(sut.transactions.count, 3, "Should have 3 initial mock transactions")
        
        // Verify mock data integrity
        let issues = TestHelpers.validateTransactionIntegrity(sut.transactions)
        XCTAssertTrue(issues.isEmpty, "Mock transactions should be valid: \(issues.joined(separator: ", "))")
    }
    
    // MARK: - Balance Management Tests
    
    func testBalanceIsPublished() {
        var balanceChanges: [Double] = []
        
        sut.$balance
            .sink { balance in
                balanceChanges.append(balance)
            }
            .store(in: &cancellables)
        
        let newBalance = 2000.50
        sut.balance = newBalance
        
        XCTAssertEqual(sut.balance, newBalance)
        XCTAssertTrue(balanceChanges.contains(newBalance), "Balance change should be published")
    }
    
    func testBalanceValidation() {
        let testCases: [Double] = [0.0, 0.01, 999.99, 10000.00, 999999.99]
        
        for testBalance in testCases {
            sut.balance = testBalance
            XCTAssertEqual(sut.balance, testBalance, "Should accept valid balance: \(testBalance)")
        }
    }
    
    // MARK: - Transaction Management Tests
    
    func testTransactionArrayIsPublished() {
        var transactionUpdates = 0
        
        sut.$transactions
            .sink { _ in
                transactionUpdates += 1
            }
            .store(in: &cancellables)
        
        let initialUpdateCount = transactionUpdates
        
        let newTransaction = MockDataFactory.generateRandomTransaction()
        sut.transactions.append(newTransaction)
        
        XCTAssertGreaterThan(transactionUpdates, initialUpdateCount, "Transaction updates should be published")
    }
    
    func testTransactionSortingByDate() {
        let transactions = TestHelpers.generateTestTransactions(count: 5)
        sut.transactions = transactions
        
        // Verify transactions are in chronological order (newest first)
        for i in 0..<(sut.transactions.count - 1) {
            XCTAssertGreaterThanOrEqual(
                sut.transactions[i].date,
                sut.transactions[i + 1].date,
                "Transactions should be sorted by date (newest first)"
            )
        }
    }
    
    // MARK: - Send Payment Tests
    
    func testSendPaymentSuccess() {
        let initialBalance = sut.balance
        let initialTransactionCount = sut.transactions.count
        
        let recipient = "test_recipient"
        let amount = 50.0
        let note = "Test payment"
        
        sut.sendPayment(to: recipient, amount: amount, note: note)
        
        // Verify balance deduction
        XCTAssertEqual(sut.balance, initialBalance - amount, "Balance should be reduced by payment amount")
        
        // Verify transaction added
        XCTAssertEqual(sut.transactions.count, initialTransactionCount + 1, "Should add new transaction")
        
        // Verify transaction details
        let newTransaction = sut.transactions.first!
        XCTAssertEqual(newTransaction.amount, amount, "Transaction should have correct amount")
        XCTAssertEqual(newTransaction.otherParty, recipient, "Transaction should have correct recipient")
        XCTAssertFalse(newTransaction.isReceived, "Sent payment should be marked as not received")
        XCTAssertEqual(newTransaction.note, note, "Transaction should have correct note")
        XCTAssertFalse(newTransaction.id.isEmpty, "Transaction should have valid ID")
    }
    
    func testSendPaymentWithZeroAmount() {
        let initialBalance = sut.balance
        let initialTransactionCount = sut.transactions.count
        
        sut.sendPayment(to: "recipient", amount: 0.0, note: "Zero payment")
        
        // Should still process (business logic decision)
        XCTAssertEqual(sut.balance, initialBalance, "Balance should not change with zero amount")
        XCTAssertEqual(sut.transactions.count, initialTransactionCount + 1, "Should still add transaction record")
    }
    
    func testSendPaymentExceedsBalance() {
        let excessiveAmount = sut.balance + 1000.0
        let initialBalance = sut.balance
        let initialTransactionCount = sut.transactions.count
        
        sut.sendPayment(to: "recipient", amount: excessiveAmount, note: "Excessive payment")
        
        // Should still process (overdraft scenario)
        XCTAssertEqual(sut.balance, initialBalance - excessiveAmount, "Should allow overdraft")
        XCTAssertEqual(sut.transactions.count, initialTransactionCount + 1, "Should add transaction")
        XCTAssertLessThan(sut.balance, 0, "Balance should be negative after overdraft")
    }
    
    func testSendPaymentWithEmptyRecipient() {
        let initialBalance = sut.balance
        let initialTransactionCount = sut.transactions.count
        
        sut.sendPayment(to: "", amount: 25.0, note: "Empty recipient")
        
        // Should handle gracefully
        XCTAssertEqual(sut.balance, initialBalance - 25.0, "Should process payment despite empty recipient")
        XCTAssertEqual(sut.transactions.count, initialTransactionCount + 1, "Should add transaction")
        
        let newTransaction = sut.transactions.first!
        XCTAssertTrue(newTransaction.otherParty.isEmpty, "Should preserve empty recipient")
    }
    
    func testMultipleConcurrentPayments() {
        let initialBalance = sut.balance
        let paymentAmount = 10.0
        let numberOfPayments = 5
        
        // Send multiple payments
        for i in 0..<numberOfPayments {
            sut.sendPayment(to: "recipient_\(i)", amount: paymentAmount, note: "Payment \(i)")
        }
        
        let expectedBalance = initialBalance - (paymentAmount * Double(numberOfPayments))
        XCTAssertEqual(sut.balance, expectedBalance, accuracy: 0.01, "Should handle multiple payments correctly")
        
        // Verify all transactions were added
        let sentTransactions = sut.transactions.filter { !$0.isReceived }
        XCTAssertGreaterThanOrEqual(sentTransactions.count, numberOfPayments, "Should have all sent transactions")
    }
    
    // MARK: - Refresh Transactions Tests
    
    func testRefreshTransactionsLoading() async {
        XCTAssertFalse(sut.isLoadingTransactions, "Should not be loading initially")
        
        let loadingExpectation = expectation(description: "Loading state changes")
        var loadingStates: [Bool] = []
        
        sut.$isLoadingTransactions
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 3 { // Initial false, true during loading, false after
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.refreshTransactions()
        
        await fulfillment(of: [loadingExpectation], timeout: 3.0)
        
        XCTAssertFalse(sut.isLoadingTransactions, "Should not be loading after refresh")
        XCTAssertTrue(loadingStates.contains(true), "Should have been loading during refresh")
    }
    
    func testRefreshTransactionsAddsNewTransaction() async {
        let initialCount = sut.transactions.count
        
        await sut.refreshTransactions()
        
        XCTAssertEqual(sut.transactions.count, initialCount + 1, "Should add one new transaction")
        
        // Verify the new transaction is at the beginning (most recent)
        let newestTransaction = sut.transactions.first!
        XCTAssertGreaterThanOrEqual(newestTransaction.date, Date().addingTimeInterval(-2), 
                                   "Newest transaction should have recent date")
    }
    
    func testRefreshTransactionsPerformance() async {
        let (_, executionTime) = await TestPerformanceMetrics.measureAsyncExecutionTime {
            await sut.refreshTransactions()
        }
        
        // Refresh should complete within reasonable time (including simulated network delay)
        XCTAssertLessThan(executionTime, 3.0, "Refresh should complete within 3 seconds")
    }
    
    func testMultipleSimultaneousRefreshRequests() async {
        let task1 = Task { await sut.refreshTransactions() }
        let task2 = Task { await sut.refreshTransactions() }
        let task3 = Task { await sut.refreshTransactions() }
        
        await task1.value
        await task2.value
        await task3.value
        
        // Should handle concurrent requests gracefully without crashes
        XCTAssertFalse(sut.isLoadingTransactions, "Should not be stuck in loading state")
    }
    
    // MARK: - Payment State Management Tests
    
    func testPaymentStateTransitions() {
        var stateChanges: [LoadingState] = []
        
        sut.$paymentState
            .sink { state in
                stateChanges.append(state)
            }
            .store(in: &cancellables)
        
        sut.paymentState = .loading
        XCTAssertEqual(sut.paymentState, .loading)
        
        sut.paymentState = .success
        XCTAssertEqual(sut.paymentState, .success)
        
        sut.paymentState = .error("Test error")
        if case .error(let message) = sut.paymentState {
            XCTAssertEqual(message, "Test error")
        } else {
            XCTFail("Payment state should be error")
        }
        
        sut.paymentState = .idle
        XCTAssertEqual(sut.paymentState, .idle)
        
        XCTAssertTrue(stateChanges.contains(.loading), "Should have recorded loading state")
        XCTAssertTrue(stateChanges.contains(.success), "Should have recorded success state")
    }
    
    // MARK: - Connection State Tests
    
    func testConnectionStateToggle() {
        XCTAssertTrue(sut.isConnected, "Should start connected")
        
        var connectionStates: [Bool] = []
        sut.$isConnected
            .sink { isConnected in
                connectionStates.append(isConnected)
            }
            .store(in: &cancellables)
        
        sut.isConnected = false
        XCTAssertFalse(sut.isConnected, "Should be able to disconnect")
        
        sut.isConnected = true
        XCTAssertTrue(sut.isConnected, "Should be able to reconnect")
        
        XCTAssertTrue(connectionStates.contains(false), "Should record disconnected state")
        XCTAssertTrue(connectionStates.contains(true), "Should record connected state")
    }
    
    // MARK: - Data Validation Tests
    
    func testTransactionDataValidation() {
        let validTransactions = MockDataFactory.sampleTransactions
        sut.transactions = validTransactions
        
        for transaction in sut.transactions {
            assertValidTransaction(transaction)
        }
    }
    
    func testTransactionUniqueIDs() {
        // Add multiple transactions and verify unique IDs
        for i in 0..<10 {
            sut.sendPayment(to: "recipient_\(i)", amount: Double(i + 1), note: "Test \(i)")
        }
        
        let transactionIDs = sut.transactions.map { $0.id }
        let uniqueIDs = Set(transactionIDs)
        
        XCTAssertEqual(transactionIDs.count, uniqueIDs.count, "All transaction IDs should be unique")
    }
    
    // MARK: - Edge Cases Tests
    
    func testTransactionWithExtremeAmounts() {
        let testCases: [Double] = [0.01, 0.001, 999999.99, 1000000.00]
        
        for amount in testCases {
            let initialCount = sut.transactions.count
            sut.sendPayment(to: "test", amount: amount, note: "Extreme amount test")
            
            XCTAssertEqual(sut.transactions.count, initialCount + 1, "Should handle extreme amount: \(amount)")
            XCTAssertEqual(sut.transactions.first!.amount, amount, "Should preserve exact amount")
        }
    }
    
    func testTransactionWithSpecialCharacters() {
        let specialRecipient = "recipient@#$%^&*()[]{}|\\:;\"'<>?,./"
        let specialNote = "Note with émojis 🚀💰 and spëcîál chars åñd ñümbérs 123"
        
        sut.sendPayment(to: specialRecipient, amount: 25.0, note: specialNote)
        
        let transaction = sut.transactions.first!
        XCTAssertEqual(transaction.otherParty, specialRecipient, "Should handle special characters in recipient")
        XCTAssertEqual(transaction.note, specialNote, "Should handle special characters and emojis in note")
    }
    
    func testTransactionWithVeryLongStrings() {
        let longRecipient = String(repeating: "a", count: 1000)
        let longNote = String(repeating: "This is a very long note. ", count: 100)
        
        sut.sendPayment(to: longRecipient, amount: 50.0, note: longNote)
        
        let transaction = sut.transactions.first!
        XCTAssertEqual(transaction.otherParty, longRecipient, "Should handle very long recipient names")
        XCTAssertEqual(transaction.note, longNote, "Should handle very long notes")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryUsageWithManyTransactions() {
        let initialMemory = TestPerformanceMetrics.getCurrentMemoryUsage()
        
        // Add many transactions
        for i in 0..<1000 {
            sut.sendPayment(to: "recipient_\(i)", amount: Double(i), note: "Transaction \(i)")
        }
        
        let afterTransactionsMemory = TestPerformanceMetrics.getCurrentMemoryUsage()
        let memoryGrowth = afterTransactionsMemory - initialMemory
        
        // Memory growth should be reasonable (allow 10MB for 1000 transactions)
        XCTAssertLessThan(memoryGrowth, 10_000_000, "Memory growth should be reasonable for many transactions")
    }
    
    func testNoMemoryLeaksInObservableObject() {
        weak var weakSUT: StarkPayViewModel?
        
        autoreleasepool {
            let tempSUT = StarkPayViewModel()
            weakSUT = tempSUT
            
            // Perform operations that might create retain cycles
            tempSUT.sendPayment(to: "test", amount: 100, note: "test")
            
            // Subscribe and unsubscribe
            let cancellable = tempSUT.$balance.sink { _ in }
            cancellable.cancel()
        }
        
        // Force deallocation
        for _ in 0..<3 {
            autoreleasepool { }
        }
        
        XCTAssertNil(weakSUT, "StarkPayViewModel should be deallocated")
    }
    
    // MARK: - Performance Tests
    
    func testSendPaymentPerformance() {
        measure {
            for i in 0..<100 {
                sut.sendPayment(to: "recipient_\(i)", amount: Double(i), note: "Performance test")
            }
        }
    }
    
    func testTransactionFilteringPerformance() {
        // Add many transactions first
        for i in 0..<1000 {
            sut.sendPayment(to: "recipient_\(i % 10)", amount: Double(i), note: "Transaction \(i)")
        }
        
        measure {
            let sentTransactions = sut.transactions.filter { !$0.isReceived }
            let receivedTransactions = sut.transactions.filter { $0.isReceived }
            let _ = sentTransactions.count + receivedTransactions.count
        }
    }
    
    // MARK: - State Consistency Tests
    
    func testStateConsistencyAfterOperations() {
        let initialBalance = sut.balance
        let payments = MockDataFactory.MockPaymentData.validPayments
        
        var totalSent = 0.0
        for payment in payments {
            sut.sendPayment(to: payment.recipient, amount: payment.amount, note: payment.note)
            totalSent += payment.amount
        }
        
        // Verify balance consistency
        XCTAssertEqual(sut.balance, initialBalance - totalSent, accuracy: 0.01, 
                      "Balance should be consistent after multiple payments")
        
        // Verify transaction count
        let sentTransactions = sut.transactions.filter { !$0.isReceived }
        XCTAssertGreaterThanOrEqual(sentTransactions.count, payments.count, 
                                   "Should have at least as many sent transactions as payments made")
    }
    
    func testStateConsistencyDuringRefresh() async {
        let initialBalance = sut.balance
        
        // Send payment during refresh
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            sut.sendPayment(to: "test", amount: 100, note: "Concurrent payment")
        }
        
        await sut.refreshTransactions()
        
        // State should be consistent
        XCTAssertEqual(sut.balance, initialBalance - 100, "Balance should reflect payment during refresh")
        XCTAssertFalse(sut.isLoadingTransactions, "Should not be stuck in loading state")
    }
    
    // MARK: - Integration Tests
    
    func testFullPaymentWorkflow() {
        let recipient = "alice_crypto"
        let amount = 150.75
        let note = "Integration test payment"
        let initialBalance = sut.balance
        let initialTransactionCount = sut.transactions.count
        
        // Send payment
        sut.sendPayment(to: recipient, amount: amount, note: note)
        
        // Verify all aspects of the payment
        XCTAssertEqual(sut.balance, initialBalance - amount, "Balance updated correctly")
        XCTAssertEqual(sut.transactions.count, initialTransactionCount + 1, "Transaction added")
        
        let transaction = sut.transactions.first!
        XCTAssertEqual(transaction.amount, amount, "Correct amount")
        XCTAssertEqual(transaction.otherParty, recipient, "Correct recipient")
        XCTAssertEqual(transaction.note, note, "Correct note")
        XCTAssertFalse(transaction.isReceived, "Marked as sent")
        XCTAssertFalse(transaction.id.isEmpty, "Has valid ID")
        
        // Verify date is recent
        let timeDifference = abs(transaction.date.timeIntervalSinceNow)
        XCTAssertLessThan(timeDifference, 1.0, "Transaction should have recent timestamp")
    }
}
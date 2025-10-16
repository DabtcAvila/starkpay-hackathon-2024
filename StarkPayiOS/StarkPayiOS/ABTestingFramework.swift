import Foundation
import SwiftUI

// MARK: - A/B Testing Framework for StarkPay

/// A/B Test Configuration
struct ABTestConfig: Codable {
    let testId: String
    let testName: String
    let isActive: Bool
    let startDate: Date
    let endDate: Date?
    let variants: [ABTestVariant]
    let targetMetric: String
    let description: String
    let hypothesis: String
    
    var isRunning: Bool {
        guard isActive else { return false }
        let now = Date()
        if let endDate = endDate {
            return now >= startDate && now <= endDate
        }
        return now >= startDate
    }
}

/// A/B Test Variant
struct ABTestVariant: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let trafficAllocation: Double // 0.0 to 1.0
    let configuration: [String: ABTestValue]
}

/// A/B Test Value (supports different data types)
enum ABTestValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case color(String) // Hex color code
    
    var stringValue: String {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(value)
        case .bool(let value): return String(value)
        case .color(let value): return value
        }
    }
    
    var colorValue: Color {
        switch self {
        case .color(let hex): return Color(hex: hex) ?? .black
        default: return .black
        }
    }
}

/// A/B Test Event for tracking user interactions
struct ABTestEvent: Codable {
    let id: String
    let testId: String
    let variantId: String
    let userId: String
    let eventType: ABTestEventType
    let eventName: String
    let timestamp: Date
    let properties: [String: String]
    let sessionId: String
}

/// A/B Test Event Types
enum ABTestEventType: String, Codable, CaseIterable {
    case impression = "impression"
    case click = "click"
    case conversion = "conversion"
    case engagement = "engagement"
    case error = "error"
}

/// A/B Test Assignment
struct ABTestAssignment: Codable {
    let userId: String
    let testId: String
    let variantId: String
    let assignedAt: Date
    let sessionId: String
}

/// A/B Test Results
struct ABTestResults: Codable {
    let testId: String
    let generatedAt: Date
    let totalParticipants: Int
    let variantResults: [VariantResults]
    let statisticalSignificance: StatisticalSignificance?
    let winner: String?
    let confidenceLevel: Double
}

struct VariantResults: Codable {
    let variantId: String
    let variantName: String
    let participants: Int
    let impressions: Int
    let clicks: Int
    let conversions: Int
    let conversionRate: Double
    let clickThroughRate: Double
    let averageEngagementTime: Double
    let errorRate: Double
}

struct StatisticalSignificance: Codable {
    let isSignificant: Bool
    let pValue: Double
    let confidenceInterval: (lower: Double, upper: Double)
    let sampleSize: Int
    let effect: String // "positive", "negative", "neutral"
}

// MARK: - A/B Testing Manager

@MainActor
class ABTestingManager: ObservableObject {
    static let shared = ABTestingManager()
    
    @Published var activeTests: [ABTestConfig] = []
    @Published var userAssignments: [String: ABTestAssignment] = [:]
    @Published var collectedEvents: [ABTestEvent] = []
    
    private let userDefaults = UserDefaults.standard
    private let testsKey = "ab_tests"
    private let assignmentsKey = "ab_assignments"
    private let eventsKey = "ab_events"
    private let sessionId = UUID().uuidString
    
    init() {
        loadStoredData()
        setupDefaultTests()
    }
    
    // MARK: - Test Configuration
    
    func getVariantForTest(_ testId: String, userId: String) -> ABTestVariant? {
        guard let test = activeTests.first(where: { $0.testId == testId && $0.isRunning }) else {
            return nil
        }
        
        // Check if user is already assigned
        if let assignment = userAssignments["\(testId)_\(userId)"] {
            return test.variants.first(where: { $0.id == assignment.variantId })
        }
        
        // Assign user to a variant
        return assignUserToVariant(test: test, userId: userId)
    }
    
    private func assignUserToVariant(test: ABTestConfig, userId: String) -> ABTestVariant? {
        // Use deterministic hash for consistent assignment
        let hash = hashUserForTest(userId: userId, testId: test.testId)
        var cumulativeAllocation = 0.0
        
        for variant in test.variants {
            cumulativeAllocation += variant.trafficAllocation
            if hash <= cumulativeAllocation {
                let assignment = ABTestAssignment(
                    userId: userId,
                    testId: test.testId,
                    variantId: variant.id,
                    assignedAt: Date(),
                    sessionId: sessionId
                )
                userAssignments["\(test.testId)_\(userId)"] = assignment
                saveAssignments()
                
                // Track assignment as impression
                trackEvent(
                    testId: test.testId,
                    variantId: variant.id,
                    userId: userId,
                    eventType: .impression,
                    eventName: "variant_assigned",
                    properties: ["variant_name": variant.name]
                )
                
                return variant
            }
        }
        
        return test.variants.first // Fallback to first variant
    }
    
    private func hashUserForTest(userId: String, testId: String) -> Double {
        let combined = "\(userId)_\(testId)"
        let hash = combined.hashValue
        let normalizedHash = abs(hash) % 10000
        return Double(normalizedHash) / 10000.0
    }
    
    // MARK: - Event Tracking
    
    func trackEvent(
        testId: String,
        variantId: String,
        userId: String,
        eventType: ABTestEventType,
        eventName: String,
        properties: [String: String] = [:]
    ) {
        let event = ABTestEvent(
            id: UUID().uuidString,
            testId: testId,
            variantId: variantId,
            userId: userId,
            eventType: eventType,
            eventName: eventName,
            timestamp: Date(),
            properties: properties,
            sessionId: sessionId
        )
        
        collectedEvents.append(event)
        saveEvents()
        
        // Trigger haptic feedback for conversion events
        if eventType == .conversion {
            HapticManager.shared.success()
        }
    }
    
    // MARK: - Results Analysis
    
    func getTestResults(testId: String) -> ABTestResults? {
        guard let test = activeTests.first(where: { $0.testId == testId }) else {
            return nil
        }
        
        let testEvents = collectedEvents.filter { $0.testId == testId }
        let assignments = userAssignments.values.filter { $0.testId == testId }
        
        var variantResults: [VariantResults] = []
        
        for variant in test.variants {
            let variantEvents = testEvents.filter { $0.variantId == variant.id }
            let variantAssignments = assignments.filter { $0.variantId == variant.id }
            
            let impressions = variantEvents.filter { $0.eventType == .impression }.count
            let clicks = variantEvents.filter { $0.eventType == .click }.count
            let conversions = variantEvents.filter { $0.eventType == .conversion }.count
            let errors = variantEvents.filter { $0.eventType == .error }.count
            
            let conversionRate = impressions > 0 ? Double(conversions) / Double(impressions) : 0.0
            let clickThroughRate = impressions > 0 ? Double(clicks) / Double(impressions) : 0.0
            let errorRate = impressions > 0 ? Double(errors) / Double(impressions) : 0.0
            
            // Calculate average engagement time
            let engagementEvents = variantEvents.filter { $0.eventType == .engagement }
            let averageEngagementTime = calculateAverageEngagementTime(events: engagementEvents)
            
            variantResults.append(VariantResults(
                variantId: variant.id,
                variantName: variant.name,
                participants: variantAssignments.count,
                impressions: impressions,
                clicks: clicks,
                conversions: conversions,
                conversionRate: conversionRate,
                clickThroughRate: clickThroughRate,
                averageEngagementTime: averageEngagementTime,
                errorRate: errorRate
            ))
        }
        
        let totalParticipants = assignments.count
        let significance = calculateStatisticalSignificance(results: variantResults)
        let winner = determineWinner(results: variantResults, significance: significance)
        
        return ABTestResults(
            testId: testId,
            generatedAt: Date(),
            totalParticipants: totalParticipants,
            variantResults: variantResults,
            statisticalSignificance: significance,
            winner: winner,
            confidenceLevel: 0.95
        )
    }
    
    private func calculateAverageEngagementTime(events: [ABTestEvent]) -> Double {
        let engagementTimes = events.compactMap { event -> Double? in
            if let timeString = event.properties["duration"],
               let time = Double(timeString) {
                return time
            }
            return nil
        }
        
        guard !engagementTimes.isEmpty else { return 0.0 }
        return engagementTimes.reduce(0, +) / Double(engagementTimes.count)
    }
    
    private func calculateStatisticalSignificance(results: [VariantResults]) -> StatisticalSignificance? {
        guard results.count == 2 else { return nil }
        
        let controlVariant = results[0]
        let testVariant = results[1]
        
        // Simple statistical significance calculation using Z-test for proportions
        let p1 = controlVariant.conversionRate
        let n1 = Double(controlVariant.participants)
        let p2 = testVariant.conversionRate
        let n2 = Double(testVariant.participants)
        
        guard n1 > 30 && n2 > 30 else {
            return StatisticalSignificance(
                isSignificant: false,
                pValue: 1.0,
                confidenceInterval: (0.0, 0.0),
                sampleSize: Int(n1 + n2),
                effect: "insufficient_data"
            )
        }
        
        let pooledProportion = (p1 * n1 + p2 * n2) / (n1 + n2)
        let standardError = sqrt(pooledProportion * (1 - pooledProportion) * (1/n1 + 1/n2))
        let zScore = abs(p2 - p1) / standardError
        
        // Approximate p-value calculation
        let pValue = 2 * (1 - normalCDF(abs(zScore)))
        let isSignificant = pValue < 0.05
        
        let confidenceInterval = calculateConfidenceInterval(p1: p1, p2: p2, n1: n1, n2: n2)
        let effect = p2 > p1 ? "positive" : (p2 < p1 ? "negative" : "neutral")
        
        return StatisticalSignificance(
            isSignificant: isSignificant,
            pValue: pValue,
            confidenceInterval: confidenceInterval,
            sampleSize: Int(n1 + n2),
            effect: effect
        )
    }
    
    private func normalCDF(_ z: Double) -> Double {
        return 0.5 * (1.0 + erf(z / sqrt(2.0)))
    }
    
    private func calculateConfidenceInterval(p1: Double, p2: Double, n1: Double, n2: Double) -> (Double, Double) {
        let diff = p2 - p1
        let se = sqrt((p1 * (1 - p1) / n1) + (p2 * (1 - p2) / n2))
        let marginOfError = 1.96 * se // 95% confidence interval
        
        return (diff - marginOfError, diff + marginOfError)
    }
    
    private func determineWinner(results: [VariantResults], significance: StatisticalSignificance?) -> String? {
        guard let significance = significance, significance.isSignificant else {
            return nil
        }
        
        let bestResult = results.max(by: { $0.conversionRate < $1.conversionRate })
        return bestResult?.variantId
    }
    
    // MARK: - Data Persistence
    
    private func loadStoredData() {
        if let testsData = userDefaults.data(forKey: testsKey),
           let tests = try? JSONDecoder().decode([ABTestConfig].self, from: testsData) {
            activeTests = tests
        }
        
        if let assignmentsData = userDefaults.data(forKey: assignmentsKey),
           let assignments = try? JSONDecoder().decode([String: ABTestAssignment].self, from: assignmentsData) {
            userAssignments = assignments
        }
        
        if let eventsData = userDefaults.data(forKey: eventsKey),
           let events = try? JSONDecoder().decode([ABTestEvent].self, from: eventsData) {
            collectedEvents = events
        }
    }
    
    private func saveTests() {
        if let data = try? JSONEncoder().encode(activeTests) {
            userDefaults.set(data, forKey: testsKey)
        }
    }
    
    private func saveAssignments() {
        if let data = try? JSONEncoder().encode(userAssignments) {
            userDefaults.set(data, forKey: assignmentsKey)
        }
    }
    
    private func saveEvents() {
        if let data = try? JSONEncoder().encode(collectedEvents) {
            userDefaults.set(data, forKey: eventsKey)
        }
    }
    
    // MARK: - Test Setup
    
    private func setupDefaultTests() {
        guard activeTests.isEmpty else { return }
        
        // Payment Button A/B Test
        let paymentButtonTest = ABTestConfig(
            testId: "payment_button_design_v1",
            testName: "Payment Button Design Optimization",
            isActive: true,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            variants: [
                ABTestVariant(
                    id: "control",
                    name: "Control (Current Design)",
                    description: "Current black gradient payment button with standard text",
                    trafficAllocation: 0.5,
                    configuration: [
                        "button_color": .color("#000000"),
                        "button_style": .string("gradient"),
                        "button_text": .string("Pay $AMOUNT"),
                        "button_size": .string("standard"),
                        "animation_enabled": .bool(true),
                        "shadow_enabled": .bool(true)
                    ]
                ),
                ABTestVariant(
                    id: "variant_a",
                    name: "Orange CTA Button",
                    description: "Bright orange button with enhanced call-to-action text",
                    trafficAllocation: 0.5,
                    configuration: [
                        "button_color": .color("#FF8C00"),
                        "button_style": .string("solid"),
                        "button_text": .string("Send $AMOUNT Now"),
                        "button_size": .string("large"),
                        "animation_enabled": .bool(true),
                        "shadow_enabled": .bool(true)
                    ]
                )
            ],
            targetMetric: "conversion_rate",
            description: "Testing payment button design variations to optimize conversion rates and user engagement in the payment flow.",
            hypothesis: "An orange call-to-action button with more direct language will increase payment completion rates by reducing hesitation and improving visual prominence."
        )
        
        activeTests = [paymentButtonTest]
        saveTests()
    }
    
    // MARK: - Helper Methods
    
    func resetTestData() {
        collectedEvents.removeAll()
        userAssignments.removeAll()
        saveEvents()
        saveAssignments()
    }
    
    func exportTestData() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let exportData = [
            "tests": activeTests,
            "assignments": Array(userAssignments.values),
            "events": collectedEvents
        ] as [String : Any]
        
        do {
            let testsData = try encoder.encode(activeTests)
            let assignmentsData = try encoder.encode(Array(userAssignments.values))
            let eventsData = try encoder.encode(collectedEvents)
            
            let testsString = String(data: testsData, encoding: .utf8) ?? "[]"
            let assignmentsString = String(data: assignmentsData, encoding: .utf8) ?? "[]"
            let eventsString = String(data: eventsData, encoding: .utf8) ?? "[]"
            
            return """
{
  "export_date": "\(ISO8601DateFormatter().string(from: Date()))",
  "tests": \(testsString),
  "assignments": \(assignmentsString),
  "events": \(eventsString)
}
"""
        } catch {
            return "Export failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
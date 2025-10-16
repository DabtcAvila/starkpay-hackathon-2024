import Foundation
import SwiftUI

// MARK: - A/B Test Simulation for Demo Users

struct ABTestSimulation {
    static let shared = ABTestSimulation()
    private let abTesting = ABTestingManager.shared
    private let testId = "payment_button_design_v1"
    
    private init() {}
    
    /// Simulates A/B test interactions for all demo users
    func simulateTestWithDemoUsers() {
        print("🧪 Starting A/B Test Simulation with Demo Users")
        
        let demoUsers = DemoUsers.createDemoUsers()
        var simulationResults: [String: ABTestSimulationResult] = [:]
        
        // Simulate user interactions over time
        for (index, user) in demoUsers.enumerated() {
            let result = simulateUserJourney(user: user, dayOffset: Double(index))
            simulationResults[user.id] = result
        }
        
        // Generate and print results
        let finalResults = abTesting.getTestResults(testId)
        printSimulationSummary(simulationResults, finalResults: finalResults)
        
        print("✅ A/B Test Simulation Complete")
    }
    
    /// Simulates a complete user journey for one user
    private func simulateUserJourney(user: UserProfile, dayOffset: Double) -> ABTestSimulationResult {
        let userId = user.id
        let baseTime = Date().addingTimeInterval(-dayOffset * 86400) // Spread over days
        
        // Get user's assigned variant
        guard let variant = abTesting.getVariantForTest(testId, userId: userId) else {
            return ABTestSimulationResult(userId: userId, variant: "none", interactions: [])
        }
        
        print("👤 Simulating journey for \(user.firstName) \(user.lastName) - Variant: \(variant.name)")
        
        var interactions: [ABTestInteraction] = []
        
        // Simulate multiple payment sessions based on user characteristics
        let sessionCount = determineSessionCount(for: user)
        
        for sessionIndex in 0..<sessionCount {
            let sessionTime = baseTime.addingTimeInterval(Double(sessionIndex) * 3600) // 1 hour apart
            let sessionResult = simulatePaymentSession(
                userId: userId,
                variant: variant,
                sessionTime: sessionTime,
                user: user
            )
            interactions.append(contentsOf: sessionResult)
        }
        
        return ABTestSimulationResult(
            userId: userId,
            variant: variant.name,
            interactions: interactions
        )
    }
    
    /// Determines number of payment sessions based on user profile
    private func determineSessionCount(for user: UserProfile) -> Int {
        switch user.totalTransactions {
        case 40...:
            return Int.random(in: 8...12) // Power user - many sessions
        case 20..<40:
            return Int.random(in: 5...8)  // Regular user
        case 10..<20:
            return Int.random(in: 3...6)  // Casual user
        default:
            return Int.random(in: 1...4)  // New user
        }
    }
    
    /// Simulates a single payment session
    private func simulatePaymentSession(
        userId: String,
        variant: ABTestVariant,
        sessionTime: Date,
        user: UserProfile
    ) -> [ABTestInteraction] {
        var interactions: [ABTestInteraction] = []
        let sessionId = UUID().uuidString
        
        // 1. User sees payment button (impression)
        let impressionTime = sessionTime
        abTesting.trackEvent(
            testId: testId,
            variantId: variant.id,
            userId: userId,
            eventType: .impression,
            eventName: "payment_button_viewed",
            properties: [
                "variant_name": variant.name,
                "session_id": sessionId,
                "user_experience_level": getUserExperienceLevel(user)
            ]
        )
        interactions.append(ABTestInteraction(
            type: "impression",
            time: impressionTime,
            result: "viewed"
        ))
        
        // 2. User engagement (time looking at button)
        let engagementDuration = simulateEngagementTime(variant: variant, user: user)
        let engagementTime = impressionTime.addingTimeInterval(1.0)
        abTesting.trackEvent(
            testId: testId,
            variantId: variant.id,
            userId: userId,
            eventType: .engagement,
            eventName: "button_engagement",
            properties: [
                "duration": String(engagementDuration),
                "variant_name": variant.name,
                "session_id": sessionId
            ]
        )
        interactions.append(ABTestInteraction(
            type: "engagement",
            time: engagementTime,
            result: "\(engagementDuration)s"
        ))
        
        // 3. Decision to click or not
        let willClick = determineClickProbability(variant: variant, user: user)
        
        if willClick {
            // 3a. User clicks payment button
            let clickTime = engagementTime.addingTimeInterval(engagementDuration)
            abTesting.trackEvent(
                testId: testId,
                variantId: variant.id,
                userId: userId,
                eventType: .click,
                eventName: "payment_button_clicked",
                properties: [
                    "variant_name": variant.name,
                    "amount": generateRandomAmount(),
                    "session_id": sessionId,
                    "hesitation_time": String(engagementDuration)
                ]
            )
            interactions.append(ABTestInteraction(
                type: "click",
                time: clickTime,
                result: "clicked"
            ))
            
            // 4. Payment completion decision
            let willComplete = determineConversionProbability(variant: variant, user: user)
            
            if willComplete {
                // 4a. Successful payment (conversion)
                let conversionTime = clickTime.addingTimeInterval(Double.random(in: 2.0...5.0))
                abTesting.trackEvent(
                    testId: testId,
                    variantId: variant.id,
                    userId: userId,
                    eventType: .conversion,
                    eventName: "payment_completed",
                    properties: [
                        "variant_name": variant.name,
                        "success": "true",
                        "session_id": sessionId,
                        "completion_time": String(conversionTime.timeIntervalSince(clickTime))
                    ]
                )
                interactions.append(ABTestInteraction(
                    type: "conversion",
                    time: conversionTime,
                    result: "completed"
                ))
            } else {
                // 4b. Payment failed or abandoned
                let errorTime = clickTime.addingTimeInterval(Double.random(in: 1.0...8.0))
                abTesting.trackEvent(
                    testId: testId,
                    variantId: variant.id,
                    userId: userId,
                    eventType: .error,
                    eventName: "payment_abandoned",
                    properties: [
                        "variant_name": variant.name,
                        "error_reason": ["timeout", "cancelled", "insufficient_funds"].randomElement()!,
                        "session_id": sessionId
                    ]
                )
                interactions.append(ABTestInteraction(
                    type: "error",
                    time: errorTime,
                    result: "abandoned"
                ))
            }
        }
        
        return interactions
    }
    
    /// Simulates user engagement time based on variant and user characteristics
    private func simulateEngagementTime(variant: ABTestVariant, user: UserProfile) -> Double {
        let baseEngagement: Double
        
        // Orange variant should be more engaging (less hesitation)
        if variant.id == "variant_a" {
            baseEngagement = Double.random(in: 0.5...2.0) // Faster decision
        } else {
            baseEngagement = Double.random(in: 1.0...3.5) // More hesitation
        }
        
        // Adjust based on user experience
        let experienceMultiplier: Double
        switch user.totalTransactions {
        case 40...:
            experienceMultiplier = 0.6 // Experienced users are faster
        case 20..<40:
            experienceMultiplier = 0.8
        case 10..<20:
            experienceMultiplier = 1.0
        default:
            experienceMultiplier = 1.3 // New users are slower
        }
        
        return baseEngagement * experienceMultiplier
    }
    
    /// Determines click probability based on variant design and user profile
    private func determineClickProbability(variant: ABTestVariant, user: UserProfile) -> Bool {
        var clickProbability: Double
        
        // Orange variant should have higher click-through rate
        if variant.id == "variant_a" {
            clickProbability = 0.75 // 75% click rate
        } else {
            clickProbability = 0.65 // 65% click rate (control)
        }
        
        // Adjust for user characteristics
        switch user.kycStatus {
        case .verified:
            clickProbability += 0.10 // Verified users more likely to click
        case .pending:
            clickProbability += 0.05
        default:
            break
        }
        
        // Experience level adjustment
        if user.totalTransactions > 30 {
            clickProbability += 0.05 // Experienced users more confident
        }
        
        return Double.random(in: 0...1) < clickProbability
    }
    
    /// Determines conversion probability after click
    private func determineConversionProbability(variant: ABTestVariant, user: UserProfile) -> Bool {
        var conversionProbability: Double
        
        // Orange variant should have higher conversion rate due to better UX
        if variant.id == "variant_a" {
            conversionProbability = 0.82 // 82% conversion after click
        } else {
            conversionProbability = 0.76 // 76% conversion (control)
        }
        
        // User trust factors
        if user.isEmailVerified && user.isPhoneVerified {
            conversionProbability += 0.08
        } else if user.isEmailVerified {
            conversionProbability += 0.04
        }
        
        // Experience factor
        if user.totalTransactions > 20 {
            conversionProbability += 0.05
        }
        
        return Double.random(in: 0...1) < conversionProbability
    }
    
    /// Generates random payment amounts for simulation
    private func generateRandomAmount() -> String {
        let amounts = ["12.50", "25.00", "8.75", "50.00", "15.99", "33.33", "7.50", "100.00"]
        return amounts.randomElement() ?? "25.00"
    }
    
    /// Gets user experience level for tracking
    private func getUserExperienceLevel(_ user: UserProfile) -> String {
        switch user.totalTransactions {
        case 40...:
            return "expert"
        case 20..<40:
            return "experienced"
        case 10..<20:
            return "intermediate"
        default:
            return "beginner"
        }
    }
    
    /// Prints comprehensive simulation summary
    private func printSimulationSummary(_ results: [String: ABTestSimulationResult], finalResults: ABTestResults?) {
        print("\n📊 A/B TEST SIMULATION RESULTS")
        print("=" * 50)
        
        // Individual user results
        for (_, result) in results {
            let impressions = result.interactions.filter { $0.type == "impression" }.count
            let clicks = result.interactions.filter { $0.type == "click" }.count
            let conversions = result.interactions.filter { $0.type == "conversion" }.count
            
            print("👤 User: \(result.userId)")
            print("   Variant: \(result.variant)")
            print("   Sessions: \(impressions)")
            print("   Clicks: \(clicks) (\(impressions > 0 ? Int(Double(clicks)/Double(impressions)*100) : 0)%)")
            print("   Conversions: \(conversions) (\(clicks > 0 ? Int(Double(conversions)/Double(clicks)*100) : 0)%)")
            print("   ---")
        }
        
        // Overall test results
        if let finalResults = finalResults {
            print("\n🎯 OVERALL TEST RESULTS")
            print("Total Participants: \(finalResults.totalParticipants)")
            
            for variant in finalResults.variantResults {
                print("\n📈 \(variant.variantName)")
                print("   Participants: \(variant.participants)")
                print("   Conversion Rate: \(String(format: "%.1f", variant.conversionRate * 100))%")
                print("   Click Rate: \(String(format: "%.1f", variant.clickThroughRate * 100))%")
                print("   Error Rate: \(String(format: "%.1f", variant.errorRate * 100))%")
            }
            
            if let significance = finalResults.statisticalSignificance {
                print("\n📊 STATISTICAL ANALYSIS")
                print("   Significant: \(significance.isSignificant ? "YES" : "NO")")
                print("   P-Value: \(String(format: "%.4f", significance.pValue))")
                print("   Effect: \(significance.effect.capitalized)")
                
                if let winner = finalResults.winner {
                    let winnerName = finalResults.variantResults.first(where: { $0.variantId == winner })?.variantName ?? "Unknown"
                    print("   🏆 Winner: \(winnerName)")
                } else {
                    print("   🤝 No clear winner")
                }
            }
        }
        
        print("\n" + "=" * 50)
    }
}

// MARK: - Simulation Data Models

struct ABTestSimulationResult {
    let userId: String
    let variant: String
    let interactions: [ABTestInteraction]
}

struct ABTestInteraction {
    let type: String
    let time: Date
    let result: String
}

// MARK: - Simulation View for Testing

struct ABTestSimulationView: View {
    @StateObject private var abTesting = ABTestingManager.shared
    @State private var isRunningSimulation = false
    @State private var simulationProgress = 0.0
    @State private var simulationComplete = false
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "flask.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("A/B Test Simulation")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Run simulated user interactions with demo users to generate test data")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            if isRunningSimulation {
                VStack(spacing: 16) {
                    ProgressView(value: simulationProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        .scaleEffect(y: 2.0)
                    
                    Text("Simulating user interactions... \(Int(simulationProgress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            } else if simulationComplete {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("Simulation Complete!")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("Check the A/B Test Dashboard for results")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                Button("Run Simulation") {
                    runSimulation()
                }
                .buttonStyle(ActionButtonStyle(color: .orange))
            }
            
            if !isRunningSimulation && !simulationComplete {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What will be simulated:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Image(systemName: "person.2")
                        Text("5 demo users with different experience levels")
                    }
                    .font(.subheadline)
                    
                    HStack {
                        Image(systemName: "eye")
                        Text("Payment button impressions and engagement")
                    }
                    .font(.subheadline)
                    
                    HStack {
                        Image(systemName: "hand.tap")
                        Text("Click-through behavior based on user psychology")
                    }
                    .font(.subheadline)
                    
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Payment conversions with realistic success rates")
                    }
                    .font(.subheadline)
                    
                    HStack {
                        Image(systemName: "chart.bar")
                        Text("Statistical analysis with significance testing")
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Run Test Simulation")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func runSimulation() {
        isRunningSimulation = true
        simulationProgress = 0.0
        simulationComplete = false
        
        // Reset previous test data
        abTesting.resetTestData()
        
        // Animate progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            simulationProgress += 0.02
            
            if simulationProgress >= 1.0 {
                timer.invalidate()
                
                // Run the actual simulation
                DispatchQueue.global(qos: .background).async {
                    ABTestSimulation.shared.simulateTestWithDemoUsers()
                    
                    DispatchQueue.main.async {
                        isRunningSimulation = false
                        simulationComplete = true
                        HapticManager.shared.success()
                    }
                }
            }
        }
    }
}

// Helper extension for string repetition
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}
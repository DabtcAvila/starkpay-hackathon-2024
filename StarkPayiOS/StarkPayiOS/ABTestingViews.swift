import SwiftUI

// MARK: - A/B Test Enabled Payment Button

struct ABTestPaymentButton: View {
    let amount: String
    let isProcessing: Bool
    let userId: String
    let onTap: () -> Void
    
    @StateObject private var abTesting = ABTestingManager.shared
    @State private var buttonPressed = false
    @State private var engagementStartTime: Date?
    
    private let testId = "payment_button_design_v1"
    
    var body: some View {
        Group {
            if let variant = abTesting.getVariantForTest(testId, userId: userId) {
                ABTestButtonView(
                    variant: variant,
                    amount: amount,
                    isProcessing: isProcessing,
                    buttonPressed: $buttonPressed,
                    onTap: handleButtonTap
                )
                .onAppear {
                    trackEngagementStart()
                }
                .onDisappear {
                    trackEngagementEnd()
                }
            } else {
                // Fallback to original button design
                DefaultPaymentButton(
                    amount: amount,
                    isProcessing: isProcessing,
                    onTap: onTap
                )
            }
        }
    }
    
    private func handleButtonTap() {
        let variant = abTesting.getVariantForTest(testId, userId: userId)
        
        // Track click event
        abTesting.trackEvent(
            testId: testId,
            variantId: variant?.id ?? "fallback",
            userId: userId,
            eventType: .click,
            eventName: "payment_button_clicked",
            properties: [
                "amount": amount,
                "variant_name": variant?.name ?? "fallback",
                "button_style": variant?.configuration["button_style"]?.stringValue ?? "default"
            ]
        )
        
        // Execute the actual payment action
        onTap()
        
        // Track conversion after a delay (simulating successful payment)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            abTesting.trackEvent(
                testId: testId,
                variantId: variant?.id ?? "fallback",
                userId: userId,
                eventType: .conversion,
                eventName: "payment_completed",
                properties: [
                    "amount": amount,
                    "success": "true",
                    "variant_name": variant?.name ?? "fallback"
                ]
            )
        }
    }
    
    private func trackEngagementStart() {
        engagementStartTime = Date()
        let variant = abTesting.getVariantForTest(testId, userId: userId)
        
        abTesting.trackEvent(
            testId: testId,
            variantId: variant?.id ?? "fallback",
            userId: userId,
            eventType: .engagement,
            eventName: "button_view_started",
            properties: [
                "variant_name": variant?.name ?? "fallback"
            ]
        )
    }
    
    private func trackEngagementEnd() {
        guard let startTime = engagementStartTime else { return }
        let engagementDuration = Date().timeIntervalSince(startTime)
        let variant = abTesting.getVariantForTest(testId, userId: userId)
        
        abTesting.trackEvent(
            testId: testId,
            variantId: variant?.id ?? "fallback",
            userId: userId,
            eventType: .engagement,
            eventName: "button_view_ended",
            properties: [
                "duration": String(engagementDuration),
                "variant_name": variant?.name ?? "fallback"
            ]
        )
    }
}

// MARK: - A/B Test Button View

struct ABTestButtonView: View {
    let variant: ABTestVariant
    let amount: String
    let isProcessing: Bool
    @Binding var buttonPressed: Bool
    let onTap: () -> Void
    
    private var buttonColor: Color {
        variant.configuration["button_color"]?.colorValue ?? .black
    }
    
    private var buttonText: String {
        let template = variant.configuration["button_text"]?.stringValue ?? "Pay $AMOUNT"
        return template.replacingOccurrences(of: "$AMOUNT", with: amount.isEmpty ? "$0.00" : "$\(amount)")
    }
    
    private var buttonStyle: String {
        variant.configuration["button_style"]?.stringValue ?? "gradient"
    }
    
    private var buttonSize: String {
        variant.configuration["button_size"]?.stringValue ?? "standard"
    }
    
    private var animationEnabled: Bool {
        variant.configuration["animation_enabled"]?.stringValue == "true"
    }
    
    private var shadowEnabled: Bool {
        variant.configuration["shadow_enabled"]?.stringValue == "true"
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            onTap()
        }) {
            HStack(spacing: 12) {
                if isProcessing {
                    PremiumLoadingView(size: 20, color: .white)
                }
                
                Text(isProcessing ? "Processing..." : buttonText)
                    .font(buttonSize == "large" ? .title3 : .headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, buttonSize == "large" ? 18 : 16)
            .background(buttonBackground)
            .cornerRadius(buttonSize == "large" ? 16 : 12)
            .shadow(
                color: shadowEnabled ? buttonColor.opacity(0.3) : .clear,
                radius: shadowEnabled ? 8 : 0,
                x: 0,
                y: shadowEnabled ? 4 : 0
            )
        }
        .buttonStyle(ABTestButtonStyle(
            color: buttonColor,
            isLoading: isProcessing,
            animationEnabled: animationEnabled
        ))
        .scaleEffect(buttonPressed ? 0.98 : 1.0)
        .animation(
            animationEnabled ? .spring(response: 0.3, dampingFraction: 0.6) : .none,
            value: buttonPressed
        )
        .disabled(amount.isEmpty || isProcessing)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            if animationEnabled {
                buttonPressed = pressing
            }
        } perform: {
            // Long press action if needed
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        switch buttonStyle {
        case "gradient":
            LinearGradient(
                colors: [buttonColor, buttonColor.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case "solid":
            buttonColor
        default:
            LinearGradient(
                colors: [buttonColor, buttonColor.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - A/B Test Button Style

struct ABTestButtonStyle: ButtonStyle {
    let color: Color
    let isLoading: Bool
    let animationEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && animationEnabled ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(
                animationEnabled ? .easeInOut(duration: 0.1) : .none,
                value: configuration.isPressed
            )
            .disabled(isLoading)
    }
}

// MARK: - Default Payment Button (Fallback)

struct DefaultPaymentButton: View {
    let amount: String
    let isProcessing: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            onTap()
        }) {
            HStack(spacing: 12) {
                if isProcessing {
                    PremiumLoadingView(size: 20, color: .white)
                }
                
                Text(isProcessing ? "Processing..." : "Pay $\(amount.isEmpty ? "0.00" : amount)")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: isProcessing ? [.gray, .gray.opacity(0.8)] : [.black, .gray.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PremiumButtonStyle(color: .black, isLoading: isProcessing))
        .disabled(amount.isEmpty || isProcessing)
    }
}

// MARK: - A/B Test Results Dashboard

struct ABTestDashboardView: View {
    @StateObject private var abTesting = ABTestingManager.shared
    @State private var selectedTestId: String = "payment_button_design_v1"
    @State private var showingRawData = false
    @State private var showingExportData = false
    @State private var exportedData = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Test Selection
                    testSelectionSection
                    
                    // Results Overview
                    if let results = abTesting.getTestResults(selectedTestId) {
                        resultsOverviewSection(results)
                        variantComparisonSection(results)
                        statisticalAnalysisSection(results)
                        rawDataSection(results)
                    } else {
                        noDataSection
                    }
                    
                    // Actions
                    actionSection
                    
                    // Simulation
                    simulationSection
                }
                .padding()
            }
            .navigationTitle("A/B Test Results")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingExportData) {
                exportDataSheet
            }
        }
    }
    
    @ViewBuilder
    private var testSelectionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Active Tests")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            ForEach(abTesting.activeTests, id: \.testId) { test in
                TestSelectionCard(
                    test: test,
                    isSelected: selectedTestId == test.testId,
                    onSelect: { selectedTestId = test.testId }
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func resultsOverviewSection(_ results: ABTestResults) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Results Overview")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                
                Text("Generated: \(results.generatedAt, style: .time)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Total Participants",
                    value: "\(results.totalParticipants)",
                    icon: "person.2.circle",
                    color: .blue
                )
                
                MetricCard(
                    title: "Confidence Level",
                    value: "\(Int(results.confidenceLevel * 100))%",
                    icon: "chart.line.uptrend.xyaxis.circle",
                    color: .green
                )
                
                MetricCard(
                    title: "Statistical Significance",
                    value: results.statisticalSignificance?.isSignificant == true ? "YES" : "NO",
                    icon: results.statisticalSignificance?.isSignificant == true ? "checkmark.circle" : "xmark.circle",
                    color: results.statisticalSignificance?.isSignificant == true ? .green : .orange
                )
                
                MetricCard(
                    title: "Winner",
                    value: results.winner != nil ? 
                        (results.variantResults.first(where: { $0.variantId == results.winner })?.variantName ?? "Unknown") : 
                        "No Winner",
                    icon: "trophy.circle",
                    color: results.winner != nil ? .yellow : .gray
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private func variantComparisonSection(_ results: ABTestResults) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Variant Performance")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            ForEach(results.variantResults, id: \.variantId) { variant in
                VariantResultCard(
                    variant: variant,
                    isWinner: variant.variantId == results.winner,
                    totalParticipants: results.totalParticipants
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private func statisticalAnalysisSection(_ results: ABTestResults) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Statistical Analysis")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            if let significance = results.statisticalSignificance {
                VStack(spacing: 12) {
                    HStack {
                        Text("P-Value:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(String(format: "%.4f", significance.pValue))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(significance.pValue < 0.05 ? .green : .red)
                    }
                    
                    HStack {
                        Text("Sample Size:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(significance.sampleSize)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Effect:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(significance.effect.capitalized)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(effectColor(significance.effect))
                    }
                    
                    if significance.isSignificant {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Results are statistically significant at 95% confidence level")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 8)
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Results are not statistically significant - need more data")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 8)
                    }
                }
            } else {
                Text("Insufficient data for statistical analysis")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func rawDataSection(_ results: ABTestResults) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Raw Data")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                
                Button("View Details") {
                    showingRawData.toggle()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if showingRawData {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Events:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        ForEach(abTesting.collectedEvents.suffix(10), id: \.id) { event in
                            HStack {
                                Text(event.eventType.rawValue.uppercased())
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(eventTypeColor(event.eventType))
                                    .cornerRadius(8)
                                
                                Text(event.eventName)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text(event.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var noDataSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Data Available")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            
            Text("Start using the app to collect A/B test data")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
    
    @ViewBuilder
    private var actionSection: some View {
        VStack(spacing: 12) {
            Button("Export Test Data") {
                exportedData = abTesting.exportTestData()
                showingExportData = true
            }
            .buttonStyle(ActionButtonStyle(color: .blue))
            
            Button("Reset Test Data") {
                abTesting.resetTestData()
            }
            .buttonStyle(ActionButtonStyle(color: .red))
        }
    }
    
    @ViewBuilder
    private var simulationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Test Simulation")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            NavigationLink(destination: ABTestSimulationView()) {
                HStack {
                    Image(systemName: "flask.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Run User Simulation")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Generate realistic A/B test data with demo users")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.orange.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var exportDataSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("A/B Test Data Export")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("This data can be imported into statistical analysis tools like R, Python, or Excel for further analysis.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ScrollView {
                        Text(exportedData)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 400)
                }
                .padding()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingExportData = false
                    }
                }
            }
        }
    }
    
    private func effectColor(_ effect: String) -> Color {
        switch effect {
        case "positive": return .green
        case "negative": return .red
        case "neutral": return .gray
        default: return .orange
        }
    }
    
    private func eventTypeColor(_ type: ABTestEventType) -> Color {
        switch type {
        case .impression: return .blue
        case .click: return .orange
        case .conversion: return .green
        case .engagement: return .purple
        case .error: return .red
        }
    }
}

// MARK: - Supporting Views

struct TestSelectionCard: View {
    let test: ABTestConfig
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(test.testName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if test.isRunning {
                        Text("ACTIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                
                Text(test.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Text("Target: \(test.targetMetric)")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("\(test.variants.count) variants")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct VariantResultCard: View {
    let variant: VariantResults
    let isWinner: Bool
    let totalParticipants: Int
    
    private var trafficPercentage: Double {
        totalParticipants > 0 ? Double(variant.participants) / Double(totalParticipants) * 100 : 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(variant.variantName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isWinner {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text("\(variant.participants) participants (\(String(format: "%.1f", trafficPercentage))%)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Conversion Rate")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", variant.conversionRate * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isWinner ? .green : .primary)
                }
                
                VStack(alignment: .leading) {
                    Text("Click Rate")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", variant.clickThroughRate * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading) {
                    Text("Errors")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", variant.errorRate * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(variant.errorRate > 0.01 ? .red : .green)
                }
            }
        }
        .padding()
        .background(isWinner ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isWinner ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: isWinner ? 2 : 1)
        )
    }
}

struct ActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
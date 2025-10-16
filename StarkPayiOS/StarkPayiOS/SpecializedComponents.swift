import SwiftUI
import Charts

// MARK: - Specialized StarkPay UI Components

// MARK: - Amount Input with Currency Formatting
struct CurrencyAmountInput: View {
    @Binding var amount: Double
    let currency: String
    let placeholder: String
    
    var maxAmount: Double? = nil
    var onValidationChanged: ((Bool) -> Void)? = nil
    
    @State private var textAmount: String = ""
    @State private var isValid = true
    @FocusState private var isFocused: Bool
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount")
                .dynamicTypeSize(16, weight: .medium)
                .foregroundColor(.primary)
            
            HStack {
                Text(currency)
                    .dynamicTypeSize(24, weight: .bold)
                    .foregroundColor(.orange)
                    .frame(width: 60, alignment: .leading)
                
                TextField(placeholder, text: $textAmount)
                    .keyboardType(.decimalPad)
                    .dynamicTypeSize(32, weight: .bold)
                    .foregroundColor(.primary)
                    .focused($isFocused)
                    .onChange(of: textAmount) { newValue in
                        updateAmount(from: newValue)
                    }
                    .onAppear {
                        if amount > 0 {
                            textAmount = String(format: "%.2f", amount)
                        }
                    }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isFocused ? .orange : (isValid ? .clear : .red),
                                lineWidth: 2
                            )
                    )
            )
            
            // Validation feedback
            if !isValid {
                Label(
                    maxAmount != nil ? "Amount exceeds maximum of \(currency) \(maxAmount!, specifier: "%.2f")" : "Invalid amount",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .dynamicTypeSize(14)
                .foregroundColor(.red)
                .slideIn(isVisible: true, from: .top)
            }
            
            // Quick amount buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(quickAmounts, id: \.self) { quickAmount in
                    Button(action: {
                        amount = quickAmount
                        textAmount = String(format: "%.0f", quickAmount)
                        HapticManager.shared.selection()
                    }) {
                        Text("\(currency) \(quickAmount, specifier: "%.0f")")
                            .dynamicTypeSize(14, weight: .medium)
                            .foregroundColor(.orange)
                            .frame(height: 36)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.orange, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .accessibleText(
            label: "Amount input field",
            hint: "Enter payment amount"
        )
    }
    
    private let quickAmounts: [Double] = [10, 25, 50, 100, 250, 500, 1000, 2500]
    
    private func updateAmount(from text: String) {
        let cleanText = text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        
        if let newAmount = Double(cleanText) {
            amount = newAmount
            let valid = newAmount > 0 && (maxAmount == nil || newAmount <= maxAmount!)
            
            if valid != isValid {
                isValid = valid
                onValidationChanged?(valid)
                
                if !valid {
                    HapticManager.shared.warning()
                }
            }
        } else {
            amount = 0
            isValid = false
            onValidationChanged?(false)
        }
    }
}

// MARK: - Payment Method Selector
struct PaymentMethodSelector: View {
    @Binding var selectedMethod: PaymentMethod
    let availableMethods: [PaymentMethod]
    
    var onSelectionChanged: ((PaymentMethod) -> Void)? = nil
    
    struct PaymentMethod: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let icon: String
        let balance: Double?
        let isEnabled: Bool
        let description: String?
        
        static func == (lhs: PaymentMethod, rhs: PaymentMethod) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Method")
                .dynamicTypeSize(18, weight: .semibold)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 12) {
                ForEach(availableMethods) { method in
                    PaymentMethodRow(
                        method: method,
                        isSelected: method == selectedMethod
                    ) {
                        selectedMethod = method
                        onSelectionChanged?(method)
                        HapticManager.shared.selection()
                    }
                }
            }
        }
    }
}

private struct PaymentMethodRow: View {
    let method: PaymentMethodSelector.PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Method icon
                ZStack {
                    Circle()
                        .fill(method.isEnabled ? .orange.opacity(0.1) : Color(.systemGray5))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: method.icon)
                        .font(.title2)
                        .foregroundColor(method.isEnabled ? .orange : .gray)
                }
                
                // Method details
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.name)
                        .dynamicTypeSize(16, weight: .semibold)
                        .foregroundColor(.primary)
                    
                    if let description = method.description {
                        Text(description)
                            .dynamicTypeSize(14)
                            .foregroundColor(.secondary)
                    }
                    
                    if let balance = method.balance {
                        Text("Balance: ETH \(balance, specifier: "%.4f")")
                            .dynamicTypeSize(13, weight: .medium)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? .orange : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(.orange)
                            .frame(width: 12, height: 12)
                    }
                }
                .animation(.spring(response: 0.3), value: isSelected)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? .orange : .clear,
                                lineWidth: 2
                            )
                    )
            )
            .opacity(method.isEnabled ? 1.0 : 0.6)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .disabled(!method.isEnabled)
        .accessibleButton(
            label: "\(method.name). \(method.description ?? "")",
            hint: isSelected ? "Selected" : "Double tap to select"
        )
    }
}

// MARK: - Transaction History Chart
struct TransactionChart: View {
    let transactions: [Transaction]
    let timeframe: Timeframe
    
    @State private var selectedTransaction: Transaction?
    @State private var animateChart = false
    
    enum Timeframe: String, CaseIterable {
        case week = "7D"
        case month = "1M"
        case quarter = "3M"
        case year = "1Y"
        
        var title: String {
            switch self {
            case .week: return "Last 7 Days"
            case .month: return "Last Month"
            case .quarter: return "Last 3 Months"
            case .year: return "Last Year"
            }
        }
    }
    
    struct Transaction: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Double
        let type: TransactionType
        let description: String
        
        enum TransactionType {
            case sent, received
            
            var color: Color {
                switch self {
                case .sent: return .red
                case .received: return .green
                }
            }
        }
    }
    
    private var chartData: [(date: Date, sent: Double, received: Double)] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch timeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        let filteredTransactions = transactions.filter { $0.date >= startDate }
        let groupedByDate = Dictionary(grouping: filteredTransactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
        
        return groupedByDate.map { date, transactions in
            let sent = transactions.filter { $0.type == .sent }.reduce(0) { $0 + $1.amount }
            let received = transactions.filter { $0.type == .received }.reduce(0) { $0 + $1.amount }
            return (date: date, sent: sent, received: received)
        }.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Transaction Activity")
                    .dynamicTypeSize(20, weight: .bold)
                    .foregroundColor(.primary)
                
                Text(timeframe.title)
                    .dynamicTypeSize(16)
                    .foregroundColor(.secondary)
            }
            
            // Chart
            if !chartData.isEmpty {
                Chart {
                    ForEach(chartData, id: \.date) { data in
                        BarMark(
                            x: .value("Date", data.date, unit: .day),
                            y: .value("Sent", -data.sent)
                        )
                        .foregroundStyle(.red.opacity(0.7))
                        .cornerRadius(4)
                        
                        BarMark(
                            x: .value("Date", data.date, unit: .day),
                            y: .value("Received", data.received)
                        )
                        .foregroundStyle(.green.opacity(0.7))
                        .cornerRadius(4)
                        
                        if let selectedTransaction = selectedTransaction,
                           Calendar.current.isDate(data.date, inSameDayAs: selectedTransaction.date) {
                            RuleMark(x: .value("Selected", data.date, unit: .day))
                                .foregroundStyle(.orange)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        }
                    }
                }
                .frame(height: 200)
                .chartAngleSelection(value: .constant(nil))
                .animation(.easeInOut(duration: 1.0), value: animateChart)
                .onAppear {
                    animateChart = true
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No transaction data")
                        .dynamicTypeSize(16, weight: .medium)
                        .foregroundColor(.secondary)
                    
                    Text("Complete your first transaction to see analytics")
                        .dynamicTypeSize(14)
                        .foregroundColor(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            }
            
            // Summary
            if !chartData.isEmpty {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Total Sent", systemImage: "arrow.up.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                        
                        Text("ETH \(totalSent, specifier: "%.4f")")
                            .dynamicTypeSize(16, weight: .bold)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Total Received", systemImage: "arrow.down.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("ETH \(totalReceived, specifier: "%.4f")")
                            .dynamicTypeSize(16, weight: .bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .accessibleText(
            label: "Transaction chart for \(timeframe.title)",
            traits: .isImage
        )
    }
    
    private var totalSent: Double {
        chartData.reduce(0) { $0 + $1.sent }
    }
    
    private var totalReceived: Double {
        chartData.reduce(0) { $0 + $1.received }
    }
}

// MARK: - QR Code Scanner Frame
struct QRScannerFrame: View {
    @Binding var isScanning: Bool
    let onCodeDetected: (String) -> Void
    
    @State private var animateScanner = false
    
    var body: some View {
        ZStack {
            // Camera background (placeholder)
            Rectangle()
                .fill(.black)
                .ignoresSafeArea()
            
            // Overlay
            Rectangle()
                .fill(.black.opacity(0.5))
                .ignoresSafeArea()
            
            // Scanner frame
            VStack {
                Spacer()
                
                ZStack {
                    // Scanner window
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 250, height: 250)
                    
                    // Corner brackets
                    VStack {
                        HStack {
                            ScannerCorner(corner: .topLeft)
                            Spacer()
                            ScannerCorner(corner: .topRight)
                        }
                        Spacer()
                        HStack {
                            ScannerCorner(corner: .bottomLeft)
                            Spacer()
                            ScannerCorner(corner: .bottomRight)
                        }
                    }
                    .frame(width: 250, height: 250)
                    
                    // Scanning line animation
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .orange, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .offset(y: animateScanner ? 100 : -100)
                        .animation(
                            .linear(duration: 2.0).repeatForever(autoreverses: true),
                            value: animateScanner
                        )
                        .onAppear {
                            animateScanner = true
                        }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Scan QR Code")
                        .dynamicTypeSize(24, weight: .bold)
                        .foregroundColor(.white)
                    
                    Text("Position the QR code within the frame to scan")
                        .dynamicTypeSize(16)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 32) {
                        Button(action: {
                            // Toggle flash
                            HapticManager.shared.lightImpact()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "flashlight.on.fill")
                                    .font(.title2)
                                Text("Flash")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            isScanning = false
                            HapticManager.shared.mediumImpact()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                Text("Cancel")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            // Open gallery
                            HapticManager.shared.lightImpact()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.title2)
                                Text("Gallery")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .accessibleText(
            label: "QR code scanner",
            hint: "Position QR code within the scanning frame"
        )
    }
}

private struct ScannerCorner: View {
    let corner: Corner
    
    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.orange)
                .frame(width: 4, height: 20)
                .offset(x: xOffset, y: 0)
            
            Rectangle()
                .fill(.orange)
                .frame(width: 20, height: 4)
                .offset(x: 0, y: yOffset)
        }
        .frame(width: 20, height: 20)
    }
    
    private var xOffset: CGFloat {
        switch corner {
        case .topLeft, .bottomLeft: return -8
        case .topRight, .bottomRight: return 8
        }
    }
    
    private var yOffset: CGFloat {
        switch corner {
        case .topLeft, .topRight: return -8
        case .bottomLeft, .bottomRight: return 8
        }
    }
}

// MARK: - Network Status Indicator
struct NetworkStatusIndicator: View {
    @StateObject private var networkMonitor = NetworkMonitor()
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(networkMonitor.isConnected ? .green : .red)
                .frame(width: 8, height: 8)
                .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
            
            Text(networkMonitor.connectionDescription)
                .dynamicTypeSize(12, weight: .medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
        .accessibleText(
            label: "Network status: \(networkMonitor.connectionDescription)"
        )
    }
}

// MARK: - Network Monitor
private class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .wifi
    
    enum ConnectionType {
        case wifi, cellular, ethernet, unknown
        
        var description: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .unknown: return "Unknown"
            }
        }
    }
    
    var connectionDescription: String {
        if isConnected {
            return connectionType.description
        } else {
            return "Offline"
        }
    }
    
    init() {
        // Initialize network monitoring
        // In a real app, use Network framework
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Simulate network status changes for demo
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            // Randomly simulate connection changes for demo
            if Bool.random() {
                self.isConnected.toggle()
            }
        }
    }
}
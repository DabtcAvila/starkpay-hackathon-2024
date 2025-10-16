import SwiftUI
import os.log
import Foundation

// MARK: - Advanced Performance Monitoring and Analytics Framework

/// Comprehensive performance monitoring system for StarkPay
@MainActor
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    // MARK: - Published Properties
    @Published var isMonitoring = false
    @Published var currentMetrics: PerformanceMetrics
    @Published var memoryWarning = false
    @Published var performanceIssues: [PerformanceIssue] = []
    
    // Configuration
    @Published var monitoringEnabled = true
    @Published var memoryThresholdMB: Double = 150
    @Published var cpuThresholdPercentage: Double = 80
    @Published var frameDropThreshold: Double = 16.67 // 60 FPS = 16.67ms per frame
    
    // Internal tracking
    private var frameTimestamps: [CFTimeInterval] = []
    private var memoryUsageHistory: [Double] = []
    private var cpuUsageHistory: [Double] = []
    private var networkRequestMetrics: [NetworkMetric] = []
    private var startTime: Date
    private var sessionMetrics: SessionMetrics
    
    // Timers and monitoring
    private var metricsTimer: Timer?
    private var memoryTimer: Timer?
    private var frameTimer: CADisplayLink?
    
    // Logger
    private let logger = Logger(subsystem: "com.starkpay.ios", category: "Performance")
    
    struct PerformanceMetrics {
        var memoryUsageMB: Double = 0
        var cpuUsagePercentage: Double = 0
        var averageFPS: Double = 60
        var frameDropCount: Int = 0
        var networkLatencyMS: Double = 0
        var batteryLevel: Float = 1.0
        var thermalState: ProcessInfo.ThermalState = .nominal
        var diskUsageMB: Double = 0
        var activeNetworkRequests: Int = 0
        
        var overallScore: Double {
            // Calculate performance score (0-100)
            let memoryScore = max(0, min(100, 100 - (memoryUsageMB / 500) * 100))
            let cpuScore = max(0, min(100, 100 - cpuUsagePercentage))
            let fpsScore = min(100, (averageFPS / 60) * 100)
            let networkScore = max(0, min(100, 100 - (networkLatencyMS / 1000) * 100))
            
            return (memoryScore + cpuScore + fpsScore + networkScore) / 4
        }
        
        var performanceGrade: String {
            switch overallScore {
            case 90...100: return "Excellent"
            case 80..<90: return "Good"
            case 70..<80: return "Fair"
            case 50..<70: return "Poor"
            default: return "Critical"
            }
        }
    }
    
    struct PerformanceIssue: Identifiable {
        let id = UUID()
        let type: IssueType
        let severity: Severity
        let message: String
        let timestamp: Date
        let metrics: [String: Any]
        
        enum IssueType {
            case memoryLeak
            case highCPUUsage
            case frameDrops
            case slowNetworkResponse
            case diskSpaceWarning
            case thermalThrottling
            case batteryDrain
        }
        
        enum Severity {
            case low, medium, high, critical
            
            var color: Color {
                switch self {
                case .low: return .green
                case .medium: return .yellow
                case .high: return .orange
                case .critical: return .red
                }
            }
        }
    }
    
    struct SessionMetrics {
        var sessionDuration: TimeInterval = 0
        var totalScreenViews: Int = 0
        var totalUserInteractions: Int = 0
        var totalNetworkRequests: Int = 0
        var totalErrors: Int = 0
        var averageResponseTime: Double = 0
        var crashCount: Int = 0
        var memoryPeakMB: Double = 0
        var cpuPeakPercentage: Double = 0
    }
    
    struct NetworkMetric {
        let id = UUID()
        let url: String
        let method: String
        let startTime: Date
        let endTime: Date
        let responseSize: Int64
        let statusCode: Int?
        let error: Error?
        
        var duration: TimeInterval {
            endTime.timeIntervalSince(startTime)
        }
        
        var wasSuccessful: Bool {
            guard let statusCode = statusCode else { return false }
            return 200...299 ~= statusCode
        }
    }
    
    private init() {
        self.startTime = Date()
        self.currentMetrics = PerformanceMetrics()
        self.sessionMetrics = SessionMetrics()
        
        setupMonitoring()
        loadConfiguration()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        guard monitoringEnabled && !isMonitoring else { return }
        
        isMonitoring = true
        logger.info("Performance monitoring started")
        
        // Start metrics collection
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateMetrics()
            }
        }
        
        // Start memory monitoring
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                self.checkMemoryUsage()
            }
        }
        
        // Start frame monitoring
        setupFrameMonitoring()
        
        // Setup crash detection
        setupCrashDetection()
        
        // Setup network monitoring
        setupNetworkMonitoring()
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        logger.info("Performance monitoring stopped")
        
        metricsTimer?.invalidate()
        metricsTimer = nil
        
        memoryTimer?.invalidate()
        memoryTimer = nil
        
        frameTimer?.invalidate()
        frameTimer = nil
        
        // Generate session report
        generateSessionReport()
    }
    
    // MARK: - Metrics Collection
    
    private func updateMetrics() {
        // Update memory usage
        currentMetrics.memoryUsageMB = getCurrentMemoryUsage()
        
        // Update CPU usage
        currentMetrics.cpuUsagePercentage = getCurrentCPUUsage()
        
        // Update battery level
        currentMetrics.batteryLevel = UIDevice.current.batteryLevel
        
        // Update thermal state
        currentMetrics.thermalState = ProcessInfo.processInfo.thermalState
        
        // Update disk usage
        currentMetrics.diskUsageMB = getDiskUsage()
        
        // Update network metrics
        currentMetrics.activeNetworkRequests = networkRequestMetrics.filter { metric in
            metric.endTime > Date().addingTimeInterval(-5) // Active in last 5 seconds
        }.count
        
        // Calculate average network latency
        let recentNetworkMetrics = networkRequestMetrics.suffix(10)
        currentMetrics.networkLatencyMS = recentNetworkMetrics.isEmpty ? 0 : 
            recentNetworkMetrics.map { $0.duration * 1000 }.reduce(0, +) / Double(recentNetworkMetrics.count)
        
        // Store historical data
        memoryUsageHistory.append(currentMetrics.memoryUsageMB)
        cpuUsageHistory.append(currentMetrics.cpuUsagePercentage)
        
        // Keep history size manageable
        if memoryUsageHistory.count > 300 { // 5 minutes at 1 second intervals
            memoryUsageHistory.removeFirst()
        }
        if cpuUsageHistory.count > 300 {
            cpuUsageHistory.removeFirst()
        }
        
        // Check for performance issues
        checkForPerformanceIssues()
        
        // Update session metrics
        updateSessionMetrics()
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0
        } else {
            return 0
        }
    }
    
    private func getCurrentCPUUsage() -> Double {
        var info = processor_info_array_t()
        var numCpuInfo = mach_msg_type_number_t()
        var numCpus = natural_t()
        
        let result = host_processor_info(mach_host_self(),
                                       PROCESSOR_CPU_LOAD_INFO,
                                       &numCpus,
                                       &info,
                                       &numCpuInfo)
        
        guard result == KERN_SUCCESS else { return 0 }
        
        let cpuLoadInfo = info?.bindMemory(to: processor_cpu_load_info.self, capacity: Int(numCpus))
        
        var totalUser: Double = 0
        var totalSystem: Double = 0
        var totalIdle: Double = 0
        
        for i in 0..<Int(numCpus) {
            let cpu = cpuLoadInfo![i]
            totalUser += Double(cpu.cpu_ticks.0)
            totalSystem += Double(cpu.cpu_ticks.1)
            totalIdle += Double(cpu.cpu_ticks.2)
        }
        
        let totalTicks = totalUser + totalSystem + totalIdle
        return totalTicks > 0 ? ((totalUser + totalSystem) / totalTicks) * 100 : 0
    }
    
    private func getDiskUsage() -> Double {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSize = attributes[.systemFreeSize] as? NSNumber {
                return Double(freeSize.int64Value) / 1024.0 / 1024.0
            }
        } catch {
            logger.error("Failed to get disk usage: \(error.localizedDescription)")
        }
        return 0
    }
    
    // MARK: - Frame Monitoring
    
    private func setupFrameMonitoring() {
        frameTimer = CADisplayLink(target: self, selector: #selector(frameUpdate))
        frameTimer?.add(to: .main, forMode: .common)
    }
    
    @objc private func frameUpdate() {
        let currentTime = CACurrentMediaTime()
        frameTimestamps.append(currentTime)
        
        // Keep only last 60 frames for FPS calculation
        if frameTimestamps.count > 60 {
            frameTimestamps.removeFirst()
        }
        
        // Calculate FPS
        if frameTimestamps.count >= 2 {
            let timeInterval = frameTimestamps.last! - frameTimestamps.first!
            currentMetrics.averageFPS = Double(frameTimestamps.count - 1) / timeInterval
            
            // Check for frame drops
            for i in 1..<frameTimestamps.count {
                let frameDuration = (frameTimestamps[i] - frameTimestamps[i-1]) * 1000
                if frameDuration > frameDropThreshold {
                    currentMetrics.frameDropCount += 1
                }
            }
        }
    }
    
    // MARK: - Performance Issue Detection
    
    private func checkForPerformanceIssues() {
        // Check memory usage
        if currentMetrics.memoryUsageMB > memoryThresholdMB {
            let severity: PerformanceIssue.Severity = currentMetrics.memoryUsageMB > memoryThresholdMB * 1.5 ? .critical : .high
            reportIssue(
                type: .memoryLeak,
                severity: severity,
                message: "High memory usage detected: \(Int(currentMetrics.memoryUsageMB))MB",
                metrics: ["memory_mb": currentMetrics.memoryUsageMB]
            )
        }
        
        // Check CPU usage
        if currentMetrics.cpuUsagePercentage > cpuThresholdPercentage {
            let severity: PerformanceIssue.Severity = currentMetrics.cpuUsagePercentage > 95 ? .critical : .high
            reportIssue(
                type: .highCPUUsage,
                severity: severity,
                message: "High CPU usage detected: \(Int(currentMetrics.cpuUsagePercentage))%",
                metrics: ["cpu_percentage": currentMetrics.cpuUsagePercentage]
            )
        }
        
        // Check frame drops
        if currentMetrics.averageFPS < 50 {
            reportIssue(
                type: .frameDrops,
                severity: .medium,
                message: "Low FPS detected: \(Int(currentMetrics.averageFPS)) FPS",
                metrics: ["fps": currentMetrics.averageFPS, "drops": currentMetrics.frameDropCount]
            )
        }
        
        // Check thermal throttling
        if currentMetrics.thermalState == .serious || currentMetrics.thermalState == .critical {
            reportIssue(
                type: .thermalThrottling,
                severity: .high,
                message: "Thermal throttling detected",
                metrics: ["thermal_state": String(describing: currentMetrics.thermalState)]
            )
        }
        
        // Check battery drain
        if currentMetrics.batteryLevel < 0.2 && currentMetrics.cpuUsagePercentage > 50 {
            reportIssue(
                type: .batteryDrain,
                severity: .medium,
                message: "High CPU usage with low battery",
                metrics: ["battery_level": currentMetrics.batteryLevel, "cpu_percentage": currentMetrics.cpuUsagePercentage]
            )
        }
    }
    
    private func reportIssue(type: PerformanceIssue.IssueType, severity: PerformanceIssue.Severity, message: String, metrics: [String: Any]) {
        let issue = PerformanceIssue(
            type: type,
            severity: severity,
            message: message,
            timestamp: Date(),
            metrics: metrics
        )
        
        performanceIssues.append(issue)
        
        // Keep only recent issues
        if performanceIssues.count > 50 {
            performanceIssues.removeFirst()
        }
        
        // Log the issue
        logger.warning("Performance issue detected: \(message)")
        
        // Send to analytics if severity is high or critical
        if severity == .high || severity == .critical {
            AnalyticsManager.shared.track("performance_issue", properties: [
                "type": String(describing: type),
                "severity": String(describing: severity),
                "message": message,
                "metrics": metrics
            ])
        }
        
        // Show memory warning if applicable
        if type == .memoryLeak && severity == .critical {
            memoryWarning = true
        }
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        // This would typically involve intercepting URLSession requests
        // For demo purposes, we'll simulate network monitoring
    }
    
    func trackNetworkRequest(url: String, method: String, startTime: Date, endTime: Date, responseSize: Int64, statusCode: Int?, error: Error?) {
        let metric = NetworkMetric(
            url: url,
            method: method,
            startTime: startTime,
            endTime: endTime,
            responseSize: responseSize,
            statusCode: statusCode,
            error: error
        )
        
        networkRequestMetrics.append(metric)
        
        // Keep only recent network metrics
        if networkRequestMetrics.count > 100 {
            networkRequestMetrics.removeFirst()
        }
        
        // Check for slow responses
        if metric.duration > 5.0 {
            reportIssue(
                type: .slowNetworkResponse,
                severity: .medium,
                message: "Slow network response: \(metric.duration)s for \(url)",
                metrics: [
                    "url": url,
                    "duration": metric.duration,
                    "size": responseSize
                ]
            )
        }
        
        sessionMetrics.totalNetworkRequests += 1
        updateAverageResponseTime(metric.duration)
    }
    
    private func updateAverageResponseTime(_ duration: TimeInterval) {
        let totalRequests = Double(sessionMetrics.totalNetworkRequests)
        sessionMetrics.averageResponseTime = ((sessionMetrics.averageResponseTime * (totalRequests - 1)) + duration) / totalRequests
    }
    
    // MARK: - Crash Detection
    
    private func setupCrashDetection() {
        NSSetUncaughtExceptionHandler { exception in
            PerformanceMonitor.shared.handleCrash(exception: exception)
        }
        
        signal(SIGABRT) { _ in
            PerformanceMonitor.shared.handleCrash(signal: "SIGABRT")
        }
        
        signal(SIGILL) { _ in
            PerformanceMonitor.shared.handleCrash(signal: "SIGILL")
        }
        
        signal(SIGSEGV) { _ in
            PerformanceMonitor.shared.handleCrash(signal: "SIGSEGV")
        }
    }
    
    private func handleCrash(exception: NSException) {
        sessionMetrics.crashCount += 1
        
        let crashInfo: [String: Any] = [
            "exception_name": exception.name.rawValue,
            "exception_reason": exception.reason ?? "Unknown",
            "call_stack": exception.callStackSymbols,
            "memory_usage": currentMetrics.memoryUsageMB,
            "cpu_usage": currentMetrics.cpuUsagePercentage,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        AnalyticsManager.shared.track("app_crash", properties: crashInfo)
        logger.critical("App crashed: \(exception.reason ?? "Unknown reason")")
    }
    
    private func handleCrash(signal: String) {
        sessionMetrics.crashCount += 1
        
        let crashInfo: [String: Any] = [
            "signal": signal,
            "memory_usage": currentMetrics.memoryUsageMB,
            "cpu_usage": currentMetrics.cpuUsagePercentage,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        AnalyticsManager.shared.track("app_crash_signal", properties: crashInfo)
        logger.critical("App crashed with signal: \(signal)")
    }
    
    // MARK: - Session Metrics
    
    private func updateSessionMetrics() {
        sessionMetrics.sessionDuration = Date().timeIntervalSince(startTime)
        sessionMetrics.memoryPeakMB = max(sessionMetrics.memoryPeakMB, currentMetrics.memoryUsageMB)
        sessionMetrics.cpuPeakPercentage = max(sessionMetrics.cpuPeakPercentage, currentMetrics.cpuUsagePercentage)
    }
    
    func trackScreenView(_ screenName: String) {
        sessionMetrics.totalScreenViews += 1
        
        AnalyticsManager.shared.track("screen_view", properties: [
            "screen_name": screenName,
            "timestamp": Date().timeIntervalSince1970,
            "session_duration": sessionMetrics.sessionDuration
        ])
    }
    
    func trackUserInteraction(_ interactionType: String, details: [String: Any] = [:]) {
        sessionMetrics.totalUserInteractions += 1
        
        var properties = details
        properties["interaction_type"] = interactionType
        properties["timestamp"] = Date().timeIntervalSince1970
        
        AnalyticsManager.shared.track("user_interaction", properties: properties)
    }
    
    func trackError(_ error: Error, context: String) {
        sessionMetrics.totalErrors += 1
        
        AnalyticsManager.shared.track("app_error", properties: [
            "error_description": error.localizedDescription,
            "context": context,
            "timestamp": Date().timeIntervalSince1970,
            "memory_usage": currentMetrics.memoryUsageMB,
            "cpu_usage": currentMetrics.cpuUsagePercentage
        ])
        
        logger.error("Error tracked: \(error.localizedDescription) in context: \(context)")
    }
    
    // MARK: - Configuration
    
    private func loadConfiguration() {
        let defaults = UserDefaults.standard
        
        monitoringEnabled = defaults.bool(forKey: "performance_monitoring_enabled", default: true)
        memoryThresholdMB = defaults.double(forKey: "memory_threshold_mb", default: 150)
        cpuThresholdPercentage = defaults.double(forKey: "cpu_threshold_percentage", default: 80)
        frameDropThreshold = defaults.double(forKey: "frame_drop_threshold", default: 16.67)
    }
    
    func saveConfiguration() {
        let defaults = UserDefaults.standard
        
        defaults.set(monitoringEnabled, forKey: "performance_monitoring_enabled")
        defaults.set(memoryThresholdMB, forKey: "memory_threshold_mb")
        defaults.set(cpuThresholdPercentage, forKey: "cpu_threshold_percentage")
        defaults.set(frameDropThreshold, forKey: "frame_drop_threshold")
    }
    
    // MARK: - Reporting
    
    private func generateSessionReport() {
        let report: [String: Any] = [
            "session_duration": sessionMetrics.sessionDuration,
            "total_screen_views": sessionMetrics.totalScreenViews,
            "total_user_interactions": sessionMetrics.totalUserInteractions,
            "total_network_requests": sessionMetrics.totalNetworkRequests,
            "total_errors": sessionMetrics.totalErrors,
            "average_response_time": sessionMetrics.averageResponseTime,
            "crash_count": sessionMetrics.crashCount,
            "memory_peak_mb": sessionMetrics.memoryPeakMB,
            "cpu_peak_percentage": sessionMetrics.cpuPeakPercentage,
            "performance_issues": performanceIssues.count,
            "overall_score": currentMetrics.overallScore,
            "performance_grade": currentMetrics.performanceGrade
        ]
        
        AnalyticsManager.shared.track("session_ended", properties: report)
        logger.info("Session report generated: \(report)")
    }
    
    func getPerformanceReport() -> [String: Any] {
        return [
            "current_metrics": [
                "memory_usage_mb": currentMetrics.memoryUsageMB,
                "cpu_usage_percentage": currentMetrics.cpuUsagePercentage,
                "average_fps": currentMetrics.averageFPS,
                "frame_drop_count": currentMetrics.frameDropCount,
                "network_latency_ms": currentMetrics.networkLatencyMS,
                "battery_level": currentMetrics.batteryLevel,
                "thermal_state": String(describing: currentMetrics.thermalState),
                "overall_score": currentMetrics.overallScore,
                "performance_grade": currentMetrics.performanceGrade
            ],
            "session_metrics": [
                "session_duration": sessionMetrics.sessionDuration,
                "total_screen_views": sessionMetrics.totalScreenViews,
                "total_user_interactions": sessionMetrics.totalUserInteractions,
                "total_network_requests": sessionMetrics.totalNetworkRequests,
                "total_errors": sessionMetrics.totalErrors,
                "average_response_time": sessionMetrics.averageResponseTime,
                "crash_count": sessionMetrics.crashCount,
                "memory_peak_mb": sessionMetrics.memoryPeakMB,
                "cpu_peak_percentage": sessionMetrics.cpuPeakPercentage
            ],
            "performance_issues": performanceIssues.map { issue in
                [
                    "type": String(describing: issue.type),
                    "severity": String(describing: issue.severity),
                    "message": issue.message,
                    "timestamp": issue.timestamp.timeIntervalSince1970,
                    "metrics": issue.metrics
                ]
            }
        ]
    }
    
    // MARK: - Memory Management
    
    func clearPerformanceData() {
        performanceIssues.removeAll()
        memoryUsageHistory.removeAll()
        cpuUsageHistory.removeAll()
        networkRequestMetrics.removeAll()
        
        // Reset counters
        currentMetrics.frameDropCount = 0
        memoryWarning = false
        
        logger.info("Performance data cleared")
    }
    
    func forceMemoryCleanup() {
        // Force garbage collection and memory cleanup
        clearPerformanceData()
        
        // Suggest system memory cleanup
        DispatchQueue.global(qos: .utility).async {
            // Perform memory-intensive cleanup operations
            autoreleasepool {
                // This would normally contain cleanup code
            }
        }
        
        logger.info("Memory cleanup performed")
    }
}

// MARK: - Performance Dashboard View

struct PerformanceDashboardView: View {
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @State private var showingDetails = false
    @State private var selectedTimeframe: TimeFrame = .lastHour
    
    enum TimeFrame: String, CaseIterable {
        case lastMinute = "Last Minute"
        case lastFiveMinutes = "Last 5 Minutes"
        case lastHour = "Last Hour"
        case session = "Session"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Overall Performance Score
                    AdvancedCard {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Performance Score")
                                    .dynamicTypeSize(18, weight: .semibold)
                                
                                Spacer()
                                
                                Text(performanceMonitor.currentMetrics.performanceGrade)
                                    .dynamicTypeSize(16, weight: .medium)
                                    .foregroundColor(gradeColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(gradeColor.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            AdvancedProgressView(
                                progress: performanceMonitor.currentMetrics.overallScore,
                                total: 100,
                                style: .circular,
                                size: .large,
                                showPercentage: true,
                                animated: true
                            )
                        }
                    }
                    
                    // Current Metrics Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        MetricCard(
                            title: "Memory",
                            value: "\(Int(performanceMonitor.currentMetrics.memoryUsageMB)) MB",
                            icon: "memorychip",
                            color: memoryColor
                        )
                        
                        MetricCard(
                            title: "CPU",
                            value: "\(Int(performanceMonitor.currentMetrics.cpuUsagePercentage))%",
                            icon: "cpu",
                            color: cpuColor
                        )
                        
                        MetricCard(
                            title: "FPS",
                            value: "\(Int(performanceMonitor.currentMetrics.averageFPS))",
                            icon: "speedometer",
                            color: fpsColor
                        )
                        
                        MetricCard(
                            title: "Network",
                            value: "\(Int(performanceMonitor.currentMetrics.networkLatencyMS))ms",
                            icon: "wifi",
                            color: networkColor
                        )
                    }
                    
                    // Performance Issues
                    if !performanceMonitor.performanceIssues.isEmpty {
                        AdvancedCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("Performance Issues", systemImage: "exclamationmark.triangle.fill")
                                        .dynamicTypeSize(16, weight: .semibold)
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                    
                                    Text("\(performanceMonitor.performanceIssues.count)")
                                        .dynamicTypeSize(14, weight: .medium)
                                        .foregroundColor(.secondary)
                                }
                                
                                ForEach(performanceMonitor.performanceIssues.prefix(3)) { issue in
                                    HStack {
                                        Circle()
                                            .fill(issue.severity.color)
                                            .frame(width: 8, height: 8)
                                        
                                        Text(issue.message)
                                            .dynamicTypeSize(14)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text(issue.timestamp, style: .relative)
                                            .dynamicTypeSize(12)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if performanceMonitor.performanceIssues.count > 3 {
                                    Button("View All Issues") {
                                        showingDetails = true
                                    }
                                    .dynamicTypeSize(14, weight: .medium)
                                    .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    
                    // Control Panel
                    AdvancedCard {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Monitoring Controls")
                                    .dynamicTypeSize(16, weight: .semibold)
                                
                                Spacer()
                                
                                AdvancedToggle(
                                    isOn: $performanceMonitor.monitoringEnabled,
                                    title: "",
                                    subtitle: nil,
                                    icon: nil,
                                    style: .minimal,
                                    size: .small
                                )
                            }
                            
                            HStack(spacing: 12) {
                                PremiumButton(
                                    title: "Clear Data",
                                    subtitle: nil,
                                    icon: "trash",
                                    action: {
                                        performanceMonitor.clearPerformanceData()
                                    },
                                    style: .secondary,
                                    size: .medium
                                )
                                
                                PremiumButton(
                                    title: "Memory Cleanup",
                                    subtitle: nil,
                                    icon: "arrow.clockwise",
                                    action: {
                                        performanceMonitor.forceMemoryCleanup()
                                    },
                                    style: .outline,
                                    size: .medium
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Performance")
            .sheet(isPresented: $showingDetails) {
                PerformanceDetailsView()
            }
        }
    }
    
    private var gradeColor: Color {
        switch performanceMonitor.currentMetrics.performanceGrade {
        case "Excellent": return .green
        case "Good": return .blue
        case "Fair": return .yellow
        case "Poor": return .orange
        default: return .red
        }
    }
    
    private var memoryColor: Color {
        performanceMonitor.currentMetrics.memoryUsageMB > performanceMonitor.memoryThresholdMB ? .red : .blue
    }
    
    private var cpuColor: Color {
        performanceMonitor.currentMetrics.cpuUsagePercentage > performanceMonitor.cpuThresholdPercentage ? .red : .green
    }
    
    private var fpsColor: Color {
        performanceMonitor.currentMetrics.averageFPS < 50 ? .red : .green
    }
    
    private var networkColor: Color {
        performanceMonitor.currentMetrics.networkLatencyMS > 500 ? .red : .blue
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        AdvancedCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .dynamicTypeSize(14, weight: .medium)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .dynamicTypeSize(20, weight: .bold)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: 100)
    }
}

private struct PerformanceDetailsView: View {
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Performance Issues") {
                    ForEach(performanceMonitor.performanceIssues) { issue in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Circle()
                                    .fill(issue.severity.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(String(describing: issue.type))
                                    .dynamicTypeSize(14, weight: .medium)
                                
                                Spacer()
                                
                                Text(issue.timestamp, style: .relative)
                                    .dynamicTypeSize(12)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(issue.message)
                                .dynamicTypeSize(13)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Performance Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        // Dismiss sheet
                    }
                }
            }
        }
    }
}
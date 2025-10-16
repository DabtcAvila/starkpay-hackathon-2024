import SwiftUI
import Combine

// MARK: - Advanced App Settings and Configuration System

/// Comprehensive settings manager for StarkPay with advanced features
@MainActor
class AppConfigurationManager: ObservableObject {
    static let shared = AppConfigurationManager()
    
    // MARK: - Published Settings
    
    // Security Settings
    @Published var biometricAuthEnabled = true
    @Published var autoLockDuration: AutoLockDuration = .fiveMinutes
    @Published var requireAuthForPayments = true
    @Published var deviceTrustEnabled = true
    @Published var securityNotificationsEnabled = true
    
    // Privacy Settings
    @Published var analyticsEnabled = false
    @Published var crashReportingEnabled = true
    @Published var personalizedAdsEnabled = false
    @Published var locationTrackingEnabled = false
    @Published var contactSyncEnabled = false
    
    // Notification Settings
    @Published var pushNotificationsEnabled = true
    @Published var paymentNotificationsEnabled = true
    @Published var securityAlertsEnabled = true
    @Published var marketingNotificationsEnabled = false
    @Published var soundEnabled = true
    @Published var vibrationEnabled = true
    @Published var quietHoursEnabled = false
    @Published var quietHoursStart = Calendar.current.date(from: DateComponents(hour: 22)) ?? Date()
    @Published var quietHoursEnd = Calendar.current.date(from: DateComponents(hour: 8)) ?? Date()
    
    // Display Settings
    @Published var appearanceMode: AppearanceMode = .system
    @Published var accentColor: AccentColor = .orange
    @Published var fontSizePreference: FontSizePreference = .medium
    @Published var highContrastEnabled = false
    @Published var reducedMotionEnabled = false
    
    // Payment Settings
    @Published var defaultCurrency: Currency = .eth
    @Published var maxTransactionAmount: Double = 10000
    @Published var autoConfirmSmallPayments = false
    @Published var smallPaymentThreshold: Double = 50
    @Published var transactionHistoryDuration: HistoryDuration = .oneYear
    @Published var gasFeePreference: GasFeePreference = .standard
    
    // Network Settings
    @Published var preferredNetwork: NetworkType = .mainnet
    @Published var customRPCURL: String = ""
    @Published var fallbackNodesEnabled = true
    @Published var maxRetryAttempts: Int = 3
    @Published var requestTimeout: TimeInterval = 30
    
    // Advanced Settings
    @Published var developerMode = false
    @Published var debugLoggingEnabled = false
    @Published var betaFeaturesEnabled = false
    @Published var performanceMonitoringEnabled = true
    @Published var advancedSecurityEnabled = false
    
    // Data & Storage Settings
    @Published var localCacheEnabled = true
    @Published var cacheSize: CacheSize = .medium
    @Published var offlineMode = false
    @Published var autoBackupEnabled = true
    @Published var backupEncryptionEnabled = true
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSettings()
        observeSettings()
        setupDefaultsIfNeeded()
    }
    
    // MARK: - Enums
    
    enum AutoLockDuration: Int, CaseIterable {
        case immediate = 0
        case thirtySeconds = 30
        case oneMinute = 60
        case twoMinutes = 120
        case fiveMinutes = 300
        case fifteenMinutes = 900
        case thirtyMinutes = 1800
        case never = -1
        
        var displayName: String {
            switch self {
            case .immediate: return "Immediately"
            case .thirtySeconds: return "30 seconds"
            case .oneMinute: return "1 minute"
            case .twoMinutes: return "2 minutes"
            case .fiveMinutes: return "5 minutes"
            case .fifteenMinutes: return "15 minutes"
            case .thirtyMinutes: return "30 minutes"
            case .never: return "Never"
            }
        }
    }
    
    enum AppearanceMode: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
            }
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
    
    enum AccentColor: String, CaseIterable {
        case orange = "orange"
        case blue = "blue"
        case green = "green"
        case purple = "purple"
        case red = "red"
        case pink = "pink"
        case indigo = "indigo"
        case teal = "teal"
        
        var color: Color {
            switch self {
            case .orange: return .orange
            case .blue: return .blue
            case .green: return .green
            case .purple: return .purple
            case .red: return .red
            case .pink: return .pink
            case .indigo: return .indigo
            case .teal: return .teal
            }
        }
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    enum FontSizePreference: String, CaseIterable {
        case small = "small"
        case medium = "medium"
        case large = "large"
        case extraLarge = "extraLarge"
        case accessibility = "accessibility"
        
        var multiplier: CGFloat {
            switch self {
            case .small: return 0.85
            case .medium: return 1.0
            case .large: return 1.15
            case .extraLarge: return 1.3
            case .accessibility: return 1.5
            }
        }
        
        var displayName: String {
            switch self {
            case .small: return "Small"
            case .medium: return "Medium"
            case .large: return "Large"
            case .extraLarge: return "Extra Large"
            case .accessibility: return "Accessibility"
            }
        }
    }
    
    enum Currency: String, CaseIterable {
        case eth = "ETH"
        case btc = "BTC"
        case usdc = "USDC"
        case usdt = "USDT"
        case dai = "DAI"
        
        var symbol: String {
            return rawValue
        }
        
        var name: String {
            switch self {
            case .eth: return "Ethereum"
            case .btc: return "Bitcoin"
            case .usdc: return "USD Coin"
            case .usdt: return "Tether"
            case .dai: return "Dai"
            }
        }
    }
    
    enum HistoryDuration: Int, CaseIterable {
        case oneWeek = 7
        case oneMonth = 30
        case threeMonths = 90
        case sixMonths = 180
        case oneYear = 365
        case forever = -1
        
        var displayName: String {
            switch self {
            case .oneWeek: return "1 Week"
            case .oneMonth: return "1 Month"
            case .threeMonths: return "3 Months"
            case .sixMonths: return "6 Months"
            case .oneYear: return "1 Year"
            case .forever: return "Forever"
            }
        }
    }
    
    enum GasFeePreference: String, CaseIterable {
        case slow = "slow"
        case standard = "standard"
        case fast = "fast"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .slow: return "Slow (Lower fees)"
            case .standard: return "Standard"
            case .fast: return "Fast (Higher fees)"
            case .custom: return "Custom"
            }
        }
        
        var priorityMultiplier: Double {
            switch self {
            case .slow: return 0.8
            case .standard: return 1.0
            case .fast: return 1.5
            case .custom: return 1.0
            }
        }
    }
    
    enum NetworkType: String, CaseIterable {
        case mainnet = "mainnet"
        case goerli = "goerli"
        case sepolia = "sepolia"
        case polygon = "polygon"
        case arbitrum = "arbitrum"
        case optimism = "optimism"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .mainnet: return "Ethereum Mainnet"
            case .goerli: return "Goerli Testnet"
            case .sepolia: return "Sepolia Testnet"
            case .polygon: return "Polygon"
            case .arbitrum: return "Arbitrum One"
            case .optimism: return "Optimism"
            case .custom: return "Custom Network"
            }
        }
        
        var isTestnet: Bool {
            switch self {
            case .goerli, .sepolia: return true
            default: return false
            }
        }
    }
    
    enum CacheSize: String, CaseIterable {
        case small = "small"
        case medium = "medium"
        case large = "large"
        case unlimited = "unlimited"
        
        var maxSizeMB: Int {
            switch self {
            case .small: return 50
            case .medium: return 100
            case .large: return 250
            case .unlimited: return -1
            }
        }
        
        var displayName: String {
            switch self {
            case .small: return "50 MB"
            case .medium: return "100 MB"
            case .large: return "250 MB"
            case .unlimited: return "Unlimited"
            }
        }
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        // Load all settings from UserDefaults
        biometricAuthEnabled = userDefaults.bool(forKey: "biometric_auth_enabled", default: true)
        autoLockDuration = AutoLockDuration(rawValue: userDefaults.integer(forKey: "auto_lock_duration")) ?? .fiveMinutes
        requireAuthForPayments = userDefaults.bool(forKey: "require_auth_payments", default: true)
        deviceTrustEnabled = userDefaults.bool(forKey: "device_trust_enabled", default: true)
        securityNotificationsEnabled = userDefaults.bool(forKey: "security_notifications", default: true)
        
        analyticsEnabled = userDefaults.bool(forKey: "analytics_enabled", default: false)
        crashReportingEnabled = userDefaults.bool(forKey: "crash_reporting", default: true)
        personalizedAdsEnabled = userDefaults.bool(forKey: "personalized_ads", default: false)
        locationTrackingEnabled = userDefaults.bool(forKey: "location_tracking", default: false)
        contactSyncEnabled = userDefaults.bool(forKey: "contact_sync", default: false)
        
        pushNotificationsEnabled = userDefaults.bool(forKey: "push_notifications", default: true)
        paymentNotificationsEnabled = userDefaults.bool(forKey: "payment_notifications", default: true)
        securityAlertsEnabled = userDefaults.bool(forKey: "security_alerts", default: true)
        marketingNotificationsEnabled = userDefaults.bool(forKey: "marketing_notifications", default: false)
        soundEnabled = userDefaults.bool(forKey: "sound_enabled", default: true)
        vibrationEnabled = userDefaults.bool(forKey: "vibration_enabled", default: true)
        quietHoursEnabled = userDefaults.bool(forKey: "quiet_hours_enabled", default: false)
        
        appearanceMode = AppearanceMode(rawValue: userDefaults.string(forKey: "appearance_mode") ?? "system") ?? .system
        accentColor = AccentColor(rawValue: userDefaults.string(forKey: "accent_color") ?? "orange") ?? .orange
        fontSizePreference = FontSizePreference(rawValue: userDefaults.string(forKey: "font_size") ?? "medium") ?? .medium
        highContrastEnabled = userDefaults.bool(forKey: "high_contrast", default: false)
        reducedMotionEnabled = userDefaults.bool(forKey: "reduced_motion", default: false)
        
        defaultCurrency = Currency(rawValue: userDefaults.string(forKey: "default_currency") ?? "ETH") ?? .eth
        maxTransactionAmount = userDefaults.double(forKey: "max_transaction_amount", default: 10000)
        autoConfirmSmallPayments = userDefaults.bool(forKey: "auto_confirm_small", default: false)
        smallPaymentThreshold = userDefaults.double(forKey: "small_payment_threshold", default: 50)
        transactionHistoryDuration = HistoryDuration(rawValue: userDefaults.integer(forKey: "history_duration")) ?? .oneYear
        gasFeePreference = GasFeePreference(rawValue: userDefaults.string(forKey: "gas_fee_preference") ?? "standard") ?? .standard
        
        preferredNetwork = NetworkType(rawValue: userDefaults.string(forKey: "preferred_network") ?? "mainnet") ?? .mainnet
        customRPCURL = userDefaults.string(forKey: "custom_rpc_url") ?? ""
        fallbackNodesEnabled = userDefaults.bool(forKey: "fallback_nodes", default: true)
        maxRetryAttempts = userDefaults.integer(forKey: "max_retry_attempts", default: 3)
        requestTimeout = userDefaults.double(forKey: "request_timeout", default: 30)
        
        developerMode = userDefaults.bool(forKey: "developer_mode", default: false)
        debugLoggingEnabled = userDefaults.bool(forKey: "debug_logging", default: false)
        betaFeaturesEnabled = userDefaults.bool(forKey: "beta_features", default: false)
        performanceMonitoringEnabled = userDefaults.bool(forKey: "performance_monitoring", default: true)
        advancedSecurityEnabled = userDefaults.bool(forKey: "advanced_security", default: false)
        
        localCacheEnabled = userDefaults.bool(forKey: "local_cache", default: true)
        cacheSize = CacheSize(rawValue: userDefaults.string(forKey: "cache_size") ?? "medium") ?? .medium
        offlineMode = userDefaults.bool(forKey: "offline_mode", default: false)
        autoBackupEnabled = userDefaults.bool(forKey: "auto_backup", default: true)
        backupEncryptionEnabled = userDefaults.bool(forKey: "backup_encryption", default: true)
    }
    
    private func observeSettings() {
        // Observe all published properties and save to UserDefaults when changed
        $biometricAuthEnabled
            .sink { self.userDefaults.set($0, forKey: "biometric_auth_enabled") }
            .store(in: &cancellables)
        
        $autoLockDuration
            .sink { self.userDefaults.set($0.rawValue, forKey: "auto_lock_duration") }
            .store(in: &cancellables)
        
        $requireAuthForPayments
            .sink { self.userDefaults.set($0, forKey: "require_auth_payments") }
            .store(in: &cancellables)
        
        $deviceTrustEnabled
            .sink { self.userDefaults.set($0, forKey: "device_trust_enabled") }
            .store(in: &cancellables)
        
        $securityNotificationsEnabled
            .sink { self.userDefaults.set($0, forKey: "security_notifications") }
            .store(in: &cancellables)
        
        $analyticsEnabled
            .sink { self.userDefaults.set($0, forKey: "analytics_enabled") }
            .store(in: &cancellables)
        
        $crashReportingEnabled
            .sink { self.userDefaults.set($0, forKey: "crash_reporting") }
            .store(in: &cancellables)
        
        $personalizedAdsEnabled
            .sink { self.userDefaults.set($0, forKey: "personalized_ads") }
            .store(in: &cancellables)
        
        $locationTrackingEnabled
            .sink { self.userDefaults.set($0, forKey: "location_tracking") }
            .store(in: &cancellables)
        
        $contactSyncEnabled
            .sink { self.userDefaults.set($0, forKey: "contact_sync") }
            .store(in: &cancellables)
        
        $pushNotificationsEnabled
            .sink { self.userDefaults.set($0, forKey: "push_notifications") }
            .store(in: &cancellables)
        
        $paymentNotificationsEnabled
            .sink { self.userDefaults.set($0, forKey: "payment_notifications") }
            .store(in: &cancellables)
        
        $securityAlertsEnabled
            .sink { self.userDefaults.set($0, forKey: "security_alerts") }
            .store(in: &cancellables)
        
        $marketingNotificationsEnabled
            .sink { self.userDefaults.set($0, forKey: "marketing_notifications") }
            .store(in: &cancellables)
        
        $soundEnabled
            .sink { self.userDefaults.set($0, forKey: "sound_enabled") }
            .store(in: &cancellables)
        
        $vibrationEnabled
            .sink { self.userDefaults.set($0, forKey: "vibration_enabled") }
            .store(in: &cancellables)
        
        $quietHoursEnabled
            .sink { self.userDefaults.set($0, forKey: "quiet_hours_enabled") }
            .store(in: &cancellables)
        
        $appearanceMode
            .sink { self.userDefaults.set($0.rawValue, forKey: "appearance_mode") }
            .store(in: &cancellables)
        
        $accentColor
            .sink { self.userDefaults.set($0.rawValue, forKey: "accent_color") }
            .store(in: &cancellables)
        
        $fontSizePreference
            .sink { self.userDefaults.set($0.rawValue, forKey: "font_size") }
            .store(in: &cancellables)
        
        $highContrastEnabled
            .sink { self.userDefaults.set($0, forKey: "high_contrast") }
            .store(in: &cancellables)
        
        $reducedMotionEnabled
            .sink { self.userDefaults.set($0, forKey: "reduced_motion") }
            .store(in: &cancellables)
        
        $defaultCurrency
            .sink { self.userDefaults.set($0.rawValue, forKey: "default_currency") }
            .store(in: &cancellables)
        
        $maxTransactionAmount
            .sink { self.userDefaults.set($0, forKey: "max_transaction_amount") }
            .store(in: &cancellables)
        
        $autoConfirmSmallPayments
            .sink { self.userDefaults.set($0, forKey: "auto_confirm_small") }
            .store(in: &cancellables)
        
        $smallPaymentThreshold
            .sink { self.userDefaults.set($0, forKey: "small_payment_threshold") }
            .store(in: &cancellables)
        
        $transactionHistoryDuration
            .sink { self.userDefaults.set($0.rawValue, forKey: "history_duration") }
            .store(in: &cancellables)
        
        $gasFeePreference
            .sink { self.userDefaults.set($0.rawValue, forKey: "gas_fee_preference") }
            .store(in: &cancellables)
        
        $preferredNetwork
            .sink { self.userDefaults.set($0.rawValue, forKey: "preferred_network") }
            .store(in: &cancellables)
        
        $customRPCURL
            .sink { self.userDefaults.set($0, forKey: "custom_rpc_url") }
            .store(in: &cancellables)
        
        $fallbackNodesEnabled
            .sink { self.userDefaults.set($0, forKey: "fallback_nodes") }
            .store(in: &cancellables)
        
        $maxRetryAttempts
            .sink { self.userDefaults.set($0, forKey: "max_retry_attempts") }
            .store(in: &cancellables)
        
        $requestTimeout
            .sink { self.userDefaults.set($0, forKey: "request_timeout") }
            .store(in: &cancellables)
        
        $developerMode
            .sink { self.userDefaults.set($0, forKey: "developer_mode") }
            .store(in: &cancellables)
        
        $debugLoggingEnabled
            .sink { self.userDefaults.set($0, forKey: "debug_logging") }
            .store(in: &cancellables)
        
        $betaFeaturesEnabled
            .sink { self.userDefaults.set($0, forKey: "beta_features") }
            .store(in: &cancellables)
        
        $performanceMonitoringEnabled
            .sink { self.userDefaults.set($0, forKey: "performance_monitoring") }
            .store(in: &cancellables)
        
        $advancedSecurityEnabled
            .sink { self.userDefaults.set($0, forKey: "advanced_security") }
            .store(in: &cancellables)
        
        $localCacheEnabled
            .sink { self.userDefaults.set($0, forKey: "local_cache") }
            .store(in: &cancellables)
        
        $cacheSize
            .sink { self.userDefaults.set($0.rawValue, forKey: "cache_size") }
            .store(in: &cancellables)
        
        $offlineMode
            .sink { self.userDefaults.set($0, forKey: "offline_mode") }
            .store(in: &cancellables)
        
        $autoBackupEnabled
            .sink { self.userDefaults.set($0, forKey: "auto_backup") }
            .store(in: &cancellables)
        
        $backupEncryptionEnabled
            .sink { self.userDefaults.set($0, forKey: "backup_encryption") }
            .store(in: &cancellables)
    }
    
    private func setupDefaultsIfNeeded() {
        // Set up default values if this is first launch
        if userDefaults.object(forKey: "first_launch") == nil {
            userDefaults.set(true, forKey: "first_launch")
            
            // Apply default settings for new users
            biometricAuthEnabled = true
            requireAuthForPayments = true
            pushNotificationsEnabled = true
            securityAlertsEnabled = true
            performanceMonitoringEnabled = true
            
            // Save defaults
            userDefaults.synchronize()
        }
    }
    
    // MARK: - Configuration Helpers
    
    func resetToDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        userDefaults.removePersistentDomain(forName: domain)
        userDefaults.synchronize()
        
        // Reload default settings
        loadSettings()
        setupDefaultsIfNeeded()
    }
    
    func exportSettings() -> [String: Any] {
        // Export all settings as dictionary for backup
        var settings: [String: Any] = [:]
        
        settings["biometric_auth_enabled"] = biometricAuthEnabled
        settings["auto_lock_duration"] = autoLockDuration.rawValue
        settings["require_auth_payments"] = requireAuthForPayments
        settings["appearance_mode"] = appearanceMode.rawValue
        settings["accent_color"] = accentColor.rawValue
        settings["font_size"] = fontSizePreference.rawValue
        settings["default_currency"] = defaultCurrency.rawValue
        settings["gas_fee_preference"] = gasFeePreference.rawValue
        settings["preferred_network"] = preferredNetwork.rawValue
        
        return settings
    }
    
    func importSettings(_ settings: [String: Any]) {
        // Import settings from dictionary
        if let biometricAuth = settings["biometric_auth_enabled"] as? Bool {
            biometricAuthEnabled = biometricAuth
        }
        
        if let autoLock = settings["auto_lock_duration"] as? Int,
           let autoLockEnum = AutoLockDuration(rawValue: autoLock) {
            autoLockDuration = autoLockEnum
        }
        
        if let requireAuth = settings["require_auth_payments"] as? Bool {
            requireAuthForPayments = requireAuth
        }
        
        if let appearance = settings["appearance_mode"] as? String,
           let appearanceEnum = AppearanceMode(rawValue: appearance) {
            appearanceMode = appearanceEnum
        }
        
        if let accent = settings["accent_color"] as? String,
           let accentEnum = AccentColor(rawValue: accent) {
            accentColor = accentEnum
        }
        
        // ... continue for other settings
    }
    
    func validateSettings() -> [String] {
        var validationErrors: [String] = []
        
        // Validate max transaction amount
        if maxTransactionAmount <= 0 {
            validationErrors.append("Maximum transaction amount must be greater than 0")
        }
        
        // Validate small payment threshold
        if smallPaymentThreshold < 0 || smallPaymentThreshold > maxTransactionAmount {
            validationErrors.append("Small payment threshold must be between 0 and maximum transaction amount")
        }
        
        // Validate custom RPC URL if using custom network
        if preferredNetwork == .custom && customRPCURL.isEmpty {
            validationErrors.append("Custom RPC URL is required when using custom network")
        }
        
        // Validate retry attempts
        if maxRetryAttempts < 1 || maxRetryAttempts > 10 {
            validationErrors.append("Maximum retry attempts must be between 1 and 10")
        }
        
        // Validate request timeout
        if requestTimeout < 5 || requestTimeout > 300 {
            validationErrors.append("Request timeout must be between 5 and 300 seconds")
        }
        
        return validationErrors
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return bool(forKey: key)
    }
    
    func integer(forKey key: String, default defaultValue: Int) -> Int {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return integer(forKey: key)
    }
    
    func double(forKey key: String, default defaultValue: Double) -> Double {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return double(forKey: key)
    }
}

// MARK: - Settings Views

struct AppSettingsView: View {
    @StateObject private var configManager = AppConfigurationManager.shared
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    @State private var selectedSection: SettingsSection = .security
    @State private var showingResetAlert = false
    @State private var showingValidationErrors = false
    @State private var validationErrors: [String] = []
    
    enum SettingsSection: String, CaseIterable {
        case security = "Security"
        case privacy = "Privacy"
        case notifications = "Notifications"
        case display = "Display"
        case payment = "Payment"
        case network = "Network"
        case advanced = "Advanced"
        case data = "Data & Storage"
        
        var icon: String {
            switch self {
            case .security: return "shield.fill"
            case .privacy: return "eye.slash.fill"
            case .notifications: return "bell.fill"
            case .display: return "paintbrush.fill"
            case .payment: return "creditcard.fill"
            case .network: return "wifi"
            case .advanced: return "gearshape.2.fill"
            case .data: return "internaldrive.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // Sidebar
                List(SettingsSection.allCases, id: \.self, selection: $selectedSection) { section in
                    NavigationLink(value: section) {
                        Label(section.rawValue, systemImage: section.icon)
                    }
                }
                .navigationTitle("Settings")
                .frame(minWidth: 200)
                
                // Detail view
                Group {
                    switch selectedSection {
                    case .security:
                        SecuritySettingsView()
                    case .privacy:
                        PrivacySettingsView()
                    case .notifications:
                        NotificationSettingsView()
                    case .display:
                        DisplaySettingsView()
                    case .payment:
                        PaymentSettingsView()
                    case .network:
                        NetworkSettingsView()
                    case .advanced:
                        AdvancedSettingsView()
                    case .data:
                        DataStorageSettingsView()
                    }
                }
                .navigationTitle(selectedSection.rawValue)
                .frame(minWidth: 400)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu("Options") {
                            Button("Validate Settings") {
                                validateCurrentSettings()
                            }
                            
                            Button("Export Settings") {
                                exportSettings()
                            }
                            
                            Button("Import Settings") {
                                importSettings()
                            }
                            
                            Divider()
                            
                            Button("Reset to Defaults") {
                                showingResetAlert = true
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .environmentObject(configManager)
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                configManager.resetToDefaults()
                HapticManager.shared.warning()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
        .alert("Validation Errors", isPresented: $showingValidationErrors) {
            Button("OK") { }
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
    }
    
    private func validateCurrentSettings() {
        validationErrors = configManager.validateSettings()
        if !validationErrors.isEmpty {
            showingValidationErrors = true
            HapticManager.shared.error()
        } else {
            HapticManager.shared.success()
            // Show success message
        }
    }
    
    private func exportSettings() {
        let settings = configManager.exportSettings()
        // Implement export functionality
        HapticManager.shared.success()
    }
    
    private func importSettings() {
        // Implement import functionality
        HapticManager.shared.success()
    }
}

// MARK: - Individual Settings Views (Placeholders)

private struct SecuritySettingsView: View {
    @EnvironmentObject var configManager: AppConfigurationManager
    
    var body: some View {
        Form {
            Section("Authentication") {
                AdvancedToggle(
                    isOn: $configManager.biometricAuthEnabled,
                    title: "Biometric Authentication",
                    subtitle: "Use Face ID or Touch ID",
                    icon: "faceid"
                )
                
                AdvancedToggle(
                    isOn: $configManager.requireAuthForPayments,
                    title: "Require Authentication for Payments",
                    subtitle: "Additional security for transactions",
                    icon: "lock.fill"
                )
            }
            
            Section("Auto-Lock") {
                Picker("Auto-Lock Duration", selection: $configManager.autoLockDuration) {
                    ForEach(AppConfigurationManager.AutoLockDuration.allCases, id: \.self) { duration in
                        Text(duration.displayName).tag(duration)
                    }
                }
            }
        }
        .padding()
    }
}

private struct PrivacySettingsView: View {
    @EnvironmentObject var configManager: AppConfigurationManager
    
    var body: some View {
        Form {
            Section("Data Collection") {
                AdvancedToggle(
                    isOn: $configManager.analyticsEnabled,
                    title: "Analytics",
                    subtitle: "Help improve the app",
                    icon: "chart.bar.fill"
                )
                
                AdvancedToggle(
                    isOn: $configManager.crashReportingEnabled,
                    title: "Crash Reporting",
                    subtitle: "Automatically send crash reports",
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
        .padding()
    }
}

private struct NotificationSettingsView: View {
    @EnvironmentObject var configManager: AppConfigurationManager
    
    var body: some View {
        Form {
            Section("Notifications") {
                AdvancedToggle(
                    isOn: $configManager.pushNotificationsEnabled,
                    title: "Push Notifications",
                    subtitle: "Receive notifications",
                    icon: "bell.fill"
                )
                
                AdvancedToggle(
                    isOn: $configManager.paymentNotificationsEnabled,
                    title: "Payment Notifications",
                    subtitle: "Alerts for transactions",
                    icon: "creditcard.fill"
                )
            }
        }
        .padding()
    }
}

private struct DisplaySettingsView: View {
    @EnvironmentObject var configManager: AppConfigurationManager
    
    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $configManager.appearanceMode) {
                    ForEach(AppConfigurationManager.AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                
                Picker("Accent Color", selection: $configManager.accentColor) {
                    ForEach(AppConfigurationManager.AccentColor.allCases, id: \.self) { color in
                        Label(color.displayName, systemImage: "circle.fill")
                            .foregroundColor(color.color)
                            .tag(color)
                    }
                }
            }
        }
        .padding()
    }
}

private struct PaymentSettingsView: View {
    @EnvironmentObject var configManager: AppConfigurationManager
    
    var body: some View {
        Form {
            Section("Default Settings") {
                Picker("Default Currency", selection: $configManager.defaultCurrency) {
                    ForEach(AppConfigurationManager.Currency.allCases, id: \.self) { currency in
                        Text("\(currency.name) (\(currency.symbol))").tag(currency)
                    }
                }
            }
        }
        .padding()
    }
}

private struct NetworkSettingsView: View {
    @EnvironmentObject var configManager: AppConfigurationManager
    
    var body: some View {
        Form {
            Section("Network") {
                Picker("Preferred Network", selection: $configManager.preferredNetwork) {
                    ForEach(AppConfigurationManager.NetworkType.allCases, id: \.self) { network in
                        Text(network.displayName).tag(network)
                    }
                }
            }
        }
        .padding()
    }
}

private struct AdvancedSettingsView: View {
    @EnvironmentObject var configManager: AppConfigurationManager
    
    var body: some View {
        Form {
            Section("Developer Options") {
                AdvancedToggle(
                    isOn: $configManager.developerMode,
                    title: "Developer Mode",
                    subtitle: "Enable advanced features",
                    icon: "hammer.fill"
                )
                
                AdvancedToggle(
                    isOn: $configManager.debugLoggingEnabled,
                    title: "Debug Logging",
                    subtitle: "Detailed log output",
                    icon: "doc.text.fill"
                )
            }
        }
        .padding()
    }
}

private struct DataStorageSettingsView: View {
    @EnvironmentObject var configManager: AppConfigurationManager
    
    var body: some View {
        Form {
            Section("Storage") {
                Picker("Cache Size", selection: $configManager.cacheSize) {
                    ForEach(AppConfigurationManager.CacheSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                
                AdvancedToggle(
                    isOn: $configManager.autoBackupEnabled,
                    title: "Auto Backup",
                    subtitle: "Automatically backup data",
                    icon: "icloud.fill"
                )
            }
        }
        .padding()
    }
}
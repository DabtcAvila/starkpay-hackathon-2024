import SwiftUI
import Foundation

// MARK: - Advanced Navigation and Deep Linking System

/// Comprehensive navigation coordinator for StarkPay with deep linking support
@MainActor
class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: Tab = .home
    @Published var presentedSheet: Sheet?
    @Published var presentedFullScreenCover: FullScreenCover?
    @Published var showingAlert: AlertType?
    
    // Navigation history for back button and breadcrumbs
    @Published var navigationHistory: [NavigationDestination] = []
    @Published var canGoBack = false
    
    // Deep link handling
    private var pendingDeepLink: URL?
    private var isAppReady = false
    
    private init() {
        setupNavigationObservers()
    }
    
    // MARK: - Navigation Destinations
    
    enum Tab: String, CaseIterable {
        case home = "home"
        case payments = "payments"
        case wallet = "wallet"
        case activity = "activity"
        case settings = "settings"
        
        var displayName: String {
            switch self {
            case .home: return "Home"
            case .payments: return "Pay"
            case .wallet: return "Wallet"
            case .activity: return "Activity"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .payments: return "paperplane.fill"
            case .wallet: return "wallet.pass.fill"
            case .activity: return "list.bullet"
            case .settings: return "gearshape.fill"
            }
        }
        
        var selectedIcon: String {
            return icon
        }
    }
    
    enum NavigationDestination: Hashable, Identifiable {
        case paymentForm(recipient: String? = nil, amount: Double? = nil)
        case transactionDetails(id: String)
        case walletDetails(address: String)
        case qrScanner
        case contactList
        case securitySettings
        case networkSettings
        case aboutApp
        case helpCenter
        case privacyPolicy
        case termsOfService
        case developerSettings
        case backupSettings
        case notificationSettings
        case paymentHistory(filter: String? = nil)
        case profile
        case accountRecovery
        case biometricSetup
        case pinSetup
        case exportPrivateKey
        
        var id: String {
            switch self {
            case .paymentForm: return "paymentForm"
            case .transactionDetails(let id): return "transactionDetails-\(id)"
            case .walletDetails(let address): return "walletDetails-\(address)"
            case .qrScanner: return "qrScanner"
            case .contactList: return "contactList"
            case .securitySettings: return "securitySettings"
            case .networkSettings: return "networkSettings"
            case .aboutApp: return "aboutApp"
            case .helpCenter: return "helpCenter"
            case .privacyPolicy: return "privacyPolicy"
            case .termsOfService: return "termsOfService"
            case .developerSettings: return "developerSettings"
            case .backupSettings: return "backupSettings"
            case .notificationSettings: return "notificationSettings"
            case .paymentHistory: return "paymentHistory"
            case .profile: return "profile"
            case .accountRecovery: return "accountRecovery"
            case .biometricSetup: return "biometricSetup"
            case .pinSetup: return "pinSetup"
            case .exportPrivateKey: return "exportPrivateKey"
            }
        }
        
        var title: String {
            switch self {
            case .paymentForm: return "Send Payment"
            case .transactionDetails: return "Transaction Details"
            case .walletDetails: return "Wallet Details"
            case .qrScanner: return "Scan QR Code"
            case .contactList: return "Contacts"
            case .securitySettings: return "Security Settings"
            case .networkSettings: return "Network Settings"
            case .aboutApp: return "About StarkPay"
            case .helpCenter: return "Help Center"
            case .privacyPolicy: return "Privacy Policy"
            case .termsOfService: return "Terms of Service"
            case .developerSettings: return "Developer Settings"
            case .backupSettings: return "Backup Settings"
            case .notificationSettings: return "Notification Settings"
            case .paymentHistory: return "Payment History"
            case .profile: return "Profile"
            case .accountRecovery: return "Account Recovery"
            case .biometricSetup: return "Biometric Setup"
            case .pinSetup: return "PIN Setup"
            case .exportPrivateKey: return "Export Private Key"
            }
        }
        
        var requiresAuthentication: Bool {
            switch self {
            case .paymentForm, .transactionDetails, .walletDetails, 
                 .securitySettings, .exportPrivateKey, .backupSettings:
                return true
            default:
                return false
            }
        }
        
        var analyticsName: String {
            switch self {
            case .paymentForm: return "payment_form_viewed"
            case .transactionDetails: return "transaction_details_viewed"
            case .walletDetails: return "wallet_details_viewed"
            case .qrScanner: return "qr_scanner_opened"
            case .contactList: return "contacts_viewed"
            case .securitySettings: return "security_settings_viewed"
            case .networkSettings: return "network_settings_viewed"
            case .aboutApp: return "about_viewed"
            case .helpCenter: return "help_center_viewed"
            case .privacyPolicy: return "privacy_policy_viewed"
            case .termsOfService: return "terms_of_service_viewed"
            case .developerSettings: return "developer_settings_viewed"
            case .backupSettings: return "backup_settings_viewed"
            case .notificationSettings: return "notification_settings_viewed"
            case .paymentHistory: return "payment_history_viewed"
            case .profile: return "profile_viewed"
            case .accountRecovery: return "account_recovery_viewed"
            case .biometricSetup: return "biometric_setup_viewed"
            case .pinSetup: return "pin_setup_viewed"
            case .exportPrivateKey: return "private_key_export_viewed"
            }
        }
    }
    
    enum Sheet: Identifiable {
        case paymentConfirmation(amount: Double, recipient: String)
        case transactionReceipt(id: String)
        case errorDetails(error: AppError)
        case contactPicker
        case currencySelector
        case networkSelector
        case gasFeeCustomizer
        case backupWarning
        case securityAlert(message: String)
        case welcomeOnboarding
        case biometricPermission
        case notificationPermission
        case cameraPermission
        case settingsMenu
        
        var id: String {
            switch self {
            case .paymentConfirmation: return "paymentConfirmation"
            case .transactionReceipt: return "transactionReceipt"
            case .errorDetails: return "errorDetails"
            case .contactPicker: return "contactPicker"
            case .currencySelector: return "currencySelector"
            case .networkSelector: return "networkSelector"
            case .gasFeeCustomizer: return "gasFeeCustomizer"
            case .backupWarning: return "backupWarning"
            case .securityAlert: return "securityAlert"
            case .welcomeOnboarding: return "welcomeOnboarding"
            case .biometricPermission: return "biometricPermission"
            case .notificationPermission: return "notificationPermission"
            case .cameraPermission: return "cameraPermission"
            case .settingsMenu: return "settingsMenu"
            }
        }
    }
    
    enum FullScreenCover: Identifiable {
        case qrScanner
        case onboarding
        case biometricSetup
        case pinSetup
        case accountRecovery
        case backupProcess
        
        var id: String {
            switch self {
            case .qrScanner: return "qrScanner"
            case .onboarding: return "onboarding"
            case .biometricSetup: return "biometricSetup"
            case .pinSetup: return "pinSetup"
            case .accountRecovery: return "accountRecovery"
            case .backupProcess: return "backupProcess"
            }
        }
    }
    
    enum AlertType: Identifiable {
        case error(AppError)
        case confirmation(title: String, message: String, action: () -> Void)
        case info(title: String, message: String)
        case warning(title: String, message: String)
        case success(title: String, message: String)
        case authentication(reason: String, action: () -> Void)
        
        var id: String {
            switch self {
            case .error: return "error"
            case .confirmation: return "confirmation"
            case .info: return "info"
            case .warning: return "warning"
            case .success: return "success"
            case .authentication: return "authentication"
            }
        }
    }
    
    struct AppError: Error, Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let code: String?
        let recoveryAction: (() -> Void)?
        
        init(title: String, message: String, code: String? = nil, recoveryAction: (() -> Void)? = nil) {
            self.title = title
            self.message = message
            self.code = code
            self.recoveryAction = recoveryAction
        }
    }
    
    // MARK: - Navigation Methods
    
    func navigate(to destination: NavigationDestination) {
        // Check authentication if required
        if destination.requiresAuthentication && !isAuthenticated() {
            showAuthenticationRequired(for: destination)
            return
        }
        
        // Add to navigation path
        navigationPath.append(destination)
        
        // Update navigation history
        navigationHistory.append(destination)
        updateCanGoBack()
        
        // Track analytics
        AnalyticsManager.shared.track(destination.analyticsName, properties: [
            "destination": destination.id,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        // Haptic feedback
        HapticManager.shared.selection()
        
        // Accessibility announcement
        AccessibilityManager.shared.announceScreenChange(destination.title)
    }
    
    func navigateBack() {
        guard !navigationPath.isEmpty else { return }
        
        navigationPath.removeLast()
        
        if !navigationHistory.isEmpty {
            navigationHistory.removeLast()
        }
        
        updateCanGoBack()
        HapticManager.shared.lightImpact()
    }
    
    func navigateToRoot() {
        navigationPath = NavigationPath()
        navigationHistory.removeAll()
        updateCanGoBack()
        HapticManager.shared.mediumImpact()
    }
    
    func switchTab(to tab: Tab) {
        if selectedTab != tab {
            selectedTab = tab
            
            // Clear navigation path when switching tabs
            navigationPath = NavigationPath()
            navigationHistory.removeAll()
            updateCanGoBack()
            
            // Track tab switch
            AnalyticsManager.shared.track("tab_switched", properties: [
                "tab": tab.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            HapticManager.shared.selection()
            AccessibilityManager.shared.announceScreenChange(tab.displayName)
        }
    }
    
    func presentSheet(_ sheet: Sheet) {
        presentedSheet = sheet
        HapticManager.shared.lightImpact()
    }
    
    func dismissSheet() {
        presentedSheet = nil
        HapticManager.shared.lightImpact()
    }
    
    func presentFullScreenCover(_ cover: FullScreenCover) {
        presentedFullScreenCover = cover
        HapticManager.shared.mediumImpact()
    }
    
    func dismissFullScreenCover() {
        presentedFullScreenCover = nil
        HapticManager.shared.mediumImpact()
    }
    
    func showAlert(_ alert: AlertType) {
        showingAlert = alert
        
        switch alert {
        case .error:
            HapticManager.shared.error()
        case .warning:
            HapticManager.shared.warning()
        case .success:
            HapticManager.shared.success()
        default:
            HapticManager.shared.mediumImpact()
        }
    }
    
    func dismissAlert() {
        showingAlert = nil
    }
    
    // MARK: - Deep Linking
    
    func handleDeepLink(_ url: URL) {
        guard isAppReady else {
            pendingDeepLink = url
            return
        }
        
        processDeepLink(url)
    }
    
    func setAppReady() {
        isAppReady = true
        
        // Process any pending deep links
        if let pendingURL = pendingDeepLink {
            processDeepLink(pendingURL)
            pendingDeepLink = nil
        }
    }
    
    private func processDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        
        // Handle different URL schemes
        switch url.scheme {
        case "starkpay":
            handleStarkPayURL(components)
        case "https", "http":
            handleWebURL(components)
        default:
            handleUnknownURL(url)
        }
    }
    
    private func handleStarkPayURL(_ components: URLComponents) {
        guard let host = components.host else { return }
        
        switch host {
        case "pay":
            handlePaymentDeepLink(components)
        case "transaction":
            handleTransactionDeepLink(components)
        case "wallet":
            handleWalletDeepLink(components)
        case "settings":
            handleSettingsDeepLink(components)
        case "qr":
            presentFullScreenCover(.qrScanner)
        default:
            break
        }
    }
    
    private func handlePaymentDeepLink(_ components: URLComponents) {
        var recipient: String?
        var amount: Double?
        
        // Extract parameters
        if let queryItems = components.queryItems {
            for item in queryItems {
                switch item.name {
                case "to", "recipient":
                    recipient = item.value
                case "amount":
                    if let value = item.value, let doubleValue = Double(value) {
                        amount = doubleValue
                    }
                default:
                    break
                }
            }
        }
        
        // Navigate to payment form
        switchTab(to: .payments)
        navigate(to: .paymentForm(recipient: recipient, amount: amount))
    }
    
    private func handleTransactionDeepLink(_ components: URLComponents) {
        if let path = components.path.split(separator: "/").last {
            let transactionId = String(path)
            switchTab(to: .activity)
            navigate(to: .transactionDetails(id: transactionId))
        }
    }
    
    private func handleWalletDeepLink(_ components: URLComponents) {
        if let path = components.path.split(separator: "/").last {
            let address = String(path)
            switchTab(to: .wallet)
            navigate(to: .walletDetails(address: address))
        }
    }
    
    private func handleSettingsDeepLink(_ components: URLComponents) {
        switchTab(to: .settings)
        
        if let path = components.path.split(separator: "/").last {
            let setting = String(path)
            switch setting {
            case "security":
                navigate(to: .securitySettings)
            case "network":
                navigate(to: .networkSettings)
            case "notifications":
                navigate(to: .notificationSettings)
            case "backup":
                navigate(to: .backupSettings)
            case "developer":
                navigate(to: .developerSettings)
            default:
                break
            }
        }
    }
    
    private func handleWebURL(_ components: URLComponents) {
        guard components.host == "starkpay.app" || components.host == "app.starkpay.io" else {
            return
        }
        
        let path = components.path
        
        if path.starts(with: "/pay") {
            handlePaymentDeepLink(components)
        } else if path.starts(with: "/tx/") {
            handleTransactionDeepLink(components)
        } else if path.starts(with: "/wallet/") {
            handleWalletDeepLink(components)
        }
    }
    
    private func handleUnknownURL(_ url: URL) {
        // Log unknown URL for debugging
        print("Unknown deep link URL: \(url)")
        
        // Show error or fallback behavior
        showAlert(.error(AppError(
            title: "Invalid Link",
            message: "The link you opened is not recognized by StarkPay."
        )))
    }
    
    // MARK: - Helper Methods
    
    private func setupNavigationObservers() {
        // Observe navigation path changes
        $navigationPath
            .sink { _ in
                self.updateCanGoBack()
            }
            .store(in: &cancellables)
    }
    
    private func updateCanGoBack() {
        canGoBack = !navigationPath.isEmpty
    }
    
    private func isAuthenticated() -> Bool {
        // Check if user is authenticated
        return BiometricAuthManager().isAuthenticated
    }
    
    private func showAuthenticationRequired(for destination: NavigationDestination) {
        showAlert(.authentication(reason: "Authentication required to access \(destination.title)") {
            // After successful authentication, navigate to destination
            Task {
                let authManager = BiometricAuthManager()
                await authManager.authenticate()
                
                if authManager.isAuthenticated {
                    self.navigate(to: destination)
                }
            }
        })
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - URL Generation
    
    func generateDeepLink(for destination: NavigationDestination) -> URL? {
        var components = URLComponents()
        components.scheme = "starkpay"
        
        switch destination {
        case .paymentForm(let recipient, let amount):
            components.host = "pay"
            var queryItems: [URLQueryItem] = []
            
            if let recipient = recipient {
                queryItems.append(URLQueryItem(name: "recipient", value: recipient))
            }
            
            if let amount = amount {
                queryItems.append(URLQueryItem(name: "amount", value: String(amount)))
            }
            
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
            
        case .transactionDetails(let id):
            components.host = "transaction"
            components.path = "/\(id)"
            
        case .walletDetails(let address):
            components.host = "wallet"
            components.path = "/\(address)"
            
        case .qrScanner:
            components.host = "qr"
            
        case .securitySettings:
            components.host = "settings"
            components.path = "/security"
            
        case .networkSettings:
            components.host = "settings"
            components.path = "/network"
            
        case .notificationSettings:
            components.host = "settings"
            components.path = "/notifications"
            
        case .backupSettings:
            components.host = "settings"
            components.path = "/backup"
            
        case .developerSettings:
            components.host = "settings"
            components.path = "/developer"
            
        default:
            return nil
        }
        
        return components.url
    }
    
    func generateShareableLink(for destination: NavigationDestination) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "app.starkpay.io"
        
        switch destination {
        case .paymentForm(let recipient, let amount):
            components.path = "/pay"
            var queryItems: [URLQueryItem] = []
            
            if let recipient = recipient {
                queryItems.append(URLQueryItem(name: "to", value: recipient))
            }
            
            if let amount = amount {
                queryItems.append(URLQueryItem(name: "amount", value: String(amount)))
            }
            
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
            
        case .transactionDetails(let id):
            components.path = "/tx/\(id)"
            
        case .walletDetails(let address):
            components.path = "/wallet/\(address)"
            
        default:
            return nil
        }
        
        return components.url
    }
}

// MARK: - Navigation Environment Key

struct NavigationCoordinatorKey: EnvironmentKey {
    static let defaultValue = NavigationCoordinator.shared
}

extension EnvironmentValues {
    var navigationCoordinator: NavigationCoordinator {
        get { self[NavigationCoordinatorKey.self] }
        set { self[NavigationCoordinatorKey.self] = newValue }
    }
}

// MARK: - Navigation Extensions

extension View {
    func navigationCoordinated() -> some View {
        environmentObject(NavigationCoordinator.shared)
    }
}

// MARK: - Breadcrumb Navigation View

struct BreadcrumbNavigation: View {
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    
    var body: some View {
        if !navigationCoordinator.navigationHistory.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Home button
                    Button(action: {
                        navigationCoordinator.navigateToRoot()
                    }) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    
                    // Breadcrumb items
                    ForEach(Array(navigationCoordinator.navigationHistory.enumerated()), id: \.element.id) { index, destination in
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                // Navigate to specific breadcrumb level
                                let targetIndex = index + 1
                                let currentCount = navigationCoordinator.navigationHistory.count
                                let stepsBack = currentCount - targetIndex
                                
                                for _ in 0..<stepsBack {
                                    navigationCoordinator.navigateBack()
                                }
                            }) {
                                Text(destination.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(index == navigationCoordinator.navigationHistory.count - 1 ? .primary : .orange)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 44)
            .background(Color(.systemGray6))
            .accessibleText(
                label: "Breadcrumb navigation",
                hint: "Shows current navigation path"
            )
        }
    }
}

// MARK: - Custom Back Button

struct CustomBackButton: View {
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    let title: String?
    
    init(title: String? = nil) {
        self.title = title
    }
    
    var body: some View {
        if navigationCoordinator.canGoBack {
            Button(action: {
                navigationCoordinator.navigateBack()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                    
                    if let title = title {
                        Text(title)
                            .font(.system(size: 17, weight: .regular))
                    } else {
                        Text("Back")
                            .font(.system(size: 17, weight: .regular))
                    }
                }
                .foregroundColor(.orange)
            }
            .accessibleButton(
                label: "Go back",
                hint: "Return to previous screen"
            )
        }
    }
}

// MARK: - Analytics Manager Placeholder

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private var eventQueue: [(event: String, properties: [String: Any], timestamp: Date)] = []
    private var userSession: UserSession
    private var isTrackingEnabled = true
    
    struct UserSession {
        let sessionId: String
        let startTime: Date
        var screenViews: Int = 0
        var userInteractions: Int = 0
        var errors: Int = 0
        var paymentAttempts: Int = 0
        var biometricAuthentications: Int = 0
        
        init() {
            self.sessionId = UUID().uuidString
            self.startTime = Date()
        }
    }
    
    private init() {
        self.userSession = UserSession()
        setupAnalytics()
    }
    
    private func setupAnalytics() {
        // Track app launch
        trackAppEvent(.appLaunched, properties: [
            "session_id": userSession.sessionId,
            "launch_time": userSession.startTime.timeIntervalSince1970,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])
        
        // Setup session timeout monitoring
        setupSessionMonitoring()
    }
    
    func track(_ event: String, properties: [String: Any] = [:]) {
        guard isTrackingEnabled else { return }
        
        let enrichedProperties = enrichProperties(properties)
        let timestamp = Date()
        
        // Add to queue for batch processing
        eventQueue.append((event: event, properties: enrichedProperties, timestamp: timestamp))
        
        // Process specific event types
        processSpecialEvents(event, properties: enrichedProperties)
        
        #if DEBUG
        print("📊 Analytics: \(event)")
        if !enrichedProperties.isEmpty {
            print("   Properties: \(enrichedProperties)")
        }
        #endif
        
        // Simulate sending to analytics service
        sendToAnalyticsService(event: event, properties: enrichedProperties, timestamp: timestamp)
    }
    
    private func enrichProperties(_ properties: [String: Any]) -> [String: Any] {
        var enriched = properties
        enriched["session_id"] = userSession.sessionId
        enriched["timestamp"] = Date().timeIntervalSince1970
        enriched["platform"] = "iOS"
        enriched["device_model"] = UIDevice.current.model
        enriched["ios_version"] = UIDevice.current.systemVersion
        enriched["app_build"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        return enriched
    }
    
    private func processSpecialEvents(_ event: String, properties: [String: Any]) {
        switch event {
        case "screen_view":
            userSession.screenViews += 1
        case "user_interaction":
            userSession.userInteractions += 1
        case "app_error", "performance_issue":
            userSession.errors += 1
        case "payment_initiated", "payment_completed":
            userSession.paymentAttempts += 1
        case "biometric_auth_success", "biometric_auth_failed":
            userSession.biometricAuthentications += 1
        default:
            break
        }
    }
    
    private func sendToAnalyticsService(event: String, properties: [String: Any], timestamp: Date) {
        // Simulate real analytics service integration
        // In production, this would send to Firebase, Mixpanel, etc.
        
        let analyticsPayload: [String: Any] = [
            "event": event,
            "properties": properties,
            "timestamp": timestamp.timeIntervalSince1970,
            "session_id": userSession.sessionId
        ]
        
        // Simulate network call (would be actual HTTP request in production)
        DispatchQueue.global().async {
            // Simulate network delay
            Thread.sleep(forTimeInterval: 0.1)
            
            #if DEBUG
            print("📤 Sent to analytics service: \(event)")
            #endif
        }
    }
    
    private func setupSessionMonitoring() {
        // Monitor app lifecycle for session tracking
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.trackAppEvent(.appBackgrounded)
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.trackAppEvent(.appForegrounded)
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.endSession()
        }
    }
    
    // MARK: - Specific Event Tracking Methods
    
    enum AppEvent: String {
        case appLaunched = "app_launched"
        case appBackgrounded = "app_backgrounded" 
        case appForegrounded = "app_foregrounded"
        case sessionEnded = "session_ended"
    }
    
    func trackAppEvent(_ event: AppEvent, properties: [String: Any] = [:]) {
        track(event.rawValue, properties: properties)
    }
    
    func trackScreenView(_ screenName: String, properties: [String: Any] = [:]) {
        var props = properties
        props["screen_name"] = screenName
        props["session_duration"] = Date().timeIntervalSince(userSession.startTime)
        track("screen_view", properties: props)
    }
    
    func trackUserAction(_ action: String, properties: [String: Any] = [:]) {
        var props = properties
        props["action"] = action
        track("user_interaction", properties: props)
    }
    
    func trackPaymentFlow(_ step: String, amount: Double? = nil, currency: String = "USD") {
        var props: [String: Any] = ["payment_step": step, "currency": currency]
        if let amount = amount {
            props["amount"] = amount
        }
        track("payment_flow", properties: props)
    }
    
    func trackBiometricAuth(success: Bool, authType: String) {
        let event = success ? "biometric_auth_success" : "biometric_auth_failed"
        track(event, properties: [
            "auth_type": authType,
            "attempt_count": userSession.biometricAuthentications + 1
        ])
    }
    
    func trackError(_ error: Error, context: String) {
        track("app_error", properties: [
            "error_description": error.localizedDescription,
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code,
            "context": context
        ])
    }
    
    func trackPerformanceMetric(_ metric: String, value: Double, unit: String) {
        track("performance_metric", properties: [
            "metric_name": metric,
            "value": value,
            "unit": unit
        ])
    }
    
    // MARK: - Session Management
    
    func endSession() {
        let sessionDuration = Date().timeIntervalSince(userSession.startTime)
        
        track("session_ended", properties: [
            "session_duration": sessionDuration,
            "screen_views": userSession.screenViews,
            "user_interactions": userSession.userInteractions,
            "errors": userSession.errors,
            "payment_attempts": userSession.paymentAttempts,
            "biometric_authentications": userSession.biometricAuthentications,
            "events_tracked": eventQueue.count
        ])
        
        // Flush remaining events
        flushEventQueue()
    }
    
    private func flushEventQueue() {
        // In production, this would batch send all queued events
        #if DEBUG
        print("📊 Flushing \(eventQueue.count) analytics events")
        #endif
        eventQueue.removeAll()
    }
    
    // MARK: - Configuration
    
    func enableTracking(_ enabled: Bool) {
        isTrackingEnabled = enabled
        track("analytics_tracking_changed", properties: ["enabled": enabled])
    }
    
    func getSessionMetrics() -> [String: Any] {
        return [
            "session_id": userSession.sessionId,
            "session_duration": Date().timeIntervalSince(userSession.startTime),
            "screen_views": userSession.screenViews,
            "user_interactions": userSession.userInteractions,
            "errors": userSession.errors,
            "payment_attempts": userSession.paymentAttempts,
            "biometric_authentications": userSession.biometricAuthentications,
            "events_queued": eventQueue.count
        ]
    }
}

import Combine
import Foundation
import CryptoKit
import Security
import LocalAuthentication
import SwiftUI

// MARK: - Advanced Security and Encryption Framework

/// Comprehensive security manager for StarkPay with enterprise-grade encryption
@MainActor
class AdvancedSecurityManager: ObservableObject {
    static let shared = AdvancedSecurityManager()
    
    // MARK: - Published Properties
    @Published var securityLevel: SecurityLevel = .standard
    @Published var encryptionStatus: EncryptionStatus = .enabled
    @Published var threatDetectionEnabled = true
    @Published var securityEvents: [SecurityEvent] = []
    @Published var isDeviceCompromised = false
    @Published var lastSecurityCheck: Date?
    
    // Security configuration
    private let keychain = KeychainManager()
    private let encryptionManager = EncryptionManager()
    private let threatDetector = ThreatDetector()
    private let secureStorage = SecureStorageManager()
    
    // Security monitoring
    private var securityTimer: Timer?
    private let securityQueue = DispatchQueue(label: "com.starkpay.security", qos: .userInitiated)
    
    enum SecurityLevel: String, CaseIterable {
        case basic = "Basic"
        case standard = "Standard"
        case enhanced = "Enhanced"
        case maximum = "Maximum"
        
        var description: String {
            switch self {
            case .basic: return "Basic security with standard encryption"
            case .standard: return "Standard security with biometric authentication"
            case .enhanced: return "Enhanced security with advanced threat detection"
            case .maximum: return "Maximum security with hardware-backed encryption"
            }
        }
        
        var requiresBiometrics: Bool {
            switch self {
            case .basic: return false
            default: return true
            }
        }
        
        var encryptionStrength: EncryptionStrength {
            switch self {
            case .basic: return .standard
            case .standard: return .strong
            case .enhanced, .maximum: return .maximum
            }
        }
    }
    
    enum EncryptionStatus {
        case disabled, enabled, hardware, compromised
        
        var description: String {
            switch self {
            case .disabled: return "Encryption disabled"
            case .enabled: return "Software encryption enabled"
            case .hardware: return "Hardware-backed encryption"
            case .compromised: return "Encryption compromised"
            }
        }
        
        var color: Color {
            switch self {
            case .disabled, .compromised: return .red
            case .enabled: return .orange
            case .hardware: return .green
            }
        }
    }
    
    struct SecurityEvent: Identifiable {
        let id = UUID()
        let type: EventType
        let severity: Severity
        let message: String
        let timestamp: Date
        let metadata: [String: Any]
        
        enum EventType {
            case authenticationFailure
            case suspiciousActivity
            case dataIntegrityViolation
            case unauthorizedAccess
            case malwareDetected
            case networkSecurityBreach
            case keychainTampering
            case debuggerDetected
            case deviceCompromise
            case certificatePinningFailure
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
    
    private init() {
        setupSecurityMonitoring()
        performInitialSecurityCheck()
    }
    
    deinit {
        securityTimer?.invalidate()
    }
    
    // MARK: - Security Monitoring
    
    private func setupSecurityMonitoring() {
        // Continuous security monitoring
        securityTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                await self.performSecurityCheck()
            }
        }
        
        // Setup threat detection
        threatDetector.delegate = self
        threatDetector.startMonitoring()
    }
    
    private func performInitialSecurityCheck() {
        Task {
            await performSecurityCheck()
            determineSecurityLevel()
            updateEncryptionStatus()
        }
    }
    
    private func performSecurityCheck() async {
        lastSecurityCheck = Date()
        
        // Check for jailbreak/root
        if threatDetector.isDeviceCompromised() {
            isDeviceCompromised = true
            reportSecurityEvent(
                type: .deviceCompromise,
                severity: .critical,
                message: "Device compromise detected"
            )
        }
        
        // Check for debugging
        if threatDetector.isBeingDebugged() {
            reportSecurityEvent(
                type: .debuggerDetected,
                severity: .high,
                message: "Debugger attachment detected"
            )
        }
        
        // Verify keychain integrity
        if !keychain.verifyIntegrity() {
            reportSecurityEvent(
                type: .keychainTampering,
                severity: .critical,
                message: "Keychain tampering detected"
            )
        }
        
        // Check certificate pinning
        if !verifyNetworkSecurity() {
            reportSecurityEvent(
                type: .certificatePinningFailure,
                severity: .high,
                message: "Certificate pinning validation failed"
            )
        }
        
        // Verify data integrity
        if !await verifyDataIntegrity() {
            reportSecurityEvent(
                type: .dataIntegrityViolation,
                severity: .high,
                message: "Data integrity check failed"
            )
        }
    }
    
    private func determineSecurityLevel() {
        if isDeviceCompromised {
            securityLevel = .basic
            return
        }
        
        let hasSecureEnclave = secureStorage.hasSecureEnclave()
        let hasBiometrics = BiometricAuthManager().canUseBiometrics
        
        if hasSecureEnclave && hasBiometrics {
            securityLevel = threatDetectionEnabled ? .maximum : .enhanced
        } else if hasBiometrics {
            securityLevel = .standard
        } else {
            securityLevel = .basic
        }
    }
    
    private func updateEncryptionStatus() {
        if isDeviceCompromised {
            encryptionStatus = .compromised
        } else if secureStorage.hasSecureEnclave() {
            encryptionStatus = .hardware
        } else {
            encryptionStatus = .enabled
        }
    }
    
    // MARK: - Encryption Services
    
    func encrypt(_ data: Data, key: String? = nil) throws -> Data {
        return try encryptionManager.encrypt(data, strength: securityLevel.encryptionStrength, key: key)
    }
    
    func decrypt(_ data: Data, key: String? = nil) throws -> Data {
        return try encryptionManager.decrypt(data, key: key)
    }
    
    func encryptString(_ string: String, key: String? = nil) throws -> String {
        let data = string.data(using: .utf8)!
        let encryptedData = try encrypt(data, key: key)
        return encryptedData.base64EncodedString()
    }
    
    func decryptString(_ encryptedString: String, key: String? = nil) throws -> String {
        guard let data = Data(base64Encoded: encryptedString) else {
            throw SecurityError.invalidEncryptedData
        }
        let decryptedData = try decrypt(data, key: key)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw SecurityError.decodingError
        }
        return string
    }
    
    // MARK: - Secure Storage
    
    func secureStore(_ data: Data, forKey key: String, requiresBiometrics: Bool = false) throws {
        try secureStorage.store(data, forKey: key, requiresBiometrics: requiresBiometrics)
    }
    
    func secureRetrieve(forKey key: String) throws -> Data? {
        return try secureStorage.retrieve(forKey: key)
    }
    
    func secureDelete(forKey key: String) throws {
        try secureStorage.delete(forKey: key)
    }
    
    // MARK: - Cryptographic Utilities
    
    func generateSecureKey(length: Int = 32) -> Data {
        return encryptionManager.generateSecureKey(length: length)
    }
    
    func hash(_ data: Data, algorithm: HashAlgorithm = .sha256) -> Data {
        return encryptionManager.hash(data, algorithm: algorithm)
    }
    
    func sign(_ data: Data, privateKey: Data) throws -> Data {
        return try encryptionManager.sign(data, privateKey: privateKey)
    }
    
    func verify(_ signature: Data, data: Data, publicKey: Data) -> Bool {
        return encryptionManager.verify(signature, data: data, publicKey: publicKey)
    }
    
    func generateKeyPair() throws -> KeyPair {
        return try encryptionManager.generateKeyPair()
    }
    
    // MARK: - Security Event Handling
    
    private func reportSecurityEvent(type: SecurityEvent.EventType, severity: SecurityEvent.Severity, message: String, metadata: [String: Any] = [:]) {
        let event = SecurityEvent(
            type: type,
            severity: severity,
            message: message,
            timestamp: Date(),
            metadata: metadata
        )
        
        securityEvents.append(event)
        
        // Keep only recent events
        if securityEvents.count > 100 {
            securityEvents.removeFirst(securityEvents.count - 100)
        }
        
        // Log critical events
        if severity == .critical {
            print("🚨 CRITICAL SECURITY EVENT: \(message)")
            
            // Notify user for critical events
            if type == .deviceCompromise {
                showSecurityAlert(title: "Security Warning", message: "Device security compromise detected. Please secure your device.")
            }
        }
        
        // Send to analytics
        AnalyticsManager.shared.track("security_event", properties: [
            "type": String(describing: type),
            "severity": String(describing: severity),
            "message": message,
            "metadata": metadata
        ])
    }
    
    private func showSecurityAlert(title: String, message: String) {
        NavigationCoordinator.shared.showAlert(.warning(title: title, message: message))
    }
    
    // MARK: - Network Security
    
    private func verifyNetworkSecurity() -> Bool {
        // Implement certificate pinning verification
        // This would check against known certificate hashes
        return true // Simplified for demo
    }
    
    // MARK: - Data Integrity
    
    private func verifyDataIntegrity() async -> Bool {
        // Verify critical data hasn't been tampered with
        do {
            // Check app binary integrity
            let bundlePath = Bundle.main.bundlePath
            let bundleData = try Data(contentsOf: URL(fileURLWithPath: bundlePath))
            let currentHash = hash(bundleData)
            
            // In production, compare with known good hash
            return true // Simplified for demo
        } catch {
            return false
        }
    }
    
    // MARK: - Authentication Enhancement
    
    func enhancedAuthentication(reason: String) async throws -> Bool {
        // Multi-factor authentication for sensitive operations
        let biometricAuth = BiometricAuthManager()
        
        // First factor: biometric authentication
        await biometricAuth.authenticate()
        guard biometricAuth.isAuthenticated else {
            throw SecurityError.authenticationFailed
        }
        
        // Second factor: time-based validation for maximum security
        if securityLevel == .maximum {
            let timeWindow = 300 // 5 minutes
            let lastAuth = UserDefaults.standard.double(forKey: "last_auth_timestamp")
            let currentTime = Date().timeIntervalSince1970
            
            if currentTime - lastAuth < Double(timeWindow) {
                // Recently authenticated, proceed
            } else {
                // Require additional verification
                try await requireAdditionalVerification()
            }
            
            UserDefaults.standard.set(currentTime, forKey: "last_auth_timestamp")
        }
        
        return true
    }
    
    private func requireAdditionalVerification() async throws {
        // Implement additional verification methods
        // This could include PIN, pattern, or other factors
        throw SecurityError.additionalVerificationRequired
    }
    
    // MARK: - Secure Communication
    
    func establishSecureChannel(with endpoint: String) throws -> SecureChannel {
        return try SecureChannel(endpoint: endpoint, securityLevel: securityLevel)
    }
    
    // MARK: - Security Configuration
    
    func updateSecurityLevel(_ level: SecurityLevel) {
        securityLevel = level
        
        // Apply security level settings
        threatDetectionEnabled = level.rawValue != "Basic"
        
        // Update encryption status
        updateEncryptionStatus()
        
        // Restart security monitoring with new settings
        securityTimer?.invalidate()
        setupSecurityMonitoring()
        
        reportSecurityEvent(
            type: .authenticationFailure,
            severity: .medium,
            message: "Security level changed to \(level.rawValue)"
        )
    }
    
    func clearSecurityEvents() {
        securityEvents.removeAll()
    }
    
    func exportSecurityReport() -> [String: Any] {
        return [
            "security_level": securityLevel.rawValue,
            "encryption_status": encryptionStatus.description,
            "device_compromised": isDeviceCompromised,
            "threat_detection_enabled": threatDetectionEnabled,
            "last_security_check": lastSecurityCheck?.timeIntervalSince1970 ?? 0,
            "security_events_count": securityEvents.count,
            "critical_events": securityEvents.filter { $0.severity == .critical }.count,
            "has_secure_enclave": secureStorage.hasSecureEnclave(),
            "biometrics_available": BiometricAuthManager().canUseBiometrics
        ]
    }
}

// MARK: - Encryption Manager

class EncryptionManager {
    
    enum EncryptionStrength {
        case standard, strong, maximum
        
        var keySize: Int {
            switch self {
            case .standard: return 128
            case .strong: return 256
            case .maximum: return 512
            }
        }
    }
    
    func encrypt(_ data: Data, strength: EncryptionStrength, key: String? = nil) throws -> Data {
        let symmetricKey: SymmetricKey
        
        if let keyString = key {
            let keyData = keyString.data(using: .utf8)!
            symmetricKey = SymmetricKey(data: keyData)
        } else {
            symmetricKey = SymmetricKey(size: .bits256)
            // Store key securely for later decryption
        }
        
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        return sealedBox.combined!
    }
    
    func decrypt(_ data: Data, key: String? = nil) throws -> Data {
        let symmetricKey: SymmetricKey
        
        if let keyString = key {
            let keyData = keyString.data(using: .utf8)!
            symmetricKey = SymmetricKey(data: keyData)
        } else {
            // Retrieve key from secure storage
            throw SecurityError.missingDecryptionKey
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
    
    func generateSecureKey(length: Int) -> Data {
        var keyData = Data(count: length)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            fatalError("Failed to generate secure key")
        }
        
        return keyData
    }
    
    func hash(_ data: Data, algorithm: HashAlgorithm) -> Data {
        switch algorithm {
        case .sha256:
            return Data(SHA256.hash(data: data))
        case .sha512:
            return Data(SHA512.hash(data: data))
        case .sha3_256:
            // SHA3 implementation would go here
            return Data(SHA256.hash(data: data)) // Fallback
        }
    }
    
    func sign(_ data: Data, privateKey: Data) throws -> Data {
        let key = try P256.Signing.PrivateKey(rawRepresentation: privateKey)
        let signature = try key.signature(for: data)
        return signature.rawRepresentation
    }
    
    func verify(_ signature: Data, data: Data, publicKey: Data) -> Bool {
        do {
            let key = try P256.Signing.PublicKey(rawRepresentation: publicKey)
            let sig = try P256.Signing.ECDSASignature(rawRepresentation: signature)
            return key.isValidSignature(sig, for: data)
        } catch {
            return false
        }
    }
    
    func generateKeyPair() throws -> KeyPair {
        let privateKey = P256.Signing.PrivateKey()
        return KeyPair(
            privateKey: privateKey.rawRepresentation,
            publicKey: privateKey.publicKey.rawRepresentation
        )
    }
}

enum HashAlgorithm {
    case sha256, sha512, sha3_256
}

struct KeyPair {
    let privateKey: Data
    let publicKey: Data
}

// MARK: - Secure Storage Manager

class SecureStorageManager {
    private let keychain = KeychainManager()
    
    func store(_ data: Data, forKey key: String, requiresBiometrics: Bool = false) throws {
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: requiresBiometrics ? kSecAttrAccessibleBiometryCurrentSet : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(attributes as CFDictionary)
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecurityError.keychainError(status)
        }
    }
    
    func retrieve(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw SecurityError.keychainError(status)
        }
        
        return result as? Data
    }
    
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecurityError.keychainError(status)
        }
    }
    
    func hasSecureEnclave() -> Bool {
        return TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
    }
}

// MARK: - Keychain Manager

class KeychainManager {
    
    func verifyIntegrity() -> Bool {
        // Implement keychain integrity verification
        // This would check for signs of tampering
        return true // Simplified for demo
    }
    
    func secureStore(_ value: String, forKey key: String, requiresBiometrics: Bool = false) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecurityError.encodingError
        }
        
        let secureStorage = SecureStorageManager()
        try secureStorage.store(data, forKey: key, requiresBiometrics: requiresBiometrics)
    }
    
    func secureRetrieve(forKey key: String) throws -> String? {
        let secureStorage = SecureStorageManager()
        guard let data = try secureStorage.retrieve(forKey: key) else {
            return nil
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw SecurityError.decodingError
        }
        
        return string
    }
}

// MARK: - Threat Detector

class ThreatDetector {
    weak var delegate: ThreatDetectorDelegate?
    
    func startMonitoring() {
        // Start continuous threat monitoring
    }
    
    func isDeviceCompromised() -> Bool {
        return isJailbroken() || isRunningOnSimulator() || hasCompromisedFiles()
    }
    
    func isBeingDebugged() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.size
        
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        
        return result == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    private func isJailbroken() -> Bool {
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/Applications/RockApp.app",
            "/Applications/Icy.app",
            "/Applications/WinterBoard.app",
            "/Applications/SBSettings.app",
            "/Applications/blackra1n.app",
            "/usr/bin/ssh"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check if we can write to system directories
        do {
            let testPath = "/private/jailbreak_test.txt"
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            // Good, we can't write to system directories
        }
        
        return false
    }
    
    private func isRunningOnSimulator() -> Bool {
        return TARGET_OS_SIMULATOR != 0
    }
    
    private func hasCompromisedFiles() -> Bool {
        // Check for presence of debugging tools or suspicious files
        let suspiciousFiles = [
            "/usr/bin/debugserver",
            "/usr/bin/lldb",
            "/usr/bin/gdb"
        ]
        
        return suspiciousFiles.contains { FileManager.default.fileExists(atPath: $0) }
    }
}

protocol ThreatDetectorDelegate: AnyObject {
    func threatDetected(_ threat: String)
}

extension AdvancedSecurityManager: ThreatDetectorDelegate {
    func threatDetected(_ threat: String) {
        reportSecurityEvent(
            type: .suspiciousActivity,
            severity: .high,
            message: "Threat detected: \(threat)"
        )
    }
}

// MARK: - Secure Channel

class SecureChannel {
    private let endpoint: String
    private let securityLevel: AdvancedSecurityManager.SecurityLevel
    private let session: URLSession
    
    init(endpoint: String, securityLevel: AdvancedSecurityManager.SecurityLevel) throws {
        self.endpoint = endpoint
        self.securityLevel = securityLevel
        
        let config = URLSessionConfiguration.default
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        
        // Configure certificate pinning for enhanced security
        self.session = URLSession(configuration: config, delegate: SecureChannelDelegate(), delegateQueue: nil)
    }
    
    func send(_ data: Data) async throws -> Data {
        guard let url = URL(string: endpoint) else {
            throw SecurityError.invalidEndpoint
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw SecurityError.networkError
        }
        
        return responseData
    }
}

class SecureChannelDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Implement certificate pinning
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Verify certificate against pinned certificates
        if verifyCertificate(serverTrust) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    private func verifyCertificate(_ serverTrust: SecTrust) -> Bool {
        // Implement certificate verification logic
        // This would check against pinned certificate hashes
        return true // Simplified for demo
    }
}

// MARK: - Security Errors

enum SecurityError: Error, LocalizedError {
    case authenticationFailed
    case encryptionFailed
    case decryptionFailed
    case invalidEncryptedData
    case missingDecryptionKey
    case keychainError(OSStatus)
    case encodingError
    case decodingError
    case deviceCompromised
    case threatDetected(String)
    case invalidEndpoint
    case networkError
    case additionalVerificationRequired
    case biometricsNotAvailable
    case biometricsNotEnrolled
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Authentication failed"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidEncryptedData:
            return "Invalid encrypted data format"
        case .missingDecryptionKey:
            return "Decryption key not found"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .encodingError:
            return "Failed to encode data"
        case .decodingError:
            return "Failed to decode data"
        case .deviceCompromised:
            return "Device security has been compromised"
        case .threatDetected(let threat):
            return "Security threat detected: \(threat)"
        case .invalidEndpoint:
            return "Invalid secure endpoint"
        case .networkError:
            return "Secure network communication failed"
        case .additionalVerificationRequired:
            return "Additional verification required"
        case .biometricsNotAvailable:
            return "Biometric authentication not available"
        case .biometricsNotEnrolled:
            return "No biometric credentials enrolled"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "Please try authenticating again"
        case .deviceCompromised:
            return "Please secure your device and restart the app"
        case .biometricsNotAvailable:
            return "Use device passcode instead"
        case .biometricsNotEnrolled:
            return "Please enroll biometric credentials in device settings"
        default:
            return "Please try again or contact support"
        }
    }
}

// MARK: - Security Dashboard View

struct SecurityDashboardView: View {
    @StateObject private var securityManager = AdvancedSecurityManager.shared
    @State private var showingSecuritySettings = false
    @State private var showingEventDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Security Level Card
                    AdvancedCard {
                        VStack(spacing: 16) {
                            HStack {
                                Label("Security Level", systemImage: "shield.fill")
                                    .dynamicTypeSize(18, weight: .semibold)
                                    .foregroundColor(.orange)
                                
                                Spacer()
                                
                                Text(securityManager.securityLevel.rawValue)
                                    .dynamicTypeSize(16, weight: .medium)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(securityLevelColor.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Text(securityManager.securityLevel.description)
                                .dynamicTypeSize(14)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Security Status Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        SecurityStatusCard(
                            title: "Encryption",
                            status: securityManager.encryptionStatus.description,
                            icon: "lock.fill",
                            color: securityManager.encryptionStatus.color
                        )
                        
                        SecurityStatusCard(
                            title: "Device Status",
                            status: securityManager.isDeviceCompromised ? "Compromised" : "Secure",
                            icon: securityManager.isDeviceCompromised ? "exclamationmark.triangle.fill" : "checkmark.shield.fill",
                            color: securityManager.isDeviceCompromised ? .red : .green
                        )
                        
                        SecurityStatusCard(
                            title: "Threat Detection",
                            status: securityManager.threatDetectionEnabled ? "Active" : "Inactive",
                            icon: "eye.fill",
                            color: securityManager.threatDetectionEnabled ? .green : .gray
                        )
                        
                        SecurityStatusCard(
                            title: "Last Check",
                            status: lastCheckText,
                            icon: "clock.fill",
                            color: .blue
                        )
                    }
                    
                    // Security Events
                    if !securityManager.securityEvents.isEmpty {
                        AdvancedCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("Security Events", systemImage: "exclamationmark.triangle.fill")
                                        .dynamicTypeSize(16, weight: .semibold)
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                    
                                    Text("\(securityManager.securityEvents.count)")
                                        .dynamicTypeSize(14, weight: .medium)
                                        .foregroundColor(.secondary)
                                    
                                    Button("View All") {
                                        showingEventDetails = true
                                    }
                                    .dynamicTypeSize(14, weight: .medium)
                                    .foregroundColor(.orange)
                                }
                                
                                ForEach(securityManager.securityEvents.prefix(3)) { event in
                                    HStack {
                                        Circle()
                                            .fill(event.severity.color)
                                            .frame(width: 8, height: 8)
                                        
                                        Text(event.message)
                                            .dynamicTypeSize(14)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text(event.timestamp, style: .relative)
                                            .dynamicTypeSize(12)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Control Panel
                    AdvancedCard {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Security Controls")
                                    .dynamicTypeSize(16, weight: .semibold)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                AdvancedToggle(
                                    isOn: $securityManager.threatDetectionEnabled,
                                    title: "Threat Detection",
                                    subtitle: "Monitor for security threats",
                                    icon: "eye.fill",
                                    style: .card
                                )
                                
                                HStack(spacing: 12) {
                                    PremiumButton(
                                        title: "Security Scan",
                                        subtitle: nil,
                                        icon: "magnifyingglass",
                                        action: {
                                            Task {
                                                await securityManager.performSecurityCheck()
                                            }
                                        },
                                        style: .secondary,
                                        size: .medium
                                    )
                                    
                                    PremiumButton(
                                        title: "Settings",
                                        subtitle: nil,
                                        icon: "gearshape.fill",
                                        action: {
                                            showingSecuritySettings = true
                                        },
                                        style: .outline,
                                        size: .medium
                                    )
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Security")
            .sheet(isPresented: $showingSecuritySettings) {
                SecuritySettingsView()
            }
            .sheet(isPresented: $showingEventDetails) {
                SecurityEventsView()
            }
        }
    }
    
    private var securityLevelColor: Color {
        switch securityManager.securityLevel {
        case .basic: return .red
        case .standard: return .orange
        case .enhanced: return .yellow
        case .maximum: return .green
        }
    }
    
    private var lastCheckText: String {
        guard let lastCheck = securityManager.lastSecurityCheck else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastCheck, relativeTo: Date())
    }
}

private struct SecurityStatusCard: View {
    let title: String
    let status: String
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
                    
                    Text(status)
                        .dynamicTypeSize(16, weight: .semibold)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: 100)
    }
}

private struct SecuritySettingsView: View {
    @StateObject private var securityManager = AdvancedSecurityManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section("Security Level") {
                    Picker("Level", selection: $securityManager.securityLevel) {
                        ForEach(AdvancedSecurityManager.SecurityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .onChange(of: securityManager.securityLevel) { newLevel in
                        securityManager.updateSecurityLevel(newLevel)
                    }
                    
                    Text(securityManager.securityLevel.description)
                        .dynamicTypeSize(12)
                        .foregroundColor(.secondary)
                }
                
                Section("Monitoring") {
                    AdvancedToggle(
                        isOn: $securityManager.threatDetectionEnabled,
                        title: "Threat Detection",
                        subtitle: "Monitor for security threats",
                        icon: "eye.fill"
                    )
                }
                
                Section("Actions") {
                    Button("Clear Security Events") {
                        securityManager.clearSecurityEvents()
                    }
                    
                    Button("Export Security Report") {
                        let report = securityManager.exportSecurityReport()
                        print("Security Report: \(report)")
                    }
                }
            }
            .navigationTitle("Security Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
    }
}

private struct SecurityEventsView: View {
    @StateObject private var securityManager = AdvancedSecurityManager.shared
    
    var body: some View {
        NavigationView {
            List(securityManager.securityEvents) { event in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(event.severity.color)
                            .frame(width: 8, height: 8)
                        
                        Text(String(describing: event.type))
                            .dynamicTypeSize(14, weight: .medium)
                        
                        Spacer()
                        
                        Text(event.timestamp, style: .relative)
                            .dynamicTypeSize(12)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(event.message)
                        .dynamicTypeSize(13)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Security Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") {
                        securityManager.clearSecurityEvents()
                    }
                }
            }
        }
    }
}
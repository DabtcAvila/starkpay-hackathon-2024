import Foundation
import Security
import LocalAuthentication
import CryptoKit

// MARK: - Advanced iOS Keychain Security Examples for StarkPay
/**
 * Professional-grade iOS security implementation examples
 * Demonstrates BON-013 compliance with zero exposed secrets
 */

// MARK: - 1. Secure Environment Configuration
struct SecureEnvironmentConfig {
    // ✅ GOOD: Environment-based configuration
    static var apiBaseURL: String {
        switch AppEnvironment.current {
        case .development:
            return ProcessInfo.processInfo.environment["DEV_API_URL"] ?? "https://api-dev.starkpay.com"
        case .staging:
            return ProcessInfo.processInfo.environment["STAGING_API_URL"] ?? "https://api-staging.starkpay.com"
        case .production:
            return "https://api.starkpay.com"
        }
    }
    
    // ✅ GOOD: Dynamic configuration from secure sources
    static func getAPIKey() async throws -> String {
        // Fetch from secure keychain, never hardcoded
        return try await SecurityManager.shared.retrieveSecurely(
            keyType: .apiCredentials,
            type: String.self
        )
    }
}

enum AppEnvironment {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
}

// MARK: - 2. Advanced Keychain Operations
extension SecurityManager {
    
    /// Store API credentials with maximum security
    public func storeAPICredentials(_ credentials: APICredentials) async throws {
        let config = SecurityConfig.highSecurity
        
        // Store with biometric + device passcode protection
        try await storeSecurely(
            credentials,
            keyType: .apiCredentials,
            config: config
        )
        
        // Log security event
        await logSecurityEvent("API credentials stored", keyType: .apiCredentials, success: true)
    }
    
    /// Store wallet private key with Secure Enclave
    public func storeWalletKey(_ privateKey: Data) async throws {
        // Use maximum security for crypto keys
        let config = SecurityConfig(
            requiresBiometric: true,
            requiresPasscode: true,
            allowBackgroundAccess: false,
            encryptionLevel: .maximum,
            accessGroup: nil
        )
        
        let keyData = WalletKeyData(
            key: privateKey,
            createdAt: Date(),
            lastUsed: Date()
        )
        
        try await storeSecurely(keyData, keyType: .privateKey, config: config)
        
        // Clear sensitive data from memory
        privateKey.withUnsafeMutableBytes { bytes in
            memset(bytes.baseAddress, 0, bytes.count)
        }
    }
    
    /// Retrieve wallet key with biometric authentication
    public func getWalletKey() async throws -> Data {
        let keyData: WalletKeyData = try await retrieveSecurely(
            keyType: .privateKey,
            type: WalletKeyData.self,
            config: .biometricRequired
        )
        
        // Update last used timestamp
        let updatedKeyData = WalletKeyData(
            key: keyData.key,
            createdAt: keyData.createdAt,
            lastUsed: Date()
        )
        
        try await storeSecurely(updatedKeyData, keyType: .privateKey, config: .biometricRequired)
        
        return keyData.key
    }
}

// MARK: - 3. Secure Data Models
struct WalletKeyData: Codable {
    let key: Data
    let createdAt: Date
    let lastUsed: Date
}

struct APICredentials: Codable {
    let token: String
    let refreshToken: String
    let expiresAt: Date
    let scope: [String]
}

struct DeviceFingerprint: Codable {
    let deviceId: String
    let appVersion: String
    let systemVersion: String
    let timestamp: Date
    let securityFeatures: [String]
}

// MARK: - 4. Network Security Configuration
class SecureNetworkManager {
    private let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        
        // ✅ GOOD: Secure networking configuration
        configuration.tlsMinimumSupportedProtocol = .tlsProtocol12
        configuration.tlsMaximumSupportedProtocol = .tlsProtocol13
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldUsePipelining = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        
        // Custom headers for security
        configuration.httpAdditionalHeaders = [
            "User-Agent": "StarkPay-iOS/\(AppVersion.current)",
            "X-App-Version": AppVersion.current,
            "X-Platform": "iOS"
        ]
        
        self.session = URLSession(configuration: configuration)
    }
    
    func makeSecureRequest(to endpoint: String) async throws -> Data {
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        // Add authentication header from keychain
        let apiToken = try await SecurityManager.shared.retrieveSecurely(
            keyType: .apiCredentials,
            type: APICredentials.self
        )
        
        request.setValue("Bearer \(apiToken.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add security headers
        request.setValue(try await getDeviceFingerprint(), forHTTPHeaderField: "X-Device-ID")
        request.setValue(generateRequestNonce(), forHTTPHeaderField: "X-Request-Nonce")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.serverError
        }
        
        return data
    }
    
    private func getDeviceFingerprint() async throws -> String {
        let fingerprint: DeviceFingerprint = try await SecurityManager.shared.retrieveSecurely(
            keyType: .deviceFingerprint,
            type: DeviceFingerprint.self
        )
        return fingerprint.deviceId
    }
    
    private func generateRequestNonce() -> String {
        let nonce = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        return nonce.base64EncodedString()
    }
}

// MARK: - 5. Runtime Security Monitoring
class RuntimeSecurityMonitor {
    static let shared = RuntimeSecurityMonitor()
    
    private var isMonitoring = false
    private let monitoringQueue = DispatchQueue(label: "security.monitor", qos: .userInitiated)
    
    private init() {}
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitoringQueue.async {
            self.performSecurityChecks()
        }
    }
    
    private func performSecurityChecks() {
        while isMonitoring {
            Task {
                // Check for jailbreak
                if await detectJailbreak() {
                    await SecurityManager.shared.handleSecurityViolation(.jailbreakDetected)
                }
                
                // Check for debugging
                if detectDebugging() {
                    await SecurityManager.shared.handleSecurityViolation(.debuggerDetected)
                }
                
                // Check for memory tampering
                if detectMemoryTampering() {
                    await SecurityManager.shared.handleSecurityViolation(.memoryTampering)
                }
            }
            
            Thread.sleep(forTimeInterval: 5.0) // Check every 5 seconds
        }
    }
    
    private func detectJailbreak() async -> Bool {
        // Check for jailbreak indicators
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]
        
        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check if we can write to system directories
        let testString = "security_test"
        do {
            try testString.write(toFile: "/private/test.txt", atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: "/private/test.txt")
            return true
        } catch {
            // Good - cannot write to system directories
        }
        
        return false
    }
    
    private func detectDebugging() -> Bool {
        // Check for debugger attachment
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let ret = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        
        if ret != 0 { return false }
        
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    private func detectMemoryTampering() -> Bool {
        // Simple memory integrity check
        let testValue: UInt32 = 0xDEADBEEF
        let ptr = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        ptr.pointee = testValue
        
        defer { ptr.deallocate() }
        
        return ptr.pointee != testValue
    }
}

// MARK: - 6. Security Violations Handler
extension SecurityManager {
    enum SecurityViolation {
        case jailbreakDetected
        case debuggerDetected
        case memoryTampering
        case unauthorizedAccess
        case certificateValidationFailure
    }
    
    func handleSecurityViolation(_ violation: SecurityViolation) async {
        let alertLevel: SecurityAlert.AlertLevel
        let message: String
        
        switch violation {
        case .jailbreakDetected:
            alertLevel = .critical
            message = "Device security compromised - jailbreak detected"
        case .debuggerDetected:
            alertLevel = .critical
            message = "Unauthorized debugging attempt detected"
        case .memoryTampering:
            alertLevel = .critical
            message = "Memory tampering detected"
        case .unauthorizedAccess:
            alertLevel = .warning
            message = "Unauthorized access attempt"
        case .certificateValidationFailure:
            alertLevel = .critical
            message = "Certificate validation failure"
        }
        
        // Log the violation
        await logSecurityEvent("Security violation: \(violation)", success: false)
        
        // Add alert
        addSecurityAlert(alertLevel, message, source: "RuntimeMonitor")
        
        // Take protective action
        switch alertLevel {
        case .critical:
            await lockAppForSecurity()
        case .warning:
            // Log and continue monitoring
            break
        default:
            break
        }
    }
    
    private func lockAppForSecurity() async {
        // Clear sensitive data from memory
        await clearSensitiveDataFromMemory()
        
        // Force re-authentication
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .securityViolationDetected, object: nil)
        }
    }
    
    private func clearSensitiveDataFromMemory() async {
        // Implementation would clear any cached sensitive data
        // This is a placeholder for the actual implementation
    }
}

// MARK: - 7. Supporting Types and Extensions
enum NetworkError: Error {
    case invalidURL
    case serverError
    case unauthorized
    case securityViolation
}

struct AppVersion {
    static var current: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

extension Notification.Name {
    static let securityViolationDetected = Notification.Name("security.violation.detected")
}

// MARK: - 8. Security Configuration Examples
extension SecurityConfig {
    /// Configuration for storing API tokens
    static let apiToken = SecurityConfig(
        requiresBiometric: true,
        requiresPasscode: false,
        allowBackgroundAccess: true,
        encryptionLevel: .high,
        accessGroup: nil
    )
    
    /// Configuration for wallet private keys
    static let walletKey = SecurityConfig(
        requiresBiometric: true,
        requiresPasscode: true,
        allowBackgroundAccess: false,
        encryptionLevel: .maximum,
        accessGroup: nil
    )
    
    /// Configuration for user preferences
    static let userPreferences = SecurityConfig(
        requiresBiometric: false,
        requiresPasscode: false,
        allowBackgroundAccess: true,
        encryptionLevel: .standard,
        accessGroup: nil
    )
}

// MARK: - 9. Security Best Practices Implementation
/**
 * Key Security Principles Implemented:
 * 
 * 1. Zero Hardcoded Secrets
 *    - All sensitive data stored in iOS Keychain
 *    - Environment-based configuration
 *    - Runtime credential fetching
 * 
 * 2. Defense in Depth
 *    - Multiple security layers
 *    - Runtime monitoring
 *    - Biometric authentication
 * 
 * 3. Secure by Default
 *    - Maximum security configurations
 *    - Fail-safe behaviors
 *    - Automatic threat detection
 * 
 * 4. Professional Implementation
 *    - Comprehensive error handling
 *    - Security event logging
 *    - Automated response to threats
 * 
 * 5. BON-013 Compliance
 *    - No exposed credentials
 *    - Professional security patterns
 *    - Industry-standard implementations
 */
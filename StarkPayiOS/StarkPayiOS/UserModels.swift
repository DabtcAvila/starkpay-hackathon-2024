import Foundation
import SwiftUI

// MARK: - User Registration Models

struct UserRegistration {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let phoneNumber: String?
    let preferredCurrency: String
    let acceptedTerms: Bool
}

struct UserProfile: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let fullName: String
    let username: String
    let phoneNumber: String?
    let profileImageURL: String?
    let preferredCurrency: String
    let isEmailVerified: Bool
    let isPhoneVerified: Bool
    let memberSince: Date
    let lastLoginDate: Date?
    let totalTransactions: Int
    let totalVolume: Double
    let kycStatus: KYCStatus
    let securitySettings: SecuritySettings
    
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    var displayName: String {
        return "\(firstName) \(lastName)"
    }
}

struct SecuritySettings: Codable {
    let biometricEnabled: Bool
    let twoFactorEnabled: Bool
    let transactionLimitsEnabled: Bool
    let notificationsEnabled: Bool
    let privacyMode: Bool
    let sessionTimeout: Int // minutes
    
    static let `default` = SecuritySettings(
        biometricEnabled: true,
        twoFactorEnabled: false,
        transactionLimitsEnabled: true,
        notificationsEnabled: true,
        privacyMode: false,
        sessionTimeout: 30
    )
}

enum KYCStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case pending = "pending"
    case verified = "verified"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .pending: return "Pending Verification"
        case .verified: return "Verified"
        case .rejected: return "Verification Failed"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .notStarted: return .gray
        case .pending: return .orange
        case .verified: return .green
        case .rejected: return .red
        }
    }
    
    var statusIcon: String {
        switch self {
        case .notStarted: return "person.circle"
        case .pending: return "clock.circle"
        case .verified: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }
}

// MARK: - Authentication States

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated(UserProfile)
    case error(String)
}

enum RegistrationStep {
    case welcome
    case personalInfo
    case credentials
    case verification
    case security
    case completed
}

// MARK: - User Storage Models (UserDefaults-based)

struct UserStorage {
    private static let userProfileKey = "user_profile_storage"
    private static let registeredUsersKey = "registered_users_storage"
    private static let currentUserIdKey = "current_user_id"
    
    // Save current user profile
    static func saveCurrentUser(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: userProfileKey)
            UserDefaults.standard.set(profile.id, forKey: currentUserIdKey)
        }
    }
    
    // Load current user profile
    static func loadCurrentUser() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: userProfileKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        return profile
    }
    
    // Save registered users list
    static func saveRegisteredUsers(_ users: [UserProfile]) {
        if let encoded = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encoded, forKey: registeredUsersKey)
        }
    }
    
    // Load registered users list
    static func loadRegisteredUsers() -> [UserProfile] {
        guard let data = UserDefaults.standard.data(forKey: registeredUsersKey),
              let users = try? JSONDecoder().decode([UserProfile].self, from: data) else {
            return []
        }
        return users
    }
    
    // Get current user ID
    static func getCurrentUserId() -> String? {
        return UserDefaults.standard.string(forKey: currentUserIdKey)
    }
    
    // Clear all user data (logout)
    static func clearUserData() {
        UserDefaults.standard.removeObject(forKey: userProfileKey)
        UserDefaults.standard.removeObject(forKey: currentUserIdKey)
    }
    
    // Check if user exists by email
    static func userExists(email: String) -> Bool {
        let users = loadRegisteredUsers()
        return users.contains { $0.email.lowercased() == email.lowercased() }
    }
    
    // Find user by email
    static func findUser(email: String) -> UserProfile? {
        let users = loadRegisteredUsers()
        return users.first { $0.email.lowercased() == email.lowercased() }
    }
    
    // Add new registered user
    static func addUser(_ profile: UserProfile) {
        var users = loadRegisteredUsers()
        users.append(profile)
        saveRegisteredUsers(users)
    }
    
    // Update user profile
    static func updateUser(_ profile: UserProfile) {
        var users = loadRegisteredUsers()
        if let index = users.firstIndex(where: { $0.id == profile.id }) {
            users[index] = profile
            saveRegisteredUsers(users)
        }
        
        // Update current user if it's the same
        if getCurrentUserId() == profile.id {
            saveCurrentUser(profile)
        }
    }
    
    // Get user statistics
    static func getUserStatistics() -> (totalUsers: Int, verifiedUsers: Int, activeUsers: Int) {
        let users = loadRegisteredUsers()
        let totalUsers = users.count
        let verifiedUsers = users.filter { $0.kycStatus == .verified }.count
        let activeUsers = users.filter { user in
            guard let lastLogin = user.lastLoginDate else { return false }
            return Date().timeIntervalSince(lastLogin) < 86400 * 7 // Active within 7 days
        }.count
        
        return (totalUsers, verifiedUsers, activeUsers)
    }
}

// MARK: - Demo Users

struct DemoUsers {
    static func createDemoUsers() -> [UserProfile] {
        return [
            UserProfile(
                id: "demo_user_1",
                email: "david@starkpay.com",
                firstName: "David",
                lastName: "Hernandez",
                fullName: "David Hernandez",
                username: "david_starkpay",
                phoneNumber: "+1-555-0123",
                profileImageURL: nil,
                preferredCurrency: "USD",
                isEmailVerified: true,
                isPhoneVerified: true,
                memberSince: Date().addingTimeInterval(-86400 * 30), // 30 days ago
                lastLoginDate: Date(),
                totalTransactions: 47,
                totalVolume: 2847.63,
                kycStatus: .verified,
                securitySettings: SecuritySettings.default
            ),
            UserProfile(
                id: "demo_user_2",
                email: "alice@crypto.com",
                firstName: "Alice",
                lastName: "Chen",
                fullName: "Alice Chen",
                username: "alice_crypto",
                phoneNumber: "+1-555-0124",
                profileImageURL: nil,
                preferredCurrency: "USD",
                isEmailVerified: true,
                isPhoneVerified: false,
                memberSince: Date().addingTimeInterval(-86400 * 15), // 15 days ago
                lastLoginDate: Date().addingTimeInterval(-3600), // 1 hour ago
                totalTransactions: 23,
                totalVolume: 1456.32,
                kycStatus: .verified,
                securitySettings: SecuritySettings.default
            ),
            UserProfile(
                id: "demo_user_3",
                email: "bob@defi.com",
                firstName: "Bob",
                lastName: "Wilson",
                fullName: "Bob Wilson",
                username: "bob_defi",
                phoneNumber: nil,
                profileImageURL: nil,
                preferredCurrency: "USD",
                isEmailVerified: true,
                isPhoneVerified: false,
                memberSince: Date().addingTimeInterval(-86400 * 7), // 7 days ago
                lastLoginDate: Date().addingTimeInterval(-86400), // 1 day ago
                totalTransactions: 12,
                totalVolume: 687.45,
                kycStatus: .pending,
                securitySettings: SecuritySettings(
                    biometricEnabled: false,
                    twoFactorEnabled: false,
                    transactionLimitsEnabled: true,
                    notificationsEnabled: false,
                    privacyMode: true,
                    sessionTimeout: 15
                )
            ),
            UserProfile(
                id: "demo_user_4",
                email: "sarah@web3.io",
                firstName: "Sarah",
                lastName: "Johnson",
                fullName: "Sarah Johnson",
                username: "sarah_web3",
                phoneNumber: "+1-555-0126",
                profileImageURL: nil,
                preferredCurrency: "USD",
                isEmailVerified: true,
                isPhoneVerified: true,
                memberSince: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                lastLoginDate: Date().addingTimeInterval(-7200), // 2 hours ago
                totalTransactions: 8,
                totalVolume: 234.67,
                kycStatus: .notStarted,
                securitySettings: SecuritySettings.default
            ),
            UserProfile(
                id: "demo_user_5",
                email: "mike@stark.net",
                firstName: "Mike",
                lastName: "Rodriguez",
                fullName: "Mike Rodriguez",
                username: "mike_stark",
                phoneNumber: "+1-555-0127",
                profileImageURL: nil,
                preferredCurrency: "EUR",
                isEmailVerified: false,
                isPhoneVerified: false,
                memberSince: Date().addingTimeInterval(-86400), // 1 day ago
                lastLoginDate: Date().addingTimeInterval(-10800), // 3 hours ago
                totalTransactions: 3,
                totalVolume: 89.23,
                kycStatus: .notStarted,
                securitySettings: SecuritySettings(
                    biometricEnabled: true,
                    twoFactorEnabled: true,
                    transactionLimitsEnabled: true,
                    notificationsEnabled: true,
                    privacyMode: false,
                    sessionTimeout: 60
                )
            )
        ]
    }
    
    static func setupDemoUsersIfNeeded() {
        let users = UserStorage.loadRegisteredUsers()
        if users.isEmpty {
            let demoUsers = createDemoUsers()
            UserStorage.saveRegisteredUsers(demoUsers)
            
            // Set first demo user as current user for testing
            if let firstUser = demoUsers.first {
                UserStorage.saveCurrentUser(firstUser)
            }
        }
    }
}

// MARK: - Validation Helpers

extension UserRegistration {
    var isValid: Bool {
        return isValidEmail && 
               isValidPassword && 
               !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               acceptedTerms
    }
    
    private var isValidEmail: Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private var isValidPassword: Bool {
        return password.count >= 8 && password.range(of: "[A-Z]", options: .regularExpression) != nil
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if !isValidEmail {
            errors.append("Please enter a valid email address")
        }
        
        if !isValidPassword {
            errors.append("Password must be at least 8 characters with 1 uppercase letter")
        }
        
        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("First name is required")
        }
        
        if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Last name is required")
        }
        
        if !acceptedTerms {
            errors.append("You must accept the Terms of Service")
        }
        
        return errors
    }
}
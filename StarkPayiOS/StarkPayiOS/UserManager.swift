import Foundation
import SwiftUI
import LocalAuthentication

// MARK: - User Manager Service

@MainActor
class UserManager: ObservableObject {
    @Published var authState: AuthenticationState = .unauthenticated
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var registrationStep: RegistrationStep = .welcome
    
    // Registration state
    @Published var registrationData = UserRegistration(
        email: "",
        password: "",
        firstName: "",
        lastName: "",
        phoneNumber: nil,
        preferredCurrency: "USD",
        acceptedTerms: false
    )
    
    // Login state
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var rememberLogin = true
    
    init() {
        // Set up demo users on first launch
        DemoUsers.setupDemoUsersIfNeeded()
        
        // Check for existing user session
        loadCurrentUser()
    }
    
    // MARK: - Session Management
    
    func loadCurrentUser() {
        if let user = UserStorage.loadCurrentUser() {
            currentUser = user
            authState = .authenticated(user)
        } else {
            authState = .unauthenticated
        }
    }
    
    func logout() {
        UserStorage.clearUserData()
        currentUser = nil
        authState = .unauthenticated
        clearLoginData()
        HapticManager.shared.mediumImpact()
    }
    
    private func clearLoginData() {
        loginEmail = ""
        loginPassword = ""
        rememberLogin = true
        errorMessage = nil
    }
    
    // MARK: - User Registration
    
    func startRegistration() {
        registrationStep = .personalInfo
        clearRegistrationData()
        HapticManager.shared.lightImpact()
    }
    
    func nextRegistrationStep() {
        switch registrationStep {
        case .welcome:
            registrationStep = .personalInfo
        case .personalInfo:
            if validatePersonalInfo() {
                registrationStep = .credentials
            }
        case .credentials:
            if validateCredentials() {
                registrationStep = .verification
            }
        case .verification:
            registrationStep = .security
        case .security:
            completeRegistration()
        case .completed:
            break
        }
        HapticManager.shared.lightImpact()
    }
    
    func previousRegistrationStep() {
        switch registrationStep {
        case .welcome:
            break
        case .personalInfo:
            registrationStep = .welcome
        case .credentials:
            registrationStep = .personalInfo
        case .verification:
            registrationStep = .credentials
        case .security:
            registrationStep = .verification
        case .completed:
            registrationStep = .security
        }
        HapticManager.shared.lightImpact()
    }
    
    private func validatePersonalInfo() -> Bool {
        let trimmedFirst = registrationData.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = registrationData.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedFirst.isEmpty || trimmedLast.isEmpty {
            errorMessage = "Please enter your first and last name"
            return false
        }
        
        errorMessage = nil
        return true
    }
    
    private func validateCredentials() -> Bool {
        // Check if email already exists
        if UserStorage.userExists(email: registrationData.email) {
            errorMessage = "An account with this email already exists"
            return false
        }
        
        // Validate registration data
        let errors = registrationData.validationErrors
        if !errors.isEmpty {
            errorMessage = errors.first
            return false
        }
        
        errorMessage = nil
        return true
    }
    
    func completeRegistration() {
        isLoading = true
        errorMessage = nil
        
        // Simulate registration delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.processRegistration()
        }
    }
    
    private func processRegistration() {
        // Create new user profile
        let newUser = UserProfile(
            id: UUID().uuidString,
            email: registrationData.email,
            firstName: registrationData.firstName,
            lastName: registrationData.lastName,
            fullName: "\(registrationData.firstName) \(registrationData.lastName)",
            username: generateUsername(from: registrationData.firstName, registrationData.lastName),
            phoneNumber: registrationData.phoneNumber,
            profileImageURL: nil,
            preferredCurrency: registrationData.preferredCurrency,
            isEmailVerified: false, // Would need email verification flow
            isPhoneVerified: false,
            memberSince: Date(),
            lastLoginDate: Date(),
            totalTransactions: 0,
            totalVolume: 0.0,
            kycStatus: .notStarted,
            securitySettings: SecuritySettings.default
        )
        
        // Save user
        UserStorage.addUser(newUser)
        UserStorage.saveCurrentUser(newUser)
        
        // Update state
        currentUser = newUser
        authState = .authenticated(newUser)
        registrationStep = .completed
        isLoading = false
        
        // Success feedback
        HapticManager.shared.success()
        
        // Clear registration data
        clearRegistrationData()
    }
    
    private func generateUsername(from firstName: String, _ lastName: String) -> String {
        let baseUsername = "\(firstName.lowercased())_\(lastName.lowercased())"
        let cleanUsername = baseUsername.replacingOccurrences(of: " ", with: "_")
        
        // Add random suffix to ensure uniqueness
        let randomSuffix = Int.random(in: 100...999)
        return "\(cleanUsername)\(randomSuffix)"
    }
    
    private func clearRegistrationData() {
        registrationData = UserRegistration(
            email: "",
            password: "",
            firstName: "",
            lastName: "",
            phoneNumber: nil,
            preferredCurrency: "USD",
            acceptedTerms: false
        )
    }
    
    // MARK: - User Login
    
    func login() {
        isLoading = true
        errorMessage = nil
        
        // Simulate login delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.processLogin()
        }
    }
    
    private func processLogin() {
        // Find user by email
        guard let user = UserStorage.findUser(email: loginEmail) else {
            errorMessage = "No account found with this email address"
            isLoading = false
            HapticManager.shared.error()
            return
        }
        
        // In a real app, you'd verify the password hash
        // For demo purposes, we'll accept any password for existing users
        
        // Update user's last login
        let updatedUser = UserProfile(
            id: user.id,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            fullName: user.fullName,
            username: user.username,
            phoneNumber: user.phoneNumber,
            profileImageURL: user.profileImageURL,
            preferredCurrency: user.preferredCurrency,
            isEmailVerified: user.isEmailVerified,
            isPhoneVerified: user.isPhoneVerified,
            memberSince: user.memberSince,
            lastLoginDate: Date(),
            totalTransactions: user.totalTransactions,
            totalVolume: user.totalVolume,
            kycStatus: user.kycStatus,
            securitySettings: user.securitySettings
        )
        
        // Save updated user
        UserStorage.updateUser(updatedUser)
        UserStorage.saveCurrentUser(updatedUser)
        
        // Update state
        currentUser = updatedUser
        authState = .authenticated(updatedUser)
        isLoading = false
        
        // Success feedback
        HapticManager.shared.success()
        
        // Clear login data if not remembering
        if !rememberLogin {
            clearLoginData()
        }
    }
    
    func loginWithBiometrics() async {
        let context = LAContext()
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Log in to StarkPay with biometrics"
            )
            
            if success {
                await MainActor.run {
                    // In a real app, you'd retrieve stored credentials from Keychain
                    // For demo, we'll log in the last used account
                    if let lastUserId = UserStorage.getCurrentUserId(),
                       let users = UserStorage.loadRegisteredUsers().first(where: { $0.id == lastUserId }) {
                        currentUser = users
                        authState = .authenticated(users)
                        HapticManager.shared.success()
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Biometric authentication failed: \(error.localizedDescription)"
                HapticManager.shared.error()
            }
        }
    }
    
    // MARK: - Profile Management
    
    func updateProfile(_ updatedProfile: UserProfile) {
        UserStorage.updateUser(updatedProfile)
        currentUser = updatedProfile
        
        if authState.isAuthenticated {
            authState = .authenticated(updatedProfile)
        }
        
        HapticManager.shared.lightImpact()
    }
    
    func updateSecuritySettings(_ settings: SecuritySettings) {
        guard let user = currentUser else { return }
        
        let updatedUser = UserProfile(
            id: user.id,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            fullName: user.fullName,
            username: user.username,
            phoneNumber: user.phoneNumber,
            profileImageURL: user.profileImageURL,
            preferredCurrency: user.preferredCurrency,
            isEmailVerified: user.isEmailVerified,
            isPhoneVerified: user.isPhoneVerified,
            memberSince: user.memberSince,
            lastLoginDate: user.lastLoginDate,
            totalTransactions: user.totalTransactions,
            totalVolume: user.totalVolume,
            kycStatus: user.kycStatus,
            securitySettings: settings
        )
        
        updateProfile(updatedUser)
    }
    
    // MARK: - User Statistics
    
    func getUserStatistics() -> (totalUsers: Int, verifiedUsers: Int, activeUsers: Int) {
        return UserStorage.getUserStatistics()
    }
    
    func getAllRegisteredUsers() -> [UserProfile] {
        return UserStorage.loadRegisteredUsers()
    }
    
    // MARK: - Demo User Management
    
    func loginAsDemoUser(_ user: UserProfile) {
        UserStorage.saveCurrentUser(user)
        currentUser = user
        authState = .authenticated(user)
        HapticManager.shared.success()
    }
    
    func resetDemoUsers() {
        // Clear existing users
        UserStorage.saveRegisteredUsers([])
        UserStorage.clearUserData()
        
        // Recreate demo users
        DemoUsers.setupDemoUsersIfNeeded()
        
        // Reset state
        currentUser = nil
        authState = .unauthenticated
        
        HapticManager.shared.mediumImpact()
    }
}

// MARK: - Authentication State Extensions

extension AuthenticationState {
    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    var user: UserProfile? {
        if case .authenticated(let user) = self {
            return user
        }
        return nil
    }
}

// MARK: - Registration Step Extensions

extension RegistrationStep {
    var title: String {
        switch self {
        case .welcome: return "Welcome to StarkPay"
        case .personalInfo: return "Personal Information"
        case .credentials: return "Account Credentials"
        case .verification: return "Verify Your Email"
        case .security: return "Security Settings"
        case .completed: return "Welcome Aboard!"
        }
    }
    
    var progress: Double {
        switch self {
        case .welcome: return 0.0
        case .personalInfo: return 0.2
        case .credentials: return 0.4
        case .verification: return 0.6
        case .security: return 0.8
        case .completed: return 1.0
        }
    }
    
    var stepNumber: Int {
        switch self {
        case .welcome: return 0
        case .personalInfo: return 1
        case .credentials: return 2
        case .verification: return 3
        case .security: return 4
        case .completed: return 5
        }
    }
}
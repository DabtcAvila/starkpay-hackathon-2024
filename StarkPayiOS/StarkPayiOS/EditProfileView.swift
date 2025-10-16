import SwiftUI

// MARK: - Edit Profile View

struct EditProfileView: View {
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var preferredCurrency: String = "USD"
    @State private var isLoading = false
    @State private var showingSuccessAlert = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case firstName, lastName, email, phone
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Profile Picture Section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.orange, Color.yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                            
                            if let user = userManager.currentUser {
                                Text(user.initials)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            // Camera overlay
                            Button(action: {
                                // TODO: Image picker
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 100, height: 100)
                                    
                                    VStack(spacing: 4) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 20, weight: .medium))
                                        Text("Change")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Text("Tap to change profile picture")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        EditableField(
                            title: "First Name",
                            text: $firstName,
                            placeholder: "Enter your first name",
                            keyboardType: .default,
                            textContentType: .givenName,
                            focusedField: $focusedField,
                            field: .firstName
                        )
                        
                        EditableField(
                            title: "Last Name",
                            text: $lastName,
                            placeholder: "Enter your last name",
                            keyboardType: .default,
                            textContentType: .familyName,
                            focusedField: $focusedField,
                            field: .lastName
                        )
                        
                        EditableField(
                            title: "Email Address",
                            text: $email,
                            placeholder: "your@email.com",
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            focusedField: $focusedField,
                            field: .email
                        )
                        
                        EditableField(
                            title: "Phone Number",
                            text: $phoneNumber,
                            placeholder: "+1 (555) 123-4567",
                            keyboardType: .phonePad,
                            textContentType: .telephoneNumber,
                            focusedField: $focusedField,
                            field: .phone
                        )
                        
                        // Currency Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preferred Currency")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Picker("Currency", selection: $preferredCurrency) {
                                Text("US Dollar (USD)").tag("USD")
                                Text("Euro (EUR)").tag("EUR")
                                Text("British Pound (GBP)").tag("GBP")
                                Text("Canadian Dollar (CAD)").tag("CAD")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Account Information
                    if let user = userManager.currentUser {
                        VStack(spacing: 16) {
                            Text("Account Information")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            InfoRow(title: "Username", value: "@\(user.username)")
                            InfoRow(title: "Member Since", value: user.memberSince.formatted(date: .abbreviated, time: .omitted))
                            InfoRow(title: "User ID", value: String(user.id.prefix(8)) + "...")
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(isLoading || !hasChanges)
                }
            }
            .onTapGesture {
                focusedField = nil
            }
        }
        .onAppear {
            loadCurrentUserData()
        }
        .alert("Profile Updated", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your profile has been successfully updated.")
        }
    }
    
    private var hasChanges: Bool {
        guard let user = userManager.currentUser else { return false }
        
        return firstName != user.firstName ||
               lastName != user.lastName ||
               email != user.email ||
               phoneNumber != (user.phoneNumber ?? "") ||
               preferredCurrency != user.preferredCurrency
    }
    
    private func loadCurrentUserData() {
        guard let user = userManager.currentUser else { return }
        
        firstName = user.firstName
        lastName = user.lastName
        email = user.email
        phoneNumber = user.phoneNumber ?? ""
        preferredCurrency = user.preferredCurrency
    }
    
    private func saveProfile() {
        guard let currentUser = userManager.currentUser else { return }
        
        isLoading = true
        
        // Create updated user profile
        let updatedUser = UserProfile(
            id: currentUser.id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            fullName: "\(firstName) \(lastName)",
            username: currentUser.username, // Keep existing username
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            profileImageURL: currentUser.profileImageURL,
            preferredCurrency: preferredCurrency,
            isEmailVerified: currentUser.isEmailVerified, // Keep verification status
            isPhoneVerified: currentUser.isPhoneVerified,
            memberSince: currentUser.memberSince,
            lastLoginDate: currentUser.lastLoginDate,
            totalTransactions: currentUser.totalTransactions,
            totalVolume: currentUser.totalVolume,
            kycStatus: currentUser.kycStatus,
            securitySettings: currentUser.securitySettings
        )
        
        // Simulate save delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            userManager.updateProfile(updatedUser)
            isLoading = false
            showingSuccessAlert = true
            HapticManager.shared.success()
        }
    }
}

// MARK: - Editable Field Component

struct EditableField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    @Binding var focusedField: EditProfileView.Field?
    let field: EditProfileView.Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(focusedField == field ? Color.orange : Color.clear, lineWidth: 2)
                )
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .focused($focusedField, equals: field)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
        }
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - User Security Settings View

struct UserSecuritySettingsView: View {
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var biometricEnabled: Bool = true
    @State private var twoFactorEnabled: Bool = false
    @State private var transactionLimitsEnabled: Bool = true
    @State private var notificationsEnabled: Bool = true
    @State private var privacyMode: Bool = false
    @State private var sessionTimeout: Double = 30
    @State private var showingChangePassword = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Security Score
                    SecurityScoreCard(
                        score: securityScore,
                        title: securityTitle,
                        description: securityDescription
                    )
                    
                    // Authentication Settings
                    VStack(spacing: 20) {
                        SectionHeader(title: "Authentication")
                        
                        SecurityToggle(
                            icon: "faceid",
                            title: "Biometric Authentication",
                            subtitle: "Use Face ID or Touch ID to unlock",
                            isEnabled: $biometricEnabled,
                            color: .blue
                        )
                        
                        SecurityToggle(
                            icon: "key.fill",
                            title: "Two-Factor Authentication",
                            subtitle: "Extra layer of account security",
                            isEnabled: $twoFactorEnabled,
                            color: .green
                        )
                        
                        Button(action: {
                            showingChangePassword = true
                        }) {
                            SecurityActionRow(
                                icon: "lock.rotation",
                                title: "Change Password",
                                subtitle: "Update your account password",
                                color: .orange
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Privacy Settings
                    VStack(spacing: 20) {
                        SectionHeader(title: "Privacy & Notifications")
                        
                        SecurityToggle(
                            icon: "bell.fill",
                            title: "Security Notifications",
                            subtitle: "Get alerts for account activity",
                            isEnabled: $notificationsEnabled,
                            color: .purple
                        )
                        
                        SecurityToggle(
                            icon: "eye.slash.fill",
                            title: "Privacy Mode",
                            subtitle: "Hide sensitive information",
                            isEnabled: $privacyMode,
                            color: .indigo
                        )
                    }
                    
                    // Account Security
                    VStack(spacing: 20) {
                        SectionHeader(title: "Account Security")
                        
                        SecurityToggle(
                            icon: "creditcard.fill",
                            title: "Transaction Limits",
                            subtitle: "Enable spending limits",
                            isEnabled: $transactionLimitsEnabled,
                            color: .red
                        )
                        
                        // Session Timeout
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Session Timeout")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    Text("Auto-lock after \(Int(sessionTimeout)) minutes")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            
                            Slider(value: $sessionTimeout, in: 5...120, step: 5)
                                .accentColor(.orange)
                                .onChange(of: sessionTimeout) { _, _ in
                                    HapticManager.shared.lightImpact()
                                }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Security & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveSecuritySettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordView()
        }
        .onAppear {
            loadSecuritySettings()
        }
    }
    
    private var securityScore: Double {
        var score = 0.2 // Base score
        if biometricEnabled { score += 0.25 }
        if twoFactorEnabled { score += 0.25 }
        if transactionLimitsEnabled { score += 0.1 }
        if notificationsEnabled { score += 0.1 }
        if sessionTimeout <= 30 { score += 0.1 }
        return min(score, 1.0)
    }
    
    private var securityTitle: String {
        switch securityScore {
        case 0..<0.5: return "Basic Security"
        case 0.5..<0.75: return "Good Security"
        default: return "Excellent Security"
        }
    }
    
    private var securityDescription: String {
        switch securityScore {
        case 0..<0.5: return "Enable more security features to better protect your account"
        case 0.5..<0.75: return "Your security is good. Consider enabling all features for maximum protection"
        default: return "Your account has excellent security with multiple protection layers"
        }
    }
    
    private func loadSecuritySettings() {
        guard let user = userManager.currentUser else { return }
        let settings = user.securitySettings
        
        biometricEnabled = settings.biometricEnabled
        twoFactorEnabled = settings.twoFactorEnabled
        transactionLimitsEnabled = settings.transactionLimitsEnabled
        notificationsEnabled = settings.notificationsEnabled
        privacyMode = settings.privacyMode
        sessionTimeout = Double(settings.sessionTimeout)
    }
    
    private func saveSecuritySettings() {
        let newSettings = SecuritySettings(
            biometricEnabled: biometricEnabled,
            twoFactorEnabled: twoFactorEnabled,
            transactionLimitsEnabled: transactionLimitsEnabled,
            notificationsEnabled: notificationsEnabled,
            privacyMode: privacyMode,
            sessionTimeout: Int(sessionTimeout)
        )
        
        userManager.updateSecuritySettings(newSettings)
        HapticManager.shared.success()
    }
}

// MARK: - Supporting Views

struct SecurityScoreCard: View {
    let score: Double
    let title: String
    let description: String
    
    var scoreColor: Color {
        switch score {
        case 0..<0.5: return .red
        case 0.5..<0.75: return .orange
        default: return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Security Score")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: score)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: score)
                    
                    Text("\(Int(score * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(scoreColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(scoreColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            
            Spacer()
        }
    }
}

struct SecurityToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isEnabled: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onChange(of: isEnabled) { _, _ in
            HapticManager.shared.lightImpact()
        }
    }
}

struct SecurityActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Change Password View

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "key.fill")
                            .font(.system(size: 35, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    
                    Text("Change Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create a new secure password for your account")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Password Fields
                VStack(spacing: 20) {
                    SecureInputField(
                        title: "Current Password",
                        text: $currentPassword,
                        placeholder: "Enter your current password"
                    )
                    
                    SecureInputField(
                        title: "New Password",
                        text: $newPassword,
                        placeholder: "Create a new password"
                    )
                    
                    SecureInputField(
                        title: "Confirm Password",
                        text: $confirmPassword,
                        placeholder: "Confirm your new password"
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Change Password Button
                Button(action: changePassword) {
                    HStack(spacing: 12) {
                        if isLoading {
                            PremiumLoadingView(size: 20, color: .white)
                        }
                        
                        Text(isLoading ? "Updating..." : "Update Password")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .cornerRadius(12)
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PremiumButtonStyle(color: .orange, isLoading: isLoading))
                .disabled(isFormValid == false || isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Password Updated", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your password has been successfully updated.")
        }
    }
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 8
    }
    
    private func changePassword() {
        isLoading = true
        
        // Simulate password change
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            showingSuccess = true
            HapticManager.shared.success()
        }
    }
}

struct SecureInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @State private var isSecured = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
            
            HStack {
                Group {
                    if isSecured {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 16))
                .textContentType(.password)
                
                Button(action: {
                    isSecured.toggle()
                }) {
                    Image(systemName: isSecured ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// MARK: - Account Settings View

struct AccountSettingsView: View {
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    Text("Account Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Placeholder for account settings
                    VStack(spacing: 16) {
                        Text("Account settings will be available in a future update.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Image(systemName: "gear")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .padding(.vertical, 60)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EditProfileView(userManager: UserManager())
}
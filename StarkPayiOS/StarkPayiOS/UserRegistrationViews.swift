import SwiftUI

// MARK: - User Registration Flow

struct UserRegistrationFlow: View {
    @StateObject private var userManager = UserManager()
    @State private var showingLogin = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.1)]),
                    startPoint: .topLeading, 
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                
                // Registration Content
                switch userManager.registrationStep {
                case .welcome:
                    WelcomeView(userManager: userManager, showingLogin: $showingLogin)
                case .personalInfo:
                    PersonalInfoView(userManager: userManager)
                case .credentials:
                    CredentialsView(userManager: userManager)
                case .verification:
                    VerificationView(userManager: userManager)
                case .security:
                    SecuritySetupView(userManager: userManager)
                case .completed:
                    RegistrationCompleteView(userManager: userManager)
                }
            }
        }
        .sheet(isPresented: $showingLogin) {
            LoginView(userManager: userManager)
        }
    }
}

// MARK: - Welcome Screen

struct WelcomeView: View {
    @ObservedObject var userManager: UserManager
    @Binding var showingLogin: Bool
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Icon and Title
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 120, height: 120)
                        .opacity(0.3)
                        .scaleEffect(animateIcon ? 1.2 : 1.0)
                        .blur(radius: 15)
                    
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.black, Color(red: 0.15, green: 0.15, blue: 0.15)],
                            center: .topLeading, startRadius: 0, endRadius: 50
                        ))
                        .frame(width: 100, height: 100)
                        .overlay(Circle().stroke(LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ), lineWidth: 3))
                    
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .shadow(color: .orange, radius: 8)
                }
                
                VStack(spacing: 12) {
                    Text("Welcome to")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("StarkPay")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.white, Color.gray],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                    
                    Text("The future of payments on Starknet")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Features List
            VStack(spacing: 20) {
                FeatureRow(icon: "bolt.fill", title: "Instant Transfers", description: "Send money in seconds")
                FeatureRow(icon: "lock.shield.fill", title: "Bank-Level Security", description: "Your funds are always protected")
                FeatureRow(icon: "dollarsign.circle.fill", title: "Low Fees", description: "Keep more of your money")
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                Button(action: {
                    userManager.startRegistration()
                }) {
                    HStack {
                        Text("Create Account")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .cornerRadius(12)
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PremiumButtonStyle(color: .orange, isLoading: false))
                
                Button(action: {
                    showingLogin = true
                }) {
                    Text("Already have an account? Sign In")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateIcon = true
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

// MARK: - Personal Info Screen

struct PersonalInfoView: View {
    @ObservedObject var userManager: UserManager
    @FocusState private var focusedField: Field?
    
    enum Field {
        case firstName, lastName, phone
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            RegistrationHeader(
                step: userManager.registrationStep,
                title: "Tell us about yourself",
                subtitle: "We need some basic information to get started"
            )
            
            // Form Fields
            VStack(spacing: 20) {
                CustomTextField(
                    title: "First Name",
                    text: $userManager.registrationData.firstName,
                    placeholder: "Enter your first name",
                    keyboardType: .default
                )
                .focused($focusedField, equals: .firstName)
                .textContentType(.givenName)
                
                CustomTextField(
                    title: "Last Name",
                    text: $userManager.registrationData.lastName,
                    placeholder: "Enter your last name",
                    keyboardType: .default
                )
                .focused($focusedField, equals: .lastName)
                .textContentType(.familyName)
                
                CustomTextField(
                    title: "Phone Number (Optional)",
                    text: Binding(
                        get: { userManager.registrationData.phoneNumber ?? "" },
                        set: { newValue in
                            userManager.registrationData = UserRegistration(
                                email: userManager.registrationData.email,
                                password: userManager.registrationData.password,
                                firstName: userManager.registrationData.firstName,
                                lastName: userManager.registrationData.lastName,
                                phoneNumber: newValue.isEmpty ? nil : newValue,
                                preferredCurrency: userManager.registrationData.preferredCurrency,
                                acceptedTerms: userManager.registrationData.acceptedTerms
                            )
                        }
                    ),
                    placeholder: "+1 (555) 123-4567",
                    keyboardType: .phonePad
                )
                .focused($focusedField, equals: .phone)
                .textContentType(.telephoneNumber)
                
                // Currency Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferred Currency")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Picker("Currency", selection: $userManager.registrationData.preferredCurrency) {
                        Text("USD ($)").tag("USD")
                        Text("EUR (€)").tag("EUR")
                        Text("GBP (£)").tag("GBP")
                        Text("CAD (C$)").tag("CAD")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Error Message
            if let errorMessage = userManager.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Navigation Buttons
            RegistrationNavigationButtons(userManager: userManager)
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}

// MARK: - Credentials Screen

struct CredentialsView: View {
    @ObservedObject var userManager: UserManager
    @FocusState private var focusedField: Field?
    @State private var showingPassword = false
    @State private var confirmPassword = ""
    
    enum Field {
        case email, password, confirmPassword
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            RegistrationHeader(
                step: userManager.registrationStep,
                title: "Secure your account",
                subtitle: "Create your login credentials"
            )
            
            // Form Fields
            VStack(spacing: 20) {
                CustomTextField(
                    title: "Email Address",
                    text: $userManager.registrationData.email,
                    placeholder: "your@email.com",
                    keyboardType: .emailAddress
                )
                .focused($focusedField, equals: .email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Group {
                            if showingPassword {
                                TextField("Create a strong password", text: $userManager.registrationData.password)
                            } else {
                                SecureField("Create a strong password", text: $userManager.registrationData.password)
                            }
                        }
                        .font(.system(size: 16))
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .password)
                        .textContentType(.newPassword)
                        
                        Button(action: {
                            showingPassword.toggle()
                            HapticManager.shared.lightImpact()
                        }) {
                            Image(systemName: showingPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        }
                        .padding(.leading, 8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    SecureField("Confirm your password", text: $confirmPassword)
                        .font(.system(size: 16))
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(confirmPassword == userManager.registrationData.password && !confirmPassword.isEmpty ? Color.green.opacity(0.5) : Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .confirmPassword)
                        .textContentType(.newPassword)
                }
                
                // Password Requirements
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password Requirements:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        PasswordRequirement(
                            text: "At least 8 characters",
                            isMet: userManager.registrationData.password.count >= 8
                        )
                        PasswordRequirement(
                            text: "At least 1 uppercase letter",
                            isMet: userManager.registrationData.password.range(of: "[A-Z]", options: .regularExpression) != nil
                        )
                        PasswordRequirement(
                            text: "Passwords match",
                            isMet: !userManager.registrationData.password.isEmpty && userManager.registrationData.password == confirmPassword
                        )
                    }
                }
                .padding(.top, 8)
                
                // Terms and Conditions
                HStack(alignment: .top, spacing: 12) {
                    Button(action: {
                        userManager.registrationData = UserRegistration(
                            email: userManager.registrationData.email,
                            password: userManager.registrationData.password,
                            firstName: userManager.registrationData.firstName,
                            lastName: userManager.registrationData.lastName,
                            phoneNumber: userManager.registrationData.phoneNumber,
                            preferredCurrency: userManager.registrationData.preferredCurrency,
                            acceptedTerms: !userManager.registrationData.acceptedTerms
                        )
                        HapticManager.shared.lightImpact()
                    }) {
                        Image(systemName: userManager.registrationData.acceptedTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(userManager.registrationData.acceptedTerms ? .orange : .gray)
                            .font(.system(size: 20))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I agree to the Terms of Service and Privacy Policy")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text("By creating an account, you agree to our terms and conditions.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Error Message
            if let errorMessage = userManager.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Navigation Buttons
            RegistrationNavigationButtons(userManager: userManager)
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}

struct PasswordRequirement: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
                .font(.system(size: 12))
            
            Text(text)
                .font(.caption2)
                .foregroundColor(isMet ? .green : .gray)
        }
    }
}

// MARK: - Verification Screen

struct VerificationView: View {
    @ObservedObject var userManager: UserManager
    @State private var verificationCode = ""
    @State private var isCodeSent = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            RegistrationHeader(
                step: userManager.registrationStep,
                title: "Verify your email",
                subtitle: "We've sent a verification code to\n\(userManager.registrationData.email)"
            )
            
            // Email Icon
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.orange)
                }
                
                if !isCodeSent {
                    Button(action: {
                        sendVerificationCode()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                            Text("Send Verification Code")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    .buttonStyle(BounceButtonStyle())
                }
            }
            
            if isCodeSent {
                // Verification Code Input
                VStack(spacing: 16) {
                    Text("Enter the 6-digit code:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("000000", text: $verificationCode)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .keyboardType(.numberPad)
                        .onChange(of: verificationCode) { _, newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                verificationCode = String(newValue.prefix(6))
                            }
                            
                            // Auto-verify when 6 digits entered
                            if verificationCode.count == 6 {
                                verifyCode()
                            }
                        }
                    
                    HStack(spacing: 4) {
                        Text("Didn't receive the code?")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            sendVerificationCode()
                        }) {
                            Text("Resend")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Navigation Buttons
            RegistrationNavigationButtons(userManager: userManager)
        }
    }
    
    private func sendVerificationCode() {
        isCodeSent = true
        HapticManager.shared.success()
        
        // Simulate email sending
        withAnimation(.easeInOut(duration: 0.5)) {
            // In a real app, you'd call your API here
        }
    }
    
    private func verifyCode() {
        // For demo purposes, accept any 6-digit code
        if verificationCode.count == 6 {
            HapticManager.shared.success()
            userManager.nextRegistrationStep()
        } else {
            HapticManager.shared.error()
        }
    }
}

// MARK: - Security Setup Screen

struct SecuritySetupView: View {
    @ObservedObject var userManager: UserManager
    @State private var biometricEnabled = true
    @State private var twoFactorEnabled = false
    @State private var notificationsEnabled = true
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            RegistrationHeader(
                step: userManager.registrationStep,
                title: "Secure your account",
                subtitle: "Choose your security preferences"
            )
            
            // Security Options
            VStack(spacing: 20) {
                SecurityOption(
                    icon: "faceid",
                    title: "Face ID / Touch ID",
                    subtitle: "Use biometrics for quick access",
                    isEnabled: $biometricEnabled
                )
                
                SecurityOption(
                    icon: "key.fill",
                    title: "Two-Factor Authentication",
                    subtitle: "Extra security for your account",
                    isEnabled: $twoFactorEnabled
                )
                
                SecurityOption(
                    icon: "bell.fill",
                    title: "Security Notifications",
                    subtitle: "Get alerts for account activity",
                    isEnabled: $notificationsEnabled
                )
            }
            .padding(.horizontal, 20)
            
            // Security Level Indicator
            VStack(spacing: 12) {
                HStack {
                    Text("Security Level:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(securityLevelText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(securityLevelColor)
                }
                
                ProgressView(value: securityLevel, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: securityLevelColor))
                    .scaleEffect(y: 2)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Navigation Buttons
            RegistrationNavigationButtons(userManager: userManager)
        }
    }
    
    private var securityLevel: Double {
        var level = 0.3 // Base level
        if biometricEnabled { level += 0.3 }
        if twoFactorEnabled { level += 0.3 }
        if notificationsEnabled { level += 0.1 }
        return min(level, 1.0)
    }
    
    private var securityLevelText: String {
        switch securityLevel {
        case 0..<0.5: return "Basic"
        case 0.5..<0.8: return "Good"
        default: return "Excellent"
        }
    }
    
    private var securityLevelColor: Color {
        switch securityLevel {
        case 0..<0.5: return .red
        case 0.5..<0.8: return .orange
        default: return .green
        }
    }
}

struct SecurityOption: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .onChange(of: isEnabled) { _, _ in
            HapticManager.shared.lightImpact()
        }
    }
}

// MARK: - Registration Complete Screen

struct RegistrationCompleteView: View {
    @ObservedObject var userManager: UserManager
    @State private var showingConfetti = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Success Animation
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showingConfetti ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showingConfetti)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 12) {
                    Text("Welcome aboard!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your StarkPay account is ready to use")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Account Summary
            VStack(spacing: 16) {
                AccountSummaryRow(
                    icon: "person.circle.fill",
                    title: "Account Created",
                    value: "\(userManager.registrationData.firstName) \(userManager.registrationData.lastName)"
                )
                
                AccountSummaryRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: userManager.registrationData.email
                )
                
                AccountSummaryRow(
                    icon: "shield.checkered",
                    title: "Security",
                    value: "Enhanced Protection Enabled"
                )
                
                AccountSummaryRow(
                    icon: "dollarsign.circle.fill",
                    title: "Currency",
                    value: userManager.registrationData.preferredCurrency
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Get Started Button
            Button(action: {
                // Registration complete, this will trigger the main app flow
                HapticManager.shared.success()
            }) {
                HStack(spacing: 12) {
                    Text("Get Started")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient(
                    colors: [Color.orange, Color.yellow],
                    startPoint: .leading, endPoint: .trailing
                ))
                .cornerRadius(12)
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PremiumButtonStyle(color: .orange, isLoading: false))
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .onAppear {
            showingConfetti = true
            HapticManager.shared.success()
        }
    }
}

struct AccountSummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Shared Components

struct RegistrationHeader: View {
    let step: RegistrationStep
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("Step \(step.stepNumber) of 5")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(Int(step.progress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                
                ProgressView(value: step.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                    .scaleEffect(y: 2)
            }
            .padding(.horizontal, 20)
            
            // Title and Subtitle
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .keyboardType(keyboardType)
        }
    }
}

struct RegistrationNavigationButtons: View {
    @ObservedObject var userManager: UserManager
    
    var body: some View {
        HStack(spacing: 16) {
            if userManager.registrationStep != .welcome {
                Button(action: {
                    userManager.previousRegistrationStep()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            
            if userManager.registrationStep != .completed {
                Button(action: {
                    if userManager.registrationStep == .security {
                        userManager.completeRegistration()
                    } else {
                        userManager.nextRegistrationStep()
                    }
                }) {
                    HStack(spacing: 8) {
                        if userManager.isLoading {
                            PremiumLoadingView(size: 20, color: .black)
                        }
                        
                        Text(userManager.registrationStep == .security ? "Create Account" : "Continue")
                        
                        if !userManager.isLoading {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .cornerRadius(10)
                    .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(userManager.isLoading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
}

#Preview {
    UserRegistrationFlow()
}
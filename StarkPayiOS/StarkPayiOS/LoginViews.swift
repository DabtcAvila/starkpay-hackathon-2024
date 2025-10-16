import SwiftUI
import LocalAuthentication

// MARK: - Login Views

struct LoginView: View {
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingForgotPassword = false
    @State private var showingDemoUsers = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 20) {
                            // Logo
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "shield.checkered")
                                    .font(.system(size: 35, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Welcome Back")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Sign in to your StarkPay account")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Login Form
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("Enter your email", text: $userManager.loginEmail)
                                    .font(.system(size: 16))
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .email)
                                    .disabled(userManager.isLoading)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                SecureField("Enter your password", text: $userManager.loginPassword)
                                    .font(.system(size: 16))
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                                    .disabled(userManager.isLoading)
                            }
                            
                            // Remember Me & Forgot Password
                            HStack {
                                Button(action: {
                                    userManager.rememberLogin.toggle()
                                    HapticManager.shared.lightImpact()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: userManager.rememberLogin ? "checkmark.square.fill" : "square")
                                            .foregroundColor(userManager.rememberLogin ? .orange : .gray)
                                            .font(.system(size: 16))
                                        
                                        Text("Remember me")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
                                
                                Button(action: {
                                    showingForgotPassword = true
                                }) {
                                    Text("Forgot password?")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Error Message
                        if let errorMessage = userManager.errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .transition(.opacity)
                        }
                        
                        // Login Buttons
                        VStack(spacing: 16) {
                            // Sign In Button
                            Button(action: {
                                focusedField = nil
                                userManager.login()
                            }) {
                                HStack(spacing: 12) {
                                    if userManager.isLoading {
                                        PremiumLoadingView(size: 20, color: .black)
                                    }
                                    
                                    Text(userManager.isLoading ? "Signing In..." : "Sign In")
                                        .font(.headline)
                                        .fontWeight(.semibold)
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
                            .buttonStyle(PremiumButtonStyle(color: .orange, isLoading: userManager.isLoading))
                            .disabled(userManager.loginEmail.isEmpty || userManager.loginPassword.isEmpty || userManager.isLoading)
                            
                            // Biometric Login Button (if available)
                            BiometricLoginButton(userManager: userManager)
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                
                                Text("OR")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 12)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)
                            
                            // Demo Login Button
                            Button(action: {
                                showingDemoUsers = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.2.fill")
                                    Text("Try Demo Account")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(BounceButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                }
                .onTapGesture {
                    focusedField = nil
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    }
                    .foregroundColor(.orange)
                    .disabled(userManager.isLoading)
                }
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
        .sheet(isPresented: $showingDemoUsers) {
            DemoUsersView(userManager: userManager)
        }
        .onChange(of: userManager.authState) { _, authState in
            if case .authenticated = authState {
                dismiss()
            }
        }
    }
}

// MARK: - Biometric Login Button

struct BiometricLoginButton: View {
    @ObservedObject var userManager: UserManager
    @State private var biometricType: LABiometryType = .none
    @State private var canUseBiometrics = false
    
    var body: some View {
        if canUseBiometrics {
            Button(action: {
                Task {
                    await userManager.loginWithBiometrics()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: biometricIcon)
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Sign in with \(biometricName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(BounceButtonStyle())
            .disabled(userManager.isLoading)
        }
    }
    
    var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.fill"
        }
    }
    
    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometrics"
        }
    }
    
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometricType = context.biometryType
    }
    
    init(userManager: UserManager) {
        self.userManager = userManager
        checkBiometricAvailability()
    }
}

// MARK: - Demo Users View

struct DemoUsersView: View {
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUser: UserProfile?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("Demo Accounts")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Try StarkPay with these pre-configured demo accounts")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Demo Users List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(userManager.getAllRegisteredUsers(), id: \.id) { user in
                            DemoUserRow(user: user, isSelected: selectedUser?.id == user.id) {
                                selectedUser = user
                                HapticManager.shared.lightImpact()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Login Button
                if let selectedUser = selectedUser {
                    VStack(spacing: 12) {
                        Button(action: {
                            userManager.loginAsDemoUser(selectedUser)
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.circle.fill")
                                Text("Login as \(selectedUser.firstName)")
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
                            .cornerRadius(12)
                        }
                        .buttonStyle(BounceButtonStyle())
                        
                        Text("Demo accounts contain sample data for testing")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .scale))
                }
                
                Spacer()
            }
            .navigationTitle("Demo Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        userManager.resetDemoUsers()
                        selectedUser = nil
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

struct DemoUserRow: View {
    let user: UserProfile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Text(user.initials)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 12) {
                        StatusBadge(
                            text: user.kycStatus.displayName,
                            color: user.kycStatus.statusColor
                        )
                        
                        StatusBadge(
                            text: "\(user.totalTransactions) txns",
                            color: .blue
                        )
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.orange.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(8)
    }
}

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "key.fill")
                            .font(.system(size: 35, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Forgot Password?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enter your email address and we'll send you a link to reset your password")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)
                
                // Email Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .font(.headline)
                    
                    TextField("Enter your email", text: $email)
                        .font(.system(size: 16))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disabled(isLoading)
                }
                .padding(.horizontal, 20)
                
                // Send Reset Button
                Button(action: sendResetEmail) {
                    HStack(spacing: 12) {
                        if isLoading {
                            PremiumLoadingView(size: 20, color: .white)
                        }
                        
                        Text(isLoading ? "Sending..." : "Send Reset Email")
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
                .disabled(email.isEmpty || isLoading)
                .padding(.horizontal, 20)
                
                if showingSuccess {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        Text("Reset email sent!")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text("Check your inbox for reset instructions")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .scale))
                }
                
                Spacer()
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendResetEmail() {
        isLoading = true
        
        // Simulate sending reset email
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showingSuccess = true
            }
            HapticManager.shared.success()
            
            // Auto dismiss after success
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismiss()
            }
        }
    }
}

#Preview {
    LoginView(userManager: UserManager())
}
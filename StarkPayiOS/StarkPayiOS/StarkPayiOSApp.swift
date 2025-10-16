import SwiftUI
import LocalAuthentication

// MARK: - Biometric Authentication Manager
@MainActor
class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var authenticationError: String?
    @Published var biometricType: LABiometryType = .none
    @Published var canUseBiometrics = false
    @Published var isBiometricEnabled = true
    
    private let context = LAContext()
    private let biometricEnabledKey = "biometric_enabled"
    
    init() {
        loadBiometricSettings()
        checkBiometricAvailability()
    }
    
    func checkBiometricAvailability() {
        var error: NSError?
        canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometricType = context.biometryType
    }
    
    func authenticate() async {
        guard canUseBiometrics && isBiometricEnabled else {
            await authenticateWithPasscode()
            return
        }
        
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"
        context.localizedFallbackTitle = "Use Passcode"
        
        let reason = getAuthenticationReason()
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            if success {
                await MainActor.run {
                    self.isAuthenticated = true
                    self.authenticationError = nil
                    HapticManager.shared.success()
                }
            }
        } catch let error as LAError {
            await handleAuthenticationError(error)
        } catch {
            await MainActor.run {
                self.authenticationError = "Authentication failed: \(error.localizedDescription)"
                HapticManager.shared.error()
            }
        }
    }
    
    func authenticateWithPasscode() async {
        let context = LAContext()
        let reason = "Please enter your device passcode to access StarkPay"
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if success {
                await MainActor.run {
                    self.isAuthenticated = true
                    self.authenticationError = nil
                    HapticManager.shared.success()
                }
            }
        } catch let error as LAError {
            await handleAuthenticationError(error)
        } catch {
            await MainActor.run {
                self.authenticationError = "Authentication failed: \(error.localizedDescription)"
                HapticManager.shared.error()
            }
        }
    }
    
    private func handleAuthenticationError(_ error: LAError) async {
        let message: String
        switch error.code {
        case .biometryLockout:
            await authenticateWithPasscode()
            return
        case .userFallback:
            await authenticateWithPasscode()
            return
        case .userCancel:
            message = "Authentication was cancelled"
        case .authenticationFailed:
            message = "Authentication failed. Please try again"
        default:
            message = "Authentication failed: \(error.localizedDescription)"
        }
        
        await MainActor.run {
            self.authenticationError = message
            HapticManager.shared.error()
        }
    }
    
    private func getAuthenticationReason() -> String {
        switch biometricType {
        case .faceID: return "Use Face ID to securely access your StarkPay wallet"
        case .touchID: return "Use Touch ID to securely access your StarkPay wallet"
        case .opticID: return "Use Optic ID to securely access your StarkPay wallet"
        default: return "Authenticate to access your StarkPay wallet"
        }
    }
    
    func getBiometricIcon() -> String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.fill"
        }
    }
    
    func getBiometricName() -> String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometric Authentication"
        }
    }
    
    func toggleBiometricAuthentication() {
        isBiometricEnabled.toggle()
        saveBiometricSettings()
        HapticManager.shared.lightImpact()
    }
    
    func logout() {
        isAuthenticated = false
        authenticationError = nil
        HapticManager.shared.mediumImpact()
    }
    
    private func saveBiometricSettings() {
        UserDefaults.standard.set(isBiometricEnabled, forKey: biometricEnabledKey)
    }
    
    private func loadBiometricSettings() {
        if UserDefaults.standard.object(forKey: biometricEnabledKey) == nil {
            isBiometricEnabled = true
            saveBiometricSettings()
        } else {
            isBiometricEnabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)
        }
    }
}

// MARK: - Biometric Authentication View
struct BiometricAuthView: View {
    @StateObject private var authManager = BiometricAuthManager()
    @State private var isAnimating = false
    @State private var pulseScale: Double = 1.0
    @State private var glowOpacity: Double = 0.3
    
    let onAuthenticated: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.1)]),
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()
            
            VStack(spacing: 50) {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 120, height: 120)
                            .opacity(glowOpacity)
                            .scaleEffect(pulseScale)
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
                    
                    VStack(spacing: 8) {
                        Text("StarkPay")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(LinearGradient(
                                colors: [Color.white, Color.gray],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                        Text("Secure Wallet Access")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(spacing: 30) {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 100, height: 100)
                                .scaleEffect(isAnimating ? 1.1 : 1.0)
                            
                            Image(systemName: authManager.getBiometricIcon())
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(.white)
                                .opacity(authManager.canUseBiometrics && authManager.isBiometricEnabled ? 1.0 : 0.5)
                        }
                        
                        VStack(spacing: 8) {
                            if authManager.canUseBiometrics && authManager.isBiometricEnabled {
                                Text("Unlock with \(authManager.getBiometricName())")
                                    .font(.headline).foregroundColor(.white)
                                Text("Touch to authenticate").font(.subheadline).foregroundColor(.gray)
                            } else {
                                Text("Unlock with Passcode").font(.headline).foregroundColor(.white)
                                Text("Biometrics not available or disabled").font(.subheadline).foregroundColor(.gray)
                            }
                        }
                    }
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            HapticManager.shared.lightImpact()
                            Task { await authManager.authenticate() }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: authManager.canUseBiometrics && authManager.isBiometricEnabled ? authManager.getBiometricIcon() : "lock.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text(authManager.canUseBiometrics && authManager.isBiometricEnabled ? "Use \(authManager.getBiometricName())" : "Use Passcode")
                                    .font(.headline).fontWeight(.semibold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        if authManager.canUseBiometrics && authManager.isBiometricEnabled {
                            Button(action: {
                                HapticManager.shared.lightImpact()
                                Task { await authManager.authenticateWithPasscode() }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "key.fill").font(.system(size: 16))
                                    Text("Use Passcode Instead").font(.subheadline).fontWeight(.medium)
                                }
                                .foregroundColor(.gray).padding(.vertical, 12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill").font(.caption).foregroundColor(.orange)
                        Text("Your data is protected with industry-standard encryption").font(.caption).foregroundColor(.gray)
                    }
                    Text("StarkPay • Secure by Design").font(.caption2).foregroundColor(.gray.opacity(0.7))
                }
                .padding(.bottom, 30)
            }
            .padding()
        }
        .onAppear {
            startAnimations()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task { await authManager.authenticate() }
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onAuthenticated() }
            }
        }
        .alert("Authentication Failed", isPresented: .constant(authManager.authenticationError != nil)) {
            Button("Retry") {
                authManager.authenticationError = nil
                Task { await authManager.authenticate() }
            }
            Button("Use Passcode") {
                authManager.authenticationError = nil
                Task { await authManager.authenticateWithPasscode() }
            }
        } message: {
            Text(authManager.authenticationError ?? "")
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.2; glowOpacity = 0.6
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
    }
}

// MARK: - Security Settings View
struct SecuritySettingsView: View {
    @EnvironmentObject var authManager: BiometricAuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    VStack(spacing: 15) {
                        ZStack {
                            Circle().fill(Color.orange.opacity(0.1)).frame(width: 80, height: 80)
                            Image(systemName: "shield.checkered").font(.system(size: 35, weight: .medium)).foregroundColor(.orange)
                        }
                        Text("Security Settings").font(.title2).fontWeight(.bold)
                        Text("Manage your wallet security preferences").font(.subheadline).foregroundColor(.gray)
                    }.padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "faceid").foregroundColor(.orange).frame(width: 24)
                            Text("Biometric Authentication").font(.headline).fontWeight(.bold)
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: authManager.getBiometricIcon())
                                .foregroundColor(authManager.canUseBiometrics ? .primary : .gray)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(authManager.getBiometricName())
                                    .font(.headline)
                                    .foregroundColor(authManager.canUseBiometrics ? .primary : .gray)
                                Text(authManager.canUseBiometrics ? "Use \(authManager.getBiometricName().lowercased()) to unlock StarkPay" : "Not available on this device")
                                    .font(.caption).foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { authManager.canUseBiometrics && authManager.isBiometricEnabled },
                                set: { _ in if authManager.canUseBiometrics { authManager.toggleBiometricAuthentication() } }
                            ))
                            .disabled(!authManager.canUseBiometrics)
                        }
                        .padding().background(Color.gray.opacity(0.05)).cornerRadius(12)
                    }
                    
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "lock.rotation").foregroundColor(.red).frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Force Re-Authentication").font(.headline).foregroundColor(.primary)
                                Text("Immediately lock the app").font(.caption).foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding().background(Color.gray.opacity(0.05)).cornerRadius(12)
                    
                    Spacer(minLength: 30)
                }
                .padding()
            }
            .navigationTitle("Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { HapticManager.shared.lightImpact(); dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .alert("Force Re-Authentication", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Lock App", role: .destructive) { authManager.logout(); dismiss() }
        } message: {
            Text("This will immediately lock StarkPay and require authentication to access.")
        }
    }
}

// MARK: - Security Status Card  
struct SecurityStatusCard: View {
    @EnvironmentObject var authManager: BiometricAuthManager
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(securityColor.opacity(0.1)).frame(width: 40, height: 40)
                Image(systemName: securityIcon).foregroundColor(securityColor).font(.system(size: 18, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(securityTitle).font(.headline).fontWeight(.semibold).foregroundColor(.primary)
                Text(securityDescription).font(.caption).foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(securityBadge)
                .font(.caption2).fontWeight(.bold).foregroundColor(securityColor)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(securityColor.opacity(0.1)).cornerRadius(8)
        }
        .padding()
        .background(LinearGradient(colors: [Color.white, Color.gray.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(securityColor.opacity(0.1), lineWidth: 1))
    }
    
    private var securityColor: Color {
        if authManager.canUseBiometrics && authManager.isBiometricEnabled { return .green }
        else if authManager.canUseBiometrics { return .orange }
        else { return .blue }
    }
    
    private var securityIcon: String {
        if authManager.canUseBiometrics && authManager.isBiometricEnabled { return authManager.getBiometricIcon() }
        else if authManager.canUseBiometrics { return "shield.slash" }
        else { return "key.fill" }
    }
    
    private var securityTitle: String {
        if authManager.canUseBiometrics && authManager.isBiometricEnabled { return "\(authManager.getBiometricName()) Active" }
        else if authManager.canUseBiometrics { return "\(authManager.getBiometricName()) Available" }
        else { return "Passcode Protection" }
    }
    
    private var securityDescription: String {
        if authManager.canUseBiometrics && authManager.isBiometricEnabled { return "Your wallet is secured with \(authManager.getBiometricName().lowercased())" }
        else if authManager.canUseBiometrics { return "Enable \(authManager.getBiometricName().lowercased()) for enhanced security" }
        else { return "Your wallet is protected with device passcode" }
    }
    
    private var securityBadge: String {
        if authManager.canUseBiometrics && authManager.isBiometricEnabled { return "SECURE" }
        else if authManager.canUseBiometrics { return "BASIC" }
        else { return "LOCKED" }
    }
}

// MARK: - Premium Loading States
enum LoadingState {
    case idle
    case loading
    case success
    case error(String)
}

// MARK: - Premium Loading View
struct PremiumLoadingView: View {
    @State private var rotation: Double = 0
    @State private var scale: Double = 1.0
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 24, color: Color = .orange) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 2)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.3)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                scale = 1.1
            }
        }
    }
}

// MARK: - Success Animation View
struct SuccessAnimationView: View {
    @State private var checkmarkScale: Double = 0
    @State private var circleScale: Double = 0
    @State private var showParticles = false
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Success circle
            Circle()
                .stroke(Color.green, lineWidth: 3)
                .frame(width: 60, height: 60)
                .scaleEffect(circleScale)
                .opacity(circleScale > 0 ? 1 : 0)
            
            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.green)
                .scaleEffect(checkmarkScale)
                .opacity(checkmarkScale > 0 ? 1 : 0)
            
            // Particle effect
            if showParticles {
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .offset(
                            x: cos(Double(index) * .pi / 4) * 40,
                            y: sin(Double(index) * .pi / 4) * 40
                        )
                        .scaleEffect(showParticles ? 0 : 1)
                        .opacity(showParticles ? 0 : 1)
                        .animation(
                            .easeOut(duration: 0.6).delay(0.3),
                            value: showParticles
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                circleScale = 1.0
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) {
                checkmarkScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showParticles = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        }
    }
}

// MARK: - Error Animation View
struct ErrorAnimationView: View {
    @State private var shake: Double = 0
    @State private var scale: Double = 0
    let message: String
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.red, lineWidth: 3)
                .frame(width: 60, height: 60)
                .scaleEffect(scale)
                .offset(x: shake)
            
            Image(systemName: "xmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.red)
                .scaleEffect(scale)
                .offset(x: shake)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true).delay(0.2)) {
                shake = 5
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        }
    }
}

// MARK: - Shimmer Loading View
struct ShimmerView: View {
    @State private var shimmerOffset: CGFloat = -200
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 100)
                    .offset(x: shimmerOffset)
                    .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = width + 100
                }
            }
    }
}

// MARK: - Premium Button Style
struct PremiumButtonStyle: ButtonStyle {
    let color: Color
    let isLoading: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(isLoading)
    }
}

// MARK: - Bounce Button Style
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Progress Indicator
struct ProgressIndicator: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: 40, height: 40)
    }
}

// MARK: - Haptic Feedback Manager
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func lightImpact() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
    }
    
    func mediumImpact() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
    }
    
    func heavyImpact() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactGenerator.impactOccurred()
    }
    
    func selectionChanged() {
        let selectionGenerator = UISelectionFeedbackGenerator()
        selectionGenerator.selectionChanged()
    }
    
    func success() {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)
    }
    
    func error() {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.error)
    }
}

@main
struct StarkPayiOSApp: App {
    @StateObject private var viewModel = StarkPayViewModel()
    @StateObject private var authManager = BiometricAuthManager()
    @StateObject private var userManager = UserManager()
    @State private var isShowingSplash = true
    @State private var shouldShowAuth = false
    
    var body: some Scene {
        WindowGroup {
            if isShowingSplash {
                SplashView(isShowingSplash: $isShowingSplash)
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        // Re-authenticate when app comes to foreground
                        if !isShowingSplash {
                            authManager.logout()
                            shouldShowAuth = true
                        }
                    }
            } else if !userManager.authState.isAuthenticated {
                // Show user registration/login flow
                UserRegistrationFlow()
                    .environmentObject(userManager)
            } else if !authManager.isAuthenticated || shouldShowAuth {
                // Show biometric authentication for existing users
                BiometricAuthView {
                    shouldShowAuth = false
                }
                .environmentObject(authManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // Lock app when backgrounded for security
                    authManager.logout()
                }
            } else {
                // Show main app content
                ContentView()
                    .environmentObject(viewModel)
                    .environmentObject(authManager)
                    .environmentObject(userManager)
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        // Re-authenticate when app comes to foreground
                        authManager.logout()
                        shouldShowAuth = true
                    }
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PayView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "dollarsign.circle.fill" : "dollarsign.circle")
                    Text("Pay")
                }
                .tag(0)
            
            ActivityView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "list.bullet.circle.fill" : "list.bullet.circle")
                    Text("Activity")
                }
                .tag(1)
            
            EnhancedProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.circle.fill" : "person.circle")
                    Text("You")
                }
                .tag(2)
        }
        .accentColor(.black)
        .onChange(of: selectedTab) { _, _ in
            HapticManager.shared.lightImpact()
        }
    }
}

struct PayView: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    @State private var showSendSheet = false
    @State private var showRequestSheet = false
    @State private var balanceScale: Double = 1.0
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 15) {
                        HStack {
                            Spacer()
                            if isRefreshing {
                                PremiumLoadingView(size: 20, color: .gray)
                            } else {
                                Button(action: refreshBalance) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(BounceButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        
                        Text("$\(viewModel.balance, specifier: "%.2f")")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.black)
                            .scaleEffect(balanceScale)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: balanceScale)
                        
                        Text("Available Balance")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    HStack(spacing: 40) {
                        ActionButton(
                            icon: "arrow.up.circle.fill",
                            title: "Pay",
                            color: .black,
                            isLoading: viewModel.paymentState == .loading
                        ) {
                            showSendSheet = true
                        }
                        
                        ActionButton(
                            icon: "arrow.down.circle.fill", 
                            title: "Request",
                            color: .black
                        ) {
                            showRequestSheet = true
                        }
                        
                        ActionButton(
                            icon: "gearshape.circle",
                            title: "Advanced",
                            color: .gray
                        ) {
                            // Advanced options
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Transaction list with shimmer loading
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Recent")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            
                            if viewModel.isLoadingTransactions {
                                PremiumLoadingView(size: 16, color: .gray)
                            }
                        }
                        
                        if viewModel.isLoadingTransactions {
                            // Shimmer loading for transactions
                            ForEach(0..<3, id: \.self) { _ in
                                HStack(spacing: 15) {
                                    ShimmerView(width: 50, height: 50, cornerRadius: 25)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        ShimmerView(width: 120, height: 16, cornerRadius: 8)
                                        ShimmerView(width: 80, height: 12, cornerRadius: 6)
                                    }
                                    
                                    Spacer()
                                    
                                    ShimmerView(width: 60, height: 16, cornerRadius: 8)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                        } else if !viewModel.transactions.isEmpty {
                            ForEach(Array(viewModel.transactions.prefix(3)), id: \.id) { transaction in
                                TransactionRow(transaction: transaction)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Text("No recent transactions")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Text("Start by making your first payment")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("StarkPay")
            .toolbar(.hidden, for: .navigationBar)
            .refreshable {
                await refreshTransactions()
            }
        }
        .sheet(isPresented: $showSendSheet) {
            SendSheet().environmentObject(viewModel)
        }
        .sheet(isPresented: $showRequestSheet) {
            RequestSheet().environmentObject(viewModel)
        }
        .onChange(of: viewModel.balance) { _, _ in
            // Animate balance change
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                balanceScale = 1.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    balanceScale = 1.0
                }
            }
        }
    }
    
    private func refreshBalance() {
        isRefreshing = true
        HapticManager.shared.lightImpact()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRefreshing = false
            HapticManager.shared.selectionChanged()
        }
    }
    
    private func refreshTransactions() async {
        await viewModel.refreshTransactions()
    }
}

struct ActivityView: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var showSearchResults = false
    @State private var searchProgress: Double = 0
    @State private var isRefreshing = false
    
    // Filtered transactions based on search
    var filteredTransactions: [SimpleTransaction] {
        if searchText.isEmpty {
            return viewModel.transactions
        }
        
        let searchLower = searchText.lowercased()
        return viewModel.transactions.filter { transaction in
            // Search by sender/receiver name
            transaction.otherParty.lowercased().contains(searchLower) ||
            // Search by amount
            String(transaction.amount).contains(searchText) ||
            "$\(String(format: "%.2f", transaction.amount))".contains(searchText) ||
            // Search by note
            transaction.note.lowercased().contains(searchLower) ||
            // Search by date (relative format like "2 hours ago")
            transaction.date.formatted(.relative(presentation: .named)).lowercased().contains(searchLower)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar Section
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        // Search Icon
                        Image(systemName: isSearching ? "magnifyingglass.circle.fill" : "magnifyingglass")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isSearching ? .orange : .gray)
                            .scaleEffect(isSearching ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSearching)
                        
                        // Search TextField
                        TextField("Search transactions...", text: $searchText)
                            .font(.system(size: 16, weight: .medium))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isSearching ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1.5)
                                    )
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isSearching = true
                                }
                                HapticManager.shared.lightImpact()
                            }
                        
                        // Clear Search Button
                        if !searchText.isEmpty {
                            Button(action: clearSearch) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .buttonStyle(BounceButtonStyle())
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Search Progress Bar (when searching)
                    if isSearching && !searchText.isEmpty {
                        VStack(spacing: 8) {
                            ProgressView(value: searchProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                .scaleEffect(y: 1.5)
                            
                            Text("Searching \(viewModel.transactions.count) transactions...")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .transition(.opacity)
                        }
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .slide))
                    }
                }
                .background(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                // Transaction List Section
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.isLoadingTransactions {
                            // Shimmer loading for transactions
                            ForEach(0..<6, id: \.self) { _ in
                                TransactionShimmerRow()
                            }
                        } else if filteredTransactions.isEmpty && !searchText.isEmpty {
                            // Empty Search Results State
                            EmptySearchResultsView(searchText: searchText)
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        } else if filteredTransactions.isEmpty {
                            // Empty Activity State
                            EmptyActivityView()
                                .transition(.opacity)
                        } else {
                            // Search Results Header (when searching)
                            if !searchText.isEmpty {
                                SearchResultsHeader(
                                    resultCount: filteredTransactions.count,
                                    totalCount: viewModel.transactions.count,
                                    searchText: searchText
                                )
                                .transition(.opacity.combined(with: .slide))
                            }
                            
                            // Transaction Rows with Enhanced Animation
                            ForEach(Array(filteredTransactions.enumerated()), id: \.element.id) { index, transaction in
                                TransactionRow(transaction: transaction)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.9)).combined(with: .slide),
                                        removal: .opacity.combined(with: .scale(scale: 0.9))
                                    ))
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05),
                                        value: filteredTransactions.count
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await performRefresh()
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .onTapGesture {
                // Dismiss keyboard and search state when tapping outside
                if isSearching {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSearching = false
                    }
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            performSearch(newValue)
        }
    }
    
    private func clearSearch() {
        withAnimation(.easeInOut(duration: 0.3)) {
            searchText = ""
            isSearching = false
            showSearchResults = false
        }
        HapticManager.shared.selectionChanged()
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func performSearch(_ text: String) {
        guard !text.isEmpty else {
            withAnimation(.easeInOut(duration: 0.2)) {
                showSearchResults = false
                searchProgress = 0
            }
            return
        }
        
        // Animate search progress
        withAnimation(.easeInOut(duration: 0.5)) {
            searchProgress = 0.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                searchProgress = 0.8
                showSearchResults = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                searchProgress = 1.0
            }
        }
        
        // Light haptic feedback during search
        HapticManager.shared.lightImpact()
    }
    
    private func performRefresh() async {
        isRefreshing = true
        HapticManager.shared.mediumImpact() // Haptic feedback on pull
        
        // Perform the actual refresh
        await viewModel.refreshTransactions()
        
        // Success haptic feedback
        HapticManager.shared.success()
        isRefreshing = false
    }
}

// MARK: - Supporting Views

struct SearchResultsHeader: View {
    let resultCount: Int
    let totalCount: Int
    let searchText: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(resultCount) result\(resultCount == 1 ? "" : "s")")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("for \"\(searchText)\" in \(totalCount) transactions")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.orange)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.05), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.1), lineWidth: 1)
        )
    }
}

struct EmptySearchResultsView: View {
    let searchText: String
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(animateIcon ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateIcon)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.gray.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text("No results found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("We couldn't find any transactions matching \"\(searchText)\"")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 8) {
                    Text("Try searching for:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text("•")
                            Text("Person's name (alice_crypto, bob_defi)")
                        }
                        HStack(spacing: 4) {
                            Text("•")
                            Text("Amount ($25.00, 12.50)")
                        }
                        HStack(spacing: 4) {
                            Text("•")
                            Text("Transaction notes (lunch, coffee)")
                        }
                        HStack(spacing: 4) {
                            Text("•")
                            Text("Time period (today, yesterday)")
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.8))
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 60)
        .onAppear {
            animateIcon = true
        }
    }
}

struct EmptyActivityView: View {
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(animateIcon ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateIcon)
                
                Image(systemName: "clock.circle")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.orange.opacity(0.8))
            }
            
            VStack(spacing: 12) {
                Text("No activity yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Your transaction history will appear here once you make your first payment")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text("Start by going to the Pay tab!")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 80)
        .onAppear {
            animateIcon = true
        }
    }
}

struct TransactionShimmerRow: View {
    var body: some View {
        HStack(spacing: 15) {
            ShimmerView(width: 50, height: 50, cornerRadius: 25)
            
            VStack(alignment: .leading, spacing: 8) {
                ShimmerView(width: 140, height: 18, cornerRadius: 9)
                ShimmerView(width: 90, height: 14, cornerRadius: 7)
            }
            
            Spacer()
            
            ShimmerView(width: 70, height: 18, cornerRadius: 9)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ProfileView: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    @EnvironmentObject var authManager: BiometricAuthManager
    @State private var showingSecuritySettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 15) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text("SP")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        Text("@starkpay_user")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("david@starkpay.com")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Security Status Card
                    SecurityStatusCard()
                    
                    VStack(spacing: 15) {
                        MenuRow(icon: "person.circle", title: "Edit Profile")
                        MenuRow(icon: "creditcard", title: "Payment Methods")
                        MenuRow(icon: "bell", title: "Notifications")
                        
                        MenuRow(
                            icon: "shield.checkered", 
                            title: "Security",
                            subtitle: authManager.canUseBiometrics && authManager.isBiometricEnabled ? 
                                "\(authManager.getBiometricName()) Enabled" : "Passcode Only",
                            action: {
                                showingSecuritySettings = true
                            }
                        )
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        MenuRow(icon: "gearshape.2", title: "Advanced Options")
                            .foregroundColor(.gray)
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        MenuRow(icon: "questionmark.circle", title: "Help & Support")
                        MenuRow(icon: "info.circle", title: "About")
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("You")
        }
        .sheet(isPresented: $showingSecuritySettings) {
            SecuritySettingsView()
                .environmentObject(authManager)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void
    
    init(icon: String, title: String, color: Color, isLoading: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    if isLoading {
                        PremiumLoadingView(size: 30, color: color)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 30))
                            .foregroundColor(color)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                    .opacity(isLoading ? 0.6 : 1.0)
            }
        }
        .buttonStyle(BounceButtonStyle())
        .disabled(isLoading)
    }
}

struct TransactionRow: View {
    let transaction: SimpleTransaction
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.mediumImpact()
            // Transaction details can be shown here in future
        }) {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: transaction.isReceived ? 
                                    [Color.green, Color.green.opacity(0.8)] : 
                                    [Color.black, Color.gray.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: (transaction.isReceived ? .green : .black).opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: transaction.isReceived ? "arrow.down" : "arrow.up")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.isReceived ? "From \(transaction.otherParty)" : "To \(transaction.otherParty)")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(transaction.date, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(transaction.isReceived ? "+" : "-")$\(transaction.amount, specifier: "%.2f")")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(transaction.isReceived ? .green : .black)
                    
                    if !transaction.note.isEmpty {
                        Text(transaction.note)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
        .background(
            LinearGradient(
                colors: [Color.white, Color.gray.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action
        }
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    @State private var isPressed = false
    
    init(icon: String, title: String, subtitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action?()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray.opacity(0.6))
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.03), Color.gray.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action if needed
        }
    }
}

struct SendSheet: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    @State private var recipient = ""
    @State private var amount = ""
    @State private var note = ""
    @State private var isProcessing = false
    @State private var paymentProgress: Double = 0
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 25) {
                    Text("Pay Someone")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    VStack(spacing: 20) {
                        TextField("To: username or phone", text: $recipient)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.headline)
                            .disabled(isProcessing)
                        
                        TextField("$0.00", text: $amount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title2)
                            .disabled(isProcessing)
                        
                        TextField("What's this for?", text: $note)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.subheadline)
                            .disabled(isProcessing)
                    }
                    .padding()
                    .opacity(isProcessing ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isProcessing)
                    
                    // Payment Progress Indicator
                    if isProcessing {
                        VStack(spacing: 16) {
                            ProgressIndicator(progress: paymentProgress, color: .orange)
                            
                            VStack(spacing: 8) {
                                Text("Processing Payment")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(progressMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .animation(.easeInOut(duration: 0.5), value: progressMessage)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .scale))
                    }
                    
                    Button(action: processPayment) {
                        HStack(spacing: 12) {
                            if isProcessing {
                                PremiumLoadingView(size: 20, color: .white)
                            }
                            
                            Text(isProcessing ? "Processing..." : "Pay $\(amount.isEmpty ? "0.00" : amount)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: isProcessing ? [.gray, .gray.opacity(0.8)] : [.black, .gray.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PremiumButtonStyle(color: .black, isLoading: isProcessing))
                    .disabled(recipient.isEmpty || amount.isEmpty || isProcessing)
                    .padding()
                    
                    Spacer()
                }
                
                // Success Animation Overlay
                if showingSuccess {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        SuccessAnimationView {
                            showingSuccess = false
                            dismiss()
                        }
                    }
                    .transition(.opacity)
                }
                
                // Error Animation Overlay
                if showingError {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ErrorAnimationView(message: errorMessage) {
                                showingError = false
                            }
                            
                            Text(errorMessage)
                                .font(.headline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 40)
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("Pay")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { 
                        HapticManager.shared.lightImpact()
                        if !isProcessing {
                            dismiss() 
                        }
                    }
                    .disabled(isProcessing)
                }
            }
        }
    }
    
    private var progressMessage: String {
        switch paymentProgress {
        case 0..<0.3:
            return "Validating payment details..."
        case 0.3..<0.6:
            return "Processing with StarkNet..."
        case 0.6..<0.9:
            return "Confirming transaction..."
        default:
            return "Almost done..."
        }
    }
    
    private func processPayment() {
        guard let amountValue = Double(amount), !recipient.isEmpty else { return }
        
        isProcessing = true
        paymentProgress = 0
        HapticManager.shared.mediumImpact()
        
        // Animate progress
        animateProgress()
        
        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isProcessing = false
            
            // Simulate success/failure randomly for demo
            let isSuccess = Bool.random()
            
            if isSuccess {
                viewModel.sendPayment(to: recipient, amount: amountValue, note: note)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showingSuccess = true
                }
                HapticManager.shared.success()
            } else {
                errorMessage = "Payment failed. Please try again."
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showingError = true
                }
                HapticManager.shared.error()
            }
        }
    }
    
    private func animateProgress() {
        withAnimation(.easeInOut(duration: 0.8)) {
            paymentProgress = 0.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                paymentProgress = 0.6
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                paymentProgress = 0.9
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut(duration: 0.2)) {
                paymentProgress = 1.0
            }
        }
    }
}

struct RequestSheet: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    @State private var amount = ""
    @State private var note = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Text("Request Payment")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(spacing: 20) {
                    TextField("$0.00", text: $amount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                    
                    TextField("What's this for?", text: $note)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.subheadline)
                }
                .padding()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            Image(systemName: "qrcode")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("QR Code")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
                
                Button(action: {
                    HapticManager.shared.mediumImpact()
                    dismiss()
                }) {
                    Text("Request $\(amount.isEmpty ? "0.00" : amount)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .disabled(amount.isEmpty)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Request")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { 
                        HapticManager.shared.lightImpact()
                        dismiss() 
                    }
                }
            }
        }
    }
}

@MainActor
class StarkPayViewModel: ObservableObject {
    @Published var balance: Double = 1247.83
    @Published var transactions: [SimpleTransaction] = []
    @Published var isConnected = true
    @Published var paymentState: LoadingState = .idle
    @Published var isLoadingTransactions = false
    
    init() {
        setupMockData()
    }
    
    func sendPayment(to recipient: String, amount: Double, note: String) {
        balance -= amount
        
        let newTransaction = SimpleTransaction(
            id: UUID().uuidString,
            amount: amount,
            otherParty: recipient,
            isReceived: false,
            date: Date(),
            note: note
        )
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            transactions.insert(newTransaction, at: 0)
        }
        
        // Heavy haptic feedback for successful payment completion
        HapticManager.shared.success()
    }
    
    func refreshTransactions() async {
        isLoadingTransactions = true
        HapticManager.shared.lightImpact()
        
        // Simulate network refresh
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        let newTransaction = SimpleTransaction(
            id: UUID().uuidString,
            amount: Double.random(in: 5...100),
            otherParty: ["alice_crypto", "bob_defi", "sarah_web3", "mike_stark"].randomElement()!,
            isReceived: Bool.random(),
            date: Date().addingTimeInterval(Double.random(in: -86400...0)),
            note: ["Coffee ☕", "Lunch 🍕", "Gas money ⛽", "Thanks! 🙏"].randomElement()!
        )
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            transactions.insert(newTransaction, at: 0)
            isLoadingTransactions = false
        }
        
        HapticManager.shared.success()
    }
    
    func refreshTransactions() async {
        isLoadingTransactions = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.5)) {
                isLoadingTransactions = false
            }
        }
    }
    
    private func setupMockData() {
        transactions = [
            SimpleTransaction(
                id: "1",
                amount: 25.0,
                otherParty: "alice_crypto",
                isReceived: true,
                date: Date().addingTimeInterval(-1800),
                note: "Thanks for lunch! 🍕"
            ),
            SimpleTransaction(
                id: "2", 
                amount: 12.50,
                otherParty: "bob_defi",
                isReceived: false,
                date: Date().addingTimeInterval(-3600),
                note: "Coffee money ☕"
            ),
            SimpleTransaction(
                id: "3",
                amount: 8.42,
                otherParty: "sarah_web3", 
                isReceived: true,
                date: Date().addingTimeInterval(-86400),
                note: "Split dinner"
            )
        ]
    }
}

struct SimpleTransaction: Identifiable {
    let id: String
    let amount: Double
    let otherParty: String
    let isReceived: Bool
    let date: Date
    let note: String
}

#Preview {
    ContentView()
        .environmentObject(StarkPayViewModel())
        .environmentObject(BiometricAuthManager())
}
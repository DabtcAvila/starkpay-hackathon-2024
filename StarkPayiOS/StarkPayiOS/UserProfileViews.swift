import SwiftUI

// MARK: - Enhanced Profile View

struct EnhancedProfileView: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    @EnvironmentObject var authManager: BiometricAuthManager
    @StateObject private var userManager = UserManager()
    @State private var showingSecuritySettings = false
    @State private var showingEditProfile = false
    @State private var showingAccountSettings = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    if let user = userManager.currentUser {
                        // Profile Header
                        ProfileHeaderView(user: user) {
                            showingEditProfile = true
                        }
                        
                        // Account Stats
                        AccountStatsView(user: user)
                        
                        // Security Status Card
                        SecurityStatusCardView(user: user) {
                            showingSecuritySettings = true
                        }
                        
                        // Menu Options
                        VStack(spacing: 12) {
                            ProfileMenuRow(
                                icon: "person.circle.fill",
                                title: "Edit Profile",
                                subtitle: "Update your personal information",
                                color: .blue
                            ) {
                                showingEditProfile = true
                            }
                            
                            ProfileMenuRow(
                                icon: "creditcard.fill",
                                title: "Payment Methods",
                                subtitle: "Manage cards and bank accounts",
                                color: .green
                            ) {
                                // TODO: Payment methods
                            }
                            
                            ProfileMenuRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                subtitle: "Control your alert preferences",
                                color: .orange
                            ) {
                                // TODO: Notifications
                            }
                            
                            ProfileMenuRow(
                                icon: "shield.checkered",
                                title: "Security & Privacy",
                                subtitle: user.securitySettings.biometricEnabled ? 
                                    "Biometrics enabled" : "Passcode only",
                                color: .red
                            ) {
                                showingSecuritySettings = true
                            }
                            
                            ProfileMenuRow(
                                icon: "gear",
                                title: "Account Settings",
                                subtitle: "Currency, limits, and preferences",
                                color: .gray
                            ) {
                                showingAccountSettings = true
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            ProfileMenuRow(
                                icon: "questionmark.circle.fill",
                                title: "Help & Support",
                                subtitle: "Get help with your account",
                                color: .purple
                            ) {
                                // TODO: Help & Support
                            }
                            
                            ProfileMenuRow(
                                icon: "info.circle.fill",
                                title: "About StarkPay",
                                subtitle: "Version 1.0.0",
                                color: .indigo
                            ) {
                                // TODO: About
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Logout Button
                            Button(action: {
                                showingLogoutAlert = true
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.red.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.red)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Sign Out")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.red)
                                        
                                        Text("Sign out of your account")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color.red.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.1), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    } else {
                        // No user logged in
                        VStack(spacing: 20) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No User Logged In")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 100)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userManager: userManager)
        }
        .sheet(isPresented: $showingSecuritySettings) {
            UserSecuritySettingsView(userManager: userManager)
        }
        .sheet(isPresented: $showingAccountSettings) {
            AccountSettingsView(userManager: userManager)
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                userManager.logout()
            }
        } message: {
            Text("Are you sure you want to sign out of your StarkPay account?")
        }
        .onAppear {
            userManager.loadCurrentUser()
        }
    }
}

// MARK: - Profile Header View

struct ProfileHeaderView: View {
    let user: UserProfile
    let onEdit: () -> Void
    @State private var animateAvatar = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Avatar and Basic Info
            VStack(spacing: 16) {
                // Profile Picture
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateAvatar ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateAvatar)
                    
                    if let imageURL = user.profileImageURL {
                        // In a real app, load image from URL
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Text(user.initials)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        Text(user.initials)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // Edit Button
                    Button(action: onEdit) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                    .buttonStyle(BounceButtonStyle())
                    .offset(x: 35, y: 35)
                }
                
                // User Info
                VStack(spacing: 8) {
                    Text(user.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        KYCStatusBadge(status: user.kycStatus)
                        
                        if user.isEmailVerified {
                            VerificationBadge(text: "Email Verified", color: .green)
                        }
                        
                        if user.isPhoneVerified {
                            VerificationBadge(text: "Phone Verified", color: .blue)
                        }
                    }
                }
            }
            
            // Member Since
            VStack(spacing: 4) {
                Text("Member Since")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(user.memberSince, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.top, 20)
        .onAppear {
            animateAvatar = true
        }
    }
}

struct KYCStatusBadge: View {
    let status: KYCStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.statusIcon)
                .font(.system(size: 12, weight: .medium))
            
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(status.statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.statusColor.opacity(0.1))
        .cornerRadius(8)
    }
}

struct VerificationBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 12, weight: .medium))
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Account Stats View

struct AccountStatsView: View {
    let user: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Account Activity")
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Transactions",
                    value: "\(user.totalTransactions)",
                    icon: "arrow.left.arrow.right",
                    color: .blue
                )
                
                StatCard(
                    title: "Total Volume",
                    value: "$\(user.totalVolume, specifier: "%.2f")",
                    icon: "dollarsign.circle",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Last Login",
                    value: user.lastLoginDate?.formatted(date: .abbreviated, time: .shortened) ?? "Never",
                    icon: "clock",
                    color: .orange,
                    isWide: true
                )
            }
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isWide: Bool
    
    init(title: String, value: String, icon: String, color: Color, isWide: Bool = false) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.isWide = isWide
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(isWide ? .headline : .title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Security Status Card View

struct SecurityStatusCardView: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                HStack {
                    Text("Security Status")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 16) {
                    // Security Level Indicator
                    ZStack {
                        Circle()
                            .fill(securityColor.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: securityIcon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(securityColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(securityTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(securityDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                
                // Security Features
                HStack(spacing: 12) {
                    SecurityFeature(
                        name: "Biometric",
                        enabled: user.securitySettings.biometricEnabled
                    )
                    
                    SecurityFeature(
                        name: "2FA",
                        enabled: user.securitySettings.twoFactorEnabled
                    )
                    
                    SecurityFeature(
                        name: "Notifications",
                        enabled: user.securitySettings.notificationsEnabled
                    )
                    
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(securityColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
    
    private var securityScore: Double {
        var score = 0.3 // Base score
        if user.securitySettings.biometricEnabled { score += 0.3 }
        if user.securitySettings.twoFactorEnabled { score += 0.2 }
        if user.securitySettings.notificationsEnabled { score += 0.1 }
        if user.isEmailVerified { score += 0.05 }
        if user.isPhoneVerified { score += 0.05 }
        return min(score, 1.0)
    }
    
    private var securityColor: Color {
        switch securityScore {
        case 0..<0.5: return .red
        case 0.5..<0.75: return .orange
        default: return .green
        }
    }
    
    private var securityIcon: String {
        switch securityScore {
        case 0..<0.5: return "shield.slash"
        case 0.5..<0.75: return "shield"
        default: return "shield.checkered"
        }
    }
    
    private var securityTitle: String {
        switch securityScore {
        case 0..<0.5: return "Security Needs Attention"
        case 0.5..<0.75: return "Good Security Level"
        default: return "Excellent Security"
        }
    }
    
    private var securityDescription: String {
        switch securityScore {
        case 0..<0.5: return "Enable additional security features to protect your account"
        case 0.5..<0.75: return "Your account has good protection. Consider enabling 2FA"
        default: return "Your account is well protected with multiple security layers"
        }
    }
}

struct SecurityFeature: View {
    let name: String
    let enabled: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(enabled ? .green : .gray)
            
            Text(name)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(enabled ? .primary : .gray)
        }
    }
}

// MARK: - Profile Menu Row

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
                .scaleEffect(isPressed ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action if needed
        }
    }
}

#Preview {
    EnhancedProfileView()
        .environmentObject(StarkPayViewModel())
        .environmentObject(BiometricAuthManager())
}
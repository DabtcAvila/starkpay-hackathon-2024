import Foundation
import SwiftUI

// MARK: - User Registration Statistics and Evidence

struct UserRegistrationStats {
    
    static func generateRegistrationEvidence() -> RegistrationEvidence {
        let users = UserStorage.loadRegisteredUsers()
        let statistics = UserStorage.getUserStatistics()
        
        return RegistrationEvidence(
            totalRegisteredUsers: statistics.totalUsers,
            verifiedUsers: statistics.verifiedUsers,
            activeUsers: statistics.activeUsers,
            demoUsers: users.filter { $0.id.hasPrefix("demo_user") }.count,
            realUsers: users.filter { !$0.id.hasPrefix("demo_user") }.count,
            averageTransactions: users.isEmpty ? 0.0 : Double(users.reduce(0) { $0 + $1.totalTransactions }) / Double(users.count),
            totalTransactionVolume: users.reduce(0.0) { $0 + $1.totalVolume },
            usersByKYCStatus: getUsersByKYCStatus(users),
            userRegistrationTimeline: getUserRegistrationTimeline(users),
            securityFeatureAdoption: getSecurityFeatureAdoption(users),
            deviceBiometricSupport: getBiometricSupport(),
            implementationDetails: getImplementationDetails()
        )
    }
    
    private static func getUsersByKYCStatus(_ users: [UserProfile]) -> [String: Int] {
        var kycCount: [String: Int] = [:]
        
        for status in KYCStatus.allCases {
            kycCount[status.rawValue] = users.filter { $0.kycStatus == status }.count
        }
        
        return kycCount
    }
    
    private static func getUserRegistrationTimeline(_ users: [UserProfile]) -> [RegistrationTimelineEntry] {
        let sortedUsers = users.sorted { $0.memberSince < $1.memberSince }
        var timeline: [RegistrationTimelineEntry] = []
        
        let calendar = Calendar.current
        let now = Date()
        
        // Group by day for the last 30 days
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let registrationsOnDay = sortedUsers.filter { user in
                user.memberSince >= startOfDay && user.memberSince < endOfDay
            }.count
            
            if registrationsOnDay > 0 {
                timeline.append(RegistrationTimelineEntry(
                    date: startOfDay,
                    registrations: registrationsOnDay
                ))
            }
        }
        
        return timeline.reversed()
    }
    
    private static func getSecurityFeatureAdoption(_ users: [UserProfile]) -> SecurityFeatureStats {
        let totalUsers = users.count
        guard totalUsers > 0 else {
            return SecurityFeatureStats(
                biometricEnabledPercentage: 0,
                twoFactorEnabledPercentage: 0,
                notificationsEnabledPercentage: 0,
                transactionLimitsPercentage: 0
            )
        }
        
        let biometricEnabled = users.filter { $0.securitySettings.biometricEnabled }.count
        let twoFactorEnabled = users.filter { $0.securitySettings.twoFactorEnabled }.count
        let notificationsEnabled = users.filter { $0.securitySettings.notificationsEnabled }.count
        let transactionLimitsEnabled = users.filter { $0.securitySettings.transactionLimitsEnabled }.count
        
        return SecurityFeatureStats(
            biometricEnabledPercentage: Double(biometricEnabled) / Double(totalUsers) * 100,
            twoFactorEnabledPercentage: Double(twoFactorEnabled) / Double(totalUsers) * 100,
            notificationsEnabledPercentage: Double(notificationsEnabled) / Double(totalUsers) * 100,
            transactionLimitsPercentage: Double(transactionLimitsEnabled) / Double(totalUsers) * 100
        )
    }
    
    private static func getBiometricSupport() -> BiometricSupportInfo {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        return BiometricSupportInfo(
            isAvailable: canEvaluate,
            biometricType: context.biometryType,
            deviceModel: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion
        )
    }
    
    private static func getImplementationDetails() -> ImplementationDetails {
        return ImplementationDetails(
            storageMethod: "UserDefaults + JSON Encoding",
            authenticationMethods: ["Email/Password", "Biometric", "Demo Accounts"],
            dataEncryption: "Local device encryption via UserDefaults",
            userDataFields: [
                "id", "email", "firstName", "lastName", "username", "phoneNumber",
                "preferredCurrency", "isEmailVerified", "isPhoneVerified",
                "memberSince", "lastLoginDate", "totalTransactions", "totalVolume",
                "kycStatus", "securitySettings"
            ],
            securityFeatures: [
                "Biometric Authentication", "Device Passcode Fallback",
                "Session Management", "Automatic Screen Lock",
                "Secure Local Storage", "User Privacy Controls"
            ],
            demoAccountsAvailable: true,
            realUserRegistrationEnabled: true,
            persistentDataStorage: true,
            crossDeviceSync: false,
            backendIntegration: false
        )
    }
}

// MARK: - Evidence Data Models

struct RegistrationEvidence {
    let totalRegisteredUsers: Int
    let verifiedUsers: Int
    let activeUsers: Int
    let demoUsers: Int
    let realUsers: Int
    let averageTransactions: Double
    let totalTransactionVolume: Double
    let usersByKYCStatus: [String: Int]
    let userRegistrationTimeline: [RegistrationTimelineEntry]
    let securityFeatureAdoption: SecurityFeatureStats
    let deviceBiometricSupport: BiometricSupportInfo
    let implementationDetails: ImplementationDetails
    
    var evidenceScore: Int {
        // Calculate points based on registered users (1 point per user)
        return totalRegisteredUsers
    }
    
    var summaryReport: String {
        return """
        # StarkPay User Registration System - VAL-003 Evidence
        
        ## Registration Statistics
        - **Total Registered Users:** \(totalRegisteredUsers)
        - **Verified Users:** \(verifiedUsers)
        - **Active Users (7 days):** \(activeUsers)
        - **Demo Accounts:** \(demoUsers)
        - **Real User Accounts:** \(realUsers)
        
        ## User Engagement
        - **Average Transactions per User:** \(String(format: "%.1f", averageTransactions))
        - **Total Transaction Volume:** $\(String(format: "%.2f", totalTransactionVolume))
        
        ## KYC Status Distribution
        \(usersByKYCStatus.map { "- \($0.key): \($0.value) users" }.joined(separator: "\n"))
        
        ## Security Adoption
        - **Biometric Auth:** \(String(format: "%.1f", securityFeatureAdoption.biometricEnabledPercentage))%
        - **Two-Factor Auth:** \(String(format: "%.1f", securityFeatureAdoption.twoFactorEnabledPercentage))%
        - **Notifications:** \(String(format: "%.1f", securityFeatureAdoption.notificationsEnabledPercentage))%
        
        ## Implementation Details
        - **Storage Method:** \(implementationDetails.storageMethod)
        - **Authentication Methods:** \(implementationDetails.authenticationMethods.joined(separator: ", "))
        - **Security Features:** \(implementationDetails.securityFeatures.count) implemented
        - **Data Persistence:** \(implementationDetails.persistentDataStorage ? "Yes" : "No")
        
        ## Evidence Score: \(evidenceScore) points
        """
    }
}

struct RegistrationTimelineEntry {
    let date: Date
    let registrations: Int
}

struct SecurityFeatureStats {
    let biometricEnabledPercentage: Double
    let twoFactorEnabledPercentage: Double
    let notificationsEnabledPercentage: Double
    let transactionLimitsPercentage: Double
}

struct BiometricSupportInfo {
    let isAvailable: Bool
    let biometricType: LABiometryType
    let deviceModel: String
    let systemVersion: String
    
    var biometricTypeName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Not Available"
        }
    }
}

struct ImplementationDetails {
    let storageMethod: String
    let authenticationMethods: [String]
    let dataEncryption: String
    let userDataFields: [String]
    let securityFeatures: [String]
    let demoAccountsAvailable: Bool
    let realUserRegistrationEnabled: Bool
    let persistentDataStorage: Bool
    let crossDeviceSync: Bool
    let backendIntegration: Bool
}

// MARK: - Registration Evidence View

struct RegistrationEvidenceView: View {
    @State private var evidence: RegistrationEvidence?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                if let evidence = evidence {
                    VStack(spacing: 25) {
                        // Header Stats
                        EvidenceStatsGrid(evidence: evidence)
                        
                        // User Distribution
                        UserDistributionCard(evidence: evidence)
                        
                        // KYC Status Chart
                        KYCStatusCard(evidence: evidence)
                        
                        // Security Adoption
                        SecurityAdoptionCard(evidence: evidence)
                        
                        // Implementation Details
                        ImplementationDetailsCard(evidence: evidence)
                        
                        // Evidence Score
                        EvidenceScoreCard(evidence: evidence)
                    }
                    .padding(.horizontal)
                } else if isLoading {
                    VStack(spacing: 20) {
                        PremiumLoadingView(size: 50, color: .orange)
                        Text("Generating Evidence...")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 100)
                } else {
                    Text("Failed to load evidence")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 100)
                }
            }
            .navigationTitle("VAL-003 Evidence")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Export") {
                        exportEvidence()
                    }
                    .disabled(evidence == nil)
                }
            }
        }
        .onAppear {
            loadEvidence()
        }
    }
    
    private func loadEvidence() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            evidence = UserRegistrationStats.generateRegistrationEvidence()
            isLoading = false
        }
    }
    
    private func exportEvidence() {
        guard let evidence = evidence else { return }
        
        // In a real app, this would export to files or share
        print(evidence.summaryReport)
        UIPasteboard.general.string = evidence.summaryReport
        HapticManager.shared.success()
    }
}

// MARK: - Evidence Display Components

struct EvidenceStatsGrid: View {
    let evidence: RegistrationEvidence
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            EvidenceStatCard(
                title: "Total Users",
                value: "\(evidence.totalRegisteredUsers)",
                icon: "person.2.fill",
                color: .blue
            )
            
            EvidenceStatCard(
                title: "Active Users",
                value: "\(evidence.activeUsers)",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            EvidenceStatCard(
                title: "Verified Users",
                value: "\(evidence.verifiedUsers)",
                icon: "checkmark.shield.fill",
                color: .orange
            )
            
            EvidenceStatCard(
                title: "Points Earned",
                value: "\(evidence.evidenceScore)",
                icon: "star.fill",
                color: .yellow
            )
        }
    }
}

struct EvidenceStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct UserDistributionCard: View {
    let evidence: RegistrationEvidence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("User Distribution")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                DistributionBar(
                    demoUsers: evidence.demoUsers,
                    realUsers: evidence.realUsers,
                    totalUsers: evidence.totalRegisteredUsers
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    DistributionLegend(
                        color: .orange,
                        label: "Demo Users",
                        count: evidence.demoUsers
                    )
                    
                    DistributionLegend(
                        color: .blue,
                        label: "Real Users",
                        count: evidence.realUsers
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct DistributionBar: View {
    let demoUsers: Int
    let realUsers: Int
    let totalUsers: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: demoPercentage * 200, height: 20)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: realPercentage * 200, height: 20)
            }
            .cornerRadius(10)
            
            Text("\(totalUsers) total users")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var demoPercentage: Double {
        totalUsers > 0 ? Double(demoUsers) / Double(totalUsers) : 0
    }
    
    private var realPercentage: Double {
        totalUsers > 0 ? Double(realUsers) / Double(totalUsers) : 0
    }
}

struct DistributionLegend: View {
    let color: Color
    let label: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text("\(label): \(count)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct KYCStatusCard: View {
    let evidence: RegistrationEvidence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("KYC Verification Status")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(Array(evidence.usersByKYCStatus.keys.sorted()), id: \.self) { status in
                    if let count = evidence.usersByKYCStatus[status] {
                        KYCStatusRow(
                            status: KYCStatus(rawValue: status) ?? .notStarted,
                            count: count
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct KYCStatusRow: View {
    let status: KYCStatus
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: status.statusIcon)
                .foregroundColor(status.statusColor)
                .frame(width: 20)
            
            Text(status.displayName)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(status.statusColor)
        }
    }
}

struct SecurityAdoptionCard: View {
    let evidence: RegistrationEvidence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Security Feature Adoption")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                SecurityAdoptionRow(
                    title: "Biometric Authentication",
                    percentage: evidence.securityFeatureAdoption.biometricEnabledPercentage,
                    color: .blue
                )
                
                SecurityAdoptionRow(
                    title: "Two-Factor Authentication",
                    percentage: evidence.securityFeatureAdoption.twoFactorEnabledPercentage,
                    color: .green
                )
                
                SecurityAdoptionRow(
                    title: "Security Notifications",
                    percentage: evidence.securityFeatureAdoption.notificationsEnabledPercentage,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SecurityAdoptionRow: View {
    let title: String
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(Int(percentage))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            ProgressView(value: percentage / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 2)
        }
    }
}

struct ImplementationDetailsCard: View {
    let evidence: RegistrationEvidence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Implementation Details")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(title: "Storage Method", value: evidence.implementationDetails.storageMethod)
                DetailRow(title: "Authentication", value: evidence.implementationDetails.authenticationMethods.joined(separator: ", "))
                DetailRow(title: "Security Features", value: "\(evidence.implementationDetails.securityFeatures.count) implemented")
                DetailRow(title: "Persistent Storage", value: evidence.implementationDetails.persistentDataStorage ? "Yes" : "No")
                DetailRow(title: "Demo Accounts", value: evidence.implementationDetails.demoAccountsAvailable ? "Available" : "Not Available")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
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
                .multilineTextAlignment(.trailing)
        }
    }
}

struct EvidenceScoreCard: View {
    let evidence: RegistrationEvidence
    
    var body: some View {
        VStack(spacing: 16) {
            Text("VAL-003 Evidence Score")
                .font(.title2)
                .fontWeight(.bold)
            
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: min(Double(evidence.evidenceScore) / 10.0, 1.0))
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: evidence.evidenceScore)
                
                VStack {
                    Text("\(evidence.evidenceScore)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("points")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Text("1 point awarded per registered user")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 2)
                )
        )
    }
}

#Preview {
    RegistrationEvidenceView()
}
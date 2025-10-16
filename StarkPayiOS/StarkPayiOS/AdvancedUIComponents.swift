import SwiftUI
import UIKit

// MARK: - Advanced UI Components for StarkPay

// MARK: - Premium Button with Advanced Features
struct PremiumButton: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let action: () -> Void
    
    var style: Style = .primary
    var size: Size = .large
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var hapticType: HapticManager.HapticTestPattern = .medium
    
    @State private var isPressed = false
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    enum Style {
        case primary, secondary, outline, ghost, destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .orange
            case .secondary: return Color(.systemGray5)
            case .outline: return .clear
            case .ghost: return .clear
            case .destructive: return .red
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive: return .white
            case .secondary: return .primary
            case .outline, .ghost: return .orange
            }
        }
        
        var borderColor: Color {
            switch self {
            case .outline: return .orange
            default: return .clear
            }
        }
    }
    
    enum Size {
        case small, medium, large, extraLarge
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 52
            case .extraLarge: return 60
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            case .extraLarge: return 20
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 18
            case .large: return 20
            case .extraLarge: return 24
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
            case .extraLarge: return EdgeInsets(top: 20, leading: 28, bottom: 20, trailing: 28)
            }
        }
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                HapticManager.shared.testHapticPattern(hapticType)
                action()
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .medium))
                        .foregroundColor(style.foregroundColor)
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .dynamicTypeSize(size.fontSize, weight: .semibold)
                        .foregroundColor(style.foregroundColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .dynamicTypeSize(size.fontSize - 2, weight: .regular)
                            .foregroundColor(style.foregroundColor.opacity(0.8))
                    }
                }
            }
            .padding(size.padding)
            .frame(minHeight: accessibilityManager.getRecommendedButtonSize())
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style.borderColor, lineWidth: 2)
                    )
            )
            .opacity(isDisabled ? 0.6 : 1.0)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibleButton(
            label: title,
            hint: subtitle ?? "Double tap to activate"
        )
        .disabled(isLoading || isDisabled)
    }
}

// MARK: - Advanced Card Component
struct AdvancedCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var style: Style = .elevated
    var padding: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
    var cornerRadius: CGFloat = 16
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    enum Style {
        case flat, elevated, outlined, glass
        
        var backgroundColor: Color {
            switch self {
            case .flat: return Color(.systemGray6)
            case .elevated: return Color(.systemBackground)
            case .outlined: return Color(.systemBackground)
            case .glass: return Color.black.opacity(0.1)
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .flat, .outlined: return 0
            case .elevated: return 8
            case .glass: return 12
            }
        }
        
        var shadowOpacity: Double {
            switch self {
            case .flat, .outlined: return 0
            case .elevated: return 0.1
            case .glass: return 0.3
            }
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .outlined: return 1
            default: return 0
            }
        }
        
        var borderColor: Color {
            return Color(.systemGray4)
        }
    }
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(style.borderColor, lineWidth: style.borderWidth)
                    )
                    .shadow(
                        color: .black.opacity(style.shadowOpacity),
                        radius: style.shadowRadius,
                        x: 0,
                        y: style.shadowRadius / 2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                if onTap != nil {
                    isPressed = pressing
                }
            }, perform: {})
    }
}

// MARK: - Advanced Input Field
struct AdvancedTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String?
    
    var style: Style = .standard
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var validation: ValidationRule? = nil
    var onEditingChanged: ((Bool) -> Void)? = nil
    var onCommit: (() -> Void)? = nil
    
    @State private var isEditing = false
    @State private var showingValidation = false
    @State private var isSecureVisible = false
    @FocusState private var isFocused: Bool
    
    enum Style {
        case standard, outlined, underlined, floating
    }
    
    struct ValidationRule {
        let message: String
        let isValid: (String) -> Bool
    }
    
    private var isValid: Bool {
        validation?.isValid(text) ?? true
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isEditing ? .orange : (showingValidation && !isValid ? .red : .clear),
                                lineWidth: 2
                            )
                    )
                
                HStack(spacing: 12) {
                    // Icon
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(.gray)
                            .frame(width: 20)
                    }
                    
                    // Text Field
                    ZStack(alignment: .leading) {
                        if text.isEmpty && !isEditing {
                            Text(placeholder)
                                .foregroundColor(.gray)
                        }
                        
                        Group {
                            if isSecure && !isSecureVisible {
                                SecureField("", text: $text)
                            } else {
                                TextField("", text: $text)
                                    .keyboardType(keyboardType)
                            }
                        }
                        .focused($isFocused)
                        .onEditingChange { editing in
                            isEditing = editing
                            if !editing {
                                showingValidation = true
                            }
                            onEditingChanged?(editing)
                        }
                        .onSubmit {
                            showingValidation = true
                            onCommit?()
                        }
                    }
                    
                    // Secure toggle button
                    if isSecure {
                        Button(action: { isSecureVisible.toggle() }) {
                            Image(systemName: isSecureVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Validation indicator
                    if showingValidation {
                        Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isValid ? .green : .red)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Validation message
            if showingValidation && !isValid, let validation = validation {
                Text(validation.message)
                    .dynamicTypeSize(12)
                    .foregroundColor(.red)
                    .slideIn(isVisible: true, from: .top, distance: 10)
            }
        }
        .onChange(of: text) { _ in
            if showingValidation {
                showingValidation = true
            }
        }
        .accessibleText(
            label: placeholder,
            hint: validation?.message ?? "Enter text"
        )
    }
}

// MARK: - Progress Indicator with Animation
struct AdvancedProgressView: View {
    let progress: Double
    let total: Double
    
    var style: Style = .circular
    var size: Size = .medium
    var showPercentage: Bool = true
    var animated: Bool = true
    
    @State private var animatedProgress: Double = 0
    
    enum Style {
        case linear, circular, ring
    }
    
    enum Size {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 60
            case .large: return 80
            }
        }
        
        var lineWidth: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
    
    private var progressPercentage: Double {
        return min(max(progress / total, 0), 1)
    }
    
    var body: some View {
        Group {
            switch style {
            case .linear:
                linearProgress
            case .circular:
                circularProgress
            case .ring:
                ringProgress
            }
        }
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedProgress = progressPercentage
                }
            } else {
                animatedProgress = progressPercentage
            }
        }
        .onChange(of: progressPercentage) { newValue in
            if animated {
                withAnimation(.easeOut(duration: 0.5)) {
                    animatedProgress = newValue
                }
            } else {
                animatedProgress = newValue
            }
        }
        .accessibleText(
            label: "Progress: \(Int(progressPercentage * 100)) percent complete"
        )
    }
    
    private var linearProgress: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(height: size.lineWidth)
                        .foregroundColor(Color(.systemGray5))
                        .cornerRadius(size.lineWidth / 2)
                    
                    Rectangle()
                        .frame(
                            width: geometry.size.width * animatedProgress,
                            height: size.lineWidth
                        )
                        .foregroundColor(.orange)
                        .cornerRadius(size.lineWidth / 2)
                }
            }
            .frame(height: size.lineWidth)
            
            if showPercentage {
                Text("\(Int(progressPercentage * 100))%")
                    .dynamicTypeSize(14, weight: .medium)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var circularProgress: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: size.dimension, height: size.dimension)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
                )
                .frame(width: size.dimension - size.lineWidth, height: size.dimension - size.lineWidth)
                .rotationEffect(.degrees(-90))
            
            if showPercentage {
                Text("\(Int(progressPercentage * 100))%")
                    .dynamicTypeSize(size.dimension / 5, weight: .semibold)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var ringProgress: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: size.lineWidth)
                .frame(width: size.dimension, height: size.dimension)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(.orange, style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round))
                .frame(width: size.dimension, height: size.dimension)
                .rotationEffect(.degrees(-90))
            
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(progressPercentage * 100))")
                        .dynamicTypeSize(size.dimension / 4, weight: .bold)
                        .foregroundColor(.primary)
                    Text("%")
                        .dynamicTypeSize(size.dimension / 6, weight: .medium)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Advanced Toggle Switch
struct AdvancedToggle: View {
    @Binding var isOn: Bool
    let title: String
    let subtitle: String?
    let icon: String?
    
    var style: Style = .standard
    var size: Size = .medium
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    enum Style {
        case standard, card, minimal
    }
    
    enum Size {
        case small, medium, large
        
        var toggleWidth: CGFloat {
            switch self {
            case .small: return 44
            case .medium: return 52
            case .large: return 60
            }
        }
        
        var toggleHeight: CGFloat {
            return toggleWidth * 0.6
        }
        
        var knobSize: CGFloat {
            return toggleHeight - 4
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .dynamicTypeSize(16, weight: .medium)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .dynamicTypeSize(14)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Custom toggle
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: size.toggleHeight / 2)
                    .fill(isOn ? .orange : Color(.systemGray4))
                    .frame(width: size.toggleWidth, height: size.toggleHeight)
                    .animation(.spring(response: 0.3), value: isOn)
                
                Circle()
                    .fill(.white)
                    .frame(width: size.knobSize, height: size.knobSize)
                    .padding(2)
                    .offset(x: dragOffset)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .animation(.spring(response: 0.3), value: isOn)
            }
            .onTapGesture {
                HapticManager.shared.toggleSwitch(isOn: !isOn)
                isOn.toggle()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        let maxOffset = (size.toggleWidth - size.knobSize) / 2
                        dragOffset = min(max(value.translation.x, -maxOffset), maxOffset)
                    }
                    .onEnded { value in
                        isDragging = false
                        dragOffset = 0
                        
                        let threshold: CGFloat = size.toggleWidth * 0.3
                        if abs(value.translation.x) > threshold {
                            let newValue = value.translation.x > 0
                            if newValue != isOn {
                                HapticManager.shared.toggleSwitch(isOn: newValue)
                                isOn = newValue
                            }
                        }
                    }
            )
        }
        .padding(style == .card ? 16 : 0)
        .background(
            Group {
                if style == .card {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                }
            }
        )
        .accessibleButton(
            label: "\(title). \(isOn ? "On" : "Off")",
            hint: subtitle ?? "Double tap to toggle"
        )
    }
}

// MARK: - Notification Banner
struct NotificationBanner: View {
    let title: String
    let message: String
    let type: NotificationType
    let action: (() -> Void)?
    
    @Binding var isVisible: Bool
    @State private var dragOffset: CGFloat = 0
    
    enum NotificationType {
        case success, warning, error, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .dynamicTypeSize(16, weight: .semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .dynamicTypeSize(14)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let action = action {
                Button("Action") {
                    action()
                    isVisible = false
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(type.color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.y < 0 {
                        dragOffset = value.translation.y
                    }
                }
                .onEnded { value in
                    if value.translation.y < -100 {
                        isVisible = false
                    }
                    dragOffset = 0
                }
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
        .accessibleText(
            label: "\(type) notification: \(title). \(message)",
            traits: .isStaticText
        )
    }
}
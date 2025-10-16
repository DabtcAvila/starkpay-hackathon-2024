import SwiftUI
import UIKit
import AVFoundation

// MARK: - Comprehensive Accessibility Manager for Inclusive Design

/// Advanced accessibility system ensuring StarkPay is usable by everyone
@MainActor
class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    // MARK: - Published Properties
    @Published var isVoiceOverEnabled = false
    @Published var isSwitchControlEnabled = false
    @Published var isAssistiveTouchEnabled = false
    @Published var isReduceMotionEnabled = false
    @Published var isReduceTransparencyEnabled = false
    @Published var isIncreaseContrastEnabled = false
    @Published var isBoldTextEnabled = false
    @Published var preferredContentSizeCategory: ContentSizeCategory = .medium
    @Published var isHighContrastModeEnabled = false
    @Published var isButtonShapesEnabled = false
    @Published var isOnOffLabelsEnabled = false
    
    // Custom accessibility settings
    @Published var hapticFeedbackLevel: HapticLevel = .standard
    @Published var isAudioDescriptionsEnabled = false
    @Published var isSimplifiedUIEnabled = false
    @Published var fontSizeMultiplier: Double = 1.0
    @Published var colorBlindnessType: ColorBlindnessType = .none
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var accessibilityObservers: [NSObjectProtocol] = []
    
    enum HapticLevel: String, CaseIterable {
        case off = "Off"
        case minimal = "Minimal"
        case standard = "Standard"
        case enhanced = "Enhanced"
        
        var multiplier: Float {
            switch self {
            case .off: return 0.0
            case .minimal: return 0.3
            case .standard: return 1.0
            case .enhanced: return 1.5
            }
        }
    }
    
    enum ColorBlindnessType: String, CaseIterable {
        case none = "None"
        case protanopia = "Protanopia (Red-blind)"
        case deuteranopia = "Deuteranopia (Green-blind)"
        case tritanopia = "Tritanopia (Blue-blind)"
        case monochromacy = "Monochromacy"
        
        var description: String {
            switch self {
            case .none: return "No color vision adjustment"
            case .protanopia: return "Difficulty distinguishing red colors"
            case .deuteranopia: return "Difficulty distinguishing green colors"
            case .tritanopia: return "Difficulty distinguishing blue colors"
            case .monochromacy: return "Complete color blindness"
            }
        }
    }
    
    private init() {
        setupAccessibilityObservers()
        updateAccessibilityStatus()
        loadCustomSettings()
    }
    
    deinit {
        accessibilityObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    // MARK: - Setup and Configuration
    
    private func setupAccessibilityObservers() {
        let notifications: [Notification.Name] = [
            UIAccessibility.voiceOverStatusDidChangeNotification,
            UIAccessibility.switchControlStatusDidChangeNotification,
            UIAccessibility.assistiveTouchStatusDidChangeNotification,
            UIAccessibility.reduceMotionStatusDidChangeNotification,
            UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            UIAccessibility.boldTextStatusDidChangeNotification,
            UIContentSizeCategory.didChangeNotification,
            UIAccessibility.buttonShapesEnabledStatusDidChangeNotification,
            UIAccessibility.onOffSwitchLabelsDidChangeNotification
        ]
        
        for notification in notifications {
            let observer = NotificationCenter.default.addObserver(
                forName: notification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            accessibilityObservers.append(observer)
        }
    }
    
    private func updateAccessibilityStatus() {
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
        isAssistiveTouchEnabled = UIAccessibility.isAssistiveTouchRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        isIncreaseContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        isButtonShapesEnabled = UIAccessibility.isButtonShapesEnabled
        isOnOffLabelsEnabled = UIAccessibility.isOnOffSwitchLabelsEnabled
        
        // Update content size category
        let sizeCategory = UIApplication.shared.preferredContentSizeCategory
        preferredContentSizeCategory = ContentSizeCategory(from: sizeCategory)
    }
    
    private func loadCustomSettings() {
        let defaults = UserDefaults.standard
        
        if let hapticLevelString = defaults.object(forKey: "accessibility_haptic_level") as? String,
           let hapticLevel = HapticLevel(rawValue: hapticLevelString) {
            self.hapticFeedbackLevel = hapticLevel
        }
        
        isAudioDescriptionsEnabled = defaults.bool(forKey: "accessibility_audio_descriptions")
        isSimplifiedUIEnabled = defaults.bool(forKey: "accessibility_simplified_ui")
        fontSizeMultiplier = defaults.double(forKey: "accessibility_font_multiplier")
        if fontSizeMultiplier == 0 { fontSizeMultiplier = 1.0 }
        
        if let colorBlindnessString = defaults.object(forKey: "accessibility_color_blindness") as? String,
           let colorBlindness = ColorBlindnessType(rawValue: colorBlindnessString) {
            self.colorBlindnessType = colorBlindness
        }
        
        isHighContrastModeEnabled = defaults.bool(forKey: "accessibility_high_contrast")
    }
    
    // MARK: - Settings Management
    
    func updateCustomSettings(
        hapticLevel: HapticLevel? = nil,
        audioDescriptions: Bool? = nil,
        simplifiedUI: Bool? = nil,
        fontMultiplier: Double? = nil,
        colorBlindness: ColorBlindnessType? = nil,
        highContrast: Bool? = nil
    ) {
        let defaults = UserDefaults.standard
        
        if let hapticLevel = hapticLevel {
            self.hapticFeedbackLevel = hapticLevel
            defaults.set(hapticLevel.rawValue, forKey: "accessibility_haptic_level")
        }
        
        if let audioDescriptions = audioDescriptions {
            self.isAudioDescriptionsEnabled = audioDescriptions
            defaults.set(audioDescriptions, forKey: "accessibility_audio_descriptions")
        }
        
        if let simplifiedUI = simplifiedUI {
            self.isSimplifiedUIEnabled = simplifiedUI
            defaults.set(simplifiedUI, forKey: "accessibility_simplified_ui")
        }
        
        if let fontMultiplier = fontMultiplier {
            self.fontSizeMultiplier = max(0.5, min(3.0, fontMultiplier))
            defaults.set(self.fontSizeMultiplier, forKey: "accessibility_font_multiplier")
        }
        
        if let colorBlindness = colorBlindness {
            self.colorBlindnessType = colorBlindness
            defaults.set(colorBlindness.rawValue, forKey: "accessibility_color_blindness")
        }
        
        if let highContrast = highContrast {
            self.isHighContrastModeEnabled = highContrast
            defaults.set(highContrast, forKey: "accessibility_high_contrast")
        }
        
        // Update haptic manager with new settings
        if let hapticLevel = hapticLevel {
            HapticManager.shared.updateHapticSettings(
                enabled: hapticLevel != .off,
                intensity: hapticLevel.multiplier
            )
        }
    }
    
    // MARK: - Text-to-Speech
    
    func speak(_ text: String, priority: SpeechPriority = .normal, language: String = "en-US") {
        guard isVoiceOverEnabled || isAudioDescriptionsEnabled else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = getOptimalSpeechRate()
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        switch priority {
        case .high:
            speechSynthesizer.stopSpeaking(at: .immediate)
            speechSynthesizer.speak(utterance)
        case .normal:
            speechSynthesizer.speak(utterance)
        case .background:
            if !speechSynthesizer.isSpeaking {
                speechSynthesizer.speak(utterance)
            }
        }
    }
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    private func getOptimalSpeechRate() -> Float {
        // Adjust speech rate based on content size category
        switch preferredContentSizeCategory {
        case .extraSmall, .small: return 0.6
        case .medium, .large: return 0.5
        case .extraLarge, .extraExtraLarge: return 0.45
        case .extraExtraExtraLarge, .accessibilityMedium: return 0.4
        case .accessibilityLarge, .accessibilityExtraLarge: return 0.35
        case .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge: return 0.3
        @unknown default: return 0.5
        }
    }
    
    enum SpeechPriority {
        case high, normal, background
    }
    
    // MARK: - Color Adjustments for Color Blindness
    
    func adjustedColor(_ color: Color) -> Color {
        guard colorBlindnessType != .none else { return color }
        
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let adjustedRGB = adjustColorForColorBlindness(red: red, green: green, blue: blue)
        return Color(.sRGB, red: adjustedRGB.red, green: adjustedRGB.green, blue: adjustedRGB.blue, opacity: alpha)
    }
    
    private func adjustColorForColorBlindness(red: CGFloat, green: CGFloat, blue: CGFloat) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        switch colorBlindnessType {
        case .none:
            return (red, green, blue)
            
        case .protanopia:
            // Simulate protanopia (red-blind)
            let newRed = 0.567 * red + 0.433 * green
            let newGreen = 0.558 * red + 0.442 * green
            return (newRed, newGreen, blue)
            
        case .deuteranopia:
            // Simulate deuteranopia (green-blind)
            let newRed = 0.625 * red + 0.375 * green
            let newGreen = 0.7 * red + 0.3 * green
            return (newRed, newGreen, blue)
            
        case .tritanopia:
            // Simulate tritanopia (blue-blind)
            let newGreen = 0.95 * green + 0.05 * blue
            let newBlue = 0.433 * green + 0.567 * blue
            return (red, newGreen, newBlue)
            
        case .monochromacy:
            // Convert to grayscale
            let gray = 0.299 * red + 0.587 * green + 0.114 * blue
            return (gray, gray, gray)
        }
    }
    
    // MARK: - High Contrast Colors
    
    func highContrastColor(foreground: Color, background: Color) -> Color {
        guard isHighContrastModeEnabled || isIncreaseContrastEnabled else { return foreground }
        
        let fgLuminance = calculateLuminance(foreground)
        let bgLuminance = calculateLuminance(background)
        
        let contrastRatio = (max(fgLuminance, bgLuminance) + 0.05) / (min(fgLuminance, bgLuminance) + 0.05)
        
        // If contrast ratio is too low, return a high contrast alternative
        if contrastRatio < 4.5 {
            return bgLuminance > 0.5 ? .black : .white
        }
        
        return foreground
    }
    
    private func calculateLuminance(_ color: Color) -> Double {
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        func sRGBtoLin(_ colorChannel: CGFloat) -> Double {
            let channel = Double(colorChannel)
            return channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        
        let r = sRGBtoLin(red)
        let g = sRGBtoLin(green)
        let b = sRGBtoLin(blue)
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    // MARK: - Dynamic Font Scaling
    
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        let scaledSize = size * fontSizeMultiplier
        return .system(size: scaledSize, weight: weight, design: design)
    }
    
    func scaledValue(_ value: CGFloat) -> CGFloat {
        return value * fontSizeMultiplier
    }
    
    // MARK: - Accessibility Announcements
    
    func announcePaymentStart(_ amount: String, recipient: String) {
        let message = "Starting payment of \(amount) to \(recipient). Please authenticate to continue."
        speak(message, priority: .high)
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    func announcePaymentSuccess(_ amount: String, recipient: String) {
        let message = "Payment successful. \(amount) sent to \(recipient)."
        speak(message, priority: .high)
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    func announcePaymentFailure(_ reason: String) {
        let message = "Payment failed. \(reason). Please try again."
        speak(message, priority: .high)
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    func announceAuthenticationRequired() {
        let message = isVoiceOverEnabled ? 
            "Authentication required. Please use Face ID, Touch ID, or your passcode to continue." :
            "Authentication required to proceed with payment."
        speak(message, priority: .high)
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    func announceScreenChange(_ screenName: String) {
        guard isVoiceOverEnabled else { return }
        let message = "Navigated to \(screenName)"
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }
    
    func announceNotification(_ title: String, message: String) {
        let announcement = "\(title). \(message)"
        speak(announcement, priority: .normal)
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    // MARK: - Accessibility Helper Functions
    
    func shouldReduceAnimations() -> Bool {
        return isReduceMotionEnabled
    }
    
    func shouldUseSimplifiedLayout() -> Bool {
        return isSimplifiedUIEnabled || isVoiceOverEnabled || preferredContentSizeCategory.isAccessibilityCategory
    }
    
    func getRecommendedButtonSize() -> CGFloat {
        let baseSize: CGFloat = 44 // Apple's recommended minimum touch target
        
        if preferredContentSizeCategory.isAccessibilityCategory {
            return baseSize * 1.5
        } else if fontSizeMultiplier > 1.2 {
            return baseSize * 1.25
        } else {
            return baseSize
        }
    }
    
    func getRecommendedSpacing() -> CGFloat {
        let baseSpacing: CGFloat = 16
        return baseSpacing * fontSizeMultiplier
    }
}

// MARK: - ContentSizeCategory Extension

extension ContentSizeCategory {
    init(from uiContentSizeCategory: UIContentSizeCategory) {
        switch uiContentSizeCategory {
        case .extraSmall: self = .extraSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .extraLarge: self = .extraLarge
        case .extraExtraLarge: self = .extraExtraLarge
        case .extraExtraExtraLarge: self = .extraExtraExtraLarge
        case .accessibilityMedium: self = .accessibilityMedium
        case .accessibilityLarge: self = .accessibilityLarge
        case .accessibilityExtraLarge: self = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge: self = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge: self = .accessibilityExtraExtraExtraLarge
        default: self = .large
        }
    }
    
    var isAccessibilityCategory: Bool {
        switch self {
        case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge, 
             .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }
}

// MARK: - Accessibility View Modifiers

struct AccessibleText: ViewModifier {
    let label: String?
    let hint: String?
    let traits: AccessibilityTraits
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

struct AccessibleButton: ViewModifier {
    let label: String
    let hint: String?
    let action: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
            .if(let action = action) { view in
                view.accessibilityAction(.default) {
                    // Custom accessibility action
                }
            }
    }
}

struct DynamicTypeSize: ViewModifier {
    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        content
            .font(accessibilityManager.scaledFont(size: baseSize, weight: weight, design: design))
    }
}

struct ColorBlindnessAdjustment: ViewModifier {
    let color: Color
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(accessibilityManager.adjustedColor(color))
    }
}

// MARK: - View Extensions

extension View {
    func accessibleText(
        label: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        modifier(AccessibleText(label: label, hint: hint, traits: traits))
    }
    
    func accessibleButton(
        label: String,
        hint: String? = nil,
        action: String? = nil
    ) -> some View {
        modifier(AccessibleButton(label: label, hint: hint, action: action))
    }
    
    func dynamicTypeSize(
        _ baseSize: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(DynamicTypeSize(baseSize: baseSize, weight: weight, design: design))
    }
    
    func colorBlindnessAdjusted(_ color: Color) -> some View {
        modifier(ColorBlindnessAdjustment(color: color))
    }
    
    func reduceMotionSensitive<T: View>(
        @ViewBuilder alternative: () -> T
    ) -> some View {
        Group {
            if AccessibilityManager.shared.shouldReduceAnimations() {
                alternative()
            } else {
                self
            }
        }
    }
    
    func if<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        Group {
            if condition {
                transform(self)
            } else {
                self
            }
        }
    }
    
    func if<Content: View, T>(let value: T?, transform: (Self, T) -> Content) -> some View {
        Group {
            if let value = value {
                transform(self, value)
            } else {
                self
            }
        }
    }
}
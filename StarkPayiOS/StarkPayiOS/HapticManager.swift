import UIKit
import CoreHaptics
import SwiftUI

// MARK: - Advanced Haptic Feedback System

/// Comprehensive haptic feedback manager with contextual patterns for premium UX
@MainActor
class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    @Published var isHapticsEnabled = true
    @Published var hapticIntensity: Float = 1.0
    
    private var hapticEngine: CHHapticEngine?
    private var supportsHaptics: Bool = false
    
    // Feedback generators for different interaction types
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        setupHapticEngine()
        loadHapticSettings()
        prepareGenerators()
    }
    
    // MARK: - Setup and Configuration
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            supportsHaptics = false
            return
        }
        
        supportsHaptics = true
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            // Handle engine stopped/reset events
            hapticEngine?.stoppedHandler = { [weak self] reason in
                print("Haptic engine stopped: \(reason)")
                self?.restartHapticEngine()
            }
            
            hapticEngine?.resetHandler = { [weak self] in
                print("Haptic engine reset")
                self?.restartHapticEngine()
            }
            
        } catch {
            print("Failed to create haptic engine: \(error)")
            supportsHaptics = false
        }
    }
    
    private func restartHapticEngine() {
        guard supportsHaptics else { return }
        
        do {
            try hapticEngine?.start()
        } catch {
            print("Failed to restart haptic engine: \(error)")
        }
    }
    
    private func loadHapticSettings() {
        isHapticsEnabled = UserDefaults.standard.object(forKey: "haptics_enabled") as? Bool ?? true
        hapticIntensity = UserDefaults.standard.object(forKey: "haptic_intensity") as? Float ?? 1.0
    }
    
    private func prepareGenerators() {
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Basic Haptic Patterns
    
    /// Light impact for subtle interactions
    func lightImpact() {
        guard isHapticsEnabled else { return }
        lightImpactGenerator.impactOccurred(intensity: hapticIntensity)
    }
    
    /// Medium impact for standard interactions
    func mediumImpact() {
        guard isHapticsEnabled else { return }
        mediumImpactGenerator.impactOccurred(intensity: hapticIntensity)
    }
    
    /// Heavy impact for important interactions
    func heavyImpact() {
        guard isHapticsEnabled else { return }
        heavyImpactGenerator.impactOccurred(intensity: hapticIntensity)
    }
    
    /// Selection feedback for navigation and choices
    func selection() {
        guard isHapticsEnabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    /// Success notification
    func success() {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Warning notification
    func warning() {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Error notification
    func error() {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }
    
    // MARK: - Contextual Haptic Patterns for StarkPay
    
    /// Payment initiation haptic
    func paymentStart() {
        guard isHapticsEnabled, supportsHaptics else {
            mediumImpact()
            return
        }
        
        playCustomPattern(events: [
            HapticEvent(type: .impact, intensity: 0.7, sharpness: 0.5, time: 0),
            HapticEvent(type: .impact, intensity: 0.9, sharpness: 0.7, time: 0.1)
        ])
    }
    
    /// Payment processing haptic (subtle pulse)
    func paymentProcessing() {
        guard isHapticsEnabled, supportsHaptics else {
            lightImpact()
            return
        }
        
        let pulseEvents: [HapticEvent] = (0..<3).map { index in
            HapticEvent(
                type: .impact,
                intensity: 0.3,
                sharpness: 0.3,
                time: Double(index) * 0.5
            )
        }
        
        playCustomPattern(events: pulseEvents)
    }
    
    /// Payment success haptic (celebration pattern)
    func paymentSuccess() {
        guard isHapticsEnabled, supportsHaptics else {
            success()
            return
        }
        
        playCustomPattern(events: [
            HapticEvent(type: .impact, intensity: 0.8, sharpness: 0.8, time: 0),
            HapticEvent(type: .impact, intensity: 1.0, sharpness: 1.0, time: 0.15),
            HapticEvent(type: .impact, intensity: 0.6, sharpness: 0.6, time: 0.3),
            HapticEvent(type: .impact, intensity: 0.4, sharpness: 0.4, time: 0.45)
        ])
    }
    
    /// Payment failure haptic (warning pattern)
    func paymentFailed() {
        guard isHapticsEnabled, supportsHaptics else {
            error()
            return
        }
        
        playCustomPattern(events: [
            HapticEvent(type: .impact, intensity: 0.9, sharpness: 0.9, time: 0),
            HapticEvent(type: .impact, intensity: 0.7, sharpness: 0.7, time: 0.1),
            HapticEvent(type: .impact, intensity: 0.9, sharpness: 0.9, time: 0.2)
        ])
    }
    
    /// Biometric authentication haptic
    func biometricAuth() {
        guard isHapticsEnabled, supportsHaptics else {
            mediumImpact()
            return
        }
        
        playCustomPattern(events: [
            HapticEvent(type: .impact, intensity: 0.6, sharpness: 0.5, time: 0),
            HapticEvent(type: .impact, intensity: 0.4, sharpness: 0.3, time: 0.08),
            HapticEvent(type: .impact, intensity: 0.8, sharpness: 0.7, time: 0.16)
        ])
    }
    
    /// Card swipe haptic
    func cardSwipe() {
        guard isHapticsEnabled, supportsHaptics else {
            lightImpact()
            return
        }
        
        playCustomPattern(events: [
            HapticEvent(type: .impact, intensity: 0.5, sharpness: 0.8, time: 0),
            HapticEvent(type: .impact, intensity: 0.3, sharpness: 0.6, time: 0.05)
        ])
    }
    
    /// Button press haptic
    func buttonPress() {
        guard isHapticsEnabled else { return }
        lightImpact()
    }
    
    /// Toggle switch haptic
    func toggleSwitch(isOn: Bool) {
        guard isHapticsEnabled, supportsHaptics else {
            selection()
            return
        }
        
        let intensity: Float = isOn ? 0.8 : 0.5
        playCustomPattern(events: [
            HapticEvent(type: .impact, intensity: intensity, sharpness: 0.7, time: 0)
        ])
    }
    
    /// Notification received haptic
    func notificationReceived() {
        guard isHapticsEnabled, supportsHaptics else {
            mediumImpact()
            return
        }
        
        playCustomPattern(events: [
            HapticEvent(type: .impact, intensity: 0.7, sharpness: 0.5, time: 0),
            HapticEvent(type: .impact, intensity: 0.5, sharpness: 0.3, time: 0.1)
        ])
    }
    
    /// QR code scan success haptic
    func qrScanSuccess() {
        guard isHapticsEnabled, supportsHaptics else {
            success()
            return
        }
        
        playCustomPattern(events: [
            HapticEvent(type: .impact, intensity: 0.6, sharpness: 0.8, time: 0),
            HapticEvent(type: .impact, intensity: 0.8, sharpness: 1.0, time: 0.1)
        ])
    }
    
    /// Long press haptic (progressive intensity)
    func longPressStart() {
        guard isHapticsEnabled, supportsHaptics else {
            mediumImpact()
            return
        }
        
        let progressiveEvents: [HapticEvent] = (0..<5).map { index in
            let intensity = 0.3 + (Float(index) * 0.15)
            return HapticEvent(
                type: .impact,
                intensity: intensity,
                sharpness: 0.5,
                time: Double(index) * 0.1
            )
        }
        
        playCustomPattern(events: progressiveEvents)
    }
    
    // MARK: - Advanced Haptic Patterns
    
    /// Custom heartbeat pattern for loading states
    func heartbeat(duration: TimeInterval = 2.0) {
        guard isHapticsEnabled, supportsHaptics else { return }
        
        let beatInterval = 0.8
        let beatsCount = Int(duration / beatInterval)
        
        let heartbeatEvents: [HapticEvent] = (0..<beatsCount).flatMap { beat in
            let baseTime = Double(beat) * beatInterval
            return [
                HapticEvent(type: .impact, intensity: 0.7, sharpness: 0.8, time: baseTime),
                HapticEvent(type: .impact, intensity: 0.5, sharpness: 0.6, time: baseTime + 0.1)
            ]
        }
        
        playCustomPattern(events: heartbeatEvents)
    }
    
    /// Morse code pattern for unique feedback
    func morseCode(_ message: String) {
        guard isHapticsEnabled, supportsHaptics else { return }
        
        let morseDict: [Character: String] = [
            "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".",
            "F": "..-.", "G": "--.", "H": "....", "I": "..", "J": ".---",
            "K": "-.-", "L": ".-..", "M": "--", "N": "-.", "O": "---",
            "P": ".--.", "Q": "--.-", "R": ".-.", "S": "...", "T": "-",
            "U": "..-", "V": "...-", "W": ".--", "X": "-..-", "Y": "-.--",
            "Z": "--.."
        ]
        
        var events: [HapticEvent] = []
        var currentTime: Double = 0
        
        for char in message.uppercased() {
            guard let morse = morseDict[char] else { continue }
            
            for symbol in morse {
                let duration: Double = symbol == "." ? 0.1 : 0.3
                let intensity: Float = symbol == "." ? 0.5 : 0.8
                
                events.append(HapticEvent(
                    type: .impact,
                    intensity: intensity,
                    sharpness: 0.7,
                    time: currentTime
                ))
                
                currentTime += duration + 0.1 // Gap between symbols
            }
            currentTime += 0.3 // Gap between letters
        }
        
        playCustomPattern(events: events)
    }
    
    // MARK: - Custom Pattern Engine
    
    private struct HapticEvent {
        let type: EventType
        let intensity: Float
        let sharpness: Float
        let time: Double
        
        enum EventType {
            case impact
            case continuous(duration: Double)
        }
    }
    
    private func playCustomPattern(events: [HapticEvent]) {
        guard isHapticsEnabled, supportsHaptics, let engine = hapticEngine else { return }
        
        var hapticEvents: [CHHapticEvent] = []
        
        for event in events {
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: event.intensity * hapticIntensity
            )
            
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: event.sharpness
            )
            
            let hapticEvent: CHHapticEvent
            
            switch event.type {
            case .impact:
                hapticEvent = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: event.time
                )
            case .continuous(let duration):
                hapticEvent = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [intensity, sharpness],
                    relativeTime: event.time,
                    duration: duration
                )
            }
            
            hapticEvents.append(hapticEvent)
        }
        
        do {
            let pattern = try CHHapticPattern(events: hapticEvents, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
    
    // MARK: - Settings Management
    
    func updateHapticSettings(enabled: Bool, intensity: Float) {
        isHapticsEnabled = enabled
        hapticIntensity = max(0.1, min(1.0, intensity))
        
        UserDefaults.standard.set(enabled, forKey: "haptics_enabled")
        UserDefaults.standard.set(hapticIntensity, forKey: "haptic_intensity")
        
        if enabled {
            prepareGenerators()
        }
    }
    
    func testHapticPattern(_ pattern: HapticTestPattern) {
        switch pattern {
        case .light:
            lightImpact()
        case .medium:
            mediumImpact()
        case .heavy:
            heavyImpact()
        case .success:
            paymentSuccess()
        case .error:
            paymentFailed()
        case .heartbeat:
            heartbeat()
        }
    }
    
    enum HapticTestPattern: String, CaseIterable {
        case light = "Light Impact"
        case medium = "Medium Impact"
        case heavy = "Heavy Impact"
        case success = "Success Pattern"
        case error = "Error Pattern"
        case heartbeat = "Heartbeat"
        
        var description: String {
            switch self {
            case .light: return "Subtle feedback for light interactions"
            case .medium: return "Standard feedback for most actions"
            case .heavy: return "Strong feedback for important actions"
            case .success: return "Celebration pattern for successful payments"
            case .error: return "Alert pattern for errors"
            case .heartbeat: return "Rhythmic pattern for loading states"
            }
        }
    }
}

// MARK: - SwiftUI Integration

struct HapticButton<Label: View>: View {
    let action: () -> Void
    let hapticType: HapticType
    @ViewBuilder let label: () -> Label
    
    @State private var isPressed = false
    
    enum HapticType {
        case light, medium, heavy, selection, success, warning, error
        case custom(() -> Void)
    }
    
    var body: some View {
        Button(action: {
            performHaptic()
            action()
        }) {
            label()
        }
        .pressScale(isPressed: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private func performHaptic() {
        let hapticManager = HapticManager.shared
        
        switch hapticType {
        case .light:
            hapticManager.lightImpact()
        case .medium:
            hapticManager.mediumImpact()
        case .heavy:
            hapticManager.heavyImpact()
        case .selection:
            hapticManager.selection()
        case .success:
            hapticManager.success()
        case .warning:
            hapticManager.warning()
        case .error:
            hapticManager.error()
        case .custom(let customHaptic):
            customHaptic()
        }
    }
}

// MARK: - View Extensions

extension View {
    func hapticFeedback(_ type: HapticManager.HapticTestPattern) -> some View {
        onTapGesture {
            HapticManager.shared.testHapticPattern(type)
        }
    }
    
    func contextualHaptic(for context: HapticContext) -> some View {
        onTapGesture {
            let hapticManager = HapticManager.shared
            
            switch context {
            case .paymentStart:
                hapticManager.paymentStart()
            case .paymentSuccess:
                hapticManager.paymentSuccess()
            case .paymentFailed:
                hapticManager.paymentFailed()
            case .biometricAuth:
                hapticManager.biometricAuth()
            case .cardSwipe:
                hapticManager.cardSwipe()
            case .buttonPress:
                hapticManager.buttonPress()
            case .qrScanSuccess:
                hapticManager.qrScanSuccess()
            }
        }
    }
}

enum HapticContext {
    case paymentStart
    case paymentSuccess
    case paymentFailed
    case biometricAuth
    case cardSwipe
    case buttonPress
    case qrScanSuccess
}
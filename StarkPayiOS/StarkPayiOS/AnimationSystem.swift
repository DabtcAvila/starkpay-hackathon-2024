import SwiftUI
import UIKit

// MARK: - Advanced Animation System for StarkPay

/// High-performance animation system with micro-interactions for premium UX
@MainActor
class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    
    @Published var isPerformingTransition = false
    @Published var currentAnimationIntensity: Double = 1.0
    
    private init() {}
    
    // MARK: - Animation Presets
    
    /// Spring animation with customizable parameters
    static func springAnimation(
        response: Double = 0.5,
        dampingFraction: Double = 0.8,
        blendDuration: Double = 0
    ) -> Animation {
        .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
    }
    
    /// Smooth easing animation
    static func smoothAnimation(duration: Double = 0.3) -> Animation {
        .timingCurve(0.4, 0.0, 0.2, 1.0, duration: duration)
    }
    
    /// Bouncy animation for success states
    static func bouncyAnimation(duration: Double = 0.6) -> Animation {
        .timingCurve(0.68, -0.55, 0.265, 1.55, duration: duration)
    }
    
    /// Gentle fade animation
    static func fadeAnimation(duration: Double = 0.25) -> Animation {
        .easeInOut(duration: duration)
    }
    
    // MARK: - Micro-interaction Animations
    
    /// Button press animation with haptic feedback
    func buttonPressAnimation() -> Animation {
        HapticManager.shared.lightImpact()
        return .spring(response: 0.3, dampingFraction: 0.6)
    }
    
    /// Card swipe animation with physics
    func cardSwipeAnimation(velocity: CGFloat = 0) -> Animation {
        .interpolatingSpring(stiffness: 300, damping: 30, initialVelocity: velocity)
    }
    
    /// Notification appearance animation
    func notificationAnimation() -> Animation {
        .timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.4)
    }
    
    /// Loading state animation
    func loadingAnimation() -> Animation {
        .linear(duration: 1.0).repeatForever(autoreverses: false)
    }
}

// MARK: - Custom Animation View Modifiers

struct ScaleEffect: ViewModifier {
    let isPressed: Bool
    let pressedScale: Double
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? pressedScale : 1.0)
            .animation(animation, value: isPressed)
    }
}

struct ShakeEffect: ViewModifier {
    let shakes: Int
    let animatableData: CGFloat
    
    func body(content: Content) -> some View {
        content
            .offset(x: sin(animatableData * .pi * CGFloat(shakes)) * 5)
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color : .clear, radius: radius)
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

struct FloatingEffect: ViewModifier {
    @State private var isFloating = false
    let amplitude: Double
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? amplitude : -amplitude)
            .animation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

struct SlideInEffect: ViewModifier {
    let isVisible: Bool
    let direction: SlideDirection
    let distance: CGFloat
    
    enum SlideDirection {
        case left, right, top, bottom
    }
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: isVisible ? 0 : offsetX,
                y: isVisible ? 0 : offsetY
            )
            .opacity(isVisible ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
    }
    
    private var offsetX: CGFloat {
        switch direction {
        case .left: return -distance
        case .right: return distance
        default: return 0
        }
    }
    
    private var offsetY: CGFloat {
        switch direction {
        case .top: return -distance
        case .bottom: return distance
        default: return 0
        }
    }
}

// MARK: - View Extensions for Easy Animation Usage

extension View {
    /// Adds a scale effect on press
    func pressScale(
        isPressed: Bool,
        scale: Double = 0.95,
        animation: Animation = AnimationManager.springAnimation()
    ) -> some View {
        modifier(ScaleEffect(isPressed: isPressed, pressedScale: scale, animation: animation))
    }
    
    /// Adds shake animation for error states
    func shake(times: Int) -> some View {
        modifier(ShakeEffect(shakes: times, animatableData: CGFloat(times)))
    }
    
    /// Adds glow effect
    func glow(color: Color = .blue, radius: CGFloat = 10, isActive: Bool = true) -> some View {
        modifier(GlowEffect(color: color, radius: radius, isActive: isActive))
    }
    
    /// Adds floating animation
    func floating(amplitude: Double = 10, duration: Double = 2) -> some View {
        modifier(FloatingEffect(amplitude: amplitude, duration: duration))
    }
    
    /// Adds slide-in animation
    func slideIn(
        isVisible: Bool,
        from direction: SlideInEffect.SlideDirection = .bottom,
        distance: CGFloat = 50
    ) -> some View {
        modifier(SlideInEffect(isVisible: isVisible, direction: direction, distance: distance))
    }
    
    /// Adds animated border
    func animatedBorder(
        color: Color = .blue,
        width: CGFloat = 2,
        isActive: Bool = true
    ) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? color : .clear, lineWidth: width)
                .animation(.easeInOut(duration: 0.2), value: isActive)
        )
    }
    
    /// Adds morphing animation between views
    func morphTransition<T: View>(to newView: T, isShowingNew: Bool) -> some View {
        ZStack {
            self
                .opacity(isShowingNew ? 0 : 1)
                .scaleEffect(isShowingNew ? 0.8 : 1)
            
            newView
                .opacity(isShowingNew ? 1 : 0)
                .scaleEffect(isShowingNew ? 1 : 0.8)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isShowingNew)
    }
}

// MARK: - Advanced Custom Animations

/// Particle animation system for success states
struct ParticleEmitter: View {
    let particleCount: Int
    let colors: [Color]
    @State private var particles: [Particle] = []
    @State private var animationTimer: Timer?
    
    private struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var velocity: CGPoint
        var color: Color
        var opacity: Double
        var scale: CGFloat
        var life: Double
    }
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                context.opacity = particle.opacity
                context.scaleBy(x: particle.scale, y: particle.scale)
                
                let rect = CGRect(
                    x: particle.x - 2,
                    y: particle.y - 2,
                    width: 4,
                    height: 4
                )
                
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(particle.color)
                )
            }
        }
        .onAppear(perform: startAnimation)
        .onDisappear(perform: stopAnimation)
    }
    
    private func startAnimation() {
        createParticles()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateParticles()
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func createParticles() {
        particles = (0..<particleCount).map { _ in
            Particle(
                x: CGFloat.random(in: 0...400),
                y: CGFloat.random(in: 0...800),
                velocity: CGPoint(
                    x: CGFloat.random(in: -2...2),
                    y: CGFloat.random(in: -4...-1)
                ),
                color: colors.randomElement() ?? .blue,
                opacity: Double.random(in: 0.3...1.0),
                scale: CGFloat.random(in: 0.5...1.5),
                life: 1.0
            )
        }
    }
    
    private func updateParticles() {
        for i in particles.indices {
            particles[i].x += particles[i].velocity.x
            particles[i].y += particles[i].velocity.y
            particles[i].life -= 0.01
            particles[i].opacity = max(0, particles[i].life)
            
            if particles[i].life <= 0 {
                // Reset particle
                particles[i].x = CGFloat.random(in: 0...400)
                particles[i].y = 800
                particles[i].life = 1.0
                particles[i].opacity = Double.random(in: 0.3...1.0)
            }
        }
    }
}

/// Ripple effect for touch interactions
struct RippleEffect: View {
    @State private var ripples: [RippleData] = []
    let maxRipples = 5
    
    private struct RippleData: Identifiable {
        let id = UUID()
        let center: CGPoint
        var scale: CGFloat = 0
        var opacity: Double = 1
    }
    
    var body: some View {
        ZStack {
            ForEach(ripples) { ripple in
                Circle()
                    .stroke(Color.blue.opacity(ripple.opacity), lineWidth: 2)
                    .frame(width: 50, height: 50)
                    .scaleEffect(ripple.scale)
                    .position(ripple.center)
                    .animation(.easeOut(duration: 1.0), value: ripple.scale)
                    .animation(.easeOut(duration: 1.0), value: ripple.opacity)
            }
        }
    }
    
    func addRipple(at point: CGPoint) {
        let newRipple = RippleData(center: point)
        ripples.append(newRipple)
        
        // Animate ripple
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if let index = ripples.firstIndex(where: { $0.id == newRipple.id }) {
                ripples[index].scale = 3.0
                ripples[index].opacity = 0.0
            }
        }
        
        // Remove ripple after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ripples.removeAll { $0.id == newRipple.id }
        }
        
        // Limit number of ripples
        if ripples.count > maxRipples {
            ripples.removeFirst(ripples.count - maxRipples)
        }
    }
}

/// Morphing background gradient
struct MorphingGradient: View {
    @State private var gradientRotation: Double = 0
    @State private var colorIndex: Int = 0
    
    let colors: [[Color]] = [
        [Color.blue, Color.purple],
        [Color.purple, Color.pink],
        [Color.pink, Color.orange],
        [Color.orange, Color.yellow],
        [Color.yellow, Color.green],
        [Color.green, Color.blue]
    ]
    
    var body: some View {
        Rectangle()
            .fill(
                AngularGradient(
                    colors: colors[colorIndex],
                    center: .center,
                    angle: .degrees(gradientRotation)
                )
            )
            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: gradientRotation)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: colorIndex)
            .onAppear {
                gradientRotation = 360
                
                Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                    colorIndex = (colorIndex + 1) % colors.count
                }
            }
    }
}

// MARK: - Animation Utilities

class AnimationUtils {
    /// Calculate spring animation timing for complex sequences
    static func calculateSpringTiming(
        mass: Double = 1,
        stiffness: Double = 100,
        damping: Double = 10
    ) -> Double {
        let omega = sqrt(stiffness / mass)
        let dampingRatio = damping / (2 * sqrt(stiffness * mass))
        
        if dampingRatio < 1 {
            return 2 * .pi / (omega * sqrt(1 - dampingRatio * dampingRatio))
        } else {
            return 4 / omega
        }
    }
    
    /// Generate smooth curve points for custom animations
    static func generateCurvePoints(
        start: CGPoint,
        end: CGPoint,
        controlPoint1: CGPoint,
        controlPoint2: CGPoint,
        steps: Int = 100
    ) -> [CGPoint] {
        var points: [CGPoint] = []
        
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let point = cubicBezierPoint(
                t: t,
                start: start,
                end: end,
                control1: controlPoint1,
                control2: controlPoint2
            )
            points.append(point)
        }
        
        return points
    }
    
    private static func cubicBezierPoint(
        t: CGFloat,
        start: CGPoint,
        end: CGPoint,
        control1: CGPoint,
        control2: CGPoint
    ) -> CGPoint {
        let oneMinusT = 1 - t
        let oneMinusTSquared = oneMinusT * oneMinusT
        let oneMinusTCubed = oneMinusTSquared * oneMinusT
        let tSquared = t * t
        let tCubed = tSquared * t
        
        let x = oneMinusTCubed * start.x +
                3 * oneMinusTSquared * t * control1.x +
                3 * oneMinusT * tSquared * control2.x +
                tCubed * end.x
        
        let y = oneMinusTCubed * start.y +
                3 * oneMinusTSquared * t * control1.y +
                3 * oneMinusT * tSquared * control2.y +
                tCubed * end.y
        
        return CGPoint(x: x, y: y)
    }
}
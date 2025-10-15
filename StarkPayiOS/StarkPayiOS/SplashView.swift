import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var glowOpacity: Double = 0.5
    @State private var rotationAngle: Double = 0
    @State private var scaleAmount: Double = 0.5
    @Binding var isShowingSplash: Bool
    
    var body: some View {
        ZStack {
            // Premium black gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.1, blue: 0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Animated StarkPay Logo
                ZStack {
                    // Glow effect background
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 200, height: 200)
                        .opacity(glowOpacity)
                        .scaleEffect(scaleAmount * 1.5)
                        .blur(radius: 20)
                    
                    // Main logo container
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.black, Color(red: 0.15, green: 0.15, blue: 0.15)],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(scaleAmount)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.orange, Color.yellow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 4
                                )
                        )
                    
                    // Lightning bolt icon with animation
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(scaleAmount)
                        .rotationEffect(.degrees(rotationAngle))
                        .shadow(color: .orange, radius: 10)
                }
                
                // StarkPay branding with animation
                VStack(spacing: 12) {
                    Text("StarkPay")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.gray],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(0.5), value: isAnimating)
                    
                    Text("Lightning Fast • Invisible Simple")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .opacity(isAnimating ? 0.8 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(1.0), value: isAnimating)
                }
                
                // Premium loading indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1.0).delay(1.5), value: isAnimating)
            }
        }
        .onAppear {
            startAnimations()
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    isShowingSplash = false
                }
            }
        }
    }
    
    private func startAnimations() {
        // Start all animations
        withAnimation(.spring(response: 1.0, dampingFraction: 0.6)) {
            scaleAmount = 1.0
            isAnimating = true
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowOpacity = 1.0
        }
        
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

#Preview {
    SplashView(isShowingSplash: .constant(true))
}
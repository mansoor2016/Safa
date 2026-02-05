// MARK: - AnimatedComponents.swift
// PURPOSE: Reusable animated UI components
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Shimmer Loading Effect

struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemGray5),
                Color(.systemGray4),
                Color(.systemGray5)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .white, .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: phase)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 300
            }
        }
    }
}

// MARK: - Pulse Animation

struct PulseView<Content: View>: View {
    let content: () -> Content
    @State private var isPulsing = false

    var body: some View {
        content()
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Bounce Animation

struct BounceView<Content: View>: View {
    let content: () -> Content
    let trigger: Bool
    @State private var isBouncing = false

    init(trigger: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.trigger = trigger
        self.content = content
    }

    var body: some View {
        content()
            .scaleEffect(isBouncing ? 1.2 : 1.0)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                        isBouncing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                            isBouncing = false
                        }
                    }
                }
            }
    }
}

// MARK: - Confetti Effect

struct ConfettiView: View {
    let isActive: Bool
    let particleCount: Int

    @State private var particles: [ConfettiParticle] = []

    init(isActive: Bool, particleCount: Int = 50) {
        self.isActive = isActive
        self.particleCount = particleCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startConfetti(in: geometry.size)
                }
            }
        }
    }

    private func startConfetti(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                color: [.green, .yellow, .orange, .blue, .purple].randomElement()!,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(x: size.width / 2, y: 0),
                opacity: 1.0
            )
        }

        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let endX = CGFloat.random(in: 0...size.width)
            let endY = size.height + 50

            withAnimation(.easeOut(duration: 2).delay(delay)) {
                particles[i].position = CGPoint(x: endX, y: endY)
                particles[i].opacity = 0
            }
        }

        // Clear particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            particles = []
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Counting Number Animation

struct AnimatedCounter: View {
    let value: Int
    let font: Font
    let color: Color

    @State private var displayValue: Int = 0

    init(value: Int, font: Font = .title, color: Color = .primary) {
        self.value = value
        self.font = font
        self.color = color
    }

    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.3)) {
                    displayValue = newValue
                }
            }
            .onAppear {
                displayValue = value
            }
    }
}

// MARK: - Slide In Animation

struct SlideInModifier: ViewModifier {
    let isVisible: Bool
    let edge: Edge

    func body(content: Content) -> some View {
        content
            .offset(x: offsetX, y: offsetY)
            .opacity(isVisible ? 1 : 0)
            .animation(.spring(response: 0.4), value: isVisible)
    }

    private var offsetX: CGFloat {
        guard !isVisible else { return 0 }
        switch edge {
        case .leading: return -100
        case .trailing: return 100
        default: return 0
        }
    }

    private var offsetY: CGFloat {
        guard !isVisible else { return 0 }
        switch edge {
        case .top: return -100
        case .bottom: return 100
        default: return 0
        }
    }
}

extension View {
    func slideIn(isVisible: Bool, from edge: Edge = .bottom) -> some View {
        modifier(SlideInModifier(isVisible: isVisible, edge: edge))
    }
}

// MARK: - Progress Bar Animation

struct AnimatedProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat

    @State private var animatedProgress: Double = 0

    init(progress: Double, color: Color = .green, height: CGFloat = 8) {
        self.progress = progress
        self.color = color
        self.height = height
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: height)

                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * animatedProgress, height: height)
            }
        }
        .frame(height: height)
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.5)) {
                animatedProgress = newValue
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Typing Text Animation

struct TypingText: View {
    let text: String
    let speed: Double

    @State private var displayedText = ""
    @State private var currentIndex = 0

    init(_ text: String, speed: Double = 0.05) {
        self.text = text
        self.speed = speed
    }

    var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
    }

    private func startTyping() {
        displayedText = ""
        currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { timer in
            if currentIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: currentIndex)
                displayedText += String(text[index])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Floating Animation

struct FloatingModifier: ViewModifier {
    @State private var isFloating = false

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -5 : 5)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isFloating = true
                }
            }
    }
}

extension View {
    func floating() -> some View {
        modifier(FloatingModifier())
    }
}

// MARK: - Scale On Press

struct ScaleOnPress: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func scaleOnPress() -> some View {
        modifier(ScaleOnPress())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AnimatedCounter(value: 125, font: .largeTitle, color: .green)

        AnimatedProgressBar(progress: 0.7)
            .padding()

        PulseView {
            Circle()
                .fill(Color.green)
                .frame(width: 50, height: 50)
        }

        TypingText("Bismillah...", speed: 0.1)
            .font(.title2)
    }
    .padding()
}

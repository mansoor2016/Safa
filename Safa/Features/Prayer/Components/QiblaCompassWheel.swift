// MARK: - QiblaCompassWheel.swift
// PURPOSE: Compass circle with cardinal directions, tick marks, and Qibla arrow
// DEPENDENCIES: SwiftUI, QiblaArrow

import SwiftUI

struct QiblaCompassWheel: View {
    let qiblaDirection: Double
    let deviceHeading: Double
    let size: CGFloat

    // Radius from center to the outer ring edge
    private var radius: CGFloat { size / 2 }

    var body: some View {
        ZStack {
            // Outer compass ring
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 3)
                .frame(width: size, height: size)

            // Tick marks — drawn inside the ring, cardinals get gaps for letters
            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let outerRadius = min(canvasSize.width, canvasSize.height) / 2

                for i in 0..<72 {
                    let degrees = Double(i) * 5
                    let isCardinal = i % 18 == 0  // 0, 90, 180, 270

                    // Skip tick marks at cardinal positions — letters go there
                    if isCardinal { continue }

                    let isMajor = i % 9 == 0       // 45, 135, 225, 315 (intercardinals)
                    let isMinor10 = i % 2 == 0      // every 10°

                    let tickLength: CGFloat = isMajor ? 12 : (isMinor10 ? 8 : 4)
                    let tickWidth: CGFloat = isMajor ? 2 : 1
                    let tickOpacity: Double = isMajor ? 0.5 : (isMinor10 ? 0.3 : 0.15)

                    let radians = CGFloat((degrees - 90) * .pi / 180)
                    let outerR = outerRadius - 2
                    let innerR = outerR - tickLength
                    let outerPoint = CGPoint(
                        x: center.x + outerR * CoreGraphics.cos(radians),
                        y: center.y + outerR * CoreGraphics.sin(radians)
                    )
                    let innerPoint = CGPoint(
                        x: center.x + innerR * CoreGraphics.cos(radians),
                        y: center.y + innerR * CoreGraphics.sin(radians)
                    )

                    var path = Path()
                    path.move(to: outerPoint)
                    path.addLine(to: innerPoint)

                    context.stroke(
                        path,
                        with: .color(.gray.opacity(tickOpacity)),
                        lineWidth: tickWidth
                    )
                }
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(-deviceHeading))

            // Cardinal direction letters — positioned inside the ring with clear spacing
            ForEach(Array(["N", "E", "S", "W"].enumerated()), id: \.offset) { index, direction in
                let angle = Double(index) * 90

                Text(direction)
                    .font(.system(size: size * 0.065, weight: .semibold, design: .rounded))
                    .foregroundColor(direction == "N" ? .red : SafaColors.Fallback.secondaryText)
                    // Counter-rotate so letters stay upright
                    .rotationEffect(.degrees(-angle + deviceHeading))
                    .offset(y: -(radius - 24))
                    .rotationEffect(.degrees(angle))
            }
            .rotationEffect(.degrees(-deviceHeading))

            // Qibla direction arrow
            QiblaArrow(compassSize: size)
                .rotationEffect(.degrees(qiblaDirection - deviceHeading))
        }
        .animation(.easeInOut(duration: 0.2), value: deviceHeading)
    }
}

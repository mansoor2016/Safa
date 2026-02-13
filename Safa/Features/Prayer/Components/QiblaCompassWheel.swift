// MARK: - QiblaCompassWheel.swift
// PURPOSE: Compass circle with cardinal directions, tick marks, and Qibla arrow
// DEPENDENCIES: SwiftUI, QiblaArrow

import SwiftUI

struct QiblaCompassWheel: View {
    let qiblaDirection: Double
    let deviceHeading: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            // Compass ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                .frame(width: size, height: size)

            // Cardinal directions
            ForEach(0..<4, id: \.self) { index in
                let direction = ["N", "E", "S", "W"][index]
                let angle = Double(index) * 90

                Text(direction)
                    .font(SafaTypography.labelLarge)
                    .foregroundColor(direction == "N" ? .red : SafaColors.Fallback.secondaryText)
                    .offset(y: -(size * 0.43))
                    .rotationEffect(.degrees(angle))
            }
            .rotationEffect(.degrees(-deviceHeading))

            // Tick marks
            ForEach(0..<36, id: \.self) { index in
                Rectangle()
                    .fill(index % 9 == 0 ? Color.gray : Color.gray.opacity(0.3))
                    .frame(width: index % 9 == 0 ? 2 : 1, height: index % 9 == 0 ? 15 : 8)
                    .offset(y: -(size * 0.46))
                    .rotationEffect(.degrees(Double(index) * 10))
            }
            .rotationEffect(.degrees(-deviceHeading))

            // Qibla direction arrow
            QiblaArrow(compassSize: size)
                .rotationEffect(.degrees(qiblaDirection - deviceHeading))
        }
        .animation(.easeInOut(duration: 0.2), value: deviceHeading)
    }
}

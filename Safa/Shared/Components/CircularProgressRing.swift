// MARK: - CircularProgressRing.swift
// PURPOSE: Reusable circular progress indicator ring
// DEPENDENCIES: SwiftUI

import SwiftUI

struct CircularProgressRing: View {
    let progress: Double
    var size: CGFloat = 24
    var lineWidth: CGFloat = 3
    var trackColor: Color = Color.gray.opacity(0.3)
    var progressColor: Color = .accentColor

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(Int(min(progress, 1.0) * 100)) percent complete")
    }
}

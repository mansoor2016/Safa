// MARK: - QiblaArrow.swift
// PURPOSE: Proportionally-sized Qibla direction arrow for the compass
// DEPENDENCIES: SwiftUI

import SwiftUI

struct QiblaArrow: View {
    let compassSize: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: compassSize * 0.107))
                .foregroundColor(.green)

            Rectangle()
                .fill(Color.green)
                .frame(width: compassSize * 0.014, height: compassSize * 0.286)
        }
        .offset(y: -(compassSize * 0.161))
    }
}

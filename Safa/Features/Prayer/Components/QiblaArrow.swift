// MARK: - QiblaArrow.swift
// PURPOSE: Proportionally-sized Qibla direction arrow for the compass
// DEPENDENCIES: SwiftUI

import SwiftUI

struct QiblaArrow: View {
    let compassSize: CGFloat

    var body: some View {
        VStack(spacing: -(compassSize * 0.015)) {
            // Arrow head — negative spacing overlaps with shaft to eliminate gap
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: compassSize * 0.10))
                .foregroundStyle(.green)

            // Arrow shaft — from head toward center
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.green)
                .frame(width: compassSize * 0.02, height: compassSize * 0.25)
        }
        .offset(y: -(compassSize * 0.17))
    }
}

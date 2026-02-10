// MARK: - AutoScrollControl.swift
// PURPOSE: Floating control pill for auto-scroll feature in Quran reader
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Auto Scroll Speed

enum AutoScrollSpeed: Double, CaseIterable {
    case half = 0.5
    case normal = 1.0
    case double = 2.0
    case triple = 3.0

    var label: String {
        switch self {
        case .half: return "0.5x"
        case .normal: return "1x"
        case .double: return "2x"
        case .triple: return "3x"
        }
    }
}

// MARK: - Auto Scroll Control

struct AutoScrollControl: View {
    let isScrolling: Bool
    let speed: AutoScrollSpeed
    let onToggle: () -> Void
    let onSpeedChange: (AutoScrollSpeed) -> Void

    var body: some View {
        HStack(spacing: SafaSpacing.sm) {
            // Play/Pause button
            Button(action: onToggle) {
                Image(systemName: isScrolling ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor)
                    .clipShape(Circle())
            }
            .accessibilityLabel(isScrolling ? "Pause auto-scroll" : "Play auto-scroll")

            // Speed pills
            ForEach(AutoScrollSpeed.allCases, id: \.self) { speedOption in
                Button {
                    onSpeedChange(speedOption)
                } label: {
                    Text(speedOption.label)
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(speed == speedOption ? .white : SafaColors.Fallback.text)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(speed == speedOption ? Color.accentColor : Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
                .accessibilityLabel("Speed \(speedOption.label)")
                .accessibilityAddTraits(speed == speedOption ? .isSelected : [])
            }
        }
        .padding(.horizontal, SafaSpacing.md)
        .padding(.vertical, SafaSpacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

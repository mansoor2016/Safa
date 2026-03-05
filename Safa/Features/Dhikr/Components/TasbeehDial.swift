// MARK: - TasbeehDial.swift
// PURPOSE: Unified tappable counter dial — progress ring, count display, and tap target in one element
// DEPENDENCIES: SwiftUI, TasbeehHelpers

import SwiftUI

struct TasbeehDial: View {
    let count: Int
    let target: Int
    let dhikrName: String
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var ringSize: CGFloat = 250
    @ScaledMetric(relativeTo: .body) private var plusIconSize: CGFloat = 20

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                // Progress arc
                Circle()
                    .trim(from: 0, to: TasbeehHelpers.progress(count: count, target: target))
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: count)

                // Center content: count + target + hint
                VStack(spacing: SafaSpacing.xs) {
                    Text("\(count)")
                        .font(SafaTypography.counterLarge)
                        .foregroundColor(SafaColors.Fallback.text)
                        .contentTransition(.numericText())

                    Text("of \(target)")
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)

                    // Tap affordance
                    Image(systemName: "plus")
                        .font(.system(size: plusIconSize, weight: .medium))
                        .foregroundColor(.accentColor.opacity(0.6))
                        .padding(.top, SafaSpacing.xxs)
                }
            }
            .frame(width: ringSize, height: ringSize)
        }
        .buttonStyle(DialButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TasbeehHelpers.accessibilityLabel(dhikrName: dhikrName, count: count, target: target))
        .accessibilityValue("\(count) of \(target)")
        .accessibilityHint("Double tap to count one \(dhikrName)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Dial Button Style

private struct DialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

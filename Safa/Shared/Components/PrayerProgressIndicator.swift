// MARK: - PrayerProgressIndicator.swift
// PURPOSE: Visual indicator showing prayer progress (X of 5 prayers completed)
// DEPENDENCIES: SwiftUI

import SwiftUI

/// A visual indicator showing the current prayer progress out of 5 obligatory prayers
struct PrayerProgressIndicator: View {
    let prayers: [PrayerTime]
    let loggedPrayers: Set<PrayerType>
    let nextPrayer: PrayerTime?
    var style: Style = .compact
    var onLogPrayer: ((PrayerType) -> Void)?

    @ScaledMetric(relativeTo: .body) private var compactDotSize: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var expandedDotSize: CGFloat = 32

    enum Style {
        case compact    // For home page - dots + numeric count
        case expanded   // For prayer page - larger with labels
    }

    // MARK: - Prayer State Helper

    private struct PrayerState {
        let type: PrayerType
        let isLogged: Bool
        let isNext: Bool
        let isPastUnlogged: Bool
        let canTap: Bool
    }

    private var prayerStates: [PrayerState] {
        let prayerTypes: [PrayerType] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        return prayerTypes.map { prayerType in
            let isLogged = loggedPrayers.contains(prayerType)
            let isNext = nextPrayer?.type == prayerType
            let prayer = obligatoryPrayers.first { $0.type == prayerType }
            let isPast = prayer.map { $0.time < Date() } ?? false
            let canTap = onLogPrayer != nil && (isLogged || isPast || isNext)
            return PrayerState(
                type: prayerType,
                isLogged: isLogged,
                isNext: isNext,
                isPastUnlogged: isPast && !isLogged,
                canTap: canTap
            )
        }
    }

    private var obligatoryPrayers: [PrayerTime] {
        prayers.filter { $0.type.isObligatory }
    }

    private var completedCount: Int {
        obligatoryPrayers.filter { loggedPrayers.contains($0.type) }.count
    }

    var body: some View {
        switch style {
        case .compact:
            compactView
        case .expanded:
            expandedView
        }
    }

    // MARK: - Compact View (for home page)

    private var compactView: some View {
        HStack(spacing: 6) {
            // Five dots representing the 5 prayers
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    compactDot(index: index)
                }
            }

            // Vertical divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: 16)

            // Numeric count - always prominent
            Text("\(completedCount)/5")
                .font(SafaTypography.bodyMedium)
                .foregroundColor(completedCount > 0 ? .green : .primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.accentColor.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    private func compactDot(index: Int) -> some View {
        let prayerTypes: [PrayerType] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        let prayerType = prayerTypes[index]
        let isLogged = loggedPrayers.contains(prayerType)
        let isNext = nextPrayer?.type == prayerType
        let prayer = obligatoryPrayers.first { $0.type == prayerType }
        let isPast = prayer.map { $0.time < Date() } ?? false
        let canTap = onLogPrayer != nil && (isLogged || isPast || isNext)

        return Button {
            guard canTap else { return }
            HapticFeedbackService.shared.play(.commit)
            onLogPrayer?(prayerType)
        } label: {
            ZStack {
                Circle()
                    .fill(compactDotColor(isLogged: isLogged, isNext: isNext, isPast: isPast && !isLogged))
                    .frame(width: compactDotSize, height: compactDotSize)

                if isLogged {
                    Image(systemName: "checkmark")
                        .font(.system(size: compactDotSize * 0.56, weight: .bold))
                        .foregroundColor(.white)
                }

                if isNext && !isLogged {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 2)
                        .frame(width: compactDotSize + 4, height: compactDotSize + 4)
                }
            }
            .frame(width: compactDotSize + 6, height: compactDotSize + 6)
        }
        .buttonStyle(.plain)
        .disabled(!canTap)
        .accessibilityLabel(formatPrayerDotAccessibilityLabel(
            prayerName: prayerType.displayName,
            isLogged: isLogged,
            isNext: isNext,
            isPast: isPast && !isLogged
        ))
        .accessibilityHint(canTap ? (isLogged ? "Double tap to unlog" : "Double tap to log") : "")
    }

    private func compactDotColor(isLogged: Bool, isNext: Bool, isPast: Bool) -> Color {
        if isLogged {
            return .green
        } else if isNext {
            return Color.accentColor.opacity(0.3)
        } else if isPast {
            return .orange
        } else {
            return Color(UIColor.systemGray4)
        }
    }

    // MARK: - Expanded View (for prayer page)

    private var expandedView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                let states = prayerStates
                ForEach(Array(states.enumerated()), id: \.offset) { index, state in
                    expandedDot(state: state)
                    if index < 4 {
                        expandedLine(from: states[index], to: states[index + 1])
                    }
                }
            }

            HStack(spacing: 4) {
                Text("\(completedCount) of 5")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                if completedCount == 5 {
                    Image(systemName: "checkmark.seal.fill")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(.green)
                }
            }
            .accessibilityProgress(label: "Prayer progress", current: completedCount, total: 5)
        }
        .padding(.vertical, 8)
    }

    private func expandedDot(state: PrayerState) -> some View {
        Button {
            guard state.canTap else { return }
            HapticFeedbackService.shared.play(.commit)
            onLogPrayer?(state.type)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if state.isLogged {
                        Circle()
                            .fill(.green)
                            .frame(width: expandedDotSize, height: expandedDotSize)
                        Image(systemName: "checkmark")
                            .font(.system(size: expandedDotSize * 0.45, weight: .bold))
                            .foregroundColor(.white)
                    } else if state.isNext {
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: expandedDotSize, height: expandedDotSize)
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 2.5)
                            .frame(width: expandedDotSize, height: expandedDotSize)
                    } else if state.isPastUnlogged {
                        Circle()
                            .fill(.orange)
                            .frame(width: expandedDotSize, height: expandedDotSize)
                        Image(systemName: "exclamationmark")
                            .font(.system(size: expandedDotSize * 0.4, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .fill(Color(UIColor.systemGray4))
                            .frame(width: expandedDotSize * 0.4, height: expandedDotSize * 0.4)
                    }
                }
                .frame(width: expandedDotSize, height: expandedDotSize)

                Text(state.type.displayName)
                    .font(SafaTypography.labelSmall)
                    .fontWeight(state.isNext ? .semibold : .regular)
                    .foregroundColor(
                        state.isLogged ? .green :
                        state.isNext ? .accentColor :
                        state.isPastUnlogged ? .orange :
                        SafaColors.Fallback.secondaryText
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
        .disabled(!state.canTap)
        .accessibilityLabel(formatPrayerDotAccessibilityLabel(
            prayerName: state.type.displayName,
            isLogged: state.isLogged,
            isNext: state.isNext,
            isPast: state.isPastUnlogged
        ))
        .accessibilityHint(state.canTap ? (state.isLogged ? "Double tap to unlog" : "Double tap to log") : "")
    }

    private func expandedLine(from: PrayerState, to: PrayerState) -> some View {
        Capsule()
            .fill(from.isLogged && to.isLogged ? Color.green.opacity(0.6) : Color(UIColor.systemGray5))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 24) // Align with circle centers
    }
}

// MARK: - Preview

#Preview("Prayer Progress Indicator") {
    VStack(spacing: 40) {
        // Compact - simulating 2 prayers done, Asr is next
        VStack(alignment: .leading, spacing: 8) {
            Text("Compact (Home Page) - 2/5 done")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("Today's Prayers")
                    .font(.headline)
                Spacer()
                PrayerProgressIndicator(
                    prayers: PrayerTime.samplePrayers,
                    loggedPrayers: [.fajr, .dhuhr],
                    nextPrayer: PrayerTime.samplePrayers.first { $0.type == .asr },
                    style: .compact
                )
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }

        // Expanded
        VStack(alignment: .leading, spacing: 8) {
            Text("Expanded (Prayer Page)")
                .font(.caption)
                .foregroundColor(.secondary)

            PrayerProgressIndicator(
                prayers: PrayerTime.samplePrayers,
                loggedPrayers: [.fajr, .dhuhr],
                nextPrayer: PrayerTime.samplePrayers.first { $0.type == .asr },
                style: .expanded
            )
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }

        // Empty state
        VStack(alignment: .leading, spacing: 8) {
            Text("Empty (No prayers logged)")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("Today's Prayers")
                    .font(.headline)
                Spacer()
                PrayerProgressIndicator(
                    prayers: PrayerTime.samplePrayers,
                    loggedPrayers: [],
                    nextPrayer: PrayerTime.samplePrayers.first { $0.type == .fajr },
                    style: .compact
                )
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    .padding()
}

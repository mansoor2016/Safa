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

    enum Style {
        case compact    // For home page - dots + numeric count
        case expanded   // For prayer page - larger with labels
    }

    private var obligatoryPrayers: [PrayerTime] {
        prayers.filter { $0.type.isObligatory }
    }

    private var completedCount: Int {
        // Count prayers that are logged
        let logged = obligatoryPrayers.filter { loggedPrayers.contains($0.type) }.count
        // If no prayers loaded yet, show 0
        return logged
    }

    private var currentPrayerNumber: Int {
        // Which prayer are we on? (1-5)
        guard let next = nextPrayer else {
            // All prayers passed for today
            return 5
        }
        switch next.type {
        case .fajr: return 1
        case .dhuhr: return 2
        case .asr: return 3
        case .maghrib: return 4
        case .isha: return 5
        default: return 1
        }
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
                .font(.system(size: 14, weight: .bold))
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
    }

    private func compactDot(index: Int) -> some View {
        let prayerTypes: [PrayerType] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        let prayerType = prayerTypes[index]
        let isLogged = loggedPrayers.contains(prayerType)
        let isNext = nextPrayer?.type == prayerType
        let prayer = obligatoryPrayers.first { $0.type == prayerType }
        let isPast = prayer.map { $0.time < Date() } ?? false
        // Can toggle off logged prayers; can toggle on if prayer time has passed or is current
        let canTap = onLogPrayer != nil && (isLogged || isPast || isNext)

        return Button {
            guard canTap else { return }
            HapticFeedbackService.shared.play(.commit)
            onLogPrayer?(prayerType)
        } label: {
            ZStack {
                // Main circle
                Circle()
                    .fill(compactDotColor(isLogged: isLogged, isNext: isNext, isPast: isPast && !isLogged))
                    .frame(width: 16, height: 16)

                // Checkmark for completed
                if isLogged {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                }

                // Ring for next prayer
                if isNext && !isLogged {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
            }
            .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .disabled(!canTap)
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
        VStack(spacing: 12) {
            // Progress bar with dots
            HStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { index in
                    expandedDot(index: index)

                    // Connecting line (except after last)
                    if index < 4 {
                        expandedConnectingLine(fromIndex: index)
                    }
                }
            }

            // Numeric status
            HStack {
                Text("\(completedCount) of 5 prayers completed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SafaColors.Fallback.secondaryText)

                if completedCount == 5 {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func expandedDot(index: Int) -> some View {
        let prayerTypes: [PrayerType] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        let prayerType = prayerTypes[index]
        let isLogged = loggedPrayers.contains(prayerType)
        let isNext = nextPrayer?.type == prayerType
        let prayer = obligatoryPrayers.first { $0.type == prayerType }
        let isPast = prayer.map { $0.time < Date() } ?? false
        // Can toggle off logged prayers; can toggle on if prayer time has passed or is current
        let canTap = onLogPrayer != nil && (isLogged || isPast || isNext)

        return Button {
            guard canTap else { return }
            HapticFeedbackService.shared.play(.commit)
            onLogPrayer?(prayerType)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(expandedDotColor(isLogged: isLogged, isNext: isNext, isPast: isPast && !isLogged))
                        .frame(width: 40, height: 40)

                    // Border for next prayer
                    if isNext && !isLogged {
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 3)
                            .frame(width: 46, height: 46)
                    }

                    // Content
                    if isLogged {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(expandedTextColor(isLogged: isLogged, isNext: isNext, isPast: isPast && !isLogged))
                    }
                }

                // Prayer name (full)
                Text(prayerType.displayName)
                    .font(.system(size: 10, weight: isNext ? .semibold : .regular))
                    .foregroundColor(isLogged ? .green : (isNext ? .accentColor : SafaColors.Fallback.secondaryText))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
        .disabled(!canTap)
    }

    private func expandedConnectingLine(fromIndex: Int) -> some View {
        let prayerTypes: [PrayerType] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        let fromLogged = loggedPrayers.contains(prayerTypes[fromIndex])
        let toLogged = loggedPrayers.contains(prayerTypes[fromIndex + 1])

        return Rectangle()
            .fill(fromLogged && toLogged ? Color.green : Color(UIColor.systemGray4))
            .frame(height: 4)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 28) // Align with circle centers
    }

    private func expandedDotColor(isLogged: Bool, isNext: Bool, isPast: Bool) -> Color {
        if isLogged {
            return .green
        } else if isNext {
            return Color.accentColor.opacity(0.2)
        } else if isPast {
            return .orange
        } else {
            return Color(UIColor.systemGray5)
        }
    }

    private func expandedTextColor(isLogged: Bool, isNext: Bool, isPast: Bool) -> Color {
        if isLogged {
            return .white
        } else if isNext {
            return .accentColor
        } else if isPast {
            return .white
        } else {
            return Color(UIColor.systemGray)
        }
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

// MARK: - PrayerTimePreviewCard.swift
// PURPOSE: Compact 2-column preview of today's prayer times with optional notification toggles
// DEPENDENCIES: SwiftUI, PrayerTimeCalculator

import SwiftUI

struct PrayerTimePreviewCard: View {
    private let prayers: [PrayerTime]
    private let notificationEnabledPrayers: Set<PrayerType>
    private let onToggleNotification: ((PrayerType) -> Void)?

    // MARK: - Init (pre-loaded prayers — used on Prayer and Ramadan pages)

    init(
        prayers: [PrayerTime],
        notificationEnabledPrayers: Set<PrayerType> = [],
        onToggleNotification: ((PrayerType) -> Void)? = nil
    ) {
        self.prayers = prayers
        self.notificationEnabledPrayers = notificationEnabledPrayers
        self.onToggleNotification = onToggleNotification
    }

    // MARK: - Init (self-calculating — used in onboarding/settings)

    init(method: CalculationMethod, madhab: Madhab, location: Coordinates, date: Date) {
        let calculator = PrayerTimeCalculator()
        self.prayers = calculator.calculatePrayerTimes(
            for: date,
            location: location,
            method: method,
            madhab: madhab
        )
        self.notificationEnabledPrayers = []
        self.onToggleNotification = nil
    }

    // MARK: - Body

    private var hasNotificationToggles: Bool { onToggleNotification != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.sm) {
            // Header
            HStack {
                Text("Today's Prayer Times")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)

                Spacer()

                if hasNotificationToggles && !notificationEnabledPrayers.isEmpty {
                    Label("Notifications on", systemImage: "bell.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                }
            }

            // 2-column layout
            let leftColumn = prayers.filter { [.fajr, .sunrise, .dhuhr].contains($0.type) }
            let rightColumn = prayers.filter { [.asr, .maghrib, .isha].contains($0.type) }

            HStack(alignment: .top, spacing: SafaSpacing.lg) {
                VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                    ForEach(leftColumn) { prayer in
                        prayerRow(prayer)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                    ForEach(rightColumn) { prayer in
                        prayerRow(prayer)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(SafaSpacing.md)
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }

    // MARK: - Prayer Row

    private func prayerRow(_ prayer: PrayerTime) -> some View {
        let isEnabled = hasNotificationToggles ? (notificationEnabledPrayers.contains(prayer.type) || !prayer.type.isObligatory) : true
        let textOpacity: Double = isEnabled ? 1.0 : 0.5

        return Group {
            if hasNotificationToggles && prayer.type.isObligatory {
                Button {
                    onToggleNotification?(prayer.type)
                } label: {
                    rowContent(prayer, textOpacity: textOpacity, showBell: true, isEnabled: notificationEnabledPrayers.contains(prayer.type))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(prayer.type.displayName) at \(prayer.time.formatted(date: .omitted, time: .shortened))")
                .accessibilityHint(notificationEnabledPrayers.contains(prayer.type) ? "Notification on, double tap to turn off" : "Notification off, double tap to turn on")
            } else {
                rowContent(prayer, textOpacity: textOpacity, showBell: false, isEnabled: true)
            }
        }
    }

    private func rowContent(_ prayer: PrayerTime, textOpacity: Double, showBell: Bool, isEnabled: Bool) -> some View {
        HStack(spacing: SafaSpacing.xs) {
            Text(prayer.type.displayName)
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)
                .opacity(textOpacity)
                .frame(width: 56, alignment: .leading)

            Text(prayer.time.formatted(date: .omitted, time: .shortened))
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.text)
                .monospacedDigit()
                .opacity(textOpacity)

            if showBell {
                Image(systemName: isEnabled ? "bell.fill" : "bell.slash")
                    .font(.system(size: 10))
                    .foregroundColor(isEnabled ? .accentColor : SafaColors.Fallback.tertiaryText)
            }
        }
    }
}

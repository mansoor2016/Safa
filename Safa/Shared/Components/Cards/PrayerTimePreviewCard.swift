// MARK: - PrayerTimePreviewCard.swift
// PURPOSE: Compact 2-column preview of today's prayer times with optional notification toggles
// DEPENDENCIES: SwiftUI, PrayerTimeCalculator, PrayerRakats

import SwiftUI

struct PrayerTimePreviewCard: View {
    private let prayers: [PrayerTime]
    private let madhab: Madhab
    private let showRakatInfo: Bool
    private let notificationEnabledPrayers: Set<PrayerType>
    private let onToggleNotification: ((PrayerType) -> Void)?
    private let onToggleRakatInfo: (() -> Void)?

    // MARK: - Init (pre-loaded prayers — used on Prayer and Ramadan pages)

    init(
        prayers: [PrayerTime],
        madhab: Madhab = AppDefaults.madhab,
        showRakatInfo: Bool = false,
        notificationEnabledPrayers: Set<PrayerType> = [],
        onToggleNotification: ((PrayerType) -> Void)? = nil,
        onToggleRakatInfo: (() -> Void)? = nil
    ) {
        self.prayers = prayers
        self.madhab = madhab
        self.showRakatInfo = showRakatInfo
        self.notificationEnabledPrayers = notificationEnabledPrayers
        self.onToggleNotification = onToggleNotification
        self.onToggleRakatInfo = onToggleRakatInfo
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
        self.madhab = madhab
        self.showRakatInfo = false
        self.notificationEnabledPrayers = []
        self.onToggleNotification = nil
        self.onToggleRakatInfo = nil
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

            // Legend (visible when rakat info is shown)
            if showRakatInfo {
                Text("F Fard · S Sunnah · N Nafl · W Witr")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
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

            // Tap hint when rakat info is hidden
            if onToggleRakatInfo != nil && !showRakatInfo {
                Text("Hold for rak'ah count")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(SafaSpacing.md)
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        .contentShape(Rectangle())
        .onTapGesture {
            if onToggleRakatInfo != nil && !hasNotificationToggles {
                onToggleRakatInfo?()
            }
        }
        .onLongPressGesture {
            onToggleRakatInfo?()
        }
    }

    // MARK: - Prayer Row

    private func prayerRow(_ prayer: PrayerTime) -> some View {
        let isEnabled = hasNotificationToggles ? (notificationEnabledPrayers.contains(prayer.type) || !prayer.type.isObligatory) : true
        let textOpacity: Double = isEnabled ? 1.0 : 0.5
        let rakatInfo = showRakatInfo ? PrayerRakats.info(for: prayer.type, madhab: madhab) : nil
        let timeString = prayer.time.formatted(date: .omitted, time: .shortened)

        return Group {
            if hasNotificationToggles && prayer.type.isObligatory {
                Button {
                    onToggleNotification?(prayer.type)
                } label: {
                    rowContent(prayer, textOpacity: textOpacity, showBell: true, isEnabled: notificationEnabledPrayers.contains(prayer.type), rakatInfo: rakatInfo)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(prayer.type.displayName) at \(timeString)\(rakatInfo.map { ", \($0.detailedSummary)" } ?? "")")
                .accessibilityHint(notificationEnabledPrayers.contains(prayer.type) ? "Notification on, double tap to turn off" : "Notification off, double tap to turn on")
            } else {
                rowContent(prayer, textOpacity: textOpacity, showBell: false, isEnabled: true, rakatInfo: rakatInfo)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(prayer.type.displayName) at \(timeString)\(rakatInfo.map { ", \($0.detailedSummary)" } ?? "")")
            }
        }
    }

    private func rowContent(_ prayer: PrayerTime, textOpacity: Double, showBell: Bool, isEnabled: Bool, rakatInfo: PrayerRakatInfo?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
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
                    .frame(minWidth: 46, alignment: .trailing)

                if showBell {
                    Image(systemName: isEnabled ? "bell.fill" : "bell.slash")
                        .font(.system(size: 10))
                        .foregroundColor(isEnabled ? .accentColor : SafaColors.Fallback.tertiaryText)
                }
            }

            if let rakatInfo {
                Text(rakatInfo.compactSummary)
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
                    .opacity(textOpacity)
            }
        }
    }
}

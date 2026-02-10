// MARK: - HomeView.swift
// PURPOSE: Main home screen with prayer countdown and quick actions
// DEPENDENCIES: SwiftUI, Combine

import SwiftUI
import Combine

struct HomeView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router

    @State private var nextPrayer: PrayerTime?
    @State private var todayPrayers: [PrayerTime] = []
    @State private var loggedPrayers: Set<PrayerType> = []
    @State private var hijriDate = ""
    @State private var dailyVerse: Ayah?
    @State private var isRamadan = false
    @State private var showRamadanBanner = true
    @State private var suhoorTime: Date?
    @State private var iftarTime: Date?
    @State private var currentRamadanDay: Int = 0
    @State private var daysUntilRamadan: Int?
    @State private var isLastTenNights = false
    @State private var isRamadanBannerExpanded = false
    @State private var showShareBanner = !ShareBanner.isDismissed
    @State private var loadError: Error?

    // Banner dismiss key (reappears next day)
    private var bannerDismissKey: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "ramadan_banner_dismissed_\(dateFormatter.string(from: Date()))"
    }

    var body: some View {
        ScrollableScreen(stickyContent: nextPrayerChip) {
            if todayPrayers.isEmpty && hijriDate.isEmpty {
                if let loadError {
                    ErrorView.loadFailed(retry: { await loadHomeData() })
                } else {
                    HomeSkeletonView()
                }
            } else {
            VStack(spacing: SafaSpacing.lg) {
                // Date subheader (Option 4: visible below large title, scrolls away)
                if !useBasicInlineHeader {
                    dateSubheader
                }

                // Next prayer card
                if let prayer = nextPrayer {
                    NextPrayerHomeCard(prayer: prayer) {
                        router.selectedTab = "prayer"
                    }
                }

                // Quick actions
                quickActions

                // Ramadan banner (collapsible, reappears next day)
                ramadanBannerSection

                // Daily verse
                if let verse = dailyVerse {
                    dailyVerseCard(verse)
                }

                // Progress summary
                progressCard

                // Contextual reminders
                contextualReminders

                // Share app banner (hidden once user shares)
                if showShareBanner {
                    ShareBanner {
                        withAnimation {
                            showShareBanner = false
                        }
                    }
                }
            }
            .padding()
            } // end else (skeleton)
        }
        .navigationTitle(useBasicInlineHeader ? "" : "Safa")
        .navigationBarTitleDisplayMode(useBasicInlineHeader ? .inline : .large)
        .toolbar {
            if useBasicInlineHeader {
                // Option 1: Compact inline header
                ToolbarItem(placement: .topBarLeading) {
                    Button { router.navigate(to: .settings) } label: {
                        Image(systemName: "gearshape").font(.body)
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text("Safa").font(.headline)
                        Text(compactDateLine).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            } else {
                // Option 4: Large collapsing title with gear on right
                ToolbarItem(placement: .topBarTrailing) {
                    Button { router.navigate(to: .settings) } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .task {
            await loadHomeData()
        }
        .onAppear {
            Task { await reloadLoggedPrayers() }
            // Recalculate next prayer (may have changed since last appear)
            nextPrayer = todayPrayers.first { $0.time > Date() && $0.type.isObligatory }
            // Re-check Ramadan state (respects Force Ramadan Mode toggle)
            isRamadan = HijriDateConverter.shared.isRamadan() || FeatureFlags.shared.isEnabled(.ramadanMode)
            if isRamadan && !HijriDateConverter.shared.isRamadan() {
                // Forced mode — set a sensible day
                currentRamadanDay = max(currentRamadanDay, 1)
                daysUntilRamadan = nil
            }
            // Re-check banner dismiss state (synced with Settings toggle)
            showRamadanBanner = !UserDefaults.standard.bool(forKey: bannerDismissKey)
        }
    }

    // MARK: - Ramadan Banner Section

    @ViewBuilder
    private var ramadanBannerSection: some View {
        let shouldShow = showRamadanBanner
            && !UserDefaults.standard.bool(forKey: bannerDismissKey)
            && (isRamadan || (daysUntilRamadan ?? 0 > 0 && daysUntilRamadan ?? 0 <= 30))

        if shouldShow {
            VStack(spacing: 0) {
                // Collapsed header row (always visible)
                ramadanBannerCollapsedRow
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isRamadanBannerExpanded.toggle()
                        }
                    }

                // Expanded content (tap to open Ramadan page)
                if isRamadanBannerExpanded {
                    ramadanBannerExpandedContent
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .onTapGesture {
                            router.navigate(to: .ramadan)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        }
    }

    private var ramadanBannerCollapsedRow: some View {
        HStack(spacing: SafaSpacing.sm) {
            Image(systemName: ramadanBannerIcon)
                .font(.body)
                .foregroundColor(ramadanBannerIconColor)

            Text(ramadanBannerSummaryText)
                .font(SafaTypography.titleSmall)
                .foregroundColor(SafaColors.Fallback.text)

            Spacer()

            Image(systemName: isRamadanBannerExpanded ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundColor(SafaColors.Fallback.tertiaryText)

            Button {
                dismissBanner()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
                    .padding(SafaSpacing.xxs)
            }
        }
        .padding(.horizontal, SafaSpacing.md)
        .padding(.vertical, SafaSpacing.sm)
        .background(Color(UIColor.secondarySystemBackground))
    }

    @ViewBuilder
    private var ramadanBannerExpandedContent: some View {
        if isRamadan {
            if isLastTenNights {
                LastTenNightsBanner(
                    currentNight: currentRamadanDay,
                    onDismiss: dismissBanner
                )
            } else {
                RamadanBanner(
                    suhoorTime: suhoorTime,
                    iftarTime: iftarTime,
                    onDismiss: dismissBanner
                )
            }
        } else if let days = daysUntilRamadan, days <= 30, days > 0 {
            PreRamadanBanner(
                daysUntil: days,
                onDismiss: dismissBanner
            )
        }
    }

    private var ramadanBannerSummaryText: String {
        if isRamadan {
            if isLastTenNights {
                return "Last 10 Nights - Night \(currentRamadanDay)"
            }
            return "Ramadan - Day \(currentRamadanDay)"
        } else if let days = daysUntilRamadan, days <= 30, days > 0 {
            return "\(days) days until Ramadan"
        }
        return "Ramadan"
    }

    private var ramadanBannerIcon: String {
        if isRamadan && isLastTenNights {
            return "sparkles"
        }
        return "moon.stars.fill"
    }

    private var ramadanBannerIconColor: Color {
        isRamadan ? .purple : .accentColor
    }

    private func dismissBanner() {
        withAnimation {
            UserDefaults.standard.set(true, forKey: bannerDismissKey)
            showRamadanBanner = false
        }
    }

    // MARK: - Next Prayer Chip (Sticky Toolbar)

    private func nextPrayerChip() -> some View {
        Group {
            if let prayer = nextPrayer {
                NextPrayerChip(prayer: prayer) {
                    router.selectedTab = "prayer"
                }
            }
        }
    }

    // MARK: - Header Layout

    private var useBasicInlineHeader: Bool {
        FeatureFlags.shared.isEnabled(.basicInlineHeader)
    }

    /// Option 4: Date line below large title (scrolls away with content)
    private var dateSubheader: some View {
        HStack {
            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if isRamadan {
                Label(hijriDate, systemImage: "moon.stars.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.purple)
            } else {
                Text(hijriDate)
                    .font(.subheadline.weight(.medium))
            }
        }
    }

    // MARK: - Compact Date Line (for toolbar)

    private var compactDateLine: String {
        let gregorian = Date().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        if hijriDate.isEmpty {
            return gregorian
        }
        return "\(gregorian) · \(hijriDate)"
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SafaSpacing.md) {
            QuickActionCard(
                icon: "clock.fill",
                title: "Prayer",
                subtitle: "Times & logging",
                color: .green
            ) {
                router.selectedTab = "prayer"
            }

            QuickActionCard(
                icon: "heart.text.square.fill",
                title: "Duas",
                subtitle: "Daily supplications",
                color: .blue
            ) {
                router.selectedTab = "duas"
            }

            QuickActionCard(
                icon: "graduationcap.fill",
                title: "Learn",
                subtitle: "Arabic & Tajweed",
                color: .purple
            ) {
                router.navigate(to: .learn)
            }
            .disabledFeature(.learning)

            QuickActionCard(
                icon: "sparkles",
                title: "Ask Safa",
                subtitle: "AI companion",
                color: .orange
            ) {
                // No-op — feature not yet implemented
            }
            .disabledFeature(.aiCompanion)
        }
    }

    // MARK: - Daily Verse Card

    private func dailyVerseCard(_ verse: Ayah) -> some View {
        TitledCard(title: "Daily Verse", subtitle: "Surah \(verse.surahNumber):\(verse.ayahNumber)") {
            VStack(alignment: .trailing, spacing: SafaSpacing.sm) {
                Text(verse.textArabic)
                    .font(SafaTypography.arabicMedium)
                    .foregroundColor(SafaColors.Fallback.text)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)

                Text(verse.textTranslation)
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        InteractiveCard(action: {
            ToastService.shared.show(Toast(message: "Progress Dashboard coming soon", type: .info))
        }) {
            HStack {
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text("Your Progress")
                        .font(SafaTypography.titleSmall)

                    HStack(spacing: SafaSpacing.md) {
                        HomeStatItem(
                            value: "\(dependencies.userState.totalHasanat)",
                            label: "Hasanat"
                        )

                        HomeStatItem(
                            value: "\(dependencies.userState.dailyStreak?.currentCount ?? 0)",
                            label: "Day Streak"
                        )

                        HomeStatItem(
                            value: "Lv.\(dependencies.userState.currentLevel)",
                            label: dependencies.userState.levelTitle
                        )
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
    }

    // MARK: - Contextual Reminders

    private var contextualReminders: some View {
        VStack(spacing: SafaSpacing.sm) {
            let hour = Calendar.current.component(.hour, from: Date())

            if hour >= 4 && hour < 6 {
                ReminderCard(
                    icon: "moon.stars",
                    title: "Tahajjud Time",
                    message: "The last third of the night is a blessed time for prayer."
                )
            }

            if hour >= 6 && hour < 9 {
                ReminderCard(
                    icon: "sunrise",
                    title: "Morning Dhikr",
                    message: "Start your day with morning remembrance."
                ) {
                    router.navigate(to: .dhikr)
                }
            }

            if hour >= 17 && hour < 20 {
                ReminderCard(
                    icon: "sunset",
                    title: "Evening Dhikr",
                    message: "Complete your evening remembrance."
                ) {
                    router.navigate(to: .dhikr)
                }
            }
        }
    }

    private func reloadLoggedPrayers() async {
        do {
            let logs = try await dependencies.prayerRepository.getPrayerLogs(for: Date())
            loggedPrayers = Set(logs.map { $0.prayerType })
        } catch {
            // Keep existing state
        }
    }

    // MARK: - Load Data

    private func loadHomeData() async {
        loadError = nil

        // Load Hijri date
        hijriDate = HijriDateConverter.shared.hijriDateString(from: Date(), style: .full)
        isRamadan = HijriDateConverter.shared.isRamadan() || FeatureFlags.shared.isEnabled(.ramadanMode)

        // Load Ramadan data
        let ramadanService = dependencies.ramadanService
        ramadanService.checkRamadanStatus()
        currentRamadanDay = isRamadan ? max(ramadanService.currentRamadanDay, 1) : 0
        daysUntilRamadan = isRamadan ? nil : ramadanService.daysUntilRamadan
        isLastTenNights = currentRamadanDay >= 21 && currentRamadanDay <= 30

        // Expanded by default during Ramadan, collapsed otherwise
        isRamadanBannerExpanded = isRamadan

        // Check if banner was dismissed today
        showRamadanBanner = !UserDefaults.standard.bool(forKey: bannerDismissKey)

        // Load prayer times
        do {
            if let location = dependencies.locationService.coordinates {
                // Use saved calculation method (same as PrayerViewModel)
                let savedMethod: CalculationMethod
                if let raw = UserDefaults.standard.string(forKey: "calculationMethod"),
                   let method = CalculationMethod(rawValue: raw) {
                    savedMethod = method
                } else {
                    savedMethod = AppDefaults.calculationMethod
                }
                todayPrayers = try await dependencies.prayerRepository.getPrayers(
                    for: Date(),
                    location: location,
                    method: savedMethod
                )
                nextPrayer = todayPrayers.first { $0.time > Date() && $0.type.isObligatory }

                // Load logged prayers for today
                let logs = try await dependencies.prayerRepository.getPrayerLogs(for: Date())
                loggedPrayers = Set(logs.map { $0.prayerType })

                // Sync to widgets via App Group
                WidgetDataService.shared.writePrayerTimes(todayPrayers)
                WidgetDataService.shared.writeLoggedPrayers(loggedPrayers, for: Date())
                WidgetDataService.shared.writeHijriDate(hijriDate)

                // Set Suhoor (Fajr) and Iftar (Maghrib) times for Ramadan banner
                suhoorTime = todayPrayers.first { $0.type == .fajr }?.time
                iftarTime = todayPrayers.first { $0.type == .maghrib }?.time
            }
        } catch {
            loadError = error
        }

        // Load daily verse
        dailyVerse = Ayah.alFatiha.randomElement()

        // Award dailyVerse hasanat (once per day)
        if dailyVerse != nil {
            await HasanatTracker.awardOnce(.dailyVerse, key: "dailyVerse", via: dependencies.userState)
        }
    }
}

// MARK: - Next Prayer Home Card

private struct NextPrayerHomeCard: View {
    let prayer: PrayerTime
    let action: () -> Void

    @State private var countdown = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        InteractiveCard(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text("Next Prayer")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)

                    Text(prayer.type.displayName)
                        .font(SafaTypography.headlineMedium)
                        .foregroundColor(prayer.type.color)

                    Text(prayer.time.formatted(date: .omitted, time: .shortened))
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: SafaSpacing.xxs) {
                    Text("Time until next prayer")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)

                    Text(countdown)
                        .font(SafaTypography.counterSmall)
                        .foregroundColor(SafaColors.Fallback.text)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
        }
        .onReceive(timer) { _ in
            updateCountdown()
        }
        .onAppear {
            updateCountdown()
        }
    }

    private func updateCountdown() {
        let (hours, minutes, seconds) = prayer.time.countdown()
        countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Quick Action Card

private struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedbackService.shared.play(.tap)
            action()
        }) {
            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(title)
                        .font(SafaTypography.titleSmall)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text(subtitle)
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SafaSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        }
    }
}

// MARK: - Home Stat Item

private struct HomeStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: SafaSpacing.xxs) {
            Text(value)
                .font(SafaTypography.titleMedium)
                .foregroundColor(.accentColor)

            Text(label)
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.tertiaryText)
        }
    }
}

// MARK: - Reminder Card

private struct ReminderCard: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: SafaSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                Text(title)
                    .font(SafaTypography.titleSmall)
                    .foregroundColor(SafaColors.Fallback.text)

                Text(message)
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            Spacer()

            if action != nil {
                Button(action: { action?() }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
            }
        }
        .padding(SafaSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }
}

// MARK: - Next Prayer Accessibility Helper

func formatNextPrayerAccessibilityLabel(prayerName: String, hours: Int, minutes: Int) -> String {
    var parts: [String] = []
    if hours > 0 { parts.append("\(hours) hour\(hours == 1 ? "" : "s")") }
    if minutes > 0 { parts.append("\(minutes) minute\(minutes == 1 ? "" : "s")") }
    let timeText = parts.isEmpty ? "now" : "in \(parts.joined(separator: " "))"
    return "Next prayer: \(prayerName) \(timeText)"
}

// MARK: - Next Prayer Chip (Sticky Toolbar)

private struct NextPrayerChip: View {
    let prayer: PrayerTime
    let action: () -> Void

    @State private var countdown = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button(action: action) {
            HStack(spacing: SafaSpacing.xs) {
                Circle()
                    .fill(prayer.type.color)
                    .frame(width: 8, height: 8)

                Text(prayer.type.displayName)
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(SafaColors.Fallback.text)

                Text("·")
                    .foregroundColor(SafaColors.Fallback.tertiaryText)

                Text(countdown)
                    .font(SafaTypography.labelMedium)
                    .monospacedDigit()
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .contentTransition(.numericText())
                    .animation(
                        reduceMotion ? nil : .default,
                        value: countdown
                    )
            }
            .padding(.horizontal, SafaSpacing.sm)
            .padding(.vertical, SafaSpacing.xxs)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(Capsule())
        }
        .accessibilityLabel(accessibilityText)
        .onReceive(timer) { _ in
            updateCountdown()
        }
        .onAppear {
            updateCountdown()
        }
    }

    private func updateCountdown() {
        let (hours, minutes, seconds) = prayer.time.countdown()
        countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var accessibilityText: String {
        let (hours, minutes, _) = prayer.time.countdown()
        return formatNextPrayerAccessibilityLabel(
            prayerName: prayer.type.displayName,
            hours: hours,
            minutes: minutes
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
            .environment(Dependencies())
            .environment(AppRouter())
    }
}

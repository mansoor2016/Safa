// MARK: - PrayerView.swift
// PURPOSE: Main prayer times view displaying daily prayers and Qibla
// DEPENDENCIES: SwiftUI, PrayerViewModel
// NOTE: DailyGoalsCard intentionally removed — goals are tracked on Home tab (Khatm card + fasting tracker)

import SwiftUI
import CoreLocation
import Combine
import SafaShared

struct PrayerView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var viewModel: PrayerViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                PrayerContentView(viewModel: viewModel)
            } else {
                PrayerSkeletonView()
            }
        }
        .task {
            if viewModel == nil {
                viewModel = PrayerViewModel(
                    prayerRepository: dependencies.prayerRepository,
                    locationService: dependencies.locationService,
                    userState: dependencies.userState
                )
            }
        }
    }
}

// MARK: - Prayer Content View

private struct PrayerContentView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var viewModel: PrayerViewModel
    @State private var showingQibla = false
    @State private var showingSettings = false
    @State private var deferredLogPrayer: PrayerType?

    // Timer to recompute nextPrayer indicator when grace window expires
    let prayerRefreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollableScreen {
            if viewModel.error != nil {
                ErrorView.prayerTimesError(retry: { await viewModel.loadPrayerTimes() })
            } else {
            VStack(spacing: SafaSpacing.lg) {
                // 1. Date Header
                dateHeader

                // 2. Next Prayer countdown (iftar-platter style)
                if let nextPrayer = viewModel.nextPrayer {
                    NextPrayerCard(prayer: nextPrayer, madhab: viewModel.madhab)
                }

                // 3. Compact prayer times with notification toggles
                PrayerTimePreviewCard(
                    prayers: viewModel.todayPrayers,
                    madhab: viewModel.madhab,
                    showRakatInfo: viewModel.showRakatInfo,
                    notificationEnabledPrayers: viewModel.notificationEnabledPrayers,
                    onToggleNotification: { prayerType in
                        Task { await viewModel.toggleNotification(for: prayerType) }
                    },
                    onToggleRakatInfo: { viewModel.toggleRakatInfo() }
                )

                // 4. Prayer progress dots in ContentCard
                PrayerProgressCard(
                    prayers: viewModel.todayPrayers,
                    loggedPrayers: viewModel.loggedPrayers,
                    nextPrayer: viewModel.nextPrayer,
                    onLogPrayer: { prayerType in
                        Task { await viewModel.togglePrayer(prayerType) }
                    }
                )

                // 5. Quick actions (Qibla + Adhan)
                quickActionsSection

                // 7. Sunnah Times (below quick actions if enabled)
                if viewModel.showSunnahTimes && !viewModel.sunnahTimes.isEmpty {
                    SunnahTimesCard(sunnahTimes: viewModel.sunnahTimes)
                }
            }
            .padding(SafaSpacing.md)
            } // end error check
        }
        .navigationTitle("Prayer Times")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingQibla) {
            NavigationStack {
                QiblaCompassView()
            }
            .largeSheet()
        }
        .sheet(isPresented: $showingSettings, onDismiss: {
            viewModel.reloadSettings()
            Task { await viewModel.loadPrayerTimes() }
        }) {
            NavigationStack {
                PrayerSettingsView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showingSettings = false }
                        }
                    }
            }
            .fullSheet()
        }
        .refreshable {
            await viewModel.refreshPrayerTimes()
        }
        .task {
            await viewModel.loadPrayerTimes()
        }
        .onAppear {
            viewModel.reloadSettings()
            Task {
                await viewModel.reloadLoggedPrayers()
                await viewModel.loadPrayerTimes()
            }
            viewModel.updateNextPrayerIndicator()
            handlePendingNotificationAction()
        }
        .onReceive(prayerRefreshTimer) { _ in
            viewModel.updateNextPrayerIndicator()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.updateNextPrayerIndicator()
                Task { await viewModel.refreshForForeground() }
            }
        }
        .onChange(of: router.pendingNotificationAction) { _, newValue in
            if newValue != nil { handlePendingNotificationAction() }
        }
        .onChange(of: viewModel.todayPrayers.isEmpty) { wasEmpty, isEmpty in
            // Prayers just loaded — flush any deferred log action
            if wasEmpty && !isEmpty, let prayerType = deferredLogPrayer {
                deferredLogPrayer = nil
                Task { await viewModel.logPrayer(prayerType) }
            }
        }
    }

    // MARK: - Notification Action Handling

    private func handlePendingNotificationAction() {
        guard let action = router.pendingNotificationAction else { return }
        router.pendingNotificationAction = nil
        switch action {
        case .openQibla:
            showingQibla = true
        case .logPrayer(let prayerType):
            if viewModel.todayPrayers.isEmpty {
                // Prayers not loaded yet — defer until they arrive
                deferredLogPrayer = prayerType
            } else {
                Task { await viewModel.logPrayer(prayerType) }
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        VStack(spacing: SafaSpacing.sm) {
            HStack {
                Text(viewModel.currentDate.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(HijriDateConverter.shared.hijriDateString(from: Date(), style: .dayMonth, maghribTime: viewModel.todayPrayers.first(where: { $0.type == .maghrib })?.time))
                    .font(.subheadline.weight(.medium))
            }

            // Location fallback indicator
            if dependencies.locationService.authorizationStatus != .authorizedWhenInUse
                && dependencies.locationService.authorizationStatus != .authorizedAlways {
                DegradedStateBanner.locationFallback(locationName: AppDefaults.defaultLocationName)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        PrayerQuickActionsBar(
            isFajr: viewModel.nextPrayer?.type == .fajr,
            onQibla: { showingQibla = true }
        )
    }
}

// MARK: - Next Prayer Card

struct NextPrayerCard: View {
    let prayer: PrayerTime
    let madhab: Madhab

    var body: some View {
        ContentCard {
            HStack(spacing: SafaSpacing.md) {
                // Prayer icon
                Image(systemName: prayer.type.iconName)
                    .font(.title2)
                    .foregroundColor(prayer.type.color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    // Countdown + prayer info
                    TimelineView(PeriodicTimelineSchedule(from: .now, by: 1)) { _ in
                        let inGrace = isPrayerTimeNow(prayer.time)
                        let inFuture = prayer.time > Date()
                        HStack(alignment: .firstTextBaseline, spacing: SafaSpacing.xs) {
                            if inGrace {
                                Text("Prayer time")
                                    .font(SafaTypography.headlineLarge)
                            } else if inFuture {
                                Text(prayer.time, style: .timer)
                                    .font(SafaTypography.headlineLarge)
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                            } else {
                                // Grace expired but parent hasn't re-rendered yet —
                                // show "Prayer time" briefly to avoid count-up display
                                Text("Prayer time")
                                    .font(SafaTypography.headlineLarge)
                            }

                            if inGrace || !inFuture {
                                Text("\(prayer.type.displayName) · \(prayer.time.formatted(date: .omitted, time: .shortened))")
                                    .font(SafaTypography.labelMedium)
                                    .foregroundColor(SafaColors.Fallback.secondaryText)
                            } else {
                                Text("until \(prayer.type.displayName) · \(prayer.time.formatted(date: .omitted, time: .shortened))")
                                    .font(SafaTypography.labelMedium)
                                    .foregroundColor(SafaColors.Fallback.secondaryText)
                            }
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    }

                    // Rakat breakdown (always visible for current prayer)
                    if let rakatInfo = PrayerRakats.info(for: prayer.type, madhab: madhab) {
                        Text(rakatInfo.detailedSummary)
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.tertiaryText)
                    }
                }

                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(nextPrayerAccessibilityLabel)
        .accessibilityHint("Shows time until next prayer")
    }

    private var nextPrayerAccessibilityLabel: String {
        let rakatSuffix = PrayerRakats.info(for: prayer.type, madhab: madhab).map { ", \($0.detailedSummary)" } ?? ""
        if isPrayerTimeNow(prayer.time) {
            return String(localized: "It's time for \(prayer.type.displayName) prayer") + rakatSuffix
        }
        let (hours, minutes, _) = prayer.time.countdown()
        let timeString = prayer.time.formatted(date: .omitted, time: .shortened)
        if hours > 0 {
            return "Next prayer is \(prayer.type.displayName) at \(timeString), \(hours) hours and \(minutes) minutes remaining" + rakatSuffix
        } else {
            return "Next prayer is \(prayer.type.displayName) at \(timeString), \(minutes) minutes remaining" + rakatSuffix
        }
    }
}

// MARK: - Sunnah Times Card

private struct SunnahTimesCard: View {
    let sunnahTimes: [SunnahTime]

    var body: some View {
        ContentCard {
            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                HStack(spacing: SafaSpacing.xs) {
                    Image(systemName: "moon.haze.fill")
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                        .font(.caption)
                    Text("Night Prayer Times")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                ForEach(sunnahTimes) { sunnah in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: sunnah.type.iconName)
                                .foregroundColor(SafaColors.Fallback.tertiaryText)
                                .frame(width: 20)

                            Text(sunnah.type.displayName)
                                .font(SafaTypography.bodyMedium)
                                .foregroundColor(SafaColors.Fallback.secondaryText)

                            Spacer()

                            Text(sunnah.time.formatted(date: .omitted, time: .shortened))
                                .font(SafaTypography.bodyMedium)
                                .foregroundColor(SafaColors.Fallback.secondaryText)
                                .monospacedDigit()
                        }

                        if sunnah.type == .middleOfTheNight {
                            Text("Tahajjud: 2 to 12 rak'ahs (pairs of 2)")
                                .font(SafaTypography.labelSmall)
                                .foregroundColor(SafaColors.Fallback.tertiaryText)
                                .padding(.leading, 24)
                        } else if sunnah.type == .lastThirdOfTheNight {
                            Text("Best time for Qiyam al-Layl")
                                .font(SafaTypography.labelSmall)
                                .foregroundColor(SafaColors.Fallback.tertiaryText)
                                .padding(.leading, 24)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(sunnahAccessibilityLabel(sunnah))
                }
            }
        }
    }

    private func sunnahAccessibilityLabel(_ sunnah: SunnahTime) -> String {
        let timeString = sunnah.time.formatted(date: .omitted, time: .shortened)
        switch sunnah.type {
        case .middleOfTheNight:
            return "\(sunnah.type.displayName) at \(timeString), Tahajjud: 2 to 12 rak'ahs in pairs of 2"
        case .lastThirdOfTheNight:
            return "\(sunnah.type.displayName) at \(timeString), Best time for Qiyam al-Layl"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrayerView()
            .environment(Dependencies())
    }
}

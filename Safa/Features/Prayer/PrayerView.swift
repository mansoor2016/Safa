// MARK: - PrayerView.swift
// PURPOSE: Main prayer times view displaying daily prayers and Qibla
// DEPENDENCIES: SwiftUI, PrayerViewModel

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
                    NextPrayerCard(prayer: nextPrayer)
                }

                // 3. Compact prayer times with notification toggles
                PrayerTimePreviewCard(
                    prayers: viewModel.todayPrayers,
                    notificationEnabledPrayers: viewModel.notificationEnabledPrayers,
                    onToggleNotification: { prayerType in
                        Task { await viewModel.toggleNotification(for: prayerType) }
                    }
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

                // 5. Daily Goals
                DailyGoalsCard(isRamadan: false, loggedPrayers: viewModel.loggedPrayers, todayPrayers: viewModel.todayPrayers)

                // 6. Quick actions (Qibla + Adhan)
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

                Text(HijriDateConverter.shared.hijriDateString(from: viewModel.currentDate, style: .full))
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

private struct NextPrayerCard: View {
    let prayer: PrayerTime

    var body: some View {
        ContentCard {
            HStack(spacing: SafaSpacing.md) {
                // Prayer icon
                Image(systemName: prayer.type.iconName)
                    .font(.title2)
                    .foregroundColor(prayer.type.color)
                    .frame(width: 32)

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
                }

                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(nextPrayerAccessibilityLabel)
        .accessibilityHint("Shows time until next prayer")
    }

    private var nextPrayerAccessibilityLabel: String {
        if isPrayerTimeNow(prayer.time) {
            return String(localized: "It's time for \(prayer.type.displayName) prayer")
        }
        let (hours, minutes, _) = prayer.time.countdown()
        let timeString = prayer.time.formatted(date: .omitted, time: .shortened)
        if hours > 0 {
            return "Next prayer is \(prayer.type.displayName) at \(timeString), \(hours) hours and \(minutes) minutes remaining"
        } else {
            return "Next prayer is \(prayer.type.displayName) at \(timeString), \(minutes) minutes remaining"
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
                }
            }
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

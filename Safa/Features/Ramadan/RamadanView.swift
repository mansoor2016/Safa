// MARK: - RamadanView.swift
// PURPOSE: Ramadan mode dashboard — replaces Prayer tab during Ramadan
// DEPENDENCIES: SwiftUI, PrayerViewModel, RamadanSubviews, shared components
// NOTE: DailyGoalsCard intentionally removed — goals are tracked on Home tab (Khatm card + fasting tracker)

import SwiftUI

struct RamadanView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @State private var prayerViewModel: PrayerViewModel?
    @State private var showTaraweehTracker = false
    @State private var showSettings = false
    @State private var showingQibla = false
    @State private var showZakat = false
    @State private var deferredLogPrayer: PrayerType?

    private let hijriConverter = HijriDateConverter.shared

    // MARK: - Computed Properties

    private var suhoorTime: Date? {
        prayerViewModel?.todayPrayers.first { $0.type == .fajr }?.time
    }

    private var iftarTime: Date? {
        prayerViewModel?.todayPrayers.first { $0.type == .maghrib }?.time
    }

    var body: some View {
        ScrollableScreen {
            VStack(spacing: SafaSpacing.lg) {
                // Date subheader (scrolls away with large title)
                dateSubheader

                // 1. Iftar/Suhoor countdown platter
                iftarPlatter

                // 2. Today's prayer timetable (with notification toggles)
                if let vm = prayerViewModel {
                    PrayerTimePreviewCard(
                        prayers: vm.todayPrayers,
                        notificationEnabledPrayers: vm.notificationEnabledPrayers,
                        onToggleNotification: { prayerType in
                            Task { await vm.toggleNotification(for: prayerType) }
                        }
                    )

                    // 3. Prayer progress (full-width, expanded)
                    PrayerProgressCard(
                        prayers: vm.todayPrayers,
                        loggedPrayers: vm.loggedPrayers,
                        nextPrayer: vm.nextPrayer,
                        onLogPrayer: { prayerType in
                            Task { await vm.togglePrayer(prayerType) }
                        }
                    )

                }

                // 4. Ramadan quick actions (Taraweeh, Zakat)
                quickActionsGrid

                // 6. Adhan + Qibla buttons (same as Prayer page)
                PrayerQuickActionsBar(onQibla: { showingQibla = true })
            }
            .padding(SafaSpacing.md)
        }
        .navigationTitle("Prayer Times")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            prayerViewModel?.reloadSettings()
            Task { await prayerViewModel?.loadPrayerTimes() }
        }) {
            NavigationStack {
                PrayerSettingsView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showSettings = false }
                        }
                    }
            }
            .fullSheet()
        }
        .sheet(isPresented: $showTaraweehTracker) {
            TaraweehTrackerSheet()
        }
        .sheet(isPresented: $showingQibla) {
            NavigationStack { QiblaCompassView() }
                .largeSheet()
        }
        .sheet(isPresented: $showZakat) {
            NavigationStack { ZakatCalculatorView() }
                .fullSheet()
        }
        .task {
            if prayerViewModel == nil {
                prayerViewModel = PrayerViewModel(
                    prayerRepository: dependencies.prayerRepository,
                    locationService: dependencies.locationService,
                    userState: dependencies.userState
                )
            }
            await loadRamadanData()
        }
        .onAppear {
            handlePendingNotificationAction()
        }
        .onChange(of: router.pendingNotificationAction) { _, newValue in
            if newValue != nil { handlePendingNotificationAction() }
        }
        .onChange(of: prayerViewModel?.todayPrayers.isEmpty) { wasEmpty, isEmpty in
            if wasEmpty == true && isEmpty == false, let prayerType = deferredLogPrayer {
                deferredLogPrayer = nil
                Task { await prayerViewModel?.logPrayer(prayerType) }
            }
        }
    }

    // MARK: - Date Subheader

    private var dateSubheader: some View {
        Text(hijriConverter.hijriDateString(from: Date(), style: .dayMonth))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Iftar Countdown Platter

    private var iftarPlatter: some View {
        ContentCard {
            VStack(spacing: SafaSpacing.sm) {
                // Sunrise + Iftar times on one line
                HStack {
                    HStack(spacing: SafaSpacing.xs) {
                        Image(systemName: "sunrise.fill")
                            .foregroundStyle(.orange)
                        Text("Suhoor")
                            .font(SafaTypography.labelSmall)
                            .foregroundStyle(.secondary)
                        if let suhoor = suhoorTime {
                            Text(suhoor.formatted(date: .omitted, time: .shortened))
                                .font(SafaTypography.titleSmall)
                        }
                    }

                    Spacer()

                    HStack(spacing: SafaSpacing.xs) {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(.purple)
                        Text("Iftar")
                            .font(SafaTypography.labelSmall)
                            .foregroundStyle(.secondary)
                        if let iftar = iftarTime {
                            Text(iftar.formatted(date: .omitted, time: .shortened))
                                .font(SafaTypography.titleSmall)
                        }
                    }
                }

                Divider()

                // Live countdown (uses shared helper for Suhoor-first priority)
                switch RamadanCountdownHelpers.resolveTarget(now: Date(), suhoorTime: suhoorTime, iftarTime: iftarTime) {
                case .suhoor(let time):
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.orange)
                        Text(time, style: .timer)
                            .font(SafaTypography.headlineLarge)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("until Suhoor ends")
                            .font(SafaTypography.labelMedium)
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                case .iftar(let time):
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(Color.accentColor)
                        Text(time, style: .timer)
                            .font(SafaTypography.headlineLarge)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("until Iftar")
                            .font(SafaTypography.labelMedium)
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                case .nextSuhoor(let time):
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.secondary)
                        Text(time, style: .timer)
                            .font(SafaTypography.headlineLarge)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .foregroundStyle(.secondary)
                        Text("until Suhoor tomorrow")
                            .font(SafaTypography.labelMedium)
                            .foregroundStyle(.tertiary)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                case .complete:
                    Label("Fasting complete for today", systemImage: "checkmark.circle.fill")
                        .font(SafaTypography.titleSmall)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    // MARK: - Quick Actions Grid

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SafaSpacing.md) {
            RamadanQuickAction(icon: "moon.stars.fill", title: "Taraweeh", subtitle: "Track prayers", color: .purple) {
                showTaraweehTracker = true
            }
            RamadanQuickAction(icon: "dollarsign.circle.fill", title: "Zakat", subtitle: "Calculator", color: .teal) {
                showZakat = true
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
            if prayerViewModel?.todayPrayers.isEmpty != false {
                deferredLogPrayer = prayerType
            } else {
                Task { await prayerViewModel?.logPrayer(prayerType) }
            }
        }
    }

    // MARK: - Load Data

    private func loadRamadanData() async {
        await prayerViewModel?.loadPrayerTimes()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RamadanView()
            .environment(Dependencies())
            .environment(AppRouter())
    }
}

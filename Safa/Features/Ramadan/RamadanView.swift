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

    var body: some View {
        ScrollableScreen {
            VStack(spacing: SafaSpacing.lg) {
                // Date subheader (scrolls away with large title)
                dateSubheader

                // 1. Next Prayer countdown
                if let vm = prayerViewModel, let nextPrayer = vm.nextPrayer {
                    NextPrayerCard(prayer: nextPrayer, madhab: vm.madhab)
                }

                // 2. Today's prayer timetable (with notification toggles)
                if let vm = prayerViewModel {
                    PrayerTimePreviewCard(
                        prayers: vm.todayPrayers,
                        madhab: vm.madhab,
                        showRakatInfo: vm.showRakatInfo,
                        notificationEnabledPrayers: vm.notificationEnabledPrayers,
                        onToggleNotification: { prayerType in
                            Task { await vm.toggleNotification(for: prayerType) }
                        },
                        onToggleRakatInfo: { vm.toggleRakatInfo() }
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
        Text(hijriConverter.hijriDateString(from: Date(), style: .dayMonth, maghribTime: prayerViewModel?.todayPrayers.first(where: { $0.type == .maghrib })?.time))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
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

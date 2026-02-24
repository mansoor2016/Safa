// MARK: - RamadanView.swift
// PURPOSE: Ramadan mode dashboard — replaces Prayer tab during Ramadan
// DEPENDENCIES: SwiftUI, PrayerViewModel, RamadanSubviews, shared components

import SwiftUI

struct RamadanView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @State private var prayerViewModel: PrayerViewModel?
    @State private var todayFasted = false
    @State private var currentDay = 1
    @State private var fastingDays: Set<Int> = []
    @State private var showTaraweehTracker = false
    @State private var showSettings = false
    @State private var showingQibla = false
    @State private var showZakat = false
    @State private var juzCompleted = 0
    @State private var healthSyncEnabled = false
    @State private var healthKitService = HealthKitService.shared
    @State private var deferredLogPrayer: PrayerType?

    private let hijriConverter = HijriDateConverter.shared
    private let totalDays = 30

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

                    // 4. Daily goals
                    DailyGoalsCard(isRamadan: true, loggedPrayers: vm.loggedPrayers, todayPrayers: vm.todayPrayers)
                }

                // 5. Ramadan quick actions (Quran, Taraweeh, Zakat, Duas)
                quickActionsGrid

                // 6. Adhan + Qibla buttons (same as Prayer page)
                PrayerQuickActionsBar(onQibla: { showingQibla = true })

                // 7. Fasting tracker (Ramadan-only)
                fastingTrackerCard

                // 8. Quran Khatm goal
                quranGoalCard
            }
            .padding(SafaSpacing.md)
        }
        .navigationTitle("Ramadan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            RamadanSettingsSheet(
                healthSyncEnabled: $healthSyncEnabled,
                healthKitService: healthKitService
            )
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
            healthSyncEnabled = healthKitService.syncEnabled
        }
        .onAppear {
            loadJuzCount()
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
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            loadJuzCount() // Refresh when daily goals are toggled
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

    // MARK: - Fasting Tracker Card

    private var fastingTrackerCard: some View {
        TitledCard(title: "Fasting Tracker", subtitle: "\(fastingDays.count) days completed") {
            VStack(spacing: SafaSpacing.md) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: SafaSpacing.xs) {
                    ForEach(1...totalDays, id: \.self) { day in
                        FastingDayCell(
                            day: day,
                            isFasted: fastingDays.contains(day),
                            isToday: day == currentDay,
                            isPast: day < currentDay
                        ) {
                            toggleFastingDay(day)
                        }
                    }
                }
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)

                if currentDay <= totalDays {
                    Button {
                        toggleFastingDay(currentDay)
                    } label: {
                        HStack {
                            Image(systemName: fastingDays.contains(currentDay) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(fastingDays.contains(currentDay) ? .green : SafaColors.Fallback.tertiaryText)
                            Text(fastingDays.contains(currentDay) ? "Fasted today" : "Mark today as fasted")
                                .font(SafaTypography.bodyMedium)
                                .foregroundColor(SafaColors.Fallback.text)
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
                    }
                }
            }
        }
    }

    // MARK: - Quran Goal Card

    private var quranGoalCard: some View {
        ContentCard {
            VStack(alignment: .leading, spacing: SafaSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                        Text("Quran Khatm Goal")
                            .font(SafaTypography.titleSmall)
                        Text("Complete the Quran this Ramadan")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(juzCompleted)/30")
                            .font(SafaTypography.titleMedium)
                            .foregroundColor(.accentColor)
                            .contentTransition(.numericText())
                        Text("Juz")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.2)).frame(height: 8)
                        Capsule().fill(Color.green)
                            .frame(width: geometry.size.width * CGFloat(juzCompleted) / 30, height: 8)
                            .animation(.easeInOut, value: juzCompleted)
                    }
                }
                .frame(height: 8)

                Text("Read 1 Juz per day to complete on time")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
    }

    // MARK: - Actions

    private func toggleFastingDay(_ day: Int) {
        if fastingDays.contains(day) {
            fastingDays.remove(day)
        } else {
            fastingDays.insert(day)
            // Award fasting hasanat (once per day)
            Task {
                await HasanatTracker.awardOnce(.fastingDay, key: "fastingDay_\(day)", via: dependencies.userState)
            }
            if healthSyncEnabled, let suhoor = suhoorTime, let iftar = iftarTime {
                Task { try? await healthKitService.logFast(start: suhoor, end: iftar, type: .ramadan) }
            }
        }
        // Persist
        let year = String(Calendar.current.component(.year, from: Date()))
        UserDefaults.standard.set(Array(fastingDays), forKey: "ramadan_fasting_days_\(year)")
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
        let (_, month, day) = hijriConverter.hijriComponents(from: Date())
        if month == 9 { currentDay = day }

        // Delegate prayer loading to PrayerViewModel
        await prayerViewModel?.loadPrayerTimes()

        // Load persisted fasting days
        let year = String(Calendar.current.component(.year, from: Date()))
        let savedFasting = UserDefaults.standard.array(forKey: "ramadan_fasting_days_\(year)") as? [Int] ?? []
        fastingDays = Set(savedFasting)

        // Count juz completed from daily goals (how many days had "juz" checked)
        loadJuzCount()
    }

    /// Count days where "Read 1 Juz" was completed in daily goals
    private func loadJuzCount() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current
        var count = 0
        for dayOffset in 0..<totalDays {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let key = "dailyGoals_\(formatter.string(from: date))"
                let goals = UserDefaults.standard.stringArray(forKey: key) ?? []
                if goals.contains("juz") { count += 1 }
            }
        }
        withAnimation { juzCompleted = count }
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

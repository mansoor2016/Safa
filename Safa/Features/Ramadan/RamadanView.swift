// MARK: - RamadanView.swift
// PURPOSE: Ramadan mode dashboard — replaces Prayer tab during Ramadan
// DEPENDENCIES: SwiftUI, RamadanSubviews, DailyGoalsCard

import SwiftUI

struct RamadanView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @State private var todayFasted = false
    @State private var currentDay = 1
    @State private var suhoorTime: Date?
    @State private var iftarTime: Date?
    @State private var todayPrayers: [PrayerTime] = []
    @State private var loggedPrayers: Set<PrayerType> = []
    @State private var nextPrayer: PrayerTime?
    @State private var fastingDays: Set<Int> = []
    @State private var showTaraweehTracker = false
    @State private var showSettings = false
    @State private var showingQibla = false
    @State private var showZakat = false
    @State private var juzCompleted = 0
    @State private var healthSyncEnabled = false
    @State private var healthKitService = HealthKitService.shared

    private let hijriConverter = HijriDateConverter.shared
    private let totalDays = 30

    var body: some View {
        ScrollableScreen {
            VStack(spacing: SafaSpacing.lg) {
                // Date subheader (scrolls away with large title)
                dateSubheader

                // 1. Iftar/Suhoor countdown platter
                iftarPlatter

                // 2. Prayer progress (full-width, expanded)
                prayerProgressCard

                // 3. Daily goals
                DailyGoalsCard(isRamadan: true, loggedPrayers: loggedPrayers, todayPrayers: todayPrayers)

                // 4. Ramadan quick actions (Quran, Taraweeh, Zakat, Duas)
                quickActionsGrid

                // 5. Adhan + Qibla buttons (same as Prayer page)
                adhanQiblaButtons

                // 6. Fasting tracker (Ramadan-only)
                fastingTrackerCard

                // 7. Quran Khatm goal
                quranGoalCard
            }
            .padding()
        }
        .navigationTitle("Ramadan Mubarak")
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
                .fullSheet()
        }
        .sheet(isPresented: $showZakat) {
            NavigationStack { ZakatCalculatorView() }
                .fullSheet()
        }
        .task {
            await loadRamadanData()
            healthSyncEnabled = healthKitService.syncEnabled
        }
        .onAppear {
            loadJuzCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            loadJuzCount() // Refresh when daily goals are toggled
        }
    }

    // MARK: - Date Subheader

    private var dateSubheader: some View {
        HStack {
            Text("Day \(currentDay) of \(totalDays)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.purple)

            Spacer()

            Text(hijriConverter.hijriDateString(from: Date(), style: .full))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
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

                // Live countdown (check Suhoor first — both are in the future before Suhoor ends)
                if let suhoor = suhoorTime, suhoor > Date() {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.orange)
                        Text(suhoor, style: .timer)
                            .font(SafaTypography.headlineLarge)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("until Suhoor ends")
                            .font(SafaTypography.labelMedium)
                            .foregroundStyle(.secondary)
                    }
                } else if let iftar = iftarTime, iftar > Date() {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(Color.accentColor)
                        Text(iftar, style: .timer)
                            .font(SafaTypography.headlineLarge)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("until Iftar")
                            .font(SafaTypography.labelMedium)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Label("Fasting complete for today", systemImage: "checkmark.circle.fill")
                        .font(SafaTypography.titleSmall)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    // MARK: - Prayer Progress (Full Width, Expanded)

    private var prayerProgressCard: some View {
        ContentCard {
            PrayerProgressIndicator(
                prayers: todayPrayers,
                loggedPrayers: loggedPrayers,
                nextPrayer: nextPrayer,
                style: .expanded,
                onLogPrayer: { prayerType in
                    Task { await togglePrayer(prayerType) }
                }
            )
        }
    }

    // MARK: - Quick Actions Grid

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SafaSpacing.md) {
            RamadanQuickAction(icon: "book.fill", title: "Quran", subtitle: "Continue reading", color: .green) {
                router.selectedTab = "quran"
            }
            RamadanQuickAction(icon: "moon.stars.fill", title: "Taraweeh", subtitle: "Track prayers", color: .purple) {
                showTaraweehTracker = true
            }
            RamadanQuickAction(icon: "dollarsign.circle.fill", title: "Zakat", subtitle: "Calculator", color: .teal) {
                showZakat = true
            }
            RamadanQuickAction(icon: "hands.sparkles.fill", title: "Duas", subtitle: "Iftar duas", color: .orange) {
                router.selectedTab = "duas"
            }
        }
    }

    // MARK: - Adhan + Qibla Buttons

    private var adhanQiblaButtons: some View {
        HStack(spacing: SafaSpacing.md) {
            // Qibla
            Button {
                showingQibla = true
            } label: {
                VStack(spacing: SafaSpacing.xs) {
                    Image(systemName: "location.north.fill")
                        .font(.title2)
                    Text("Qibla")
                        .font(SafaTypography.labelSmall)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SafaSpacing.sm)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
            }
            .buttonStyle(.plain)

            // Adhan
            AdhanPlayButton(style: .quickAction)
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

    private func togglePrayer(_ prayerType: PrayerType) async {
        if loggedPrayers.contains(prayerType) {
            await optimisticUnlogPrayer(prayerType)
        } else {
            await optimisticLogPrayer(prayerType)
        }
    }

    private func optimisticLogPrayer(_ prayerType: PrayerType) async {
        // Optimistic: update UI immediately
        loggedPrayers.insert(prayerType)
        WidgetDataService.shared.writeLoggedPrayers(loggedPrayers, for: Date())

        let displayName = prayerType.displayName
        ToastService.shared.show(Toast.undoAction(message: "\(displayName) logged") {
            Task { @MainActor [self] in
                loggedPrayers.remove(prayerType)
                WidgetDataService.shared.writeLoggedPrayers(loggedPrayers, for: Date())
                // Best-effort: delete from repo
                do {
                    let logs = try await dependencies.prayerRepository.getPrayerLogs(for: Date())
                    if let log = logs.first(where: { $0.prayerType == prayerType }) {
                        try await dependencies.prayerRepository.deletePrayerLog(log)
                    }
                } catch {}
            }
        })

        // Persist
        do {
            let prayer = todayPrayers.first { $0.type == prayerType }
            let isOnTime = prayer.map { abs(Date().timeIntervalSince($0.time)) < 30 * 60 } ?? false
            try await dependencies.prayerRepository.logPrayer(prayerType, for: Date(), at: Date(), isOnTime: isOnTime)

            await HasanatTracker.awardOnce(.prayerLogged, key: "prayer_\(prayerType.rawValue)", via: dependencies.userState)
            await dependencies.userState.incrementPrayersLogged()
            await dependencies.userState.recordActivity(type: .prayer)

            if PrayerType.obligatoryPrayers.allSatisfy({ loggedPrayers.contains($0) }) {
                await HasanatTracker.awardOnce(.prayerAllFive, key: "prayerAllFive", via: dependencies.userState)
            }
        } catch {
            // Revert on failure
            loggedPrayers.remove(prayerType)
            WidgetDataService.shared.writeLoggedPrayers(loggedPrayers, for: Date())
        }
    }

    private func optimisticUnlogPrayer(_ prayerType: PrayerType) async {
        // Optimistic: update UI immediately
        loggedPrayers.remove(prayerType)
        WidgetDataService.shared.writeLoggedPrayers(loggedPrayers, for: Date())

        let displayName = prayerType.displayName
        ToastService.shared.show(Toast.undoAction(message: "\(displayName) unlogged", type: .info) {
            Task { @MainActor [self] in
                loggedPrayers.insert(prayerType)
                WidgetDataService.shared.writeLoggedPrayers(loggedPrayers, for: Date())
                // Best-effort: re-log to repo
                do {
                    let prayer = todayPrayers.first { $0.type == prayerType }
                    let isOnTime = prayer.map { abs(Date().timeIntervalSince($0.time)) < 30 * 60 } ?? false
                    try await dependencies.prayerRepository.logPrayer(prayerType, for: Date(), at: Date(), isOnTime: isOnTime)
                } catch {}
            }
        })

        // Persist
        do {
            let logs = try await dependencies.prayerRepository.getPrayerLogs(for: Date())
            if let log = logs.first(where: { $0.prayerType == prayerType }) {
                try await dependencies.prayerRepository.deletePrayerLog(log)
            }
        } catch {
            // Revert on failure
            loggedPrayers.insert(prayerType)
            WidgetDataService.shared.writeLoggedPrayers(loggedPrayers, for: Date())
        }
    }

    // Adhan play/stop logic extracted to AdhanPlayButton shared component

    // MARK: - Load Data

    private func loadRamadanData() async {
        let (_, month, day) = hijriConverter.hijriComponents(from: Date())
        if month == 9 { currentDay = day }

        if let location = dependencies.locationService.coordinates {
            do {
                let prefs = PreferencesManager.loadPreferencesSync()
                let prayers = try await dependencies.prayerRepository.getPrayers(for: Date(), location: location, method: prefs.calculationMethod, madhab: prefs.madhab)
                todayPrayers = prayers
                nextPrayer = prayers.first { $0.time > Date() && $0.type.isObligatory }
                suhoorTime = prayers.first { $0.type == .fajr }?.time
                iftarTime = prayers.first { $0.type == .maghrib }?.time

                let logs = try await dependencies.prayerRepository.getPrayerLogs(for: Date())
                loggedPrayers = Set(logs.map { $0.prayerType })

                // Sync to widgets
                WidgetDataService.shared.writePrayerTimes(prayers)
                WidgetDataService.shared.writeLoggedPrayers(loggedPrayers, for: Date())
            } catch {}
        }

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

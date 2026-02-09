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
    @State private var healthSyncEnabled = false
    @State private var healthKitService = HealthKitService.shared

    private let hijriConverter = HijriDateConverter.shared
    private let totalDays = 30

    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                // Date subheader (scrolls away with large title)
                dateSubheader

                // 1. Iftar/Suhoor countdown platter
                iftarPlatter

                // 2. Prayer progress (full-width, expanded)
                prayerProgressCard

                // 3. Daily goals
                DailyGoalsCard(isRamadan: true, loggedPrayers: loggedPrayers)

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
        }
        .task {
            await loadRamadanData()
            healthSyncEnabled = healthKitService.syncEnabled
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

                // Live countdown
                if let iftar = iftarTime, iftar > Date() {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(Color.accentColor)
                        Text(iftar, style: .timer)
                            .font(SafaTypography.counterMedium)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("until Iftar")
                            .font(SafaTypography.labelMedium)
                            .foregroundStyle(.secondary)
                    }
                } else if let suhoor = suhoorTime, suhoor > Date() {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.orange)
                        Text(suhoor, style: .timer)
                            .font(SafaTypography.counterMedium)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("until Suhoor ends")
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
                router.navigate(to: .settings) // TODO: navigate to ZakatCalculator
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
            Button {
                playAdhan()
            } label: {
                VStack(spacing: SafaSpacing.xs) {
                    Image(systemName: dependencies.audioPlayerService.isPlaying ? "stop.fill" : "speaker.wave.2.fill")
                        .font(.title2)
                    Text(dependencies.audioPlayerService.isPlaying ? "Stop" : "Adhan")
                        .font(SafaTypography.labelSmall)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SafaSpacing.sm)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
            }
            .buttonStyle(.plain)
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
                        Text("5/30")
                            .font(SafaTypography.titleMedium)
                            .foregroundColor(.accentColor)
                        Text("Juz")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.2)).frame(height: 8)
                        Capsule().fill(Color.green).frame(width: geometry.size.width * 5 / 30, height: 8)
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
            if healthSyncEnabled, let suhoor = suhoorTime, let iftar = iftarTime {
                Task { try? await healthKitService.logFast(start: suhoor, end: iftar, type: .ramadan) }
            }
        }
    }

    private func togglePrayer(_ prayerType: PrayerType) async {
        if loggedPrayers.contains(prayerType) {
            do {
                let logs = try await dependencies.prayerRepository.getPrayerLogs(for: Date())
                if let log = logs.first(where: { $0.prayerType == prayerType }) {
                    try await dependencies.prayerRepository.deletePrayerLog(log)
                    loggedPrayers.remove(prayerType)
                }
            } catch {}
        } else {
            do {
                let prayer = todayPrayers.first { $0.type == prayerType }
                let isOnTime = prayer.map { abs(Date().timeIntervalSince($0.time)) < 30 * 60 } ?? false
                try await dependencies.prayerRepository.logPrayer(prayerType, for: Date(), at: Date(), isOnTime: isOnTime)
                loggedPrayers.insert(prayerType)
                await dependencies.userState.awardHasanat(.prayerLogged)
                await dependencies.userState.recordActivity(type: .prayer)
            } catch {}
        }
    }

    private func playAdhan() {
        if dependencies.audioPlayerService.isPlaying {
            dependencies.audioPlayerService.stop()
            return
        }
        Task {
            let prefs = await PreferencesManager.shared.getPreferences()
            let adhanSound = AdhanSound(rawValue: prefs.selectedAdhan) ?? .misharyAlafasy
            if adhanSound != .defaultSound {
                do {
                    try dependencies.audioPlayerService.playBundled(fileName: adhanSound.rawValue, fileExtension: "caf")
                } catch {
                    ToastService.shared.show(Toast(message: "Could not play adhan.", type: .warning))
                }
            }
        }
    }

    // MARK: - Load Data

    private func loadRamadanData() async {
        let (_, month, day) = hijriConverter.hijriComponents(from: Date())
        if month == 9 { currentDay = day }

        if let location = dependencies.locationService.coordinates {
            do {
                let savedMethod: CalculationMethod
                if let raw = UserDefaults.standard.string(forKey: AppConstants.StorageKeys.calculationMethod),
                   let m = CalculationMethod(rawValue: raw) {
                    savedMethod = m
                } else {
                    savedMethod = AppDefaults.calculationMethod
                }
                let prayers = try await dependencies.prayerRepository.getPrayers(for: Date(), location: location, method: savedMethod)
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

        fastingDays = [1, 2, 3, 4, 5] // Sample data — TODO: persist to UserDefaults
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

// MARK: - RamadanView.swift
// PURPOSE: Ramadan mode dashboard with fasting tracking
// DEPENDENCIES: SwiftUI, RamadanSubviews

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
    @State private var showTaraweehReminder = false
    @State private var showSettings = false
    @State private var healthSyncEnabled = false
    @State private var healthKitService = HealthKitService.shared

    private let hijriConverter = HijriDateConverter.shared
    private let totalDays = 30

    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                ramadanHeader
                iftarCountdown
                todayTimesCard
                prayerProgressSection
                fastingTrackerCard
                quickActionsSection
                dailyGoalsSection
                quranGoalCard
            }
            .padding()
        }
        .navigationTitle("Ramadan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
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
        .task {
            await loadRamadanData()
            healthSyncEnabled = healthKitService.syncEnabled
        }
    }

    // MARK: - Ramadan Header

    private var ramadanHeader: some View {
        VStack(spacing: SafaSpacing.md) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text("Ramadan Mubarak")
                .font(SafaTypography.headlineMedium)
                .foregroundColor(SafaColors.Fallback.text)

            Text("رمضان مبارك")
                .font(SafaTypography.arabicMedium)
                .foregroundColor(.accentColor)

            Text("Day \(currentDay) of \(totalDays)")
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            progressBar
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                Capsule()
                    .fill(LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geometry.size.width * CGFloat(currentDay) / CGFloat(totalDays), height: 8)
            }
        }
        .frame(height: 8)
        .padding(.horizontal, SafaSpacing.lg)
    }

    // MARK: - Iftar/Suhoor Hero Countdown

    private var iftarCountdown: some View {
        ContentCard {
            VStack(spacing: SafaSpacing.sm) {
                if let iftar = iftarTime, iftar > Date() {
                    Text("Time until Iftar")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)

                    let (hours, minutes, seconds) = iftar.countdown()
                    Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                        .font(SafaTypography.counterLarge)
                        .foregroundColor(SafaColors.Fallback.text)
                        .monospacedDigit()
                } else if let suhoor = suhoorTime, suhoor > Date() {
                    Text("Time until Suhoor ends")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)

                    let (hours, minutes, seconds) = suhoor.countdown()
                    Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                        .font(SafaTypography.counterLarge)
                        .foregroundColor(SafaColors.Fallback.text)
                        .monospacedDigit()
                } else {
                    Text("Fasting complete for today")
                        .font(SafaTypography.titleSmall)
                        .foregroundColor(.green)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SafaSpacing.md)
        }
    }

    // MARK: - Prayer Progress Section

    private var prayerProgressSection: some View {
        VStack(spacing: SafaSpacing.sm) {
            HStack {
                PrayerProgressIndicator(
                    prayers: todayPrayers,
                    loggedPrayers: loggedPrayers,
                    nextPrayer: nextPrayer,
                    style: .compact
                )

                Spacer()

                Button {
                    router.selectedTab = "prayer"
                } label: {
                    HStack(spacing: SafaSpacing.xxs) {
                        Text("All prayer times")
                            .font(SafaTypography.labelSmall)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.accentColor)
                }
            }

            // Play Adhan button
            HStack(spacing: SafaSpacing.md) {
                Button {
                    playAdhan()
                } label: {
                    HStack(spacing: SafaSpacing.xs) {
                        Image(systemName: dependencies.audioPlayerService.isPlaying ? "stop.fill" : "speaker.wave.2.fill")
                            .font(.body)
                        Text(dependencies.audioPlayerService.isPlaying ? "Stop" : "Play Adhan")
                            .font(SafaTypography.labelMedium)
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, SafaSpacing.md)
                    .padding(.vertical, SafaSpacing.xs)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
                }

                Spacer()
            }
        }
    }

    // MARK: - Today's Times Card

    private var todayTimesCard: some View {
        ContentCard {
            VStack(spacing: SafaSpacing.md) {
                HStack {
                    Text("Today's Times")
                        .font(SafaTypography.titleSmall)

                    Spacer()

                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                HStack(spacing: SafaSpacing.lg) {
                    suhoorTimeView
                    Divider().frame(height: 60)
                    iftarTimeView
                }

                // Countdown moved to hero section above
            }
        }
    }

    private var suhoorTimeView: some View {
        VStack(spacing: SafaSpacing.xs) {
            Image(systemName: "sun.horizon.fill")
                .font(.title2)
                .foregroundColor(.orange)

            Text("Suhoor Ends")
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            if let suhoor = suhoorTime {
                Text(suhoor.formatted(date: .omitted, time: .shortened))
                    .font(SafaTypography.titleMedium)
                    .foregroundColor(SafaColors.Fallback.text)
            } else {
                Text("--:--")
                    .font(SafaTypography.titleMedium)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var iftarTimeView: some View {
        VStack(spacing: SafaSpacing.xs) {
            Image(systemName: "moon.fill")
                .font(.title2)
                .foregroundColor(.purple)

            Text("Iftar")
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            if let iftar = iftarTime {
                Text(iftar.formatted(date: .omitted, time: .shortened))
                    .font(SafaTypography.titleMedium)
                    .foregroundColor(SafaColors.Fallback.text)
            } else {
                Text("--:--")
                    .font(SafaTypography.titleMedium)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
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
                    todayFastingToggle
                }
            }
        }
    }

    private var todayFastingToggle: some View {
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

    private func toggleFastingDay(_ day: Int) {
        if fastingDays.contains(day) {
            fastingDays.remove(day)
        } else {
            fastingDays.insert(day)
            if healthSyncEnabled, let suhoor = suhoorTime, let iftar = iftarTime {
                Task {
                    try? await healthKitService.logFast(start: suhoor, end: iftar, type: .ramadan)
                }
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SafaSpacing.md) {
            RamadanQuickAction(icon: "book.fill", title: "Quran", subtitle: "Continue reading", color: .green) {}
            RamadanQuickAction(icon: "hands.sparkles.fill", title: "Dua", subtitle: "Iftar duas", color: .orange) {}
            RamadanQuickAction(icon: "moon.stars.fill", title: "Taraweeh", subtitle: "Track prayers", color: .purple) {
                showTaraweehReminder = true
            }
            RamadanQuickAction(icon: "heart.fill", title: "Zakat", subtitle: "Calculator", color: .red) {}
        }
        .sheet(isPresented: $showTaraweehReminder) {
            TaraweehTrackerSheet()
        }
    }

    // MARK: - Daily Goals Section

    private var dailyGoalsSection: some View {
        TitledCard(title: "Daily Goals", subtitle: "Track your ibadah") {
            VStack(spacing: SafaSpacing.sm) {
                DailyGoalRow(icon: "checkmark.circle", title: "5 Daily Prayers", isCompleted: true)
                DailyGoalRow(icon: "moon.stars", title: "Taraweeh", isCompleted: false)
                DailyGoalRow(icon: "book", title: "Read 1 Juz", isCompleted: false)
                DailyGoalRow(icon: "text.quote", title: "Morning Adhkar", isCompleted: true)
                DailyGoalRow(icon: "text.quote", title: "Evening Adhkar", isCompleted: false)
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
                            .foregroundColor(SafaColors.Fallback.text)

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

                quranProgressBar

                Text("Read 1 Juz per day to complete on time")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
    }

    private var quranProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                Capsule()
                    .fill(Color.green)
                    .frame(width: geometry.size.width * 5 / 30, height: 8)
            }
        }
        .frame(height: 8)
    }

    // MARK: - Play Adhan

    private func playAdhan() {
        if dependencies.audioPlayerService.isPlaying {
            dependencies.audioPlayerService.stop()
            return
        }

        Task {
            let prefs = await PreferencesManager.shared.getPreferences()
            let fileName = prefs.selectedAdhan
            let adhanSound = AdhanSound(rawValue: fileName) ?? .misharyAlafasy

            if adhanSound != .defaultSound {
                do {
                    try dependencies.audioPlayerService.playBundled(
                        fileName: adhanSound.rawValue,
                        fileExtension: "caf"
                    )
                } catch {
                    ToastService.shared.show(Toast(
                        message: "Could not play adhan.",
                        type: .warning
                    ))
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
                if let raw = UserDefaults.standard.string(forKey: "calculationMethod"),
                   let m = CalculationMethod(rawValue: raw) {
                    savedMethod = m
                } else {
                    savedMethod = AppDefaults.calculationMethod
                }
                let prayers = try await dependencies.prayerRepository.getPrayers(
                    for: Date(),
                    location: location,
                    method: savedMethod
                )
                todayPrayers = prayers
                nextPrayer = prayers.first { $0.time > Date() && $0.type.isObligatory }
                suhoorTime = prayers.first { $0.type == .fajr }?.time
                iftarTime = prayers.first { $0.type == .maghrib }?.time

                // Load logged prayers
                let logs = try await dependencies.prayerRepository.getPrayerLogs(for: Date())
                loggedPrayers = Set(logs.map { $0.prayerType })
            } catch {
                // Handle error silently
            }
        }

        fastingDays = [1, 2, 3, 4, 5] // Sample data
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RamadanView()
            .environment(Dependencies())
    }
}

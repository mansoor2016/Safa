// MARK: - RamadanView.swift
// PURPOSE: Ramadan mode dashboard with fasting tracking
// DEPENDENCIES: SwiftUI

import SwiftUI

struct RamadanView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var todayFasted = false
    @State private var currentDay = 1
    @State private var suhoorTime: Date?
    @State private var iftarTime: Date?
    @State private var fastingDays: Set<Int> = []
    @State private var showTaraweehReminder = false

    private let hijriConverter = HijriDateConverter.shared
    private let totalDays = 30

    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                // Ramadan header
                ramadanHeader

                // Today's times card
                todayTimesCard

                // Fasting tracker
                fastingTrackerCard

                // Quick actions
                quickActionsSection

                // Daily goals
                dailyGoalsSection

                // Quranic goal
                quranGoalCard
            }
            .padding()
        }
        .navigationTitle("Ramadan")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadRamadanData()
        }
    }

    // MARK: - Ramadan Header

    private var ramadanHeader: some View {
        VStack(spacing: SafaSpacing.md) {
            // Moon and stars decoration
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

            // Progress bar
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
                    // Suhoor
                    VStack(spacing: SafaSpacing.xs) {
                        Image(systemName: "moon.fill")
                            .font(.title2)
                            .foregroundColor(.purple)

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

                    Divider()
                        .frame(height: 60)

                    // Iftar
                    VStack(spacing: SafaSpacing.xs) {
                        Image(systemName: "sun.horizon.fill")
                            .font(.title2)
                            .foregroundColor(.orange)

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

                // Countdown
                if let iftar = iftarTime, iftar > Date() {
                    let (hours, minutes, _) = iftar.countdown()
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.accentColor)

                        Text("\(hours)h \(minutes)m until Iftar")
                            .font(SafaTypography.bodyMedium)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.top, SafaSpacing.xs)
                }
            }
        }
    }

    // MARK: - Fasting Tracker Card

    private var fastingTrackerCard: some View {
        TitledCard(title: "Fasting Tracker", subtitle: "\(fastingDays.count) days completed") {
            VStack(spacing: SafaSpacing.md) {
                // Calendar grid for Ramadan days
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

                // Today's toggle
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

    private func toggleFastingDay(_ day: Int) {
        if fastingDays.contains(day) {
            fastingDays.remove(day)
        } else {
            fastingDays.insert(day)
        }
        // Save to repository
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SafaSpacing.md) {
            RamadanQuickAction(
                icon: "book.fill",
                title: "Quran",
                subtitle: "Continue reading",
                color: .green
            ) {
                // Navigate to Quran
            }

            RamadanQuickAction(
                icon: "hands.sparkles.fill",
                title: "Dua",
                subtitle: "Iftar duas",
                color: .orange
            ) {
                // Navigate to Iftar duas
            }

            RamadanQuickAction(
                icon: "moon.stars.fill",
                title: "Taraweeh",
                subtitle: "Track prayers",
                color: .purple
            ) {
                showTaraweehReminder = true
            }

            RamadanQuickAction(
                icon: "heart.fill",
                title: "Zakat",
                subtitle: "Calculator",
                color: .red
            ) {
                // Navigate to Zakat calculator
            }
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

                // Progress bar
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

                Text("Read 1 Juz per day to complete on time")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
    }

    // MARK: - Load Data

    private func loadRamadanData() async {
        // Calculate current Ramadan day
        let (_, month, day) = hijriConverter.hijriComponents(from: Date())
        if month == 9 { // Ramadan
            currentDay = day
        }

        // Load prayer times for Suhoor/Iftar
        if let location = dependencies.locationService.coordinates {
            do {
                let prayers = try await dependencies.prayerRepository.getPrayers(
                    for: Date(),
                    location: location,
                    method: .isna
                )
                suhoorTime = prayers.first { $0.type == .fajr }?.time
                iftarTime = prayers.first { $0.type == .maghrib }?.time
            } catch {
                // Handle error
            }
        }

        // Load fasting history
        // This would come from the repository
        fastingDays = [1, 2, 3, 4, 5] // Sample data
    }
}

// MARK: - Fasting Day Cell

private struct FastingDayCell: View {
    let day: Int
    let isFasted: Bool
    let isToday: Bool
    let isPast: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)

                if isFasted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("\(day)")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(textColor)
                }
            }
        }
        .disabled(!isPast && !isToday)
    }

    private var backgroundColor: Color {
        if isFasted {
            return .green
        } else if isToday {
            return Color.accentColor.opacity(0.2)
        } else if isPast {
            return Color.red.opacity(0.2)
        } else {
            return Color.gray.opacity(0.1)
        }
    }

    private var textColor: Color {
        if isToday {
            return .accentColor
        } else if isPast && !isFasted {
            return .red
        } else {
            return SafaColors.Fallback.secondaryText
        }
    }
}

// MARK: - Ramadan Quick Action

private struct RamadanQuickAction: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(title)
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text(subtitle)
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SafaSpacing.md)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        }
    }
}

// MARK: - Daily Goal Row

private struct DailyGoalRow: View {
    let icon: String
    let title: String
    let isCompleted: Bool

    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : icon)
                .foregroundColor(isCompleted ? .green : SafaColors.Fallback.tertiaryText)
                .frame(width: 24)

            Text(title)
                .font(SafaTypography.bodyMedium)
                .foregroundColor(isCompleted ? SafaColors.Fallback.secondaryText : SafaColors.Fallback.text)
                .strikethrough(isCompleted)

            Spacer()
        }
    }
}

// MARK: - Taraweeh Tracker Sheet

private struct TaraweehTrackerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rakahsPrayed = 8

    var body: some View {
        NavigationStack {
            VStack(spacing: SafaSpacing.xl) {
                Spacer()

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)

                Text("Taraweeh Tonight")
                    .font(SafaTypography.headlineMedium)

                VStack(spacing: SafaSpacing.sm) {
                    Text("Rak'ahs Prayed")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)

                    HStack(spacing: SafaSpacing.lg) {
                        Button {
                            if rakahsPrayed > 0 {
                                rakahsPrayed -= 2
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.accentColor)
                        }

                        Text("\(rakahsPrayed)")
                            .font(SafaTypography.counterLarge)
                            .frame(width: 80)

                        Button {
                            if rakahsPrayed < 20 {
                                rakahsPrayed += 2
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.accentColor)
                        }
                    }

                    Text("Common: 8 or 20 rak'ahs")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }

                Spacer()

                Button {
                    // Save and dismiss
                    dismiss()
                } label: {
                    Text("Save")
                        .font(SafaTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
                }
            }
            .padding()
            .navigationTitle("Taraweeh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RamadanView()
            .environment(Dependencies())
    }
}

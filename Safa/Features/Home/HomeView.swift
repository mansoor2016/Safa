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
    @State private var hijriDate = ""
    @State private var dailyVerse: Ayah?
    @State private var isRamadan = false

    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                // Header with date
                dateHeader

                // Next prayer card
                if let prayer = nextPrayer {
                    NextPrayerHomeCard(prayer: prayer) {
                        router.navigate(to: .prayer)
                    }
                }

                // Prayer timeline
                prayerTimeline

                // Quick actions
                quickActions

                // Daily verse
                if let verse = dailyVerse {
                    dailyVerseCard(verse)
                }

                // Progress summary
                progressCard

                // Contextual reminders
                contextualReminders
            }
            .padding()
        }
        .navigationTitle("Safa")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.navigate(to: .settings)
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .task {
            await loadHomeData()
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        VStack(spacing: SafaSpacing.xxs) {
            Text(Date().formatted(date: .complete, time: .omitted))
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            Text(hijriDate)
                .font(SafaTypography.titleMedium)
                .foregroundColor(SafaColors.Fallback.text)

            if isRamadan {
                Label("Ramadan Mubarak", systemImage: "moon.stars.fill")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(.accentColor)
                    .padding(.top, SafaSpacing.xxs)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Prayer Timeline

    private var prayerTimeline: some View {
        ContentCard {
            VStack(spacing: SafaSpacing.sm) {
                HStack {
                    Text("Today's Prayers")
                        .font(SafaTypography.titleSmall)

                    Spacer()

                    Button("See All") {
                        router.navigate(to: .prayer)
                    }
                    .font(SafaTypography.labelSmall)
                }

                HStack(spacing: SafaSpacing.xs) {
                    ForEach(todayPrayers.filter { $0.type.isObligatory }) { prayer in
                        PrayerTimelineItem(
                            prayer: prayer,
                            isNext: prayer.id == nextPrayer?.id
                        )
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SafaSpacing.md) {
            QuickActionCard(
                icon: "book.fill",
                title: "Quran",
                subtitle: "Continue reading",
                color: .green
            ) {
                router.navigate(to: .quran)
            }

            QuickActionCard(
                icon: "location.north.fill",
                title: "Qibla",
                subtitle: "Find direction",
                color: .blue
            ) {
                router.navigate(to: .qibla)
            }

            QuickActionCard(
                icon: "graduationcap.fill",
                title: "Learn",
                subtitle: "Arabic & Tajweed",
                color: .purple
            ) {
                router.navigate(to: .learn)
            }

            QuickActionCard(
                icon: "sparkles",
                title: "Ask Safa",
                subtitle: "AI companion",
                color: .orange
            ) {
                router.navigate(to: .chat)
            }
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
            // Navigate to progress/stats
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
                    title: "Morning Adhkar",
                    message: "Start your day with morning remembrance."
                ) {
                    router.navigate(to: .dhikr)
                }
            }

            if hour >= 17 && hour < 20 {
                ReminderCard(
                    icon: "sunset",
                    title: "Evening Adhkar",
                    message: "Complete your evening remembrance."
                ) {
                    router.navigate(to: .dhikr)
                }
            }
        }
    }

    // MARK: - Load Data

    private func loadHomeData() async {
        // Load Hijri date
        hijriDate = HijriDateConverter.shared.hijriDateString(from: Date(), style: .full)
        isRamadan = HijriDateConverter.shared.isRamadan()

        // Load prayer times
        do {
            if let location = dependencies.locationService.coordinates {
                todayPrayers = try await dependencies.prayerRepository.getPrayers(
                    for: Date(),
                    location: location,
                    method: .isna
                )
                nextPrayer = todayPrayers.first { $0.time > Date() && $0.type.isObligatory }
            }
        } catch {
            // Handle error silently on home screen
        }

        // Load daily verse
        dailyVerse = Ayah.alFatiha.randomElement()
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

                Text(countdown)
                    .font(SafaTypography.counterSmall)
                    .foregroundColor(SafaColors.Fallback.text)
                    .monospacedDigit()
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

// MARK: - Prayer Timeline Item

private struct PrayerTimelineItem: View {
    let prayer: PrayerTime
    let isNext: Bool

    var body: some View {
        VStack(spacing: SafaSpacing.xxs) {
            Circle()
                .fill(isNext ? Color.accentColor : (prayer.time < Date() ? Color.green : Color.gray.opacity(0.3)))
                .frame(width: 12, height: 12)

            Text(prayer.type.displayName.prefix(3))
                .font(SafaTypography.labelSmall)
                .foregroundColor(isNext ? .accentColor : SafaColors.Fallback.secondaryText)

            Text(prayer.time.formatted(date: .omitted, time: .shortened))
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.tertiaryText)
        }
        .frame(maxWidth: .infinity)
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
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
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

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
            .environment(Dependencies())
            .environment(AppRouter())
    }
}

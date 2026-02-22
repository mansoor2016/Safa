// MARK: - RamadanBanner.swift
// PURPOSE: Dismissible Ramadan banner for home screen with countdown and quick actions
// DEPENDENCIES: SwiftUI, Combine

import SwiftUI
import Combine

struct RamadanBanner: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router

    let suhoorTime: Date?
    let iftarTime: Date?
    let onDismiss: () -> Void

    @State private var countdown = ""
    @State private var isUntilSuhoor = false
    @State private var isNextSuhoor = false
    @State private var quranProgress: QuranProgress?
    @State private var showingIftarDuaPrompt = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var ramadanService: RamadanService {
        dependencies.ramadanService
    }

    var body: some View {
        VStack(spacing: SafaSpacing.sm) {
            // Header with dismiss
            header

            Divider()
                .background(Color.white.opacity(0.2))

            // Countdown (centered) then day progress (left-aligned to match Quran line)
            countdownView
            dayProgress

            // Quran khatm progress
            if let progress = quranProgress {
                quranKhatmProgress(progress: progress)
            }

            // Quick actions
            quickActions
        }
        .padding(SafaSpacing.md)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.9), Color.indigo.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
        .onReceive(timer) { _ in
            updateCountdown()
        }
        .onAppear {
            updateCountdown()
        }
        .task {
            await loadQuranProgress()
        }
        .sheet(isPresented: $showingIftarDuaPrompt) {
            IftarDuaPromptSheet()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: SafaSpacing.xs) {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.yellow)

                Text("Ramadan Mubarak")
                    .font(SafaTypography.titleSmall)
                    .foregroundColor(.white)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(SafaSpacing.xxs)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Day Progress

    private var dayProgress: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
            Text("Day \(ramadanService.currentRamadanDay) of \(ramadanService.totalRamadanDays)")
                .font(SafaTypography.labelMedium)
                .foregroundColor(.white)

            // Progress bar (full width)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)

                    Capsule()
                        .fill(Color.white)
                        .frame(
                            width: geometry.size.width * CGFloat(ramadanService.currentRamadanDay) / CGFloat(ramadanService.totalRamadanDays),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Quran Khatm Progress

    private func quranKhatmProgress(progress: QuranProgress) -> some View {
        VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                Text("Ramadan Quran")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text("\(Int(progress.progressPercentage))%")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(.white)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(progress.progressPercentage) / 100,
                            height: 4
                        )
                }
            }
            .frame(height: 4)

            HStack {
                Text("Last read: \(progress.lastSurah):\(progress.lastAyah)")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                if progress.khatmCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("\(progress.khatmCount) khatm")
                    }
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, SafaSpacing.xxs)
    }

    // MARK: - Countdown

    private var countdownView: some View {
        VStack(spacing: SafaSpacing.xxs) {
            Text(countdownLabel)
                .font(SafaTypography.labelSmall)
                .foregroundColor(.white.opacity(isNextSuhoor ? 0.5 : 0.7))

            Text(countdown)
                .font(isNextSuhoor ? SafaTypography.counterSmall : SafaTypography.counterSmall)
                .foregroundColor(.white.opacity(isNextSuhoor ? 0.6 : 1.0))
                .monospacedDigit()

            if !isNextSuhoor, let time = isUntilSuhoor ? suhoorTime : iftarTime {
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var countdownLabel: String {
        if isNextSuhoor {
            return "Suhoor tomorrow in"
        }
        return isUntilSuhoor ? "Suhoor ends in" : "Iftar in"
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: SafaSpacing.sm) {
            bannerQuickAction(icon: "hands.sparkles", title: "Duas") {
                router.selectedTab = "duas"
            }

            bannerQuickAction(icon: "book.fill", title: "Quran") {
                router.selectedTab = "quran"
            }

            AdhanPlayButton(style: .banner)
        }
    }

    private func bannerQuickAction(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: SafaSpacing.xxs) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.white)

                Text(title)
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SafaSpacing.xs)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.sm))
        }
    }

    // MARK: - Methods

    private func updateCountdown() {
        let now = Date()
        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoorTime, iftarTime: iftarTime
        )

        switch target {
        case .suhoor(let time):
            isUntilSuhoor = true
            isNextSuhoor = false
            let (hours, minutes, seconds) = time.countdown()
            countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        case .iftar(let time):
            isUntilSuhoor = false
            isNextSuhoor = false
            let (hours, minutes, seconds) = time.countdown()
            countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        case .nextSuhoor(let time):
            isUntilSuhoor = true
            isNextSuhoor = true
            let (hours, minutes, seconds) = time.countdown()
            countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        case .complete:
            isNextSuhoor = false
            countdown = "--:--:--"
        }
    }

    // Adhan play/stop extracted to AdhanPlayButton shared component

    private func loadQuranProgress() async {
        do {
            quranProgress = try await dependencies.quranRepository.getReadingProgress()
        } catch {
            // Ignore errors - just don't show progress
        }
    }
}

// MARK: - Iftar Dua Prompt Sheet

private struct IftarDuaPromptSheet: View {
    @Environment(\.dismiss) private var dismiss

    // Dua to say after adhan
    private let afterAdhanDua = (
        arabic: "اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلاَةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ",
        transliteration: "Allahumma Rabba hadhihi'd-da'wat it-taammah, was-salat il-qaa'imah, aati Muhammadan al-waseelata wal-fadeelah, wab'ath-hu maqaman mahmoodan alladhi wa'adtah",
        translation: "O Allah, Lord of this perfect call and established prayer, grant Muhammad the intercession and favor, and raise him to the praised station You have promised him."
    )

    // Dua for breaking fast
    private let breakingFastDua = (
        arabic: "ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ",
        transliteration: "Dhahaba ath-thama'u wab-tallat al-'urooqu wa thabat al-ajru in sha Allah",
        translation: "The thirst has gone, the veins are moistened and the reward is confirmed, if Allah wills."
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SafaSpacing.lg) {
                    // After Adhan Dua
                    duaCard(
                        title: "Dua After Adhan",
                        arabic: afterAdhanDua.arabic,
                        transliteration: afterAdhanDua.transliteration,
                        translation: afterAdhanDua.translation,
                        reference: "Bukhari"
                    )

                    // Breaking Fast Dua
                    duaCard(
                        title: "Dua for Breaking Fast",
                        arabic: breakingFastDua.arabic,
                        transliteration: breakingFastDua.transliteration,
                        translation: breakingFastDua.translation,
                        reference: "Abu Dawud"
                    )
                }
                .padding()
            }
            .navigationTitle("Iftar Duas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .compactSheet()
    }

    private func duaCard(title: String, arabic: String, transliteration: String, translation: String, reference: String) -> some View {
        VStack(alignment: .leading, spacing: SafaSpacing.md) {
            Text(title)
                .font(SafaTypography.titleSmall)
                .foregroundColor(SafaColors.Fallback.text)

            Text(arabic)
                .font(SafaTypography.arabicMedium)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(SafaColors.Fallback.text)
                .environment(\.layoutDirection, .rightToLeft)
                .accessibilityArabic()

            Divider()

            VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                Text("Transliteration")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)

                Text(transliteration)
                    .font(SafaTypography.bodyMedium)
                    .italic()
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                Text("Translation")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)

                Text(translation)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.text)
            }

            Text("Source: \(reference)")
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.tertiaryText)
        }
        .padding(SafaSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }
}

// MARK: - Pre-Ramadan Banner

struct PreRamadanBanner: View {
    let daysUntil: Int
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: SafaSpacing.md) {
            Image(systemName: "moon.stars")
                .font(.title2)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                Text("Ramadan is coming!")
                    .font(SafaTypography.titleSmall)
                    .foregroundColor(SafaColors.Fallback.text)

                Text("\(daysUntil) days until Ramadan begins")
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
        .padding(SafaSpacing.md)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }
}

// MARK: - Last 10 Nights Banner

struct LastTenNightsBanner: View {
    @Environment(AppRouter.self) private var router
    let currentNight: Int
    let onDismiss: () -> Void

    private let oddNights = [21, 23, 25, 27, 29]

    var body: some View {
        VStack(spacing: SafaSpacing.sm) {
            HStack {
                HStack(spacing: SafaSpacing.xs) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)

                    Text("Last 10 Nights")
                        .font(SafaTypography.titleSmall)
                        .foregroundColor(.white)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // Night indicators
            HStack(spacing: SafaSpacing.xs) {
                ForEach(21...30, id: \.self) { night in
                    nightIndicator(night: night)
                }
            }

            if oddNights.contains(currentNight) {
                Text("Tonight is the \(ordinal(currentNight)) - an odd night")
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(.white.opacity(0.9))
            }

            // Quick action
            Button {
                router.navigate(to: .dhikr)
            } label: {
                Text("Laylatul Qadr Duas")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, SafaSpacing.md)
                    .padding(.vertical, SafaSpacing.xs)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(SafaSpacing.md)
        .background(
            LinearGradient(
                colors: [Color.indigo.opacity(0.95), Color.purple.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
    }

    private func nightIndicator(night: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(night)")
                .font(SafaTypography.labelSmall)
                .foregroundColor(night == currentNight ? .yellow : .white.opacity(0.6))

            Circle()
                .fill(night == currentNight ? Color.yellow : (night < currentNight ? Color.green : Color.white.opacity(0.3)))
                .frame(width: 8, height: 8)

            if oddNights.contains(night) {
                Image(systemName: "star.fill")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(.yellow.opacity(0.8))
            }
        }
    }

    private func ordinal(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Preview

#Preview("Ramadan Banner") {
    VStack {
        RamadanBanner(
            suhoorTime: Date().addingTimeInterval(3600),
            iftarTime: Date().addingTimeInterval(7200),
            onDismiss: {}
        )
        .environment(Dependencies())
        .environment(AppRouter())

        PreRamadanBanner(daysUntil: 7, onDismiss: {})

        EidBanner(eidType: .fitr, dayNumber: 1, eidPrayerTime: Date().addingTimeInterval(3600), onShare: {}, onDismiss: {})

        LastTenNightsBanner(currentNight: 25, onDismiss: {})
            .environment(AppRouter())
    }
    .padding()
}

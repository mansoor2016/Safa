// MARK: - SafaApp.swift
// PURPOSE: Main entry point for the Safa iOS application
// DEPENDENCIES: SwiftUI, Dependencies, AppRouter

import SwiftUI
import CoreSpotlight

@main
struct SafaApp: App {
    // MARK: - State
    @State private var dependencies = Dependencies()
    @State private var router = AppRouter()
    @State private var hasCompletedOnboarding = false

    // Spotlight service
    private let spotlightService = SpotlightIndexService.shared

    // Check if running UI tests (skip onboarding)
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
                }
            }
            .tint(.accentColor)
            .environment(dependencies)
            .environment(router)
            .onOpenURL { url in
                router.handleDeepLink(url)
            }
            .task {
                // Skip onboarding in UI tests
                if isUITesting {
                    hasCompletedOnboarding = true
                    return
                }

                // Check if onboarding is complete
                let prefs = await dependencies.userRepository.getPreferences()
                hasCompletedOnboarding = prefs.hasCompletedOnboarding

                // Index Spotlight content on first launch (after onboarding)
                if prefs.hasCompletedOnboarding && spotlightService.lastIndexDate == nil {
                    await spotlightService.indexAllContent()
                }
            }
            .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                // Handle Spotlight search result tap
                router.handleSpotlightResult(userActivity)
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    enum Tab: String, CaseIterable {
        case home
        case quran
        case prayer
        case learn
        case more

        var title: String {
            switch self {
            case .home: return "Home"
            case .quran: return "Quran"
            case .prayer: return "Prayer"
            case .learn: return "Learn"
            case .more: return "More"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house"
            case .quran: return "book"
            case .prayer: return "clock"
            case .learn: return "graduationcap"
            case .more: return "ellipsis.circle"
            }
        }

        var selectedIcon: String {
            switch self {
            case .home: return "house.fill"
            case .quran: return "book.fill"
            case .prayer: return "clock.fill"
            case .learn: return "graduationcap.fill"
            case .more: return "ellipsis.circle.fill"
            }
        }
    }

    private var selectedTab: Binding<Tab> {
        Binding(
            get: { Tab(rawValue: router.selectedTab) ?? .home },
            set: { router.selectedTab = $0.rawValue }
        )
    }

    var body: some View {
        TabView(selection: selectedTab) {
            // Home Tab
            NavigationStack(path: Binding(
                get: { router.path },
                set: { router.path = $0 }
            )) {
                HomeView()
                    .navigationDestination(for: AppRouter.Destination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label(Tab.home.title, systemImage: router.selectedTab == Tab.home.rawValue ? Tab.home.selectedIcon : Tab.home.icon)
            }
            .tag(Tab.home)

            // Quran Tab
            NavigationStack {
                QuranView()
            }
            .tabItem {
                Label(Tab.quran.title, systemImage: router.selectedTab == Tab.quran.rawValue ? Tab.quran.selectedIcon : Tab.quran.icon)
            }
            .tag(Tab.quran)

            // Prayer Tab
            NavigationStack {
                PrayerView()
            }
            .tabItem {
                Label(Tab.prayer.title, systemImage: router.selectedTab == Tab.prayer.rawValue ? Tab.prayer.selectedIcon : Tab.prayer.icon)
            }
            .tag(Tab.prayer)

            // Learn Tab
            NavigationStack {
                LearnView()
            }
            .tabItem {
                Label(Tab.learn.title, systemImage: router.selectedTab == Tab.learn.rawValue ? Tab.learn.selectedIcon : Tab.learn.icon)
            }
            .tag(Tab.learn)

            // More Tab
            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label(Tab.more.title, systemImage: router.selectedTab == Tab.more.rawValue ? Tab.more.selectedIcon : Tab.more.icon)
            }
            .tag(Tab.more)
        }
        .tint(.accentColor)
    }

    // MARK: - Destination View Builder

    @ViewBuilder
    private func destinationView(for destination: AppRouter.Destination) -> some View {
        switch destination {
        case .quran:
            QuranView()
        case .surah(let number):
            SurahDetailView(surahNumber: number)
        case .ayah(let surah, let ayah):
            AyahReaderView(surahNumber: surah, startAyah: ayah)
        case .prayer:
            PrayerView()
        case .qibla:
            QiblaCompassView()
        case .prayerLog:
            PrayerLogView()
        case .learn:
            LearnView()
        case .lesson(let trackId, let lessonId):
            LessonDetailView(trackId: trackId, lessonId: lessonId)
        case .chat:
            ChatView()
        case .hadith(_, _):
            HadithView()
        case .dhikr:
            DhikrView()
        case .calendar:
            CalendarView()
        case .ramadan:
            RamadanView()
        case .windDown:
            WindDownView()
        case .settings:
            SettingsView()
        case .family:
            FamilyView()
        }
    }
}

// MARK: - More View

struct MoreView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router

    private let hijriConverter = HijriDateConverter.shared

    var body: some View {
        List {
            // Ramadan section (shown during Ramadan)
            if hijriConverter.isRamadan() || FeatureFlags.shared.isEnabled(.ramadanMode) {
                Section {
                    NavigationLink {
                        RamadanView()
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Ramadan Mode")
                                Text("Track your fasting")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "moon.stars.fill")
                                .foregroundColor(.purple)
                        }
                    }
                }
            }

            // Main features
            Section("Features") {
                NavigationLink {
                    ChatView()
                } label: {
                    Label("Ask Safa", systemImage: "sparkles")
                }

                NavigationLink {
                    DhikrView()
                } label: {
                    Label("Dhikr & Adhkar", systemImage: "hands.sparkles")
                }

                NavigationLink {
                    HadithView()
                } label: {
                    Label("Hadith", systemImage: "text.book.closed")
                }

                NavigationLink {
                    CalendarView()
                } label: {
                    Label("Islamic Calendar", systemImage: "calendar")
                }

                NavigationLink {
                    QiblaCompassView()
                } label: {
                    Label("Qibla Compass", systemImage: "location.north.fill")
                }
            }

            // Tools
            Section("Tools") {
                NavigationLink {
                    ZakatCalculatorView()
                } label: {
                    Label("Zakat Calculator", systemImage: "dollarsign.circle")
                }

                NavigationLink {
                    NamesOfAllahView()
                } label: {
                    Label("99 Names of Allah", systemImage: "list.star")
                }

                NavigationLink {
                    DuaCategoriesView()
                } label: {
                    Label("Duas", systemImage: "heart.text.square")
                }
            }

            // Progress
            Section("Progress") {
                NavigationLink {
                    ProgressDashboardView()
                } label: {
                    Label("Your Journey", systemImage: "chart.line.uptrend.xyaxis")
                }

                NavigationLink {
                    AchievementsView()
                } label: {
                    Label("Achievements", systemImage: "trophy")
                }
            }

            // Settings
            Section {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Placeholder Views

struct SurahDetailView: View {
    let surahNumber: Int

    var body: some View {
        Text("Surah \(surahNumber)")
            .navigationTitle("Surah")
    }
}

struct LessonDetailView: View {
    let trackId: String
    let lessonId: String

    var body: some View {
        Text("Lesson: \(trackId)/\(lessonId)")
            .navigationTitle("Lesson")
    }
}

struct FamilyView: View {
    var body: some View {
        VStack(spacing: SafaSpacing.lg) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Family Circle")
                .font(SafaTypography.headlineMedium)

            Text("Share your spiritual journey with family members.")
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)
                .multilineTextAlignment(.center)

            Button("Invite Family Member") {
                // Invite action
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Family")
    }
}

// Note: ZakatCalculatorView, NamesOfAllahView, DuaCategoriesView,
// ProgressDashboardView, and AchievementsView are implemented in their
// respective feature folders under Safa/Features/

// MARK: - Preview

#Preview {
    MainTabView()
        .environment(Dependencies())
        .environment(AppRouter())
}

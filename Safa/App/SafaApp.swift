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
    @State private var themeManager = ThemeManager()
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
            .safaTheme(themeManager)
            .environment(dependencies)
            .environment(router)
            .environment(themeManager)
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

                // Re-schedule prayer notifications daily on app launch
                if prefs.hasCompletedOnboarding {
                    await NotificationScheduler.shared.scheduleIfNeeded()
                }

                // Pre-warm compressed databases in background (non-blocking)
                await SQLiteService.shared.preWarmDatabases()
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
        case duas
        case more

        var title: String {
            switch self {
            case .home: return "Home"
            case .quran: return "Quran"
            case .prayer: return "Prayer"
            case .duas: return "Duas"
            case .more: return "More"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house"
            case .quran: return "book"
            case .prayer: return "clock"
            case .duas: return "heart.text.square"
            case .more: return "ellipsis.circle"
            }
        }

        var selectedIcon: String {
            switch self {
            case .home: return "house.fill"
            case .quran: return "book.fill"
            case .prayer: return "clock.fill"
            case .duas: return "heart.text.square.fill"
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

            // Prayer Tab (swaps to Ramadan view during Ramadan)
            NavigationStack {
                if HijriDateConverter.shared.isRamadan() || FeatureFlags.shared.isEnabled(.ramadanMode) {
                    RamadanView()
                } else {
                    PrayerView()
                }
            }
            .tabItem {
                Label(Tab.prayer.title, systemImage: router.selectedTab == Tab.prayer.rawValue ? Tab.prayer.selectedIcon : Tab.prayer.icon)
            }
            .tag(Tab.prayer)

            // Duas Tab
            NavigationStack {
                DuaCategoriesView()
            }
            .tabItem {
                Label(Tab.duas.title, systemImage: router.selectedTab == Tab.duas.rawValue ? Tab.duas.selectedIcon : Tab.duas.icon)
            }
            .tag(Tab.duas)

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

// MoreView extracted to Features/More/MoreView.swift
// Placeholder views (SurahDetailView, LessonDetailView, FamilyView) extracted to their feature folders

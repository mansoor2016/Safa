// MARK: - SafaApp.swift
// PURPOSE: Main entry point for the Safa iOS application
// DEPENDENCIES: SwiftUI, Dependencies, AppRouter

import SwiftUI
import UIKit
import UserNotifications
import CoreSpotlight
import AppIntents
import SafaShared

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    static var pendingShortcutType: String?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate so foreground notifications display with banner + sound
        UNUserNotificationCenter.current().delegate = NotificationResponseHandler.shared

        // Register background refresh task for prayer notification rescheduling
        NotificationScheduler.shared.registerBackgroundTask()

        // Subscribe to MetricKit performance and diagnostic payloads
        MetricKitSubscriber.shared.register()

        return true
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        Self.pendingShortcutType = shortcutItem.type
        completionHandler(true)
    }
}

@main
struct SafaApp: App {
    // MARK: - State
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var dependencies = Dependencies()
    @State private var router = AppRouter.shared
    @State private var themeManager = ThemeManager()
    @State private var launchState: LaunchState = .loading
    @State private var qadaReminderPayload: RamadanQadaReminderService.ReminderPayload?
    @Environment(\.scenePhase) private var scenePhase

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
                switch launchState {
                case .loading:
                    Color(UIColor.systemBackground)
                        .ignoresSafeArea()
                case .onboarding:
                    OnboardingView(isOnboardingComplete: Binding(
                        get: { launchState == .ready },
                        set: { if $0 { launchState = .ready } }
                    ))
                case .ready:
                    MainTabView()
                }
            }
            .safaTheme(themeManager)
            .toastContainer()
            .environment(dependencies)
            .environment(router)
            .environment(themeManager)
            .onOpenURL { url in
                router.handleDeepLink(url)
            }
            .task {
                // Determine launch state
                let prefs = await dependencies.userRepository.getPreferences()
                launchState = LaunchStateResolver.resolve(
                    isUITesting: isUITesting,
                    hasCompletedOnboarding: prefs.hasCompletedOnboarding
                )
                guard launchState == .ready else { return }

                // Precompute today's prayer times for instant home screen rendering
                if prefs.hasCompletedOnboarding, let location = dependencies.locationService.coordinates {
                    let userPrefs = PreferencesManager.loadPreferencesSync()
                    dependencies.cachedTodayPrayers = try? await dependencies.prayerRepository.getPrayers(
                        for: Date(),
                        location: location,
                        method: userPrefs.calculationMethod,
                        madhab: userPrefs.madhab
                    )
                }

                // Index Spotlight content on first launch or after version bump
                if prefs.hasCompletedOnboarding && spotlightService.needsReindex {
                    await spotlightService.indexAllContent()
                }

                // Ensure Siri shortcuts stay registered
                if prefs.hasCompletedOnboarding {
                    SafaShortcuts.updateAppShortcutParameters()
                }

                // Re-schedule prayer notifications daily on app launch
                if prefs.hasCompletedOnboarding {
                    await NotificationScheduler.shared.scheduleIfNeeded()
                    NotificationScheduler.shared.scheduleBackgroundRefresh()
                }

                // Record daily activity (awards .dailyOpen hasanat + daily streak)
                if prefs.hasCompletedOnboarding {
                    await dependencies.userState.recordActivity(type: .daily)
                }

                // Restore or start Live Activity (handles stale cleanup internally)
                await PrayerLiveActivityManager.shared.ensureActivityIfNeeded()

                // Prune old hasanat tracker entries (prevents UserDefaults bloat)
                HasanatTracker.pruneOldEntries()

                // Record first launch date for review prompt timing
                AppReviewService.recordFirstLaunchIfNeeded()

                // Pre-warm compressed databases in background (non-blocking)
                await SQLiteService.shared.preWarmDatabases()

                // Check for one-off Qada (missed fast) reminder
                if let payload = RamadanQadaReminderService.shouldShowReminder(
                    hasCompletedOnboarding: prefs.hasCompletedOnboarding
                ) {
                    qadaReminderPayload = payload
                }
            }
            .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                // Handle Spotlight search result tap
                router.handleSpotlightResult(userActivity)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    if let shortcutType = AppDelegate.pendingShortcutType {
                        AppDelegate.pendingShortcutType = nil
                        handleShortcut(shortcutType)
                    }
                    Task { await checkLocationChange() }
                    // Recover Live Activity on every foreground resume
                    Task { await PrayerLiveActivityManager.shared.ensureActivityIfNeeded() }
                }
            }
            .alert(
                "Gentle reminder",
                isPresented: Binding(
                    get: { qadaReminderPayload != nil },
                    set: { if !$0 { dismissQadaReminder() } }
                )
            ) {
                Button("Got it") { dismissQadaReminder() }
            } message: {
                if let payload = qadaReminderPayload {
                    Text("You logged \(payload.trackedDays) of 30 fasting days this Ramadan. If you have missed fasts, you can make them up when able.")
                }
            }
        }
    }

    // MARK: - Home Screen Quick Actions

    private func handleShortcut(_ type: String) {
        switch type {
        case "com.safa.prayer":
            router.selectedTab = "prayer"
        case "com.safa.qibla":
            router.selectedTab = "home"
            router.popToRoot()
            router.navigate(to: .qibla)
        default:
            break
        }
    }

    // MARK: - Location Change Detection

    private func checkLocationChange() async {
        let prefs = PreferencesManager.loadPreferencesSync()
        guard prefs.hasCompletedOnboarding else { return }

        // Determine if we're near a prayer time (within 30 min) for adaptive throttle
        let nearPrayer = isNearPrayerTime(prefs: prefs)

        guard let context = await dependencies.locationService
            .checkForSignificantLocationChange(nearPrayerTime: nearPrayer) else { return }

        // Location was already saved internally by the service.
        // Only update UI / recalculate if the user has auto-update enabled.
        guard prefs.autoUpdateLocationForPrayers else { return }

        // Recalculate prayer times for the new location
        guard let prayers = try? await dependencies.prayerRepository.getPrayers(
            for: Date(),
            location: context.coordinates,
            method: prefs.calculationMethod,
            madhab: prefs.madhab
        ) else { return }

        // Update cached prayers for instant home screen rendering
        dependencies.cachedTodayPrayers = prayers

        // Update widgets
        WidgetDataService.shared.writePrayerTimes(prayers)

        // Update Live Activity with next obligatory prayer + schedule boundary updates
        let hijri = HijriDateConverter.shared.hijriDateString(from: Date(), style: .full)
        if let next = prayers.first(where: { $0.time > Date() && $0.type.isObligatory }) {
            await PrayerLiveActivityManager.shared.updateActivity(
                prayerName: next.type.displayName,
                prayerTime: next.time,
                hijriDate: hijri,
                locationName: context.regionName
            )
        }
        let prayerInfos = prayers
            .filter { $0.type.isObligatory }
            .map { PrayerInfo(name: $0.type.displayName, time: $0.time) }
        PrayerLiveActivityManager.shared.scheduleBoundaryUpdates(
            prayers: prayerInfos,
            hijriDate: hijri,
            locationName: context.regionName
        )

        // Re-schedule notifications for the new location
        await NotificationScheduler.shared.scheduleIfNeeded()

        await MainActor.run {
            ToastService.shared.show(Toast(
                message: "Prayer times updated for \(context.regionName)",
                type: .success
            ))
        }
    }

    private func isNearPrayerTime(prefs: UserPreferences) -> Bool {
        guard let prayers = dependencies.cachedTodayPrayers else { return false }
        let now = Date()
        return prayers.contains { $0.type.isObligatory && $0.time > now
            && $0.time.timeIntervalSince(now) < 1800 }
    }

    private func dismissQadaReminder() {
        if let payload = qadaReminderPayload {
            RamadanQadaReminderService.markShown(hijriYear: payload.hijriYear)
        }
        qadaReminderPayload = nil
    }

}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @State private var showReviewPrompt = false
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
            QuranView()
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
        .overlay {
            if showReviewPrompt {
                ReviewPromptView(isPresented: $showReviewPrompt)
            }
        }
        .task {
            // Wait at least 15 minutes before showing review prompt (matches AppReviewService.baseInterval)
            try? await Task.sleep(for: .seconds(AppReviewService.baseInterval))
            if AppReviewService.shouldShowPrompt() {
                withAnimation { showReviewPrompt = true }
                AppReviewService.recordPromptShown()
            }
        }
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
            QiblaCompassView(showsDoneButton: false)
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
        }
    }
}

// MoreView extracted to Features/More/MoreView.swift
// Placeholder views (SurahDetailView, LessonDetailView) extracted to their feature folders

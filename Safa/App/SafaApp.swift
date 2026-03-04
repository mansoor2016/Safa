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
    @State private var languageManager = AppLanguageManager.shared
    @State private var launchState: LaunchState = .loading
    @State private var qadaReminderPayload: RamadanQadaReminderService.ReminderPayload?
    @State private var endingSoonTask: Task<Void, Never>?
    @State private var dailySummaryTask: Task<Void, Never>?
    @State private var schedulerGeneration: Int = 0
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
            .environment(\.locale, languageManager.currentLocale)
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

                // Prune stale toast dedup keys and schedule in-app reminders
                PrayerToastService.pruneStaleKeys()
                scheduleToastReminders()

                // Record first launch date for review prompt timing
                AppReviewService.recordFirstLaunchIfNeeded()

                // Record first eligible date for support prompt timing
                SupportPromptService.recordFirstEligibleIfNeeded()

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
                    // Re-schedule toast reminders on foreground resume
                    scheduleToastReminders()
                } else {
                    // Cancel toast tasks when going inactive/background
                    endingSoonTask?.cancel()
                    dailySummaryTask?.cancel()
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
            router.selectedTab = .prayer
        case "com.safa.qibla":
            router.selectedTab = .home
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

        // Update Live Activity with next obligatory prayer (grace-aware) + schedule boundary updates
        let now = Date()
        let maghrib = prayers.first(where: { $0.type == .maghrib })?.time
        let hijri = HijriDateConverter.shared.hijriDateString(from: now, style: .dayMonth, maghribTime: maghrib)
        let obligatory = prayers.filter { $0.type.isObligatory }
        let gracePrayer = obligatory.last { isPrayerTimeNow($0.time, at: now) }
        let futurePrayer = obligatory.first { $0.time > now }
        if let activePrayer = gracePrayer ?? futurePrayer {
            await PrayerLiveActivityManager.shared.updateActivity(
                prayerName: activePrayer.type.localizedDisplayName,
                prayerTime: activePrayer.time,
                hijriDate: hijri,
                locationName: context.regionName,
                isGrace: gracePrayer != nil
            )
        }
        let prayerInfos = obligatory
            .map { PrayerInfo(name: $0.type.localizedDisplayName, time: $0.time) }
        PrayerLiveActivityManager.shared.scheduleBoundaryUpdates(
            prayers: prayerInfos,
            maghribTime: maghrib,
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

    // MARK: - In-App Toast Reminders

    private func scheduleToastReminders() {
        schedulerGeneration += 1
        let gen = schedulerGeneration

        endingSoonTask?.cancel()
        dailySummaryTask?.cancel()

        let prefs = PreferencesManager.loadPreferencesSync()
        let coordinates = dependencies.locationService.coordinates ?? prefs.savedCoordinates
        guard PrayerToastService.shouldSchedule(prefs: prefs, coordinates: coordinates) else { return }
        guard let coordinates else { return }

        // Schedule ending-soon toast
        if prefs.prayerEndingSoonToastEnabled {
            endingSoonTask = Task { [gen] in
                await runEndingSoonToast(gen: gen, coordinates: coordinates, prefs: prefs)
            }
        }

        // Schedule daily summary toast
        if prefs.dailyPrayerSummaryToastEnabled {
            dailySummaryTask = Task { [gen] in
                await runDailySummaryToast(gen: gen, coordinates: coordinates, prefs: prefs)
            }
        }
    }

    private func runEndingSoonToast(gen: Int, coordinates: Coordinates, prefs: UserPreferences) async {
        let now = Date()

        guard let schedule = try? await dependencies.prayerRepository.getPrayers(
            for: now, location: coordinates, method: prefs.calculationMethod, madhab: prefs.madhab
        ) else { return }
        guard gen == schedulerGeneration else { return }

        let logs = (try? await dependencies.prayerRepository.getPrayerLogs(for: now)) ?? []
        guard gen == schedulerGeneration else { return }

        let loggedTypes = Set(logs.map(\.prayerType))

        guard let fireDate = PrayerToastService.nextEndingSoonFireDate(
            now: now, schedule: schedule, loggedPrayers: loggedTypes
        ) else { return }

        // Sleep until fire date
        let delay = fireDate.timeIntervalSince(Date())
        if delay > 0 {
            try? await Task.sleep(for: .seconds(delay))
        }
        guard !Task.isCancelled, gen == schedulerGeneration else { return }

        // Revalidate at fire time
        let freshPrefs = PreferencesManager.loadPreferencesSync()
        guard freshPrefs.prayerEndingSoonToastEnabled else { return }

        let freshLogs = (try? await dependencies.prayerRepository.getPrayerLogs(for: Date())) ?? []
        guard gen == schedulerGeneration else { return }
        let freshLoggedTypes = Set(freshLogs.map(\.prayerType))

        guard let prayer = PrayerToastService.prayerEndingSoon(
            now: Date(), schedule: schedule, loggedPrayers: freshLoggedTypes
        ) else {
            // No toast needed, but re-schedule for next prayer
            Task { @MainActor in scheduleToastReminders() }
            return
        }

        // Collision guard: wait if another toast is visible
        await waitForToastSlot()
        guard gen == schedulerGeneration else { return }

        PrayerToastService.markEndingSoonShown(for: prayer, on: Date())

        let prayerName = prayer.localizedDisplayName
        ToastService.shared.show(Toast(
            message: String(localized: "\(prayerName) ending soon"),
            type: .warning,
            duration: 4.0,
            actionTitle: String(localized: "Log"),
            action: { [router] in
                router.selectedTab = .prayer
                router.pendingNotificationAction = .logPrayer(prayerType: prayer)
            }
        ))

        // Re-schedule for next prayer
        Task { @MainActor in scheduleToastReminders() }
    }

    private func runDailySummaryToast(gen: Int, coordinates: Coordinates, prefs: UserPreferences) async {
        let now = Date()

        guard let schedule = try? await dependencies.prayerRepository.getPrayers(
            for: now, location: coordinates, method: prefs.calculationMethod, madhab: prefs.madhab
        ) else { return }
        guard gen == schedulerGeneration else { return }

        guard let fireDate = PrayerToastService.nextDailySummaryFireDate(
            now: now, schedule: schedule
        ) else { return }

        // Sleep until fire date
        let delay = fireDate.timeIntervalSince(Date())
        if delay > 0 {
            try? await Task.sleep(for: .seconds(delay))
        }
        guard !Task.isCancelled, gen == schedulerGeneration else { return }

        // Small delay after Isha for a natural feel
        try? await Task.sleep(for: .seconds(1.5))
        guard !Task.isCancelled, gen == schedulerGeneration else { return }

        // Revalidate at fire time
        let freshPrefs = PreferencesManager.loadPreferencesSync()
        guard freshPrefs.dailyPrayerSummaryToastEnabled else { return }

        let logs = (try? await dependencies.prayerRepository.getPrayerLogs(for: Date())) ?? []
        guard gen == schedulerGeneration else { return }

        let obligatorySet = Set(PrayerType.obligatoryPrayers)
        let obligatoryCount = Set(logs.map(\.prayerType)).intersection(obligatorySet).count

        guard let _ = PrayerToastService.dailySummary(
            now: Date(), schedule: schedule, loggedCount: obligatoryCount
        ) else { return }

        // Collision guard
        await waitForToastSlot()
        guard gen == schedulerGeneration else { return }

        PrayerToastService.markDailySummaryShown(on: Date())

        ToastService.shared.show(Toast(
            message: String(localized: "You logged \(obligatoryCount)/5 prayers today"),
            type: .info,
            duration: 3.5
        ))
    }

    /// Waits for any visible toast to dismiss before showing a new one.
    private func waitForToastSlot() async {
        for _ in 0..<3 {
            if ToastService.shared.currentToast == nil { return }
            try? await Task.sleep(for: .seconds(2))
        }
    }

}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @State private var showReviewPrompt = false
    @State private var showSupportCardThisSession = false
    @State private var supportCardDismissed = false
    @State private var debugForceSupport = false
    @State private var hasEvaluatedPromptsThisSession = false
    private typealias Tab = AppRouter.Tab

    var body: some View {
        TabView(selection: Binding(
            get: { router.selectedTab },
            set: { router.selectedTab = $0 }
        )) {
            // Home Tab
            NavigationStack(path: Binding(
                get: { router.path },
                set: { router.path = $0 }
            )) {
                HomeView(
                    showSupportCardThisSession: $showSupportCardThisSession,
                    supportCardDismissed: $supportCardDismissed,
                    debugForceSupport: $debugForceSupport
                )
                    .navigationDestination(for: AppRouter.Destination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label(Tab.home.title, systemImage: router.selectedTab == .home ? Tab.home.selectedIcon : Tab.home.icon)
            }
            .tag(Tab.home)

            // Quran Tab
            QuranView()
            .tabItem {
                Label(Tab.quran.title, systemImage: router.selectedTab == .quran ? Tab.quran.selectedIcon : Tab.quran.icon)
            }
            .tag(Tab.quran)

            // Prayer Tab (swaps to Ramadan view during Ramadan)
            NavigationStack {
                if router.isRamadanActive() {
                    RamadanView()
                } else {
                    PrayerView()
                }
            }
            .tabItem {
                Label(Tab.prayer.title, systemImage: router.selectedTab == .prayer ? Tab.prayer.selectedIcon : Tab.prayer.icon)
            }
            .tag(Tab.prayer)

            // Duas Tab
            NavigationStack {
                DuaCategoriesView()
            }
            .tabItem {
                Label(Tab.duas.title, systemImage: router.selectedTab == .duas ? Tab.duas.selectedIcon : Tab.duas.icon)
            }
            .tag(Tab.duas)

            // More Tab
            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label(Tab.more.title, systemImage: router.selectedTab == .more ? Tab.more.selectedIcon : Tab.more.icon)
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
            try? await Task.sleep(for: .seconds(AppReviewService.baseInterval))

            // Guard: evaluate prompts exactly once per session
            guard !hasEvaluatedPromptsThisSession else { return }
            hasEvaluatedPromptsThisSession = true

            // Review has priority
            if AppReviewService.shouldShowPrompt() {
                withAnimation { showReviewPrompt = true }
                AppReviewService.recordPromptShown()
                return // Only one prompt per session
            }

            // Support prompt — only if eligible this session
            let sub = dependencies.subscriptionService
            if SupportPromptService.shouldShowPrompt(
                hasActiveSubscription: sub.hasActiveSubscription,
                entitlementsInitialized: sub.entitlementsInitialized
            ) {
                showSupportCardThisSession = true
                SupportPromptService.recordPromptShown()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .debugShowReviewPrompt)) { _ in
            withAnimation { showReviewPrompt = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .debugShowSupportPrompt)) { _ in
            debugForceSupport = true
            supportCardDismissed = false
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
        case .progress:
            ProgressDashboardView()
        case .settings:
            SettingsView()
        }
    }
}

// MoreView extracted to Features/More/MoreView.swift
// Placeholder views (SurahDetailView, LessonDetailView) extracted to their feature folders

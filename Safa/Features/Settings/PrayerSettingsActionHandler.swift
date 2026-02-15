// MARK: - PrayerSettingsActionHandler.swift
// PURPOSE: Shared side-effect handler for prayer settings changes (save + reschedule + live activity)
// DEPENDENCIES: Foundation, PreferencesManager, NotificationScheduler, PrayerLiveActivityManager

import Foundation

// MARK: - Protocols

protocol PrayerPreferencesSaving {
    func saveCalculationMethod(_ method: CalculationMethod) async
    func saveMadhab(_ madhab: Madhab) async
    func saveLocationSettings(method: CalculationMethod, madhab: Madhab, language: String) async
}

protocol LiveActivityManaging {
    func ensureActivityIfNeeded() async
}

// MARK: - Conformances

extension PreferencesManager: PrayerPreferencesSaving {}
extension PrayerLiveActivityManager: LiveActivityManaging {}

// MARK: - Handler

enum PrayerSettingsActionHandler {

    /// Apply method + madhab together (single reschedule). No-op if nothing changed.
    @MainActor static func applyPrayerSettings(
        method: CalculationMethod,
        madhab: Madhab,
        current: (method: CalculationMethod, madhab: Madhab)
    ) async {
        await applyPrayerSettings(
            method: method, madhab: madhab, current: current,
            preferenceSaver: PreferencesManager.shared,
            scheduler: NotificationScheduler.shared,
            liveActivity: PrayerLiveActivityManager.shared
        )
    }

    /// Testable variant with injectable dependencies.
    static func applyPrayerSettings(
        method: CalculationMethod,
        madhab: Madhab,
        current: (method: CalculationMethod, madhab: Madhab),
        preferenceSaver: some PrayerPreferencesSaving,
        scheduler: some NotificationScheduling,
        liveActivity: some LiveActivityManaging
    ) async {
        let methodChanged = method != current.method
        let madhabChanged = madhab != current.madhab
        guard methodChanged || madhabChanged else { return }

        if methodChanged { await preferenceSaver.saveCalculationMethod(method) }
        if madhabChanged { await preferenceSaver.saveMadhab(madhab) }
        await scheduler.forceReschedule()
        await liveActivity.ensureActivityIfNeeded()
    }

    /// Apply all recommendations (method + madhab + language). No-op if nothing changed.
    @MainActor static func applyRecommendations(
        method: CalculationMethod,
        madhab: Madhab,
        language: String,
        current: (method: CalculationMethod, madhab: Madhab, language: String)
    ) async {
        await applyRecommendations(
            method: method, madhab: madhab, language: language, current: current,
            preferenceSaver: PreferencesManager.shared,
            scheduler: NotificationScheduler.shared,
            liveActivity: PrayerLiveActivityManager.shared
        )
    }

    /// Testable variant with injectable dependencies.
    static func applyRecommendations(
        method: CalculationMethod,
        madhab: Madhab,
        language: String,
        current: (method: CalculationMethod, madhab: Madhab, language: String),
        preferenceSaver: some PrayerPreferencesSaving,
        scheduler: some NotificationScheduling,
        liveActivity: some LiveActivityManaging
    ) async {
        guard method != current.method || madhab != current.madhab || language != current.language else { return }
        await preferenceSaver.saveLocationSettings(method: method, madhab: madhab, language: language)
        await scheduler.forceReschedule()
        await liveActivity.ensureActivityIfNeeded()
    }
}

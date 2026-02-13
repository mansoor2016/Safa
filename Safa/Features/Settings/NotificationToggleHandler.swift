// MARK: - NotificationToggleHandler.swift
// PURPOSE: Testable handler for the notification master toggle, with injectable dependencies
// DEPENDENCIES: Foundation

import Foundation

// MARK: - Protocols

protocol NotificationScheduling {
    func requestAuthorization() async -> Bool
    func forceReschedule() async
}

protocol NotificationPreferencesSaving {
    func saveNotificationsEnabled(_ enabled: Bool) async
}

// MARK: - Conformances

extension NotificationScheduler: NotificationScheduling {}
extension PreferencesManager: NotificationPreferencesSaving {}

// MARK: - Result

struct NotificationToggleResult: Equatable {
    let authorizationRequested: Bool
    let authorizationGranted: Bool
    let rescheduled: Bool
    let showDisabledToast: Bool
}

// MARK: - Handler

enum NotificationToggleHandler {

    /// Handles the notification master toggle change.
    /// Saves prefs first (must complete before reschedule reads them), then acts on new state.
    static func handle(
        enabled: Bool,
        preferenceSaver: some NotificationPreferencesSaving,
        scheduler: some NotificationScheduling
    ) async -> NotificationToggleResult {
        // 1. Save first — must complete before reschedule reads prefs
        await preferenceSaver.saveNotificationsEnabled(enabled)

        // 2. Act on new state
        if enabled {
            let granted = await scheduler.requestAuthorization()
            await scheduler.forceReschedule()
            return NotificationToggleResult(
                authorizationRequested: true,
                authorizationGranted: granted,
                rescheduled: true,
                showDisabledToast: false
            )
        } else {
            await scheduler.forceReschedule() // will hit kill switch → cancel
            return NotificationToggleResult(
                authorizationRequested: false,
                authorizationGranted: false,
                rescheduled: true,
                showDisabledToast: true
            )
        }
    }
}

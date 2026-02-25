// MARK: - SupportPromptService.swift
// PURPOSE: Manages support subscription prompt timing with session-based frequency
// DEPENDENCIES: Foundation, AppConstants

import Foundation

struct SupportPromptService {
    // MARK: - Constants

    /// Number of sessions before first prompt
    static let initialGraceSessions = 3

    /// Show prompt every N sessions after grace period
    static let sessionInterval = 10

    // MARK: - In-Process Guard

    /// Ensures `recordSessionStart` only increments once per process lifetime.
    private static var didRecordThisProcess = false

    // MARK: - Public Methods

    /// Determines whether the support prompt should be shown this session.
    static func shouldShowPrompt(
        hasActiveSubscription: Bool,
        entitlementsInitialized: Bool,
        defaults: UserDefaults = .standard
    ) -> Bool {
        // Never prompt if entitlements haven't loaded yet
        guard entitlementsInitialized else { return false }

        // Never prompt active subscribers
        if hasActiveSubscription { return false }

        // Respect opt-out
        if defaults.bool(forKey: AppConstants.StorageKeys.supportOptedOut) {
            return false
        }

        let sessions = defaults.integer(forKey: AppConstants.StorageKeys.supportSessionCount)

        // Grace period: no prompts during initial sessions
        guard sessions >= initialGraceSessions else { return false }

        // Show on every Nth session after grace
        return (sessions - initialGraceSessions) % sessionInterval == 0
    }

    /// Increments the session counter. Idempotent per process lifetime.
    /// Called at app startup (SafaApp.swift).
    static func recordSessionStart(defaults: UserDefaults = .standard) {
        guard !didRecordThisProcess else { return }
        didRecordThisProcess = true

        let count = defaults.integer(forKey: AppConstants.StorageKeys.supportSessionCount)
        defaults.set(count + 1, forKey: AppConstants.StorageKeys.supportSessionCount)
    }

    /// Records the first eligible date if not already set.
    /// Now delegates to `recordSessionStart` to preserve the call site at SafaApp.swift:140.
    static func recordFirstEligibleIfNeeded(defaults: UserDefaults = .standard) {
        recordSessionStart(defaults: defaults)
    }

    /// Records that a support prompt was shown. Increments count and sets last prompt date.
    static func recordPromptShown(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        let count = defaults.integer(forKey: AppConstants.StorageKeys.supportPromptCount)
        defaults.set(count + 1, forKey: AppConstants.StorageKeys.supportPromptCount)
        defaults.set(now, forKey: AppConstants.StorageKeys.supportLastPromptDate)
    }

    /// Marks the user as opted out of support prompts.
    static func optOut(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: AppConstants.StorageKeys.supportOptedOut)
    }

    /// Returns how many times the prompt has been shown.
    static func promptCount(defaults: UserDefaults = .standard) -> Int {
        defaults.integer(forKey: AppConstants.StorageKeys.supportPromptCount)
    }

    /// Clears all support prompt state. For testing only.
    static func resetForTesting(defaults: UserDefaults = .standard) {
        // Clean up old time-based keys (removed in this release)
        defaults.removeObject(forKey: AppConstants.StorageKeys.supportFirstEligibleDate)
        defaults.removeObject(forKey: AppConstants.StorageKeys.supportLastPromptDate)
        // Clean up current keys
        defaults.removeObject(forKey: AppConstants.StorageKeys.supportPromptCount)
        defaults.removeObject(forKey: AppConstants.StorageKeys.supportOptedOut)
        defaults.removeObject(forKey: AppConstants.StorageKeys.supportSessionCount)
        // Reset in-process guard
        didRecordThisProcess = false
    }

    /// Posts a notification to immediately show the support prompt (developer testing only).
    static func triggerDebugPrompt() {
        NotificationCenter.default.post(name: .debugShowSupportPrompt, object: nil)
    }
}

extension Notification.Name {
    static let debugShowSupportPrompt = Notification.Name("com.safa.debug.showSupportPrompt")
}

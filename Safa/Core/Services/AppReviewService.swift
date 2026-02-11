// MARK: - AppReviewService.swift
// PURPOSE: Manages review prompt timing with exponential backoff
// DEPENDENCIES: Foundation, AppConstants

import Foundation

struct AppReviewService {
    // MARK: - Constants

    /// Base interval before first prompt (15 minutes)
    static let baseInterval: TimeInterval = 900

    /// Multiplier for exponential backoff (15min → 1hr → 4hr → 16hr → ...)
    static let multiplier: Double = 4

    private static var defaults: UserDefaults { .standard }

    // MARK: - Public Methods

    /// Determines whether the review prompt should be shown now.
    /// All date parameters are injectable for testing.
    static func shouldShowPrompt(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> Bool {
        if defaults.bool(forKey: AppConstants.StorageKeys.reviewOptedOut) {
            return false
        }

        guard let firstLaunch = defaults.object(forKey: AppConstants.StorageKeys.reviewFirstLaunchDate) as? Date else {
            return false
        }

        let count = defaults.integer(forKey: AppConstants.StorageKeys.reviewPromptCount)
        let requiredInterval = baseInterval * pow(multiplier, Double(count))

        // Must have waited long enough since first launch
        guard now.timeIntervalSince(firstLaunch) >= requiredInterval else {
            return false
        }

        // Must have waited long enough since last prompt (if any)
        if let lastPrompt = defaults.object(forKey: AppConstants.StorageKeys.reviewLastPromptDate) as? Date {
            // Clock skew safety: if lastPrompt is in the future, don't show
            guard lastPrompt <= now else { return false }
            guard now.timeIntervalSince(lastPrompt) >= requiredInterval else {
                return false
            }
        }

        return true
    }

    /// Records the first launch date if not already set.
    static func recordFirstLaunchIfNeeded(defaults: UserDefaults = .standard) {
        if defaults.object(forKey: AppConstants.StorageKeys.reviewFirstLaunchDate) == nil {
            defaults.set(Date(), forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        }
    }

    /// Records that a review prompt was shown. Increments count and sets last prompt date.
    static func recordPromptShown(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        let count = defaults.integer(forKey: AppConstants.StorageKeys.reviewPromptCount)
        defaults.set(count + 1, forKey: AppConstants.StorageKeys.reviewPromptCount)
        defaults.set(now, forKey: AppConstants.StorageKeys.reviewLastPromptDate)
    }

    /// Marks the user as opted out of review prompts.
    static func optOut(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: AppConstants.StorageKeys.reviewOptedOut)
    }

    /// Returns how many times the prompt has been shown.
    static func promptCount(defaults: UserDefaults = .standard) -> Int {
        defaults.integer(forKey: AppConstants.StorageKeys.reviewPromptCount)
    }

    /// Clears all review state. For testing only.
    static func resetForTesting(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        defaults.removeObject(forKey: AppConstants.StorageKeys.reviewPromptCount)
        defaults.removeObject(forKey: AppConstants.StorageKeys.reviewOptedOut)
        defaults.removeObject(forKey: AppConstants.StorageKeys.reviewLastPromptDate)
    }
}

// MARK: - OnboardingNotificationAuthCoordinator.swift
// PURPOSE: Testable handler for requesting notification authorization during onboarding
// DEPENDENCIES: OnboardingHelpers, NotificationScheduling

import Foundation
import UserNotifications

@MainActor
final class OnboardingNotificationAuthCoordinator {
    // MARK: - State
    private(set) var isRequesting = false

    // MARK: - Dependencies
    private let scheduler: any NotificationScheduling

    // MARK: - Init
    init(scheduler: any NotificationScheduling = NotificationScheduler.shared) {
        self.scheduler = scheduler
    }

    // MARK: - Public Methods

    /// Requests notification authorization if conditions are met.
    /// Returns `true` if a request was fired. Caller should refresh auth status after.
    func requestIfNeeded(
        currentPage: Int,
        notificationsEnabled: Bool,
        notificationAuthStatus: UNAuthorizationStatus
    ) async -> Bool {
        guard OnboardingHelpers.shouldRequestNotificationAuth(
            currentPage: currentPage,
            notificationsEnabled: notificationsEnabled,
            notificationAuthStatus: notificationAuthStatus,
            isRequestingAuth: isRequesting
        ) else { return false }

        isRequesting = true
        defer { isRequesting = false }
        _ = await scheduler.requestAuthorization()
        return true
    }
}

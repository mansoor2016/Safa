// MARK: - NotificationSchedulerHelpers.swift
// PURPOSE: Pure-function decision logic for notification scheduling, testable without UNUserNotificationCenter
// DEPENDENCIES: Foundation

import Foundation

enum NotificationSchedulerHelpers {

    enum ScheduleAction: Equatable {
        case cancelAll              // master toggle OFF — cancel pending notifications
        case skipNotAuthorized      // system notification permission not granted
        case skipAlreadyScheduled   // already scheduled today (daily dedup)
        case schedule               // proceed to schedule notifications
    }

    /// Determines what the scheduler should do given current state.
    /// Used by both `scheduleIfNeeded` (daily) and `forceReschedule`.
    static func determineAction(
        notificationsEnabled: Bool,
        isAuthorized: Bool,
        lastScheduledDate: Date?,
        isForceReschedule: Bool
    ) -> ScheduleAction {
        // Kill switch always wins — even if not authorized, cancel pending requests
        guard notificationsEnabled else { return .cancelAll }

        guard isAuthorized else { return .skipNotAuthorized }

        // Force reschedule skips the daily dedup
        if !isForceReschedule,
           let lastDate = lastScheduledDate,
           Calendar.current.isDateInToday(lastDate) {
            return .skipAlreadyScheduled
        }

        return .schedule
    }
}

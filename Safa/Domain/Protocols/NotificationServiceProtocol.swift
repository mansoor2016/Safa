// MARK: - NotificationServiceProtocol.swift
// PURPOSE: Defines contract for notification services

import Foundation

protocol NotificationServiceProtocol {
    /// Whether notifications are authorized
    var isAuthorized: Bool { get }

    /// Request notification authorization
    func requestAuthorization() async throws -> Bool

    /// Schedule daily prayer notifications
    func scheduleDailyPrayerNotifications(prayers: [PrayerTime], offsetMinutes: Int) async throws
}

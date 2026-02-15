// MARK: - PrayerRepositoryProtocol.swift
// PURPOSE: Defines contract for prayer data access and management

import Foundation

protocol PrayerRepositoryProtocol {
    /// Fetches prayer times for a specific date and location
    /// - Parameters:
    ///   - date: The date to get prayer times for
    ///   - location: The coordinates for calculation
    ///   - method: The calculation method to use
    /// - Returns: Array of prayer times for the day
    func getPrayers(for date: Date, location: Coordinates, method: CalculationMethod, madhab: Madhab?) async throws -> [PrayerTime]

    /// Logs a prayer as completed
    /// - Parameters:
    ///   - prayer: The prayer type to log
    ///   - date: The date of the prayer
    ///   - time: The time the prayer was logged
    ///   - isOnTime: Whether the prayer was logged within its time window
    func logPrayer(_ prayer: PrayerType, for date: Date, at time: Date, isOnTime: Bool) async throws

    /// Fetches prayer logs for a date range
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Array of prayer logs
    func getPrayerLogs(from: Date, to: Date) async throws -> [PrayerLog]

    /// Fetches prayer log for a specific date
    /// - Parameter date: The date to fetch logs for
    /// - Returns: Array of prayer logs for that date
    func getPrayerLogs(for date: Date) async throws -> [PrayerLog]

    /// Deletes a prayer log
    /// - Parameter log: The log to delete
    func deletePrayerLog(_ log: PrayerLog) async throws

    /// Checks if a prayer has been logged for a specific date
    /// - Parameters:
    ///   - prayer: The prayer type
    ///   - date: The date to check
    /// - Returns: True if the prayer has been logged
    func isPrayerLogged(_ prayer: PrayerType, for date: Date) async throws -> Bool

    /// Fetches sunnah times (middle of night, last third) for a given date and location
    func getSunnahTimes(for date: Date, location: Coordinates, method: CalculationMethod, madhab: Madhab?) -> [SunnahTime]
}

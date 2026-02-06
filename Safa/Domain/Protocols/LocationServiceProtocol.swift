// MARK: - LocationServiceProtocol.swift
// PURPOSE: Defines contract for location services

import Foundation
import CoreLocation

protocol LocationServiceProtocol {
    /// The current authorization status
    var authorizationStatus: CLAuthorizationStatus { get }

    /// Cached or saved coordinates (available without live GPS)
    var coordinates: Coordinates? { get }

    /// Request location permission
    func requestPermission()

    /// Get the current location asynchronously
    func getCurrentLocation() async throws -> CLLocation
}

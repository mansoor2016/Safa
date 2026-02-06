// MARK: - LocationService.swift
// PURPOSE: Location services for prayer times and Qibla direction
// DEPENDENCIES: CoreLocation

import Foundation
import CoreLocation
import Combine

final class LocationService: NSObject, ObservableObject, LocationServiceProtocol {
    // MARK: - Published State
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var heading: CLHeading?
    @Published private(set) var error: Error?
    @Published private(set) var locationContext: LocationContext?

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let inferenceService = LocationInferenceService.shared
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    // MARK: - Init
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Public Methods

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func getCurrentLocation() async throws -> CLLocation {
        // Return cached location if recent (within 5 minutes)
        if let location = currentLocation,
           Date().timeIntervalSince(location.timestamp) < 300 {
            return location
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    /// Get current location with full context (reverse geocoded)
    func getLocationContext() async throws -> LocationContext {
        let location = try await getCurrentLocation()
        let context = await inferenceService.inferContext(from: location)

        await MainActor.run {
            self.locationContext = context
        }

        return context
    }

    /// Get location context with fallback (never throws)
    func getLocationContextSafe() async -> LocationContext {
        do {
            return try await getLocationContext()
        } catch {
            // Return fallback based on device locale if location unavailable
            return LocationContext.fallback
        }
    }

    /// Quick context without geocoding (uses coordinate heuristics)
    func getQuickContext() async -> LocationContext? {
        guard let location = currentLocation else {
            do {
                let loc = try await getCurrentLocation()
                let coords = Coordinates(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
                return inferenceService.inferContextFast(from: coords)
            } catch {
                return nil
            }
        }

        let coords = Coordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        return inferenceService.inferContextFast(from: coords)
    }

    func startUpdatingHeading() {
        guard CLLocationManager.headingAvailable() else { return }
        locationManager.startUpdatingHeading()
    }

    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }

    var coordinates: Coordinates? {
        if let location = currentLocation {
            return Coordinates(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
        // Fall back to default location (London, UK)
        return AppDefaults.defaultCoordinates
    }

    /// Check if location permission is granted
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }

    /// Check if permission has been determined
    var isPermissionDetermined: Bool {
        authorizationStatus != .notDetermined
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }
}

// MARK: - Location Error
enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable
    case timeout

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission was denied. Please enable in Settings."
        case .locationUnavailable:
            return "Unable to determine your location."
        case .timeout:
            return "Location request timed out."
        }
    }
}

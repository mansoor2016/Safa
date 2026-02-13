// MARK: - QiblaCompassHelpers.swift
// PURPOSE: Testable pure-function helpers for Qibla compass heading, alignment, and accuracy
// DEPENDENCIES: Foundation, CoreLocation

import Foundation
import CoreLocation

enum QiblaCompassHelpers {

    // MARK: - Alignment Zones

    enum AlignmentZone: Equatable {
        case perfect    // Within 5 degrees
        case close      // Within 15 degrees
        case near       // Within 30 degrees
        case far        // More than 30 degrees

        static func from(angle: Double) -> AlignmentZone {
            let normalizedAngle = min(angle, 360 - angle)
            switch normalizedAngle {
            case 0..<5: return .perfect
            case 5..<15: return .close
            case 15..<30: return .near
            default: return .far
            }
        }
    }

    // MARK: - Compass Accuracy

    enum CompassAccuracy: Equatable {
        case good       // headingAccuracy <= 25
        case low        // headingAccuracy > 25
        case unreliable // headingAccuracy < 0
    }

    static func compassAccuracy(for headingAccuracy: CLLocationDirectionAccuracy) -> CompassAccuracy {
        if headingAccuracy < 0 { return .unreliable }
        if headingAccuracy > 25 { return .low }
        return .good
    }

    // MARK: - Heading Math

    /// Normalize a degree value to 0..<360 range.
    static func normalizeDegrees(_ value: Double) -> Double {
        let normalized = value.truncatingRemainder(dividingBy: 360)
        return normalized >= 0 ? normalized : normalized + 360
    }

    /// Smooth heading transitions while correctly handling 0/360 wrap-around.
    static func smoothHeading(from current: Double, to target: Double, factor: Double) -> Double {
        let shortestDelta = ((target - current + 540).truncatingRemainder(dividingBy: 360)) - 180
        return normalizeDegrees(current + shortestDelta * factor)
    }

    /// Compute the relative angle from device heading to Qibla direction.
    static func relativeAngle(qiblaDirection: Double, deviceHeading: Double) -> Double {
        (qiblaDirection - deviceHeading + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Extract usable heading value from CLHeading (prefer trueHeading, fallback to magnetic).
    static func headingValue(from heading: CLHeading) -> Double {
        let value = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
        return normalizeDegrees(value)
    }

    // MARK: - Responsive Sizing

    /// Compute compass size from the available container width.
    /// Subtracts horizontal breathing room and clamps to [200, 320].
    static func compassSize(forContainerWidth width: CGFloat) -> CGFloat {
        let breathing: CGFloat = 64 // SafaSpacing.xl * 2
        return min(max(width - breathing, 200), 320)
    }
}

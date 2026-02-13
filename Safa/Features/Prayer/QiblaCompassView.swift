// MARK: - QiblaCompassView.swift
// PURPOSE: Qibla direction compass view
// DEPENDENCIES: SwiftUI, CoreLocation

import SwiftUI
import CoreLocation
import Combine

struct QiblaCompassView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var qiblaDirection: Double = 0
    @State private var deviceHeading: Double = 0
    @State private var isLoading = true
    @State private var error: Error?
    @State private var isSimulatedHeading = false
    @State private var compassAccuracy: QiblaCompassHelpers.CompassAccuracy = .good
    @State private var headingTimedOut = false
    @State private var lastHeadingUpdate = Date()
    @State private var hasReceivedHeading = false
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined
    @State private var locationSource: LocationSource = .fallback(name: AppDefaults.defaultLocationName)
    @ScaledMetric(relativeTo: .largeTitle) private var compassSize: CGFloat = 280

    private enum LocationSource: Equatable {
        case live
        case saved(name: String?)
        case fallback(name: String)

        var icon: String {
            switch self {
            case .live:
                return "location.fill"
            case .saved:
                return "mappin.and.ellipse"
            case .fallback:
                return "exclamationmark.triangle.fill"
            }
        }

        var message: String {
            switch self {
            case .live:
                return String(localized: "Using current location")
            case .saved(let name):
                if let name, !name.isEmpty {
                    return String(localized: "Using saved location: \(name)")
                }
                return String(localized: "Using saved location")
            case .fallback(let name):
                return String(localized: "Using default location: \(name)")
            }
        }

        var color: Color {
            switch self {
            case .live:
                return .green
            case .saved:
                return .orange
            case .fallback:
                return .red
            }
        }
    }

    // Haptic feedback state
    @State private var previousAlignmentZone: QiblaCompassHelpers.AlignmentZone = .far
    @State private var hapticFeedbackEnabled = true

    private typealias AlignmentZone = QiblaCompassHelpers.AlignmentZone

    var body: some View {
        VStack(spacing: SafaSpacing.xl) {
            if isLoading {
                LoadingView(message: "Finding Qibla direction...")
            } else if let error = error {
                QiblaErrorView(error: error) {
                    Task {
                        await loadQiblaDirection()
                    }
                }
            } else {
                qiblaContent
            }
        }
        .padding()
        .navigationTitle("Qibla")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            locationStatus = dependencies.locationService.authorizationStatus
            await loadQiblaDirection()
            startHeadingUpdates()
        }
        .onDisappear {
            stopHeadingUpdates()
        }
        .onReceive(dependencies.locationService.headingPublisher) { heading in
            guard let heading else { return }
            applyHeadingUpdate(heading)
        }
        .onReceive(dependencies.locationService.authorizationStatusPublisher) { status in
            let previous = locationStatus
            locationStatus = status

            guard previous != status else { return }

            if status == .authorizedAlways || status == .authorizedWhenInUse {
                Task { await loadQiblaDirection() }
                startHeadingUpdates()
            }
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            // Only check for stale heading when we've previously received data
            // and the sensor should be active
            guard hasReceivedHeading,
                  !isSimulatedHeading,
                  !isLoading,
                  !isPermissionDenied else { return }
            if Date().timeIntervalSince(lastHeadingUpdate) > 5 {
                headingTimedOut = true
            }
        }
    }

    // MARK: - Qibla Content

    private var qiblaContent: some View {
        VStack(spacing: SafaSpacing.xl) {
            // Kaaba image/icon
            VStack(spacing: SafaSpacing.xs) {
                Image(systemName: "building.columns.fill")
                    .font(SafaTypography.displaySmall)
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)

                Text("Kaaba")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Direction to Kaaba in Makkah")

            // Compass
            CompassView(
                qiblaDirection: qiblaDirection,
                deviceHeading: deviceHeading,
                size: compassSize
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(compassAccessibilityLabel)
            .accessibilityHint("Rotate your device to align with the Qibla direction")
            .onChange(of: deviceHeading) { _, newHeading in
                if hapticFeedbackEnabled {
                    provideDirectionalHapticFeedback(heading: newHeading)
                }
            }

            // Direction info
            VStack(spacing: SafaSpacing.xs) {
                Text("Qibla Direction")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)

                Text("\(Int(qiblaDirection))° from North")
                    .font(SafaTypography.headlineSmall)
                    .foregroundColor(SafaColors.Fallback.text)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Qibla direction is \(Int(qiblaDirection)) degrees from North")

            HStack(spacing: SafaSpacing.xs) {
                Image(systemName: locationSource.icon)
                    .font(.caption)
                Text(locationSource.message)
                    .font(SafaTypography.labelSmall)
                    .lineLimit(1)
            }
            .foregroundColor(locationSource.color)
            .accessibilityLabel(locationSource.message)

            if locationSource != .live {
                Button {
                    Task { await loadQiblaDirection() }
                } label: {
                    HStack(spacing: SafaSpacing.xs) {
                        Image(systemName: "location.fill")
                        Text("Refresh Location")
                    }
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(.accentColor)
                }
            }

            // Alignment indicator
            alignmentIndicator

            // Instructions
            Text("Point the top of your phone towards the arrow to face the Qibla")
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Compass status notices
            if isSimulatedHeading {
                compassNotice(
                    icon: "ant.fill",
                    text: "Debug mode: magnetometer reading not available",
                    color: .orange
                )
            } else if isPermissionDenied {
                VStack(spacing: SafaSpacing.xs) {
                    compassNotice(
                        icon: "location.slash.fill",
                        text: "Compass needs location permission to determine heading.",
                        color: .red
                    )
                    Button("Open Settings") {
                        openAppSettings()
                    }
                    .font(SafaTypography.labelSmall)
                }
            } else if headingTimedOut {
                compassNotice(
                    icon: "exclamationmark.triangle.fill",
                    text: "No compass updates detected. Move your phone in a figure-8.",
                    color: .red
                )
            } else if compassAccuracy == .unreliable {
                compassNotice(
                    icon: "arrow.triangle.2.circlepath",
                    text: "Move your device in a figure-8 to calibrate the compass",
                    color: .orange
                )
            } else if compassAccuracy == .low {
                compassNotice(
                    icon: "exclamationmark.circle",
                    text: "Low compass accuracy. Move away from metal objects.",
                    color: .yellow
                )
            }
        }
    }

    // MARK: - Alignment Indicator

    private var alignmentIndicator: some View {
        let relativeAngle = QiblaCompassHelpers.relativeAngle(qiblaDirection: qiblaDirection, deviceHeading: deviceHeading)
        let zone = AlignmentZone.from(angle: relativeAngle)

        return HStack(spacing: SafaSpacing.xs) {
            if zone == .perfect {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }

            Text(alignmentStatusText(for: zone))
                .font(SafaTypography.bodyMedium)
                .foregroundColor(zone == .perfect ? .green : SafaColors.Fallback.secondaryText)
        }
        .padding(.horizontal, SafaSpacing.md)
        .padding(.vertical, SafaSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.sm)
                .fill(zone == .perfect ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
        )
        .accessibilityLabel(alignmentStatusText(for: zone))
    }

    private func alignmentStatusText(for zone: AlignmentZone) -> String {
        switch zone {
        case .perfect: return "Facing Qibla"
        case .close: return "Almost there"
        case .near: return "Getting closer"
        case .far: return "Keep turning"
        }
    }

    private var compassAccessibilityLabel: String {
        let relativeAngle = QiblaCompassHelpers.relativeAngle(qiblaDirection: qiblaDirection, deviceHeading: deviceHeading)

        if relativeAngle < 10 || relativeAngle > 350 {
            return "You are facing the Qibla direction"
        } else if relativeAngle <= 180 {
            return "Turn \(Int(relativeAngle)) degrees to your right to face the Qibla"
        } else {
            return "Turn \(Int(360 - relativeAngle)) degrees to your left to face the Qibla"
        }
    }

    // MARK: - Methods

    private func loadQiblaDirection() async {
        isLoading = true
        error = nil

        let calculator = PrayerTimeCalculator()
        let prefs = PreferencesManager.loadPreferencesSync()

        if canUseLiveLocation {
            if let currentLocation = dependencies.locationService.currentLocation {
                let coords = Coordinates(
                    latitude: currentLocation.coordinate.latitude,
                    longitude: currentLocation.coordinate.longitude
                )
                qiblaDirection = calculator.calculateQiblaDirection(from: coords)
                locationSource = .live
                isLoading = false
                return
            }

            do {
                let liveLocation = try await dependencies.locationService.getCurrentLocation()
                let coords = Coordinates(
                    latitude: liveLocation.coordinate.latitude,
                    longitude: liveLocation.coordinate.longitude
                )
                qiblaDirection = calculator.calculateQiblaDirection(from: coords)
                locationSource = .live
                isLoading = false
                return
            } catch {
                // Fall through to saved/default location. We'll still show a source banner.
            }
        }

        if let saved = prefs.savedCoordinates {
            qiblaDirection = calculator.calculateQiblaDirection(from: saved)
            locationSource = .saved(name: prefs.savedLocationName)
            isLoading = false
            return
        }

        qiblaDirection = calculator.calculateQiblaDirection(from: AppDefaults.defaultCoordinates)
        locationSource = .fallback(name: AppDefaults.defaultLocationName)
        isLoading = false
    }

    private func startHeadingUpdates() {
        guard CLLocationManager.headingAvailable() else {
            // Simulator: no magnetometer, assume North (0°)
            isSimulatedHeading = true
            deviceHeading = 0
            return
        }

        isSimulatedHeading = false
        lastHeadingUpdate = Date()
        hasReceivedHeading = false

        if locationStatus == .notDetermined {
            dependencies.locationService.requestPermission()
        }

        guard !isPermissionDenied else { return }
        dependencies.locationService.startUpdatingHeading()
    }

    private func stopHeadingUpdates() {
        dependencies.locationService.stopUpdatingHeading()
    }

    private func compassNotice(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: SafaSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(SafaTypography.labelSmall)
        }
        .foregroundColor(color)
        .padding(.horizontal, SafaSpacing.md)
        .padding(.vertical, SafaSpacing.xs)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.sm))
    }

    // MARK: - Haptic Feedback

    private func provideDirectionalHapticFeedback(heading: Double) {
        let relativeAngle = (qiblaDirection - heading + 360).truncatingRemainder(dividingBy: 360)
        let currentZone = AlignmentZone.from(angle: relativeAngle)

        // Only provide feedback when entering a new zone
        guard currentZone != previousAlignmentZone else { return }

        switch currentZone {
        case .perfect:
            // Strong success haptic when perfectly aligned
            HapticFeedbackService.shared.play(.qiblaPerfect)
        case .close:
            // Medium haptic when getting close
            HapticFeedbackService.shared.play(.commit)
        case .near:
            // Light haptic when moderately close
            HapticFeedbackService.shared.play(.qiblaLight)
        case .far:
            // No haptic when far away
            break
        }

        previousAlignmentZone = currentZone
    }

    private func applyHeadingUpdate(_ heading: CLHeading) {
        let normalizedHeading = QiblaCompassHelpers.headingValue(from: heading)

        if hasReceivedHeading {
            deviceHeading = QiblaCompassHelpers.smoothHeading(from: deviceHeading, to: normalizedHeading, factor: 0.25)
        } else {
            deviceHeading = normalizedHeading
            hasReceivedHeading = true
        }

        compassAccuracy = QiblaCompassHelpers.compassAccuracy(for: heading.headingAccuracy)
        lastHeadingUpdate = Date()
        headingTimedOut = false
    }

    private var isPermissionDenied: Bool {
        locationStatus == .denied || locationStatus == .restricted
    }

    private var canUseLiveLocation: Bool {
        locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(settingsURL)
    }
}

// MARK: - Compass View

private struct CompassView: View {
    let qiblaDirection: Double
    let deviceHeading: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            // Compass background
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                .frame(width: size, height: size)

            // Cardinal directions
            ForEach(0..<4, id: \.self) { index in
                let direction = ["N", "E", "S", "W"][index]
                let angle = Double(index) * 90

                Text(direction)
                    .font(SafaTypography.labelLarge)
                    .foregroundColor(direction == "N" ? .red : SafaColors.Fallback.secondaryText)
                    .offset(y: -(size * 0.43))
                    .rotationEffect(.degrees(angle))
            }
            .rotationEffect(.degrees(-deviceHeading))

            // Tick marks
            ForEach(0..<36, id: \.self) { index in
                Rectangle()
                    .fill(index % 9 == 0 ? Color.gray : Color.gray.opacity(0.3))
                    .frame(width: index % 9 == 0 ? 2 : 1, height: index % 9 == 0 ? 15 : 8)
                    .offset(y: -(size * 0.46))
                    .rotationEffect(.degrees(Double(index) * 10))
            }
            .rotationEffect(.degrees(-deviceHeading))

            // Qibla direction arrow
            QiblaArrow()
                .rotationEffect(.degrees(qiblaDirection - deviceHeading))
        }
        .animation(.easeInOut(duration: 0.2), value: deviceHeading)
    }
}

// MARK: - Qibla Arrow

private struct QiblaArrow: View {
    var body: some View {
        VStack(spacing: 0) {
            // Arrow head
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 30))
                .foregroundColor(.green)

            // Arrow body
            Rectangle()
                .fill(Color.green)
                .frame(width: 4, height: 80)
        }
        .offset(y: -45)
    }
}

// MARK: - Qibla Error View

private struct QiblaErrorView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: SafaSpacing.md) {
            Image(systemName: "location.slash")
                .font(.system(size: 50))
                .foregroundColor(SafaColors.Fallback.error)

            Text("Unable to determine direction")
                .font(SafaTypography.titleMedium)

            Text(error.localizedDescription)
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)
                .multilineTextAlignment(.center)

            PrimaryButton(title: "Try Again", action: retry, fullWidth: false)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QiblaCompassView()
            .environment(Dependencies())
    }
}

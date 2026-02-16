// MARK: - QiblaCompassView.swift
// PURPOSE: Qibla direction compass view with card-based layout
// DEPENDENCIES: SwiftUI, CoreLocation, QiblaCompassWheel, QiblaAlignmentIndicator, QiblaStatusBanner

import SwiftUI
import CoreLocation
import Combine

struct QiblaCompassView: View {
    let showsDoneButton: Bool

    init(showsDoneButton: Bool = true) {
        self.showsDoneButton = showsDoneButton
    }

    @Environment(Dependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // MARK: - State

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
    @State private var previousAlignmentZone: QiblaCompassHelpers.AlignmentZone = .far
    @State private var hapticFeedbackEnabled = true

    /// Compass size derived from screen width minus card padding
    private var compassDisplaySize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let cardPadding: CGFloat = SafaSpacing.md * 2 // outer padding
        let cardInset: CGFloat = SafaSpacing.md * 2   // ContentCard internal padding
        let containerWidth = screenWidth - cardPadding - cardInset
        return QiblaCompassHelpers.compassSize(forContainerWidth: containerWidth)
    }

    private enum LocationSource: Equatable {
        case live
        case saved(name: String?)
        case fallback(name: String)

        var icon: String {
            switch self {
            case .live: return "location.fill"
            case .saved: return "mappin.and.ellipse"
            case .fallback: return "exclamationmark.triangle.fill"
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
            case .live: return .green
            case .saved: return .orange
            case .fallback: return .red
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollableScreen {
            if isLoading {
                LoadingView(message: "Finding Qibla direction...")
            } else if let error {
                ErrorView(
                    icon: "location.slash",
                    title: "Unable to determine direction",
                    message: error.localizedDescription,
                    retry: { await loadQiblaDirection() }
                )
            } else {
                qiblaContent
            }
        }
        .navigationTitle("Qibla")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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
        VStack(spacing: SafaSpacing.lg) {
            // Instructions (below nav title)
            Text("Align the compass arrow in the direction of the Kaaba")
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Hero: compass card
            ContentCard {
                VStack(spacing: SafaSpacing.md) {
                    // Kaaba icon + label
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

                    // Responsive compass
                    QiblaCompassWheel(
                        qiblaDirection: qiblaDirection,
                        deviceHeading: deviceHeading,
                        size: compassDisplaySize
                    )
                    .frame(height: compassDisplaySize)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(compassAccessibilityLabel)
                    .accessibilityHint("Rotate your device to align with the Qibla direction")
                    .onChange(of: deviceHeading) { _, newHeading in
                        if hapticFeedbackEnabled {
                            provideDirectionalHapticFeedback(heading: newHeading)
                        }
                    }

                    // Alignment indicator
                    QiblaAlignmentIndicator(
                        qiblaDirection: qiblaDirection,
                        deviceHeading: deviceHeading
                    )
                }
            }

            // Direction info card
            ContentCard {
                VStack(spacing: SafaSpacing.sm) {
                    Text("\(Int(qiblaDirection))\u{00B0} from North")
                        .font(SafaTypography.headlineSmall)
                        .foregroundColor(SafaColors.Fallback.text)
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
                }
            }

            // Status banner (one at a time)
            QiblaStatusBanner(
                status: QiblaCompassStatus.resolve(
                    isPermissionDenied: isPermissionDenied,
                    headingTimedOut: headingTimedOut,
                    accuracy: compassAccuracy,
                    isSimulated: isSimulatedHeading
                ),
                onOpenSettings: isPermissionDenied ? { openAppSettings() } : nil
            )

        }
        .padding(SafaSpacing.md)
    }

    // MARK: - Accessibility

    private var compassAccessibilityLabel: String {
        let relativeAngle = QiblaCompassHelpers.relativeAngle(
            qiblaDirection: qiblaDirection,
            deviceHeading: deviceHeading
        )
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
                // Fall through to saved/default location
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

    // MARK: - Haptic Feedback

    private func provideDirectionalHapticFeedback(heading: Double) {
        let relativeAngle = (qiblaDirection - heading + 360).truncatingRemainder(dividingBy: 360)
        let currentZone = QiblaCompassHelpers.AlignmentZone.from(angle: relativeAngle)

        guard currentZone != previousAlignmentZone else { return }

        switch currentZone {
        case .perfect:
            HapticFeedbackService.shared.play(.qiblaPerfect)
        case .close:
            HapticFeedbackService.shared.play(.commit)
        case .near:
            HapticFeedbackService.shared.play(.qiblaLight)
        case .far:
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

// MARK: - Preview

#Preview {
    NavigationStack {
        QiblaCompassView()
            .environment(Dependencies())
    }
}

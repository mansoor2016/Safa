// MARK: - QiblaCompassView.swift
// PURPOSE: Qibla direction compass view
// DEPENDENCIES: SwiftUI, CoreLocation

import SwiftUI
import CoreLocation
import Combine

struct QiblaCompassView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @State private var qiblaDirection: Double = 0
    @State private var deviceHeading: Double = 0
    @State private var isLoading = true
    @State private var error: Error?
    @State private var isSimulatedHeading = false
    @State private var compassAccuracy: CompassAccuracy = .good
    @State private var headingTimedOut = false
    @State private var lastHeadingUpdate = Date()

    private enum CompassAccuracy {
        case good       // headingAccuracy <= 25
        case low        // headingAccuracy > 25
        case unreliable // headingAccuracy < 0
    }

    // Haptic feedback state
    @State private var previousAlignmentZone: AlignmentZone = .far
    @State private var hapticFeedbackEnabled = true

    // Alignment zones for directional haptic feedback
    private enum AlignmentZone {
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

    var body: some View {
        VStack(spacing: SafaSpacing.xl) {
            if isLoading {
                LoadingView(message: "Finding Qibla direction...")
            } else if let error = error {
                ErrorView(error: error) {
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
            await loadQiblaDirection()
            startHeadingUpdates()
        }
        .onDisappear {
            stopHeadingUpdates()
        }
        .onChange(of: deviceHeading) { _, _ in
            lastHeadingUpdate = Date()
            headingTimedOut = false
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            guard !isSimulatedHeading && !isLoading && CLLocationManager.headingAvailable() else { return }
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
                    .font(.system(size: 40))
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
                deviceHeading: deviceHeading
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
            } else if headingTimedOut {
                compassNotice(
                    icon: "exclamationmark.triangle.fill",
                    text: "Compass unavailable. Try moving to an open area.",
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
        let relativeAngle = (qiblaDirection - deviceHeading + 360).truncatingRemainder(dividingBy: 360)
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
        let relativeAngle = (qiblaDirection - deviceHeading + 360).truncatingRemainder(dividingBy: 360)

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

        // Try cached/saved coordinates first, then live GPS
        if let coords = dependencies.locationService.coordinates {
            let calculator = PrayerTimeCalculator()
            qiblaDirection = calculator.calculateQiblaDirection(from: coords)
            isLoading = false
        } else {
            do {
                let location = try await dependencies.locationService.getCurrentLocation()
                let coords = Coordinates(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                let calculator = PrayerTimeCalculator()
                qiblaDirection = calculator.calculateQiblaDirection(from: coords)
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }

    private func startHeadingUpdates() {
        if CLLocationManager.headingAvailable() {
            dependencies.locationService.startUpdatingHeading()
        } else {
            // Simulator: no magnetometer, assume North (0°)
            isSimulatedHeading = true
            deviceHeading = 0
        }
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
}

// MARK: - Compass View

private struct CompassView: View {
    let qiblaDirection: Double
    let deviceHeading: Double

    @State private var currentHeading: Double = 0

    var body: some View {
        ZStack {
            // Compass background
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                .frame(width: 280, height: 280)

            // Cardinal directions
            ForEach(0..<4, id: \.self) { index in
                let direction = ["N", "E", "S", "W"][index]
                let angle = Double(index) * 90

                Text(direction)
                    .font(SafaTypography.labelLarge)
                    .foregroundColor(direction == "N" ? .red : SafaColors.Fallback.secondaryText)
                    .offset(y: -120)
                    .rotationEffect(.degrees(angle))
            }
            .rotationEffect(.degrees(-currentHeading))

            // Tick marks
            ForEach(0..<36, id: \.self) { index in
                Rectangle()
                    .fill(index % 9 == 0 ? Color.gray : Color.gray.opacity(0.3))
                    .frame(width: index % 9 == 0 ? 2 : 1, height: index % 9 == 0 ? 15 : 8)
                    .offset(y: -130)
                    .rotationEffect(.degrees(Double(index) * 10))
            }
            .rotationEffect(.degrees(-currentHeading))

            // Qibla direction arrow
            QiblaArrow()
                .rotationEffect(.degrees(qiblaDirection - currentHeading))
        }
        .animation(.easeInOut(duration: 0.3), value: currentHeading)
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            // In a real implementation, this would come from the LocationService heading updates
            // For now, we'll simulate it
            currentHeading = deviceHeading
        }
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

// MARK: - Error View

private struct ErrorView: View {
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

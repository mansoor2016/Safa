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
    }

    // MARK: - Qibla Content

    private var qiblaContent: some View {
        VStack(spacing: SafaSpacing.xl) {
            // Kaaba image/icon
            VStack(spacing: SafaSpacing.xs) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)

                Text("Kaaba")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            // Compass
            CompassView(
                qiblaDirection: qiblaDirection,
                deviceHeading: deviceHeading
            )

            // Direction info
            VStack(spacing: SafaSpacing.xs) {
                Text("Qibla Direction")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)

                Text("\(Int(qiblaDirection))° from North")
                    .font(SafaTypography.headlineSmall)
                    .foregroundColor(SafaColors.Fallback.text)
            }

            // Instructions
            Text("Point the top of your phone towards the arrow to face the Qibla")
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Methods

    private func loadQiblaDirection() async {
        isLoading = true
        error = nil

        do {
            let location = try await dependencies.locationService.getCurrentLocation()
            let coordinates = Coordinates(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )

            let calculator = PrayerTimeCalculator()
            qiblaDirection = calculator.calculateQiblaDirection(from: coordinates)
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    private func startHeadingUpdates() {
        dependencies.locationService.startUpdatingHeading()
    }

    private func stopHeadingUpdates() {
        dependencies.locationService.stopUpdatingHeading()
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

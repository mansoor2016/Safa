// MARK: - OnboardingLocationSection.swift
// PURPOSE: Extracted location permission UI for onboarding page 1
// DEPENDENCIES: SwiftUI, OnboardingHelpers, LocationPermissionState

import SwiftUI
import CoreLocation

struct OnboardingLocationSection: View {
    @Binding var locationContext: LocationContext?
    @Binding var locationError: String?
    @Binding var isLoadingLocation: Bool
    @Binding var highLatitudeWarning: String?
    var locationStatus: CLAuthorizationStatus
    var onRequestPermission: () -> Void

    private var state: LocationPermissionState {
        OnboardingHelpers.resolveLocationPermissionState(
            locationContext: locationContext,
            locationStatus: locationStatus
        )
    }

    var body: some View {
        VStack(spacing: SafaSpacing.sm) {
            switch state {
            case .contextDetected:
                contextDetectedContent
            case .notDetermined:
                notDeterminedContent
            case .denied:
                deniedContent
            case .restricted:
                restrictedContent
            case .authorizedNoContext:
                authorizedNoContextContent
            }
        }
    }

    // MARK: - Context Detected

    @ViewBuilder
    private var contextDetectedContent: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 36))
            .foregroundColor(.green)

        if let context = locationContext {
            Text(context.regionName)
                .font(SafaTypography.titleMedium)
                .foregroundColor(SafaColors.Fallback.text)
        }

        if let warning = highLatitudeWarning {
            Text(warning)
                .font(SafaTypography.bodySmall)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
        }

        Button {
            locationContext = nil
            highLatitudeWarning = nil
            onRequestPermission()
        } label: {
            HStack(spacing: SafaSpacing.xs) {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("Update Location")
            }
            .font(SafaTypography.bodySmall)
            .foregroundColor(.accentColor)
        }
    }

    // MARK: - Not Determined

    @ViewBuilder
    private var notDeterminedContent: some View {
        Image(systemName: "location.circle.fill")
            .font(.system(size: 36))
            .foregroundColor(.accentColor)

        Text("Enable location for accurate prayer times")
            .font(SafaTypography.bodyMedium)
            .foregroundColor(SafaColors.Fallback.secondaryText)
            .multilineTextAlignment(.center)

        enableLocationButton
    }

    // MARK: - Denied

    @ViewBuilder
    private var deniedContent: some View {
        Image(systemName: "location.slash.fill")
            .font(.system(size: 36))
            .foregroundColor(.orange)

        Text("Location Permission Denied")
            .font(SafaTypography.titleMedium)
            .foregroundColor(SafaColors.Fallback.text)

        Text("Safa needs your location for accurate prayer times and Qibla direction. Tap Open Settings and enable Location.")
            .font(SafaTypography.bodySmall)
            .foregroundColor(SafaColors.Fallback.secondaryText)
            .multilineTextAlignment(.center)

        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            Text("Open Settings")
                .font(SafaTypography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, SafaSpacing.xl)
                .padding(.vertical, SafaSpacing.sm)
                .background(Color.orange)
                .clipShape(Capsule())
        }

        fallbackNotice
    }

    // MARK: - Restricted

    @ViewBuilder
    private var restrictedContent: some View {
        Image(systemName: "location.slash.fill")
            .font(.system(size: 36))
            .foregroundColor(.orange)

        Text("Location Restricted")
            .font(SafaTypography.titleMedium)
            .foregroundColor(SafaColors.Fallback.text)

        Text("Location access is restricted on this device. Safa will use a default location for prayer times.")
            .font(SafaTypography.bodySmall)
            .foregroundColor(SafaColors.Fallback.secondaryText)
            .multilineTextAlignment(.center)

        fallbackNotice
    }

    // MARK: - Authorized No Context

    @ViewBuilder
    private var authorizedNoContextContent: some View {
        Image(systemName: "location.circle.fill")
            .font(.system(size: 36))
            .foregroundColor(.accentColor)

        Text("Enable location for accurate prayer times")
            .font(SafaTypography.bodyMedium)
            .foregroundColor(SafaColors.Fallback.secondaryText)
            .multilineTextAlignment(.center)

        if let error = locationError {
            Text(error)
                .font(SafaTypography.bodySmall)
                .foregroundColor(.orange)
        }

        enableLocationButton
    }

    // MARK: - Shared Components

    private var enableLocationButton: some View {
        Button {
            onRequestPermission()
        } label: {
            HStack {
                if isLoadingLocation {
                    ProgressView()
                        .tint(.white)
                        .padding(.trailing, 4)
                }
                Text(isLoadingLocation ? "Detecting..." : "Enable Location")
            }
            .font(SafaTypography.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, SafaSpacing.xl)
            .padding(.vertical, SafaSpacing.sm)
            .background(Color.accentColor)
            .clipShape(Capsule())
        }
        .disabled(isLoadingLocation)
    }

    private var fallbackNotice: some View {
        Text("Default location (London, UK) will be used")
            .font(SafaTypography.bodySmall)
            .foregroundColor(SafaColors.Fallback.tertiaryText)
    }
}

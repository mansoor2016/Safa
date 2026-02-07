// MARK: - SystemStatusView.swift
// PURPOSE: System status dashboard showing permission, sync, and storage health
// DEPENDENCIES: SwiftUI, CoreLocation

import SwiftUI
import CoreLocation

struct SystemStatusView: View {
    @Environment(Dependencies.self) private var dependencies

    var body: some View {
        List {
            Section("Location") {
                statusRow(
                    icon: locationIcon,
                    title: "Location Permission",
                    status: locationStatus,
                    color: locationColor
                )

                if let coords = dependencies.locationService.coordinates {
                    HStack {
                        Text("Coordinates")
                            .font(SafaTypography.bodyMedium)
                        Spacer()
                        Text(String(format: "%.4f, %.4f", coords.latitude, coords.longitude))
                            .font(SafaTypography.bodySmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                }
            }

            Section("Notifications") {
                statusRow(
                    icon: "bell.fill",
                    title: "Notification Permission",
                    status: "Check in iOS Settings",
                    color: .secondary
                )
            }

            Section("Storage") {
                statusRow(
                    icon: storageIcon,
                    title: "Device Storage",
                    status: storageStatus,
                    color: storageColor
                )

                statusRow(
                    icon: "cylinder.split.1x2",
                    title: "Core Data",
                    status: CoreDataStack.shared.isDegradedMode ? "Degraded (in-memory)" : "Healthy",
                    color: CoreDataStack.shared.isDegradedMode ? .orange : .green
                )
            }

            Section("Sync") {
                statusRow(
                    icon: "icloud",
                    title: "CloudKit Sync",
                    status: AppDefaults.useCloudKit ? "Enabled" : "Disabled (local only)",
                    color: AppDefaults.useCloudKit ? .green : .secondary
                )
            }

            Section("Network") {
                statusRow(
                    icon: NetworkMonitor.shared.isConnected ? "wifi" : "wifi.slash",
                    title: "Network",
                    status: NetworkMonitor.shared.isConnected ? "Connected" : "Offline",
                    color: NetworkMonitor.shared.isConnected ? .green : .orange
                )

                statusRow(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "WiFi",
                    status: NetworkMonitor.shared.isOnWiFi ? "On WiFi" : "Not on WiFi",
                    color: NetworkMonitor.shared.isOnWiFi ? .green : .secondary
                )
            }
        }
        .navigationTitle("System Status")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Row

    private func statusRow(icon: String, title: String, status: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(SafaTypography.bodyMedium)

            Spacer()

            Text(status)
                .font(SafaTypography.bodySmall)
                .foregroundColor(color)
        }
    }

    // MARK: - Computed Properties

    private var locationIcon: String {
        switch dependencies.locationService.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return "location.fill"
        case .denied, .restricted: return "location.slash"
        default: return "location"
        }
    }

    private var locationStatus: String {
        switch dependencies.locationService.authorizationStatus {
        case .authorizedWhenInUse: return "While Using"
        case .authorizedAlways: return "Always"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Requested"
        @unknown default: return "Unknown"
        }
    }

    private var locationColor: Color {
        switch dependencies.locationService.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return .green
        case .denied, .restricted: return .red
        default: return .orange
        }
    }

    private var storageIcon: String {
        CoreDataStack.shared.hasLowStorage ? "externaldrive.badge.exclamationmark" : "externaldrive"
    }

    private var storageStatus: String {
        CoreDataStack.shared.hasLowStorage ? "Low (< 50MB free)" : "Healthy"
    }

    private var storageColor: Color {
        CoreDataStack.shared.hasLowStorage ? .red : .green
    }
}

#Preview {
    NavigationStack {
        SystemStatusView()
            .environment(Dependencies())
    }
}

// MARK: - LocationSettingsView.swift
// PURPOSE: Shared location settings used by Settings menu
// DEPENDENCIES: SwiftUI, PreferencesManager, LocationService

import SwiftUI

struct LocationSettingsView: View {
    // MARK: - Environment
    @Environment(Dependencies.self) private var dependencies

    // MARK: - State
    @State private var savedLocationName: String?
    @State private var autoUpdateLocation: Bool
    @State private var isUpdatingLocation = false

    private let prefsManager = PreferencesManager.shared

    // MARK: - Init
    init() {
        let prefs = PreferencesManager.loadPreferencesSync()
        _savedLocationName = State(initialValue: prefs.savedLocationName)
        _autoUpdateLocation = State(initialValue: prefs.autoUpdateLocationForPrayers)
    }

    // MARK: - Body
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prayer Location")
                            .font(SafaTypography.bodyMedium)
                            .foregroundColor(SafaColors.Fallback.text)

                        Text(savedLocationName ?? "Not set")
                            .font(SafaTypography.bodySmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }

                    Spacer()

                    if isUpdatingLocation {
                        ProgressView()
                    }
                }

                Button {
                    Task { await updateLocation() }
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Update Location")
                    }
                }
                .disabled(isUpdatingLocation)

                Toggle(isOn: $autoUpdateLocation) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Update When Traveling")
                        Text("Refresh prayer times when you move to a new city")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: autoUpdateLocation) { _, newValue in
                    Task { await prefsManager.update(\.autoUpdateLocationForPrayers, to: newValue) }
                }
            } header: {
                Text("Location")
            } footer: {
                Text("Your location is used to calculate accurate prayer times.")
            }
        }
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Private

    private func updateLocation() async {
        isUpdatingLocation = true
        do {
            let context = try await dependencies.locationService.getLocationContext()
            savedLocationName = context.regionName
            isUpdatingLocation = false

            await prefsManager.saveLocation(
                name: context.regionName,
                latitude: context.coordinates.latitude,
                longitude: context.coordinates.longitude,
                countryCode: context.countryCode
            )
        } catch {
            isUpdatingLocation = false
        }
    }
}

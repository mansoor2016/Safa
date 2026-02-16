// MARK: - QuranSettingsView.swift
// PURPOSE: Shared Quran settings used by both Settings menu and Quran gear icon
// DEPENDENCIES: SwiftUI, PreferencesManager

import SwiftUI

struct QuranSettingsView: View {
    // MARK: - State
    @State private var autoScrollEnabled: Bool

    private let prefsManager = PreferencesManager.shared

    // MARK: - Init
    init() {
        let prefs = PreferencesManager.loadPreferencesSync()
        _autoScrollEnabled = State(initialValue: prefs.autoScrollEnabled)
    }

    // MARK: - Body
    var body: some View {
        List {
            Section {
                NavigationLink {
                    FontSettingsView()
                } label: {
                    Text("Font Settings")
                }

                Toggle("Auto-Scroll Reader", isOn: $autoScrollEnabled)
                    .onChange(of: autoScrollEnabled) { _, newValue in
                        Task { await prefsManager.update(\.autoScrollEnabled, to: newValue) }
                    }
            } header: {
                Text("Quran")
            }
        }
        .navigationTitle("Quran Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

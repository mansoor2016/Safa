// MARK: - AppearanceSettingsView.swift
// PURPOSE: Shared appearance settings used by Settings menu
// DEPENDENCIES: SwiftUI, PreferencesManager, ThemeManager, HapticFeedbackService

import SwiftUI

struct AppearanceSettingsView: View {
    // MARK: - Environment
    @Environment(ThemeManager.self) private var themeManager

    // MARK: - State
    @State private var selectedAppearance: AppearanceOption
    @State private var hapticFeedbackEnabled: Bool
    @State private var showRamadanBanner: Bool
    @State private var showEidBanner: Bool

    private let prefsManager = PreferencesManager.shared

    private var ramadanBannerDismissKey: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "ramadan_banner_dismissed_\(dateFormatter.string(from: Date()))"
    }

    private var eidBannerDismissKey: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "\(AppConstants.StorageKeys.eidBannerDismissedPrefix)\(dateFormatter.string(from: Date()))"
    }

    // MARK: - Init
    init() {
        let prefs = PreferencesManager.loadPreferencesSync()
        _hapticFeedbackEnabled = State(initialValue: prefs.hapticFeedbackEnabled)

        // Appearance requires ThemeManager which isn't available in init, seed as .system
        _selectedAppearance = State(initialValue: .system)

        // Banner dismiss keys depend on current date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        let ramadanKey = "ramadan_banner_dismissed_\(dateString)"
        let eidKey = "\(AppConstants.StorageKeys.eidBannerDismissedPrefix)\(dateString)"
        _showRamadanBanner = State(initialValue: !UserDefaults.standard.bool(forKey: ramadanKey))
        _showEidBanner = State(initialValue: !UserDefaults.standard.bool(forKey: eidKey))
    }

    // MARK: - Body
    var body: some View {
        List {
            // MARK: Appearance Section
            Section {
                Picker("Appearance", selection: $selectedAppearance) {
                    ForEach(AppearanceOption.allCases) { option in
                        Label(option.rawValue, systemImage: option.iconName)
                            .tag(option)
                    }
                }
                .onChange(of: selectedAppearance) { _, newValue in
                    themeManager.setColorScheme(newValue.colorScheme)
                }

                Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                    .onChange(of: hapticFeedbackEnabled) { _, newValue in
                        HapticFeedbackService.shared.setEnabled(newValue)
                        Task { await prefsManager.saveHapticFeedback(newValue) }
                    }

                if hapticFeedbackEnabled {
                    Button {
                        HapticFeedbackService.shared.play(.success)
                    } label: {
                        HStack {
                            Text("Test Haptics")
                            Spacer()
                            Image(systemName: "hand.tap")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Toggle("Show Ramadan Banner", isOn: $showRamadanBanner)
                    .onChange(of: showRamadanBanner) { _, newValue in
                        if newValue {
                            UserDefaults.standard.removeObject(forKey: ramadanBannerDismissKey)
                        } else {
                            UserDefaults.standard.set(true, forKey: ramadanBannerDismissKey)
                        }
                    }

                Toggle("Show Eid Banner", isOn: $showEidBanner)
                    .onChange(of: showEidBanner) { _, newValue in
                        if newValue {
                            UserDefaults.standard.removeObject(forKey: eidBannerDismissKey)
                        } else {
                            UserDefaults.standard.set(true, forKey: eidBannerDismissKey)
                        }
                    }
            } header: {
                Text("Appearance")
            }

        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Sync appearance from ThemeManager (not available in init)
            if let scheme = themeManager.colorScheme {
                selectedAppearance = scheme == .light ? .light : .dark
            } else {
                selectedAppearance = .system
            }
        }
    }
}

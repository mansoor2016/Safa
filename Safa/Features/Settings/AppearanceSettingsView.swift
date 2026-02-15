// MARK: - AppearanceSettingsView.swift
// PURPOSE: Shared appearance + accessibility settings used by Settings menu
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

    // Accessibility state
    @State private var reduceMotionEnabled: Bool
    @State private var largerTextEnabled: Bool
    @State private var highContrastEnabled: Bool

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
        _reduceMotionEnabled = State(initialValue: prefs.reduceMotionEnabled)
        _largerTextEnabled = State(initialValue: prefs.largerArabicTextEnabled)
        _highContrastEnabled = State(initialValue: prefs.highContrastEnabled)

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

            // MARK: Accessibility Section
            Section {
                Toggle("Reduce Motion", isOn: $reduceMotionEnabled)
                    .onChange(of: reduceMotionEnabled) { _, newValue in
                        Task { await prefsManager.saveAccessibility(reduceMotion: newValue) }
                    }

                Toggle("Larger Arabic Text", isOn: $largerTextEnabled)
                    .onChange(of: largerTextEnabled) { _, newValue in
                        Task { await prefsManager.saveAccessibility(largerText: newValue) }
                    }

                Toggle("High Contrast", isOn: $highContrastEnabled)
                    .onChange(of: highContrastEnabled) { _, newValue in
                        Task { await prefsManager.saveAccessibility(highContrast: newValue) }
                    }
            } header: {
                Text("Accessibility")
            } footer: {
                Text("Accessibility features are not yet fully functional. Safa will support Dynamic Type, VoiceOver, and other iOS accessibility features in a future update.")
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

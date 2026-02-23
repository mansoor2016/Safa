// MARK: - LanguageSettingsView.swift
// PURPOSE: Language picker (app UI language) + Quran translation picker
// DEPENDENCIES: SwiftUI, PreferencesManager, AppLanguageManager, SupportedAppLanguage

import SwiftUI

struct LanguageSettingsView: View {
    // MARK: - State
    @State private var selectedTranslation: QuranTranslation
    @State private var appLanguageCode: String?
    @State private var showRestartAlert = false

    private let prefsManager = PreferencesManager.shared

    // MARK: - Init
    init() {
        let prefs = PreferencesManager.loadPreferencesSync()
        _selectedTranslation = State(initialValue: prefs.quranTranslation)
        // Read from the manager (synchronously updated) rather than prefs
        // (async save may not have completed if locale change triggered view rebuild)
        _appLanguageCode = State(initialValue: AppLanguageManager.shared.appLanguageCode)
    }

    // MARK: - Body
    var body: some View {
        List {
            appLanguageSection
            quranTranslationSection
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Restart Recommended", isPresented: $showRestartAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Some changes will take full effect after restarting the app.")
        }
    }

    // MARK: - App Language Section

    private var appLanguageSection: some View {
        Section {
            // Device Default row
            Button {
                selectLanguage(nil)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Device Default")
                            .font(.body)
                            .foregroundColor(.primary)
                        Text(AppLanguageManager.deviceLanguageDisplayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if appLanguageCode == nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }

            // Supported languages
            ForEach(SupportedAppLanguage.allCases) { language in
                Button {
                    selectLanguage(language.rawValue)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(language.nativeName)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text(language.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if appLanguageCode == language.rawValue {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        } header: {
            Text("App Language")
        } footer: {
            Text("Translations are in beta — community-contributed and may be incomplete or contain inaccuracies. English is used where translations are unavailable. Feedback is welcome.")
        }
    }

    // MARK: - Quran Translation Section

    private var quranTranslationSection: some View {
        Section {
            Picker("Translation", selection: $selectedTranslation) {
                ForEach(QuranTranslation.allCases) { translation in
                    Text(translation.fullDisplayName).tag(translation)
                }
            }
            .onChange(of: selectedTranslation) { _, newValue in
                Task { await prefsManager.update(\.quranTranslation, to: newValue) }
            }
        } header: {
            Text("Quran Translation")
        } footer: {
            Text("The translation shown alongside Arabic text in the Quran reader")
        }
    }

    // MARK: - Private Methods

    private func selectLanguage(_ code: String?) {
        appLanguageCode = code
        Task {
            await prefsManager.saveAppLanguage(code)

            // Re-schedule notifications in new language
            await NotificationScheduler.shared.forceReschedule()

            // Rewrite widget data with localized prayer names
            let prefs = PreferencesManager.loadPreferencesSync()
            let coords = Dependencies.shared.locationService.coordinates
                ?? prefs.savedCoordinates ?? AppDefaults.defaultCoordinates
            var prayers = Dependencies.shared.cachedTodayPrayers
            if prayers == nil {
                prayers = try? await Dependencies.shared.prayerRepository.getPrayers(
                    for: .now, location: coords,
                    method: prefs.calculationMethod, madhab: prefs.madhab)
            }
            if let prayers {
                WidgetDataService.shared.writePrayerTimes(prayers)
                WidgetDataService.shared.writePrayerNames(prayers)
            }
            WidgetDataService.shared.reloadWidgets()

            // Refresh Live Activity
            await PrayerLiveActivityManager.shared.ensureActivityIfNeeded()
        }
        showRestartAlert = true
    }
}

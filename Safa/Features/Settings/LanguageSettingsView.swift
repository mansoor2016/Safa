// MARK: - LanguageSettingsView.swift
// PURPOSE: Language and translation settings (app language info + Quran translation picker)
// DEPENDENCIES: SwiftUI, PreferencesManager, LanguageDisplayHelpers, QuranTranslation

import SwiftUI

struct LanguageSettingsView: View {
    // MARK: - State
    @State private var selectedTranslation: QuranTranslation

    private let prefsManager = PreferencesManager.shared

    // MARK: - Init
    init() {
        let prefs = PreferencesManager.loadPreferencesSync()
        _selectedTranslation = State(initialValue: prefs.quranTranslation)
    }

    // MARK: - Body
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Language")
                    Spacer()
                    Text(LanguageDisplayHelpers.displayName(
                        forLanguageCode: LanguageDisplayHelpers.currentAppLanguageCode()
                    ))
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                }
            } header: {
                Text("App Language")
            } footer: {
                Text("To change the app language, go to your device Settings \u{2192} Safa \u{2192} Language")
            }

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
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}

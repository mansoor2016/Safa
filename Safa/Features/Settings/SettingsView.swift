// MARK: - SettingsView.swift
// PURPOSE: App settings and preferences
// DEPENDENCIES: SwiftUI, PreferencesManager

import SwiftUI

struct SettingsView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCalculationMethod: CalculationMethod = AppDefaults.calculationMethod
    @State private var selectedMadhab: Madhab = AppDefaults.madhab
    @State private var notificationsEnabled = AppDefaults.notificationsEnabled
    @State private var adhanEnabled = true
    @State private var selectedAdhanSound = "Default"
    @State private var hapticFeedbackEnabled = AppDefaults.hapticFeedbackEnabled
    @State private var showArabicText = AppDefaults.showArabicText
    @State private var showTransliteration = AppDefaults.showTransliteration
    @State private var selectedTranslation = AppDefaults.translationLanguage
    @State private var selectedAccentColor: AccentColorOption = .teal
    @State private var showDeleteConfirmation = false

    // Accessibility state
    @State private var reduceMotionEnabled = false
    @State private var largerTextEnabled = false
    @State private var highContrastEnabled = false

    // Location state
    @State private var savedLocationName: String?
    @State private var locationContext: LocationContext?
    @State private var isUpdatingLocation = false
    @State private var showLocationRecommendations = false
    @State private var showInviteFriendsSheet = false

    private let prefsManager = PreferencesManager.shared

    var body: some View {
        List {
            locationSection
            prayerSettingsSection
            notificationSettingsSection
            quranSettingsSection
            appearanceSection
            accessibilitySection
            dataPrivacySection
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteAllData() }
            }
        } message: {
            Text("This will permanently delete all your progress, bookmarks, and chat history. This action cannot be undone.")
        }
        .sheet(isPresented: $showLocationRecommendations) {
            LocationRecommendationsSheet(
                context: locationContext,
                currentMethod: selectedCalculationMethod,
                currentMadhab: selectedMadhab,
                currentLanguage: selectedTranslation,
                onApply: { method, madhab, language in
                    Task {
                        selectedCalculationMethod = method
                        selectedMadhab = madhab
                        selectedTranslation = language
                        await prefsManager.saveLocationSettings(method: method, madhab: madhab, language: language)
                    }
                }
            )
        }
        .task {
            await loadSettings()
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
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

            if locationContext != nil {
                Button {
                    showLocationRecommendations = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("View Recommended Settings")
                        Spacer()
                        if hasNonRecommendedSettings {
                            Text("Available")
                                .font(SafaTypography.labelSmall)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        } header: {
            Text("Location")
        } footer: {
            Text("Your location is used to calculate accurate prayer times and recommend regional settings.")
        }
    }

    private var hasNonRecommendedSettings: Bool {
        guard let context = locationContext else { return false }
        return selectedCalculationMethod != context.recommendedMethod ||
               selectedMadhab != context.recommendedMadhab ||
               selectedTranslation != context.recommendedLanguage
    }

    // MARK: - Prayer Settings Section

    private var prayerSettingsSection: some View {
        Section {
            HStack {
                Picker("Calculation Method", selection: $selectedCalculationMethod) {
                    ForEach(CalculationMethod.allCases, id: \.self) { method in
                        Text(method.displayName).tag(method)
                    }
                }

                if let context = locationContext, selectedCalculationMethod == context.recommendedMethod {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            .onChange(of: selectedCalculationMethod) { _, newValue in
                Task { await prefsManager.saveCalculationMethod(newValue) }
            }

            HStack {
                Picker("Madhab (Asr)", selection: $selectedMadhab) {
                    ForEach(Madhab.allCases, id: \.self) { madhab in
                        Text(madhab.displayName).tag(madhab)
                    }
                }

                if let context = locationContext, selectedMadhab == context.recommendedMadhab {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            .onChange(of: selectedMadhab) { _, newValue in
                Task { await prefsManager.saveMadhab(newValue) }
            }

            NavigationLink {
                PrayerAdjustmentsView()
            } label: {
                HStack {
                    Text("Prayer Time Adjustments")
                    Spacer()
                    Text("0 min")
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
            }
        } header: {
            Text("Prayer Times")
        } footer: {
            if let context = locationContext {
                Text("Recommended for \(context.regionName): \(context.recommendedMethod.displayName)")
            } else {
                Text("Select the calculation method used by your local mosque for accurate prayer times.")
            }
        }
    }

    // MARK: - Notification Settings Section

    private var notificationSettingsSection: some View {
        Section {
            Toggle("Prayer Notifications", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, newValue in
                    Task { await prefsManager.saveNotificationsEnabled(newValue) }
                }

            if notificationsEnabled {
                Toggle("Adhan Sound", isOn: $adhanEnabled)

                if adhanEnabled {
                    Picker("Adhan Style", selection: $selectedAdhanSound) {
                        Text("Default").tag("Default")
                        Text("Makkah").tag("Makkah")
                        Text("Madinah").tag("Madinah")
                        Text("Silent").tag("Silent")
                    }
                }

                NavigationLink {
                    NotificationScheduleView()
                } label: {
                    Text("Notification Schedule")
                }
            }
        } header: {
            Text("Notifications")
        }
    }

    // MARK: - Quran Settings Section

    private var quranSettingsSection: some View {
        Section {
            Toggle("Show Arabic Text", isOn: $showArabicText)
                .onChange(of: showArabicText) { _, newValue in
                    Task { await prefsManager.saveQuranSettings(showArabic: newValue) }
                }

            Toggle("Show Transliteration", isOn: $showTransliteration)
                .onChange(of: showTransliteration) { _, newValue in
                    Task { await prefsManager.saveQuranSettings(showTransliteration: newValue) }
                }

            HStack {
                Picker("Translation", selection: $selectedTranslation) {
                    Text("English - Sahih International").tag("English")
                    Text("Arabic").tag("Arabic")
                    Text("Urdu - Ahmed Ali").tag("Urdu")
                    Text("Indonesian").tag("Indonesian")
                    Text("French").tag("French")
                    Text("Turkish").tag("Turkish")
                    Text("Bengali").tag("Bengali")
                }
                .onChange(of: selectedTranslation) { _, newValue in
                    Task { await prefsManager.saveTranslation(newValue) }
                }

                if let context = locationContext, selectedTranslation == context.recommendedLanguage {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            NavigationLink {
                FontSettingsView()
            } label: {
                Text("Font Settings")
            }
        } header: {
            Text("Quran")
        } footer: {
            if let context = locationContext, selectedTranslation != context.recommendedLanguage {
                Text("Recommended translation for \(context.regionName): \(context.recommendedLanguage)")
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section {
            Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                .onChange(of: hapticFeedbackEnabled) { _, newValue in
                    Task { await prefsManager.saveHapticFeedback(newValue) }
                }

            Picker("Accent Color", selection: $selectedAccentColor) {
                ForEach(AccentColorOption.allCases, id: \.self) { option in
                    HStack {
                        Circle()
                            .fill(option.color)
                            .frame(width: 20, height: 20)
                        Text(option.displayName)
                    }
                    .tag(option)
                }
            }
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Accessibility Section

    private var accessibilitySection: some View {
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

            NavigationLink {
                AccessibilityInfoView()
            } label: {
                Text("VoiceOver Tips")
            }
        } header: {
            Text("Accessibility")
        } footer: {
            Text("Safa supports Dynamic Type, VoiceOver, and other iOS accessibility features. These settings provide additional customization.")
        }
    }

    // MARK: - Data & Privacy Section

    private var dataPrivacySection: some View {
        Section {
            NavigationLink {
                DataExportView()
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
                    .foregroundColor(.red)
            }
        } header: {
            Text("Data & Privacy")
        } footer: {
            Text("Your data is stored locally and synced via iCloud. Safa does not collect or share personal data.")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            Button {
                showInviteFriendsSheet = true
            } label: {
                HStack {
                    Label("Share Safa", systemImage: "square.and.arrow.up")
                    Spacer()
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showInviteFriendsSheet) {
                InviteFriendsView()
            }

            NavigationLink {
                AcknowledgementsView()
            } label: {
                Text("Acknowledgements")
            }

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Text("Privacy Policy")
            }

            NavigationLink {
                TermsOfServiceView()
            } label: {
                Text("Terms of Service")
            }

            NavigationLink {
                RequestFeatureView()
            } label: {
                Text("Request a Feature")
            }

            NavigationLink {
                FeedbackView()
            } label: {
                Text("Send Feedback")
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Load/Save Methods

    private func loadSettings() async {
        let prefs = await prefsManager.getPreferences()
        selectedCalculationMethod = prefs.calculationMethod
        selectedMadhab = prefs.madhab
        selectedTranslation = prefs.selectedTranslation
        notificationsEnabled = prefs.notificationsEnabled
        hapticFeedbackEnabled = prefs.hapticFeedbackEnabled
        savedLocationName = prefs.savedLocationName

        // Load accessibility settings
        reduceMotionEnabled = prefs.reduceMotionEnabled
        largerTextEnabled = prefs.largerArabicTextEnabled
        highContrastEnabled = prefs.highContrastEnabled

        // Load location context if we have saved coordinates
        if let coords = prefs.savedCoordinates {
            locationContext = LocationInferenceService.shared.inferContextFast(from: coords)
        }
    }

    private func updateLocation() async {
        isUpdatingLocation = true
        do {
            let context = try await dependencies.locationService.getLocationContext()
            await MainActor.run {
                self.locationContext = context
                self.savedLocationName = context.regionName
                self.isUpdatingLocation = false
            }

            // Save location using PreferencesManager
            await prefsManager.saveLocation(
                name: context.regionName,
                latitude: context.coordinates.latitude,
                longitude: context.coordinates.longitude,
                countryCode: context.countryCode
            )
        } catch {
            await MainActor.run {
                self.isUpdatingLocation = false
            }
        }
    }

    private func deleteAllData() async {
        try? await dependencies.chatRepository.clearHistory()
        // Reset other data...
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
            .environment(Dependencies())
    }
}

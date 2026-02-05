// MARK: - SettingsView.swift
// PURPOSE: App settings and preferences
// DEPENDENCIES: SwiftUI

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

    // Location state
    @State private var savedLocationName: String?
    @State private var locationContext: LocationContext?
    @State private var isUpdatingLocation = false
    @State private var showLocationRecommendations = false

    var body: some View {
        List {
            // Location Section
            locationSection

            // Prayer Settings
            prayerSettingsSection

            // Notifications
            notificationSettingsSection

            // Quran Settings
            quranSettingsSection

            // Appearance
            appearanceSection

            // Data & Privacy
            dataPrivacySection

            // About
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
                        await saveAllLocationSettings(method: method, madhab: madhab, language: language)
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
            // Current location display
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

            // Update location button
            Button {
                Task { await updateLocation() }
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Update Location")
                }
            }
            .disabled(isUpdatingLocation)

            // Show recommendations if available
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
                Task { await saveCalculationMethod(newValue) }
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
                Task { await saveMadhab(newValue) }
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
                    Task { await saveNotificationSetting(newValue) }
                }

            if notificationsEnabled {
                Toggle("Adhan Sound", isOn: $adhanEnabled)
                    .onChange(of: adhanEnabled) { _, newValue in
                        Task { await saveAdhanSetting(newValue) }
                    }

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
                    Task { await saveQuranSetting("showArabic", value: newValue) }
                }

            Toggle("Show Transliteration", isOn: $showTransliteration)
                .onChange(of: showTransliteration) { _, newValue in
                    Task { await saveQuranSetting("showTransliteration", value: newValue) }
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
                    Task {
                        var prefs = await dependencies.userRepository.getPreferences()
                        prefs.selectedTranslation = newValue
                        try? await dependencies.userRepository.updatePreferences(prefs)
                    }
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
                    Task { await saveHapticSetting(newValue) }
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
            .onChange(of: selectedAccentColor) { _, newValue in
                Task { await saveAccentColor(newValue) }
            }
        } header: {
            Text("Appearance")
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

            NavigationLink {
                AcknowledgementsView()
            } label: {
                Text("Acknowledgements")
            }

            Link(destination: URL(string: "https://safa.app/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
            }

            Link(destination: URL(string: "https://safa.app/terms")!) {
                HStack {
                    Text("Terms of Service")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
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
        let prefs = await dependencies.userRepository.getPreferences()
        selectedCalculationMethod = prefs.calculationMethod
        selectedMadhab = prefs.madhab
        selectedTranslation = prefs.selectedTranslation
        notificationsEnabled = prefs.notificationsEnabled
        hapticFeedbackEnabled = prefs.hapticFeedbackEnabled
        savedLocationName = prefs.savedLocationName

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

            // Save location to preferences
            var prefs = await dependencies.userRepository.getPreferences()
            prefs.savedLocationName = context.regionName
            prefs.savedLatitude = context.coordinates.latitude
            prefs.savedLongitude = context.coordinates.longitude
            prefs.savedCountryCode = context.countryCode
            try? await dependencies.userRepository.updatePreferences(prefs)
        } catch {
            await MainActor.run {
                self.isUpdatingLocation = false
            }
        }
    }

    private func saveCalculationMethod(_ method: CalculationMethod) async {
        var prefs = await dependencies.userRepository.getPreferences()
        prefs.calculationMethod = method
        try? await dependencies.userRepository.updatePreferences(prefs)
    }

    private func saveMadhab(_ madhab: Madhab) async {
        var prefs = await dependencies.userRepository.getPreferences()
        prefs.madhab = madhab
        try? await dependencies.userRepository.updatePreferences(prefs)
    }

    private func saveAllLocationSettings(method: CalculationMethod, madhab: Madhab, language: String) async {
        var prefs = await dependencies.userRepository.getPreferences()
        prefs.calculationMethod = method
        prefs.madhab = madhab
        prefs.selectedTranslation = language
        try? await dependencies.userRepository.updatePreferences(prefs)
    }

    private func saveNotificationSetting(_ enabled: Bool) async {
        var prefs = await dependencies.userRepository.getPreferences()
        prefs.notificationsEnabled = enabled
        try? await dependencies.userRepository.updatePreferences(prefs)
    }

    private func saveAdhanSetting(_ enabled: Bool) async {
        // Save to preferences
    }

    private func saveQuranSetting(_ key: String, value: Bool) async {
        // Save to preferences
    }

    private func saveHapticSetting(_ enabled: Bool) async {
        var prefs = await dependencies.userRepository.getPreferences()
        prefs.hapticFeedbackEnabled = enabled
        try? await dependencies.userRepository.updatePreferences(prefs)
    }

    private func saveAccentColor(_ color: AccentColorOption) async {
        // Save to preferences
    }

    private func deleteAllData() async {
        // Clear all user data
        try? await dependencies.chatRepository.clearHistory()
        // Reset other data...
    }
}

// MARK: - Location Recommendations Sheet

private struct LocationRecommendationsSheet: View {
    let context: LocationContext?
    let currentMethod: CalculationMethod
    let currentMadhab: Madhab
    let currentLanguage: String
    let onApply: (CalculationMethod, Madhab, String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let context = context {
                    Section {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.accentColor)
                            Text(context.regionName)
                                .font(SafaTypography.titleMedium)
                        }
                    }

                    Section("Recommended Settings") {
                        recommendationRow(
                            title: "Calculation Method",
                            current: currentMethod.displayName,
                            recommended: context.recommendedMethod.displayName,
                            isMatching: currentMethod == context.recommendedMethod
                        )

                        recommendationRow(
                            title: "Madhab",
                            current: currentMadhab.displayName,
                            recommended: context.recommendedMadhab.displayName,
                            isMatching: currentMadhab == context.recommendedMadhab
                        )

                        recommendationRow(
                            title: "Translation",
                            current: currentLanguage,
                            recommended: context.recommendedLanguage,
                            isMatching: currentLanguage == context.recommendedLanguage
                        )
                    }

                    Section {
                        Button {
                            onApply(context.recommendedMethod, context.recommendedMadhab, context.recommendedLanguage)
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Apply All Recommendations")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .disabled(
                            currentMethod == context.recommendedMethod &&
                            currentMadhab == context.recommendedMadhab &&
                            currentLanguage == context.recommendedLanguage
                        )
                    }

                    Section {
                        Text("These recommendations are based on common practices in your region. You can always customize these settings to match your preference or local mosque.")
                            .font(SafaTypography.bodySmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                }
            }
            .navigationTitle("Recommendations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func recommendationRow(title: String, current: String, recommended: String, isMatching: Bool) -> some View {
        VStack(alignment: .leading, spacing: SafaSpacing.xs) {
            Text(title)
                .font(SafaTypography.labelMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            HStack {
                VStack(alignment: .leading) {
                    Text("Current: \(current)")
                        .font(SafaTypography.bodyMedium)
                    Text("Recommended: \(recommended)")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(.accentColor)
                }

                Spacer()

                if isMatching {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, SafaSpacing.xxs)
    }
}

// MARK: - Placeholder Views

private struct PrayerAdjustmentsView: View {
    var body: some View {
        List {
            ForEach(PrayerType.allCases) { prayer in
                if prayer.isObligatory {
                    Stepper("\(prayer.displayName): 0 min", value: .constant(0), in: -30...30)
                }
            }
        }
        .navigationTitle("Adjustments")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NotificationScheduleView: View {
    var body: some View {
        List {
            ForEach(PrayerType.allCases) { prayer in
                if prayer.isObligatory {
                    Toggle(prayer.displayName, isOn: .constant(true))
                }
            }
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FontSettingsView: View {
    @State private var arabicFontSize: Double = 28
    @State private var translationFontSize: Double = 16

    var body: some View {
        List {
            Section("Arabic") {
                VStack {
                    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                        .font(.system(size: arabicFontSize))
                    Slider(value: $arabicFontSize, in: 20...40, step: 2)
                }
            }

            Section("Translation") {
                VStack {
                    Text("In the name of Allah, the Most Gracious, the Most Merciful")
                        .font(.system(size: translationFontSize))
                    Slider(value: $translationFontSize, in: 12...24, step: 1)
                }
            }
        }
        .navigationTitle("Font Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DataExportView: View {
    var body: some View {
        VStack(spacing: SafaSpacing.lg) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Export Your Data")
                .font(SafaTypography.headlineMedium)

            Text("Download a copy of your Safa data including bookmarks, progress, and settings.")
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)
                .multilineTextAlignment(.center)

            Button("Export as JSON") {
                // Export functionality
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AcknowledgementsView: View {
    var body: some View {
        List {
            Section("Data Sources") {
                Text("Quran text from Tanzil.net")
                Text("Prayer time calculations from PrayTimes.org")
                Text("Hadith from Sunnah.com")
            }

            Section("Open Source") {
                Text("SwiftUI")
                Text("Core ML")
                Text("Core Location")
            }

            Section("Special Thanks") {
                Text("The Muslim developer community")
                Text("Beta testers and early users")
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FeedbackView: View {
    @State private var feedbackType = "Bug Report"
    @State private var feedbackText = ""

    var body: some View {
        Form {
            Picker("Type", selection: $feedbackType) {
                Text("Bug Report").tag("Bug Report")
                Text("Feature Request").tag("Feature Request")
                Text("General Feedback").tag("General Feedback")
            }

            Section("Description") {
                TextEditor(text: $feedbackText)
                    .frame(minHeight: 150)
            }

            Section {
                Button("Send Feedback") {
                    // Send feedback
                }
                .disabled(feedbackText.isEmpty)
            }
        }
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
            .environment(Dependencies())
    }
}

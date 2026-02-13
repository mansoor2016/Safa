// MARK: - SettingsView.swift
// PURPOSE: App settings and preferences
// DEPENDENCIES: SwiftUI, PreferencesManager

import SwiftUI

struct SettingsView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCalculationMethod: CalculationMethod = AppDefaults.calculationMethod
    @State private var selectedMadhab: Madhab = AppDefaults.madhab
    @State private var notificationsEnabled = AppDefaults.notificationsEnabled
    @State private var adhanEnabled = false
    @State private var selectedAdhan: AdhanSound = .misharyAlafasy
    @State private var smartAdhanEnabled = false
    @State private var iftarAdhanEnabled = false
    @State private var hapticFeedbackEnabled = AppDefaults.hapticFeedbackEnabled
    @State private var showArabicText = AppDefaults.showArabicText
    @State private var showTransliteration = AppDefaults.showTransliteration
    @State private var selectedTranslation = AppDefaults.translationLanguage
    @State private var autoScrollEnabled = false
    @State private var selectedAppearance: AppearanceOption = .system
    @State private var showDeleteConfirmation = false

    // Accessibility state
    @State private var reduceMotionEnabled = false
    @State private var largerTextEnabled = false
    @State private var highContrastEnabled = false

    // Location state
    @State private var savedLocationName: String?
    @State private var locationContext: LocationContext?
    @State private var isUpdatingLocation = false
    @State private var autoUpdateLocation = true
    @State private var showLocationRecommendations = false
    @State private var showInviteFriendsSheet = false
    @State private var showRamadanBanner = true
    @State private var showEidBanner = true

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

    var body: some View {
        List {
            shareSection
            locationSection
            prayerSettingsSection
            notificationSettingsSection
            quranSettingsSection
            appearanceSection
            accessibilitySection
            dataPrivacySection
            aboutSection
            #if DEBUG
            debugSection
            #endif
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
            .fullSheet()
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

            Toggle(isOn: $autoUpdateLocation) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-update prayer times")
                    Text("Update automatically when you travel to a new city")
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
                Picker("Method", selection: $selectedCalculationMethod) {
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
                    Task {
                        let result = await NotificationToggleHandler.handle(
                            enabled: newValue,
                            preferenceSaver: prefsManager,
                            scheduler: NotificationScheduler.shared
                        )
                        if result.showDisabledToast {
                            ToastService.shared.show(Toast(
                                message: String(localized: "All prayer notifications disabled"),
                                type: .info
                            ))
                        }
                    }
                }

            if notificationsEnabled {
                Toggle("Use Adhan Sound", isOn: $adhanEnabled)
                    .onChange(of: adhanEnabled) { _, newValue in
                        Task {
                            await prefsManager.update(\.adhanEnabled, to: newValue)
                        }
                    }

                if adhanEnabled {
                    Picker("Adhan", selection: $selectedAdhan) {
                        ForEach(AdhanSound.regularOptions) { sound in
                            VStack(alignment: .leading) {
                                Text(sound.displayName)
                                Text(sound.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(sound)
                        }
                    }
                    .onChange(of: selectedAdhan) { _, newValue in
                        Task {
                            await prefsManager.update(\.selectedAdhan, to: newValue.rawValue)
                        }
                    }

                    Toggle("Smart Adhan", isOn: $smartAdhanEnabled)
                        .onChange(of: smartAdhanEnabled) { _, newValue in
                            Task {
                                await prefsManager.update(\.smartAdhanEnabled, to: newValue)
                            }
                        }
                }
            }

            Toggle("Iftar Adhan (Ramadan Only)", isOn: $iftarAdhanEnabled)
                .onChange(of: iftarAdhanEnabled) { _, newValue in
                    Task {
                        await prefsManager.update(\.iftarAdhanEnabled, to: newValue)
                    }
                }
        } header: {
            Text("Notifications")
        } footer: {
            if iftarAdhanEnabled && !adhanEnabled {
                Text("During Ramadan, the adhan will play for Maghrib (Iftar) only.")
            } else if adhanEnabled && smartAdhanEnabled {
                Text("Adhan plays at home only. Standard tone elsewhere. Fajr uses a distinct adhan.")
            } else if adhanEnabled {
                Text("Fajr prayer uses a distinct adhan that includes \"Prayer is better than sleep\".")
            }
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
                Text("Translation")
                Spacer()
                Text("English - Sahih International")
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            DisabledFeatureRow(
                title: "More Translations",
                icon: "globe",
                feature: .moreTranslations
            )

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
        } footer: {
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
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
        } header: {
            Text("Accessibility")
        } footer: {
            Text("Accessibility features are not yet fully functional. Safa will support Dynamic Type, VoiceOver, and other iOS accessibility features in a future update.")
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

            NavigationLink {
                DataManagementView()
            } label: {
                Label("Manage Data", systemImage: "externaldrive")
            }

            NavigationLink {
                SystemStatusView()
            } label: {
                Label("System Status", systemImage: "heart.text.square")
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

    // MARK: - Share Section

    private var shareSection: some View {
        Section {
            Button {
                showInviteFriendsSheet = true
            } label: {
                HStack {
                    Label("Share Safa", systemImage: "square.and.arrow.up")
                        .foregroundColor(.accentColor)
                    Spacer()
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.pink)
                }
            }
            .sheet(isPresented: $showInviteFriendsSheet) {
                InviteFriendsView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(SafaSpacing.CornerRadius.xl)
            }
        } footer: {
            Text("Help others discover Safa")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            NavigationLink {
                AboutSafaView()
            } label: {
                Text("About Safa")
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
                FeedbackView()
            } label: {
                Text("Send Feedback")
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Debug Section

    #if DEBUG
    @State private var forceRamadan = false
    @State private var forceEidAlFitr = false
    @State private var forceEidAlAdha = false
    @State private var useBasicInlineHeader = false
    @State private var useAdaptiveTabBar = false
    @State private var isDeveloperExpanded = false

    private var debugSection: some View {
        Section {
            DisclosureGroup("Developer Settings", isExpanded: $isDeveloperExpanded) {
                Toggle("Force Ramadan Mode", isOn: $forceRamadan)
                    .onAppear {
                        forceRamadan = FeatureFlags.shared.isEnabled(.ramadanMode)
                    }
                    .onChange(of: forceRamadan) { _, newValue in
                        if newValue {
                            FeatureFlags.shared.setOverride(.ramadanMode, enabled: true)
                            // Clear dismiss key so banner appears on Home
                            UserDefaults.standard.removeObject(forKey: ramadanBannerDismissKey)
                        } else {
                            FeatureFlags.shared.removeOverride(.ramadanMode)
                        }
                    }

                Toggle("Force Eid al-Fitr", isOn: $forceEidAlFitr)
                    .onAppear {
                        forceEidAlFitr = FeatureFlags.shared.isEnabled(.forceEidAlFitr)
                    }
                    .onChange(of: forceEidAlFitr) { _, newValue in
                        if newValue {
                            FeatureFlags.shared.setOverride(.forceEidAlFitr, enabled: true)
                            // Turn off conflicting Eid
                            forceEidAlAdha = false
                            FeatureFlags.shared.removeOverride(.forceEidAlAdha)
                            // Clear dismiss key so banner appears on Home
                            UserDefaults.standard.removeObject(forKey: eidBannerDismissKey)
                        } else {
                            FeatureFlags.shared.removeOverride(.forceEidAlFitr)
                        }
                    }

                Toggle("Force Eid al-Adha", isOn: $forceEidAlAdha)
                    .onAppear {
                        forceEidAlAdha = FeatureFlags.shared.isEnabled(.forceEidAlAdha)
                    }
                    .onChange(of: forceEidAlAdha) { _, newValue in
                        if newValue {
                            FeatureFlags.shared.setOverride(.forceEidAlAdha, enabled: true)
                            // Turn off conflicting Eid
                            forceEidAlFitr = false
                            FeatureFlags.shared.removeOverride(.forceEidAlFitr)
                            // Clear dismiss key so banner appears on Home
                            UserDefaults.standard.removeObject(forKey: eidBannerDismissKey)
                        } else {
                            FeatureFlags.shared.removeOverride(.forceEidAlAdha)
                        }
                    }

                Toggle("Basic Inline Header", isOn: $useBasicInlineHeader)
                    .onAppear {
                        useBasicInlineHeader = FeatureFlags.shared.isEnabled(.basicInlineHeader)
                    }
                    .onChange(of: useBasicInlineHeader) { _, newValue in
                        if newValue {
                            FeatureFlags.shared.setOverride(.basicInlineHeader, enabled: true)
                        } else {
                            FeatureFlags.shared.removeOverride(.basicInlineHeader)
                        }
                    }

                Toggle("Adaptive Tab Bar", isOn: $useAdaptiveTabBar)
                    .onAppear {
                        useAdaptiveTabBar = FeatureFlags.shared.isEnabled(.adaptiveTabBar)
                    }
                    .onChange(of: useAdaptiveTabBar) { _, newValue in
                        if newValue {
                            FeatureFlags.shared.setOverride(.adaptiveTabBar, enabled: true)
                        } else {
                            FeatureFlags.shared.removeOverride(.adaptiveTabBar)
                        }
                    }

                Button("Reset Onboarding") {
                    Task {
                        var prefs = await dependencies.userRepository.getPreferences()
                        prefs.hasCompletedOnboarding = false
                        try? await dependencies.userRepository.updatePreferences(prefs)
                    }
                }
                .foregroundColor(.red)
            }
        } footer: {
            Text("Debug options only visible in development builds.")
        }
    }
    #endif

    // MARK: - Load/Save Methods

    private func loadSettings() async {
        let prefs = await prefsManager.getPreferences()
        selectedCalculationMethod = prefs.calculationMethod
        selectedMadhab = prefs.madhab
        selectedTranslation = prefs.selectedTranslation
        notificationsEnabled = prefs.notificationsEnabled
        hapticFeedbackEnabled = prefs.hapticFeedbackEnabled
        HapticFeedbackService.shared.setEnabled(prefs.hapticFeedbackEnabled)
        savedLocationName = prefs.savedLocationName

        // Load appearance from ThemeManager
        if let scheme = themeManager.colorScheme {
            selectedAppearance = scheme == .light ? .light : .dark
        } else {
            selectedAppearance = .system
        }
        // Load banner states (synced with HomeView dismiss keys)
        showRamadanBanner = !UserDefaults.standard.bool(forKey: ramadanBannerDismissKey)
        showEidBanner = !UserDefaults.standard.bool(forKey: eidBannerDismissKey)

        // Load adhan settings
        adhanEnabled = prefs.adhanEnabled
        selectedAdhan = AdhanSound(rawValue: prefs.selectedAdhan) ?? .misharyAlafasy
        smartAdhanEnabled = prefs.smartAdhanEnabled
        iftarAdhanEnabled = prefs.iftarAdhanEnabled

        // Load accessibility settings
        reduceMotionEnabled = prefs.reduceMotionEnabled
        largerTextEnabled = prefs.largerArabicTextEnabled
        highContrastEnabled = prefs.highContrastEnabled

        // Load Quran reader settings
        autoScrollEnabled = prefs.autoScrollEnabled

        // Load auto-update location setting
        autoUpdateLocation = prefs.autoUpdateLocationForPrayers

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
        let appGroupDefaults = UserDefaults(suiteName: AppConstants.appGroupId)
        DataDeletionService.deleteAllCategories(from: .standard, appGroupDefaults: appGroupDefaults)
        try? await dependencies.chatRepository.clearHistory()
        await dependencies.userState.loadUserData()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
            .environment(Dependencies())
    }
}

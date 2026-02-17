// MARK: - SettingsView.swift
// PURPOSE: Top-level settings menu with NavigationLinks to subpages
// DEPENDENCIES: SwiftUI, PreferencesManager

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(ThemeManager.self) private var themeManager

    // Summary state
    @State private var locationName = ""
    @State private var methodName = ""
    @State private var translationName = ""
    @State private var appearanceName = ""

    // Inline section state
    @State private var showDeleteConfirmation = false
    @State private var showInviteFriendsSheet = false
    @State private var showDeveloperSettings = false

    var body: some View {
        List {
            shareSection

            Section {
                settingsRow(
                    icon: "mappin.circle.fill",
                    iconColor: .accentColor,
                    title: "Location",
                    summary: locationName
                ) {
                    LocationSettingsView()
                }

                settingsRow(
                    icon: "clock.fill",
                    iconColor: .orange,
                    title: "Prayer Times",
                    summary: methodName
                ) {
                    PrayerSettingsView()
                }

                settingsRow(
                    icon: "bell.fill",
                    iconColor: .red,
                    title: "Notifications",
                    summary: nil
                ) {
                    NotificationSettingsView()
                }

                settingsRow(
                    icon: "book.fill",
                    iconColor: .green,
                    title: "Quran",
                    summary: nil
                ) {
                    QuranSettingsView()
                }

                settingsRow(
                    icon: "globe",
                    iconColor: .blue,
                    title: "Language",
                    summary: translationName
                ) {
                    LanguageSettingsView()
                }

                settingsRow(
                    icon: "paintbrush.fill",
                    iconColor: .purple,
                    title: "Appearance",
                    summary: appearanceName
                ) {
                    AppearanceSettingsView()
                }
            }

            dataPrivacySection
            aboutSection

            if showDeveloperSettings {
                debugSection
            }
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
        .onAppear { loadSummary() }
    }

    // MARK: - Settings Row Helper

    private func settingsRow<Destination: View>(
        icon: String,
        iconColor: Color,
        title: String,
        summary: String?,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: SafaSpacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24)

                Text(title)

                Spacer()

                if let summary {
                    Text(summary)
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - Summary

    private func loadSummary() {
        let prefs = PreferencesManager.loadPreferencesSync()
        locationName = prefs.savedLocationName ?? "Not set"
        methodName = prefs.calculationMethod.displayName
        translationName = prefs.quranTranslation.displayName

        if let scheme = themeManager.colorScheme {
            appearanceName = scheme == .light ? "Light" : "Dark"
        } else {
            appearanceName = "System"
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

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
                    .foregroundColor(.red)
            }
        } header: {
            Text("Data & Privacy")
        } footer: {
            Text("Your data is stored locally on your device. Safa does not collect or share personal data.")
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
            .contentShape(Rectangle())
            .onTapGesture(count: 3) {
                showDeveloperSettings.toggle()
                HapticFeedbackService.shared.play(.success)
                ToastService.shared.show(Toast(
                    message: showDeveloperSettings
                        ? String(localized: "Developer settings enabled")
                        : String(localized: "Developer settings hidden"),
                    type: .info
                ))
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

    // MARK: - Developer Section

    @State private var forceRamadan = false
    @State private var forceEidAlFitr = false
    @State private var forceEidAlAdha = false
    @State private var isDeveloperExpanded = false

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
                            forceEidAlAdha = false
                            FeatureFlags.shared.removeOverride(.forceEidAlAdha)
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
                            forceEidAlFitr = false
                            FeatureFlags.shared.removeOverride(.forceEidAlFitr)
                            UserDefaults.standard.removeObject(forKey: eidBannerDismissKey)
                        } else {
                            FeatureFlags.shared.removeOverride(.forceEidAlAdha)
                        }
                    }


                Button("Test Prayer Notification (5s)") {
                    Task {
                        let prefs = PreferencesManager.loadPreferencesSync()
                        let content = UNMutableNotificationContent()
                        content.title = "Test Notification"
                        content.body = "This is a test prayer notification"
                        if prefs.adhanEnabled {
                            let fileName = prefs.selectedAdhan
                            content.sound = UNNotificationSound(named: UNNotificationSoundName("\(fileName)_notification.caf"))
                        } else {
                            content.sound = .default
                        }
                        content.interruptionLevel = .timeSensitive
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                        let request = UNNotificationRequest(
                            identifier: "debug_test_notification",
                            content: content,
                            trigger: trigger
                        )
                        try? await UNUserNotificationCenter.current().add(request)
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
            Text("Triple-tap the version number to hide.")
        }
    }

    // MARK: - Actions

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

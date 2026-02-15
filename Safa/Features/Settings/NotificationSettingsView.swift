// MARK: - NotificationSettingsView.swift
// PURPOSE: Shared notification settings used by Settings menu
// DEPENDENCIES: SwiftUI, PreferencesManager, NotificationToggleHandler, PrayerLiveActivityManager

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    // MARK: - State
    @State private var notificationsEnabled: Bool
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var adhanEnabled: Bool
    @State private var selectedAdhan: AdhanSound
    @State private var smartAdhanEnabled: Bool
    @State private var iftarAdhanEnabled: Bool
    @State private var liveActivityEnabled: Bool

    private let prefsManager = PreferencesManager.shared

    // MARK: - Init
    init() {
        let prefs = PreferencesManager.loadPreferencesSync()
        _notificationsEnabled = State(initialValue: prefs.notificationsEnabled)
        _adhanEnabled = State(initialValue: prefs.adhanEnabled)
        _selectedAdhan = State(initialValue: AdhanSound(rawValue: prefs.selectedAdhan) ?? .misharyAlafasy)
        _smartAdhanEnabled = State(initialValue: prefs.smartAdhanEnabled)
        _iftarAdhanEnabled = State(initialValue: prefs.iftarAdhanEnabled)
        _liveActivityEnabled = State(initialValue: prefs.liveActivityEnabled)
    }

    // MARK: - Body
    var body: some View {
        List {
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

                if notificationsEnabled && notificationAuthStatus == .denied {
                    HStack(spacing: SafaSpacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Notifications are disabled in Settings")
                            .font(SafaTypography.bodySmall)
                            .foregroundColor(.orange)
                        Spacer()
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(SafaTypography.labelSmall)
                    }
                }

                if notificationsEnabled {
                    Toggle("Use Adhan Sound", isOn: $adhanEnabled)
                        .onChange(of: adhanEnabled) { _, newValue in
                            Task { await prefsManager.update(\.adhanEnabled, to: newValue) }
                            if newValue && notificationAuthStatus == .authorized {
                                showSilentModeTipIfNeeded()
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
                            Task { await prefsManager.update(\.selectedAdhan, to: newValue.rawValue) }
                        }

                        Toggle("Smart Adhan", isOn: $smartAdhanEnabled)
                            .onChange(of: smartAdhanEnabled) { _, newValue in
                                Task { await prefsManager.update(\.smartAdhanEnabled, to: newValue) }
                            }
                    }
                }

                Toggle("Iftar Adhan (Ramadan Only)", isOn: $iftarAdhanEnabled)
                    .onChange(of: iftarAdhanEnabled) { _, newValue in
                        Task { await prefsManager.update(\.iftarAdhanEnabled, to: newValue) }
                        if newValue && notificationsEnabled && notificationAuthStatus == .authorized {
                            showSilentModeTipIfNeeded()
                        }
                    }

                Toggle("Live Activity", isOn: $liveActivityEnabled)
                    .onChange(of: liveActivityEnabled) { _, newValue in
                        Task {
                            await prefsManager.saveLiveActivityEnabled(newValue)
                            if newValue {
                                await PrayerLiveActivityManager.shared.ensureActivityIfNeeded()
                            } else {
                                await PrayerLiveActivityManager.shared.endAllActivities()
                            }
                        }
                    }
            } header: {
                Text("Notifications")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    if iftarAdhanEnabled && !adhanEnabled {
                        Text("During Ramadan, the adhan will play for Maghrib (Iftar) only.")
                    } else if adhanEnabled && smartAdhanEnabled {
                        Text("Adhan plays at home only. Standard tone elsewhere. Fajr uses a distinct adhan.")
                    } else if adhanEnabled {
                        Text("Fajr prayer uses a distinct adhan that includes \"Prayer is better than sleep\".")
                    }
                    if notificationsEnabled && notificationAuthStatus != .denied && (adhanEnabled || iftarAdhanEnabled) {
                        Label("Adhan won't play when your iPhone is on silent mode.", systemImage: "speaker.slash")
                    }
                    Text("Live Activity shows the next prayer countdown on your Lock Screen and Dynamic Island.")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await checkNotificationAuth()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await checkNotificationAuth() }
        }
    }

    // MARK: - Private

    private func checkNotificationAuth() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationAuthStatus = settings.authorizationStatus
    }

    private func showSilentModeTipIfNeeded() {
        guard SilentModeTipService.shouldShowTip() else { return }
        SilentModeTipService.markTipShown()
        ToastService.shared.show(Toast(
            message: String(localized: "Make sure silent mode is off so the adhan plays aloud."),
            type: .info
        ))
    }
}

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
    @State private var iftarAdhanEnabled: Bool
    @State private var liveActivityEnabled: Bool
    @State private var wudhuReminderEnabled: Bool
    @State private var wudhuReminderMinutesBefore: Int
    @State private var rescheduleTask: Task<Void, Never>?
    @State private var prayerEndingSoonToastEnabled: Bool
    @State private var prayerEndingSoonMinutesBefore: Int
    @State private var dailyPrayerSummaryToastEnabled: Bool

    private let prefsManager = PreferencesManager.shared

    // MARK: - Init
    init() {
        let prefs = PreferencesManager.loadPreferencesSync()
        _notificationsEnabled = State(initialValue: prefs.notificationsEnabled)
        _adhanEnabled = State(initialValue: prefs.adhanEnabled)
        _selectedAdhan = State(initialValue: AdhanSound(rawValue: prefs.selectedAdhan) ?? .misharyAlafasy)
        _iftarAdhanEnabled = State(initialValue: prefs.iftarAdhanEnabled)
        _liveActivityEnabled = State(initialValue: prefs.liveActivityEnabled)
        _wudhuReminderEnabled = State(initialValue: prefs.wudhuReminderEnabled)
        _wudhuReminderMinutesBefore = State(initialValue: prefs.wudhuReminderMinutesBefore)
        _prayerEndingSoonToastEnabled = State(initialValue: prefs.prayerEndingSoonToastEnabled)
        _prayerEndingSoonMinutesBefore = State(initialValue: prefs.prayerEndingSoonMinutesBefore)
        _dailyPrayerSummaryToastEnabled = State(initialValue: prefs.dailyPrayerSummaryToastEnabled)
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
                    NotificationDeniedBanner()
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                if notificationsEnabled {
                    Toggle("Use Adhan Sound", isOn: $adhanEnabled)
                        .disabled(notificationAuthStatus == .denied)
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
                        .disabled(notificationAuthStatus == .denied)
                        .onChange(of: selectedAdhan) { _, newValue in
                            Task { await prefsManager.update(\.selectedAdhan, to: newValue.rawValue) }
                        }

                    }
                }

                Toggle("Iftar Adhan (Ramadan Only)", isOn: $iftarAdhanEnabled)
                    .disabled(notificationAuthStatus == .denied)
                    .onChange(of: iftarAdhanEnabled) { _, newValue in
                        Task { await prefsManager.update(\.iftarAdhanEnabled, to: newValue) }
                        if newValue && notificationsEnabled && notificationAuthStatus == .authorized {
                            showSilentModeTipIfNeeded()
                        }
                    }

                Toggle("Live Activity", isOn: $liveActivityEnabled)
                    .disabled(notificationAuthStatus == .denied)
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
                if notificationsEnabled && notificationAuthStatus != .denied && (adhanEnabled || iftarAdhanEnabled) {
                    Label("Adhan won't play when your iPhone is on silent mode.", systemImage: "speaker.slash")
                }
            }

            Section {
                Toggle("Wudhu Reminder", isOn: $wudhuReminderEnabled)
                    .onChange(of: wudhuReminderEnabled) { _, newValue in
                        Task { await prefsManager.update(\.wudhuReminderEnabled, to: newValue) }
                    }

                if wudhuReminderEnabled {
                    Picker("Remind Before", selection: $wudhuReminderMinutesBefore) {
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("20 minutes").tag(20)
                    }
                    .onChange(of: wudhuReminderMinutesBefore) { _, newValue in
                        Task { await prefsManager.update(\.wudhuReminderMinutesBefore, to: newValue) }
                    }
                }

                Toggle("Prayer Ending Soon", isOn: $prayerEndingSoonToastEnabled)
                    .onChange(of: prayerEndingSoonToastEnabled) { _, newValue in
                        Task { await prefsManager.update(\.prayerEndingSoonToastEnabled, to: newValue) }
                    }

                if prayerEndingSoonToastEnabled {
                    Picker("Remind Before", selection: $prayerEndingSoonMinutesBefore) {
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("20 minutes").tag(20)
                        Text("30 minutes").tag(30)
                    }
                    .onChange(of: prayerEndingSoonMinutesBefore) { _, newValue in
                        Task { await prefsManager.update(\.prayerEndingSoonMinutesBefore, to: newValue) }
                    }
                }

                Toggle("Daily Prayer Summary", isOn: $dailyPrayerSummaryToastEnabled)
                    .onChange(of: dailyPrayerSummaryToastEnabled) { _, newValue in
                        Task { await prefsManager.update(\.dailyPrayerSummaryToastEnabled, to: newValue) }
                    }
            } header: {
                Text("In-App Reminders")
            } footer: {
                Text("Gentle reminders shown inside the app. These are not push notifications.")
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

    private func debouncedReschedule() {
        rescheduleTask?.cancel()
        rescheduleTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await NotificationScheduler.shared.forceReschedule()
        }
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

// MARK: - OnboardingView.swift
// PURPOSE: Streamlined 4-page onboarding flow with location-based recommendations
// DEPENDENCIES: SwiftUI, CoreLocation, UserNotifications

import SwiftUI
import CoreLocation
import UserNotifications

struct OnboardingView: View {
    @Environment(Dependencies.self) private var dependencies
    @Binding var isOnboardingComplete: Bool

    @State private var currentPage = 0
    @State private var selectedMethod: CalculationMethod = AppDefaults.calculationMethod
    @State private var selectedMadhab: Madhab = AppDefaults.madhab
    /// Quran translation content language (location-inferred, e.g. "English", "Bahasa Indonesia")
    @State private var selectedLanguage: String = AppDefaults.translationLanguage
    /// App UI language override (nil = device default). Distinct from Quran translation above.
    @State private var selectedAppLanguage: SupportedAppLanguage?
    @State private var notificationsEnabled = AppDefaults.notificationsEnabled
    @State private var adhanEnabled = false
    @State private var selectedAdhan: AdhanSound = .misharyAlafasy
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined

    // Location inference
    @State private var locationContext: LocationContext?
    @State private var isLoadingLocation = false
    @State private var locationError: String?
    @State private var highLatitudeWarning: String?
    @State private var showCustomizeSettings = false

    private let totalPages = 4

    /// Location permission has been resolved (granted, denied, or restricted) — Apple guideline 5.1.1
    private var locationPermissionResolved: Bool {
        locationContext != nil || locationStatus == .denied || locationStatus == .restricted
            || locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Stable 3-region scaffold: progress → pages, footer in safe area inset
            VStack(spacing: 0) {
                progressIndicator
                    .padding(.top)
                    .padding(.bottom, SafaSpacing.sm)

                // Page content — TabView handles its own height, no GeometryReader
                TabView(selection: $currentPage) {
                    aboutPage.tag(0)
                    locationPage.tag(1)
                    quickSetupPage.tag(2)
                    readyPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { oldValue, newValue in
                    if !OnboardingHelpers.shouldAllowForwardNavigation(
                        from: oldValue,
                        to: newValue,
                        locationPermissionResolved: locationPermissionResolved
                    ) {
                        currentPage = oldValue
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                onboardingFooter
            }
        }
        .onAppear {
            locationStatus = dependencies.locationService.authorizationStatus
        }
        .task {
            await checkNotificationAuth()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await checkNotificationAuth() }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: SafaSpacing.xs) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(), value: currentPage)
            }
        }
    }

    // MARK: - Page 0: About

    private var aboutPage: some View {
        ScrollView {
            VStack(spacing: 32) {
                // App icon + name
                VStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.accentColor)

                    Text("Safa")
                        .font(.largeTitle.weight(.bold))

                    Text("صفا")
                        .font(.system(size: 28, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)

                    Text("Purity · Clarity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // Mission
                VStack(spacing: 16) {
                    Text("Safa is a comprehensive Islamic companion app designed with privacy, simplicity, and intelligence at its core.")
                        .font(.body)
                        .multilineTextAlignment(.center)

                    Text("No ads. No clutter. No tracking.")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)

                    Text("Just you and your faith.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Closing
                Text("Bismillah. May Safa be a means of benefit for you in this life and the next.")
                    .font(.subheadline)
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .padding()
        }
    }

    // MARK: - Page 1: Location

    private var locationPage: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .padding(.top, SafaSpacing.xl)

                VStack(spacing: SafaSpacing.xs) {
                    Text("Location")
                        .font(SafaTypography.headlineMedium)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text("Enable location for accurate prayer times")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                locationSection
                    .padding(.horizontal)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var locationSection: some View {
        VStack(spacing: SafaSpacing.sm) {
            if let context = locationContext {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.green)

                Text(context.regionName)
                    .font(SafaTypography.titleMedium)
                    .foregroundColor(SafaColors.Fallback.text)

                if let warning = highLatitudeWarning {
                    Text(warning)
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }

                Button {
                    locationContext = nil
                    highLatitudeWarning = nil
                    requestLocationPermission()
                } label: {
                    HStack(spacing: SafaSpacing.xs) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Update Location")
                    }
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(.accentColor)
                }
            } else {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)

                Text("Enable location for accurate prayer times")
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .multilineTextAlignment(.center)

                if let error = locationError {
                    Text(error)
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(.orange)

                    if OnboardingHelpers.shouldShowSettingsLink(locationStatus: locationStatus) {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Open Settings")
                                .font(SafaTypography.bodySmall)
                                .foregroundColor(.accentColor)
                        }
                    }
                }

                Button {
                    requestLocationPermission()
                } label: {
                    HStack {
                        if isLoadingLocation {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 4)
                        }
                        Text(isLoadingLocation ? "Detecting..." : "Enable Location")
                    }
                    .font(SafaTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, SafaSpacing.xl)
                    .padding(.vertical, SafaSpacing.sm)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
                }
                .disabled(isLoadingLocation)
            }
        }
    }

    // MARK: - Page 2: Notifications

    private var quickSetupPage: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .padding(.top, SafaSpacing.xl)

                VStack(spacing: SafaSpacing.xs) {
                    Text("Notifications")
                        .font(SafaTypography.headlineMedium)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text("Stay connected to your prayers")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                VStack(spacing: SafaSpacing.md) {
                    if locationContext != nil {
                        detectedSettingsSummary
                    }

                    // Notifications toggle (ON by default — user can opt out)
                    Toggle(isOn: $notificationsEnabled) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.accentColor)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Prayer Reminders")
                                    .font(SafaTypography.bodyMedium)
                                    .foregroundColor(SafaColors.Fallback.text)

                                Text("Get notified at prayer times")
                                    .font(SafaTypography.bodySmall)
                                    .foregroundColor(SafaColors.Fallback.tertiaryText)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))

                    if notificationsEnabled && notificationAuthStatus == .denied {
                        HStack(spacing: SafaSpacing.xs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
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
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
                    }

                    // Adhan sound (shown when notifications enabled)
                    if notificationsEnabled {
                        Toggle(isOn: $adhanEnabled) {
                            HStack {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundColor(.accentColor)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use Adhan Sound")
                                        .font(SafaTypography.bodyMedium)
                                        .foregroundColor(SafaColors.Fallback.text)

                                    Text("Play adhan for prayer notifications")
                                        .font(SafaTypography.bodySmall)
                                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))

                        if adhanEnabled {
                            Picker("Adhan Voice", selection: $selectedAdhan) {
                                ForEach(AdhanSound.regularOptions, id: \.self) { adhan in
                                    Text(adhan.displayName).tag(adhan)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
                        }
                    }
                }
                .padding(.horizontal)

                Text("You can customize calculation methods and more in the Settings")
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SafaSpacing.xl)
            }
            .padding()
        }
    }

    private var detectedSettingsSummary: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.sm) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)

                Text("Smart settings applied")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(SafaColors.Fallback.text)
            }

            HStack(spacing: SafaSpacing.lg) {
                settingSummaryItem(label: "Method", value: selectedMethod.shortName)
                settingSummaryItem(label: "Madhab", value: selectedMadhab.displayName)
            }

            if let context = locationContext {
                PrayerTimePreviewCard(
                    method: selectedMethod,
                    madhab: selectedMadhab,
                    location: context.coordinates,
                    date: Date()
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }

    private func settingSummaryItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.tertiaryText)
            Text(value)
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.text)
        }
    }

    // MARK: - Page 3: Ready

    private var readyPage: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                }
                .padding(.top, SafaSpacing.xl)

                VStack(spacing: SafaSpacing.xs) {
                    Text("Ready to Begin")
                        .font(SafaTypography.headlineMedium)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text("May your journey with Safa be blessed")
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                // Brief summary
                VStack(spacing: SafaSpacing.xs) {
                    if let context = locationContext {
                        summaryItem(icon: "mappin", value: context.regionName)
                    }
                    summaryItem(icon: "clock", value: selectedMethod.displayName)
                    summaryItem(icon: "person", value: selectedMadhab.displayName)
                    summaryItem(
                        icon: "globe",
                        value: selectedAppLanguage?.nativeName
                            ?? AppLanguageManager.deviceLanguageDisplayName
                    )
                    if notificationsEnabled {
                        summaryItem(icon: "bell", value: "Notifications On")
                        if adhanEnabled {
                            summaryItem(icon: "speaker.wave.2", value: "Adhan: \(selectedAdhan.displayName)")
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
                .padding(.horizontal, SafaSpacing.xl)

                // Customize Settings link
                Button {
                    showCustomizeSettings = true
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Customize Settings")
                    }
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(.accentColor)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showCustomizeSettings) {
            customizeSettingsSheet
                .fullSheet()
        }
    }

    // MARK: - Customize Settings Sheet

    private var customizeSettingsSheet: some View {
        NavigationStack {
            Form {
                Section("Prayer Calculation") {
                    Picker("Method", selection: $selectedMethod) {
                        ForEach(CalculationMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }

                    Picker("Madhab", selection: $selectedMadhab) {
                        ForEach(Madhab.allCases, id: \.self) { madhab in
                            Text(madhab.displayName).tag(madhab)
                        }
                    }

                    if let context = locationContext {
                        PrayerTimePreviewCard(
                            method: selectedMethod,
                            madhab: selectedMadhab,
                            location: context.coordinates,
                            date: Date()
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }

                Section {
                    Picker("Language", selection: $selectedAppLanguage) {
                        Text("Device Default").tag(SupportedAppLanguage?.none)
                        ForEach(SupportedAppLanguage.allCases) { lang in
                            Text(lang.nativeName).tag(SupportedAppLanguage?.some(lang))
                        }
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text("Translations are in beta and may be incomplete. English is used where unavailable.")
                }

                Section("Quran") {
                    HStack {
                        Text("Translation")
                        Spacer()
                        Text(AppDefaults.quranTranslation.fullDisplayName)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showCustomizeSettings = false
                    }
                }
            }
        }
    }

    private func summaryItem(icon: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)

            Text(value)
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.text)

            Spacer()
        }
    }

    // MARK: - Onboarding Footer

    private var onboardingFooter: some View {
        VStack(spacing: SafaSpacing.sm) {
            // "Get Started" CTA on page 3
            if currentPage == totalPages - 1 {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Get Started")
                        .font(SafaTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: SafaSpacing.ButtonHeight.lg)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
                }
            }

            // Back / Next row — shown on all non-final pages
            if currentPage < totalPages - 1 {
                HStack {
                    if currentPage > 0 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage -= 1
                            }
                        } label: {
                            Text("Back")
                                .font(SafaTypography.bodyMedium)
                                .foregroundColor(SafaColors.Fallback.secondaryText)
                                .frame(minWidth: 60, minHeight: SafaSpacing.ButtonHeight.md)
                                .contentShape(Rectangle())
                        }
                    }

                    Spacer()

                    if OnboardingHelpers.shouldAllowForwardNavigation(
                        from: currentPage,
                        to: currentPage + 1,
                        locationPermissionResolved: locationPermissionResolved
                    ) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        } label: {
                            HStack(spacing: SafaSpacing.xxs) {
                                Text("Next")
                                Image(systemName: "arrow.right")
                            }
                            .font(SafaTypography.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                            .frame(minWidth: 80, minHeight: SafaSpacing.ButtonHeight.md)
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, SafaSpacing.xl)
        .padding(.vertical, SafaSpacing.md)
        .frame(maxWidth: 560)
        .background(
            RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.xl)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }

    // MARK: - Methods

    private func checkNotificationAuth() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationAuthStatus = settings.authorizationStatus
    }

    private func requestLocationPermission() {
        if locationStatus == .notDetermined {
            dependencies.locationService.requestPermission()
        }

        isLoadingLocation = true
        locationError = nil

        Task {
            do {
                let context = try await dependencies.locationService.getLocationContext()

                await MainActor.run {
                    self.locationContext = context
                    self.locationStatus = dependencies.locationService.authorizationStatus

                    self.selectedMethod = context.recommendedMethod
                    self.selectedMadhab = context.recommendedMadhab
                    self.selectedLanguage = context.recommendedLanguage

                    self.highLatitudeWarning = LocationInferenceService.shared.highLatitudeWarning(for: context.coordinates)

                    self.isLoadingLocation = false
                }
            } catch {
                await MainActor.run {
                    self.locationError = "Could not detect location"
                    self.locationStatus = dependencies.locationService.authorizationStatus
                    self.isLoadingLocation = false
                }
            }
        }
    }

    private func skipOnboarding() {
        Task {
            let current = await dependencies.userRepository.getPreferences()
            let prefs = OnboardingHelpers.buildSkipPreferences(
                current: current,
                locationContext: locationContext
            )
            try? await dependencies.userRepository.updatePreferences(prefs)

            if prefs.notificationsEnabled {
                _ = await NotificationScheduler.shared.requestAuthorization()
                await NotificationScheduler.shared.forceReschedule()
            }

            await MainActor.run {
                withAnimation {
                    isOnboardingComplete = true
                }
            }
        }
    }

    private func completeOnboarding() {
        Task {
            var prefs = await dependencies.userRepository.getPreferences()
            prefs.calculationMethod = selectedMethod
            prefs.madhab = selectedMadhab
            prefs.selectedTranslation = selectedLanguage
            prefs.appLanguageCode = selectedAppLanguage?.rawValue
            prefs.notificationsEnabled = notificationsEnabled
            prefs.adhanEnabled = adhanEnabled && notificationsEnabled
            prefs.selectedAdhan = selectedAdhan.rawValue
            prefs.hasCompletedOnboarding = true

            if let context = locationContext {
                prefs.savedLocationName = context.regionName
                prefs.savedLatitude = context.coordinates.latitude
                prefs.savedLongitude = context.coordinates.longitude
                prefs.savedCountryCode = context.countryCode
                prefs.useLocationBasedDefaults = true
            }

            try? await dependencies.userRepository.updatePreferences(prefs)

            AppLanguageManager.shared.setLanguage(selectedAppLanguage?.rawValue)

            if notificationsEnabled {
                _ = await NotificationScheduler.shared.requestAuthorization()
                await NotificationScheduler.shared.forceReschedule()
            }

            await MainActor.run {
                withAnimation {
                    isOnboardingComplete = true
                }
            }
        }
    }
}

// MARK: - CalculationMethod Extension

extension CalculationMethod {
    var shortName: String {
        switch self {
        case .muslimWorldLeague: return "MWL"
        case .isna: return "ISNA"
        case .egypt: return "Egypt"
        case .makkah: return "Makkah"
        case .karachi: return "Karachi"
        case .tehran: return "Tehran"
        case .jafari: return "Jafari"
        case .dubai: return "Dubai"
        case .kuwait: return "Kuwait"
        case .qatar: return "Qatar"
        case .singapore: return "Singapore"
        case .turkey: return "Turkey"
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
        .environment(Dependencies())
}

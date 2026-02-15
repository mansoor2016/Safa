// MARK: - OnboardingView.swift
// PURPOSE: Streamlined 3-page onboarding flow with location-based recommendations
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
    @State private var selectedLanguage: String = AppDefaults.translationLanguage
    @State private var notificationsEnabled = AppDefaults.notificationsEnabled
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined

    // Location inference
    @State private var locationContext: LocationContext?
    @State private var isLoadingLocation = false
    @State private var locationError: String?
    @State private var highLatitudeWarning: String?
    @State private var showCustomizeSettings = false

    private let totalPages = 3

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
                    welcomeLocationPage.tag(0)
                    quickSetupPage.tag(1)
                    readyPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
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

    // MARK: - Page 1: Welcome + Location

    private var welcomeLocationPage: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.md) {
                // App branding
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                }
                .padding(.top, SafaSpacing.xl)

                VStack(spacing: SafaSpacing.xs) {
                    Text("صفا")
                        .font(SafaTypography.arabicLarge)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text("Your Islamic Companion")
                        .font(SafaTypography.bodyLarge)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                // Quick features list
                VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                    featureItem(icon: "nosign", text: "No ads, ever")
                    featureItem(icon: "hand.tap", text: "Easy to navigate")
                    featureItem(icon: "sparkles", text: "Islamic AI assistant")
                }
                .padding(.vertical, SafaSpacing.sm)

                // Location section
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

    private func featureItem(icon: String, text: String) -> some View {
        HStack(spacing: SafaSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            Text(text)
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.text)

            Spacer()
        }
        .padding(.horizontal, SafaSpacing.lg)
    }

    // MARK: - Page 2: Quick Setup

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

                    // Mosque mode info (future feature)
                    HStack {
                        Image(systemName: "building.columns")
                            .foregroundColor(.accentColor)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mosque Mode")
                                .font(SafaTypography.bodyMedium)
                                .foregroundColor(SafaColors.Fallback.text)

                            Text("Location based auto-silence")
                                .font(SafaTypography.bodySmall)
                                .foregroundColor(SafaColors.Fallback.tertiaryText)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
                    .disabledFeature(isDisabled: true, name: "Mosque Mode")
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
                    if notificationsEnabled {
                        summaryItem(icon: "bell", value: "Notifications On")
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

                    Picker("Madhab (Asr Time)", selection: $selectedMadhab) {
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

                Section("Quran") {
                    HStack {
                        Text("Translation")
                        Spacer()
                        Text("English - Sahih International")
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

            // Skip / Back / Next row
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
                    } else {
                        Button {
                            skipOnboarding()
                        } label: {
                            Text("Skip")
                                .font(SafaTypography.bodyMedium)
                                .foregroundColor(SafaColors.Fallback.secondaryText)
                                .frame(minWidth: 60, minHeight: SafaSpacing.ButtonHeight.md)
                                .contentShape(Rectangle())
                        }
                    }

                    Spacer()

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
            prefs.notificationsEnabled = notificationsEnabled
            prefs.hasCompletedOnboarding = true

            if let context = locationContext {
                prefs.savedLocationName = context.regionName
                prefs.savedLatitude = context.coordinates.latitude
                prefs.savedLongitude = context.coordinates.longitude
                prefs.savedCountryCode = context.countryCode
                prefs.useLocationBasedDefaults = true
            }

            try? await dependencies.userRepository.updatePreferences(prefs)

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

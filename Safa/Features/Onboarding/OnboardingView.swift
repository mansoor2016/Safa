// MARK: - OnboardingView.swift
// PURPOSE: First-time user onboarding flow with location-based recommendations
// DEPENDENCIES: SwiftUI, CoreLocation

import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @Environment(Dependencies.self) private var dependencies
    @Binding var isOnboardingComplete: Bool

    @State private var currentPage = 0
    @State private var selectedMethod: CalculationMethod = AppDefaults.calculationMethod
    @State private var selectedMadhab: Madhab = AppDefaults.madhab
    @State private var selectedLanguage: String = AppDefaults.translationLanguage
    @State private var notificationsEnabled = true
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined

    // Location inference
    @State private var locationContext: LocationContext?
    @State private var isLoadingLocation = false
    @State private var locationError: String?
    @State private var highLatitudeWarning: String?
    @State private var useRecommendedSettings = true

    private let totalPages = 5

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                // Progress indicator
                progressIndicator
                    .padding(.top)

                // Page content
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    locationPage.tag(1)
                    prayerSettingsPage.tag(2)
                    notificationPage.tag(3)
                    completionPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Navigation buttons
                navigationButtons
                    .padding()
            }
        }
        .onAppear {
            locationStatus = dependencies.locationService.authorizationStatus
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

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: SafaSpacing.xl) {
            Spacer()

            // App icon placeholder
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
            }

            VStack(spacing: SafaSpacing.sm) {
                // Arabic app name - prominent
                Text("صفا")
                    .font(SafaTypography.arabicLarge)
                    .foregroundColor(SafaColors.Fallback.text)

                // English subtitle
                Text("Safa")
                    .font(SafaTypography.titleMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)

                Text("Your comprehensive Islamic companion")
                    .font(SafaTypography.bodyLarge)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            // Features preview
            VStack(alignment: .leading, spacing: SafaSpacing.md) {
                featureRow(icon: "clock", title: "Prayer Times", description: "Accurate times with notifications")
                featureRow(icon: "book", title: "Quran", description: "Read, listen, and learn")
                featureRow(icon: "sparkles", title: "AI Companion", description: "Get answers to Islamic questions")
                featureRow(icon: "chart.line.uptrend.xyaxis", title: "Progress", description: "Track your spiritual growth")
            }
            .padding(.horizontal, SafaSpacing.lg)

            Spacer()
        }
        .padding()
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: SafaSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                Text(title)
                    .font(SafaTypography.bodyLarge)
                    .foregroundColor(SafaColors.Fallback.text)

                Text(description)
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            Spacer()
        }
    }

    // MARK: - Location Page

    private var locationPage: some View {
        VStack(spacing: SafaSpacing.xl) {
            Spacer()

            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            VStack(spacing: SafaSpacing.sm) {
                Text("Location Access")
                    .font(SafaTypography.headlineMedium)
                    .foregroundColor(SafaColors.Fallback.text)

                Text("We need your location to calculate accurate prayer times and recommend the best settings for your region.")
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Location status and detected location
            VStack(spacing: SafaSpacing.md) {
                locationStatusView

                // Show detected location if available
                if let context = locationContext {
                    detectedLocationView(context)
                }

                // High latitude warning
                if let warning = highLatitudeWarning {
                    highLatitudeWarningView(warning)
                }

                // Error message
                if let error = locationError {
                    Text(error)
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // Location button
            Button {
                requestLocationPermission()
            } label: {
                HStack {
                    if isLoadingLocation {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 4)
                    }
                    Text(locationButtonText)
                }
                .font(SafaTypography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(locationButtonColor)
                .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
            }
            .disabled(isLoadingLocation || locationContext != nil)
        }
        .padding()
    }

    private var locationButtonText: String {
        if isLoadingLocation {
            return "Detecting Location..."
        } else if locationContext != nil {
            return "Location Detected"
        } else if locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways {
            return "Detect My Location"
        } else {
            return "Enable Location"
        }
    }

    private var locationButtonColor: Color {
        if locationContext != nil {
            return .green
        } else {
            return .accentColor
        }
    }

    private var locationStatusView: some View {
        HStack {
            Image(systemName: locationStatusIcon)
                .foregroundColor(locationStatusColor)

            Text(locationStatusText)
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }

    private func detectedLocationView(_ context: LocationContext) -> some View {
        VStack(spacing: SafaSpacing.sm) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.green)
                Text("Prayer times for")
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            Text(context.regionName)
                .font(SafaTypography.titleMedium)
                .foregroundColor(SafaColors.Fallback.text)

            // Show recommended settings preview
            HStack(spacing: SafaSpacing.lg) {
                VStack {
                    Text(context.recommendedMethod.shortName)
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(.accentColor)
                    Text("Method")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }

                VStack {
                    Text(context.recommendedMadhab.displayName)
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(.accentColor)
                    Text("Madhab")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }

                VStack {
                    Text(context.recommendedLanguage)
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(.accentColor)
                    Text("Language")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }

    private func highLatitudeWarningView(_ warning: String) -> some View {
        HStack(alignment: .top, spacing: SafaSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(warning)
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }

    private var locationStatusIcon: String {
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return "checkmark.circle.fill"
        case .denied, .restricted: return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }

    private var locationStatusColor: Color {
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return .green
        case .denied, .restricted: return .red
        default: return .orange
        }
    }

    private var locationStatusText: String {
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return locationContext != nil ? "Location detected" : "Tap to detect location"
        case .denied: return "Location access denied"
        case .restricted: return "Location access restricted"
        default: return "Location permission required"
        }
    }

    // MARK: - Prayer Settings Page

    private var prayerSettingsPage: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.xl) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                    .padding(.top, SafaSpacing.xl)

                VStack(spacing: SafaSpacing.sm) {
                    Text("Prayer Settings")
                        .font(SafaTypography.headlineMedium)
                        .foregroundColor(SafaColors.Fallback.text)

                    if locationContext != nil {
                        Text("We've recommended settings based on your location. You can adjust them below.")
                            .font(SafaTypography.bodyMedium)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Choose your preferred calculation method and madhab for accurate prayer times.")
                            .font(SafaTypography.bodyMedium)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }

                // Use recommended toggle (if location context available)
                if locationContext != nil {
                    Toggle(isOn: $useRecommendedSettings) {
                        VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                            Text("Use Recommended Settings")
                                .font(SafaTypography.bodyLarge)
                                .foregroundColor(SafaColors.Fallback.text)

                            Text("Based on \(locationContext?.regionName ?? "your location")")
                                .font(SafaTypography.bodySmall)
                                .foregroundColor(SafaColors.Fallback.secondaryText)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
                    .onChange(of: useRecommendedSettings) { _, newValue in
                        if newValue, let context = locationContext {
                            selectedMethod = context.recommendedMethod
                            selectedMadhab = context.recommendedMadhab
                            selectedLanguage = context.recommendedLanguage
                        }
                    }
                }

                VStack(spacing: SafaSpacing.md) {
                    // Calculation Method
                    VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                        HStack {
                            Text("Calculation Method")
                                .font(SafaTypography.labelMedium)
                                .foregroundColor(SafaColors.Fallback.secondaryText)

                            if let context = locationContext, selectedMethod == context.recommendedMethod {
                                recommendedBadge
                            }
                        }

                        Picker("Method", selection: $selectedMethod) {
                            ForEach(CalculationMethod.allCases, id: \.self) { method in
                                Text(method.displayName).tag(method)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
                        .disabled(useRecommendedSettings && locationContext != nil)
                    }

                    // Madhab
                    VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                        HStack {
                            Text("Madhab (for Asr time)")
                                .font(SafaTypography.labelMedium)
                                .foregroundColor(SafaColors.Fallback.secondaryText)

                            if let context = locationContext, selectedMadhab == context.recommendedMadhab {
                                recommendedBadge
                            }
                        }

                        Picker("Madhab", selection: $selectedMadhab) {
                            ForEach(Madhab.allCases, id: \.self) { madhab in
                                Text(madhab.displayName).tag(madhab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(useRecommendedSettings && locationContext != nil)
                    }

                    // Translation Language
                    VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                        HStack {
                            Text("Translation Language")
                                .font(SafaTypography.labelMedium)
                                .foregroundColor(SafaColors.Fallback.secondaryText)

                            if let context = locationContext, selectedLanguage == context.recommendedLanguage {
                                recommendedBadge
                            }
                        }

                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(availableLanguages, id: \.self) { language in
                                Text(language).tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
                        .disabled(useRecommendedSettings && locationContext != nil)
                    }
                }
                .padding()

                Spacer(minLength: SafaSpacing.xl)
            }
            .padding()
        }
    }

    private var recommendedBadge: some View {
        Text("Recommended")
            .font(SafaTypography.labelSmall)
            .foregroundColor(.white)
            .padding(.horizontal, SafaSpacing.xs)
            .padding(.vertical, 2)
            .background(Color.green)
            .clipShape(Capsule())
    }

    private var availableLanguages: [String] {
        ["English", "Arabic", "Urdu", "Turkish", "French", "Indonesian", "Bengali"]
    }

    // MARK: - Notification Page

    private var notificationPage: some View {
        VStack(spacing: SafaSpacing.xl) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            VStack(spacing: SafaSpacing.sm) {
                Text("Prayer Reminders")
                    .font(SafaTypography.headlineMedium)
                    .foregroundColor(SafaColors.Fallback.text)

                Text("Get notified when it's time to pray. You can customize which prayers you want to be reminded about.")
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Toggle(isOn: $notificationsEnabled) {
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text("Enable Notifications")
                        .font(SafaTypography.bodyLarge)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text("Receive prayer time reminders")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
            .padding(.horizontal)

            if notificationsEnabled {
                VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                    ForEach(PrayerType.allCases) { prayer in
                        if prayer.isObligatory {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(prayer.displayName)
                                    .font(SafaTypography.bodyMedium)
                            }
                        }
                    }
                }
                .padding()
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Completion Page

    private var completionPage: some View {
        VStack(spacing: SafaSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            }

            VStack(spacing: SafaSpacing.sm) {
                Text("You're All Set!")
                    .font(SafaTypography.headlineMedium)
                    .foregroundColor(SafaColors.Fallback.text)

                Text("Begin your journey with Safa. May your prayers be answered and your knowledge increase.")
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Summary
            if let context = locationContext {
                VStack(spacing: SafaSpacing.sm) {
                    summaryRow(icon: "mappin", title: "Location", value: context.regionName)
                    summaryRow(icon: "clock", title: "Method", value: selectedMethod.displayName)
                    summaryRow(icon: "book", title: "Madhab", value: selectedMadhab.displayName)
                    summaryRow(icon: "globe", title: "Language", value: selectedLanguage)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
            }

            Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                .font(SafaTypography.arabicMedium)
                .foregroundColor(SafaColors.Fallback.text)
                .padding()

            Spacer()

            Button {
                completeOnboarding()
            } label: {
                Text("Get Started")
                    .font(SafaTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
            }
        }
        .padding()
    }

    private func summaryRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            Text(title)
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            Spacer()

            Text(value)
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.text)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack {
            // Skip/Back button
            if currentPage > 0 && currentPage < totalPages - 1 {
                Button("Back") {
                    withAnimation {
                        currentPage -= 1
                    }
                }
                .foregroundColor(SafaColors.Fallback.secondaryText)
            } else if currentPage == 0 {
                Button("Skip") {
                    completeOnboarding()
                }
                .foregroundColor(SafaColors.Fallback.secondaryText)
            } else {
                Spacer()
            }

            Spacer()

            // Next button (hidden on last page)
            if currentPage < totalPages - 1 {
                Button {
                    withAnimation {
                        currentPage += 1
                    }
                } label: {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
    }

    // MARK: - Methods

    private func requestLocationPermission() {
        // First request permission if needed
        if locationStatus == .notDetermined {
            dependencies.locationService.requestPermission()
        }

        // Then try to get location and infer context
        isLoadingLocation = true
        locationError = nil

        Task {
            do {
                let context = try await dependencies.locationService.getLocationContext()

                await MainActor.run {
                    self.locationContext = context
                    self.locationStatus = dependencies.locationService.authorizationStatus

                    // Apply recommended settings
                    self.selectedMethod = context.recommendedMethod
                    self.selectedMadhab = context.recommendedMadhab
                    self.selectedLanguage = context.recommendedLanguage

                    // Check for high latitude warning
                    self.highLatitudeWarning = LocationInferenceService.shared.highLatitudeWarning(for: context.coordinates)

                    self.isLoadingLocation = false
                }
            } catch {
                await MainActor.run {
                    self.locationError = "Unable to detect location. You can set your preferences manually."
                    self.locationStatus = dependencies.locationService.authorizationStatus
                    self.isLoadingLocation = false
                }
            }
        }
    }

    private func completeOnboarding() {
        Task {
            // Save preferences
            var prefs = await dependencies.userRepository.getPreferences()
            prefs.calculationMethod = selectedMethod
            prefs.madhab = selectedMadhab
            prefs.selectedTranslation = selectedLanguage
            prefs.notificationsEnabled = notificationsEnabled
            prefs.hasCompletedOnboarding = true

            // Save location data if available
            if let context = locationContext {
                prefs.savedLocationName = context.regionName
                prefs.savedLatitude = context.coordinates.latitude
                prefs.savedLongitude = context.coordinates.longitude
                prefs.savedCountryCode = context.countryCode
                prefs.useLocationBasedDefaults = useRecommendedSettings
            }

            try? await dependencies.userRepository.updatePreferences(prefs)

            // Request notification permission if enabled
            if notificationsEnabled {
                try? await dependencies.notificationService.requestAuthorization()
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
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
        .environment(Dependencies())
}

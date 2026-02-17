// MARK: - SettingsSubviews.swift
// PURPOSE: Subviews for Settings (Privacy, Terms, About, Request Feature)
// DEPENDENCIES: SwiftUI, MessageUI

import SwiftUI
import MessageUI

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                section(title: "Data Stored on Your Device") {
                    bulletPoint("Location coordinates (for prayer times) — saved locally, never sent to servers")
                    bulletPoint("User preferences (calculation method, theme) — stored locally")
                    bulletPoint("Prayer logs, Quran progress, streaks — stored locally")
                    bulletPoint("Chat conversations with AI — processed on-device, never sent to servers")
                }

                section(title: "Permissions") {
                    bulletPoint("Location: calculates prayer times and Qibla direction")
                    bulletPoint("Microphone & Speech: optional Arabic pronunciation practice (on-device only)")
                    bulletPoint("HealthKit: optional Ramadan fasting sync (write-only, never shared)")
                    bulletPoint("Notifications: local prayer reminders (no marketing)")
                }

                section(title: "Network Connections") {
                    bulletPoint("Core features work entirely offline")
                    bulletPoint("Quran audio downloaded from quranicaudio.com and islamic.network")
                    bulletPoint("No personal data is sent — only audio files are downloaded")
                    bulletPoint("No analytics, advertising, or tracking SDKs")
                }

                section(title: "Data Sharing") {
                    Text("We do not sell, trade, or share your personal information with anyone. Period.")
                        .font(.body)
                }

                section(title: "Your Rights") {
                    bulletPoint("Delete specific data categories from Settings > Data Management")
                    bulletPoint("Export all data as JSON or prayer logs as CSV")
                    bulletPoint("Revoke any permission without losing core functionality")
                }

                section(title: "Contact") {
                    Text("Questions? Email us at helpmesafa@gmail.com")
                        .font(.body)
                }

                Text("Last updated: February 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Privacy Matters")
                .font(.title2.weight(.bold))

            Text("Safa is built with privacy at its core. We believe your spiritual journey is personal and should stay that way.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content()
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.body)
        }
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                section(title: "Agreement to Terms") {
                    Text("By using Safa, you agree to these terms. If you disagree, please do not use the app.")
                        .font(.body)
                }

                section(title: "Description of Service") {
                    bulletPoint("Prayer times based on your location")
                    bulletPoint("Quran text with translations")
                    bulletPoint("Hadith collections and duas")
                    bulletPoint("AI companion for Islamic questions")
                    bulletPoint("Learning tools for Arabic and Tajweed")
                    bulletPoint("Progress tracking and gamification")
                }

                section(title: "Important Disclaimers") {
                    VStack(alignment: .leading, spacing: 12) {
                        disclaimerItem(
                            title: "Religious Guidance",
                            content: "Safa is a tool for learning and practice, not a replacement for qualified Islamic scholarship. Consult scholars for personal religious rulings."
                        )

                        disclaimerItem(
                            title: "Prayer Times",
                            content: "Prayer times are calculated using established algorithms. Verify important prayers with local mosques, especially during Ramadan."
                        )

                        disclaimerItem(
                            title: "AI Companion",
                            content: "The AI provides educational information but is not a scholar, mufti, or religious authority."
                        )
                    }
                }

                section(title: "Limitation of Liability") {
                    Text("Safa is provided \"as is\" without warranty. We are not liable for spiritual decisions, missed prayers due to technical issues, or any indirect damages.")
                        .font(.body)
                }

                section(title: "Contact") {
                    Text("Questions? Email us at helpmesafa@gmail.com")
                        .font(.body)
                }

                Text("Last updated: February 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Terms of Service")
                .font(.title2.weight(.bold))

            Text("Please read these terms carefully before using Safa.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content()
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.body)
        }
    }

    private func disclaimerItem(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - About View

struct AboutView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        List {
            // App Info Section
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.accentColor)

                    VStack(spacing: 4) {
                        Text("Safa")
                            .font(.title.weight(.bold))

                        Text("Your Islamic Companion")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            // Links Section
            Section {
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label("Privacy Policy", systemImage: "lock.shield")
                }

                NavigationLink {
                    TermsOfServiceView()
                } label: {
                    Label("Terms of Service", systemImage: "doc.text")
                }

                NavigationLink {
                    AcknowledgementsView()
                } label: {
                    Label("Acknowledgements", systemImage: "heart")
                }
            }

            // Support Section
            Section {
                NavigationLink {
                    FeedbackView()
                } label: {
                    Label("Send Feedback", systemImage: "envelope")
                }

                Link(destination: AppConstants.URLs.support) {
                    HStack {
                        Label("Help & Support", systemImage: "questionmark.circle")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                Text("Support")
            }

            // Share Section
            Section {
                Button {
                    shareApp()
                } label: {
                    Label("Share Safa", systemImage: "square.and.arrow.up")
                }

                Link(destination: AppConstants.URLs.downloadURL) {
                    HStack {
                        Label("Rate on App Store", systemImage: "star")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                Text("Spread the Word")
            }

            // Credits
            Section {
                Text("Made with love for the Ummah")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
    }

    private func shareApp() {
        let message = InviteFriendsService.shared.shareMessage
        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Mail Composer View

struct MailComposerView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let recipient: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Previews

#Preview("Privacy Policy") {
    NavigationStack {
        PrivacyPolicyView()
    }
}

#Preview("Terms of Service") {
    NavigationStack {
        TermsOfServiceView()
    }
}

#Preview("About") {
    NavigationStack {
        AboutView()
    }
}

// MARK: - Acknowledgements View

struct AcknowledgementsView: View {
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

// MARK: - Accessibility Info View

struct AccessibilityInfoView: View {
    var body: some View {
        List {
            Section("VoiceOver Support") {
                VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                    Label("Prayer Times", systemImage: "clock")
                        .font(SafaTypography.bodyMedium)
                    Text("Each prayer time is announced with the prayer name, time, and completion status. The log button describes its function.")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
                .padding(.vertical, SafaSpacing.xs)

                VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                    Label("Qibla Compass", systemImage: "location.north")
                        .font(SafaTypography.bodyMedium)
                    Text("VoiceOver announces the direction to turn and tells you when you're facing the Qibla.")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
                .padding(.vertical, SafaSpacing.xs)

                VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                    Label("Tasbeeh Counter", systemImage: "circle.circle")
                        .font(SafaTypography.bodyMedium)
                    Text("The counter announces the current count, target, and percentage complete. The main button describes the dhikr being counted.")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
                .padding(.vertical, SafaSpacing.xs)

                VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                    Label("Quran Reader", systemImage: "book")
                        .font(SafaTypography.bodyMedium)
                    Text("Each surah is announced with its number, name, revelation type, and verse count. Arabic text uses proper right-to-left reading.")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
                .padding(.vertical, SafaSpacing.xs)
            }

            Section("Tips") {
                Text("• Use rotor to navigate between headings and buttons")
                Text("• Three-finger swipe to navigate between pages")
                Text("• Double-tap and hold on the tasbeeh button for rapid counting")
                Text("• Enable \"Speak Screen\" to have the Quran read aloud")
            }

            Section("System Accessibility") {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Text("Open iOS Accessibility Settings")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                    }
                }
            }
        }
        .navigationTitle("Accessibility Tips")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Location Recommendations Sheet

struct LocationRecommendationsSheet: View {
    let context: LocationContext?
    let currentMethod: CalculationMethod
    let currentMadhab: Madhab
    let currentLanguage: String
    let coordinates: Coordinates?
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

                        Text(context.recommendedMethod.methodDescription)
                            .font(.caption)
                            .foregroundColor(SafaColors.Fallback.secondaryText)

                        recommendationRow(
                            title: "Madhab",
                            current: currentMadhab.displayName,
                            recommended: context.recommendedMadhab.displayName,
                            isMatching: currentMadhab == context.recommendedMadhab
                        )

                        recommendationRow(
                            title: "Region Language",
                            current: currentLanguage,
                            recommended: context.recommendedLanguage,
                            isMatching: currentLanguage == context.recommendedLanguage
                        )
                    }

                    if let coords = coordinates {
                        Section("Preview with Recommended Settings") {
                            PrayerTimePreviewCard(
                                method: context.recommendedMethod,
                                madhab: context.recommendedMadhab,
                                location: coords,
                                date: Date()
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
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
        .fullSheet()
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

// MARK: - Prayer Adjustments View

struct PrayerAdjustmentsView: View {
    @State private var adjustments: [PrayerType: Int] = [:]

    var body: some View {
        List {
            ForEach(PrayerType.allCases) { prayer in
                if prayer.isObligatory {
                    Stepper(
                        "\(prayer.displayName): \(adjustments[prayer] ?? 0) min",
                        value: Binding(
                            get: { adjustments[prayer] ?? 0 },
                            set: { newValue in
                                adjustments[prayer] = newValue
                                saveAdjustment(newValue, for: prayer)
                            }
                        ),
                        in: -30...30
                    )
                }
            }
        }
        .navigationTitle("Adjustments")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let prefs = await PreferencesManager.shared.getPreferences()
            for prayer in PrayerType.allCases where prayer.isObligatory {
                adjustments[prayer] = prefs.adjustment(for: prayer)
            }
        }
    }

    private func saveAdjustment(_ minutes: Int, for prayer: PrayerType) {
        Task {
            await PreferencesManager.shared.update { prefs in
                prefs.setAdjustment(minutes, for: prayer)
            }
            await NotificationScheduler.shared.forceReschedule()
        }
    }
}

// MARK: - Notification Schedule View

struct NotificationScheduleView: View {
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

// MARK: - Font Settings View

struct FontSettingsView: View {
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

// MARK: - Data Export View

struct DataExportView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var exportError: String?

    var body: some View {
        List {
            Section {
                Button {
                    Task { await exportJSON() }
                } label: {
                    HStack {
                        Label("Export All Data (JSON)", systemImage: "doc.text")
                        Spacer()
                        if isExporting { ProgressView() }
                    }
                }
                .disabled(isExporting)

                Button {
                    Task { await exportPrayerCSV() }
                } label: {
                    Label("Export Prayer Logs (CSV)", systemImage: "tablecells")
                }
                .disabled(isExporting)
            } header: {
                Text("Export")
            } footer: {
                Text("Your data is exported as a file you can save or share. JSON includes all data; CSV is a spreadsheet of prayer logs.")
            }

            Section {
                VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                    Text("What's included in JSON export:")
                        .font(SafaTypography.labelMedium)
                    Text("• Preferences and settings")
                    Text("• Prayer log history")
                    Text("• Quran bookmarks and reading progress")
                    Text("• Streaks and progress")
                    Text("• User statistics")
                }
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            if let error = exportError {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(SafaTypography.bodySmall)
                }
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareActivityView(items: [url])
            }
        }
    }

    private func exportJSON() async {
        isExporting = true
        exportError = nil
        do {
            let data = try await DataExportService.exportJSON(
                userRepository: dependencies.userRepository,
                quranRepository: dependencies.quranRepository
            )
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("safa_export.json")
            try data.write(to: url)
            exportedFileURL = url
            showShareSheet = true
        } catch {
            exportError = "Export failed: \(error.localizedDescription)"
        }
        isExporting = false
    }

    private func exportPrayerCSV() async {
        isExporting = true
        exportError = nil
        do {
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let data = try await DataExportService.exportPrayerLogsCSV(
                prayerRepository: dependencies.prayerRepository,
                from: thirtyDaysAgo,
                to: Date()
            )
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("safa_prayer_logs.csv")
            try data.write(to: url)
            exportedFileURL = url
            showShareSheet = true
        } catch {
            exportError = "Export failed: \(error.localizedDescription)"
        }
        isExporting = false
    }
}

// MARK: - Share Activity View

private struct ShareActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Feedback View

struct FeedbackView: View {
    @State private var feedbackType: FeedbackType = .bugReport
    @State private var feedbackTitle = ""
    @State private var feedbackDescription = ""
    @State private var selectedCategory: FeedbackCategory = .general
    @State private var showMailComposer = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    enum FeedbackType: String, CaseIterable {
        case bugReport = "Bug Report"
        case featureRequest = "Feature Request"
        case generalFeedback = "General Feedback"
    }

    enum FeedbackCategory: String, CaseIterable {
        case general = "General"
        case prayer = "Prayer Times"
        case quran = "Quran"
        case learning = "Learning"
        case ai = "AI Companion"
        case widgets = "Widgets"
        case accessibility = "Accessibility"
    }

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $feedbackType) {
                    ForEach(FeedbackType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                Picker("Category", selection: $selectedCategory) {
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }

                TextField("Title", text: $feedbackTitle)
            }

            Section {
                ZStack(alignment: .topLeading) {
                    if feedbackDescription.isEmpty {
                        Text("What happened?\nWhich page were you on?\nWhat did you expect instead?")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    TextEditor(text: $feedbackDescription)
                        .frame(minHeight: 150)
                }
            } header: {
                Text("Description")
            }

            Section {
                Button {
                    submitFeedback()
                } label: {
                    HStack {
                        Spacer()
                        Text("Send Feedback")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(feedbackDescription.isEmpty)
            }
        }
        .navigationTitle("Send Feedback")
        .navigationBarTitleDisplayMode(.large)
        .alert("Feedback", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                subject: "[\(feedbackType.rawValue)] \(selectedCategory.rawValue): \(feedbackTitle)",
                body: feedbackDescription,
                recipient: "helpmesafa@gmail.com"
            )
        }
    }

    private func submitFeedback() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            let text = """
            \(feedbackType.rawValue): \(feedbackTitle)
            Category: \(selectedCategory.rawValue)

            Description:
            \(feedbackDescription)
            """
            UIPasteboard.general.string = text
            alertMessage = "Email is not configured. Your feedback has been copied to your clipboard. Please email it to helpmesafa@gmail.com"
            showAlert = true
        }
    }
}

// MARK: - Additional Previews

#Preview("Acknowledgements") {
    NavigationStack {
        AcknowledgementsView()
    }
}

#Preview("Accessibility Info") {
    NavigationStack {
        AccessibilityInfoView()
    }
}

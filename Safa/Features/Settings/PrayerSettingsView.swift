// MARK: - PrayerSettingsView.swift
// PURPOSE: Shared prayer settings used by both Settings menu and Prayer gear icon
// DEPENDENCIES: SwiftUI, PreferencesManager, PrayerSettingsActionHandler

import SwiftUI

struct PrayerSettingsView: View {
    // MARK: - State
    @State private var selectedCalculationMethod: CalculationMethod
    @State private var selectedMadhab: Madhab
    @State private var selectedTranslation: String
    @State private var locationContext: LocationContext?
    @State private var showLocationRecommendations = false

    // Debounce state
    @State private var pendingCommitTask: Task<Void, Never>?
    @State private var lastAppliedMethod: CalculationMethod
    @State private var lastAppliedMadhab: Madhab

    private let prefsManager = PreferencesManager.shared

    // MARK: - Init
    init() {
        let prefs = PreferencesManager.loadPreferencesSync()
        _selectedCalculationMethod = State(initialValue: prefs.calculationMethod)
        _selectedMadhab = State(initialValue: prefs.madhab)
        _selectedTranslation = State(initialValue: prefs.selectedTranslation)
        _lastAppliedMethod = State(initialValue: prefs.calculationMethod)
        _lastAppliedMadhab = State(initialValue: prefs.madhab)
    }

    // MARK: - Computed

    private var adjustmentsSummary: String {
        let prefs = PreferencesManager.loadPreferencesSync()
        let count = prefs.prayerAdjustments.values.filter { $0 != 0 }.count
        if count == 0 { return "0 min" }
        return "\(count) adjusted"
    }

    private var previewCoordinates: Coordinates? {
        if let context = locationContext {
            return context.coordinates
        }
        let prefs = PreferencesManager.loadPreferencesSync()
        return prefs.savedCoordinates
    }

    private var hasNonRecommendedSettings: Bool {
        guard let context = locationContext else { return false }
        return selectedCalculationMethod != context.recommendedMethod ||
               selectedMadhab != context.recommendedMadhab ||
               selectedTranslation != context.recommendedLanguage
    }

    // MARK: - Body
    var body: some View {
        List {
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

                if let coords = previewCoordinates {
                    PrayerTimePreviewCard(
                        method: selectedCalculationMethod,
                        madhab: selectedMadhab,
                        location: coords,
                        date: Date()
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                NavigationLink {
                    PrayerAdjustmentsView()
                } label: {
                    HStack {
                        Text("Prayer Time Adjustments")
                        Spacer()
                        Text(adjustmentsSummary)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                }
            } header: {
                Text("Prayer Times")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedCalculationMethod.methodDescription)
                    if let context = locationContext, selectedCalculationMethod != context.recommendedMethod {
                        Text("Recommended for \(context.regionName): \(context.recommendedMethod.displayName)")
                    }
                }
            }
        }
        .navigationTitle("Prayer Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedCalculationMethod) { _, _ in schedulePrayerSettingsCommit() }
        .onChange(of: selectedMadhab) { _, _ in schedulePrayerSettingsCommit() }
        .onDisappear { flushPendingCommit() }
        .sheet(isPresented: $showLocationRecommendations) {
            LocationRecommendationsSheet(
                context: locationContext,
                currentMethod: selectedCalculationMethod,
                currentMadhab: selectedMadhab,
                currentLanguage: selectedTranslation,
                coordinates: previewCoordinates,
                onApply: { method, madhab, language in
                    selectedCalculationMethod = method
                    selectedMadhab = madhab
                    selectedTranslation = language
                    Task {
                        await PrayerSettingsActionHandler.applyRecommendations(
                            method: method,
                            madhab: madhab,
                            language: language,
                            current: (method: lastAppliedMethod, madhab: lastAppliedMadhab, language: selectedTranslation)
                        )
                        lastAppliedMethod = method
                        lastAppliedMadhab = madhab
                    }
                }
            )
            .fullSheet()
        }
        .task {
            if let coords = PreferencesManager.loadPreferencesSync().savedCoordinates {
                locationContext = LocationInferenceService.shared.inferContextFast(from: coords)
            }
        }
    }

    // MARK: - Debounce

    private func schedulePrayerSettingsCommit() {
        pendingCommitTask?.cancel()
        pendingCommitTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await PrayerSettingsActionHandler.applyPrayerSettings(
                method: selectedCalculationMethod,
                madhab: selectedMadhab,
                current: (method: lastAppliedMethod, madhab: lastAppliedMadhab)
            )
            lastAppliedMethod = selectedCalculationMethod
            lastAppliedMadhab = selectedMadhab
            pendingCommitTask = nil
        }
    }

    private func flushPendingCommit() {
        guard let pending = pendingCommitTask else { return }
        pending.cancel()
        pendingCommitTask = nil
        Task { @MainActor in
            await PrayerSettingsActionHandler.applyPrayerSettings(
                method: selectedCalculationMethod,
                madhab: selectedMadhab,
                current: (method: lastAppliedMethod, madhab: lastAppliedMadhab)
            )
            lastAppliedMethod = selectedCalculationMethod
            lastAppliedMadhab = selectedMadhab
        }
    }
}

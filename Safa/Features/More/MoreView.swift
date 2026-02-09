// MARK: - MoreView.swift
// PURPOSE: More tab with navigation to all secondary features
// DEPENDENCIES: SwiftUI, Dependencies, AppRouter

import SwiftUI

struct MoreView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router

    private let hijriConverter = HijriDateConverter.shared

    var body: some View {
        List {
            // Ramadan section (shown during Ramadan)
            if hijriConverter.isRamadan() || FeatureFlags.shared.isEnabled(.ramadanMode) {
                Section {
                    NavigationLink {
                        RamadanView()
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Ramadan Mode")
                                Text("Track your fasting")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "moon.stars.fill")
                                .foregroundColor(.purple)
                        }
                    }
                }
            }

            // Daily Practice
            Section("Daily Practice") {
                NavigationLink {
                    DhikrView()
                } label: {
                    Label("Dhikr", systemImage: "hands.sparkles")
                }

                NavigationLink {
                    QiblaCompassView()
                } label: {
                    Label("Qibla Compass", systemImage: "location.north.fill")
                }

                NavigationLink {
                    HadithView()
                } label: {
                    Label("Hadith", systemImage: "text.book.closed")
                }

                NavigationLink {
                    LearnView()
                } label: {
                    Label("Learn", systemImage: "graduationcap")
                }
            }

            // Knowledge & Tools
            Section("Knowledge & Tools") {
                NavigationLink {
                    NamesOfAllahView()
                } label: {
                    Label("99 Names of Allah", systemImage: "list.star")
                }

                NavigationLink {
                    CalendarView()
                } label: {
                    Label("Islamic Calendar", systemImage: "calendar")
                }

                NavigationLink {
                    ZakatCalculatorView()
                } label: {
                    Label("Zakat Calculator", systemImage: "dollarsign.circle")
                }

            }

            // Progress
            Section("Progress") {
                NavigationLink {
                    ProgressDashboardView()
                } label: {
                    Label("Your Journey", systemImage: "chart.line.uptrend.xyaxis")
                }

                NavigationLink {
                    AchievementsView()
                } label: {
                    Label("Achievements", systemImage: "trophy")
                }
            }

            // Settings
            Section {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.large)
    }
}

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
            // Ramadan is now shown via the Prayer tab during Ramadan month

            // Daily Practice
            Section("Daily Practice") {
                NavigationLink {
                    DhikrView()
                } label: {
                    Label("Dhikr", systemImage: "hands.sparkles")
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
                    Label("Your Progress", systemImage: "chart.line.uptrend.xyaxis")
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

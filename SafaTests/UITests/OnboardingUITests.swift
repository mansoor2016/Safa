// MARK: - OnboardingUITests.swift
// PURPOSE: UI tests for onboarding flow
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class OnboardingUITests: XCTestCase {

    // MARK: - View Model Tests

    func testOnboardingViewModelInitialState() {
        let viewModel = OnboardingViewModel()

        XCTAssertFalse(viewModel.hasCompletedOnboarding)
        XCTAssertEqual(viewModel.currentStep, 0)
    }

    func testOnboardingViewModelNextStep() {
        let viewModel = OnboardingViewModel()
        let initialStep = viewModel.currentStep

        viewModel.nextStep()

        XCTAssertEqual(viewModel.currentStep, initialStep + 1)
    }

    func testOnboardingViewModelPreviousStep() {
        let viewModel = OnboardingViewModel()
        viewModel.nextStep()
        viewModel.nextStep()
        let currentStep = viewModel.currentStep

        viewModel.previousStep()

        XCTAssertEqual(viewModel.currentStep, currentStep - 1)
    }

    func testOnboardingViewModelCantGoBackFromFirstStep() {
        let viewModel = OnboardingViewModel()
        XCTAssertEqual(viewModel.currentStep, 0)

        viewModel.previousStep()

        XCTAssertEqual(viewModel.currentStep, 0)
    }

    func testOnboardingCompletion() {
        let viewModel = OnboardingViewModel()

        viewModel.completeOnboarding()

        XCTAssertTrue(viewModel.hasCompletedOnboarding)
    }

    // MARK: - User Preferences Tests

    func testCalculationMethodSelection() {
        var preferences = UserPreferences()

        preferences.calculationMethod = .mwl

        XCTAssertEqual(preferences.calculationMethod, .mwl)
    }

    func testMadhabSelection() {
        var preferences = UserPreferences()

        preferences.madhab = .hanafi

        XCTAssertEqual(preferences.madhab, .hanafi)
    }

    func testNotificationPreference() {
        var preferences = UserPreferences()

        preferences.notificationsEnabled = true

        XCTAssertTrue(preferences.notificationsEnabled)
    }

    func testOnboardingCompletionFlag() {
        var preferences = UserPreferences()

        preferences.hasCompletedOnboarding = true

        XCTAssertTrue(preferences.hasCompletedOnboarding)
    }
}

// MARK: - Onboarding Step Tests

final class OnboardingStepTests: XCTestCase {

    func testAllStepsExist() {
        let steps = OnboardingStep.allSteps

        XCTAssertFalse(steps.isEmpty)
        XCTAssertGreaterThanOrEqual(steps.count, 4)
    }

    func testStepsHaveTitles() {
        for step in OnboardingStep.allSteps {
            XCTAssertFalse(step.title.isEmpty)
        }
    }

    func testStepsHaveDescriptions() {
        for step in OnboardingStep.allSteps {
            XCTAssertFalse(step.description.isEmpty)
        }
    }

    func testStepsHaveIcons() {
        for step in OnboardingStep.allSteps {
            XCTAssertFalse(step.iconName.isEmpty)
        }
    }
}

// MARK: - Home View Tests

final class HomeViewModelTests: XCTestCase {

    func testHomeViewModelInitialState() {
        let viewModel = HomeViewModel()

        XCTAssertFalse(viewModel.isLoading)
    }

    func testPrayerCountdownCardExists() {
        // Verify the component exists and can be initialized
        let _ = PrayerCountdownCard.self
    }

    func testReminderCardExists() {
        // Verify the component exists
        let _ = ReminderCard.self
    }
}

//
//  OnboardingViewModelTests.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 02/05/25.
//

@testable import BeeAway
import XCTest

// A fake checker to simulate trust changes
private class FakeChecker: AccessibilityChecker {
    private var state: Bool
    init(initial: Bool) { state = initial }
    func setTrusted(_ t: Bool) { state = t }
    func isTrusted() -> Bool { state }
}

final class OnboardingViewModelTests: XCTestCase {
    func testInitialState_FromChecker() {
        let checker = FakeChecker(initial: false)
        let vm = OnboardingViewModel(
            checker: checker,
            onGrant: {},
            onContinue: {}
        )
        XCTAssertFalse(vm.isTrusted)
    }

    func testGrantTapped_InvokesClosure() {
        let expectation = XCTestExpectation(description: "onGrant called")
        let vm = OnboardingViewModel(
            checker: FakeChecker(initial: false),
            onGrant: { expectation.fulfill() },
            onContinue: {}
        )
        vm.grantTapped()
        wait(for: [expectation], timeout: 0.1)
    }

    func testContinueTapped_InvokesClosure_WhenTrusted() {
        let checker = FakeChecker(initial: true)
        let exp1 = XCTestExpectation(description: "onContinue called")
        let vm = OnboardingViewModel(
            checker: checker,
            onGrant: {},
            onContinue: { exp1.fulfill() }
        )
        // Must be trusted initially
        XCTAssertTrue(vm.isTrusted)
        vm.continueTapped()
        wait(for: [exp1], timeout: 0.1)
    }

    func testRefresh_UpdatesIsTrusted() {
        let checker = FakeChecker(initial: false)
        let vm = OnboardingViewModel(checker: checker)
        XCTAssertFalse(vm.isTrusted)

        checker.setTrusted(true)
        vm.refresh()
        XCTAssertTrue(vm.isTrusted)

        checker.setTrusted(false)
        vm.refresh()
        XCTAssertFalse(vm.isTrusted)
    }

    func testContinueButton_DisabledWhenNotTrusted() {
        let checker = FakeChecker(initial: false)
        let vm = OnboardingViewModel(
            checker: checker,
            onGrant: {},
            onContinue: {}
        )
        // In the view, Button("Continue") is disabled when isTrusted == false
        XCTAssertFalse(vm.isTrusted)
    }

    func testIveGrantedAccess_ButtonEnablesAfterRefresh() {
        let checker = FakeChecker(initial: false)
        let vm = OnboardingViewModel(checker: checker)
        XCTAssertFalse(vm.isTrusted)

        checker.setTrusted(true)
        vm.refresh()
        XCTAssertTrue(vm.isTrusted)
    }
}

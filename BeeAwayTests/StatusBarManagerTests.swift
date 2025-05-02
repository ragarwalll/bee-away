//
//  StatusBarManagerTests.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 02/05/25.
//

import AppKit
@testable import BeeAway
import XCTest

final class StatusBarManagerTests: XCTestCase {
    var manager: StatusBarManager!

    override func setUp() {
        super.setUp()
        manager = StatusBarManager()
        manager.setupStatusBar()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testMenuStructure() {
        guard let menu = manager.statusBarItem?.menu else {
            return XCTFail("Menu should exist")
        }
        let titles = menu.items.map { $0.title }
        XCTAssertEqual(titles[0], "Start Keep-Alive")
        XCTAssertEqual(titles[1], "Stop Keep-Alive")
        XCTAssertTrue(menu.items[2].isSeparatorItem)
        XCTAssertTrue(titles[3].hasPrefix("Activate for Duration"))
        // your code uses the ellipsis in the menu title:
        XCTAssertEqual(titles[4], "Preferences…")
        XCTAssertTrue(menu.items[5].isSeparatorItem)
        XCTAssertEqual(titles[6], "Reset")
        XCTAssertEqual(titles[7], "Quit")
    }

    func testStartStopWithNoPermissionShowsOnboarding() {
        // By default, no permission
        XCTAssertNil(manager.onboardingWindow)

        manager.startKeepAlive()

        // Expect onboarding to appear, and no timer
        XCTAssertNotNil(manager.onboardingWindow)
        XCTAssertNil(manager.movementTimer)
        XCTAssertTrue(manager.startItem.isEnabled)
        XCTAssertFalse(manager.stopItem.isEnabled)
    }

    func testStartStopAfterClosingOnboardingStillShowsOnboardingInTests() {
        // Simulate user has seen and closed the onboarding
        manager.showOnboarding()
        let onboardWin = manager.onboardingWindow!
        onboardWin.close()
        RunLoop.current.run(until: Date())
        XCTAssertNil(manager.onboardingWindow)

        // Even after “closing” onboarding, AXIsProcessTrusted() is still false in tests:
        manager.startKeepAlive()

        // Onboarding should re-appear again:
        XCTAssertNotNil(manager.onboardingWindow)
        XCTAssertNil(manager.movementTimer)
        XCTAssertTrue(manager.startItem.isEnabled)
        XCTAssertFalse(manager.stopItem.isEnabled)
    }

    func testDurationSelectionCreatesTimer() {
        let menu = manager.statusBarItem!.menu!
        let submenu = menu.items[3].submenu!
        guard let fiveMin = submenu.items.first(where: { $0.title == "5 minutes" })
        else { return XCTFail("5 minutes item missing") }
        manager.durationSelected(fiveMin)

        XCTAssertEqual(fiveMin.state, .on)
        for item in submenu.items where item !== fiveMin {
            XCTAssertEqual(item.state, .off)
        }
        XCTAssertNotNil(manager.durationTimer)
    }

    func testPreferencesWindowCreationAndRecreation() {
        // 1st show:
        XCTAssertNil(manager.preferencesWindow)
        manager.showPreferences()
        let firstWin = manager.preferencesWindow
        XCTAssertNotNil(firstWin)
        XCTAssertEqual(firstWin?.title, "Preferences")
        XCTAssertTrue(firstWin!.isVisible)

        // 2nd show: your code brings forward old, THEN zeroes it, THEN
        // creates a brand‐new window and stores in preferencesWindow.
        manager.showPreferences()
        let secondWin = manager.preferencesWindow
        XCTAssertNotNil(secondWin)
        // must be a different instance than the first one:
        XCTAssertFalse(firstWin === secondWin)
        XCTAssertEqual(secondWin?.title, "Preferences")
        XCTAssertTrue(secondWin!.isVisible)
    }

    func testOnboardingWindowLifecycle() {
        // show it
        XCTAssertNil(manager.onboardingWindow)
        manager.showOnboarding()
        let onboardWin = manager.onboardingWindow
        XCTAssertNotNil(onboardWin)
        XCTAssertEqual(onboardWin?.title, "Welcome to BeeAway")

        // simulate AppKit willClose notification
        NotificationCenter.default.post(
            name: NSWindow.willCloseNotification,
            object: onboardWin
        )
        // your delegate only clears onboardingWindow:
        XCTAssertNil(manager.onboardingWindow)
    }
}

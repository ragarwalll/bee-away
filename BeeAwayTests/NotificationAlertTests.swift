//
//  NotificationAlertTests.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 02/05/25.
//

import AppKit
@testable import BeeAway
import XCTest

final class NotificationAlertTests: XCTestCase {
    func testAlertContents() {
        let msg = "You must enable notifications in Settings"
        let wrapper = NotificationAlert(message: msg)
        let alert = wrapper.alert

        XCTAssertEqual(alert.messageText, "Notifications Disabled")
        XCTAssertEqual(alert.informativeText, msg)
        XCTAssertEqual(alert.alertStyle, .informational)
        XCTAssertEqual(alert.buttons.count, 1)
        XCTAssertEqual(alert.buttons[0].title, "OK")
    }
}

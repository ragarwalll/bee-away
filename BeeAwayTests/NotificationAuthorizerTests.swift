//
//  NotificationAuthorizerTests.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 02/05/25.
//

@testable import BeeAway
import UserNotifications
import XCTest

// A fake authorizer that calls back with predetermined values
private class FakeAuthorizer: NotificationAuthorizing {
    let granted: Bool
    let error: Error?
    init(granted: Bool, error: Error? = nil) {
        self.granted = granted; self.error = error
    }

    func requestAuthorization(
        options _: UNAuthorizationOptions,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        // Call back immediately
        completion(granted, error)
    }
}

final class NotificationAuthorizerTests: XCTestCase {
    func testGrantedPath() {
        let fake = FakeAuthorizer(granted: true)
        let exp = expectation(description: "Completion called")
        fake.requestAuthorization(options: []) { granted, error in
            XCTAssertTrue(granted)
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.1)
    }

    func testDeniedPath() {
        let fake = FakeAuthorizer(granted: false)
        let exp = expectation(description: "Completion called")
        fake.requestAuthorization(options: []) { granted, error in
            XCTAssertFalse(granted, "Denial path should report `granted == false`")
            XCTAssertNil(error, "No error object when just denied")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.1)
    }

    func testErrorPath() {
        let err = NSError(domain: "Test", code: 42, userInfo: nil)
        let fake = FakeAuthorizer(granted: false, error: err)
        let exp = expectation(description: "Completion called")
        fake.requestAuthorization(options: []) { granted, error in
            XCTAssertFalse(granted, "Error path should report `granted == false`")
            XCTAssertEqual(error as NSError?, err,
                           "Error path should pass along the error object")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.1)
    }
}

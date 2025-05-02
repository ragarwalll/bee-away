//
//  PreferencesViewTests.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 02/05/25.
//

@testable import BeeAway
import XCTest

final class PreferencesViewModelTests: XCTestCase {
    let key = "BoundApps"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: key)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    func testInitialLoadEmpty() {
        let vm = PreferencesViewModel()
        XCTAssertTrue(vm.apps.isEmpty)
    }

    func testSaveWritesUserDefaults() {
        let vm = PreferencesViewModel()
        let one = AppEntry(name: "One", bundleID: "com.test.one")
        let two = AppEntry(name: "Two", bundleID: "com.test.two")
        vm.apps = [one, two]
        vm.save()

        let saved = UserDefaults.standard.stringArray(forKey: key)
        XCTAssertEqual(Set(saved ?? []),
                       Set(["com.test.one", "com.test.two"]))
    }

    func testAddPreventsDuplicates() {
        let vm = PreferencesViewModel()
        // use the same fake URL twice
        let url = Bundle.main.bundleURL
        vm.apps = []
        vm.add(urls: [url, url])
        // after add, only one entry
        XCTAssertEqual(vm.apps.count, 1)
        // and the default was saved once
        let defaults = UserDefaults.standard.stringArray(forKey: key) ?? []
        XCTAssertEqual(defaults.count, 1)
    }

    func testRemoveSelected() {
        let one = AppEntry(name: "One", bundleID: "com.one")
        let two = AppEntry(name: "Two", bundleID: "com.two")
        let vm = PreferencesViewModel()
        vm.apps = [one, two]
        vm.selection = [one.id]
        vm.removeSelected()

        XCTAssertEqual(vm.apps, [two])
        XCTAssertTrue(vm.selection.isEmpty)

        let saved = UserDefaults.standard.stringArray(forKey: key) ?? []
        XCTAssertEqual(saved, [two.bundleID])
    }

    func testRemoveSelectedNothing() {
        let one = AppEntry(name: "One", bundleID: "com.one")
        let vm = PreferencesViewModel()
        vm.apps = [one]
        vm.selection = []
        vm.removeSelected()

        XCTAssertEqual(vm.apps, [one])
        XCTAssertNil(UserDefaults.standard.object(forKey: key))
    }
}

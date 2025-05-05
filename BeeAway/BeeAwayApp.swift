//
//  BeeAwayApp.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 02/05/25.
//

import Cocoa
import SwiftUI
import UserNotifications

private func showNotificationDeniedAlert(message: String) {
    let wrapper = NotificationAlert(message: message)
    let alert = wrapper.alert
    alert.messageText = "Notifications Disabled"
    alert.informativeText = message
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")

    if let win = NSApp.keyWindow {
        alert.beginSheetModal(for: win, completionHandler: nil)
    } else {
        alert.runModal()
    }
}

@main
struct BeeAwayApp: App {
    private let statusBarManager = StatusBarManager.shared
    private let authorizer: NotificationAuthorizing

    init() {
        self.init(authorizer: UNUserNotificationCenter.current())
    }

    init(authorizer: NotificationAuthorizing) {
        self.authorizer = authorizer
        let mgr = statusBarManager
        let auth = authorizer

        DispatchQueue.main.async {
            mgr.setupStatusBar()
            NSApp.setActivationPolicy(.regular)

            auth.requestAuthorization(options: [.alert, .sound]) { granted, error in
                DispatchQueue.main.async {
                    NSApp.setActivationPolicy(.accessory)
                    if let error = error {
                        print("Notification auth error:", error)
                    } else if !granted {
                        print("User denied notification permission")
                        showNotificationDeniedAlert(
                            message: "Notifications are disabled — please enable them in Settings."
                        )
                    } else {
                        print("Notification permission granted")
                    }
                }
            }
        }
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

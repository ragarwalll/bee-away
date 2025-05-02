//
//  NotificationAlert.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 02/05/25.
//

import AppKit

public struct NotificationAlert {
    public let alert: NSAlert

    /// Build an informational “notifications disabled” alert.
    ///
    /// - Parameter message: the message to show under the title.
    public init(message: String) {
        let a = NSAlert()
        a.messageText = "Notifications Disabled"
        a.informativeText = message
        a.alertStyle = .informational
        a.addButton(withTitle: "OK")
        alert = a
    }
}

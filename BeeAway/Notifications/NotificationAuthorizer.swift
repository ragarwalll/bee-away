//
//  NotificationAuthorizer.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 02/05/25.
//

import UserNotifications

public protocol NotificationAuthorizing {
    func requestAuthorization(
        options: UNAuthorizationOptions,
        completion: @escaping (Bool, Error?) -> Void
    )
}

extension UNUserNotificationCenter: NotificationAuthorizing {
    public func requestAuthorization(
        options: UNAuthorizationOptions,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        requestAuthorization(options: options, completionHandler: completion)
    }
}

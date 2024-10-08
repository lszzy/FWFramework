//
//  ActivityManager.swift
//  FWFramework_SwiftUI
//
//  Created by wuyong on 2024/9/5.
//

import ActivityKit
import SwiftUI

@available(iOS 16.1, *)
struct ActivityManager {
    static func requestAuthorization(
        options: UNAuthorizationOptions = [.sound, .alert, .badge],
        completionHandler: ((Bool, Error?) -> Void)? = nil
    ) {
        UIApplication.shared.registerForRemoteNotifications()

        UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: { success, error in
            completionHandler?(success, error)
        })
    }

    @discardableResult
    static func createActivity<T: ActivityAttributes>(attributes: T, contentState: T.ContentState, tokenHandler: ((String) -> Void)? = nil) throws -> Activity<T> {
        let activity = try Activity<T>.request(attributes: attributes, contentState: contentState, pushType: .token)
        Task {
            for await tokenData in activity.pushTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                tokenHandler?(token)
            }
        }
        return activity
    }

    static func updateActivity<T: ActivityAttributes>(_ activity: Activity<T>, using contentState: T.ContentState) {
        Task {
            await activity.update(using: contentState)
        }
    }

    static func endActivity<T: ActivityAttributes>(_ activity: Activity<T>) {
        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
    }

    static func endAllActivities<T: ActivityAttributes>(of type: T.Type) {
        Task {
            for activity in Activity<T>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }

    static func getAllActivities<T: ActivityAttributes>(of type: T.Type) -> [Activity<T>] {
        Activity<T>.activities.sorted { $0.id > $1.id }
    }
}

//
//  AuthorizeCalendar.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import EventKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - AuthorizeType+Calendar
extension AuthorizeType {
    /// 日历，Info.plist需配置NSCalendarsUsageDescription|NSCalendarsFullAccessUsageDescription
    public static let calendars: AuthorizeType = .init("calendars")
    /// 日历仅写入，Info.plist需配置NSCalendarsUsageDescription|NSCalendarsWriteOnlyAccessUsageDescription
    public static let calendarsWriteOnly: AuthorizeType = .init("calendarsWriteOnly")
    /// 提醒，Info.plist需配置NSRemindersUsageDescription|NSRemindersFullAccessUsageDescription
    public static let reminders: AuthorizeType = .init("reminders")
}

// MARK: - AuthorizeCalendar
/// 日历授权
public class AuthorizeCalendar: NSObject, AuthorizeProtocol, @unchecked Sendable {
    public static let shared = AuthorizeCalendar(type: .event)
    public static let writeOnly = AuthorizeCalendar(type: .event, writeOnly: true)
    public static let reminder = AuthorizeCalendar(type: .reminder)

    private var type: EKEntityType = .event
    private var writeOnly: Bool = false

    public init(type: EKEntityType, writeOnly: Bool = false) {
        super.init()
        self.type = type
        self.writeOnly = writeOnly
    }

    public func authorizeStatus() -> AuthorizeStatus {
        let status = EKEventStore.authorizationStatus(for: type)
        switch status {
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .fullAccess:
            return .authorized
        case .writeOnly:
            if #available(iOS 17.0, *) {
                if type == .event && !writeOnly {
                    return .denied
                }
            }
            return .authorized
        default:
            return .notDetermined
        }
    }

    public func requestAuthorize(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?) {
        let completionHandler: EKEventStoreRequestAccessCompletionHandler = { granted, error in
            let status: AuthorizeStatus = granted ? .authorized : .denied
            if completion != nil {
                DispatchQueue.fw.mainAsync {
                    completion?(status, error)
                }
            }
        }

        if #available(iOS 17.0, *) {
            let eventStore = EKEventStore()
            if type == .event {
                if writeOnly {
                    eventStore.requestWriteOnlyAccessToEvents(completion: completionHandler)
                } else {
                    eventStore.requestFullAccessToEvents(completion: completionHandler)
                }
            } else {
                eventStore.requestFullAccessToReminders(completion: completionHandler)
            }
            return
        }

        let eventStore = EKEventStore()
        eventStore.requestAccess(to: type, completion: completionHandler)
    }
}

// MARK: - Autoloader+Calendar
@objc extension Autoloader {
    static func loadPlugin_Calendar() {
        AuthorizeManager.presetAuthorize(.calendars) { AuthorizeCalendar.shared }
        AuthorizeManager.presetAuthorize(.calendarsWriteOnly) { AuthorizeCalendar.writeOnly }
        AuthorizeManager.presetAuthorize(.reminders) { AuthorizeCalendar.reminder }
    }
}

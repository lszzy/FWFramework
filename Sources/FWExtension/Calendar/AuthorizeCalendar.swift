//
//  AuthorizeCalendar.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import EventKit
#if FWMacroSPM
import FWFramework
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
private class AuthorizeCalendar: NSObject, AuthorizeProtocol {
    private var type: EKEntityType = .event
    private var writeOnly: Bool = false
    
    init(type: EKEntityType, writeOnly: Bool = false) {
        super.init()
        self.type = type
        self.writeOnly = writeOnly
    }
    
    func authorizeStatus() -> AuthorizeStatus {
        let status = EKEventStore.authorizationStatus(for: type)
        switch status {
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        #if swift(>=5.9)
        case .fullAccess:
            return .authorized
        case .writeOnly:
            if #available(iOS 17.0, *) {
                if type == .event && !writeOnly {
                    return .denied
                }
            }
            return .authorized
        #endif
        default:
            return .notDetermined
        }
    }
    
    func authorize(_ completion: ((AuthorizeStatus) -> Void)?) {
        let completionHandler: EKEventStoreRequestAccessCompletionHandler = { granted, error in
            let status: AuthorizeStatus = granted ? .authorized : .denied
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(status)
                }
            }
        }
        
        #if swift(>=5.9)
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
        #endif
        
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: type, completion: completionHandler)
    }
}

// MARK: - Autoloader+Calendar
@objc extension Autoloader {
    static func loadExtension_Calendar() {
        AuthorizeManager.presetAuthorize(.calendars) { AuthorizeCalendar(type: .event) }
        AuthorizeManager.presetAuthorize(.calendarsWriteOnly) { AuthorizeCalendar(type: .event, writeOnly: true) }
        AuthorizeManager.presetAuthorize(.reminders) { AuthorizeCalendar(type: .reminder) }
    }
}

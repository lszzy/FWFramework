//
//  Message.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/19.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

// MARK: - Message
extension Wrapper where Base: NSObject {
    
    // MARK: - Observer
    /// 监听某个点对点消息，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 消息名称
    ///   - block: 消息句柄
    /// - Returns: 监听唯一标志
    @discardableResult
    public func observeMessage(_ name: Notification.Name, block: @escaping (Notification) -> Void) -> String {
        return observeMessage(name, object: nil, block: block)
    }
    
    /// 监听某个指定对象点对点消息，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    ///   - block: 消息句柄
    /// - Returns: 监听唯一标志
    @discardableResult
    public func observeMessage(_ name: Notification.Name, object: AnyObject?, block: @escaping (Notification) -> Void) -> String {
        let dict = messageTargets(true)
        var array = dict?[name] as? NSMutableArray
        if array == nil {
            array = NSMutableArray()
            dict?[name] = array
        }
        
        let messageTarget = __NotificationTarget()
        messageTarget.broadcast = false
        messageTarget.object = object
        messageTarget.block = block
        array?.add(messageTarget)
        return messageTarget.identifier
    }
    
    /// 监听某个点对点消息，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 消息名称
    ///   - target: 消息目标
    ///   - action: 目标动作，参数为通知对象
    /// - Returns: 监听唯一标志
    @discardableResult
    public func observeMessage(_ name: Notification.Name, target: AnyObject?, action: Selector) -> String {
        return observeMessage(name, object: nil, target: target, action: action)
    }
    
    /// 监听某个指定对象点对点消息，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    ///   - target: 消息目标
    ///   - action: 目标动作，参数为通知对象
    /// - Returns: 监听唯一标志
    @discardableResult
    public func observeMessage(_ name: Notification.Name, object: AnyObject?, target: AnyObject?, action: Selector) -> String {
        let dict = messageTargets(true)
        var array = dict?[name] as? NSMutableArray
        if array == nil {
            array = NSMutableArray()
            dict?[name] = array
        }
        
        let messageTarget = __NotificationTarget()
        messageTarget.broadcast = false
        messageTarget.object = object
        messageTarget.target = target
        messageTarget.action = action
        array?.add(messageTarget)
        return messageTarget.identifier
    }
    
    /// 手工移除某个点对点消息指定监听
    /// - Parameters:
    ///   - name: 消息名称
    ///   - target: 消息目标
    ///   - action: 目标动作
    public func unobserveMessage(_ name: Notification.Name, target: Any?, action: Selector?) {
        unobserveMessage(name, object: nil, target: target, action: action)
    }
    
    /// 手工移除某个指定对象点对点消息指定监听
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    ///   - target: 消息目标
    ///   - action: 目标动作
    public func unobserveMessage(_ name: Notification.Name, object: AnyObject?, target: Any?, action: Selector?) {
        guard let dict = messageTargets(false) else { return }
        
        // object为nil且target为nil始终移除
        if object == nil && target == nil {
            dict.removeObject(forKey: name)
            return
        }
        
        guard let array = dict[name] as? NSMutableArray else { return }
        // object相同且target为nil时始终移除
        if target == nil {
            for (_, elem) in array.enumerated() {
                if let obj = elem as? __NotificationTarget,
                   obj.equalsObject(object) {
                    array.remove(obj)
                }
            }
        // object相同且target相同且action为NULL或者action相同才移除
        } else {
            for (_, elem) in array.enumerated() {
                if let obj = elem as? __NotificationTarget,
                   obj.equalsObject(object, target: target, action: action) {
                    array.remove(obj)
                }
            }
        }
    }
    
    /// 手工移除某个指定对象点对点消息指定监听
    /// - Parameters:
    ///   - name: 消息名称
    ///   - identifier: 监听唯一标志
    public func unobserveMessage(_ name: Notification.Name, identifier: String) {
        guard let dict = messageTargets(false),
              let array = dict[name] as? NSMutableArray else { return }
        
        for (_, elem) in array.enumerated() {
            if let obj = elem as? __NotificationTarget,
               obj.identifier == identifier {
                array.remove(obj)
            }
        }
    }
    
    /// 手工移除某个点对点消息所有监听
    /// - Parameter name: 消息名称
    public func unobserveMessage(_ name: Notification.Name) {
        unobserveMessage(name, object: nil)
    }
    
    /// 手工移除某个指定对象点对点消息所有监听
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    public func unobserveMessage(_ name: Notification.Name, object: AnyObject?) {
        unobserveMessage(name, object: object, target: nil, action: nil)
    }
    
    /// 手工移除所有点对点消息监听
    public func unobserveAllMessages() {
        guard let dict = messageTargets(false) else { return }
        dict.removeAllObjects()
    }
    
    private func messageTargets(_ lazyload: Bool) -> NSMutableDictionary? {
        var targets = property(forName: "messageTargets") as? NSMutableDictionary
        if targets == nil && lazyload {
            targets = NSMutableDictionary()
            setProperty(targets, forName: "messageTargets")
        }
        return targets
    }
    
    // MARK: - Subject
    /// 发送点对点消息
    /// - Parameters:
    ///   - name: 消息名称
    ///   - toReceiver: 消息接收者
    public func sendMessage(_ name: Notification.Name, toReceiver: Any) {
        sendMessage(name, object: nil, toReceiver: toReceiver)
    }
    
    /// 发送点对点消息，附带对象
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象
    ///   - toReceiver: 消息接收者
    public func sendMessage(_ name: Notification.Name, object: Any?, toReceiver: Any) {
        sendMessage(name, object: object, userInfo: nil, toReceiver: toReceiver)
    }
    
    /// 发送点对点消息，附带对象和用户信息
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象
    ///   - userInfo: 用户信息
    ///   - toReceiver: 消息接收者
    public func sendMessage(_ name: Notification.Name, object: Any?, userInfo: [AnyHashable: Any]?, toReceiver: Any) {
        NSObject.fw.sendMessage(name, object: object, userInfo: userInfo, toReceiver: toReceiver)
    }
    
    /// 发送点对点消息
    /// - Parameters:
    ///   - name: 消息名称
    ///   - toReceiver: 消息接收者
    public static func sendMessage(_ name: Notification.Name, toReceiver: Any) {
        sendMessage(name, object: nil, toReceiver: toReceiver)
    }
    
    /// 发送点对点消息，附带对象
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象
    ///   - toReceiver: 消息接收者
    public static func sendMessage(_ name: Notification.Name, object: Any?, toReceiver: Any) {
        sendMessage(name, object: object, userInfo: nil, toReceiver: toReceiver)
    }
    
    /// 发送点对点消息，附带对象和用户信息
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象
    ///   - userInfo: 用户信息
    ///   - toReceiver: 消息接收者
    public static func sendMessage(_ name: Notification.Name, object: Any?, userInfo: [AnyHashable: Any]?, toReceiver: Any) {
        guard let receiver = toReceiver as? NSObject,
              let dict = receiver.fw.messageTargets(false),
              let array = dict[name] as? NSMutableArray else { return }
        
        let notification = Notification(name: name, object: object, userInfo: userInfo)
        for (_, elem) in array.enumerated() {
            // obj.object为nil或者obj.object和object相同才触发
            if let obj = elem as? __NotificationTarget,
               (obj.object == nil || obj.equalsObject(object)) {
                obj.handle(notification)
            }
        }
    }
    
}

// MARK: - Notification
extension Wrapper where Base: NSObject {
    
    // MARK: - Observer
    /// 监听某个广播通知，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 通知名称
    ///   - block: 通知句柄
    /// - Returns: 监听唯一标志
    @discardableResult
    public func observeNotification(_ name: Notification.Name, block: @escaping (Notification) -> Void) -> String {
        return observeNotification(name, object: nil, block: block)
    }
    
    /// 监听某个指定对象广播通知，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - block: 通知句柄
    /// - Returns: 监听唯一标志
    @discardableResult
    public func observeNotification(_ name: Notification.Name, object: AnyObject?, block: @escaping (Notification) -> Void) -> String {
        let dict = notificationTargets(true)
        var array = dict?[name] as? NSMutableArray
        if array == nil {
            array = NSMutableArray()
            dict?[name] = array
        }
        
        let notificationTarget = __NotificationTarget()
        notificationTarget.broadcast = true
        notificationTarget.object = object
        notificationTarget.block = block
        array?.add(notificationTarget)
        NotificationCenter.default.addObserver(notificationTarget, selector: #selector(__NotificationTarget.handle(_:)), name: name, object: object)
        return notificationTarget.identifier
    }
    
    /// 监听某个广播通知，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 通知名称
    ///   - target: 通知目标
    ///   - action: 目标动作，参数为通知对象
    /// - Returns: 监听唯一标志
    @discardableResult
    public func observeNotification(_ name: Notification.Name, target: AnyObject?, action: Selector) -> String {
        return observeNotification(name, object: nil, target: target, action: action)
    }
    
    /// 监听某个指定对象广播通知，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - target: 通知目标
    ///   - action: 目标动作，参数为通知对象
    /// - Returns: 监听唯一标志
    @discardableResult
    public func observeNotification(_ name: Notification.Name, object: AnyObject?, target: AnyObject?, action: Selector) -> String {
        let dict = notificationTargets(true)
        var array = dict?[name] as? NSMutableArray
        if array == nil {
            array = NSMutableArray()
            dict?[name] = array
        }
        
        let notificationTarget = __NotificationTarget()
        notificationTarget.broadcast = true
        notificationTarget.object = object
        notificationTarget.target = target
        notificationTarget.action = action
        array?.add(notificationTarget)
        NotificationCenter.default.addObserver(notificationTarget, selector: #selector(__NotificationTarget.handle(_:)), name: name, object: object)
        return notificationTarget.identifier
    }
    
    /// 手工移除某个广播通知指定监听
    /// - Parameters:
    ///   - name: 通知名称
    ///   - target: 通知目标
    ///   - action: 目标动作
    public func unobserveNotification(_ name: Notification.Name, target: Any?, action: Selector?) {
        unobserveNotification(name, object: nil, target: target, action: action)
    }
    
    /// 手工移除某个指定对象广播通知指定监听
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - target: 通知目标
    ///   - action: 目标动作
    public func unobserveNotification(_ name: Notification.Name, object: Any?, target: Any?, action: Selector?) {
        guard let dict = notificationTargets(false) else { return }
        
        // object为nil且target为nil始终移除
        if object == nil && target == nil {
            if let array = dict[name] as? NSMutableArray {
                for (_, obj) in array.enumerated() {
                    NotificationCenter.default.removeObserver(obj)
                }
            }
            dict.removeObject(forKey: name)
            return
        }
        
        guard let array = dict[name] as? NSMutableArray else { return }
        // object相同且target为nil时始终移除
        if target == nil {
            for (_, elem) in array.enumerated() {
                if let obj = elem as? __NotificationTarget,
                   obj.equalsObject(object) {
                    NotificationCenter.default.removeObserver(obj)
                    array.remove(obj)
                }
            }
        // object相同且target相同且action为NULL或者action相同才移除
        } else {
            for (_, elem) in array.enumerated() {
                if let obj = elem as? __NotificationTarget,
                   obj.equalsObject(object, target: target, action: action) {
                    NotificationCenter.default.removeObserver(obj)
                    array.remove(obj)
                }
            }
        }
    }
    
    /// 手工移除某个指定对象广播通知指定监听
    /// - Parameters:
    ///   - name: 通知名称
    ///   - identifier: 监听唯一标志
    public func unobserveNotification(_ name: Notification.Name, identifier: String) {
        guard let dict = notificationTargets(false),
              let array = dict[name] as? NSMutableArray else { return }
        
        for (_, elem) in array.enumerated() {
            if let obj = elem as? __NotificationTarget,
               obj.identifier == identifier {
                NotificationCenter.default.removeObserver(obj)
                array.remove(obj)
            }
        }
    }
    
    /// 手工移除某个广播通知所有监听
    /// - Parameter name: 通知名称
    public func unobserveNotification(_ name: Notification.Name) {
        unobserveNotification(name, object: nil)
    }

    /// 手工移除某个指定对象广播通知所有监听
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    public func unobserveNotification(_ name: Notification.Name, object: Any?) {
        unobserveNotification(name, object: object, target: nil, action: nil)
    }
    
    /// 手工移除所有点对点消息监听
    public func unobserveAllNotifications() {
        guard let dict = notificationTargets(false) else { return }
        
        for (_, value) in dict {
            if let array = value as? NSArray {
                for (_, obj) in array.enumerated() {
                    NotificationCenter.default.removeObserver(obj)
                }
            }
        }
        dict.removeAllObjects()
    }
    
    private func notificationTargets(_ lazyload: Bool) -> NSMutableDictionary? {
        var targets = property(forName: "notificationTargets") as? NSMutableDictionary
        if targets == nil && lazyload {
            targets = NSMutableDictionary()
            setProperty(targets, forName: "notificationTargets")
        }
        return targets
    }
    
    // MARK: - Subject
    
    /// 发送广播通知，附带对象和用户信息
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象
    ///   - userInfo: 用户信息
    public func postNotification(_ name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
    }
    
    /// 发送广播通知，附带对象和用户信息
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象
    ///   - userInfo: 用户信息
    public static func postNotification(_ name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
    }
    
}

// MARK: - KVO
extension Wrapper where Base: NSObject {
    
    /// 监听对象某个属性，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - property: 属性名称
    ///   - block: 目标句柄，block参数依次为object、优化的change字典(不含NSNull)
    /// - Returns: 监听唯一标志
    @discardableResult
    public func observeProperty(_ property: String, block: @escaping (Any, [NSKeyValueChangeKey: Any]) -> Void) -> String {
        let dict = kvoTargets(true)
        var array = dict?[property] as? NSMutableArray
        if array == nil {
            array = NSMutableArray()
            dict?[property] = array
        }
        
        let kvoTarget = __KvoTarget()
        kvoTarget.object = base
        kvoTarget.keyPath = property
        kvoTarget.block = block
        array?.add(kvoTarget)
        kvoTarget.addObserver()
        return kvoTarget.identifier
    }
    
    /// 监听对象某个属性，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - property: 属性名称
    ///   - target: 目标对象
    ///   - action: 目标动作，action参数依次为object、优化的change字典(不含NSNull)
    /// - Returns: 监听唯一标志
    @discardableResult
    public func observeProperty(_ property: String, target: AnyObject?, action: Selector) -> String {
        let dict = kvoTargets(true)
        var array = dict?[property] as? NSMutableArray
        if array == nil {
            array = NSMutableArray()
            dict?[property] = array
        }
        
        let kvoTarget = __KvoTarget()
        kvoTarget.object = base
        kvoTarget.keyPath = property
        kvoTarget.target = target
        kvoTarget.action = action
        array?.add(kvoTarget)
        kvoTarget.addObserver()
        return kvoTarget.identifier
    }
    
    /// 手工移除某个属性指定监听
    /// - Parameters:
    ///   - property: 属性名称
    ///   - target: 目标对象，值为nil时移除所有对象(同UIControl)
    ///   - action: 目标动作，值为nil时移除所有动作(同UIControl)
    public func unobserveProperty(_ property: String, target: Any?, action: Selector?) {
        guard let dict = kvoTargets(false) else { return }
        
        // target为nil始终移除
        if target == nil {
            if let array = dict[property] as? NSMutableArray {
                for (_, elem) in array.enumerated() {
                    if let obj = elem as? __KvoTarget {
                        obj.removeObserver()
                    }
                }
            }
            dict.removeObject(forKey: property)
            return
        }
        
        guard let array = dict[property] as? NSMutableArray else { return }
        // target相同且action为NULL或者action相同才移除
        for (_, elem) in array.enumerated() {
            if let obj = elem as? __KvoTarget,
               obj.equalsTarget(target, action: action) {
                obj.removeObserver()
                array.remove(obj)
            }
        }
    }
    
    /// 手工移除某个属性指定监听
    /// - Parameters:
    ///   - property: 属性名称
    ///   - identifier: 监听唯一标志
    public func unobserveProperty(_ property: String, identifier: String) {
        guard let dict = kvoTargets(false),
              let array = dict[property] as? NSMutableArray else { return }
        
        for (_, elem) in array.enumerated() {
            if let obj = elem as? __KvoTarget,
               obj.identifier == identifier {
                obj.removeObserver()
                array.remove(obj)
            }
        }
    }
    
    /// 手工移除某个属性所有监听
    /// - Parameter property: 属性名称
    public func unobserveProperty(_ property: String) {
        unobserveProperty(property, target: nil, action: nil)
    }
    
    /// 手工移除所有属性所有监听
    public func unobserveAllProperties() {
        guard let dict = kvoTargets(false) else { return }
        
        for (_, value) in dict {
            if let array = value as? NSArray {
                for (_, elem) in array.enumerated() {
                    if let obj = elem as? __KvoTarget {
                        obj.removeObserver()
                    }
                }
            }
        }
        dict.removeAllObjects()
    }
    
    private func kvoTargets(_ lazyload: Bool) -> NSMutableDictionary? {
        var targets = property(forName: "kvoTargets") as? NSMutableDictionary
        if targets == nil && lazyload {
            targets = NSMutableDictionary()
            setProperty(targets, forName: "kvoTargets")
        }
        return targets
    }
    
}

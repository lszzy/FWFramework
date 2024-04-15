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

// MARK: - Wrapper+AnyObject
extension Wrapper where Base: WrapperObject {
    // MARK: - Observer
    /// 监听某个点对点消息，可指定对象，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    ///   - block: 消息句柄
    /// - Returns: 监听者
    @discardableResult
    public func observeMessage(_ name: Notification.Name, object: AnyObject? = nil, block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return base.fw_observeMessage(name, object: object, block: block)
    }
    
    /// 监听某个指定对象点对点消息，可指定对象，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    ///   - target: 消息目标
    ///   - action: 目标动作，参数为通知对象
    /// - Returns: 监听者
    @discardableResult
    public func observeMessage(_ name: Notification.Name, object: AnyObject? = nil, target: AnyObject?, action: Selector) -> NSObjectProtocol {
        return base.fw_observeMessage(name, object: object, target: target, action: action)
    }
    
    /// 手工移除某个点对点消息指定监听，可指定对象
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    ///   - target: 消息目标
    ///   - action: 目标动作
    public func unobserveMessage(_ name: Notification.Name, object: AnyObject? = nil, target: AnyObject?, action: Selector?) {
        base.fw_unobserveMessage(name, object: object, target: target, action: action)
    }
    
    /// 手工移除某个指定对象点对点消息指定监听
    /// - Parameters:
    ///   - name: 消息名称
    ///   - observer: 监听者
    @discardableResult
    public func unobserveMessage(_ name: Notification.Name, observer: Any) -> Bool {
        return base.fw_unobserveMessage(name, observer: observer)
    }
    
    /// 手工移除某个点对点消息所有监听，可指定对象
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    public func unobserveMessage(_ name: Notification.Name, object: AnyObject? = nil) {
        base.fw_unobserveMessage(name, object: object)
    }
    
    /// 手工移除所有点对点消息监听
    public func unobserveAllMessages() {
        base.fw_unobserveAllMessages()
    }
    
    // MARK: - Subject
    /// 发送点对点消息，附带对象和用户信息
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，默认nil
    ///   - userInfo: 用户信息，默认nil
    ///   - toReceiver: 消息接收者
    public func sendMessage(_ name: Notification.Name, object: AnyObject? = nil, userInfo: [AnyHashable: Any]? = nil, toReceiver: Any) {
        base.fw_sendMessage(name, object: object, userInfo: userInfo, toReceiver: toReceiver)
    }
    
    /// 发送点对点消息，附带对象和用户信息
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，默认nil
    ///   - userInfo: 用户信息，默认nil
    ///   - toReceiver: 消息接收者
    public static func sendMessage(_ name: Notification.Name, object: AnyObject? = nil, userInfo: [AnyHashable: Any]? = nil, toReceiver: Any) {
        Base.fw_sendMessage(name, object: object, userInfo: userInfo, toReceiver: toReceiver)
    }
}

// MARK: - Wrapper+AnyObject
extension Wrapper where Base: WrapperObject {
    // MARK: - Observer
    /// 监听某个广播通知，可指定对象，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - block: 通知句柄
    /// - Returns: 监听者
    @discardableResult
    public func observeNotification(_ name: Notification.Name, object: AnyObject? = nil, block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return base.fw_observeNotification(name, object: object, block: block)
    }
    
    /// 监听某个广播通知，可指定对象，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - target: 通知目标
    ///   - action: 目标动作，参数为通知对象
    /// - Returns: 监听者
    @discardableResult
    public func observeNotification(_ name: Notification.Name, object: AnyObject? = nil, target: AnyObject?, action: Selector) -> NSObjectProtocol {
        return base.fw_observeNotification(name, object: object, target: target, action: action)
    }
    
    /// 单次监听通知，触发后自动移除监听
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - queue: 通知队列
    ///   - block: 监听句柄
    public static func observeOnce(
        forName name: NSNotification.Name?,
        object: Any? = nil,
        queue: OperationQueue? = nil,
        using block: @escaping (_ notification: Notification) -> Void
    ) {
        Base.fw_observeOnce(forName: name, object: object, queue: queue, using: block)
    }
    
    /// 手工移除某个广播通知指定监听，可指定对象
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - target: 通知目标
    ///   - action: 目标动作
    public func unobserveNotification(_ name: Notification.Name, object: AnyObject? = nil, target: AnyObject?, action: Selector?) {
        base.fw_unobserveNotification(name, object: object, target: target, action: action)
    }
    
    /// 手工移除某个指定对象广播通知指定监听
    /// - Parameters:
    ///   - name: 通知名称
    ///   - observer: 监听者
    @discardableResult
    public func unobserveNotification(_ name: Notification.Name, observer: Any) -> Bool {
        return base.fw_unobserveNotification(name, observer: observer)
    }
    
    /// 手工移除某个广播通知所有监听，可指定对象
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    public func unobserveNotification(_ name: Notification.Name, object: AnyObject? = nil) {
        base.fw_unobserveNotification(name, object: object)
    }
    
    /// 手工移除所有点对点消息监听
    public func unobserveAllNotifications() {
        base.fw_unobserveAllNotifications()
    }
    
    // MARK: - Subject
    /// 发送广播通知，附带对象和用户信息
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象
    ///   - userInfo: 用户信息
    public func postNotification(_ name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        base.fw_postNotification(name, object: object, userInfo: userInfo)
    }
    
    /// 发送广播通知，附带对象和用户信息
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象
    ///   - userInfo: 用户信息
    public static func postNotification(_ name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        Base.fw_postNotification(name, object: object, userInfo: userInfo)
    }
}

// MARK: - Wrapper+NSObject
extension Wrapper where Base: NSObject {
    /// 监听对象某个属性，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - keyPath: 属性KeyPath
    ///   - options: 监听选项
    ///   - block: 目标句柄，block参数依次为object、change对象
    /// - Returns: 监听者
    @discardableResult
    public func observeProperty<Value>(_ keyPath: KeyPath<Base, Value>, options: NSKeyValueObservingOptions = [], block: @escaping (Base, NSKeyValueObservedChange<Value>) -> Void) -> NSObjectProtocol {
        let observation = base.observe(keyPath, options: options, changeHandler: block)
        return base.fw_addObservation(observation, keyPath: keyPath)
    }
    
    /// 监听对象某个属性，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - keyPath: 属性KeyPath
    ///   - options: 监听选项
    ///   - target: 目标对象
    ///   - action: 目标动作，action参数依次为object、change对象
    /// - Returns: 监听者
    @discardableResult
    public func observeProperty<Value>(_ keyPath: KeyPath<Base, Value>, options: NSKeyValueObservingOptions = [], target: AnyObject?, action: Selector) -> NSObjectProtocol {
        let observation = base.observe(keyPath, options: options) { object, change in
            if let target = target, target.responds(to: action) {
                _ = target.perform(action, with: object, with: change)
            }
        }
        return base.fw_addObservation(observation, keyPath: keyPath, target: target, action: action)
    }
    
    /// 手工移除某个属性指定监听
    /// - Parameters:
    ///   - keyPath: 属性KeyPath
    ///   - target: 目标对象，值为nil时移除所有对象(同UIControl)
    ///   - action: 目标动作，值为nil时移除所有动作(同UIControl)
    public func unobserveProperty<Value>(_ keyPath: KeyPath<Base, Value>, target: AnyObject? = nil, action: Selector? = nil) {
        base.fw_unobserveProperty(keyPath, target: target, action: action)
    }
    
    /// 手工移除某个属性指定监听
    /// - Parameters:
    ///   - observer: 监听者
    @discardableResult
    public func unobserveProperty(observer: Any) -> Bool {
        return base.fw_unobserveProperty(observer: observer)
    }
    
    /// 手工移除所有属性所有监听
    public func unobserveAllProperties() {
        base.fw_unobserveAllProperties()
    }
    
    /// 手工添加指定监听，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - observation: 监听对象
    ///   - keyPath: 属性keyPath
    ///   - target: 目标对象
    ///   - action: 目标动作
    /// - Returns: 监听者
    @discardableResult
    public func addObservation(_ observation: NSKeyValueObservation, keyPath: AnyHashable? = nil, target: AnyObject? = nil, action: Selector? = nil) -> NSObjectProtocol {
        return base.fw_addObservation(observation, keyPath: keyPath, target: target, action: action)
    }
    
    /// 手工移除指定监听
    /// - Parameter observation: 监听对象
    /// - Returns: 是否移除成功
    @discardableResult
    public func removeObservation(_ observation: NSKeyValueObservation) -> Bool {
        return base.fw_removeObservation(observation)
    }
}

// MARK: - Message
@_spi(FW) extension WrapperCompatible where Self: AnyObject {
    
    // MARK: - Observer
    /// 监听某个点对点消息，可指定对象，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    ///   - block: 消息句柄
    /// - Returns: 监听者
    @discardableResult
    public func fw_observeMessage(_ name: Notification.Name, object: AnyObject? = nil, block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        let dict = fw_messageTargets(true)
        var array = dict?[name] as? NSMutableArray
        if array == nil {
            array = NSMutableArray()
            dict?[name] = array
        }
        
        let messageTarget = NSObject.NotificationTarget()
        messageTarget.broadcast = false
        messageTarget.object = object
        messageTarget.block = block
        array?.add(messageTarget)
        return messageTarget
    }
    
    /// 监听某个点对点消息，可指定对象，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    ///   - target: 消息目标
    ///   - action: 目标动作，参数为通知对象
    /// - Returns: 监听者
    @discardableResult
    public func fw_observeMessage(_ name: Notification.Name, object: AnyObject? = nil, target: AnyObject?, action: Selector) -> NSObjectProtocol {
        let dict = fw_messageTargets(true)
        var array = dict?[name] as? NSMutableArray
        if array == nil {
            array = NSMutableArray()
            dict?[name] = array
        }
        
        let messageTarget = NSObject.NotificationTarget()
        messageTarget.broadcast = false
        messageTarget.object = object
        messageTarget.target = target
        messageTarget.action = action
        array?.add(messageTarget)
        return messageTarget
    }
    
    /// 手工移除某个点对点消息指定监听，可指定对象
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    ///   - target: 消息目标
    ///   - action: 目标动作
    public func fw_unobserveMessage(_ name: Notification.Name, object: AnyObject? = nil, target: AnyObject?, action: Selector?) {
        guard let dict = fw_messageTargets(false) else { return }
        
        // object为nil且target为nil始终移除
        if object == nil && target == nil {
            dict.removeObject(forKey: name)
            return
        }
        
        guard let array = dict[name] as? NSMutableArray else { return }
        // object相同且target为nil时始终移除
        if target == nil {
            for (_, elem) in array.enumerated() {
                if let obj = elem as? NSObject.NotificationTarget,
                   obj.object === object {
                    array.remove(obj)
                }
            }
        // object相同且target相同且action为NULL或者action相同才移除
        } else {
            for (_, elem) in array.enumerated() {
                if let obj = elem as? NSObject.NotificationTarget,
                   object === obj.object && target === obj.target && (action == nil || action == obj.action) {
                    array.remove(obj)
                }
            }
        }
    }
    
    /// 手工移除某个指定对象点对点消息指定监听
    /// - Parameters:
    ///   - name: 消息名称
    ///   - observer: 监听者
    @discardableResult
    public func fw_unobserveMessage(_ name: Notification.Name, observer: Any) -> Bool {
        guard let observer = observer as? NSObject.NotificationTarget,
              let dict = fw_messageTargets(false),
              let array = dict[name] as? NSMutableArray else { return false }
        
        let result = array.contains(observer)
        array.remove(observer)
        return result
    }
    
    /// 手工移除某个点对点消息所有监听，可指定对象
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    public func fw_unobserveMessage(_ name: Notification.Name, object: AnyObject? = nil) {
        fw_unobserveMessage(name, object: object, target: nil, action: nil)
    }
    
    /// 手工移除所有点对点消息监听
    public func fw_unobserveAllMessages() {
        guard let dict = fw_messageTargets(false) else { return }
        dict.removeAllObjects()
    }
    
    private func fw_messageTargets(_ lazyload: Bool) -> NSMutableDictionary? {
        var targets = fw_property(forName: "fw_messageTargets") as? NSMutableDictionary
        if targets == nil && lazyload {
            targets = NSMutableDictionary()
            fw_setProperty(targets, forName: "fw_messageTargets")
        }
        return targets
    }
    
    // MARK: - Subject
    /// 发送点对点消息，附带对象和用户信息
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，默认nil
    ///   - userInfo: 用户信息，默认nil
    ///   - toReceiver: 消息接收者
    public func fw_sendMessage(_ name: Notification.Name, object: AnyObject? = nil, userInfo: [AnyHashable: Any]? = nil, toReceiver: Any) {
        NSObject.fw_sendMessage(name, object: object, userInfo: userInfo, toReceiver: toReceiver)
    }
    
    /// 发送点对点消息，附带对象和用户信息
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，默认nil
    ///   - userInfo: 用户信息，默认nil
    ///   - toReceiver: 消息接收者
    public static func fw_sendMessage(_ name: Notification.Name, object: AnyObject? = nil, userInfo: [AnyHashable: Any]? = nil, toReceiver: Any) {
        guard let receiver = toReceiver as? (any WrapperObject),
              let dict = receiver.fw_messageTargets(false),
              let array = dict[name] as? NSMutableArray else { return }
        
        let notification = Notification(name: name, object: object, userInfo: userInfo)
        for (_, elem) in array.enumerated() {
            // obj.object为nil或者obj.object和object相同才触发
            if let obj = elem as? NSObject.NotificationTarget,
               (obj.object == nil || obj.object === object) {
                obj.handle(notification)
            }
        }
    }
    
}

// MARK: - Notification
@_spi(FW) extension WrapperCompatible where Self: AnyObject {
    
    // MARK: - Observer
    /// 监听某个广播通知，可指定对象，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - block: 通知句柄
    /// - Returns: 监听者
    @discardableResult
    public func fw_observeNotification(_ name: Notification.Name, object: AnyObject? = nil, block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        let dict = fw_notificationTargets(true)
        var array = dict?[name] as? NSMutableArray
        if array == nil {
            array = NSMutableArray()
            dict?[name] = array
        }
        
        let notificationTarget = NSObject.NotificationTarget()
        notificationTarget.broadcast = true
        notificationTarget.object = object
        notificationTarget.block = block
        array?.add(notificationTarget)
        NotificationCenter.default.addObserver(notificationTarget, selector: #selector(NSObject.NotificationTarget.handle(_:)), name: name, object: object)
        return notificationTarget
    }
    
    /// 监听某个广播通知，可指定对象，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - target: 通知目标
    ///   - action: 目标动作，参数为通知对象
    /// - Returns: 监听者
    @discardableResult
    public func fw_observeNotification(_ name: Notification.Name, object: AnyObject? = nil, target: AnyObject?, action: Selector) -> NSObjectProtocol {
        let dict = fw_notificationTargets(true)
        var array = dict?[name] as? NSMutableArray
        if array == nil {
            array = NSMutableArray()
            dict?[name] = array
        }
        
        let notificationTarget = NSObject.NotificationTarget()
        notificationTarget.broadcast = true
        notificationTarget.object = object
        notificationTarget.target = target
        notificationTarget.action = action
        array?.add(notificationTarget)
        NotificationCenter.default.addObserver(notificationTarget, selector: #selector(NSObject.NotificationTarget.handle(_:)), name: name, object: object)
        return notificationTarget
    }
    
    /// 单次监听通知，触发后自动移除监听
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - queue: 通知队列
    ///   - block: 监听句柄
    public static func fw_observeOnce(
        forName name: NSNotification.Name?,
        object: Any? = nil,
        queue: OperationQueue? = nil,
        using block: @escaping (_ notification: Notification) -> Void
    ) {
        var handler: (any NSObjectProtocol)!
        let removeObserver = {
            NotificationCenter.default.removeObserver(handler!)
        }
        handler = NotificationCenter.default.addObserver(forName: name, object: object, queue: queue) {
            removeObserver()
            block($0)
        }
    }
    
    /// 手工移除某个广播通知指定监听，可指定对象
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - target: 通知目标
    ///   - action: 目标动作
    public func fw_unobserveNotification(_ name: Notification.Name, object: AnyObject? = nil, target: AnyObject?, action: Selector?) {
        guard let dict = fw_notificationTargets(false) else { return }
        
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
                if let obj = elem as? NSObject.NotificationTarget,
                   obj.object === object {
                    NotificationCenter.default.removeObserver(obj)
                    array.remove(obj)
                }
            }
        // object相同且target相同且action为NULL或者action相同才移除
        } else {
            for (_, elem) in array.enumerated() {
                if let obj = elem as? NSObject.NotificationTarget,
                   object === obj.object && target === obj.target && (action == nil || action == obj.action) {
                    NotificationCenter.default.removeObserver(obj)
                    array.remove(obj)
                }
            }
        }
    }
    
    /// 手工移除某个指定对象广播通知指定监听
    /// - Parameters:
    ///   - name: 通知名称
    ///   - observer: 监听者
    @discardableResult
    public func fw_unobserveNotification(_ name: Notification.Name, observer: Any) -> Bool {
        guard let observer = observer as? NSObject.NotificationTarget,
              let dict = fw_notificationTargets(false),
              let array = dict[name] as? NSMutableArray else { return false }
        
        var result = false
        for (_, elem) in array.enumerated() {
            if let obj = elem as? NSObject.NotificationTarget, obj == observer {
                NotificationCenter.default.removeObserver(obj)
                array.remove(obj)
                result = true
            }
        }
        return result
    }
    
    /// 手工移除某个广播通知所有监听，可指定对象
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    public func fw_unobserveNotification(_ name: Notification.Name, object: AnyObject? = nil) {
        fw_unobserveNotification(name, object: object, target: nil, action: nil)
    }
    
    /// 手工移除所有点对点消息监听
    public func fw_unobserveAllNotifications() {
        guard let dict = fw_notificationTargets(false) else { return }
        
        for (_, value) in dict {
            if let array = value as? NSArray {
                for (_, obj) in array.enumerated() {
                    NotificationCenter.default.removeObserver(obj)
                }
            }
        }
        dict.removeAllObjects()
    }
    
    private func fw_notificationTargets(_ lazyload: Bool) -> NSMutableDictionary? {
        var targets = fw_property(forName: "fw_notificationTargets") as? NSMutableDictionary
        if targets == nil && lazyload {
            targets = NSMutableDictionary()
            fw_setProperty(targets, forName: "fw_notificationTargets")
        }
        return targets
    }
    
    // MARK: - Subject
    /// 发送广播通知，附带对象和用户信息
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象
    ///   - userInfo: 用户信息
    public func fw_postNotification(_ name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
    }
    
    /// 发送广播通知，附带对象和用户信息
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象
    ///   - userInfo: 用户信息
    public static func fw_postNotification(_ name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
    }
    
}

// MARK: - KVO
@_spi(FW) extension NSObject {
    
    // MARK: - Target
    fileprivate class NotificationTarget: NSObject {
        var broadcast: Bool = false
        weak var object: AnyObject?
        weak var target: AnyObject?
        var action: Selector?
        var block: ((Notification) -> Void)?
        
        deinit {
            if broadcast {
                NotificationCenter.default.removeObserver(self)
            }
        }
        
        @objc func handle(_ notification: Notification) {
            if block != nil {
                block?(notification)
                return
            }
            
            if let target = target, let action = action, target.responds(to: action) {
                _ = target.perform(action, with: notification)
            }
        }
    }
    
    private class PropertyTarget: NSObject {
        var observation: NSKeyValueObservation?
        var keyPath: AnyHashable?
        weak var target: AnyObject?
        var action: Selector?
        
        deinit {
            removeObserver()
        }
        
        func removeObserver() {
            observation?.invalidate()
            observation = nil
        }
    }
    
    // MARK: - Observer
    /// 手工移除某个属性指定监听
    /// - Parameters:
    ///   - keyPath: 属性keyPath
    ///   - target: 目标对象，值为nil时移除所有对象(同UIControl)
    ///   - action: 目标动作，值为nil时移除所有动作(同UIControl)
    public func fw_unobserveProperty(_ keyPath: AnyHashable, target: AnyObject? = nil, action: Selector? = nil) {
        guard fw_issetPropertyTargets else { return }
        
        var removals = fw_propertyTargets.filter { $0.keyPath == keyPath }
        // target为nil时始终移除
        if target != nil {
            // 不为nil时，target相同且action为NULL或者action相同才移除
            removals = removals.filter({ target === $0.target && (action == nil || action == $0.action) })
        }
        guard !removals.isEmpty else { return }
        
        removals.forEach { $0.removeObserver() }
        fw_propertyTargets.removeAll { removals.contains($0) }
    }
    
    /// 手工移除某个属性指定监听
    /// - Parameters:
    ///   - observer: 监听者
    @discardableResult
    public func fw_unobserveProperty(observer: Any) -> Bool {
        if let observation = observer as? NSKeyValueObservation {
            return fw_removeObservation(observation)
        }
        
        guard let observer = observer as? PropertyTarget,
              fw_issetPropertyTargets else {
            return false
        }
        let removals = fw_propertyTargets.filter { $0 == observer }
        guard !removals.isEmpty else {
            return false
        }
        
        removals.forEach { $0.removeObserver() }
        fw_propertyTargets.removeAll { removals.contains($0) }
        return true
    }
    
    /// 手工移除所有属性所有监听
    public func fw_unobserveAllProperties() {
        guard fw_issetPropertyTargets else { return }
        
        let targets = fw_propertyTargets
        targets.forEach { $0.removeObserver() }
        fw_propertyTargets.removeAll()
    }
    
    /// 手工添加指定监听，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - observation: 监听对象
    ///   - keyPath: 属性keyPath
    ///   - target: 目标对象
    ///   - action: 目标动作
    /// - Returns: 监听者
    @discardableResult
    public func fw_addObservation(_ observation: NSKeyValueObservation, keyPath: AnyHashable? = nil, target: AnyObject? = nil, action: Selector? = nil) -> NSObjectProtocol {
        let target = PropertyTarget()
        target.observation = observation
        target.keyPath = keyPath
        target.target = target
        target.action = action
        fw_propertyTargets.append(target)
        return target
    }
    
    /// 手工移除指定监听
    /// - Parameter observation: 监听对象
    /// - Returns: 是否移除成功
    @discardableResult
    public func fw_removeObservation(_ observation: NSKeyValueObservation) -> Bool {
        let targets = fw_issetPropertyTargets ? fw_propertyTargets : []
        let removals = targets.filter { $0.observation == observation }
        guard !removals.isEmpty else {
            observation.invalidate()
            return false
        }
        
        removals.forEach { $0.removeObserver() }
        fw_propertyTargets.removeAll { removals.contains($0) }
        return true
    }
    
    private var fw_issetPropertyTargets: Bool {
        return fw_property(forName: "fw_propertyTargets") != nil
    }
    
    private var fw_propertyTargets: [PropertyTarget] {
        get { return fw_property(forName: "fw_propertyTargets") as? [PropertyTarget] ?? [] }
        set { fw_setProperty(newValue, forName: "fw_propertyTargets") }
    }
    
}

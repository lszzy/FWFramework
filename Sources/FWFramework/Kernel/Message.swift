//
//  Message.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/19.
//

import Foundation

// MARK: - Message
extension Wrapper where Base: WrapperObject {
    // MARK: - Observer
    /// 监听某个点对点消息，可指定对象，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    ///   - block: 消息句柄
    /// - Returns: 监听者
    @discardableResult
    public func observeMessage(_ name: Notification.Name, object: AnyObject? = nil, block: @escaping @Sendable (Notification) -> Void) -> NSObjectProtocol {
        let messageTarget = NotificationTarget()
        messageTarget.broadcast = false
        messageTarget.name = name
        messageTarget.object = object
        messageTarget.block = block
        messageTargets.append(messageTarget)
        return messageTarget
    }
    
    /// 主线程安全监听某个点对点消息，可指定对象，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    ///   - block: 消息句柄
    /// - Returns: 监听者
    @discardableResult
    public func safeObserveMessage(_ name: Notification.Name, object: AnyObject? = nil, block: @escaping @MainActor @Sendable (Notification) -> Void) -> NSObjectProtocol {
        return observeMessage(name, object: object) { notification in
            let sendableNotification = SendableObject(notification)
            DispatchQueue.fw.mainAsync {
                if let notification = sendableNotification.object as? Notification {
                    block(notification)
                }
            }
        }
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
        let messageTarget = NotificationTarget()
        messageTarget.broadcast = false
        messageTarget.name = name
        messageTarget.object = object
        messageTarget.target = target
        messageTarget.action = action
        messageTargets.append(messageTarget)
        return messageTarget
    }
    
    /// 手工移除某个点对点消息指定监听，可指定对象
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，值为nil时表示所有
    ///   - target: 消息目标
    ///   - action: 目标动作
    public func unobserveMessage(_ name: Notification.Name, object: AnyObject? = nil, target: AnyObject? = nil, action: Selector? = nil) {
        guard issetMessageTargets else { return }
        
        var removals = messageTargets.filter { $0.name == name }
        // object为nil且target为nil始终移除
        if object != nil || target != nil {
            // object相同且target为nil时始终移除
            if target == nil {
                removals = removals.filter({ $0.object === object })
            // object相同且target相同且action为NULL或者action相同才移除
            } else {
                removals = removals.filter({ object === $0.object && target === $0.target && (action == nil || action == $0.action) })
            }
        }
        guard !removals.isEmpty else { return }
        
        messageTargets.removeAll { removals.contains($0) }
    }
    
    /// 手工移除某个指定对象点对点消息指定监听
    /// - Parameters:
    ///   - observer: 监听者
    @discardableResult
    public func unobserveMessage(observer: Any) -> Bool {
        guard let observer = observer as? NotificationTarget,
              issetMessageTargets else {
            return false
        }
        
        let result = messageTargets.contains(observer)
        messageTargets.removeAll { $0 == observer }
        return result
    }
    
    /// 手工移除所有点对点消息监听
    public func unobserveAllMessages() {
        guard issetMessageTargets else { return }
        
        messageTargets.removeAll()
    }
    
    // MARK: - Subject
    /// 发送点对点消息，附带对象和用户信息
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，默认nil
    ///   - userInfo: 用户信息，默认nil
    ///   - receiver: 消息接收者
    public func sendMessage(_ name: Notification.Name, object: AnyObject? = nil, userInfo: [AnyHashable: Any]? = nil, to receiver: some WrapperObject) {
        NSObject.fw.sendMessage(name, object: object, userInfo: userInfo, to: receiver)
    }
    
    /// 发送点对点消息，附带对象和用户信息
    /// - Parameters:
    ///   - name: 消息名称
    ///   - object: 消息对象，默认nil
    ///   - userInfo: 用户信息，默认nil
    ///   - receiver: 消息接收者
    public static func sendMessage(_ name: Notification.Name, object: AnyObject? = nil, userInfo: [AnyHashable: Any]? = nil, to receiver: some WrapperObject) {
        guard receiver.fw.issetMessageTargets else { return }
        
        let notification = Notification(name: name, object: object, userInfo: userInfo)
        let observers = receiver.fw.messageTargets.filter { $0.name == name }
        for observer in observers {
            // observer.object为nil或者observer.object和object相同才触发
            if (observer.object == nil || observer.object === object) {
                observer.handle(notification)
            }
        }
    }
    
    private var issetMessageTargets: Bool {
        return property(forName: "messageTargets") != nil
    }
    
    private var messageTargets: [NotificationTarget] {
        get { return property(forName: "messageTargets") as? [NotificationTarget] ?? [] }
        set { setProperty(newValue, forName: "messageTargets") }
    }
}

// MARK: - Notification
extension Wrapper where Base: WrapperObject {
    // MARK: - Observer
    /// 监听某个广播通知，可指定对象，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - block: 通知句柄
    /// - Returns: 监听者
    @discardableResult
    public func observeNotification(_ name: Notification.Name, object: AnyObject? = nil, block: @escaping @Sendable (Notification) -> Void) -> NSObjectProtocol {
        let notificationTarget = NotificationTarget()
        notificationTarget.broadcast = true
        notificationTarget.name = name
        notificationTarget.object = object
        notificationTarget.block = block
        notificationTargets.append(notificationTarget)
        NotificationCenter.default.addObserver(notificationTarget, selector: #selector(NotificationTarget.handle(_:)), name: name, object: object)
        return notificationTarget
    }
    
    /// 主线程安全监听某个广播通知，可指定对象，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - block: 通知句柄
    /// - Returns: 监听者
    @discardableResult
    public func safeObserveNotification(_ name: Notification.Name, object: AnyObject? = nil, block: @escaping @MainActor @Sendable (Notification) -> Void) -> NSObjectProtocol {
        return observeNotification(name, object: object) { notification in
            let sendableNotification = SendableObject(notification)
            DispatchQueue.fw.mainAsync {
                if let notification = sendableNotification.object as? Notification {
                    block(notification)
                }
            }
        }
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
        let notificationTarget = NotificationTarget()
        notificationTarget.broadcast = true
        notificationTarget.name = name
        notificationTarget.object = object
        notificationTarget.target = target
        notificationTarget.action = action
        notificationTargets.append(notificationTarget)
        NotificationCenter.default.addObserver(notificationTarget, selector: #selector(NotificationTarget.handle(_:)), name: name, object: object)
        return notificationTarget
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
        using block: @escaping @Sendable (_ notification: Notification) -> Void
    ) {
        let sendableObserver = SendableObject()
        sendableObserver.object = NotificationCenter.default.addObserver(forName: name, object: object, queue: queue) { notification in
            if let observer = sendableObserver.object {
                NotificationCenter.default.removeObserver(observer)
            }
            block(notification)
        }
    }
    
    /// 主线程安全单次监听通知，触发后自动移除监听
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - block: 监听句柄
    public static func safeObserveOnce(
        forName name: NSNotification.Name?,
        object: Any? = nil,
        using block: @escaping @MainActor @Sendable (_ notification: Notification) -> Void
    ) {
        observeOnce(forName: name, object: object, queue: .main) { notification in
            let sendableNotification = SendableObject(notification)
            DispatchQueue.fw.mainAsync {
                if let notification = sendableNotification.object as? Notification {
                    block(notification)
                }
            }
        }
    }
    
    /// 手工移除某个广播通知指定监听，可指定对象
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 通知对象，值为nil时表示所有
    ///   - target: 通知目标
    ///   - action: 目标动作
    public func unobserveNotification(_ name: Notification.Name, object: AnyObject? = nil, target: AnyObject? = nil, action: Selector? = nil) {
        guard issetNotificationTargets else { return }
        
        var removals = notificationTargets.filter { $0.name == name }
        // object为nil且target为nil始终移除
        if object != nil || target != nil {
            // object相同且target为nil时始终移除
            if target == nil {
                removals = removals.filter({ $0.object === object })
            // object相同且target相同且action为NULL或者action相同才移除
            } else {
                removals = removals.filter({ object === $0.object && target === $0.target && (action == nil || action == $0.action) })
            }
        }
        guard !removals.isEmpty else { return }
        
        removals.forEach { NotificationCenter.default.removeObserver($0) }
        notificationTargets.removeAll { removals.contains($0) }
    }
    
    /// 手工移除某个指定对象广播通知指定监听
    /// - Parameters:
    ///   - observer: 监听者
    @discardableResult
    public func unobserveNotification(observer: Any) -> Bool {
        guard let observer = observer as? NotificationTarget,
              issetNotificationTargets else {
            return false
        }
        let removals = notificationTargets.filter { $0 == observer }
        guard !removals.isEmpty else {
            return false
        }
        
        removals.forEach { NotificationCenter.default.removeObserver($0) }
        notificationTargets.removeAll { removals.contains($0) }
        return true
    }
    
    /// 手工移除所有点对点消息监听
    public func unobserveAllNotifications() {
        guard issetNotificationTargets else { return }
        
        let targets = notificationTargets
        targets.forEach { NotificationCenter.default.removeObserver($0) }
        notificationTargets.removeAll()
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
    
    private var issetNotificationTargets: Bool {
        return property(forName: "notificationTargets") != nil
    }
    
    private var notificationTargets: [NotificationTarget] {
        get { return property(forName: "notificationTargets") as? [NotificationTarget] ?? [] }
        set { setProperty(newValue, forName: "notificationTargets") }
    }
}

// MARK: - KVO
/// Swift自带KeyPath监听(声明@objc dynamic)、didSet属性监听等；
/// SwiftUI自带Combine订阅等方式，建议优先使用；
/// 如不满足需求时，才考虑使用KVO属性名监听方式
extension Wrapper where Base: NSObject {
    /// 监听对象某个属性KeyPath，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - keyPath: 属性KeyPath
    ///   - options: 监听选项
    ///   - block: 目标句柄，block参数依次为object、change对象
    /// - Returns: 监听者
    @discardableResult
    public func observeProperty<Value>(_ keyPath: KeyPath<Base, Value>, options: NSKeyValueObservingOptions = [], block: @escaping @Sendable (Base, NSKeyValueObservedChange<Value>) -> Void) -> NSObjectProtocol {
        let observation = base.observe(keyPath, options: options, changeHandler: block)
        return addObservation(observation, keyPath: keyPath)
    }
    
    /// 主线程安全监听对象某个属性KeyPath，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - keyPath: 属性KeyPath
    ///   - options: 监听选项
    ///   - block: 目标句柄，block参数依次为object、change对象
    /// - Returns: 监听者
    @discardableResult
    public func safeObserveProperty<Value>(_ keyPath: KeyPath<Base, Value>, options: NSKeyValueObservingOptions = [], block: @escaping @MainActor @Sendable (Base, NSKeyValueObservedChange<Value>) -> Void) -> NSObjectProtocol where Base: Sendable, Value: Sendable {
        return observeProperty(keyPath, options: options) { object, change in
            DispatchQueue.fw.mainAsync {
                block(object, change)
            }
        }
    }
    
    /// 监听对象某个属性KeyPath，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - keyPath: 属性KeyPath
    ///   - options: 监听选项
    ///   - target: 目标对象
    ///   - action: 目标动作，action参数依次为object、change对象
    /// - Returns: 监听者
    @discardableResult
    public func observeProperty<Value>(_ keyPath: KeyPath<Base, Value>, options: NSKeyValueObservingOptions = [], target: AnyObject?, action: Selector) -> NSObjectProtocol {
        let weakObject = WeakObject(target)
        let observation = base.observe(keyPath, options: options) { object, change in
            if let weakTarget = weakObject.object, weakTarget.responds(to: action) {
                _ = weakTarget.perform(action, with: object, with: change)
            }
        }
        return addObservation(observation, keyPath: keyPath, target: target, action: action)
    }
    
    /// 监听对象某个属性，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - property: 属性名称
    ///   - block: 目标句柄，block参数依次为object、优化的change字典(不含NSNull)
    /// - Returns: 监听者
    @discardableResult
    public func observeProperty(_ property: String, block: @escaping @Sendable (Base, [NSKeyValueChangeKey: Any]) -> Void) -> NSObjectProtocol {
        let target = PropertyTarget()
        target.isKvo = true
        target.object = base
        target.keyPath = property
        target.block = { object, change in
            block(object as! Base, change)
        }
        propertyTargets.append(target)
        target.addObserver()
        return target
    }
    
    /// 主线程安全监听对象某个属性，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - property: 属性名称
    ///   - block: 目标句柄，block参数依次为object、优化的change字典(不含NSNull)
    /// - Returns: 监听者
    @discardableResult
    public func safeObserveProperty(_ property: String, block: @escaping @MainActor @Sendable (Base, [NSKeyValueChangeKey: Any]) -> Void) -> NSObjectProtocol where Base: Sendable {
        return observeProperty(property) { object, change in
            let sendableChange = SendableObject(change)
            DispatchQueue.fw.mainAsync {
                if let change = sendableChange.object as? [NSKeyValueChangeKey: Any] {
                    block(object, change)
                }
            }
        }
    }
    
    /// 监听对象某个属性，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - property: 属性名称
    ///   - target: 目标对象
    ///   - action: 目标动作，action参数依次为object、优化的change字典(不含NSNull)
    /// - Returns: 监听者
    @discardableResult
    public func observeProperty(_ property: String, target: AnyObject?, action: Selector) -> NSObjectProtocol {
        let target = PropertyTarget()
        target.isKvo = true
        target.object = base
        target.keyPath = property
        target.target = target
        target.action = action
        propertyTargets.append(target)
        target.addObserver()
        return target
    }
    
    /// 手工移除某个属性指定KeyPath监听
    /// - Parameters:
    ///   - keyPath: 属性KeyPath
    ///   - target: 目标对象，值为nil时移除所有对象(同UIControl)
    ///   - action: 目标动作，值为nil时移除所有动作(同UIControl)
    public func unobserveProperty<Value>(_ keyPath: KeyPath<Base, Value>, target: AnyObject? = nil, action: Selector? = nil) {
        unobserveProperty(keyPath: keyPath, target: target, action: action)
    }
    
    /// 手工移除某个属性指定监听
    /// - Parameters:
    ///   - property: 属性名称
    ///   - target: 目标对象，值为nil时移除所有对象(同UIControl)
    ///   - action: 目标动作，值为nil时移除所有动作(同UIControl)
    public func unobserveProperty(_ property: String, target: AnyObject? = nil, action: Selector? = nil) {
        unobserveProperty(keyPath: property, target: target, action: action)
    }
    
    private func unobserveProperty(keyPath: AnyHashable, target: AnyObject?, action: Selector?) {
        guard issetPropertyTargets else { return }
        
        var removals = propertyTargets.filter { $0.keyPath == keyPath }
        // target为nil时始终移除
        if target != nil {
            // 不为nil时，target相同且action为NULL或者action相同才移除
            removals = removals.filter({ target === $0.target && (action == nil || action == $0.action) })
        }
        guard !removals.isEmpty else { return }
        
        removals.forEach { $0.removeObserver() }
        propertyTargets.removeAll { removals.contains($0) }
    }
    
    /// 手工移除某个属性指定监听
    /// - Parameters:
    ///   - observer: 监听者
    @discardableResult
    public func unobserveProperty(observer: Any) -> Bool {
        if let observation = observer as? NSKeyValueObservation {
            return removeObservation(observation)
        }
        
        guard let observer = observer as? PropertyTarget,
              issetPropertyTargets else {
            return false
        }
        let removals = propertyTargets.filter { $0 == observer }
        guard !removals.isEmpty else {
            return false
        }
        
        removals.forEach { $0.removeObserver() }
        propertyTargets.removeAll { removals.contains($0) }
        return true
    }
    
    /// 手工移除所有属性所有监听
    public func unobserveAllProperties() {
        guard issetPropertyTargets else { return }
        
        let targets = propertyTargets
        targets.forEach { $0.removeObserver() }
        propertyTargets.removeAll()
    }
    
    /// 手工添加指定KeyPath监听，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - observation: 监听对象
    ///   - keyPath: 属性keyPath
    ///   - target: 目标对象
    ///   - action: 目标动作
    /// - Returns: 监听者
    @discardableResult
    public func addObservation(_ observation: NSKeyValueObservation, keyPath: AnyHashable? = nil, target: AnyObject? = nil, action: Selector? = nil) -> NSObjectProtocol {
        let target = PropertyTarget()
        target.observation = observation
        target.keyPath = keyPath
        target.target = target
        target.action = action
        propertyTargets.append(target)
        return target
    }
    
    /// 手工移除指定KeyPath监听
    /// - Parameter observation: 监听对象
    /// - Returns: 是否移除成功
    @discardableResult
    public func removeObservation(_ observation: NSKeyValueObservation) -> Bool {
        let targets = issetPropertyTargets ? propertyTargets : []
        let removals = targets.filter { $0.observation == observation }
        guard !removals.isEmpty else {
            observation.invalidate()
            return false
        }
        
        removals.forEach { $0.removeObserver() }
        propertyTargets.removeAll { removals.contains($0) }
        return true
    }
    
    private var issetPropertyTargets: Bool {
        return property(forName: "propertyTargets") != nil
    }
    
    private var propertyTargets: [PropertyTarget] {
        get { return property(forName: "propertyTargets") as? [PropertyTarget] ?? [] }
        set { setProperty(newValue, forName: "propertyTargets") }
    }
}

// MARK: - NotificationTarget
fileprivate class NotificationTarget: NSObject {
    var broadcast: Bool = false
    var name: Notification.Name?
    weak var object: AnyObject?
    weak var target: AnyObject?
    var action: Selector?
    var block: (@Sendable (Notification) -> Void)?
    
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

// MARK: - PropertyTarget
fileprivate class PropertyTarget: NSObject {
    var observation: NSKeyValueObservation?
    var keyPath: AnyHashable?
    weak var target: AnyObject?
    var action: Selector?
    
    var isKvo: Bool = false
    unowned(unsafe) var object: AnyObject?
    var block: (@Sendable (Any, [NSKeyValueChangeKey: Any]) -> Void)?
    private var isObserving = false
    
    deinit {
        removeObserver()
    }
    
    func removeObserver() {
        guard isKvo else {
            observation?.invalidate()
            observation = nil
            return
        }
        
        guard isObserving, let object = object as? NSObject, let keyPath = keyPath as? String else { return }
        isObserving = false
        object.removeObserver(self, forKeyPath: keyPath)
    }
    
    func addObserver() {
        guard isKvo else { return }
        
        guard !isObserving, let object = object as? NSObject, let keyPath = keyPath as? String else { return }
        isObserving = true
        object.addObserver(self, forKeyPath: keyPath, options: [.old, .new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let object = object else { return }
        
        var newChange = change ?? [:]
        if newChange[.oldKey] is NSNull {
            newChange.removeValue(forKey: .oldKey)
        }
        if newChange[.newKey] is NSNull {
            newChange.removeValue(forKey: .newKey)
        }
        
        if block != nil {
            block?(object, newChange)
            return
        }
        
        if let target = target, let action = action, target.responds(to: action) {
            _ = target.perform(action, with: object, with: newChange)
        }
    }
}

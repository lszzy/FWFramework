//
//  Message+Wrapper.swift
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

// MARK: - KVO
extension Wrapper where Base: NSObject {
    
    /// 监听对象某个属性，对象释放时自动移除监听，添加多次执行多次
    /// - Parameters:
    ///   - property: 属性名称
    ///   - block: 目标句柄，block参数依次为object、优化的change字典(不含NSNull)
    /// - Returns: 监听者
    @discardableResult
    public func observeProperty(_ property: String, block: @escaping (Base, [NSKeyValueChangeKey: Any]) -> Void) -> NSObjectProtocol {
        return base.fw_observeProperty(property) { object, change in
            block(object as! Base, change)
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
        return base.fw_observeProperty(property, target: target, action: action)
    }
    
    /// 手工移除某个属性指定监听
    /// - Parameters:
    ///   - property: 属性名称
    ///   - target: 目标对象，值为nil时移除所有对象(同UIControl)
    ///   - action: 目标动作，值为nil时移除所有动作(同UIControl)
    public func unobserveProperty(_ property: String, target: AnyObject?, action: Selector?) {
        base.fw_unobserveProperty(property, target: target, action: action)
    }
    
    /// 手工移除某个属性指定监听
    /// - Parameters:
    ///   - property: 属性名称
    ///   - observer: 监听者
    @discardableResult
    public func unobserveProperty(_ property: String, observer: Any) -> Bool {
        return base.fw_unobserveProperty(property, observer: observer)
    }
    
    /// 手工移除某个属性所有监听
    /// - Parameter property: 属性名称
    public func unobserveProperty(_ property: String) {
        base.fw_unobserveProperty(property)
    }
    
    /// 手工移除所有属性所有监听
    public func unobserveAllProperties() {
        base.fw_unobserveAllProperties()
    }
    
}

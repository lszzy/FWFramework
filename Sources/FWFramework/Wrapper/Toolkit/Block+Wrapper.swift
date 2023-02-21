//
//  Block+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - DispatchQueue+Block
extension Wrapper where Base: DispatchQueue {
    
    /// 主线程安全异步执行句柄
    public static func mainAsync(execute block: @escaping () -> Void) {
        Base.fw_mainAsync(execute: block)
    }
    
}

// MARK: - Timer+Block
extension Wrapper where Base: Timer {
    
    /// 创建Timer，使用target-action，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - target: 目标
    ///   - selector: 方法
    ///   - userInfo: 参数
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func commonTimer(timeInterval: TimeInterval, target: Any, selector: Selector, userInfo: Any?, repeats: Bool) -> Timer {
        return Base.fw_commonTimer(timeInterval: timeInterval, target: target, selector: selector, userInfo: userInfo, repeats: repeats)
    }

    /// 创建Timer，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - block: 代码块
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func commonTimer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        return Base.fw_commonTimer(timeInterval: timeInterval, block: block, repeats: repeats)
    }

    /// 创建倒计时定时器
    /// - Parameters:
    ///   - countDown: 倒计时时间
    ///   - block: 每秒执行block，为0时自动停止
    /// - Returns: 定时器，可手工停止
    public static func commonTimer(countDown: Int, block: @escaping (Int) -> Void) -> Timer {
        return Base.fw_commonTimer(countDown: countDown, block: block)
    }

    /// 创建Timer，使用block，需要调用addTimer:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
    ///
    /// 示例：[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes]
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - block: 代码块
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func timer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        return Base.fw_timer(timeInterval: timeInterval, block: block, repeats: repeats)
    }

    /// 创建Timer，使用block，默认模式安排到当前的运行循环中
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - block: 代码块
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func scheduledTimer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        return Base.fw_scheduledTimer(timeInterval: timeInterval, block: block, repeats: repeats)
    }
    
    /// 暂停NSTimer
    public func pauseTimer() {
        base.fw_pauseTimer()
    }

    /// 开始NSTimer
    public func resumeTimer() {
        base.fw_resumeTimer()
    }

    /// 延迟delay秒后开始NSTimer
    public func resumeTimer(afterDelay delay: TimeInterval) {
        base.fw_resumeTimer(afterDelay: delay)
    }
    
}

// MARK: - UIGestureRecognizer+Block
extension Wrapper where Base: UIGestureRecognizer {
    
    /// 从事件句柄初始化
    public static func gestureRecognizer(block: @escaping (Base) -> Void) -> Base {
        return Base.fw_gestureRecognizer { sender in
            block(sender as! Base)
        }
    }
    
    /// 添加事件句柄，返回监听唯一标志
    @discardableResult
    public func addBlock(_ block: @escaping (Base) -> Void) -> String {
        return base.fw_addBlock { sender in
            block(sender as! Base)
        }
    }

    /// 根据监听唯一标志移除事件句柄，返回是否成功
    @discardableResult
    public func removeBlock(identifier: String) -> Bool {
        return base.fw_removeBlock(identifier: identifier)
    }

    /// 移除所有事件句柄
    public func removeAllBlocks() {
        base.fw_removeAllBlocks()
    }
    
}

// MARK: UIView+Block
extension Wrapper where Base: UIView {
    
    /// 获取当前视图添加的第一个点击手势，默认nil
    public var tapGesture: UITapGestureRecognizer? {
        return base.fw_tapGesture
    }
    
    /// 添加点击手势事件，可自定义点击高亮句柄等
    public func addTapGesture(target: Any, action: Selector, customize: ((TapGestureRecognizer) -> Void)? = nil) {
        base.fw_addTapGesture(target: target, action: action, customize: customize)
    }

    /// 添加点击手势句柄，可自定义点击高亮句柄等
    @discardableResult
    public func addTapGesture(block: @escaping (UITapGestureRecognizer) -> Void, customize: ((TapGestureRecognizer) -> Void)? = nil) -> String {
        return base.fw_addTapGesture(block: { sender in
            block(sender as! UITapGestureRecognizer)
        }, customize: customize)
    }

    /// 根据监听唯一标志移除点击手势句柄，返回是否成功
    @discardableResult
    public func removeTapGesture(identifier: String) -> Bool {
        return base.fw_removeTapGesture(identifier: identifier)
    }

    /// 移除所有点击手势
    public func removeAllTapGestures() {
        base.fw_removeAllTapGestures()
    }
    
}

// MARK: UIControl+Block
extension Wrapper where Base: UIControl {
    
    /// 添加事件句柄，返回监听唯一标志
    @discardableResult
    public func addBlock(_ block: @escaping (Base) -> Void, for controlEvents: UIControl.Event) -> String {
        return base.fw_addBlock({ sender in
            block(sender as! Base)
        }, for: controlEvents)
    }

    /// 根据监听唯一标志移除事件句柄
    @discardableResult
    public func removeBlock(identifier: String, for controlEvents: UIControl.Event) -> Bool {
        return base.fw_removeBlock(identifier: identifier, for: controlEvents)
    }

    /// 移除所有事件句柄
    @discardableResult
    public func removeAllBlocks(for controlEvents: UIControl.Event) -> Bool {
        return base.fw_removeAllBlocks(for: controlEvents)
    }

    /// 添加点击事件
    public func addTouch(target: Any, action: Selector) {
        base.fw_addTouch(target: target, action: action)
    }

    /// 添加点击句柄，返回监听唯一标志
    @discardableResult
    public func addTouch(block: @escaping (Base) -> Void) -> String {
        return base.fw_addTouch { sender in
            block(sender as! Base)
        }
    }

    /// 根据监听唯一标志移除点击句柄
    @discardableResult
    public func removeTouchBlock(identifier: String) -> Bool {
        base.fw_removeTouchBlock(identifier: identifier)
    }
    
    /// 移除所有点击句柄
    public func removeAllTouchBlocks() {
        base.fw_removeAllTouchBlocks()
    }
    
}

// MARK: UIBarButtonItem+Block
/// iOS11之后，customView必须具有intrinsicContentSize值才能点击，可使用frame布局或者实现intrinsicContentSize即可
extension Wrapper where Base: UIBarButtonItem {
    
    /// 使用指定对象和事件创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func item(object: Any?, target: Any?, action: Selector?) -> Base {
        return Base.fw_item(object: object, target: target, action: action)
    }

    /// 使用指定对象和句柄创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func item(object: Any?, block: ((UIBarButtonItem) -> Void)?) -> Base {
        return Base.fw_item(object: object, block: block)
    }
    
    /// 自定义标题样式属性，兼容appearance，默认nil同系统
    public var titleAttributes: [NSAttributedString.Key: Any]? {
        get { base.fw_titleAttributes }
        set { base.fw_titleAttributes = newValue }
    }
    
    /// 设置当前Item触发句柄，nil时清空句柄
    public func setBlock(_ block: ((UIBarButtonItem) -> Void)?) {
        base.fw_setBlock(block)
    }
    
}

// MARK: UIViewController+Block
extension Wrapper where Base: UIViewController {

    /// 快捷设置导航栏标题文字
    public var title: String? {
        get { base.fw_title }
        set { base.fw_title = newValue }
    }
    
    /// 设置导航栏返回按钮，支持UIBarButtonItem|NSString|UIImage等，nil时显示系统箭头，下个页面生效
    public var backBarItem: Any? {
        get { base.fw_backBarItem }
        set { base.fw_backBarItem = newValue }
    }
    
    /// 设置导航栏左侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面，下个页面生效
    public var leftBarItem: Any? {
        get { base.fw_leftBarItem }
        set { base.fw_leftBarItem = newValue }
    }
    
    /// 设置导航栏右侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面，下个页面生效
    public var rightBarItem: Any? {
        get { base.fw_rightBarItem }
        set { base.fw_rightBarItem = newValue }
    }
    
    /// 快捷设置导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
    public func setLeftBarItem(_ object: Any?, target: Any, action: Selector) {
        base.fw_setLeftBarItem(object, target: target, action: action)
    }
    
    /// 快捷设置导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
    public func setLeftBarItem(_ object: Any?, block: @escaping (UIBarButtonItem) -> Void) {
        base.fw_setLeftBarItem(object, block: block)
    }
    
    /// 快捷设置导航栏右侧按钮
    public func setRightBarItem(_ object: Any?, target: Any, action: Selector) {
        base.fw_setRightBarItem(object, target: target, action: action)
    }
    
    /// 快捷设置导航栏右侧按钮，block事件
    public func setRightBarItem(_ object: Any?, block: @escaping (UIBarButtonItem) -> Void) {
        base.fw_setRightBarItem(object, block: block)
    }

    /// 快捷添加导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
    public func addLeftBarItem(_ object: Any?, target: Any, action: Selector) {
        base.fw_addLeftBarItem(object, target: target, action: action)
    }

    /// 快捷添加导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
    public func addLeftBarItem(_ object: Any?, block: @escaping (UIBarButtonItem) -> Void) {
        base.fw_addLeftBarItem(object, block: block)
    }

    /// 快捷添加导航栏右侧按钮
    public func addRightBarItem(_ object: Any?, target: Any, action: Selector) {
        base.fw_addRightBarItem(object, target: target, action: action)
    }

    /// 快捷添加导航栏右侧按钮，block事件
    public func addRightBarItem(_ object: Any?, block: @escaping (UIBarButtonItem) -> Void) {
        base.fw_addRightBarItem(object, block: block)
    }
    
}

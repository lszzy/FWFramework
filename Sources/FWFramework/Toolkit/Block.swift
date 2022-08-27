//
//  Block.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - FW+Block
extension FW {

    /// 通用互斥锁方法
    public static func synchronized(_ object: AnyObject, closure: () -> Void) {
        __FWSynchronized(object, closure)
    }
    
    /// 通用互斥锁泛型方法
    public func synchronized<T>(_ object: AnyObject, closure: () -> T) -> T {
        var result: T? = nil
        __FWSynchronized(object) {
            result = closure()
        }
        return result!
    }
    
}

// MARK: - Block
/// 通用无参数block
public typealias BlockVoid = () -> ()

/// 通用Any参数block
public typealias BlockParam = (Any?) -> ()

/// 通用Bool参数block
public typealias BlockBool = (Bool) -> ()

/// 通用Int参数block
public typealias BlockInt = (Int) -> ()

/// 通用Double参数block
public typealias BlockDouble = (Double) -> ()

/// 通用(Bool, Any)参数block
public typealias BlockBoolParam = (Bool, Any?) -> ()

/// 通用(Int, Any)参数block
public typealias BlockIntParam = (Int, Any?) -> ()

// MARK: Timer+Block
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
        return Base.__fw_commonTimer(withTimeInterval: timeInterval, target: target, selector: selector, userInfo: userInfo, repeats: repeats)
    }

    /// 创建Timer，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - block: 代码块
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func commonTimer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        return Base.__fw_commonTimer(withTimeInterval: timeInterval, block: block, repeats: repeats)
    }

    /// 创建倒计时定时器
    /// - Parameters:
    ///   - countDown: 倒计时时间
    ///   - block: 每秒执行block，为0时自动停止
    /// - Returns: 定时器，可手工停止
    public static func commonTimer(countDown: Int, block: @escaping (Int) -> Void) -> Timer {
        return Base.__fw_commonTimer(withCountDown: countDown, block: block)
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
        return Base.__fw_timer(withTimeInterval: timeInterval, block: block, repeats: repeats)
    }

    /// 创建Timer，使用block，默认模式安排到当前的运行循环中
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - block: 代码块
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func scheduledTimer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        return Base.__fw_scheduledTimer(withTimeInterval: timeInterval, block: block, repeats: repeats)
    }
    
    /// 暂停NSTimer
    public func pauseTimer() {
        base.__fw_pause()
    }

    /// 开始NSTimer
    public func resumeTimer() {
        base.__fw_resumeTimer()
    }

    /// 延迟delay秒后开始NSTimer
    public func resumeTimer(afterDelay: TimeInterval) {
        base.__fw_resumeTimer(afterDelay: afterDelay)
    }
    
}

// MARK: - UIGestureRecognizer+Block
extension Wrapper where Base: UIGestureRecognizer {
    
    /// 从事件句柄初始化
    public static func gestureRecognizer(block: @escaping (Any) -> Void) -> Base {
        return Base.__fw_gestureRecognizer(block)
    }
    
    /// 添加事件句柄，返回唯一标志
    @discardableResult
    public func addBlock(_ block: @escaping (Any) -> Void) -> String {
        return base.__fw_add(block)
    }

    /// 根据唯一标志移除事件句柄
    public func removeBlock(_ identifier: String?) {
        base.__fw_removeBlock(identifier)
    }

    /// 移除所有事件句柄
    public func removeAllBlocks() {
        base.__fw_removeAllBlocks()
    }
    
}

// MARK: UIView+Block
extension Wrapper where Base: UIView {
    
    /// 添加点击手势事件，默认子视图也会响应此事件。如要屏蔽之，解决方法：1、子视图设为UIButton；2、子视图添加空手势事件
    public func addTapGesture(target: Any, action: Selector) {
        base.__fw_addTapGesture(withTarget: target, action: action)
    }

    /// 添加点击手势句柄，同上
    @discardableResult
    public func addTapGesture(block: @escaping (Any) -> Void) -> String {
        return base.__fw_addTapGesture(block)
    }

    /// 根据唯一标志移除点击手势句柄
    public func removeTapGesture(_ identifier: String?) {
        base.__fw_removeTapGesture(identifier)
    }

    /// 移除所有点击手势
    public func removeAllTapGestures() {
        base.__fw_removeAllTapGestures()
    }
    
}

// MARK: UIControl+Block
extension Wrapper where Base: UIControl {
    
    /// 添加事件句柄
    @discardableResult
    public func addBlock(_ block: @escaping (Any) -> Void, for controlEvents: UIControl.Event) -> String {
        return base.__fw_add(block, for: controlEvents)
    }

    /// 根据唯一标志移除事件句柄
    public func removeBlock(_ identifier: String?, for controlEvents: UIControl.Event) {
        base.__fw_removeBlock(identifier, for: controlEvents)
    }

    /// 移除所有事件句柄
    public func removeAllBlocks(for controlEvents: UIControl.Event) {
        base.__fw_removeAllBlocks(for: controlEvents)
    }

    /// 添加点击事件
    public func addTouch(target: Any, action: Selector) {
        base.__fw_addTouchTarget(target, action: action)
    }

    /// 添加点击句柄
    @discardableResult
    public func addTouch(block: @escaping (Any) -> Void) -> String {
        return base.__fw_addTouch(block)
    }

    /// 根据唯一标志移除点击句柄
    public func removeTouchBlock(_ identifier: String?) {
        base.__fw_removeTouchBlock(identifier)
    }
    
    /// 移除所有点击句柄
    public func removeAllTouchBlocks() {
        base.__fw_removeAllTouchBlocks()
    }
    
}

// MARK: UIBarButtonItem+Block
/// iOS11之后，customView必须具有intrinsicContentSize值才能点击，可使用frame布局或者实现intrinsicContentSize即可
extension Wrapper where Base: UIBarButtonItem {
    
    /// 使用指定对象和事件创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func item(object: Any?, target: Any?, action: Selector?) -> UIBarButtonItem {
        return Base.__fw_item(with: object, target: target, action: action)
    }

    /// 使用指定对象和句柄创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func item(object: Any?, block: ((Any) -> Void)?) -> UIBarButtonItem {
        return Base.__fw_item(with: object, block: block)
    }
    
    /// 自定义标题样式属性，兼容appearance，默认nil同系统
    public var titleAttributes: [NSAttributedString.Key: Any]? {
        get { return base.__fw_titleAttributes }
        set { base.__fw_titleAttributes = newValue }
    }
    
    /// 设置当前Item触发句柄，nil时清空句柄
    public func setBlock(_ block: ((Any) -> Void)?) {
        base.__fw_setBlock(block)
    }
    
}

// MARK: UIViewController+Block
extension Wrapper where Base: UIViewController {

    /// 快捷设置导航栏标题文字
    public var title: String? {
        get { return base.__fw_title }
        set { base.__fw_title = newValue }
    }
    
    /// 设置导航栏返回按钮，支持UIBarButtonItem|NSString|UIImage等，nil时显示系统箭头，下个页面生效
    public var backBarItem: Any? {
        get { return base.__fw_backBarItem }
        set { base.__fw_backBarItem = newValue }
    }
    
    /// 设置导航栏左侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面，下个页面生效
    public var leftBarItem: Any? {
        get { return base.__fw_leftBarItem }
        set { base.__fw_leftBarItem = newValue }
    }
    
    /// 设置导航栏右侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面，下个页面生效
    public var rightBarItem: Any? {
        get { return base.__fw_rightBarItem }
        set { base.__fw_rightBarItem = newValue }
    }
    
    /// 快捷设置导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
    public func setLeftBarItem(_ object: Any?, target: Any, action: Selector) {
        base.__fw_setLeftBarItem(object, target: target, action: action)
    }
    
    /// 快捷设置导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
    public func setLeftBarItem(_ object: Any?, block: @escaping (Any) -> Void) {
        base.__fw_setLeftBarItem(object, block: block)
    }
    
    /// 快捷设置导航栏右侧按钮
    public func setRightBarItem(_ object: Any?, target: Any, action: Selector) {
        base.__fw_setRightBarItem(object, target: target, action: action)
    }
    
    /// 快捷设置导航栏右侧按钮，block事件
    public func setRightBarItem(_ object: Any?, block: @escaping (Any) -> Void) {
        base.__fw_setRightBarItem(object, block: block)
    }

    /// 快捷添加导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
    public func addLeftBarItem(_ object: Any?, target: Any, action: Selector) {
        base.__fw_addLeftBarItem(object, target: target, action: action)
    }

    /// 快捷添加导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
    public func addLeftBarItem(_ object: Any?, block: @escaping (Any) -> Void) {
        base.__fw_addLeftBarItem(object, block: block)
    }

    /// 快捷添加导航栏右侧按钮
    public func addRightBarItem(_ object: Any?, target: Any, action: Selector) {
        base.__fw_addRightBarItem(object, target: target, action: action)
    }

    /// 快捷添加导航栏右侧按钮，block事件
    public func addRightBarItem(_ object: Any?, block: @escaping (Any) -> Void) {
        base.__fw_addRightBarItem(object, block: block)
    }
    
}

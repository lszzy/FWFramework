//
//  Block.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import UIKit
#if FWMacroSPM
import FWFramework
#endif

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
        return Base.__fw.commonTimer(withTimeInterval: timeInterval, target: target, selector: selector, userInfo: userInfo, repeats: repeats)
    }

    /// 创建Timer，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - block: 代码块
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func commonTimer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        return Base.__fw.commonTimer(withTimeInterval: timeInterval, block: block, repeats: repeats)
    }

    /// 创建倒计时定时器
    /// - Parameters:
    ///   - countDown: 倒计时时间
    ///   - block: 每秒执行block，为0时自动停止
    /// - Returns: 定时器，可手工停止
    public static func commonTimer(countDown: Int, block: @escaping (Int) -> Void) -> Timer {
        return Base.__fw.commonTimer(withCountDown: countDown, block: block)
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
        return Base.__fw.timer(withTimeInterval: timeInterval, block: block, repeats: repeats)
    }

    /// 创建Timer，使用block，默认模式安排到当前的运行循环中
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - block: 代码块
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func scheduledTimer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        return Base.__fw.scheduledTimer(withTimeInterval: timeInterval, block: block, repeats: repeats)
    }
    
    /// 暂停NSTimer
    public func pauseTimer() {
        base.__fw.pauseTimer()
    }

    /// 开始NSTimer
    public func resumeTimer() {
        base.__fw.resumeTimer()
    }

    /// 延迟delay秒后开始NSTimer
    public func resumeTimer(afterDelay: TimeInterval) {
        base.__fw.resumeTimer(afterDelay: afterDelay)
    }
    
}

// MARK: - UIGestureRecognizer+Block
extension Wrapper where Base: UIGestureRecognizer {
    
    /// 从事件句柄初始化
    public static func gestureRecognizer(block: @escaping (Any) -> Void) -> Base {
        return Base.__fw.gestureRecognizer(block) as! Base
    }
    
    /// 添加事件句柄，返回唯一标志
    @discardableResult
    public func addBlock(_ block: @escaping (Any) -> Void) -> String {
        return base.__fw.add(block)
    }

    /// 根据唯一标志移除事件句柄
    public func removeBlock(_ identifier: String?) {
        base.__fw.removeBlock(identifier)
    }

    /// 移除所有事件句柄
    public func removeAllBlocks() {
        base.__fw.removeAllBlocks()
    }
    
}

// MARK: UIView+Block
extension Wrapper where Base: UIView {
    
    /// 添加点击手势事件，默认子视图也会响应此事件。如要屏蔽之，解决方法：1、子视图设为UIButton；2、子视图添加空手势事件
    public func addTapGesture(target: Any, action: Selector) {
        base.__fw.addTapGesture(withTarget: target, action: action)
    }

    /// 添加点击手势句柄，同上
    @discardableResult
    public func addTapGesture(block: @escaping (Any) -> Void) -> String {
        return base.__fw.addTapGesture(block)
    }

    /// 根据唯一标志移除点击手势句柄
    public func removeTapGesture(_ identifier: String?) {
        base.__fw.removeTapGesture(identifier)
    }

    /// 移除所有点击手势
    public func removeAllTapGestures() {
        base.__fw.removeAllTapGestures()
    }
    
}

// MARK: UIControl+Block
extension Wrapper where Base: UIControl {
    
    /// 添加事件句柄
    @discardableResult
    public func addBlock(_ block: @escaping (Any) -> Void, for controlEvents: UIControl.Event) -> String {
        return base.__fw.add(block, for: controlEvents)
    }

    /// 根据唯一标志移除事件句柄
    public func removeBlock(_ identifier: String?, for controlEvents: UIControl.Event) {
        base.__fw.removeBlock(identifier, for: controlEvents)
    }

    /// 移除所有事件句柄
    public func removeAllBlocks(for controlEvents: UIControl.Event) {
        base.__fw.removeAllBlocks(for: controlEvents)
    }

    /// 添加点击事件
    public func addTouch(target: Any, action: Selector) {
        base.__fw.addTouchTarget(target, action: action)
    }

    /// 添加点击句柄
    public func addTouchBlock(_ block: @escaping (Any) -> Void) -> String {
        return base.__fw.addTouch(block)
    }

    /// 根据唯一标志移除点击句柄
    public func removeTouchBlock(_ identifier: String?) {
        base.__fw.removeTouchBlock(identifier)
    }
    
}

// MARK: UIBarButtonItem+Block
/// iOS11之后，customView必须具有intrinsicContentSize值才能点击，可使用frame布局或者实现intrinsicContentSize即可
extension Wrapper where Base: UIBarButtonItem {
    
    /// 使用指定对象和事件创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func item(object: Any?, target: Any?, action: Selector?) -> UIBarButtonItem {
        return UIBarButtonItem.__fw.item(with: object, target: target, action: action)
    }

    /// 使用指定对象和句柄创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func item(object: Any?, block: ((Any) -> Void)?) -> UIBarButtonItem {
        return UIBarButtonItem.__fw.item(with: object, block: block)
    }
    
    /// 设置当前Item触发句柄，nil时清空句柄
    public func setBlock(_ block: ((Any) -> Void)?) {
        base.__fw.setBlock(block)
    }
    
}

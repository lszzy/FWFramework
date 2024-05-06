//
//  Block.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - Wrapper+DispatchQueue
extension Wrapper where Base: DispatchQueue {
    /// 主线程安全异步执行句柄
    public static func mainAsync(execute block: @escaping () -> Void) {
        Base.fw_mainAsync(execute: block)
    }
}

// MARK: - Wrapper+Timer
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

// MARK: - Wrapper+UIGestureRecognizer
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

// MARK: - Wrapper+UIView
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

// MARK: - Wrapper+UIControl
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

// MARK: - Wrapper+UIBarButtonItem
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

// MARK: - Wrapper+UIViewController
extension Wrapper where Base: UIViewController {
    /// 快捷设置导航栏标题文字
    public var title: String? {
        get { base.fw_title }
        set { base.fw_title = newValue }
    }
    
    /// 设置导航栏返回按钮，支持UIBarButtonItem|NSString|UIImage等，nil时显示系统箭头
    public var backBarItem: Any? {
        get { base.fw_backBarItem }
        set { base.fw_backBarItem = newValue }
    }
    
    /// 设置导航栏左侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面
    public var leftBarItem: Any? {
        get { base.fw_leftBarItem }
        set { base.fw_leftBarItem = newValue }
    }
    
    /// 设置导航栏右侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面
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

// MARK: - MulticastBlock
/// 多句柄代理，线程安全，可实现重复、单次或延迟调用功能
///
/// 串行安全：读sync，写async
/// 并行安全：读sync，写async， 用flags:.barrier加共享互斥锁
public class MulticastBlock: NSObject {
    
    /// 调用后是否自动移除句柄，默认false可重复执行
    public var autoRemoved = false
    
    /// 是否只能invoke一次，开启时invoke后再append会立即执行而不是添加，默认false
    public var invokeOnce = false
    
    /// 是否在主线程执行，会阻碍UI渲染，默认false
    public var onMainThread = false
    
    private var blocks: [() -> Void] = []
    private var isInvoked = false
    private var queue = DispatchQueue(label: "site.wuyong.queue.block.multicast")
    
    private static var instances: [AnyHashable: MulticastBlock] = [:]
    
    /// 指定Key并返回代理单例
    public static func sharedBlock(_ key: AnyHashable) -> MulticastBlock {
        return fw_synchronized {
            if let instance = instances[key] {
                return instance
            } else {
                let instance = MulticastBlock()
                instances[key] = instance
                return instance
            }
        }
    }
    
    /// 添加句柄，invokeOnce开启且调用了invoke后会立即执行而不是添加
    public func append(_ block: @escaping () -> Void) {
        let targetBlock = !onMainThread ? block : {
            if Thread.isMainThread {
                block()
            } else {
                DispatchQueue.main.async {
                    block()
                }
            }
        }
        
        queue.sync {
            if invokeOnce && isInvoked {
                targetBlock()
                return
            }
            
            blocks.append(targetBlock)
        }
    }
    
    /// 手动清空所有句柄
    public func removeAll() {
        queue.sync {
            blocks.removeAll()
        }
    }
    
    /// 调用句柄，invokeOnce开启时多次调用无效
    public func invoke() {
        queue.sync {
            if invokeOnce && isInvoked { return }
            isInvoked = true
            
            blocks.forEach { block in
                block()
            }
            
            if invokeOnce || autoRemoved {
                blocks.removeAll()
            }
        }
    }
    
}

// MARK: - TapGestureRecognizer
/// 支持高亮状态的点击手势
open class TapGestureRecognizer: UITapGestureRecognizer {
    
    /// 是否是高亮状态，默认NO
    open var isHighlighted: Bool = false {
        didSet {
            if oldValue == isHighlighted { return }
            if isEnabled && highlightedAlpha > 0 {
                view?.alpha = isHighlighted ? highlightedAlpha : 1
            }
            if isEnabled && highlightedChanged != nil {
                highlightedChanged?(self, isHighlighted)
            }
        }
    }

    /// 自定义高亮状态变化时处理句柄
    open var highlightedChanged: ((TapGestureRecognizer, Bool) -> Void)? {
        didSet {
            if isEnabled && highlightedChanged != nil {
                highlightedChanged?(self, isHighlighted)
            }
        }
    }

    /// 高亮状态时view的透明度，默认0不生效
    open var highlightedAlpha: CGFloat = 0 {
        didSet {
            if isEnabled && highlightedAlpha > 0 {
                view?.alpha = isHighlighted ? highlightedAlpha : 1
            }
        }
    }
    
    /// 自定义禁用状态变化时处理句柄
    open var disabledChanged: ((TapGestureRecognizer, Bool) -> Void)? {
        didSet {
            if disabledChanged != nil {
                disabledChanged?(self, isEnabled)
            }
        }
    }

    /// 禁用状态时view的透明度，默认0不生效
    open var disabledAlpha: CGFloat = 0 {
        didSet {
            if disabledAlpha > 0 {
                view?.alpha = isEnabled ? 1 : disabledAlpha
            }
        }
    }
    
    open override var isEnabled: Bool {
        didSet {
            if disabledAlpha > 0 {
                view?.alpha = isEnabled ? 1 : disabledAlpha
            }
            if disabledChanged != nil {
                disabledChanged?(self, isEnabled)
            }
        }
    }
    
    open override var state: UIGestureRecognizer.State {
        didSet {
            if state == .began {
                isHighlighted = true
            } else if state != .changed {
                isHighlighted = false
            }
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        isHighlighted = true
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        isHighlighted = false
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        isHighlighted = false
    }
    
    open override func reset() {
        super.reset()
        isHighlighted = false
    }
    
}

// MARK: - DispatchQueue+Block
@_spi(FW) extension DispatchQueue {
    
    /// 主线程安全异步执行句柄
    public static func fw_mainAsync(execute block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
    
}

// MARK: - Timer+Block
@_spi(FW) extension Timer {
    
    /// 创建Timer，使用target-action，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - target: 目标
    ///   - selector: 方法
    ///   - userInfo: 参数
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func fw_commonTimer(timeInterval: TimeInterval, target: Any, selector: Selector, userInfo: Any?, repeats: Bool) -> Timer {
        let timer = Timer(timeInterval: timeInterval, target: target, selector: selector, userInfo: userInfo, repeats: repeats)
        RunLoop.current.add(timer, forMode: .common)
        return timer
    }

    /// 创建Timer，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - block: 代码块
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func fw_commonTimer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        let timer = fw_timer(timeInterval: timeInterval, block: block, repeats: repeats)
        RunLoop.current.add(timer, forMode: .common)
        return timer
    }

    /// 创建倒计时定时器
    /// - Parameters:
    ///   - countDown: 倒计时时间
    ///   - block: 每秒执行block，为0时自动停止
    /// - Returns: 定时器，可手工停止
    public static func fw_commonTimer(countDown: Int, block: @escaping (Int) -> Void) -> Timer {
        let startTime = Date.fw_currentTime
        let timer = fw_commonTimer(timeInterval: 1, block: { timer in
            DispatchQueue.main.async {
                let remainTime = countDown - Int(round(Date.fw_currentTime - startTime))
                if remainTime <= 0 {
                    block(0)
                    timer.invalidate()
                } else {
                    block(remainTime)
                }
            }
        }, repeats: true)
        
        // 立即触发定时器，默认等待1秒后才执行
        timer.fire()
        return timer
    }

    /// 创建Timer，使用block，需要调用addTimer:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
    ///
    /// 示例：[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes]
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - block: 代码块
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func fw_timer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        return Timer(timeInterval: timeInterval, target: Timer.self, selector: #selector(Timer.fw_timerAction(_:)), userInfo: block, repeats: repeats)
    }

    /// 创建Timer，使用block，默认模式安排到当前的运行循环中
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - block: 代码块
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func fw_scheduledTimer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        return Timer.scheduledTimer(timeInterval: timeInterval, target: Timer.self, selector: #selector(Timer.fw_timerAction(_:)), userInfo: block, repeats: repeats)
    }
    
    /// 暂停NSTimer
    public func fw_pauseTimer() {
        if !self.isValid { return }
        self.fireDate = Date.distantFuture
    }

    /// 开始NSTimer
    public func fw_resumeTimer() {
        if !self.isValid { return }
        self.fireDate = Date()
    }

    /// 延迟delay秒后开始NSTimer
    public func fw_resumeTimer(afterDelay delay: TimeInterval) {
        if !self.isValid { return }
        self.fireDate = Date(timeIntervalSinceNow: delay)
    }
    
    @objc private class func fw_timerAction(_ timer: Timer) {
        let block = timer.userInfo as? (Timer) -> Void
        block?(timer)
    }
    
}

// MARK: - UIGestureRecognizer+Block
@_spi(FW) extension UIGestureRecognizer {
    
    fileprivate class BlockTarget {
        let identifier = UUID().uuidString
        var block: ((Any) -> Void)?
        var events: UIControl.Event = []
        
        @objc func invoke(_ sender: Any) {
            block?(sender)
        }
    }
    
    /// 从事件句柄初始化
    public static func fw_gestureRecognizer(block: @escaping (Any) -> Void) -> Self {
        let gestureRecognizer = Self()
        gestureRecognizer.fw_addBlock(block)
        return gestureRecognizer
    }
    
    /// 添加事件句柄，返回监听唯一标志
    @discardableResult
    public func fw_addBlock(_ block: @escaping (Any) -> Void) -> String {
        let target = BlockTarget()
        target.block = block
        self.addTarget(target, action: #selector(BlockTarget.invoke(_:)))
        fw_blockTargets.append(target)
        return target.identifier
    }

    /// 根据监听唯一标志移除事件句柄，返回是否成功
    @discardableResult
    public func fw_removeBlock(identifier: String) -> Bool {
        var result = false
        fw_blockTargets.forEach { target in
            if identifier == target.identifier {
                self.removeTarget(target, action: #selector(BlockTarget.invoke(_:)))
                result = true
            }
        }
        fw_blockTargets.removeAll { identifier == $0.identifier }
        return result
    }

    /// 移除所有事件句柄
    public func fw_removeAllBlocks() {
        fw_blockTargets.forEach { target in
            self.removeTarget(target, action: #selector(BlockTarget.invoke(_:)))
        }
        fw_blockTargets.removeAll()
    }
    
    private var fw_blockTargets: [BlockTarget] {
        get { return fw_property(forName: "fw_blockTargets") as? [BlockTarget] ?? [] }
        set { fw_setProperty(newValue, forName: "fw_blockTargets") }
    }
    
}

// MARK: UIView+Block
@_spi(FW) extension UIView {
    
    /// 获取当前视图添加的第一个点击手势，默认nil
    public var fw_tapGesture: UITapGestureRecognizer? {
        let tapGesture = self.gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer })
        return tapGesture as? UITapGestureRecognizer
    }
    
    /// 添加点击手势事件，可自定义点击高亮句柄等
    public func fw_addTapGesture(target: Any, action: Selector, customize: ((TapGestureRecognizer) -> Void)? = nil) {
        let gesture: UITapGestureRecognizer = customize != nil ? TapGestureRecognizer(target: target, action: action) : UITapGestureRecognizer(target: target, action: action)
        self.addGestureRecognizer(gesture)
        if customize != nil, let tapGesture = gesture as? TapGestureRecognizer {
            customize?(tapGesture)
        }
    }

    /// 添加点击手势句柄，可自定义点击高亮句柄等
    @discardableResult
    public func fw_addTapGesture(block: @escaping (Any) -> Void, customize: ((TapGestureRecognizer) -> Void)? = nil) -> String {
        let gesture: UITapGestureRecognizer = customize != nil ? TapGestureRecognizer() : UITapGestureRecognizer()
        let identifier = gesture.fw_addBlock(block)
        self.addGestureRecognizer(gesture)
        if customize != nil, let tapGesture = gesture as? TapGestureRecognizer {
            customize?(tapGesture)
        }
        return identifier
    }

    /// 根据监听唯一标志移除点击手势句柄，返回是否成功
    @discardableResult
    public func fw_removeTapGesture(identifier: String) -> Bool {
        var result = false
        self.gestureRecognizers?.forEach({ gesture in
            if gesture is UITapGestureRecognizer,
               gesture.fw_removeBlock(identifier: identifier) {
                self.removeGestureRecognizer(gesture)
                result = true
            }
        })
        return result
    }

    /// 移除所有点击手势
    public func fw_removeAllTapGestures() {
        self.gestureRecognizers?.forEach({ gesture in
            if gesture is UITapGestureRecognizer {
                self.removeGestureRecognizer(gesture)
            }
        })
    }
    
}

// MARK: UIControl+Block
@_spi(FW) extension UIControl {
    
    /// 添加事件句柄，返回监听唯一标志
    @discardableResult
    public func fw_addBlock(_ block: @escaping (Any) -> Void, for controlEvents: UIControl.Event) -> String {
        let target = UIGestureRecognizer.BlockTarget()
        target.block = block
        target.events = controlEvents
        self.addTarget(target, action: #selector(UIGestureRecognizer.BlockTarget.invoke(_:)), for: controlEvents)
        fw_blockTargets.append(target)
        return target.identifier
    }

    /// 根据监听唯一标志移除事件句柄
    @discardableResult
    public func fw_removeBlock(identifier: String, for controlEvents: UIControl.Event) -> Bool {
        return fw_removeAllBlocks(for: controlEvents, identifier: identifier)
    }

    /// 移除所有事件句柄
    @discardableResult
    public func fw_removeAllBlocks(for controlEvents: UIControl.Event) -> Bool {
        return fw_removeAllBlocks(for: controlEvents, identifier: nil)
    }
    
    private func fw_removeAllBlocks(for controlEvents: UIControl.Event, identifier: String?) -> Bool {
        var result = false
        var removeIdentifiers: [String] = []
        for target in fw_blockTargets {
            if !target.events.intersection(controlEvents).isEmpty {
                let shouldRemove = identifier == nil || target.identifier == identifier
                if !shouldRemove { continue }
                
                var newEvent = target.events
                newEvent.remove(controlEvents)
                if !newEvent.isEmpty {
                    self.removeTarget(target, action: #selector(UIGestureRecognizer.BlockTarget.invoke(_:)), for: target.events)
                    target.events = newEvent
                    self.addTarget(target, action: #selector(UIGestureRecognizer.BlockTarget.invoke(_:)), for: target.events)
                } else {
                    self.removeTarget(target, action: #selector(UIGestureRecognizer.BlockTarget.invoke(_:)), for: target.events)
                    removeIdentifiers.append(target.identifier)
                }
                result = true
            }
        }
        fw_blockTargets.removeAll { removeIdentifiers.contains($0.identifier) }
        return result
    }

    /// 添加点击事件
    public func fw_addTouch(target: Any, action: Selector) {
        self.addTarget(target, action: action, for: .touchUpInside)
    }

    /// 添加点击句柄，返回监听唯一标志
    @discardableResult
    public func fw_addTouch(block: @escaping (Any) -> Void) -> String {
        return fw_addBlock(block, for: .touchUpInside)
    }

    /// 监听唯一标志移除点击句柄
    @discardableResult
    public func fw_removeTouchBlock(identifier: String) -> Bool {
        return fw_removeBlock(identifier: identifier, for: .touchUpInside)
    }
    
    /// 移除所有点击句柄
    public func fw_removeAllTouchBlocks() {
        fw_removeAllBlocks(for: .touchUpInside)
    }
    
    private var fw_blockTargets: [UIGestureRecognizer.BlockTarget] {
        get { return fw_property(forName: "fw_blockTargets") as? [UIGestureRecognizer.BlockTarget] ?? [] }
        set { fw_setProperty(newValue, forName: "fw_blockTargets") }
    }
    
}

// MARK: UIBarButtonItem+Block
/// iOS11之后，customView必须具有intrinsicContentSize值才能点击，可使用frame布局或者实现intrinsicContentSize即可
@_spi(FW) extension UIBarButtonItem {
    
    /// 使用指定对象和事件创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func fw_item(object: Any?, target: Any?, action: Selector?) -> Self {
        var barItem: Self
        if let title = object as? String {
            barItem = Self(title: title, style: .plain, target: target, action: action)
        } else if let attributedString = object as? NSAttributedString {
            barItem = Self(title: attributedString.string, style: .plain, target: target, action: action)
            barItem.fw_titleAttributes = attributedString.attributes(at: 0, effectiveRange: nil)
        } else if let image = object as? UIImage {
            barItem = Self(image: image, style: .plain, target: target, action: action)
        } else if let systemItem = object as? UIBarButtonItem.SystemItem {
            barItem = Self(barButtonSystemItem: systemItem, target: target, action: action)
        } else if let value = object as? Int {
            barItem = Self(barButtonSystemItem: .init(rawValue: value) ?? .done, target: target, action: action)
        } else if let number = object as? NSNumber {
            barItem = Self(barButtonSystemItem: .init(rawValue: number.intValue) ?? .done, target: target, action: action)
        } else if let customView = object as? UIView {
            barItem = Self(customView: customView)
            barItem.target = target as? AnyObject
            barItem.action = action
            barItem.fw_addItemEvent(customView)
        } else {
            barItem = Self()
            barItem.target = target as? AnyObject
            barItem.action = action
        }
        return barItem
    }

    /// 使用指定对象和句柄创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func fw_item(object: Any?, block: ((UIBarButtonItem) -> Void)?) -> Self {
        let barItem = fw_item(object: object, target: nil, action: nil)
        barItem.fw_setBlock(block)
        return barItem
    }
    
    /// 自定义标题样式属性，兼容appearance，默认nil同系统
    public var fw_titleAttributes: [NSAttributedString.Key: Any]? {
        get {
            return fw_property(forName: "fw_titleAttributes") as? [NSAttributedString.Key: Any]
        }
        set {
            fw_setProperty(newValue, forName: "fw_titleAttributes")
            guard let titleAttributes = newValue else { return }
            
            let states: [UIControl.State] = [.normal, .highlighted, .disabled, .focused]
            for state in states {
                var attributes = self.titleTextAttributes(for: state) ?? [:]
                attributes.merge(titleAttributes) { _, last in last }
                self.setTitleTextAttributes(attributes, for: state)
            }
        }
    }
    
    /// 设置当前Item触发句柄，nil时清空句柄
    public func fw_setBlock(_ block: ((UIBarButtonItem) -> Void)?) {
        var target: UIGestureRecognizer.BlockTarget?
        var action: Selector?
        if block != nil {
            target = UIGestureRecognizer.BlockTarget()
            target?.block = { sender in
                if let sender = sender as? UIBarButtonItem {
                    block?(sender)
                }
            }
            action = #selector(UIGestureRecognizer.BlockTarget.invoke(_:))
        }
        
        self.target = target
        self.action = action
        // 设置target为强引用，因为self.target为弱引用
        fw_setProperty(target, forName: "fw_setBlock")
    }
    
    private func fw_addItemEvent(_ customView: UIView) {
        // 进行self转发，模拟实际action回调参数
        if let customControl = customView as? UIControl {
            customControl.fw_addTouch(target: self, action: #selector(UIBarButtonItem.fw_invokeTargetAction(_:)))
        } else {
            customView.fw_addTapGesture(target: self, action: #selector(UIBarButtonItem.fw_invokeTargetAction(_:)))
        }
    }
    
    @objc private func fw_invokeTargetAction(_ sender: Any) {
        if let target = target, let action = action,
            target.responds(to: action) {
            // 第一个参数UIBarButtonItem，第二个参数为UIControl或者手势对象
            _ = target.perform(action, with: self, with: sender)
        }
    }
    
}

// MARK: UIViewController+Block
@_spi(FW) extension UIViewController {

    /// 快捷设置导航栏标题文字
    public var fw_title: String? {
        get { self.navigationItem.title }
        set { self.navigationItem.title = newValue }
    }
    
    /// 设置导航栏返回按钮，支持UIBarButtonItem|NSString|UIImage等，nil时显示系统箭头
    public var fw_backBarItem: Any? {
        get {
            return self.navigationItem.backBarButtonItem
        }
        set {
            if let item = newValue as? UIBarButtonItem {
                self.navigationItem.backBarButtonItem = item
                self.navigationController?.navigationBar.fw_backImage = nil
            } else if let image = newValue as? UIImage {
                self.navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: nil, action: nil)
                self.navigationController?.navigationBar.fw_backImage = image
            } else {
                self.navigationItem.backBarButtonItem = UIBarButtonItem.fw_item(object: newValue ?? UIImage(), target: nil, action: nil)
                self.navigationController?.navigationBar.fw_backImage = nil
            }
        }
    }
    
    /// 设置导航栏左侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面
    public var fw_leftBarItem: Any? {
        get {
            return self.navigationItem.leftBarButtonItem
        }
        set {
            if let item = newValue as? UIBarButtonItem {
                self.navigationItem.leftBarButtonItem = item
            } else if let object = newValue {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem.fw_item(object: object, block: { [weak self] _ in
                    guard let this = self else { return }
                    if !this.shouldPopController { return }
                    this.fw.close()
                })
            } else {
                self.navigationItem.leftBarButtonItem = nil
            }
        }
    }
    
    /// 设置导航栏右侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面
    public var fw_rightBarItem: Any? {
        get {
            return self.navigationItem.rightBarButtonItem
        }
        set {
            if let item = newValue as? UIBarButtonItem {
                self.navigationItem.rightBarButtonItem = item
            } else if let object = newValue {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem.fw_item(object: object, block: { [weak self] _ in
                    guard let this = self else { return }
                    if !this.shouldPopController { return }
                    this.fw.close()
                })
            } else {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    /// 快捷设置导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
    public func fw_setLeftBarItem(_ object: Any?, target: Any, action: Selector) {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.fw_item(object: object, target: target, action: action)
    }
    
    /// 快捷设置导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
    public func fw_setLeftBarItem(_ object: Any?, block: @escaping (UIBarButtonItem) -> Void) {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.fw_item(object: object, block: block)
    }
    
    /// 快捷设置导航栏右侧按钮
    public func fw_setRightBarItem(_ object: Any?, target: Any, action: Selector) {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.fw_item(object: object, target: target, action: action)
    }
    
    /// 快捷设置导航栏右侧按钮，block事件
    public func fw_setRightBarItem(_ object: Any?, block: @escaping (UIBarButtonItem) -> Void) {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.fw_item(object: object, block: block)
    }

    /// 快捷添加导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
    public func fw_addLeftBarItem(_ object: Any?, target: Any, action: Selector) {
        let barItem = UIBarButtonItem.fw_item(object: object, target: target, action: action)
        var items = self.navigationItem.leftBarButtonItems ?? []
        items.append(barItem)
        self.navigationItem.leftBarButtonItems = items
    }

    /// 快捷添加导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
    public func fw_addLeftBarItem(_ object: Any?, block: @escaping (UIBarButtonItem) -> Void) {
        let barItem = UIBarButtonItem.fw_item(object: object, block: block)
        var items = self.navigationItem.leftBarButtonItems ?? []
        items.append(barItem)
        self.navigationItem.leftBarButtonItems = items
    }

    /// 快捷添加导航栏右侧按钮
    public func fw_addRightBarItem(_ object: Any?, target: Any, action: Selector) {
        let barItem = UIBarButtonItem.fw_item(object: object, target: target, action: action)
        var items = self.navigationItem.rightBarButtonItems ?? []
        items.append(barItem)
        self.navigationItem.rightBarButtonItems = items
    }

    /// 快捷添加导航栏右侧按钮，block事件
    public func fw_addRightBarItem(_ object: Any?, block: @escaping (UIBarButtonItem) -> Void) {
        let barItem = UIBarButtonItem.fw_item(object: object, block: block)
        var items = self.navigationItem.rightBarButtonItems ?? []
        items.append(barItem)
        self.navigationItem.rightBarButtonItems = items
    }
    
}

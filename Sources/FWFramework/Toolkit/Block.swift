//
//  Block.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

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
    public static func commonTimer(timeInterval: TimeInterval, block: @escaping @Sendable (Timer) -> Void, repeats: Bool) -> Timer {
        let timer = timer(timeInterval: timeInterval, block: block, repeats: repeats)
        RunLoop.current.add(timer, forMode: .common)
        return timer
    }

    /// 创建倒计时定时器
    /// - Parameters:
    ///   - countDown: 倒计时时间
    ///   - block: 每秒执行block，为0时自动停止
    /// - Returns: 定时器，可手工停止
    public static func commonTimer(countDown: Int, block: @escaping @MainActor @Sendable (Int) -> Void) -> Timer {
        let startTime = Date.fw.currentTime
        let timer = commonTimer(timeInterval: 1, block: { timer in
            let sendableTimer = SendableObject(timer)
            DispatchQueue.main.async {
                let remainTime = countDown - Int(round(Date.fw.currentTime - startTime))
                if remainTime <= 0 {
                    block(0)
                    if let timer = sendableTimer.object as? Timer {
                        timer.invalidate()
                    }
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
    public static func timer(timeInterval: TimeInterval, block: @escaping @Sendable (Timer) -> Void, repeats: Bool) -> Timer {
        return Timer(timeInterval: timeInterval, target: Timer.self, selector: #selector(Timer.innerTimerAction(_:)), userInfo: block, repeats: repeats)
    }

    /// 创建Timer，使用block，默认模式安排到当前的运行循环中
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - block: 代码块
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func scheduledTimer(timeInterval: TimeInterval, block: @escaping @Sendable (Timer) -> Void, repeats: Bool) -> Timer {
        return Timer.scheduledTimer(timeInterval: timeInterval, target: Timer.self, selector: #selector(Timer.innerTimerAction(_:)), userInfo: block, repeats: repeats)
    }
    
    /// 暂停NSTimer
    public func pauseTimer() {
        if !base.isValid { return }
        base.fireDate = Date.distantFuture
    }

    /// 开始NSTimer
    public func resumeTimer() {
        if !base.isValid { return }
        base.fireDate = Date()
    }

    /// 延迟delay秒后开始NSTimer
    public func resumeTimer(afterDelay delay: TimeInterval) {
        if !base.isValid { return }
        base.fireDate = Date(timeIntervalSinceNow: delay)
    }
}

// MARK: - Wrapper+UIGestureRecognizer
@MainActor extension Wrapper where Base: UIGestureRecognizer {
    /// 从事件句柄初始化
    public static func gestureRecognizer(block: @escaping @MainActor @Sendable (Base) -> Void) -> Base {
        let gestureRecognizer = Base.init()
        gestureRecognizer.fw.addBlock(block)
        return gestureRecognizer
    }
    
    /// 添加事件句柄，返回监听唯一标志
    @discardableResult
    public func addBlock(_ block: @escaping @MainActor @Sendable (Base) -> Void) -> String {
        let target = BlockTarget()
        target.block = { sender in
            block(sender as! Base)
        }
        base.addTarget(target, action: #selector(BlockTarget.invoke(_:)))
        blockTargets.append(target)
        return target.identifier
    }

    /// 根据监听唯一标志移除事件句柄，返回是否成功
    @discardableResult
    public func removeBlock(identifier: String) -> Bool {
        var result = false
        blockTargets.forEach { target in
            if identifier == target.identifier {
                base.removeTarget(target, action: #selector(BlockTarget.invoke(_:)))
                result = true
            }
        }
        blockTargets.removeAll { identifier == $0.identifier }
        return result
    }

    /// 移除所有事件句柄
    public func removeAllBlocks() {
        blockTargets.forEach { target in
            base.removeTarget(target, action: #selector(BlockTarget.invoke(_:)))
        }
        blockTargets.removeAll()
    }
    
    private var blockTargets: [BlockTarget] {
        get { return property(forName: "blockTargets") as? [BlockTarget] ?? [] }
        set { setProperty(newValue, forName: "blockTargets") }
    }
}

// MARK: - Wrapper+UIView
@MainActor extension Wrapper where Base: UIView {
    /// 获取当前视图添加的第一个点击手势，默认nil
    public var tapGesture: UITapGestureRecognizer? {
        let tapGesture = base.gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer })
        return tapGesture as? UITapGestureRecognizer
    }
    
    /// 添加点击手势事件，可自定义点击高亮句柄等
    public func addTapGesture(target: Any, action: Selector, customize: (@MainActor (TapGestureRecognizer) -> Void)? = nil) {
        let gesture: UITapGestureRecognizer = customize != nil ? TapGestureRecognizer(target: target, action: action) : UITapGestureRecognizer(target: target, action: action)
        base.addGestureRecognizer(gesture)
        if customize != nil, let tapGesture = gesture as? TapGestureRecognizer {
            customize?(tapGesture)
        }
    }

    /// 添加点击手势句柄，可自定义点击高亮句柄等
    @discardableResult
    public func addTapGesture(block: @escaping @MainActor @Sendable (UITapGestureRecognizer) -> Void, customize: (@MainActor (TapGestureRecognizer) -> Void)? = nil) -> String {
        let gesture: UITapGestureRecognizer = customize != nil ? TapGestureRecognizer() : UITapGestureRecognizer()
        let identifier = gesture.fw.addBlock(block)
        base.addGestureRecognizer(gesture)
        if customize != nil, let tapGesture = gesture as? TapGestureRecognizer {
            customize?(tapGesture)
        }
        return identifier
    }

    /// 根据监听唯一标志移除点击手势句柄，返回是否成功
    @discardableResult
    public func removeTapGesture(identifier: String) -> Bool {
        var result = false
        base.gestureRecognizers?.forEach({ gesture in
            if gesture is UITapGestureRecognizer,
               gesture.fw.removeBlock(identifier: identifier) {
                base.removeGestureRecognizer(gesture)
                result = true
            }
        })
        return result
    }

    /// 移除所有点击手势
    public func removeAllTapGestures() {
        base.gestureRecognizers?.forEach({ gesture in
            if gesture is UITapGestureRecognizer {
                base.removeGestureRecognizer(gesture)
            }
        })
    }
}

// MARK: - Wrapper+UIControl
@MainActor extension Wrapper where Base: UIControl {
    /// 添加事件句柄，返回监听唯一标志
    @discardableResult
    public func addBlock(_ block: @escaping @MainActor @Sendable (Base) -> Void, for controlEvents: UIControl.Event) -> String {
        let target = BlockTarget()
        target.block = { sender in
            block(sender as! Base)
        }
        target.events = controlEvents
        base.addTarget(target, action: #selector(BlockTarget.invoke(_:)), for: controlEvents)
        blockTargets.append(target)
        return target.identifier
    }

    /// 根据监听唯一标志移除事件句柄
    @discardableResult
    public func removeBlock(identifier: String, for controlEvents: UIControl.Event) -> Bool {
        return removeAllBlocks(for: controlEvents, identifier: identifier)
    }

    /// 移除所有事件句柄
    @discardableResult
    public func removeAllBlocks(for controlEvents: UIControl.Event) -> Bool {
        return removeAllBlocks(for: controlEvents, identifier: nil)
    }
    
    private func removeAllBlocks(for controlEvents: UIControl.Event, identifier: String?) -> Bool {
        var result = false
        var removeIdentifiers: [String] = []
        for target in blockTargets {
            if !target.events.intersection(controlEvents).isEmpty {
                let shouldRemove = identifier == nil || target.identifier == identifier
                if !shouldRemove { continue }
                
                var newEvent = target.events
                newEvent.remove(controlEvents)
                if !newEvent.isEmpty {
                    base.removeTarget(target, action: #selector(BlockTarget.invoke(_:)), for: target.events)
                    target.events = newEvent
                    base.addTarget(target, action: #selector(BlockTarget.invoke(_:)), for: target.events)
                } else {
                    base.removeTarget(target, action: #selector(BlockTarget.invoke(_:)), for: target.events)
                    removeIdentifiers.append(target.identifier)
                }
                result = true
            }
        }
        blockTargets.removeAll { removeIdentifiers.contains($0.identifier) }
        return result
    }

    /// 添加点击事件
    public func addTouch(target: Any, action: Selector) {
        base.addTarget(target, action: action, for: .touchUpInside)
    }

    /// 添加点击句柄，返回监听唯一标志
    @discardableResult
    public func addTouch(block: @escaping @MainActor @Sendable (Base) -> Void) -> String {
        return addBlock(block, for: .touchUpInside)
    }

    /// 根据监听唯一标志移除点击句柄
    @discardableResult
    public func removeTouchBlock(identifier: String) -> Bool {
        return removeBlock(identifier: identifier, for: .touchUpInside)
    }
    
    /// 移除所有点击句柄
    public func removeAllTouchBlocks() {
        removeAllBlocks(for: .touchUpInside)
    }
    
    private var blockTargets: [BlockTarget] {
        get { return property(forName: "blockTargets") as? [BlockTarget] ?? [] }
        set { setProperty(newValue, forName: "blockTargets") }
    }
}

// MARK: - Wrapper+UIBarButtonItem
/// iOS11之后，customView必须具有intrinsicContentSize值才能点击，可使用frame布局或者实现intrinsicContentSize即可
@MainActor extension Wrapper where Base: UIBarButtonItem {
    /// 使用指定对象和事件创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func item(object: Any?, target: Any?, action: Selector?) -> Base {
        var barItem: Base
        if let title = object as? String {
            barItem = Base.init(title: title, style: .plain, target: target, action: action)
        } else if let attributedString = object as? NSAttributedString {
            barItem = Base.init(title: attributedString.string, style: .plain, target: target, action: action)
            barItem.fw.titleAttributes = attributedString.attributes(at: 0, effectiveRange: nil)
        } else if let image = object as? UIImage {
            barItem = Base.init(image: image, style: .plain, target: target, action: action)
        } else if let systemItem = object as? UIBarButtonItem.SystemItem {
            barItem = Base.init(barButtonSystemItem: systemItem, target: target, action: action)
        } else if let value = object as? Int {
            barItem = Base.init(barButtonSystemItem: .init(rawValue: value) ?? .done, target: target, action: action)
        } else if let number = object as? NSNumber {
            barItem = Base.init(barButtonSystemItem: .init(rawValue: number.intValue) ?? .done, target: target, action: action)
        } else if let customView = object as? UIView {
            barItem = Base.init(customView: customView)
            barItem.target = target as? AnyObject
            barItem.action = action
            barItem.fw.addItemEvent(customView)
        } else {
            barItem = Base.init()
            barItem.target = target as? AnyObject
            barItem.action = action
        }
        return barItem
    }

    /// 使用指定对象和句柄创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func item(object: Any?, block: (@MainActor @Sendable (UIBarButtonItem) -> Void)?) -> Base {
        let barItem = item(object: object, target: nil, action: nil)
        barItem.fw.setBlock(block)
        return barItem
    }
    
    /// 自定义标题样式属性，兼容appearance，默认nil同系统
    public var titleAttributes: [NSAttributedString.Key: Any]? {
        get {
            return property(forName: "titleAttributes") as? [NSAttributedString.Key: Any]
        }
        set {
            setProperty(newValue, forName: "titleAttributes")
            guard let titleAttributes = newValue else { return }
            
            let states: [UIControl.State] = [.normal, .highlighted, .disabled, .focused]
            for state in states {
                var attributes = base.titleTextAttributes(for: state) ?? [:]
                attributes.merge(titleAttributes) { _, last in last }
                base.setTitleTextAttributes(attributes, for: state)
            }
        }
    }
    
    /// 设置当前Item触发句柄，nil时清空句柄
    public func setBlock(_ block: (@MainActor @Sendable (UIBarButtonItem) -> Void)?) {
        var target: BlockTarget?
        var action: Selector?
        if block != nil {
            target = BlockTarget()
            target?.block = { sender in
                if let sender = sender as? UIBarButtonItem {
                    block?(sender)
                }
            }
            action = #selector(BlockTarget.invoke(_:))
        }
        
        base.target = target
        base.action = action
        // 设置target为强引用，因为base.target为弱引用
        setProperty(target, forName: #function)
    }
    
    private func addItemEvent(_ customView: UIView) {
        // 进行base转发，模拟实际action回调参数
        if let customControl = customView as? UIControl {
            customControl.fw.addTouch(target: base, action: #selector(UIBarButtonItem.innerInvokeTargetAction(_:)))
        } else {
            customView.fw.addTapGesture(target: base, action: #selector(UIBarButtonItem.innerInvokeTargetAction(_:)))
        }
    }
}

// MARK: - Wrapper+UIViewController
@MainActor extension Wrapper where Base: UIViewController {
    /// 快捷设置导航栏标题文字
    public var title: String? {
        get { base.navigationItem.title }
        set { base.navigationItem.title = newValue }
    }
    
    /// 设置导航栏返回按钮，支持UIBarButtonItem|NSString|UIImage等，nil时显示系统箭头
    public var backBarItem: Any? {
        get {
            return base.navigationItem.backBarButtonItem
        }
        set {
            if let item = newValue as? UIBarButtonItem {
                base.navigationItem.backBarButtonItem = item
                base.navigationController?.navigationBar.fw.backImage = nil
            } else if let image = newValue as? UIImage {
                base.navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: nil, action: nil)
                base.navigationController?.navigationBar.fw.backImage = image
            } else {
                base.navigationItem.backBarButtonItem = UIBarButtonItem.fw.item(object: newValue ?? UIImage(), target: nil, action: nil)
                base.navigationController?.navigationBar.fw.backImage = nil
            }
        }
    }
    
    /// 设置导航栏左侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面
    public var leftBarItem: Any? {
        get {
            return base.navigationItem.leftBarButtonItem
        }
        set {
            if let item = newValue as? UIBarButtonItem {
                base.navigationItem.leftBarButtonItem = item
            } else if let object = newValue {
                base.navigationItem.leftBarButtonItem = UIBarButtonItem.fw.item(object: object, block: { [weak base] _ in
                    guard let viewController = base else { return }
                    if !viewController.shouldPopController { return }
                    viewController.fw.close()
                })
            } else {
                base.navigationItem.leftBarButtonItem = nil
            }
        }
    }
    
    /// 设置导航栏右侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面
    public var rightBarItem: Any? {
        get {
            return base.navigationItem.rightBarButtonItem
        }
        set {
            if let item = newValue as? UIBarButtonItem {
                base.navigationItem.rightBarButtonItem = item
            } else if let object = newValue {
                base.navigationItem.rightBarButtonItem = UIBarButtonItem.fw.item(object: object, block: { [weak base] _ in
                    guard let viewController = base else { return }
                    if !viewController.shouldPopController { return }
                    viewController.fw.close()
                })
            } else {
                base.navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    /// 快捷设置导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
    @discardableResult
    public func setLeftBarItem(_ object: Any?, target: Any, action: Selector) -> UIBarButtonItem {
        let barItem = UIBarButtonItem.fw.item(object: object, target: target, action: action)
        base.navigationItem.leftBarButtonItem = barItem
        return barItem
    }
    
    /// 快捷设置导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
    @discardableResult
    public func setLeftBarItem(_ object: Any?, block: @escaping @MainActor @Sendable (UIBarButtonItem) -> Void) -> UIBarButtonItem {
        let barItem = UIBarButtonItem.fw.item(object: object, block: block)
        base.navigationItem.leftBarButtonItem = barItem
        return barItem
    }
    
    /// 快捷设置导航栏右侧按钮
    @discardableResult
    public func setRightBarItem(_ object: Any?, target: Any, action: Selector) -> UIBarButtonItem {
        let barItem = UIBarButtonItem.fw.item(object: object, target: target, action: action)
        base.navigationItem.rightBarButtonItem = barItem
        return barItem
    }
    
    /// 快捷设置导航栏右侧按钮，block事件
    @discardableResult
    public func setRightBarItem(_ object: Any?, block: @escaping @MainActor @Sendable (UIBarButtonItem) -> Void) -> UIBarButtonItem {
        let barItem = UIBarButtonItem.fw.item(object: object, block: block)
        base.navigationItem.rightBarButtonItem = barItem
        return barItem
    }

    /// 快捷添加导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
    @discardableResult
    public func addLeftBarItem(_ object: Any?, target: Any, action: Selector) -> UIBarButtonItem {
        let barItem = UIBarButtonItem.fw.item(object: object, target: target, action: action)
        var items = base.navigationItem.leftBarButtonItems ?? []
        items.append(barItem)
        base.navigationItem.leftBarButtonItems = items
        return barItem
    }

    /// 快捷添加导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
    @discardableResult
    public func addLeftBarItem(_ object: Any?, block: @escaping @MainActor @Sendable (UIBarButtonItem) -> Void) -> UIBarButtonItem {
        let barItem = UIBarButtonItem.fw.item(object: object, block: block)
        var items = base.navigationItem.leftBarButtonItems ?? []
        items.append(barItem)
        base.navigationItem.leftBarButtonItems = items
        return barItem
    }

    /// 快捷添加导航栏右侧按钮
    @discardableResult
    public func addRightBarItem(_ object: Any?, target: Any, action: Selector) -> UIBarButtonItem {
        let barItem = UIBarButtonItem.fw.item(object: object, target: target, action: action)
        var items = base.navigationItem.rightBarButtonItems ?? []
        items.append(barItem)
        base.navigationItem.rightBarButtonItems = items
        return barItem
    }

    /// 快捷添加导航栏右侧按钮，block事件
    @discardableResult
    public func addRightBarItem(_ object: Any?, block: @escaping @MainActor @Sendable (UIBarButtonItem) -> Void) -> UIBarButtonItem {
        let barItem = UIBarButtonItem.fw.item(object: object, block: block)
        var items = base.navigationItem.rightBarButtonItems ?? []
        items.append(barItem)
        base.navigationItem.rightBarButtonItems = items
        return barItem
    }
}

// MARK: - BlockTarget
fileprivate class BlockTarget {
    let identifier = UUID().uuidString
    var block: ((Any) -> Void)?
    var events: UIControl.Event = []
    
    @objc func invoke(_ sender: Any) {
        block?(sender)
    }
}

// MARK: - Timer+Block
extension Timer {
    
    @objc fileprivate class func innerTimerAction(_ timer: Timer) {
        let block = timer.userInfo as? (Timer) -> Void
        block?(timer)
    }
    
}

// MARK: UIBarButtonItem+Block
extension UIBarButtonItem {
    
    @objc fileprivate func innerInvokeTargetAction(_ sender: Any) {
        if let target = target, let action = action,
            target.responds(to: action) {
            // 第一个参数UIBarButtonItem，第二个参数为UIControl或者手势对象
            _ = target.perform(action, with: self, with: sender)
        }
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
public class MulticastBlock {
    
    /// 句柄可扩展优先级
    public struct Priority: RawRepresentable, Equatable, Hashable, Sendable {
        
        public typealias RawValue = Int
        
        public static let veryLow: Priority = .init(-8)
        public static let low: Priority = .init(-4)
        public static let normal: Priority = .init(0)
        public static let high: Priority = .init(4)
        public static let veryHigh: Priority = .init(8)
        
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
        
    }
    
    private class Target {
        let block: (@Sendable () -> Void)?
        let asyncBlock: (@Sendable (@escaping @Sendable () -> Void) -> Void)?
        let priority: Priority
        
        init(block: (@Sendable () -> Void)? = nil, asyncBlock: (@Sendable (@escaping @Sendable () -> Void) -> Void)? = nil, priority: Priority) {
            self.block = block
            self.asyncBlock = asyncBlock
            self.priority = priority
        }
    }
    
    /// 是否只能invoke一次，开启时invoke后再append会立即执行而不是添加，默认false
    public var invokeOnce = false
    
    /// 调用后是否自动移除句柄，默认false可重复执行
    public var autoRemoved = false
    
    /// 是否在主线程执行，会阻碍UI渲染，默认false
    public var onMainThread = false
    
    private var targets: [Target] = []
    private var isInvoked = false
    private var queue = DispatchQueue(label: "site.wuyong.queue.block.multicast")
    
    /// 初始化方法
    public init(invokeOnce: Bool = false, autoRemoved: Bool = false, onMainThread: Bool = false) {
        self.invokeOnce = invokeOnce
        self.autoRemoved = autoRemoved
        self.onMainThread = onMainThread
    }
    
    /// 添加同步句柄，优先级默认normal，注意invokeOnce开启且调用了invoke后会立即执行而不是添加
    public func append(_ block: @escaping @Sendable () -> Void, priority: Priority = .normal) {
        let targetBlock = !onMainThread ? block : { @Sendable in
            DispatchQueue.fw.mainAsync {
                block()
            }
        }
        
        queue.sync {
            if invokeOnce && isInvoked {
                targetBlock()
                return
            }
            
            targets.append(Target(block: targetBlock, priority: priority))
        }
    }
    
    /// 添加异步句柄，block必须调用completionHandler，优先级默认normal，注意invokeOnce开启且调用了invoke后会立即执行而不是添加
    public func append(_ block: @escaping @Sendable (_ completionHandler: @escaping @Sendable () -> Void) -> Void, priority: Priority = .normal) {
        let targetBlock = !onMainThread ? block : { @Sendable completionHandler in
            DispatchQueue.fw.mainAsync {
                block(completionHandler)
            }
        }
        
        queue.sync {
            if invokeOnce && isInvoked {
                targetBlock({})
                return
            }
            
            targets.append(Target(asyncBlock: targetBlock, priority: priority))
        }
    }
    
    /// 手动清空所有句柄
    public func removeAll() {
        queue.sync {
            targets.removeAll()
        }
    }
    
    /// 调用句柄，invokeOnce开启时多次调用无效
    public func invoke() {
        queue.sync {
            if invokeOnce && isInvoked { return }
            isInvoked = true
            
            let semaphore = DispatchSemaphore(value: 1)
            let blocks = targets.sorted { $0.priority.rawValue > $1.priority.rawValue }
            for target in blocks {
                if let asyncBlock = target.asyncBlock {
                    queue.async {
                        semaphore.wait()
                        asyncBlock({ semaphore.signal() })
                    }
                } else {
                    target.block?()
                }
            }
            
            if invokeOnce || autoRemoved {
                targets.removeAll()
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
    open var highlightedChanged: (@MainActor @Sendable (TapGestureRecognizer, Bool) -> Void)? {
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
    open var disabledChanged: (@MainActor @Sendable (TapGestureRecognizer, Bool) -> Void)? {
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

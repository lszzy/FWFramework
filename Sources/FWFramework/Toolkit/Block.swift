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
        __Runtime.synchronized(object, closure: closure)
    }
    
    /// 通用互斥锁泛型方法
    public static func synchronized<T>(_ object: AnyObject, closure: () -> T) -> T {
        var result: T? = nil
        __Runtime.synchronized(object) {
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
                highlightedChanged?(self)
            }
        }
    }

    /// 自定义高亮状态变化时处理句柄
    open var highlightedChanged: ((TapGestureRecognizer) -> Void)? {
        didSet {
            if isEnabled && highlightedChanged != nil {
                highlightedChanged?(self)
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
    public static func commonTimer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        let timer = timer(timeInterval: timeInterval, block: block, repeats: repeats)
        RunLoop.current.add(timer, forMode: .common)
        return timer
    }

    /// 创建倒计时定时器
    /// - Parameters:
    ///   - countDown: 倒计时时间
    ///   - block: 每秒执行block，为0时自动停止
    /// - Returns: 定时器，可手工停止
    public static func commonTimer(countDown: Int, block: @escaping (Int) -> Void) -> Timer {
        let startTime = Date.fw.currentTime
        let timer = commonTimer(timeInterval: 1, block: { timer in
            DispatchQueue.main.async {
                let remainTime = countDown - Int(round(Date.fw.currentTime - startTime))
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
    public static func timer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        return Timer(timeInterval: timeInterval, target: Timer.self, selector: #selector(Timer.__timerAction(_:)), userInfo: block, repeats: repeats)
    }

    /// 创建Timer，使用block，默认模式安排到当前的运行循环中
    /// - Parameters:
    ///   - timeInterval: 时间
    ///   - block: 代码块
    ///   - repeats: 是否重复
    /// - Returns: 定时器
    public static func scheduledTimer(timeInterval: TimeInterval, block: @escaping (Timer) -> Void, repeats: Bool) -> Timer {
        return Timer.scheduledTimer(timeInterval: timeInterval, target: Timer.self, selector: #selector(Timer.__timerAction(_:)), userInfo: block, repeats: repeats)
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

extension Timer {
    
    fileprivate static var __timerActionKey = "timerAction"
    
    @objc fileprivate class func __timerAction(_ timer: Timer) {
        let block = timer.userInfo as? (Timer) -> Void
        block?(timer)
    }
    
}

// MARK: - UIGestureRecognizer+Block
extension Wrapper where Base: UIGestureRecognizer {
    
    /// 从事件句柄初始化
    public static func gestureRecognizer(block: @escaping (Any) -> Void) -> Base {
        let gestureRecognizer = Base()
        gestureRecognizer.fw.addBlock(block)
        return gestureRecognizer
    }
    
    /// 添加事件句柄，返回唯一标志
    @discardableResult
    public func addBlock(_ block: @escaping (Any) -> Void) -> String {
        let target = __BlockTarget()
        target.block = block
        base.addTarget(target, action: #selector(__BlockTarget.invoke(_:)))
        innerBlockTargets.add(target)
        return target.identifier
    }

    /// 根据唯一标志移除事件句柄
    public func removeBlock(_ identifier: String?) {
        guard let identifier = identifier else { return }
        let targets = innerBlockTargets
        targets.enumerateObjects { target, _, _ in
            guard let target = target as? __BlockTarget else { return }
            if identifier == target.identifier {
                base.removeTarget(target, action: #selector(__BlockTarget.invoke(_:)))
                targets.remove(target)
            }
        }
    }

    /// 移除所有事件句柄
    public func removeAllBlocks() {
        let targets = innerBlockTargets
        targets.enumerateObjects { target, _, _ in
            guard let target = target as? __BlockTarget else { return }
            base.removeTarget(target, action: #selector(__BlockTarget.invoke(_:)))
        }
        targets.removeAllObjects()
    }
    
    private var innerBlockTargets: NSMutableArray {
        if let targets = property(forName: "innerBlockTargets") as? NSMutableArray {
            return targets
        } else {
            let targets = NSMutableArray()
            setProperty(targets, forName: "innerBlockTargets")
            return targets
        }
    }
    
}

// MARK: UIView+Block
extension Wrapper where Base: UIView {
    
    /// 获取当前视图添加的第一个点击手势，默认nil
    public var tapGesture: UITapGestureRecognizer? {
        let tapGesture = base.gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer })
        return tapGesture as? UITapGestureRecognizer
    }
    
    /// 添加点击手势事件，可自定义点击高亮句柄等
    public func addTapGesture(target: Any, action: Selector, customize: ((TapGestureRecognizer) -> Void)? = nil) {
        let gesture: UITapGestureRecognizer = customize != nil ? TapGestureRecognizer(target: target, action: action) : UITapGestureRecognizer(target: target, action: action)
        base.addGestureRecognizer(gesture)
        if customize != nil, let tapGesture = gesture as? TapGestureRecognizer {
            customize?(tapGesture)
        }
    }

    /// 添加点击手势句柄，可自定义点击高亮句柄等
    @discardableResult
    public func addTapGesture(block: @escaping (Any) -> Void, customize: ((TapGestureRecognizer) -> Void)? = nil) -> String {
        let gesture: UITapGestureRecognizer = customize != nil ? TapGestureRecognizer() : UITapGestureRecognizer()
        let identifier = gesture.fw.addBlock(block)
        gesture.fw.setPropertyCopy(identifier, forName: "tapGesture")
        base.addGestureRecognizer(gesture)
        if customize != nil, let tapGesture = gesture as? TapGestureRecognizer {
            customize?(tapGesture)
        }
        return identifier
    }

    /// 根据唯一标志移除点击手势句柄
    public func removeTapGesture(_ identifier: String?) {
        guard let identifier = identifier else { return }
        base.gestureRecognizers?.forEach({ gesture in
            if gesture is UITapGestureRecognizer {
                if let gestureIdentifier = gesture.fw.property(forName: "tapGesture") as? String,
                   gestureIdentifier == identifier {
                    base.removeGestureRecognizer(gesture)
                }
            }
        })
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

// MARK: UIControl+Block
extension Wrapper where Base: UIControl {
    
    /// 添加事件句柄
    @discardableResult
    public func addBlock(_ block: @escaping (Any) -> Void, for controlEvents: UIControl.Event) -> String {
        let target = __BlockTarget()
        target.block = block
        target.events = controlEvents
        base.addTarget(target, action: #selector(__BlockTarget.invoke(_:)), for: controlEvents)
        innerBlockTargets.add(target)
        return target.identifier
    }

    /// 根据唯一标志移除事件句柄
    public func removeBlock(_ identifier: String?, for controlEvents: UIControl.Event) {
        guard let identifier = identifier else { return }
        removeAllBlocks(for: controlEvents, identifier: identifier)
    }

    /// 移除所有事件句柄
    public func removeAllBlocks(for controlEvents: UIControl.Event) {
        removeAllBlocks(for: controlEvents, identifier: nil)
    }
    
    private func removeAllBlocks(for controlEvents: UIControl.Event, identifier: String?) {
        let targets = innerBlockTargets
        var removes: [__BlockTarget] = []
        for target in targets {
            if let target = target as? __BlockTarget,
               !target.events.intersection(controlEvents).isEmpty {
                let shouldRemove = identifier == nil || target.identifier == identifier
                if !shouldRemove { continue }
                
                var newEvent = target.events
                newEvent.remove(controlEvents)
                if !newEvent.isEmpty {
                    base.removeTarget(target, action: #selector(__BlockTarget.invoke(_:)), for: target.events)
                    target.events = newEvent
                    base.addTarget(target, action: #selector(__BlockTarget.invoke(_:)), for: target.events)
                } else {
                    base.removeTarget(target, action: #selector(__BlockTarget.invoke(_:)), for: target.events)
                    removes.append(target)
                }
            }
        }
        targets.removeObjects(in: removes)
    }

    /// 添加点击事件
    public func addTouch(target: Any, action: Selector) {
        base.addTarget(target, action: action, for: .touchUpInside)
    }

    /// 添加点击句柄
    @discardableResult
    public func addTouch(block: @escaping (Any) -> Void) -> String {
        return addBlock(block, for: .touchUpInside)
    }

    /// 根据唯一标志移除点击句柄
    public func removeTouchBlock(_ identifier: String?) {
        removeBlock(identifier, for: .touchUpInside)
    }
    
    /// 移除所有点击句柄
    public func removeAllTouchBlocks() {
        removeAllBlocks(for: .touchUpInside)
    }
    
    private var innerBlockTargets: NSMutableArray {
        if let targets = property(forName: "innerBlockTargets") as? NSMutableArray {
            return targets
        } else {
            let targets = NSMutableArray()
            setProperty(targets, forName: "innerBlockTargets")
            return targets
        }
    }
    
}

// MARK: UIBarButtonItem+Block
/// iOS11之后，customView必须具有intrinsicContentSize值才能点击，可使用frame布局或者实现intrinsicContentSize即可
extension Wrapper where Base: UIBarButtonItem {
    
    /// 使用指定对象和事件创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func item(object: Any?, target: Any?, action: Selector?) -> Base {
        var barItem: Base
        if let title = object as? String {
            barItem = Base(title: title, style: .plain, target: target, action: action)
        } else if let attributedString = object as? NSAttributedString {
            barItem = Base(title: attributedString.string, style: .plain, target: target, action: action)
            barItem.fw.titleAttributes = attributedString.attributes(at: 0, effectiveRange: nil)
        } else if let image = object as? UIImage {
            barItem = Base(image: image, style: .plain, target: target, action: action)
        } else if let systemItem = object as? UIBarButtonItem.SystemItem {
            barItem = Base(barButtonSystemItem: systemItem, target: target, action: action)
        } else if let value = object as? Int {
            barItem = Base(barButtonSystemItem: .init(rawValue: value) ?? .done, target: target, action: action)
        } else if let number = object as? NSNumber {
            barItem = Base(barButtonSystemItem: .init(rawValue: number.intValue) ?? .done, target: target, action: action)
        } else if let customView = object as? UIView {
            barItem = Base(customView: customView)
            barItem.target = target as? AnyObject
            barItem.action = action
            barItem.fw.addItemEvent(customView)
        } else {
            barItem = Base()
            barItem.target = target as? AnyObject
            barItem.action = action
        }
        return barItem
    }

    /// 使用指定对象和句柄创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func item(object: Any?, block: ((Any) -> Void)?) -> Base {
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
    public func setBlock(_ block: ((Any) -> Void)?) {
        var target: __BlockTarget?
        var action: Selector?
        if block != nil {
            target = __BlockTarget()
            target?.block = block
            action = #selector(__BlockTarget.invoke(_:))
        }
        
        base.target = target
        base.action = action
        // 设置target为强引用，因为base.target为弱引用
        setProperty(target, forName: "setBlock")
    }
    
    fileprivate func addItemEvent(_ customView: UIView) {
        // 进行self转发，模拟实际action回调参数
        if let customControl = customView as? UIControl {
            customControl.fw.addTouch(target: base, action: #selector(UIBarButtonItem.__invokeTargetAction(_:)))
        } else {
            customView.fw.addTapGesture(target: base, action: #selector(UIBarButtonItem.__invokeTargetAction(_:)))
        }
    }
    
}

extension UIBarButtonItem {
    
    @objc fileprivate func __invokeTargetAction(_ sender: Any) {
        if let target = target, let action = action,
            target.responds(to: action) {
            // 第一个参数UIBarButtonItem，第二个参数为UIControl或者手势对象
            _ = target.perform(action, with: self, with: sender)
        }
    }
    
}

// MARK: UIViewController+Block
extension Wrapper where Base: UIViewController {

    /// 快捷设置导航栏标题文字
    public var title: String? {
        get { base.navigationItem.title }
        set { base.navigationItem.title = newValue }
    }
    
    /// 设置导航栏返回按钮，支持UIBarButtonItem|NSString|UIImage等，nil时显示系统箭头，下个页面生效
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
    
    /// 设置导航栏左侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面，下个页面生效
    public var leftBarItem: Any? {
        get {
            return base.navigationItem.leftBarButtonItem
        }
        set {
            if let item = newValue as? UIBarButtonItem {
                base.navigationItem.leftBarButtonItem = item
            } else if let object = newValue {
                let weakBase = base
                base.navigationItem.leftBarButtonItem = UIBarButtonItem.fw.item(object: object, block: { [weak weakBase] _ in
                    guard let weakBase = weakBase else { return }
                    if !weakBase.shouldPopController { return }
                    weakBase.fw.close()
                })
            } else {
                base.navigationItem.leftBarButtonItem = nil
            }
        }
    }
    
    /// 设置导航栏右侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面，下个页面生效
    public var rightBarItem: Any? {
        get {
            return base.navigationItem.rightBarButtonItem
        }
        set {
            if let item = newValue as? UIBarButtonItem {
                base.navigationItem.rightBarButtonItem = item
            } else if let object = newValue {
                let weakBase = base
                base.navigationItem.rightBarButtonItem = UIBarButtonItem.fw.item(object: object, block: { [weak weakBase] _ in
                    guard let weakBase = weakBase else { return }
                    if !weakBase.shouldPopController { return }
                    weakBase.fw.close()
                })
            } else {
                base.navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    /// 快捷设置导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
    public func setLeftBarItem(_ object: Any?, target: Any, action: Selector) {
        base.navigationItem.leftBarButtonItem = UIBarButtonItem.fw.item(object: object, target: target, action: action)
    }
    
    /// 快捷设置导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
    public func setLeftBarItem(_ object: Any?, block: @escaping (Any) -> Void) {
        base.navigationItem.leftBarButtonItem = UIBarButtonItem.fw.item(object: object, block: block)
    }
    
    /// 快捷设置导航栏右侧按钮
    public func setRightBarItem(_ object: Any?, target: Any, action: Selector) {
        base.navigationItem.rightBarButtonItem = UIBarButtonItem.fw.item(object: object, target: target, action: action)
    }
    
    /// 快捷设置导航栏右侧按钮，block事件
    public func setRightBarItem(_ object: Any?, block: @escaping (Any) -> Void) {
        base.navigationItem.rightBarButtonItem = UIBarButtonItem.fw.item(object: object, block: block)
    }

    /// 快捷添加导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
    public func addLeftBarItem(_ object: Any?, target: Any, action: Selector) {
        let barItem = UIBarButtonItem.fw.item(object: object, target: target, action: action)
        var items = base.navigationItem.leftBarButtonItems ?? []
        items.append(barItem)
        base.navigationItem.leftBarButtonItems = items
    }

    /// 快捷添加导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
    public func addLeftBarItem(_ object: Any?, block: @escaping (Any) -> Void) {
        let barItem = UIBarButtonItem.fw.item(object: object, block: block)
        var items = base.navigationItem.leftBarButtonItems ?? []
        items.append(barItem)
        base.navigationItem.leftBarButtonItems = items
    }

    /// 快捷添加导航栏右侧按钮
    public func addRightBarItem(_ object: Any?, target: Any, action: Selector) {
        let barItem = UIBarButtonItem.fw.item(object: object, target: target, action: action)
        var items = base.navigationItem.rightBarButtonItems ?? []
        items.append(barItem)
        base.navigationItem.rightBarButtonItems = items
    }

    /// 快捷添加导航栏右侧按钮，block事件
    public func addRightBarItem(_ object: Any?, block: @escaping (Any) -> Void) {
        let barItem = UIBarButtonItem.fw.item(object: object, block: block)
        var items = base.navigationItem.rightBarButtonItems ?? []
        items.append(barItem)
        base.navigationItem.rightBarButtonItems = items
    }
    
}

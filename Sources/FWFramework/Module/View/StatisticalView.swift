//
//  StatisticalView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - StatisticalManager
extension Notification.Name {
    
    /// 统计事件触发通知，可统一处理。通知object为StatisticalEvent对象，userInfo为附加信息
    public static let StatisticalEventTriggered = Notification.Name("FWStatisticalEventTriggeredNotification")
    
}

/// 事件统计管理器
///
/// 视图从不可见变为可见时曝光开始，触发曝光开始事件(triggerDuration为0)；
/// 视图从可见到不可见时曝光结束，视为一次曝光，触发曝光结束事件(triggerDuration大于0)并统计曝光时长。
/// 默认未开启曝光时长统计，仅触发开始事件用于统计次数；开启曝光时长统计后会触发结束事件并统计时长，应用退后台时不计曝光时间。
/// 默认运行模式时，视图快速滚动不计算曝光，可配置runLoopMode快速滚动时也计算曝光
public class StatisticalManager: NSObject {
    
    // MARK: - Accessor
    /// 单例模式
    public static let shared = StatisticalManager()
    
    /// 是否启用通知，默认false
    public var notificationEnabled = false
    /// 是否启用分析上报，默认false
    public var reportEnabled = false
    /// 设置全局事件过滤器
    public var eventFilter: ((StatisticalEvent) -> Bool)?
    /// 设置全局事件处理器
    public var eventHandler: ((StatisticalEvent) -> Void)?
    
    /// 是否相同点击只触发一次，默认false，视图自定义后覆盖默认
    public var clickOnce = false
    /// 是否相同曝光只触发一次，默认false，视图自定义后覆盖默认
    public var exposureOnce = false
    /// 设置运行模式，默认default快速滚动时不计算曝光
    public var runLoopMode: RunLoop.Mode = .default
    
    /// 是否统计曝光时长，开启后会触发曝光结束事件并计算时长，默认false
    public var exposureTime = false
    /// 设置部分可见时触发曝光的比率，范围0-1，默认>=0.95会触发曝光(因为frame有小数，忽略计算误差)
    public var exposureThresholds: CGFloat = 0.95
    /// 计算曝光时是否自动屏蔽控制器的顶部栏和底部栏，默认true
    public var exposureIgnoredBars = true
    /// 应用回到前台时是否重新计算曝光，默认true
    public var exposureBecomeActive = true
    
    private var eventHandlers: [String: (StatisticalEvent) -> Void] = [:]
    
    // MARK: - Public
    /// 注册单个事件处理器
    public func registerEvent(_ name: String, handler: @escaping (StatisticalEvent) -> Void) {
        eventHandlers[name] = handler
    }
    
    /// 手工触发点击统计，如果为cell需指定indexPath，点击触发时调用
    public func trackClick(_ view: UIView?, indexPath: IndexPath? = nil, event: StatisticalEvent) {
        if event.triggerIgnored { return }
        if let eventFilter = eventFilter, !eventFilter(event) { return }
        
        let triggerKey = StatisticalManager.statisticalIdentifier(event: event, indexPath: indexPath)
        let triggerCount = (view?.fw_statisticalTarget.clickCounts[triggerKey] ?? 0) + 1
        let triggerOnce = event.triggerOnce != nil ? (event.triggerOnce ?? false) : clickOnce
        if triggerCount > 1 && triggerOnce { return }
        view?.fw_statisticalTarget.clickCounts[triggerKey] = triggerCount
        
        event.view = view
        event.viewController = view?.fw_viewController
        event.indexPath = indexPath
        event.triggerCount = triggerCount
        event.triggerTimestamp = Date.fw_currentTime
        event.isExposure = false
        event.isFinished = true
        handleEvent(event)
    }
    
    /// 手工触发视图曝光并统计次数，如果为cell需指定indexPath，isFinished为曝光结束，可重复触发
    public func trackExposure(_ view: UIView?, indexPath: IndexPath? = nil, isFinished: Bool = false, event: StatisticalEvent) {
        if event.triggerIgnored { return }
        if let eventFilter = eventFilter, !eventFilter(event) { return }
        
        let triggerKey = StatisticalManager.statisticalIdentifier(event: event, indexPath: indexPath)
        var triggerCount = (view?.fw_statisticalTarget.exposureCounts[triggerKey] ?? 0)
        if !isFinished {
            triggerCount += 1
        }
        let triggerOnce = event.triggerOnce != nil ? (event.triggerOnce ?? false) : exposureOnce
        if triggerCount > 1 && triggerOnce { return }
        if !isFinished {
            view?.fw_statisticalTarget.exposureCounts[triggerKey] = triggerCount
        }
        
        let isVisibleCells = view?.statisticalViewVisibleIndexPaths() != nil
        var totalDuration = (view?.fw_statisticalTarget.exposureDurations[triggerKey] ?? 0)
        var duration: TimeInterval = 0
        let triggerTimestamp = Date.fw_currentTime
        if isFinished {
            var exposureTimestamp: TimeInterval?
            if isVisibleCells {
                exposureTimestamp = view?.fw_statisticalTarget.exposureTimestamps[triggerKey]
                view?.fw_statisticalTarget.exposureBegins[triggerKey] = nil
                view?.fw_statisticalTarget.exposureTimestamps[triggerKey] = nil
            } else {
                exposureTimestamp = view?.fw_statisticalTarget.exposureTimestamp
                view?.fw_statisticalTarget.exposureBegin = nil
                view?.fw_statisticalTarget.exposureTimestamp = 0
            }
            if let exposureTimestamp = exposureTimestamp, exposureTimestamp > 0 {
                duration = triggerTimestamp - exposureTimestamp
                totalDuration += duration
            }
            view?.fw_statisticalTarget.exposureDurations[triggerKey] = totalDuration
        } else {
            if isVisibleCells {
                view?.fw_statisticalTarget.exposureTimestamps[triggerKey] = triggerTimestamp
            } else {
                view?.fw_statisticalTarget.exposureTimestamp = triggerTimestamp
            }
        }
        let isBackground = UIApplication.shared.applicationState == .background
        let isTerminated = view?.fw_statisticalTarget.exposureTerminated ?? false
        
        event.view = view
        event.viewController = view?.fw_viewController
        event.indexPath = indexPath
        event.triggerCount = triggerCount
        event.triggerTimestamp = triggerTimestamp
        event.triggerDuration = duration
        event.totalDuration = totalDuration
        event.isExposure = true
        event.isFinished = isFinished
        event.isBackground = isBackground
        event.isTerminated = isTerminated
        
        if !isFinished {
            if isVisibleCells {
                view?.fw_statisticalTarget.exposureBegins[triggerKey] = event.copy() as? StatisticalEvent
            } else {
                view?.fw_statisticalTarget.exposureBegin = event.copy() as? StatisticalEvent
            }
        }
        handleEvent(event)
    }
    
    /// 手工触发控制器曝光并统计次数，isFinished为曝光结束，可重复触发
    public func trackExposure(_ viewController: UIViewController?, isFinished: Bool = false, event: StatisticalEvent) {
        if event.triggerIgnored { return }
        if let eventFilter = eventFilter, !eventFilter(event) { return }
        
        var triggerCount = (viewController?.fw_statisticalTarget.exposureCount ?? 0)
        if !isFinished {
            triggerCount += 1
        }
        let triggerOnce = event.triggerOnce != nil ? (event.triggerOnce ?? false) : exposureOnce
        if triggerCount > 1 && triggerOnce { return }
        if !isFinished {
            viewController?.fw_statisticalTarget.exposureCount = triggerCount
        }
        
        var totalDuration = (viewController?.fw_statisticalTarget.exposureDuration ?? 0)
        var duration: TimeInterval = 0
        let triggerTimestamp = Date.fw_currentTime
        if isFinished {
            let exposureTimestamp = viewController?.fw_statisticalTarget.exposureTimestamp
            if let exposureTimestamp = exposureTimestamp, exposureTimestamp > 0 {
                duration = triggerTimestamp - exposureTimestamp
                totalDuration += duration
            }
            viewController?.fw_statisticalTarget.exposureDuration = totalDuration
            viewController?.fw_statisticalTarget.exposureBegin = nil
            viewController?.fw_statisticalTarget.exposureTimestamp = 0
        } else {
            viewController?.fw_statisticalTarget.exposureTimestamp = triggerTimestamp
        }
        let isBackground = UIApplication.shared.applicationState == .background
        let isTerminated = viewController?.fw_statisticalTarget.exposureTerminated ?? false
        
        event.view = nil
        event.viewController = viewController
        event.indexPath = nil
        event.triggerCount = triggerCount
        event.triggerTimestamp = triggerTimestamp
        event.triggerDuration = duration
        event.totalDuration = totalDuration
        event.isExposure = true
        event.isFinished = isFinished
        event.isBackground = isBackground
        event.isTerminated = isTerminated
        
        if !isFinished {
            viewController?.fw_statisticalTarget.exposureBegin = event.copy() as? StatisticalEvent
        }
        handleEvent(event)
    }
    
    // MARK: - Private
    /// 内部方法，处理事件
    private func handleEvent(_ event: StatisticalEvent) {
        let event = event.eventFormatter?(event) ?? event
        if event.isExposure {
            if event.view != nil {
                event.view?.fw_statisticalExposureListener?(event)
            } else {
                event.viewController?.fw_statisticalExposureListener?(event)
            }
        } else {
            event.view?.fw_statisticalClickListener?(event)
        }
        
        if let handler = eventHandlers[event.name] {
            handler(event)
        }
        eventHandler?(event)
        if reportEnabled, !event.name.isEmpty {
            Analyzer.shared.trackEvent(event.name, parameters: event.userInfo)
        }
        if notificationEnabled {
            NotificationCenter.default.post(name: .StatisticalEventTriggered, object: event, userInfo: event.userInfo)
        }
    }
    
    fileprivate static func statisticalIdentifier(event: StatisticalEvent?, indexPath: IndexPath? = nil, indexPaths: [IndexPath]? = nil) -> String {
        var identifier = "\(String.fw_safeString(event?.name))-\(String.fw_safeString(event?.object))"
        if let indexPaths = indexPaths {
            for indexPath in indexPaths {
                identifier += "-\(indexPath.section).\(indexPath.row)"
            }
        } else if let indexPath = indexPath {
            identifier += "-\(indexPath.section).\(indexPath.row)"
        }
        return identifier
    }
    
    private static var statisticalSwizzled = false
    
    fileprivate static func swizzleStatistical() {
        guard !statisticalSwizzled else { return }
        statisticalSwizzled = true
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.didMoveToSuperview),
            methodSignature: (@convention(c) (UIView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.superview == nil {
                selfObject.fw_statisticalRemoveObservers()
            } else {
                if selfObject.fw_statisticalClick != nil {
                    selfObject.fw_statisticalBindClick()
                }
                if selfObject.fw_statisticalExposure != nil {
                    selfObject.fw_statisticalBindExposure()
                }
                
                selfObject.fw_statisticalAddObservers()
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.didMoveToWindow),
            methodSignature: (@convention(c) (UIView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.fw_statisticalExposure != nil {
                selfObject.fw_statisticalCheckExposure()
            }
        }}
    }
    
}

// MARK: - StatisticalEvent
/// 事件统计对象
public class StatisticalEvent: NSObject, NSCopying {
    
    /// 事件绑定名称，只读
    public fileprivate(set) var name: String = ""
    /// 事件绑定对象，只读
    public fileprivate(set) var object: Any?
    /// 事件绑定信息，可写
    public var userInfo: [AnyHashable: Any]?
    
    /// 自定义曝光容器视图，默认nil时获取VC视图或window
    public weak var containerView: UIView?
    /// 自定义曝光容器内边距，设置后忽略全局ignoredBars配置，默认nil
    public var containerInset: UIEdgeInsets?
    /// 是否事件仅触发一次，默认nil时采用全局配置
    public var triggerOnce: Bool?
    /// 是否忽略事件触发，默认false
    public var triggerIgnored = false
    /// 曝光遮挡视图，被遮挡时不计曝光，参数为所在视图
    public var shieldView: ((UIView) -> UIView?)?
    /// 自定义曝光句柄，参数为所在视图或控制器，用于自定义处理
    public var exposureBlock: ((Any) -> Bool)?
    /// 格式化事件句柄，用于替换indexPath数据为cell数据，默认nil
    public var eventFormatter: ((StatisticalEvent) -> StatisticalEvent)?
    
    /// 事件来源视图，触发时自动赋值
    public fileprivate(set) weak var view: UIView?
    /// 事件来源控制器，触发时自动赋值
    public fileprivate(set) weak var viewController: UIViewController?
    /// 事件来源位置，触发时自动赋值
    public fileprivate(set) var indexPath: IndexPath?
    /// 事件触发次数，触发时自动赋值
    public fileprivate(set) var triggerCount: Int = 0
    /// 事件触发时间戳，触发时自动赋值
    public fileprivate(set) var triggerTimestamp: TimeInterval = 0
    /// 曝光事件触发单次时长，0表示曝光开始，触发时自动赋值
    public fileprivate(set) var triggerDuration: TimeInterval = 0
    /// 曝光事件触发总时长，触发时自动赋值
    public fileprivate(set) var totalDuration: TimeInterval = 0
    /// 是否是曝光事件，默认false为点击事件
    public fileprivate(set) var isExposure = false
    /// 曝光事件是否完成，注意曝光会触发两次，第一次为false曝光开始，第二次为true曝光结束
    public fileprivate(set) var isFinished = false
    /// 曝光事件是否在后台触发，默认false
    public fileprivate(set) var isBackground = false
    /// 曝光事件是否在应用结束时触发，默认false
    public fileprivate(set) var isTerminated = false
    
    /// 创建事件统计对象，指定名称、对象和信息
    public required init(name: String, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        super.init()
        self.name = name
        self.object = object
        self.userInfo = userInfo
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let event = Self.init(name: name, object: object, userInfo: userInfo)
        event.containerView = containerView
        event.containerInset = containerInset
        event.triggerOnce = triggerOnce
        event.triggerIgnored = triggerIgnored
        event.shieldView = shieldView
        event.exposureBlock = exposureBlock
        event.eventFormatter = eventFormatter
        
        event.view = view
        event.viewController = viewController
        event.indexPath = indexPath
        event.triggerCount = triggerCount
        event.triggerTimestamp = triggerTimestamp
        event.triggerDuration = triggerDuration
        event.totalDuration = totalDuration
        event.isExposure = isExposure
        event.isFinished = isFinished
        event.isBackground = isBackground
        event.isTerminated = isTerminated
        return event
    }
    
}

// MARK: - StatisticalViewProtocol
/// 可统计视图协议，UIView默认实现，子类可重写
@objc public protocol StatisticalViewProtocol {
    
    /// 可统计视图绑定点击事件方法，返回绑定结果，子类可重写，勿直接调用
    func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool
    
    /// 可统计视图绑定曝光事件方法，返回绑定结果，子类可重写，勿直接调用
    func statisticalViewWillBindExposure(_ containerView: UIView?) -> Bool
    
    /// 可统计视图子视图列表方法，返回nil时不处理，一般container实现(批量曝光)，子类可重写
    func statisticalViewChildViews() -> [UIView]?
    
    /// 可统计视图可见indexPaths方法，返回nil时不处理，一般container实现(批量曝光)，子类可重写
    func statisticalViewVisibleIndexPaths() -> [IndexPath]?
    
    /// 可统计视图容器视图方法，返回nil时不处理，一般cell实现，子类可重写
    func statisticalViewContainerView() -> UIView?
    
    /// 可统计视图索引位置方法，返回nil时不处理，一般cell(批量曝光)和container(单曝光)实现，子类可重写
    func statisticalViewIndexPath() -> IndexPath?
    
}

@objc extension UIView: StatisticalViewProtocol {
    
    /// 默认实现绑定点击事件方法，返回绑定结果，子类可重写，勿直接调用
    open func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        if let control = self as? UIControl {
            var controlEvents = UIControl.Event.touchUpInside
            if self is UIDatePicker ||
                self is UIPageControl ||
                self is UISegmentedControl ||
                self is UISlider ||
                self is UIStepper ||
                self is UISwitch ||
                self is UITextField {
                controlEvents = .valueChanged
            }
            control.fw_addBlock({ sender in
                (sender as? UIControl)?.fw_statisticalTrackClick()
            }, for: controlEvents)
            return true
        }
        
        guard let gestureRecognizers = self.gestureRecognizers else { return false }
        for gesture in gestureRecognizers {
            if let tapGesture = gesture as? UITapGestureRecognizer {
                tapGesture.fw_addBlock { sender in
                    (sender as? UIGestureRecognizer)?.view?.fw_statisticalTrackClick()
                }
                return true
            }
        }
        return false
    }
    
    /// 可统计视图绑定曝光事件方法，返回绑定结果，子类可重写，勿直接调用
    open func statisticalViewWillBindExposure(_ containerView: UIView?) -> Bool {
        if self == containerView {
            return true
        }
        superview?.fw_statisticalBindExposure(containerView)
        return true
    }
    
    /// 可统计视图子视图列表方法，返回nil时不处理，一般container实现(批量曝光)，子类可重写
    open func statisticalViewChildViews() -> [UIView]? {
        return nil
    }
    
    /// 可统计视图可见indexPaths方法，返回nil时不处理，一般container实现(批量曝光)，子类可重写
    open func statisticalViewVisibleIndexPaths() -> [IndexPath]? {
        return nil
    }
    
    /// 可统计视图容器视图方法，返回nil时不处理，一般cell实现，子类可重写
    open func statisticalViewContainerView() -> UIView? {
        return nil
    }
    
    /// 可统计视图索引位置方法，返回nil时不处理，一般cell(批量曝光)和container(单曝光)实现，子类可重写
    open func statisticalViewIndexPath() -> IndexPath? {
        return nil
    }
    
}

@_spi(FW) extension UITableView {
    
    open override func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        guard let tableDelegate = self.delegate as? NSObject else { return false }
        NSObject.fw_swizzleMethod(
            tableDelegate,
            selector: #selector(UITableViewDelegate.tableView(_:didSelectRowAt:)),
            identifier: "FWStatisticalManager",
            methodSignature: (@convention(c) (NSObject, Selector, UITableView, IndexPath) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, UITableView, IndexPath) -> Void).self
        ) { store in { selfObject, tableView, indexPath in
            store.original(selfObject, store.selector, tableView, indexPath)
            
            if !selfObject.fw_isSwizzleInstanceMethod(#selector(UITableViewDelegate.tableView(_:didSelectRowAt:)), identifier: "FWStatisticalManager") { return }
            
            let cell = tableView.cellForRow(at: indexPath)
            let isTracked = cell?.fw_statisticalTrackClick(indexPath: indexPath) ?? false
            if !isTracked, let containerView = cell?.statisticalViewContainerView() {
                containerView.fw_statisticalTrackClick(indexPath: indexPath)
            }
        }}
        return true
    }
    
    open override func statisticalViewChildViews() -> [UIView]? {
        return subviews
    }
    
}

@_spi(FW) extension UICollectionView {
    
    open override func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        guard let collectionDelegate = self.delegate as? NSObject else { return false }
        NSObject.fw_swizzleMethod(
            collectionDelegate,
            selector: #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:)),
            identifier: "FWStatisticalManager",
            methodSignature: (@convention(c) (NSObject, Selector, UICollectionView, IndexPath) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, UICollectionView, IndexPath) -> Void).self
        ) { store in { selfObject, collectionView, indexPath in
            store.original(selfObject, store.selector, collectionView, indexPath)
            
            if !selfObject.fw_isSwizzleInstanceMethod(#selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:)), identifier: "FWStatisticalManager") { return }
            
            let cell = collectionView.cellForItem(at: indexPath)
            let isTracked = cell?.fw_statisticalTrackClick(indexPath: indexPath) ?? false
            if !isTracked, let containerView = cell?.statisticalViewContainerView() {
                containerView.fw_statisticalTrackClick(indexPath: indexPath)
            }
        }}
        return true
    }
    
    open override func statisticalViewChildViews() -> [UIView]? {
        return subviews
    }
    
}

@_spi(FW) extension UITableViewCell {
    
    open override func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        guard let tableView = (containerView as? UITableView) ?? statisticalViewContainerView() else {
            return false
        }
        return tableView.fw_statisticalBindClick()
    }
    
    open override func statisticalViewWillBindExposure(_ containerView: UIView?) -> Bool {
        guard let tableView = (containerView as? UITableView) ?? statisticalViewContainerView() else {
            return false
        }
        return tableView.fw_statisticalBindExposure(containerView)
    }
    
    open override func statisticalViewContainerView() -> UIView? {
        return fw_tableView
    }
    
    open override func statisticalViewIndexPath() -> IndexPath? {
        return fw_tableView?.indexPath(for: self)
    }
    
}

@_spi(FW) extension UICollectionViewCell {
    
    open override func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        guard let collectionView = (containerView as? UICollectionView) ?? statisticalViewContainerView() else {
            return false
        }
        return collectionView.fw_statisticalBindClick()
    }
    
    open override func statisticalViewWillBindExposure(_ containerView: UIView?) -> Bool {
        guard let collectionView = (containerView as? UICollectionView) ?? statisticalViewContainerView() else {
            return false
        }
        return collectionView.fw_statisticalBindExposure(containerView)
    }
    
    open override func statisticalViewContainerView() -> UIView? {
        return fw_collectionView
    }
    
    open override func statisticalViewIndexPath() -> IndexPath? {
        return fw_collectionView?.indexPath(for: self)
    }
    
}

// MARK: - UIView+StatisticalView
@_spi(FW) extension UIView {
    
    fileprivate class StatisticalTarget: NSObject {
        weak var view: UIView?
        
        var clickCounts: [String: Int] = [:]
        
        var exposureFully = false
        var exposureIdentifier = ""
        var exposureState: StatisticalState = .none
        var exposureObserved = false
        
        var exposureCounts: [String: Int] = [:]
        var exposureDurations: [String: TimeInterval] = [:]
        var exposureTimestamp: TimeInterval = 0
        var exposureTimestamps: [String: TimeInterval] = [:]
        var exposureBegin: StatisticalEvent?
        var exposureBegins: [String: StatisticalEvent] = [:]
        var exposureTerminated = false
        
        deinit {
            removeObservers()
        }
        
        func addObservers() {
            guard !exposureObserved else { return }
            exposureObserved = true
            
            view?.addObserver(self, forKeyPath: "alpha", options: [.new, .old], context: nil)
            view?.addObserver(self, forKeyPath: "hidden", options: [.new, .old], context: nil)
            view?.addObserver(self, forKeyPath: "frame", options: [.new, .old], context: nil)
            view?.addObserver(self, forKeyPath: "bounds", options: [.new, .old], context: nil)
            
            if StatisticalManager.shared.exposureBecomeActive ||
                StatisticalManager.shared.exposureTime {
                NotificationCenter.default.addObserver(self, selector: #selector(self.appBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(self.appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
            }
            if StatisticalManager.shared.exposureTime {
                NotificationCenter.default.addObserver(self, selector: #selector(self.appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
            }
        }
        
        func removeObservers() {
            guard exposureObserved else { return }
            exposureObserved = false
            
            view?.removeObserver(self, forKeyPath: "alpha")
            view?.removeObserver(self, forKeyPath: "hidden")
            view?.removeObserver(self, forKeyPath: "frame")
            view?.removeObserver(self, forKeyPath: "bounds")
            
            if StatisticalManager.shared.exposureBecomeActive ||
                StatisticalManager.shared.exposureTime {
                NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
            }
            if StatisticalManager.shared.exposureTime {
                NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
            }
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            var valueChanged = false
            if keyPath == "alpha" {
                let oldValue = change?[.oldKey] as? Double
                let newValue = change?[.newKey] as? Double
                valueChanged = newValue != oldValue
            } else if keyPath == "hidden" {
                let oldValue = change?[.oldKey] as? Bool
                let newValue = change?[.newKey] as? Bool
                valueChanged = newValue != oldValue
            } else if keyPath == "frame" {
                let oldValue = (change?[.oldKey] as? NSValue)?.cgRectValue
                let newValue = (change?[.newKey] as? NSValue)?.cgRectValue
                valueChanged = newValue != oldValue
            } else if keyPath == "bounds" {
                let oldValue = (change?[.oldKey] as? NSValue)?.cgRectValue
                let newValue = (change?[.newKey] as? NSValue)?.cgRectValue
                valueChanged = newValue != oldValue
            }
            
            if valueChanged {
                (object as? UIView)?.fw_statisticalCheckExposure()
            }
        }
        
        @objc func appBecomeActive() {
            view?.fw_statisticalCheckExposure()
        }
        
        @objc func appEnterBackground() {
            view?.fw_statisticalCheckExposure()
        }
        
        @objc func appWillTerminate() {
            exposureTerminated = true
            view?.fw_statisticalCheckExposure()
        }
        
        @objc func exposureUpdate() {
            if view?.statisticalViewVisibleIndexPaths() == nil,
               let childViews = view?.statisticalViewChildViews() {
                childViews.forEach { childView in
                    childView.fw_statisticalCheckState()
                }
            } else {
                view?.fw_statisticalCheckState()
            }
        }
    }
    
    fileprivate enum StatisticalState: Equatable {
        case none
        case partly(CGFloat)
        case fully
        
        var isFully: Bool {
            switch self {
            case .fully:
                return true
            case .partly(let ratio):
                return ratio >= StatisticalManager.shared.exposureThresholds
            default:
                return false
            }
        }
        
        func isState(_ state: StatisticalState) -> Bool {
            if case StatisticalState.partly(_) = self,
               case StatisticalState.partly(_) = state {
                return true
            }
            return self == state
        }
    }
    
    // MARK: - Click
    /// 设置并尝试自动绑定点击事件统计
    public var fw_statisticalClick: StatisticalEvent? {
        get {
            return fw_property(forName: "fw_statisticalClick") as? StatisticalEvent
        }
        set {
            fw_setProperty(newValue, forName: "fw_statisticalClick")
            StatisticalManager.swizzleStatistical()
            fw_statisticalBindClick(newValue?.containerView)
        }
    }
    
    /// 设置统计点击事件触发时自定义监听器，默认nil
    public var fw_statisticalClickListener: ((StatisticalEvent) -> Void)? {
        get { fw_property(forName: "fw_statisticalClickListener") as? (StatisticalEvent) -> Void }
        set { fw_setPropertyCopy(newValue, forName: "fw_statisticalClickListener") }
    }
    
    /// 手工绑定点击事件统计，可指定容器视图，自动绑定失败时可手工调用
    @discardableResult
    public func fw_statisticalBindClick(_ containerView: UIView? = nil) -> Bool {
        guard !fw_propertyBool(forName: "fw_statisticalBindClick") else { return true }
        let result = statisticalViewWillBindClick(containerView)
        if result { fw_setPropertyBool(true, forName: "fw_statisticalBindClick") }
        return result
    }
    
    /// 触发视图点击事件统计，仅绑定statisticalClick后生效
    @discardableResult
    public func fw_statisticalTrackClick(indexPath: IndexPath? = nil, event: StatisticalEvent? = nil) -> Bool {
        guard let event = event ?? fw_statisticalClick else { return false }
        StatisticalManager.shared.trackClick(self, indexPath: indexPath, event: event)
        return true
    }
    
    // MARK: - Exposure
    /// 设置并尝试自动绑定曝光事件统计。如果对象发生变化(indexPath|name|object)，也会触发
    public var fw_statisticalExposure: StatisticalEvent? {
        get {
            return fw_property(forName: "fw_statisticalExposure") as? StatisticalEvent
        }
        set {
            let oldValue = fw_statisticalExposure
            fw_setProperty(newValue, forName: "fw_statisticalExposure")
            StatisticalManager.swizzleStatistical()
            fw_statisticalBindExposure(newValue?.containerView)
            if oldValue != nil, newValue == nil {
                fw_statisticalRemoveObservers()
            }
        }
    }
    
    /// 设置统计曝光事件触发时自定义监听器，默认nil
    public var fw_statisticalExposureListener: ((StatisticalEvent) -> Void)? {
        get { fw_property(forName: "fw_statisticalExposureListener") as? (StatisticalEvent) -> Void }
        set { fw_setPropertyCopy(newValue, forName: "fw_statisticalExposureListener") }
    }
    
    /// 手工绑定曝光事件统计，可指定容器视图，自动绑定失败时可手工调用
    @discardableResult
    public func fw_statisticalBindExposure(_ containerView: UIView? = nil) -> Bool {
        var result = fw_propertyBool(forName: "fw_statisticalBindExposure")
        if !result {
            result = statisticalViewWillBindExposure(containerView)
            if result {
                fw_setPropertyBool(true, forName: "fw_statisticalBindExposure")
                fw_statisticalAddObservers()
            }
        }
        guard result else { return false }
        
        if (fw_statisticalExposure != nil && window != nil) ||
            StatisticalManager.shared.exposureTime {
            fw_statisticalCheckExposure()
        }
        return result
    }
    
    /// 触发视图曝光事件统计，仅绑定statisticalExposure后生效
    @discardableResult
    public func fw_statisticalTrackExposure(indexPath: IndexPath? = nil, isFinished: Bool = false, event: StatisticalEvent? = nil) -> Bool {
        guard let event = event ?? fw_statisticalExposure else { return false }
        StatisticalManager.shared.trackExposure(self, indexPath: indexPath, isFinished: isFinished, event: event)
        return true
    }
    
    /// 检查并更新视图曝光状态，用于自定义场景
    public func fw_statisticalCheckExposure() {
        guard fw_propertyBool(forName: "fw_statisticalBindExposure") else { return }
        
        if fw_statisticalExposure != nil {
            NSObject.cancelPreviousPerformRequests(withTarget: fw_statisticalTarget, selector: #selector(StatisticalTarget.exposureUpdate), object: nil)
            fw_statisticalTarget.perform(#selector(StatisticalTarget.exposureUpdate), with: nil, afterDelay: 0, inModes: [StatisticalManager.shared.runLoopMode])
        }
        
        if statisticalViewVisibleIndexPaths() == nil {
            let childViews = statisticalViewChildViews() ?? subviews
            childViews.forEach { childView in
                childView.fw_statisticalCheckExposure()
            }
        }
    }
    
    // MARK: - Private
    fileprivate var fw_statisticalTarget: StatisticalTarget {
        if let target = fw_property(forName: "fw_statisticalTarget") as? StatisticalTarget {
            return target
        } else {
            let target = StatisticalTarget()
            target.view = self
            fw_setProperty(target, forName: "fw_statisticalTarget")
            return target
        }
    }
    
    fileprivate func fw_statisticalAddObservers() {
        guard fw_propertyBool(forName: "fw_statisticalBindExposure") else { return }
        fw_statisticalTarget.addObservers()
    }
    
    fileprivate func fw_statisticalRemoveObservers() {
        guard fw_propertyBool(forName: "fw_statisticalBindExposure") else { return }
        fw_statisticalTarget.removeObservers()
    }
    
    fileprivate func fw_statisticalCheckState() {
        var isVisibleCells = false
        var indexPaths: [IndexPath] = []
        var indexPath: IndexPath?
        var event = fw_statisticalExposure
        var identifier: String = ""
        if let visibleIndexPaths = statisticalViewVisibleIndexPaths() {
            isVisibleCells = true
            indexPaths = visibleIndexPaths.sorted(by: { ip1, ip2 in
                return ip1.section < ip2.section || ip1.row < ip2.row
            })
            identifier = StatisticalManager.statisticalIdentifier(event: event, indexPaths: indexPaths)
        } else {
            indexPath = statisticalViewIndexPath()
            event = event ?? statisticalViewContainerView()?.fw_statisticalExposure
            identifier = StatisticalManager.statisticalIdentifier(event: event, indexPath: indexPath)
        }
        let oldIdentifier = fw_statisticalTarget.exposureIdentifier
        let identifierChanged = !oldIdentifier.isEmpty && identifier != oldIdentifier
        if oldIdentifier.isEmpty || identifierChanged {
            fw_statisticalTarget.exposureIdentifier = identifier
        }
        
        let oldState = fw_statisticalTarget.exposureState
        let state = fw_statisticalExposureState
        if state.isState(oldState), !identifierChanged { return }
        fw_statisticalTarget.exposureState = state
        
        var isBegin = false
        var isFinished = false
        if state.isFully, (!fw_statisticalTarget.exposureFully || identifierChanged) {
            fw_statisticalTarget.exposureFully = true
            isFinished = true
            isBegin = true
        } else if state == .none || identifierChanged {
            fw_statisticalTarget.exposureFully = false
            isFinished = true
        }
        
        if isVisibleCells {
            var finishExposures = fw_statisticalTarget.exposureBegins
            var beginExposures: [IndexPath] = []
            if isFinished, isBegin {
                for indexPath in indexPaths {
                    let finishKey = StatisticalManager.statisticalIdentifier(event: event, indexPath: indexPath)
                    if finishExposures[finishKey] != nil {
                        finishExposures.removeValue(forKey: finishKey)
                    } else {
                        beginExposures.append(indexPath)
                    }
                }
            }
            
            if isFinished, !finishExposures.isEmpty {
                if StatisticalManager.shared.exposureTime {
                    for (_, finishExposure) in finishExposures {
                        fw_statisticalTrackExposure(indexPath: finishExposure.indexPath, isFinished: true, event: finishExposure)
                    }
                } else {
                    for (finishKey, _) in finishExposures {
                        fw_statisticalTarget.exposureBegins.removeValue(forKey: finishKey)
                        fw_statisticalTarget.exposureTimestamps.removeValue(forKey: finishKey)
                    }
                }
            }
            
            if isBegin, !beginExposures.isEmpty {
                for indexPath in beginExposures {
                    fw_statisticalTrackExposure(indexPath: indexPath, event: event)
                }
            }
        } else {
            if isFinished, let finishExposure = fw_statisticalTarget.exposureBegin {
                if StatisticalManager.shared.exposureTime {
                    fw_statisticalTrackExposure(indexPath: finishExposure.indexPath, isFinished: true, event: finishExposure)
                } else {
                    fw_statisticalTarget.exposureBegin = nil
                    fw_statisticalTarget.exposureTimestamp = 0
                }
            }
            
            if isBegin {
                fw_statisticalTrackExposure(indexPath: indexPath, event: event)
            }
        }
    }
    
    fileprivate var fw_statisticalExposureState: StatisticalState {
        if !fw_isViewVisible {
            return .none
        }
        
        if let exposureBlock = fw_statisticalExposure?.exposureBlock,
           !exposureBlock(self) {
            return .none
        }
        
        if StatisticalManager.shared.exposureBecomeActive ||
            StatisticalManager.shared.exposureTime {
            if UIApplication.shared.applicationState == .background {
                return .none
            }
            if StatisticalManager.shared.exposureTime,
               fw_statisticalTarget.exposureTerminated {
                return .none
            }
        }
        
        let viewController = fw_viewController
        if let viewController = viewController,
            !viewController.fw_isVisible {
            return .none
        }
        
        var containerView = fw_statisticalExposure?.containerView
        if let containerView = containerView {
            if !containerView.fw_isViewVisible {
                return .none
            }
        } else {
            containerView = viewController?.view ?? self.window
        }
        guard let containerView = containerView else {
            return .none
        }
        
        var superview = self.superview
        var superviewHidden = false
        while superview != nil && superview != containerView {
            if !(superview?.fw_isViewVisible ?? false) {
                superviewHidden = true
                break
            }
            superview = superview?.superview
        }
        if superviewHidden {
            return .none
        }
        
        let ratio = fw_statisticalExposureRatio(containerView, viewController: viewController)
        if ratio >= 1.0 {
            return .fully
        } else if ratio > 0 {
            return .partly(ratio)
        }
        return .none
    }
    
    fileprivate func fw_statisticalExposureRatio(_ containerView: UIView, viewController: UIViewController?) -> CGFloat {
        var ratio: CGFloat = 0
        var viewRect = self.convert(self.bounds, to: containerView)
        viewRect = CGRect(x: viewRect.origin.x, y: viewRect.origin.y, width: floor(viewRect.size.width), height: floor(viewRect.size.height))
        
        var tx = CGRectGetMinX(viewRect) - containerView.bounds.origin.x
        var ty = CGRectGetMinY(viewRect) - containerView.bounds.origin.y
        var cw = CGRectGetWidth(containerView.bounds)
        var ch = CGRectGetHeight(containerView.bounds)
        
        if let containerWindow = containerView.window {
            let containerRect = containerView.convert(containerView.bounds, to: containerWindow)
            if containerRect.origin.x < 0 {
                tx += containerRect.origin.x
            }
            if containerRect.origin.y < 0 {
                ty += containerRect.origin.y
            }
            let intersectionRect = CGRectIntersection(containerWindow.bounds, containerRect)
            cw = intersectionRect.size.width
            ch = intersectionRect.size.height
        }
        
        let viewportRect = CGRect(x: tx, y: ty, width: CGRectGetWidth(viewRect), height: CGRectGetHeight(viewRect))
        var containerRect = CGRect(x: 0, y: 0, width: cw, height: ch)
        if let containerInset = self.fw_statisticalExposure?.containerInset {
            containerRect = containerRect.inset(by: containerInset)
        } else if StatisticalManager.shared.exposureIgnoredBars, let viewController = viewController {
            containerRect = containerRect.inset(by: UIEdgeInsets(top: viewController.fw_topBarHeight, left: 0, bottom: viewController.fw_bottomBarHeight, right: 0))
        }
        
        if !viewportRect.isValid {
            return ratio
        }
        let viewSize = CGRectGetWidth(viewRect) * CGRectGetHeight(viewRect)
        if viewSize <= 0 || !containerRect.isValid {
            return ratio
        }
        
        var intersectionRect = CGRectIntersection(containerRect, viewportRect)
        if !intersectionRect.isValid {
            intersectionRect = .zero
        }
        let intersectionSize = CGRectGetWidth(intersectionRect) * CGRectGetHeight(intersectionRect)
        ratio = intersectionSize > 0 ? ceil(intersectionSize / viewSize * 100.0) / 100.0 : 0
        if ratio <= 0 {
            return ratio
        }
        
        let shieldView = self.fw_statisticalExposure?.shieldView?(self)
        guard let shieldView = shieldView, shieldView.fw_isViewVisible else {
            return ratio
        }
        let shieldRect = shieldView.convert(shieldView.bounds, to: containerView)
        if !CGRectIsEmpty(shieldRect) && !CGRectIsEmpty(intersectionRect) {
            if CGRectContainsRect(shieldRect, intersectionRect) {
                ratio = 0
                return ratio
            } else if CGRectIntersectsRect(shieldRect, intersectionRect) {
                var shieldIntersectionRect = CGRectIntersection(shieldRect, intersectionRect)
                if !shieldIntersectionRect.isValid {
                    shieldIntersectionRect = .zero
                }
                let shieldIntersectionSize = CGRectGetWidth(shieldIntersectionRect) * CGRectGetHeight(shieldIntersectionRect)
                let shieldRatio = shieldIntersectionSize > 0 ? ceil(shieldIntersectionSize / intersectionSize * 100.0) / 100.0 : 0
                ratio = ceil(ratio * (1.0 - shieldRatio) * 100.0) / 100.0
                return ratio
            }
        }
        return ratio
    }
    
}

// MARK: - UIViewController+StatisticalView
@_spi(FW) extension UIViewController {
    
    fileprivate class StatisticalTarget: NSObject {
        weak var viewController: UIViewController?
        
        var exposureFully = false
        var exposureIdentifier = ""
        var exposureState: UIView.StatisticalState = .none
        var exposureObserved = false
        
        var exposureCount: Int = 0
        var exposureDuration: TimeInterval = 0
        var exposureTimestamp: TimeInterval = 0
        var exposureBegin: StatisticalEvent?
        var exposureTerminated = false
        
        deinit {
            removeObservers()
        }
        
        func addObservers() {
            guard !exposureObserved else { return }
            exposureObserved = true
            
            viewController?.fw_observeLifecycleState({ vc, state in
                if state == .didAppear {
                    vc.fw_statisticalCheckExposure()
                } else if state == .didDisappear {
                    vc.fw_statisticalCheckExposure()
                }
            })
            
            if StatisticalManager.shared.exposureBecomeActive ||
                StatisticalManager.shared.exposureTime {
                NotificationCenter.default.addObserver(self, selector: #selector(self.appBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(self.appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
            }
            if StatisticalManager.shared.exposureTime {
                NotificationCenter.default.addObserver(self, selector: #selector(self.appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
            }
        }
        
        func removeObservers() {
            guard exposureObserved else { return }
            exposureObserved = false
            
            if StatisticalManager.shared.exposureBecomeActive ||
                StatisticalManager.shared.exposureTime {
                NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
            }
            if StatisticalManager.shared.exposureTime {
                NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
            }
        }
        
        @objc func appBecomeActive() {
            viewController?.fw_statisticalCheckExposure()
        }
        
        @objc func appEnterBackground() {
            viewController?.fw_statisticalCheckExposure()
        }
        
        @objc func appWillTerminate() {
            exposureTerminated = true
            viewController?.fw_statisticalCheckExposure()
        }
    }
    
    // MARK: - Public
    /// 设置并尝试自动绑定曝光事件统计
    public var fw_statisticalExposure: StatisticalEvent? {
        get {
            return fw_property(forName: "fw_statisticalExposure") as? StatisticalEvent
        }
        set {
            let oldValue = fw_statisticalExposure
            fw_setProperty(newValue, forName: "fw_statisticalExposure")
            fw_statisticalBindExposure()
            if oldValue != nil, newValue == nil {
                fw_statisticalTarget.removeObservers()
            }
        }
    }
    
    /// 设置统计曝光事件触发时自定义监听器，默认nil
    public var fw_statisticalExposureListener: ((StatisticalEvent) -> Void)? {
        get { fw_property(forName: "fw_statisticalExposureListener") as? (StatisticalEvent) -> Void }
        set { fw_setPropertyCopy(newValue, forName: "fw_statisticalExposureListener") }
    }
    
    /// 触发控制器曝光事件统计，仅绑定statisticalExposure后生效
    @discardableResult
    public func fw_statisticalTrackExposure(isFinished: Bool = false, event: StatisticalEvent? = nil) -> Bool {
        guard let event = event ?? fw_statisticalExposure else { return false }
        StatisticalManager.shared.trackExposure(self, isFinished: isFinished, event: event)
        return true
    }
    
    /// 检查并更新控制器曝光状态，用于自定义场景
    public func fw_statisticalCheckExposure() {
        guard fw_propertyBool(forName: "fw_statisticalBindExposure") else { return }
        
        let identifier = StatisticalManager.statisticalIdentifier(event: fw_statisticalExposure)
        let oldIdentifier = fw_statisticalTarget.exposureIdentifier
        let identifierChanged = !oldIdentifier.isEmpty && identifier != oldIdentifier
        if oldIdentifier.isEmpty || identifierChanged {
            fw_statisticalTarget.exposureIdentifier = identifier
        }
        
        let oldState = fw_statisticalTarget.exposureState
        let state = fw_statisticalExposureState
        if state.isState(oldState), !identifierChanged { return }
        fw_statisticalTarget.exposureState = state
        
        var isBegin = false
        var isFinished = false
        if state.isFully, (!fw_statisticalTarget.exposureFully || identifierChanged) {
            fw_statisticalTarget.exposureFully = true
            isFinished = true
            isBegin = true
        } else if state == .none || identifierChanged {
            fw_statisticalTarget.exposureFully = false
            isFinished = true
        }
        
        if isFinished, let finishExposure = fw_statisticalTarget.exposureBegin {
            if StatisticalManager.shared.exposureTime {
                fw_statisticalTrackExposure(isFinished: true, event: finishExposure)
            } else {
                fw_statisticalTarget.exposureBegin = nil
                fw_statisticalTarget.exposureTimestamp = 0
            }
        }
        
        if isBegin {
            fw_statisticalTrackExposure()
        }
    }
    
    // MARK: - Private
    fileprivate var fw_statisticalTarget: StatisticalTarget {
        if let target = fw_property(forName: "fw_statisticalTarget") as? StatisticalTarget {
            return target
        } else {
            let target = StatisticalTarget()
            target.viewController = self
            fw_setProperty(target, forName: "fw_statisticalTarget")
            return target
        }
    }
    
    fileprivate func fw_statisticalBindExposure() {
        if !fw_propertyBool(forName: "fw_statisticalBindExposure") {
            fw_setPropertyBool(true, forName: "fw_statisticalBindExposure")
            fw_statisticalTarget.addObservers()
        }
        
        if fw_statisticalExposure != nil ||
            StatisticalManager.shared.exposureTime {
            fw_statisticalCheckExposure()
        }
    }
    
    fileprivate var fw_statisticalExposureState: UIView.StatisticalState {
        if !fw_isVisible {
            return .none
        }
        
        let lifecycleStates: [ViewControllerLifecycleState] = [.didLayoutSubviews, .didAppear]
        if !lifecycleStates.contains(fw_lifecycleState) {
            return .none
        }
        
        if let exposureBlock = fw_statisticalExposure?.exposureBlock,
           !exposureBlock(self) {
            return .none
        }
        
        if StatisticalManager.shared.exposureBecomeActive ||
            StatisticalManager.shared.exposureTime {
            if UIApplication.shared.applicationState == .background {
                return .none
            }
            if StatisticalManager.shared.exposureTime,
               fw_statisticalTarget.exposureTerminated {
                return .none
            }
        }
        
        return .fully
    }
    
}

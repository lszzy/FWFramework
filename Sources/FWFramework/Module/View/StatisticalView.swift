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
    public static let StatisticalEventTriggered = NSNotification.Name("FWStatisticalEventTriggeredNotification")
    
}

/// 事件统计管理器
///
/// 视图从不可见变为可见时曝光开始，触发曝光开始事件(triggerDuration为0)；
/// 视图从可见到不可见时曝光结束，视为一次曝光，触发曝光结束事件(triggerDuration大于0)并统计曝光时长。
/// 目前暂未实现曝光时长统计，仅触发开始事件用于统计次数，可自行处理时长统计，注意应用退后台时不计曝光时间。
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
    
    /// 设置部分可见时触发曝光的比率，范围0-1，默认1，仅视图完全可见时才触发曝光
    public var exposureThresholds: CGFloat = 1
    /// 计算曝光时是否自动屏蔽控制器的顶部栏和底部栏，默认true
    public var exposureIgnoredBars = true
    /// 应用状态改变(前后台切换)时是否重新计算曝光，默认true
    public var exposureWhenAppStateChanged = true
    /// 界面可见状态改变(present或push)时是否重新计算曝光，默认true
    public var exposureWhenVisibilityChanged = true
    
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
        let triggerKey = "\(indexPath?.section ?? -1).\(indexPath?.row ?? -1)-\(event.name)-\(String.fw_safeString(event.object))"
        let triggerCount = (view?.fw_trackClickCounts[triggerKey] ?? 0) + 1
        let triggerOnce = event.triggerOnce != nil ? (event.triggerOnce ?? false) : clickOnce
        if triggerCount > 1 && triggerOnce { return }
        view?.fw_trackClickCounts[triggerKey] = triggerCount
        
        event.view = view
        event.viewController = view?.fw_viewController
        event.indexPath = indexPath
        event.triggerCount = triggerCount
        event.triggerTimestamp = Date.fw_currentTime
        event.isExposure = false
        event.isFinished = true
        handleEvent(event)
    }
    
    /// 手工触发视图曝光并统计次数，如果为cell需指定indexPath，duration为单次曝光时长(0表示开始)，可重复触发
    public func trackExposure(_ view: UIView?, indexPath: IndexPath? = nil, duration: TimeInterval = 0, event: StatisticalEvent) {
        if event.triggerIgnored { return }
        if let eventFilter = eventFilter, !eventFilter(event) { return }
        let isFinished = duration > 0
        let triggerKey = "\(indexPath?.section ?? -1).\(indexPath?.row ?? -1)-\(event.name)-\(String.fw_safeString(event.object))"
        var triggerCount = (view?.fw_trackExposureCounts[triggerKey] ?? 0)
        if !isFinished {
            triggerCount += 1
        }
        let triggerOnce = event.triggerOnce != nil ? (event.triggerOnce ?? false) : exposureOnce
        if triggerCount > 1 && triggerOnce { return }
        if !isFinished {
            view?.fw_trackExposureCounts[triggerKey] = triggerCount
        }
        var totalDuration = (view?.fw_trackExposureDurations[triggerKey] ?? 0)
        if isFinished {
            totalDuration += duration
            view?.fw_trackExposureDurations[triggerKey] = totalDuration
        }
        
        event.view = view
        event.viewController = view?.fw_viewController
        event.indexPath = indexPath
        event.triggerCount = triggerCount
        event.triggerTimestamp = Date.fw_currentTime
        event.triggerDuration = duration
        event.totalDuration = totalDuration
        event.isExposure = true
        event.isFinished = isFinished
        handleEvent(event)
    }
    
    /// 手工触发控制器曝光并统计次数，duration为单次曝光时长(0表示开始)，可重复触发
    public func trackExposure(_ viewController: UIViewController?, duration: TimeInterval = 0, event: StatisticalEvent) {
        if event.triggerIgnored { return }
        if let eventFilter = eventFilter, !eventFilter(event) { return }
        let isFinished = duration > 0
        var triggerCount = (viewController?.fw_trackExposureCount ?? 0)
        if !isFinished {
            triggerCount += 1
        }
        let triggerOnce = event.triggerOnce != nil ? (event.triggerOnce ?? false) : exposureOnce
        if triggerCount > 1 && triggerOnce { return }
        if !isFinished {
            viewController?.fw_trackExposureCount = triggerCount
        }
        var totalDuration = (viewController?.fw_trackExposureDuration ?? 0)
        if isFinished {
            totalDuration += duration
            viewController?.fw_trackExposureDuration = totalDuration
        }
        
        event.view = nil
        event.viewController = viewController
        event.indexPath = nil
        event.triggerCount = triggerCount
        event.triggerTimestamp = Date.fw_currentTime
        event.triggerDuration = duration
        event.totalDuration = totalDuration
        event.isExposure = true
        event.isFinished = isFinished
        handleEvent(event)
    }
    
    // MARK: - Private
    /// 内部方法，处理事件
    private func handleEvent(_ event: StatisticalEvent) {
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
    
}

// MARK: - StatisticalEvent
/// 事件统计对象
public class StatisticalEvent: NSObject {
    
    /// 事件绑定名称
    public private(set) var name: String = ""
    /// 事件绑定对象
    public private(set) var object: Any?
    /// 事件绑定信息
    public private(set) var userInfo: [AnyHashable: Any]?
    
    /// 自定义绑定视图，作为bindClick参数，默认nil
    public weak var bindView: UIView?
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
    /// 自定义曝光计算句柄，返回是否曝光，用于自定义处理
    public var customBlock: ((UIView) -> Bool)?
    
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
    
    /// 创建事件统计对象，指定名称、对象和信息
    public init(name: String, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        super.init()
        self.name = name
        self.object = object
        self.userInfo = userInfo
    }
    
}

// MARK: - StatisticalViewProtocol
/// 可统计视图协议，UIView默认实现，子类可重写
@objc public protocol StatisticalViewProtocol {
    
    /// 可统计视图绑定点击事件方法，返回绑定结果，子类可重写，勿直接调用
    func statisticalViewWillBindClick(_ bindView: UIView?) -> Bool
    
    /// 可统计视图绑定曝光事件方法，返回绑定结果，子类可重写，勿直接调用
    func statisticalViewWillBindExposure(_ bindView: UIView?) -> Bool
    
}

@objc extension UIView: StatisticalViewProtocol {
    
    /// 默认实现绑定点击事件方法，返回绑定结果，子类可重写，勿直接调用
    open func statisticalViewWillBindClick(_ bindView: UIView?) -> Bool {
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
    open func statisticalViewWillBindExposure(_ bindView: UIView?) -> Bool {
        // TODO: - TODO
        return false
    }
    
}

@_spi(FW) extension UIControl {
    
    open override func statisticalViewWillBindClick(_ bindView: UIView?) -> Bool {
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
        self.fw_addBlock({ sender in
            (sender as? UIControl)?.fw_statisticalTrackClick()
        }, for: controlEvents)
        return true
    }
    
}

@_spi(FW) extension UITableView {
    
    open override func statisticalViewWillBindClick(_ bindView: UIView?) -> Bool {
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
            let cellTracked = cell?.fw_statisticalTrackClick(indexPath: indexPath) ?? false
            if !cellTracked {
                tableView.fw_statisticalTrackClick(indexPath: indexPath)
            }
        }}
        return true
    }
    
}

@_spi(FW) extension UICollectionView {
    
    open override func statisticalViewWillBindClick(_ bindView: UIView?) -> Bool {
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
            let cellTracked = cell?.fw_statisticalTrackClick(indexPath: indexPath) ?? false
            if !cellTracked {
                collectionView.fw_statisticalTrackClick(indexPath: indexPath)
            }
        }}
        return true
    }
    
}

@_spi(FW) extension UITableViewCell {
    
    open override func statisticalViewWillBindClick(_ bindView: UIView?) -> Bool {
        guard let tableView = (bindView as? UITableView) ?? self.fw_tableView else {
            UIView.fw_swizzleStatisticalView()
            return false
        }
        return tableView.fw_statisticalBindClick()
    }
    
}

@_spi(FW) extension UICollectionViewCell {
    
    open override func statisticalViewWillBindClick(_ bindView: UIView?) -> Bool {
        guard let collectionView = (bindView as? UICollectionView) ?? self.fw_collectionView else {
            UIView.fw_swizzleStatisticalView()
            return false
        }
        return collectionView.fw_statisticalBindClick()
    }
    
}

// MARK: - UIView+StatisticalClick
@_spi(FW) extension UIView {
    
    // MARK: - Public
    /// 设置并尝试自动绑定点击事件统计
    public var fw_statisticalClick: StatisticalEvent? {
        get {
            return fw_property(forName: "fw_statisticalClick") as? StatisticalEvent
        }
        set {
            fw_setProperty(newValue, forName: "fw_statisticalClick")
            fw_statisticalBindClick(newValue?.bindView)
        }
    }
    
    /// 设置统计点击事件触发时自定义监听器，默认nil
    public var fw_statisticalClickListener: ((StatisticalEvent) -> Void)? {
        get { fw_property(forName: "fw_statisticalClickListener") as? (StatisticalEvent) -> Void }
        set { fw_setPropertyCopy(newValue, forName: "fw_statisticalClickListener") }
    }
    
    /// 手工绑定点击事件统计，可指定绑定视图，自动绑定失败时可手工调用
    @discardableResult
    public func fw_statisticalBindClick(_ bindView: UIView? = nil) -> Bool {
        guard !fw_propertyBool(forName: "fw_statisticalBindClick") else { return true }
        let result = statisticalViewWillBindClick(bindView)
        if result { fw_setPropertyBool(true, forName: "fw_statisticalBindClick") }
        return result
    }
    
    /// 触发视图点击事件统计，仅绑定statisticalClick后生效
    @objc(__fw_statisticalTrackClickWithIndexPath:event:)
    @discardableResult
    public func fw_statisticalTrackClick(indexPath: IndexPath? = nil, event: StatisticalEvent? = nil) -> Bool {
        guard let event = event ?? fw_statisticalClick else { return false }
        StatisticalManager.shared.trackClick(self, indexPath: indexPath, event: event)
        return true
    }
    
    // MARK: - Private
    fileprivate var fw_trackClickCounts: [String: Int] {
        get { return fw_property(forName: "fw_trackClickCounts") as? [String: Int] ?? [:] }
        set { fw_setProperty(newValue, forName: "fw_trackClickCounts") }
    }
    
    private static var fw_staticStatisticalViewSwizzled = false
    
    fileprivate static func fw_swizzleStatisticalView() {
        guard !fw_staticStatisticalViewSwizzled else { return }
        fw_staticStatisticalViewSwizzled = true
        
        NSObject.fw_swizzleInstanceMethod(
            UITableViewCell.self,
            selector: #selector(UITableViewCell.didMoveToSuperview),
            methodSignature: (@convention(c) (UITableViewCell, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UITableViewCell) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.fw_statisticalClick != nil {
                selfObject.fw_statisticalBindClick()
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UICollectionViewCell.self,
            selector: #selector(UICollectionViewCell.didMoveToSuperview),
            methodSignature: (@convention(c) (UICollectionViewCell, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UICollectionViewCell) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.fw_statisticalClick != nil {
                selfObject.fw_statisticalBindClick()
            }
        }}
    }
    
}

// MARK: - UIView+StatisticalExposure
@_spi(FW) extension UIView {
    
    // MARK: - Public
    /// 设置并尝试自动绑定曝光事件统计。如果对象发生变化(indexPath|name|object)，也会触发
    public var fw_statisticalExposure: StatisticalEvent? {
        get {
            return fw_property(forName: "fw_statisticalExposure") as? StatisticalEvent
        }
        set {
            fw_setProperty(newValue, forName: "fw_statisticalExposure")
            fw_statisticalBindExposure(newValue?.bindView)
        }
    }
    
    /// 设置统计曝光事件触发时自定义监听器，默认nil
    public var fw_statisticalExposureListener: ((StatisticalEvent) -> Void)? {
        get { fw_property(forName: "fw_statisticalExposureListener") as? (StatisticalEvent) -> Void }
        set { fw_setPropertyCopy(newValue, forName: "fw_statisticalExposureListener") }
    }
    
    /// 手工绑定曝光事件统计，可指定绑定视图，自动绑定失败时可手工调用
    @discardableResult
    public func fw_statisticalBindExposure(_ bindView: UIView? = nil) -> Bool {
        guard !fw_propertyBool(forName: "fw_statisticalBindExposure") else { return true }
        let result = statisticalViewWillBindExposure(bindView)
        if result { fw_setPropertyBool(true, forName: "fw_statisticalBindExposure") }
        return result
    }
    
    /// 触发视图曝光事件统计，仅绑定statisticalExposure后生效
    @objc(__fw_statisticalTrackExposureWithIndexPath:duration:event:)
    @discardableResult
    public func fw_statisticalTrackExposure(indexPath: IndexPath? = nil, duration: TimeInterval = 0, event: StatisticalEvent? = nil) -> Bool {
        guard let event = event ?? fw_statisticalExposure else { return false }
        StatisticalManager.shared.trackExposure(self, indexPath: indexPath, duration: duration, event: event)
        return true
    }
    
    // MARK: - Private
    fileprivate var fw_trackExposureCounts: [String: Int] {
        get { return fw_property(forName: "fw_trackExposureCounts") as? [String: Int] ?? [:] }
        set { fw_setProperty(newValue, forName: "fw_trackExposureCounts") }
    }
    
    fileprivate var fw_trackExposureDurations: [String: TimeInterval] {
        get { return fw_property(forName: "fw_trackExposureDurations") as? [String: TimeInterval] ?? [:] }
        set { fw_setProperty(newValue, forName: "fw_trackExposureDurations") }
    }
    
}

// MARK: - UIViewController+StatisticalExposure
@_spi(FW) extension UIViewController {
    
    /// 设置并尝试自动绑定曝光事件统计
    public var fw_statisticalExposure: StatisticalEvent? {
        get {
            return fw_property(forName: "fw_statisticalExposure") as? StatisticalEvent
        }
        set {
            fw_setProperty(newValue, forName: "fw_statisticalExposure")
            fw_statisticalBindExposure()
        }
    }
    
    /// 设置统计曝光事件触发时自定义监听器，默认nil
    public var fw_statisticalExposureListener: ((StatisticalEvent) -> Void)? {
        get { fw_property(forName: "fw_statisticalExposureListener") as? (StatisticalEvent) -> Void }
        set { fw_setPropertyCopy(newValue, forName: "fw_statisticalExposureListener") }
    }
    
    /// 触发控制器曝光事件统计，仅绑定statisticalExposure后生效
    @discardableResult
    public func fw_statisticalTrackExposure(duration: TimeInterval = 0, event: StatisticalEvent? = nil) -> Bool {
        guard let event = event ?? fw_statisticalExposure else { return false }
        StatisticalManager.shared.trackExposure(self, duration: duration, event: event)
        return true
    }
    
    // MARK: - Private
    private func fw_statisticalBindExposure() {
        guard !fw_propertyBool(forName: "fw_statisticalBindExposure") else { return }
        // TODO: - TODO
        fw_setPropertyBool(true, forName: "fw_statisticalBindExposure")
    }
    
    fileprivate var fw_trackExposureCount: Int {
        get { return fw_propertyInt(forName: "fw_trackExposureCount") }
        set { fw_setPropertyInt(newValue, forName: "fw_trackExposureCount") }
    }
    
    fileprivate var fw_trackExposureDuration: TimeInterval {
        get { return fw_propertyDouble(forName: "fw_trackExposureDuration") }
        set { fw_setPropertyDouble(newValue, forName: "fw_trackExposureDuration") }
    }
    
}

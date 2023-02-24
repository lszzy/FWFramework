//
//  StatisticalView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - FWStatisticalManager
/// 统计通用block，参数object为FWStatisticalObject统计对象
public typealias FWStatisticalBlock = (FWStatisticalObject) -> Void

/// 事件统计管理器
///
/// 视图从不可见变为可见时曝光开始，触发曝光开始事件(triggerDuration为0)；
/// 视图从可见到不可见时曝光结束，视为一次曝光，触发曝光结束事件(triggerDuration大于0)并统计曝光时长。
/// 目前暂未实现曝光时长统计，仅触发开始事件用于统计次数，可自行处理时长统计，注意应用退后台时不计曝光时间。
/// 默认运行模式时，视图快速滚动不计算曝光，可配置runLoopMode快速滚动时也计算曝光
public class FWStatisticalManager: NSObject {
    
    /// TODO: 都需要监听退后台，when开关唯一的差别是是否触发曝光结束Event而已，不影响时间
    
    /// 单例模式
    public static let shared = FWStatisticalManager()
    
    /// 是否启用事件统计，为提高性能，默认false未开启，需手动开启
    public var statisticalEnabled = false {
        didSet {
            if statisticalEnabled {
                UIView.fw_swizzleUIViewStatistical()
            }
        }
    }

    /// 是否启用通知，默认false
    public var notificationEnabled = false
    
    /// 是否启用分析上报，默认false
    public var reportEnabled = false

    /// 设置运行模式，默认default快速滚动时不计算曝光
    public var runLoopMode: RunLoop.Mode = .default
    
    /// 设置部分可见时触发曝光的比率，范围0-1，默认1，仅视图完全可见时才触发曝光
    public var exposureThresholds: CGFloat = 1
    
    /// 是否统计曝光时长，开启后会触发曝光结束事件，默认true
    public var exposureDurationEnabled = true
    
    /// 计算曝光时是否自动屏蔽控制器的顶部栏和底部栏，默认true
    public var exposureIgnoredBar = true
    
    /// 从后台返回时是否重新计算曝光，默认true
    public var exposureAppState = true
    
    /// 从界面返回时是否重新计算曝光，默认true
    public var exposureWhenPopped = true
    
    /// 是否相同点击只触发一次，默认false，视图自定义后覆盖默认
    public var clickOnce = false
    
    /// 是否相同曝光只触发一次，默认false，视图自定义后覆盖默认
    public var exposureOnce = false

    /// 设置全局事件处理器
    public var globalHandler: FWStatisticalBlock?
    
    private var eventHandlers: [String: FWStatisticalBlock] = [:]

    /// 注册单个事件处理器
    public func registerEvent(_ name: String, handler: @escaping FWStatisticalBlock) {
        eventHandlers[name] = handler
    }

    /// 内部方法，处理事件
    fileprivate func handleEvent(_ object: FWStatisticalObject) {
        if let eventHandler = eventHandlers[object.name] {
            eventHandler(object)
        }
        globalHandler?(object)
        if reportEnabled, !object.name.isEmpty {
            Analyzer.shared.trackEvent(object.name, parameters: object.userInfo)
        }
        if notificationEnabled {
            NotificationCenter.default.post(name: .StatisticalEventTriggered, object: object, userInfo: object.userInfo)
        }
    }
    
}

// MARK: - FWStatisticalObject
/// 事件统计对象
/// TODO: 改名为Option？
public class FWStatisticalObject: NSObject {
    
    /// 事件绑定名称，未绑定时为空字符串
    public private(set) var name: String = ""
    /// 事件绑定对象，未绑定时为空
    public private(set) var object: Any?
    /// 事件绑定信息，未绑定时为空
    public private(set) var userInfo: [AnyHashable: Any]?

    /// 事件来源视图，触发时自动赋值
    public fileprivate(set) weak var view: UIView?
    /// 事件来源控制器，触发时自动赋值
    public fileprivate(set) weak var viewController: UIViewController?
    /// 事件来源位置，触发时自动赋值
    public fileprivate(set) var indexPath: IndexPath?
    /// 事件触发次数，触发时自动赋值
    public fileprivate(set) var triggerCount: Int = 0
    /// 事件触发单次时长，0表示曝光开始，仅曝光支持，触发时自动赋值
    public fileprivate(set) var triggerDuration: TimeInterval = 0
    /// 事件触发总时长，仅曝光支持，触发时自动赋值
    public fileprivate(set) var totalDuration: TimeInterval = 0
    /// 是否是曝光事件，默认false为点击事件
    public fileprivate(set) var isExposure = false
    /// 事件是否完成，注意曝光会触发两次，第一次为false曝光开始，第二次为true曝光结束
    public fileprivate(set) var isFinished = false
    
    /// TODO: 监听App Terminate时触发一次曝光
    public fileprivate(set) var isTerminated = false
    /// TODO: 退后台或关闭或离开界面时状态从fully变为none时触发结束并计算时间，这样可以不用计算退后台的时间
    /// 一定要监听background防止授权等弹窗触发曝光计算
    public fileprivate(set) var isBackground = false

    /// TODO: 如果指定了containerView，优化效率，只监听父视图和当前视图，未指定时是否同理
    /// 自定义容器视图，默认nil时获取VC视图或window
    public weak var containerView: UIView?
    /// 自定义容器视图句柄，默认nil时获取VC视图或window，参数为所在视图
    public var containerViewBlock: ((UIView) -> UIView?)?
    /// 自定义容器内边距，设置后忽略全局ignoredBar配置，默认nil
    public var containerInset: UIEdgeInsets?
    /// 是否事件仅触发一次，默认nil时采用全局配置
    public var triggerOnce: Bool?
    /// 是否忽略事件触发，默认false
    public var triggerIgnored = false
    /// 曝光遮挡视图，被遮挡时不计曝光
    public weak var shieldView: UIView?
    /// 曝光遮挡视图句柄，被遮挡时不计曝光，参数为所在视图
    public var shieldViewBlock: ((UIView) -> UIView?)?

    /// 创建事件绑定信息，指定名称、对象和信息
    public init(name: String = "", object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        super.init()
        self.name = name
        self.object = object
        self.userInfo = userInfo
    }
    
}

// MARK: - UIView+Statistical
@_spi(FW) extension UIView {
    
    private class StatisticalTarget: NSObject {
        private(set) weak var view: UIView?
        
        var exposureIsProxy = false
        var exposureIsFully = false
        var exposureIdentifier: String = ""
        var exposureState = StatisticalExposureState()
        private var exposureTotalCounts: [String: Int] = [:]
        private var exposureTotalDurations: [String: TimeInterval] = [:]
        
        init(view: UIView?) {
            super.init()
            self.view = view
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
        }
        
        func exposureRegister() {
            if FWStatisticalManager.shared.exposureAppState {
                NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
            }
        }
        
        func triggerExposure(_ cell: UIView?, indexPath: IndexPath?, duration: TimeInterval) {
            var object: FWStatisticalObject
            if let exposureObject = cell?.__fw_statisticalExposure ?? view?.__fw_statisticalExposure {
                object = exposureObject
            } else {
                object = FWStatisticalObject()
            }
            if object.triggerIgnored { return }
            let triggerCount = exposureTotalCount(indexPath)
            let triggerOnce = object.triggerOnce != nil ? (object.triggerOnce ?? false) : FWStatisticalManager.shared.exposureOnce
            if triggerCount > 1 && triggerOnce { return }
            let totalDuration = exposureTotalDuration(duration, indexPath: indexPath)
            
            object.view = view
            object.viewController = view?.fw_viewController
            object.indexPath = indexPath
            object.triggerCount = triggerCount
            object.triggerDuration = duration
            object.totalDuration = totalDuration
            object.isExposure = true
            object.isFinished = duration > 0
            
            if cell?.__fw_statisticalExposureBlock != nil {
                cell?.__fw_statisticalExposureBlock?(object)
            } else if view?.__fw_statisticalExposureBlock != nil {
                view?.__fw_statisticalExposureBlock?(object)
            }
            if cell?.__fw_statisticalExposure != nil || view?.__fw_statisticalExposure != nil {
                FWStatisticalManager.shared.handleEvent(object)
            }
        }
        
        private func exposureTotalCount(_ indexPath: IndexPath?) -> Int {
            let triggerKey = "\(indexPath?.section ?? -1).\(indexPath?.row ?? -1)"
            let triggerCount = (exposureTotalCounts[triggerKey] ?? 0) + 1
            exposureTotalCounts[triggerKey] = triggerCount
            return triggerCount
        }
        
        private func exposureTotalDuration(_ duration: TimeInterval, indexPath: IndexPath?) -> TimeInterval {
            let triggerKey = "\(indexPath?.section ?? -1).\(indexPath?.row ?? -1)"
            let triggerDuration = (exposureTotalDurations[triggerKey] ?? 0) + duration
            exposureTotalDurations[triggerKey] = triggerDuration
            return triggerDuration
        }
        
        func exposureViewIdentifier() -> String {
            var indexPath: IndexPath?
            if let cell = view as? UITableViewCell {
                indexPath = cell.fw_indexPath
            } else if let cell = view as? UICollectionViewCell {
                indexPath = cell.fw_indexPath
            }
            
            let identifier = "\(indexPath?.section ?? -1)-\(indexPath?.row ?? -1)-\(view?.__fw_statisticalExposure?.name ?? "")-\(String.fw_safeString(view?.__fw_statisticalExposure?.object))"
            return identifier
        }
        
        static func exposureIsFullyState(_ state: StatisticalExposureState) -> Bool {
            var isFullState = (state.state == .fully) ? true : false
            if !isFullState && state.state == .partly {
                isFullState = state.ratio >= FWStatisticalManager.shared.exposureThresholds
            }
            return isFullState
        }
        
        static func exposureIsValidRect(_ rect: CGRect) -> Bool {
            let isNan = rect.origin.x.isNaN || rect.origin.y.isNaN || rect.size.width.isNaN || rect.size.height.isNaN
            let isInf = rect.origin.x.isInfinite || rect.origin.y.isInfinite || rect.size.width.isInfinite || rect.size.height.isInfinite
            return !rect.isNull && !rect.isInfinite && !isNan && !isInf
        }
        
        @objc func appEnterBackground() {
            // TODO: 标记并更新
            self.view?.__fw_statisticalExposureUpdate()
        }
        
        @objc func appEnterForeground() {
            // TODO: 标记并更新
            self.view?.__fw_statisticalExposureUpdate()
        }
        
        @objc func appWillTerminate() {
            // TODO: 标记并更新
            self.view?.__fw_statisticalExposureUpdate()
        }
        
        @objc func exposureCalculate() {
            if let view = self.view, (view is UITableView || view is UICollectionView) {
                for subview in view.subviews {
                    subview.fw_updateStatisticalExposureState()
                }
            } else {
                self.view?.fw_updateStatisticalExposureState()
            }
        }
    }
    
    private struct StatisticalExposureState {
        enum State: Int {
            case none = 0
            case partly
            case fully
        }
        
        var ratio: CGFloat = .zero
        var viewportRect: CGRect = .zero
        var intersectionRect: CGRect = .zero
        var shieldIntersectionRect: CGRect = .zero
        
        var state: State {
            if ratio >= 1.0 {
                return .fully
            } else if ratio > 0 {
                return .partly
            } else {
                return .none
            }
        }
    }
    
    /// 绑定统计曝光事件，触发管理器。如果对象发生变化(indexPath|name|object)，也会触发
    fileprivate var __fw_statisticalExposure: FWStatisticalObject? {
        get {
            return fw_property(forName: "__fw_statisticalExposure") as? FWStatisticalObject
        }
        set {
            fw_setProperty(newValue, forName: "__fw_statisticalExposure")
            self.__fw_statisticalExposureRegister()
        }
    }

    /// 绑定统计曝光事件，仅触发回调
    public var __fw_statisticalExposureBlock: FWStatisticalBlock? {
        get {
            return fw_property(forName: "__fw_statisticalExposureBlock") as? FWStatisticalBlock
        }
        set {
            fw_setPropertyCopy(newValue, forName: "__fw_statisticalExposureBlock")
            self.__fw_statisticalExposureRegister()
        }
    }

    /// 手工触发统计曝光事件，更新曝光次数和时长，列表可指定cell和位置，duration为单次曝光时长(0表示开始)，可重复触发
    public func fw_statisticalTriggerExposure(_ cell: UIView?, indexPath: IndexPath?, duration: TimeInterval = 0) {
        fw_statisticalTarget.triggerExposure(cell, indexPath: indexPath, duration: duration)
    }
    
    private static var fw_staticStatisticalSwizzled = false
    
    fileprivate static func fw_swizzleUIViewStatistical() {
        guard !fw_staticStatisticalSwizzled else { return }
        fw_staticStatisticalSwizzled = true
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(setter: UIView.frame),
            methodSignature: (@convention(c) (UIView, Selector, CGRect) -> Void).self,
            swizzleSignature: (@convention(block) (UIView, CGRect) -> Void).self
        ) { store in { selfObject, frame in
            store.original(selfObject, store.selector, frame)
            selfObject.__fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(setter: UIView.isHidden),
            methodSignature: (@convention(c) (UIView, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIView, Bool) -> Void).self
        ) { store in { selfObject, hidden in
            store.original(selfObject, store.selector, hidden)
            selfObject.__fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(setter: UIView.alpha),
            methodSignature: (@convention(c) (UIView, Selector, CGFloat) -> Void).self,
            swizzleSignature: (@convention(block) (UIView, CGFloat) -> Void).self
        ) { store in { selfObject, alpha in
            store.original(selfObject, store.selector, alpha)
            selfObject.__fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(setter: UIView.bounds),
            methodSignature: (@convention(c) (UIView, Selector, CGRect) -> Void).self,
            swizzleSignature: (@convention(block) (UIView, CGRect) -> Void).self
        ) { store in { selfObject, bounds in
            store.original(selfObject, store.selector, bounds)
            selfObject.__fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.didMoveToWindow),
            methodSignature: (@convention(c) (UIView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            selfObject.__fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UITableView.self,
            selector: #selector(UITableView.reloadData),
            methodSignature: (@convention(c) (UITableView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UITableView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            selfObject.__fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UICollectionView.self,
            selector: #selector(UICollectionView.reloadData),
            methodSignature: (@convention(c) (UICollectionView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UICollectionView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            selfObject.__fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UITableViewCell.self,
            selector: #selector(UITableViewCell.didMoveToSuperview),
            methodSignature: (@convention(c) (UITableViewCell, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UITableViewCell) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.__fw_statisticalExposure != nil || selfObject.__fw_statisticalExposureBlock != nil {
                selfObject.__fw_statisticalExposureCellRegister()
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UICollectionViewCell.self,
            selector: #selector(UICollectionViewCell.didMoveToSuperview),
            methodSignature: (@convention(c) (UICollectionViewCell, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UICollectionViewCell) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.__fw_statisticalExposure != nil || selfObject.__fw_statisticalExposureBlock != nil {
                selfObject.__fw_statisticalExposureCellRegister()
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidAppear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)
            selfObject.__fw_statisticalExposureDidAppear()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidDisappear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)
            selfObject.__fw_statisticalExposureDidDisappear()
        }}
    }
    
    private var __fw_statisticalExposureEnabled: Bool {
        get { return fw_propertyBool(forName: "__fw_statisticalExposureEnabled") }
        set { fw_setPropertyBool(newValue, forName: "__fw_statisticalExposureEnabled") }
    }
    
    @discardableResult
    private func __fw_statisticalExposureCustom() -> Bool {
        if (self as? StatisticalDelegate)?.statisticalExposure?(callback: { [weak self] cell, indexPath, duration in
            guard let this = self else { return }
            if StatisticalTarget.exposureIsFullyState(this.__fw_statisticalExposureViewState()) {
                this.fw_statisticalTriggerExposure(cell, indexPath: indexPath, duration: duration)
            }
        }) != nil {
            return true
        }
        return false
    }
    
    /// TODO: 支持曝光状态监听，变化时触发block，类似vc.fw_state监听机制，这样可以移除exposureBlock，从而支持多个block的效果
    
    private func __fw_statisticalExposureViewState() -> StatisticalExposureState {
        var state = StatisticalExposureState()
        if !self.fw_isViewVisible {
            return state
        }
        
        if FWStatisticalManager.shared.exposureAppState {
            if UIApplication.shared.applicationState == .background {
                return state
            }
        }
        
        let viewController = self.fw_viewController
        if let viewController = viewController {
            if !viewController.fw_isViewVisible { return state }
            if viewController.presentedViewController != nil { return state }
            if FWStatisticalManager.shared.exposureWhenPopped && !viewController.fw_isTail {
                return state
            }
        }
        
        var containerView = self.__fw_statisticalExposure?.containerView ?? self.__fw_statisticalExposure?.containerViewBlock?(self)
        if let containerView = containerView {
            if !containerView.fw_isViewVisible {
                return state
            }
        } else {
            containerView = viewController?.view ?? self.window
        }
        guard let containerView = containerView else {
            return state
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
            return state
        }
        
        state = __fw_statisticalExposureCalculateRatio(containerView: containerView, viewController: viewController)
        return state
    }
    
    private func __fw_statisticalExposureCalculateRatio(containerView: UIView, viewController: UIViewController?) -> StatisticalExposureState {
        var ratio = StatisticalExposureState()
        var viewRect = self.convert(self.bounds, to: containerView)
        viewRect = CGRect(x: floor(viewRect.origin.x), y: floor(viewRect.origin.y), width: floor(viewRect.size.width), height: floor(viewRect.size.height))
        
        var tx = CGRectGetMinX(viewRect) - floor(containerView.bounds.origin.x)
        var ty = CGRectGetMinY(viewRect) - floor(containerView.bounds.origin.y)
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
        if let containerInset = self.__fw_statisticalExposure?.containerInset {
            containerRect = containerRect.inset(by: containerInset)
        } else if FWStatisticalManager.shared.exposureIgnoredBar, let viewController = viewController {
            containerRect = containerRect.inset(by: UIEdgeInsets(top: viewController.fw_topBarHeight, left: 0, bottom: viewController.fw_bottomBarHeight, right: 0))
        }
        
        if !StatisticalTarget.exposureIsValidRect(viewportRect) {
            return ratio
        }
        let viewSize = CGRectGetWidth(viewRect) * CGRectGetHeight(viewRect)
        if viewSize <= 0 {
            return ratio
        }
        if !StatisticalTarget.exposureIsValidRect(containerRect) {
            return ratio
        }
        
        var intersectionRect = CGRectIntersection(containerRect, viewportRect)
        if !StatisticalTarget.exposureIsValidRect(intersectionRect) {
            intersectionRect = .zero
        }
        let intersectionSize = CGRectGetWidth(intersectionRect) * CGRectGetHeight(intersectionRect)
        ratio.ratio = intersectionSize > 0 ? ceil(intersectionSize / viewSize * 100.0) / 100.0 : 0
        ratio.viewportRect = viewportRect
        ratio.intersectionRect = intersectionRect
        if ratio.ratio <= 0 {
            return ratio
        }
        
        let shieldView = self.__fw_statisticalExposure?.shieldView ?? self.__fw_statisticalExposure?.shieldViewBlock?(self)
        guard let shieldView = shieldView, shieldView.fw_isViewVisible else {
            return ratio
        }
        let shieldRect = shieldView.convert(shieldView.bounds, to: containerView)
        if !CGRectIsEmpty(shieldRect) && !CGRectIsEmpty(intersectionRect) {
            if CGRectContainsRect(shieldRect, intersectionRect) {
                ratio.ratio = 0
                ratio.viewportRect = .zero
                ratio.intersectionRect = .zero
                return ratio
            } else if CGRectIntersectsRect(shieldRect, intersectionRect) {
                var shieldIntersectionRect = CGRectIntersection(shieldRect, intersectionRect)
                if !StatisticalTarget.exposureIsValidRect(shieldIntersectionRect) {
                    shieldIntersectionRect = .zero
                }
                let shieldIntersectionSize = CGRectGetWidth(shieldIntersectionRect) * CGRectGetHeight(shieldIntersectionRect)
                let shieldRatio = shieldIntersectionSize > 0 ? ceil(shieldIntersectionSize / intersectionSize * 100.0) / 100.0 : 0
                ratio.ratio = ceil(ratio.ratio * (1.0 - shieldRatio) * 100.0) / 100.0
                ratio.shieldIntersectionRect = shieldIntersectionRect
                return ratio
            }
        }
        return ratio
    }
    
    private func fw_updateStatisticalExposureState() {
        let oldIdentifier = self.fw_statisticalTarget.exposureIdentifier
        let identifier = self.fw_statisticalTarget.exposureViewIdentifier()
        let identifierChanged = oldIdentifier.count > 0 && identifier != oldIdentifier
        if oldIdentifier.count < 1 || identifierChanged {
            self.fw_statisticalTarget.exposureIdentifier = identifier
            if oldIdentifier.count < 1 { self.__fw_statisticalExposureCustom() }
        }
        
        let oldState = self.fw_statisticalTarget.exposureState
        let state = self.__fw_statisticalExposureViewState()
        if state.state == oldState.state && !identifierChanged { return }
        self.fw_statisticalTarget.exposureState = state
        
        if StatisticalTarget.exposureIsFullyState(state),
           (!self.fw_statisticalTarget.exposureIsFully || identifierChanged) {
            self.fw_statisticalTarget.exposureIsFully = true
            if self.__fw_statisticalExposureCustom() {
            } else if let cell = self as? UITableViewCell {
                cell.fw_tableView?.fw_statisticalTriggerExposure(self, indexPath: cell.fw_indexPath, duration: 0)
            } else if let cell = self as? UICollectionViewCell {
                cell.fw_collectionView?.fw_statisticalTriggerExposure(self, indexPath: cell.fw_indexPath, duration: 0)
            } else {
                self.fw_statisticalTriggerExposure(nil, indexPath: nil, duration: 0)
            }
        } else if state.state == .none || identifierChanged {
            self.fw_statisticalTarget.exposureIsFully = false
            
            // TODO: 触发曝光结束计算时间并调用triggerExposure，需要更新是否是后台和是否关闭属性等
        }
    }
    
    private func __fw_statisticalExposureRegister() {
        if self.__fw_statisticalExposureEnabled { return }
        self.__fw_statisticalExposureEnabled = true
        if self is UITableViewCell || self is UICollectionViewCell {
            self.__fw_statisticalExposureCellRegister()
            return
        }
        
        if self.superview != nil {
            self.superview?.__fw_statisticalExposureRegister()
        }
        
        if self.__fw_statisticalExposure != nil ||
            self.__fw_statisticalExposureBlock != nil ||
            self.fw_statisticalTarget.exposureIsProxy {
            self.fw_statisticalTarget.exposureRegister()
            
            NSObject.cancelPreviousPerformRequests(withTarget: self.fw_statisticalTarget, selector: #selector(StatisticalTarget.exposureCalculate), object: nil)
            self.fw_statisticalTarget.perform(#selector(StatisticalTarget.exposureCalculate), with: nil, afterDelay: 0, inModes: [FWStatisticalManager.shared.runLoopMode])
        }
    }
    
    private func __fw_statisticalExposureCellRegister() {
        if self.superview == nil { return }
        var proxyView: UIView?
        if self.conforms(to: StatisticalDelegate.self),
           self.responds(to: #selector(StatisticalDelegate.statisticalCellProxyView)) {
            proxyView = (self as? StatisticalDelegate)?.statisticalCellProxyView?()
        } else {
            if let cell = self as? UITableViewCell {
                proxyView = cell.fw_tableView
            } else if let cell = self as? UICollectionViewCell {
                proxyView = cell.fw_collectionView
            }
        }
        proxyView?.fw_statisticalTarget.exposureIsProxy = true
        proxyView?.__fw_statisticalExposureRegister()
    }
    
    private func __fw_statisticalExposureUpdate() {
        if !self.__fw_statisticalExposureEnabled { return }
        
        self.__fw_statisticalExposureRecursive()
    }
    
    private func __fw_statisticalExposureRecursive() {
        if !self.__fw_statisticalExposureEnabled { return }
        
        if self.__fw_statisticalExposure != nil ||
            self.__fw_statisticalExposureBlock != nil ||
            self.fw_statisticalTarget.exposureIsProxy {
            NSObject.cancelPreviousPerformRequests(withTarget: self.fw_statisticalTarget, selector: #selector(StatisticalTarget.exposureCalculate), object: nil)
            self.fw_statisticalTarget.perform(#selector(StatisticalTarget.exposureCalculate), with: nil, afterDelay: 0, inModes: [FWStatisticalManager.shared.runLoopMode])
        }
        
        for subview in self.subviews {
            subview.__fw_statisticalExposureRecursive()
        }
    }
    
    private var fw_statisticalTarget: StatisticalTarget {
        if let target = fw_property(forName: "fw_statisticalTarget") as? StatisticalTarget {
            return target
        } else {
            let target = StatisticalTarget(view: self)
            fw_setProperty(target, forName: "fw_statisticalTarget")
            return target
        }
    }
    
}

// MARK: - UIViewController+Statistical
/// TODO: 退后台、关闭时自动触发结束，重构下，这样不用计算时间
@_spi(FW) extension UIViewController {
    
    private class StatisticalTarget: NSObject {
        var exposure: FWStatisticalObject?
        var exposureBlock: FWStatisticalBlock?
        var exposureTimestamp: TimeInterval = 0
        var exposureDuration: TimeInterval = 0
        var exposureTotalCount: Int = 0
        var exposureTotalDuration: TimeInterval = 0
        
        private(set) weak var viewController: UIViewController?
        
        init(viewController: UIViewController?) {
            super.init()
            self.viewController = viewController
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        }
        
        func exposureRegister() {
            NotificationCenter.default.addObserver(self, selector: #selector(appResignActive), name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(appBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            
            // TODO: 注册时检查是否要触发一次
            // TODO: 还需监听关闭
        }
        
        @objc func appResignActive() {
            let beginTime = exposureTimestamp
            if beginTime > 0 {
                exposureTimestamp = 0
                exposureDuration += Date().timeIntervalSince1970 - beginTime
            }
        }
        
        @objc func appBecomeActive() {
            exposureTimestamp = Date().timeIntervalSince1970
        }
        
        func viewDidAppear() {
            // 忽略侧滑返回手势取消触发viewDidAppear的情况
            if exposureDuration > 0 { return }
            
            exposureTimestamp = Date().timeIntervalSince1970
            exposureDuration = 0
            triggerExposure(duration: 0)
        }
        
        func viewDidDisappear() {
            var duration = exposureDuration
            let beginTime = exposureTimestamp
            if beginTime > 0 {
                duration += Date().timeIntervalSince1970 - beginTime
            }
            exposureTimestamp = 0
            exposureDuration = 0
            triggerExposure(duration: duration)
        }
        
        func triggerExposure(duration: TimeInterval) {
            var object: FWStatisticalObject
            if let exposureObject = exposure {
                object = exposureObject
            } else {
                object = FWStatisticalObject()
            }
            if object.triggerIgnored { return }
            exposureTotalCount += 1
            let triggerOnce = object.triggerOnce != nil ? (object.triggerOnce ?? false) : FWStatisticalManager.shared.exposureOnce
            if exposureTotalCount > 1 && triggerOnce { return }
            exposureTotalDuration += duration
            
            object.viewController = viewController
            object.triggerCount = exposureTotalCount
            object.triggerDuration = duration
            object.totalDuration = exposureTotalDuration
            object.isExposure = true
            object.isFinished = duration > 0
            
            if exposureBlock != nil {
                exposureBlock?(object)
            }
            if exposure != nil {
                FWStatisticalManager.shared.handleEvent(object)
            }
        }
    }
    
    /// 绑定统计曝光事件，触发管理器
    fileprivate var __fw_statisticalExposure: FWStatisticalObject? {
        get { return fw_statisticalTarget.exposure }
        set {
            fw_statisticalTarget.exposure = newValue
            if !__fw_statisticalExposureEnabled {
                __fw_statisticalExposureEnabled = true
                fw_statisticalTarget.exposureRegister()
            }
        }
    }

    /// 绑定统计曝光事件，仅触发回调
    public var __fw_statisticalExposureBlock: FWStatisticalBlock? {
        get { return fw_statisticalTarget.exposureBlock }
        set {
            fw_statisticalTarget.exposureBlock = newValue
            if !__fw_statisticalExposureEnabled {
                __fw_statisticalExposureEnabled = true
                fw_statisticalTarget.exposureRegister()
            }
        }
    }

    /// 手工触发统计曝光事件，更新曝光次数和时长，duration为单次曝光时长(0表示开始)，可重复触发
    public func fw_statisticalTriggerExposure(duration: TimeInterval = 0) {
        fw_statisticalTarget.triggerExposure(duration: duration)
    }
    
    fileprivate func __fw_statisticalExposureDidAppear() {
        if !self.__fw_statisticalExposureEnabled { return }
        fw_statisticalTarget.viewDidAppear()
    }
    
    fileprivate func __fw_statisticalExposureDidDisappear() {
        if !self.__fw_statisticalExposureEnabled { return }
        fw_statisticalTarget.viewDidDisappear()
    }
    
    private var __fw_statisticalExposureEnabled: Bool {
        get { return fw_propertyBool(forName: "__fw_statisticalExposureEnabled") }
        set { fw_setPropertyBool(newValue, forName: "__fw_statisticalExposureEnabled") }
    }
    
    private var fw_statisticalTarget: StatisticalTarget {
        if let target = fw_property(forName: "fw_statisticalTarget") as? StatisticalTarget {
            return target
        } else {
            let target = StatisticalTarget(viewController: self)
            fw_setProperty(target, forName: "fw_statisticalTarget")
            return target
        }
    }
    
}

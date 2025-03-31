//
//  StatisticalView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - Wrapper+UIView
@MainActor extension Wrapper where Base: UIView {
    // MARK: - Click
    /// 设置并尝试自动绑定点击事件统计
    public var statisticalClick: StatisticalEvent? {
        get {
            property(forName: "statisticalClick") as? StatisticalEvent
        }
        set {
            setProperty(newValue, forName: "statisticalClick")
            StatisticalManager.swizzleStatisticalView()
            statisticalBindClick(newValue?.containerView)
        }
    }

    /// 设置统计点击事件触发时自定义监听器，默认nil
    public var statisticalClickListener: ((StatisticalEvent) -> Void)? {
        get { property(forName: "statisticalClickListener") as? (StatisticalEvent) -> Void }
        set { setPropertyCopy(newValue, forName: "statisticalClickListener") }
    }

    /// 手工绑定点击事件统计，可指定容器视图，自动绑定失败时可手工调用
    @discardableResult
    public func statisticalBindClick(_ containerView: UIView? = nil) -> Bool {
        guard !propertyBool(forName: "statisticalBindClick") else { return true }
        let result = base.statisticalViewWillBindClick(containerView)
        if result { setPropertyBool(true, forName: "statisticalBindClick") }
        return result
    }

    /// 触发视图点击事件统计，仅绑定statisticalClick后生效
    @discardableResult
    public func statisticalTrackClick(indexPath: IndexPath? = nil, event: StatisticalEvent? = nil) -> Bool {
        guard let event = event ?? statisticalClick else { return false }
        StatisticalManager.shared.trackClick(base, indexPath: indexPath, event: event)
        return true
    }

    // MARK: - Exposure
    /// 设置并尝试自动绑定曝光事件统计。如果对象发生变化(indexPath|name|object)，也会触发
    public var statisticalExposure: StatisticalEvent? {
        get {
            property(forName: "statisticalExposure") as? StatisticalEvent
        }
        set {
            let oldValue = statisticalExposure
            setProperty(newValue, forName: "statisticalExposure")
            StatisticalManager.swizzleStatisticalView()
            statisticalBindExposure(newValue?.containerView)
            if oldValue != nil, newValue == nil {
                statisticalRemoveObservers()
            }
        }
    }

    /// 设置统计曝光事件触发时自定义监听器，默认nil
    public var statisticalExposureListener: ((StatisticalEvent) -> Void)? {
        get { property(forName: "statisticalExposureListener") as? (StatisticalEvent) -> Void }
        set { setPropertyCopy(newValue, forName: "statisticalExposureListener") }
    }

    /// 手工绑定曝光事件统计，可指定容器视图，自动绑定失败时可手工调用
    @discardableResult
    public func statisticalBindExposure(_ containerView: UIView? = nil) -> Bool {
        var result = propertyBool(forName: "statisticalBindExposure")
        if !result {
            result = base.statisticalViewWillBindExposure(containerView)
            if result {
                setPropertyBool(true, forName: "statisticalBindExposure")
                statisticalAddObservers()
            }
        }
        guard result else { return false }

        if (statisticalExposure != nil && base.window != nil) ||
            StatisticalManager.shared.exposureTime {
            statisticalCheckExposure()
        }
        return result
    }

    /// 触发视图曝光事件统计，仅绑定statisticalExposure后生效
    @discardableResult
    public func statisticalTrackExposure(indexPath: IndexPath? = nil, isFinished: Bool = false, event: StatisticalEvent? = nil) -> Bool {
        guard let event = event ?? statisticalExposure else { return false }
        StatisticalManager.shared.trackExposure(base, indexPath: indexPath, isFinished: isFinished, event: event)
        return true
    }

    /// 检查并更新视图曝光状态，用于自定义场景
    public func statisticalCheckExposure() {
        guard propertyBool(forName: "statisticalBindExposure") else { return }

        if statisticalExposure != nil {
            NSObject.cancelPreviousPerformRequests(withTarget: statisticalTarget, selector: #selector(StatisticalTarget.exposureUpdate), object: nil)
            statisticalTarget.perform(#selector(StatisticalTarget.exposureUpdate), with: nil, afterDelay: 0, inModes: [StatisticalManager.shared.runLoopMode])
        }

        if base.statisticalViewVisibleIndexPaths() == nil {
            let childViews = base.statisticalViewChildViews() ?? base.subviews
            for childView in childViews {
                childView.fw.statisticalCheckExposure()
            }
        }
    }

    // MARK: - Private
    fileprivate var statisticalTarget: StatisticalTarget {
        if let target = property(forName: "statisticalTarget") as? StatisticalTarget {
            return target
        } else {
            let target = StatisticalTarget()
            target.view = base
            setProperty(target, forName: "statisticalTarget")
            return target
        }
    }

    fileprivate func statisticalAddObservers() {
        guard propertyBool(forName: "statisticalBindExposure") else { return }
        statisticalTarget.addObservers()
    }

    fileprivate func statisticalRemoveObservers() {
        guard propertyBool(forName: "statisticalBindExposure") else { return }
        statisticalTarget.removeObservers()
    }

    fileprivate func statisticalCheckState() {
        var isVisibleCells = false
        var indexPaths: [IndexPath] = []
        var indexPath: IndexPath?
        var event = statisticalExposure
        var identifier = ""
        if let visibleIndexPaths = base.statisticalViewVisibleIndexPaths() {
            isVisibleCells = true
            indexPaths = visibleIndexPaths.sorted(by: { ip1, ip2 in
                ip1.section < ip2.section || ip1.row < ip2.row
            })
            identifier = StatisticalManager.statisticalIdentifier(event: event, indexPaths: indexPaths)
        } else {
            indexPath = base.statisticalViewIndexPath()
            event = event ?? base.statisticalViewContainerView()?.fw.statisticalExposure
            identifier = StatisticalManager.statisticalIdentifier(event: event, indexPath: indexPath)
        }
        let oldIdentifier = statisticalTarget.exposureIdentifier
        let identifierChanged = !oldIdentifier.isEmpty && identifier != oldIdentifier
        if oldIdentifier.isEmpty || identifierChanged {
            statisticalTarget.exposureIdentifier = identifier
        }

        let oldState = statisticalTarget.exposureState
        let state = statisticalExposureState
        if state.isState(oldState), !identifierChanged { return }
        statisticalTarget.exposureState = state

        var isBegin = false
        var isFinished = false
        if state.isFully, !statisticalTarget.exposureFully || identifierChanged {
            statisticalTarget.exposureFully = true
            isFinished = true
            isBegin = true
        } else if state == .none || identifierChanged {
            statisticalTarget.exposureFully = false
            isFinished = true
        }

        if isVisibleCells {
            var finishExposures = statisticalTarget.exposureBegins
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
                        statisticalTrackExposure(indexPath: finishExposure.indexPath, isFinished: true, event: finishExposure)
                    }
                } else {
                    for (finishKey, _) in finishExposures {
                        statisticalTarget.exposureBegins.removeValue(forKey: finishKey)
                        statisticalTarget.exposureTimestamps.removeValue(forKey: finishKey)
                    }
                }
            }

            if isBegin, !beginExposures.isEmpty {
                for indexPath in beginExposures {
                    statisticalTrackExposure(indexPath: indexPath, event: event)
                }
            }
        } else {
            if isFinished, let finishExposure = statisticalTarget.exposureBegin {
                if StatisticalManager.shared.exposureTime {
                    statisticalTrackExposure(indexPath: finishExposure.indexPath, isFinished: true, event: finishExposure)
                } else {
                    statisticalTarget.exposureBegin = nil
                    statisticalTarget.exposureTimestamp = 0
                }
            }

            if isBegin {
                statisticalTrackExposure(indexPath: indexPath, event: event)
            }
        }
    }

    fileprivate var statisticalExposureState: StatisticalState {
        if !isViewVisible {
            return .none
        }

        if let exposureBlock = statisticalExposure?.exposureBlock,
           !exposureBlock(base) {
            return .none
        }

        if StatisticalManager.shared.exposureBecomeActive ||
            StatisticalManager.shared.exposureTime {
            if UIApplication.shared.applicationState == .background {
                return .none
            }
            if StatisticalManager.shared.exposureTime,
               statisticalTarget.exposureTerminated {
                return .none
            }
        }

        let viewController = viewController
        if let viewController,
           !viewController.fw.isVisible {
            return .none
        }

        var containerView = statisticalExposure?.containerView
        if let containerView {
            if !containerView.fw.isViewVisible {
                return .none
            }
        } else {
            containerView = viewController?.view ?? base.window
        }
        guard let containerView else {
            return .none
        }

        var superview = base.superview
        var superviewHidden = false
        while superview != nil && superview != containerView {
            if !(superview?.fw.isViewVisible ?? false) {
                superviewHidden = true
                break
            }
            superview = superview?.superview
        }
        if superviewHidden {
            return .none
        }

        let ratio = statisticalExposureRatio(containerView, viewController: viewController)
        if ratio >= 1.0 {
            return .fully
        } else if ratio > 0 {
            return .partly(ratio)
        }
        return .none
    }

    fileprivate func statisticalExposureRatio(_ containerView: UIView, viewController: UIViewController?) -> CGFloat {
        var ratio: CGFloat = 0
        var viewRect = base.convert(base.bounds, to: containerView)
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
        if let containerInset = statisticalExposure?.containerInset {
            containerRect = containerRect.inset(by: containerInset)
        } else if StatisticalManager.shared.exposureIgnoredBars, let viewController {
            containerRect = containerRect.inset(by: UIEdgeInsets(top: viewController.fw.topBarHeight, left: 0, bottom: viewController.fw.bottomBarHeight, right: 0))
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

        let shieldView = statisticalExposure?.shieldView?(base)
        guard let shieldView, shieldView.fw.isViewVisible else {
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

// MARK: - Wrapper+UIViewController
@MainActor extension Wrapper where Base: UIViewController {
    /// 设置并尝试自动绑定曝光事件统计
    public var statisticalExposure: StatisticalEvent? {
        get {
            property(forName: "statisticalExposure") as? StatisticalEvent
        }
        set {
            let oldValue = statisticalExposure
            setProperty(newValue, forName: "statisticalExposure")
            statisticalBindExposure()
            if oldValue != nil, newValue == nil {
                statisticalTarget.removeObservers()
            }
        }
    }

    /// 设置统计曝光事件触发时自定义监听器，默认nil
    public var statisticalExposureListener: ((StatisticalEvent) -> Void)? {
        get { property(forName: "statisticalExposureListener") as? (StatisticalEvent) -> Void }
        set { setPropertyCopy(newValue, forName: "statisticalExposureListener") }
    }

    /// 触发控制器曝光事件统计，仅绑定statisticalExposure后生效
    @discardableResult
    public func statisticalTrackExposure(isFinished: Bool = false, event: StatisticalEvent? = nil) -> Bool {
        guard let event = event ?? statisticalExposure else { return false }
        StatisticalManager.shared.trackExposure(base, isFinished: isFinished, event: event)
        return true
    }

    /// 检查并更新控制器曝光状态，用于自定义场景
    public func statisticalCheckExposure() {
        guard propertyBool(forName: "statisticalBindExposure") else { return }

        let identifier = StatisticalManager.statisticalIdentifier(event: statisticalExposure)
        let oldIdentifier = statisticalTarget.exposureIdentifier
        let identifierChanged = !oldIdentifier.isEmpty && identifier != oldIdentifier
        if oldIdentifier.isEmpty || identifierChanged {
            statisticalTarget.exposureIdentifier = identifier
        }

        let oldState = statisticalTarget.exposureState
        let state = statisticalExposureState
        if state.isState(oldState), !identifierChanged { return }
        statisticalTarget.exposureState = state

        var isBegin = false
        var isFinished = false
        if state.isFully, !statisticalTarget.exposureFully || identifierChanged {
            statisticalTarget.exposureFully = true
            isFinished = true
            isBegin = true
        } else if state == .none || identifierChanged {
            statisticalTarget.exposureFully = false
            isFinished = true
        }

        if isFinished, let finishExposure = statisticalTarget.exposureBegin {
            if StatisticalManager.shared.exposureTime {
                statisticalTrackExposure(isFinished: true, event: finishExposure)
            } else {
                statisticalTarget.exposureBegin = nil
                statisticalTarget.exposureTimestamp = 0
            }
        }

        if isBegin {
            statisticalTrackExposure()
        }
    }

    // MARK: - Private
    fileprivate var statisticalTarget: StatisticalControllerTarget {
        if let target = property(forName: "statisticalTarget") as? StatisticalControllerTarget {
            return target
        } else {
            let target = StatisticalControllerTarget()
            target.viewController = base
            setProperty(target, forName: "statisticalTarget")
            return target
        }
    }

    fileprivate func statisticalBindExposure() {
        if !propertyBool(forName: "statisticalBindExposure") {
            setPropertyBool(true, forName: "statisticalBindExposure")
            statisticalTarget.addObservers()
        }

        if statisticalExposure != nil ||
            StatisticalManager.shared.exposureTime {
            statisticalCheckExposure()
        }
    }

    fileprivate var statisticalExposureState: StatisticalState {
        if !isVisible {
            return .none
        }

        if let exposureBlock = statisticalExposure?.exposureBlock,
           !exposureBlock(base) {
            return .none
        }

        if StatisticalManager.shared.exposureBecomeActive ||
            StatisticalManager.shared.exposureTime {
            if UIApplication.shared.applicationState == .background {
                return .none
            }
            if StatisticalManager.shared.exposureTime,
               statisticalTarget.exposureTerminated {
                return .none
            }
        }

        return .fully
    }
}

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
public class StatisticalManager: NSObject, @unchecked Sendable {
    // MARK: - Accessor
    /// 单例模式
    public static let shared = StatisticalManager()

    /// 是否启用通知，默认false
    public var notificationEnabled = false
    /// 是否启用分析上报，默认false
    public var reportEnabled = false
    /// 设置全局事件过滤器
    public var eventFilter: (@MainActor @Sendable (StatisticalEvent) -> Bool)?
    /// 设置全局事件处理器
    public var eventHandler: (@MainActor @Sendable (StatisticalEvent) -> Void)?

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

    private var eventHandlers: [String: @MainActor @Sendable (StatisticalEvent) -> Void] = [:]

    // MARK: - Public
    /// 注册单个事件处理器
    public func registerEvent(_ name: String, handler: @escaping @MainActor @Sendable (StatisticalEvent) -> Void) {
        eventHandlers[name] = handler
    }

    /// 手工触发点击统计，如果为cell需指定indexPath，点击触发时调用
    @MainActor public func trackClick(_ view: UIView?, indexPath: IndexPath? = nil, event: StatisticalEvent) {
        if event.triggerIgnored { return }
        if let eventFilter, !eventFilter(event) { return }

        let triggerKey = StatisticalManager.statisticalIdentifier(event: event, indexPath: indexPath)
        let triggerCount = (view?.fw.statisticalTarget.clickCounts[triggerKey] ?? 0) + 1
        let triggerOnce = event.triggerOnce != nil ? (event.triggerOnce ?? false) : clickOnce
        if triggerCount > 1 && triggerOnce { return }
        view?.fw.statisticalTarget.clickCounts[triggerKey] = triggerCount

        event.view = view
        event.viewController = view?.fw.viewController
        event.indexPath = indexPath
        event.triggerCount = triggerCount
        event.triggerTimestamp = Date.fw.currentTime
        event.isExposure = false
        event.isFinished = true
        handleEvent(event)
    }

    /// 手工触发视图曝光并统计次数，如果为cell需指定indexPath，isFinished为曝光结束，可重复触发
    @MainActor public func trackExposure(_ view: UIView?, indexPath: IndexPath? = nil, isFinished: Bool = false, event: StatisticalEvent) {
        if event.triggerIgnored { return }
        if let eventFilter, !eventFilter(event) { return }

        let triggerKey = StatisticalManager.statisticalIdentifier(event: event, indexPath: indexPath)
        var triggerCount = (view?.fw.statisticalTarget.exposureCounts[triggerKey] ?? 0)
        if !isFinished {
            triggerCount += 1
        }
        let triggerOnce = event.triggerOnce != nil ? (event.triggerOnce ?? false) : exposureOnce
        if triggerCount > 1 && triggerOnce { return }
        if !isFinished {
            view?.fw.statisticalTarget.exposureCounts[triggerKey] = triggerCount
        }

        let isVisibleCells = view?.statisticalViewVisibleIndexPaths() != nil
        var totalDuration = (view?.fw.statisticalTarget.exposureDurations[triggerKey] ?? 0)
        var duration: TimeInterval = 0
        let triggerTimestamp = Date.fw.currentTime
        if isFinished {
            var exposureTimestamp: TimeInterval?
            if isVisibleCells {
                exposureTimestamp = view?.fw.statisticalTarget.exposureTimestamps[triggerKey]
                view?.fw.statisticalTarget.exposureBegins[triggerKey] = nil
                view?.fw.statisticalTarget.exposureTimestamps[triggerKey] = nil
            } else {
                exposureTimestamp = view?.fw.statisticalTarget.exposureTimestamp
                view?.fw.statisticalTarget.exposureBegin = nil
                view?.fw.statisticalTarget.exposureTimestamp = 0
            }
            if let exposureTimestamp, exposureTimestamp > 0 {
                duration = triggerTimestamp - exposureTimestamp
                totalDuration += duration
            }
            view?.fw.statisticalTarget.exposureDurations[triggerKey] = totalDuration
        } else {
            if isVisibleCells {
                view?.fw.statisticalTarget.exposureTimestamps[triggerKey] = triggerTimestamp
            } else {
                view?.fw.statisticalTarget.exposureTimestamp = triggerTimestamp
            }
        }
        let isBackground = UIApplication.shared.applicationState == .background
        let isTerminated = view?.fw.statisticalTarget.exposureTerminated ?? false

        event.view = view
        event.viewController = view?.fw.viewController
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
                view?.fw.statisticalTarget.exposureBegins[triggerKey] = event.copy() as? StatisticalEvent
            } else {
                view?.fw.statisticalTarget.exposureBegin = event.copy() as? StatisticalEvent
            }
        }
        handleEvent(event)
    }

    /// 手工触发控制器曝光并统计次数，isFinished为曝光结束，可重复触发
    @MainActor public func trackExposure(_ viewController: UIViewController?, isFinished: Bool = false, event: StatisticalEvent) {
        if event.triggerIgnored { return }
        if let eventFilter, !eventFilter(event) { return }

        var triggerCount = (viewController?.fw.statisticalTarget.exposureCount ?? 0)
        if !isFinished {
            triggerCount += 1
        }
        let triggerOnce = event.triggerOnce != nil ? (event.triggerOnce ?? false) : exposureOnce
        if triggerCount > 1 && triggerOnce { return }
        if !isFinished {
            viewController?.fw.statisticalTarget.exposureCount = triggerCount
        }

        var totalDuration = (viewController?.fw.statisticalTarget.exposureDuration ?? 0)
        var duration: TimeInterval = 0
        let triggerTimestamp = Date.fw.currentTime
        if isFinished {
            let exposureTimestamp = viewController?.fw.statisticalTarget.exposureTimestamp
            if let exposureTimestamp, exposureTimestamp > 0 {
                duration = triggerTimestamp - exposureTimestamp
                totalDuration += duration
            }
            viewController?.fw.statisticalTarget.exposureDuration = totalDuration
            viewController?.fw.statisticalTarget.exposureBegin = nil
            viewController?.fw.statisticalTarget.exposureTimestamp = 0
        } else {
            viewController?.fw.statisticalTarget.exposureTimestamp = triggerTimestamp
        }
        let isBackground = UIApplication.shared.applicationState == .background
        let isTerminated = viewController?.fw.statisticalTarget.exposureTerminated ?? false

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
            viewController?.fw.statisticalTarget.exposureBegin = event.copy() as? StatisticalEvent
        }
        handleEvent(event)
    }

    // MARK: - Private
    /// 内部方法，处理事件
    @MainActor private func handleEvent(_ event: StatisticalEvent) {
        let event = event.eventFormatter?(event) ?? event
        if event.isExposure {
            if event.view != nil {
                event.view?.fw.statisticalExposureListener?(event)
            } else {
                event.viewController?.fw.statisticalExposureListener?(event)
            }
        } else {
            event.view?.fw.statisticalClickListener?(event)
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
        var identifier = "\(String.fw.safeString(event?.name))-\(String.fw.safeString(event?.object))"
        if let indexPaths {
            for indexPath in indexPaths {
                identifier += "-\(indexPath.section).\(indexPath.row)"
            }
        } else if let indexPath {
            identifier += "-\(indexPath.section).\(indexPath.row)"
        }
        return identifier
    }

    private var swizzleStatisticalViewFinished = false

    fileprivate static func swizzleStatisticalView() {
        guard !shared.swizzleStatisticalViewFinished else { return }
        shared.swizzleStatisticalViewFinished = true

        NSObject.fw.swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.didMoveToSuperview),
            methodSignature: (@convention(c) (UIView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)

            if selfObject.superview == nil {
                selfObject.fw.statisticalRemoveObservers()
            } else {
                if selfObject.fw.statisticalClick != nil {
                    selfObject.fw.statisticalBindClick()
                }
                if selfObject.fw.statisticalExposure != nil {
                    selfObject.fw.statisticalBindExposure()
                }

                selfObject.fw.statisticalAddObservers()
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.didMoveToWindow),
            methodSignature: (@convention(c) (UIView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)

            if selfObject.fw.statisticalExposure != nil {
                selfObject.fw.statisticalCheckExposure()
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
    public var shieldView: (@MainActor @Sendable (UIView) -> UIView?)?
    /// 自定义曝光句柄，参数为所在视图或控制器，用于自定义处理
    public var exposureBlock: (@MainActor @Sendable (Any) -> Bool)?
    /// 格式化事件句柄，用于替换indexPath数据为cell数据，默认nil
    public var eventFormatter: (@MainActor @Sendable (StatisticalEvent) -> StatisticalEvent)?

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
        let event = Self(name: name, object: object, userInfo: userInfo)
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
@MainActor @objc public protocol StatisticalViewProtocol {
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
            control.fw.addBlock({ sender in
                sender.fw.statisticalTrackClick()
            }, for: controlEvents)
            return true
        }

        guard let gestureRecognizers else { return false }
        for gesture in gestureRecognizers {
            if let tapGesture = gesture as? UITapGestureRecognizer {
                tapGesture.fw.addBlock { sender in
                    sender.view?.fw.statisticalTrackClick()
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
        superview?.fw.statisticalBindExposure(containerView)
        return true
    }

    /// 可统计视图子视图列表方法，返回nil时不处理，一般container实现(批量曝光)，子类可重写
    open func statisticalViewChildViews() -> [UIView]? {
        nil
    }

    /// 可统计视图可见indexPaths方法，返回nil时不处理，一般container实现(批量曝光)，子类可重写
    open func statisticalViewVisibleIndexPaths() -> [IndexPath]? {
        nil
    }

    /// 可统计视图容器视图方法，返回nil时不处理，一般cell实现，子类可重写
    open func statisticalViewContainerView() -> UIView? {
        nil
    }

    /// 可统计视图索引位置方法，返回nil时不处理，一般cell(批量曝光)和container(单曝光)实现，子类可重写
    open func statisticalViewIndexPath() -> IndexPath? {
        nil
    }
}

extension UITableView {
    override open func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        guard let tableDelegate = delegate as? NSObject else { return false }
        NSObject.fw.swizzleMethod(
            tableDelegate,
            selector: #selector(UITableViewDelegate.tableView(_:didSelectRowAt:)),
            identifier: "FWStatisticalManager",
            methodSignature: (@convention(c) (NSObject, Selector, UITableView, IndexPath) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, UITableView, IndexPath) -> Void).self
        ) { store in { selfObject, tableView, indexPath in
            store.original(selfObject, store.selector, tableView, indexPath)

            if !selfObject.fw.isSwizzleInstanceMethod(#selector(UITableViewDelegate.tableView(_:didSelectRowAt:)), identifier: "FWStatisticalManager") { return }

            let cell = tableView.cellForRow(at: indexPath)
            let isTracked = cell?.fw.statisticalTrackClick(indexPath: indexPath) ?? false
            if !isTracked, let containerView = cell?.statisticalViewContainerView() {
                containerView.fw.statisticalTrackClick(indexPath: indexPath)
            }
        }}
        return true
    }

    override open func statisticalViewChildViews() -> [UIView]? {
        subviews
    }
}

extension UICollectionView {
    override open func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        guard let collectionDelegate = delegate as? NSObject else { return false }
        NSObject.fw.swizzleMethod(
            collectionDelegate,
            selector: #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:)),
            identifier: "FWStatisticalManager",
            methodSignature: (@convention(c) (NSObject, Selector, UICollectionView, IndexPath) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, UICollectionView, IndexPath) -> Void).self
        ) { store in { selfObject, collectionView, indexPath in
            store.original(selfObject, store.selector, collectionView, indexPath)

            if !selfObject.fw.isSwizzleInstanceMethod(#selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:)), identifier: "FWStatisticalManager") { return }

            let cell = collectionView.cellForItem(at: indexPath)
            let isTracked = cell?.fw.statisticalTrackClick(indexPath: indexPath) ?? false
            if !isTracked, let containerView = cell?.statisticalViewContainerView() {
                containerView.fw.statisticalTrackClick(indexPath: indexPath)
            }
        }}
        return true
    }

    override open func statisticalViewChildViews() -> [UIView]? {
        subviews
    }
}

extension UITableViewCell {
    override open func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        guard let tableView = (containerView as? UITableView) ?? statisticalViewContainerView() else {
            return false
        }
        return tableView.fw.statisticalBindClick()
    }

    override open func statisticalViewWillBindExposure(_ containerView: UIView?) -> Bool {
        guard let tableView = (containerView as? UITableView) ?? statisticalViewContainerView() else {
            return false
        }
        return tableView.fw.statisticalBindExposure(containerView)
    }

    override open func statisticalViewContainerView() -> UIView? {
        fw.tableView
    }

    override open func statisticalViewIndexPath() -> IndexPath? {
        fw.tableView?.indexPath(for: self)
    }
}

extension UICollectionViewCell {
    override open func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        guard let collectionView = (containerView as? UICollectionView) ?? statisticalViewContainerView() else {
            return false
        }
        return collectionView.fw.statisticalBindClick()
    }

    override open func statisticalViewWillBindExposure(_ containerView: UIView?) -> Bool {
        guard let collectionView = (containerView as? UICollectionView) ?? statisticalViewContainerView() else {
            return false
        }
        return collectionView.fw.statisticalBindExposure(containerView)
    }

    override open func statisticalViewContainerView() -> UIView? {
        fw.collectionView
    }

    override open func statisticalViewIndexPath() -> IndexPath? {
        fw.collectionView?.indexPath(for: self)
    }
}

// MARK: - StatisticalTarget
private class StatisticalTarget: NSObject {
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
            NotificationCenter.default.addObserver(self, selector: #selector(appBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
        if StatisticalManager.shared.exposureTime {
            NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
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

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
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

        if valueChanged, let view = object as? UIView {
            DispatchQueue.fw.mainAsync {
                view.fw.statisticalCheckExposure()
            }
        }
    }

    @MainActor @objc func appBecomeActive() {
        view?.fw.statisticalCheckExposure()
    }

    @MainActor @objc func appEnterBackground() {
        view?.fw.statisticalCheckExposure()
    }

    @MainActor @objc func appWillTerminate() {
        exposureTerminated = true
        view?.fw.statisticalCheckExposure()
    }

    @MainActor @objc func exposureUpdate() {
        if view?.statisticalViewVisibleIndexPaths() == nil,
           let childViews = view?.statisticalViewChildViews() {
            for childView in childViews {
                childView.fw.statisticalCheckState()
            }
        } else {
            view?.fw.statisticalCheckState()
        }
    }
}

// MARK: - StatisticalState
private enum StatisticalState: Equatable {
    case none
    case partly(CGFloat)
    case fully

    var isFully: Bool {
        switch self {
        case .fully:
            return true
        case let .partly(ratio):
            return ratio >= StatisticalManager.shared.exposureThresholds
        default:
            return false
        }
    }

    func isState(_ state: StatisticalState) -> Bool {
        if case StatisticalState.partly = self,
           case StatisticalState.partly = state {
            return true
        }
        return self == state
    }
}

// MARK: - StatisticalControllerTarget
private class StatisticalControllerTarget: NSObject {
    weak var viewController: UIViewController?

    var exposureFully = false
    var exposureIdentifier = ""
    var exposureState: StatisticalState = .none
    var exposureObserved = false

    var exposureCount: Int = 0
    var exposureDuration: TimeInterval = 0
    var exposureTimestamp: TimeInterval = 0
    var exposureBegin: StatisticalEvent?
    var exposureTerminated = false

    deinit {
        removeObservers()
    }

    @MainActor func addObservers() {
        guard !exposureObserved else { return }
        exposureObserved = true

        viewController?.fw.observeLifecycleState { vc, state in
            if state == .didAppear {
                vc.fw.statisticalCheckExposure()
            } else if state == .didDisappear {
                vc.fw.statisticalCheckExposure()
            }
        }

        if StatisticalManager.shared.exposureBecomeActive ||
            StatisticalManager.shared.exposureTime {
            NotificationCenter.default.addObserver(self, selector: #selector(appBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
        if StatisticalManager.shared.exposureTime {
            NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
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

    @MainActor @objc func appBecomeActive() {
        viewController?.fw.statisticalCheckExposure()
    }

    @MainActor @objc func appEnterBackground() {
        viewController?.fw.statisticalCheckExposure()
    }

    @MainActor @objc func appWillTerminate() {
        exposureTerminated = true
        viewController?.fw.statisticalCheckExposure()
    }
}

// MARK: - BannerView+StatisticalView
extension BannerView {
    override open func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        true
    }

    override open func statisticalViewChildViews() -> [UIView]? {
        mainView.subviews
    }

    override open func statisticalViewIndexPath() -> IndexPath? {
        let itemIndex = flowLayout.currentPage ?? 0
        let indexPath = IndexPath(row: pageControlIndex(cellIndex: itemIndex), section: 0)
        return indexPath
    }
}

extension BannerViewCell {
    override open func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        true
    }

    override open func statisticalViewWillBindExposure(_ containerView: UIView?) -> Bool {
        let bannerView: UIView? = (containerView is BannerView) ? containerView : statisticalViewContainerView()
        return bannerView?.fw.statisticalBindExposure(containerView) ?? false
    }

    override open func statisticalViewContainerView() -> UIView? {
        var superview = superview
        while superview != nil {
            if let bannerView = superview as? BannerView {
                return bannerView
            }
            superview = superview?.superview
        }
        return nil
    }

    override open func statisticalViewIndexPath() -> IndexPath? {
        guard let bannerView = statisticalViewContainerView() as? BannerView,
              let cellIndexPath = bannerView.mainView.indexPath(for: self) else {
            return nil
        }

        let indexPath = IndexPath(row: bannerView.pageControlIndex(cellIndex: cellIndexPath.row), section: 0)
        return indexPath
    }
}

// MARK: - SegmentedControl+StatisticalView
extension SegmentedControl {
    override open func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        true
    }

    override open func statisticalViewVisibleIndexPaths() -> [IndexPath]? {
        let visibleMin = scrollView.contentOffset.x
        let visibleMax = visibleMin + scrollView.frame.size.width
        var sectionCount = 0
        var dynamicWidth = false
        if type == .text && segmentWidthStyle == .fixed {
            sectionCount = sectionTitles.count
        } else if segmentWidthStyle == .dynamic {
            sectionCount = segmentWidthsArray.count
            dynamicWidth = true
        } else {
            sectionCount = sectionImages.count
        }

        var indexPaths = [IndexPath]()
        var currentMin = contentEdgeInset.left
        for i in 0..<sectionCount {
            let currentMax = currentMin + (dynamicWidth ? segmentWidthsArray[i] : segmentWidth)
            if currentMin > visibleMax { break }

            if currentMin >= visibleMin && currentMax <= visibleMax {
                indexPaths.append(IndexPath(row: i, section: 0))
            }
            currentMin = currentMax
        }
        return indexPaths
    }
}

// MARK: - SegmentedControl+StatisticalView
extension TagCollectionView {
    override open func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        true
    }

    override open func statisticalViewVisibleIndexPaths() -> [IndexPath]? {
        var indexPaths: [IndexPath] = []
        let subviewsCount = containerView.subviews.count
        for idx in 0..<subviewsCount {
            indexPaths.append(IndexPath(row: idx, section: 0))
        }
        return indexPaths
    }
}

extension TextTagCollectionView {
    override open func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        true
    }

    override open func statisticalViewVisibleIndexPaths() -> [IndexPath]? {
        tagCollectionView.statisticalViewVisibleIndexPaths()
    }
}

// MARK: - FrameworkAutoloader+StatisticalView
@objc extension FrameworkAutoloader {
    static func loadToolkit_StatisticalView() {
        BannerView.trackClickBlock = { view, indexPath in
            view.fw.statisticalTrackClick(indexPath: indexPath)
        }

        BannerView.trackExposureBlock = { view in
            view.fw.statisticalCheckExposure()
        }
    }
}

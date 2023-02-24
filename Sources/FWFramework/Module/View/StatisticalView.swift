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
/// 视图从不可见变为可见时曝光开始，触发曝光开始事件；
/// 视图从可见到不可见时曝光结束，视为一次曝光，触发曝光结束事件并统计曝光时长(注意应用退后台时不计曝光时间)。
/// 默认运行模式时，视图快速滚动不计算曝光，可配置runLoopMode快速滚动时也计算曝光
public class StatisticalManager: NSObject {
    
    // MARK: - Accessor
    /// 单例模式
    public static let shared = StatisticalManager()
    
    /// 是否启用通知，默认false
    public var notificationEnabled = false
    /// 是否启用分析上报，默认false
    public var reportEnabled = false
    /// 设置全局事件处理器
    public var globalHandler: ((StatisticalEvent) -> Void)?
    
    /// 是否相同点击只触发一次，默认false，视图自定义后覆盖默认
    public var clickOnce = false
    /// 是否相同曝光只触发一次，默认false，视图自定义后覆盖默认
    public var exposureOnce = false
    /// 设置运行模式，默认default快速滚动时不计算曝光
    public var runLoopMode: RunLoop.Mode = .default
    /// 是否触发曝光结束事件并统计时长，如果只需要触发开始事件并统计次数可设为false，默认true
    public var trackingTime = true
    
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
    public func trackClick(view: UIView?, indexPath: IndexPath? = nil, event closure: @autoclosure () -> StatisticalEvent) {
        let event = closure()
        if event.triggerIgnored { return }
        let triggerKey = "\(indexPath?.section ?? -1).\(indexPath?.row ?? -1)-\(event.name)-\(String.fw_safeString(event.object))"
        let triggerCount = (view?.fw_trackClickCounts[triggerKey] ?? 0) + 1
        let triggerOnce = event.triggerOnce != nil ? (event.triggerOnce ?? false) : StatisticalManager.shared.clickOnce
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
    
    // MARK: - Private
    /// 内部方法，处理事件
    private func handleEvent(_ event: StatisticalEvent) {
        if let eventHandler = eventHandlers[event.name] {
            eventHandler(event)
        }
        globalHandler?(event)
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
    
    /// 自定义曝光容器视图，默认nil时获取VC视图或window
    public weak var containerView: UIView?
    /// 自定义曝光容器视图句柄，默认nil时获取VC视图或window，参数为所在视图
    public var containerViewBlock: ((UIView) -> UIView?)?
    /// 自定义曝光容器内边距，设置后忽略全局ignoredBars配置，默认nil
    public var containerInset: UIEdgeInsets?
    /// 是否事件仅触发一次，默认nil时采用全局配置
    public var triggerOnce: Bool?
    /// 是否忽略事件触发，默认false
    public var triggerIgnored = false
    /// 曝光遮挡视图，被遮挡时不计曝光
    public weak var shieldView: UIView?
    /// 曝光遮挡视图句柄，被遮挡时不计曝光，参数为所在视图
    public var shieldViewBlock: ((UIView) -> UIView?)?
    
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
    /// 是否是应用即将Terminate触发的曝光事件，用于自定义处理
    public fileprivate(set) var isTerminate = false
    /// 是否是应用退后台时触发的曝光事件，用于自定义处理
    public fileprivate(set) var isBackground = false
    
    /// 创建事件统计对象，指定名称、对象和信息
    public init(name: String, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        super.init()
        self.name = name
        self.object = object
        self.userInfo = userInfo
    }
    
}

// MARK: - UIView+StatisticalClick
@_spi(FW) extension UIView {
    
    fileprivate var fw_trackClickCounts: [String: Int] {
        get { return fw_property(forName: "fw_trackClickCounts") as? [String: Int] ?? [:] }
        set { fw_setProperty(newValue, forName: "fw_trackClickCounts") }
    }
    
}

// MARK: - UIView+StatisticalExposure
@_spi(FW) extension UIView {
    
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
    
}

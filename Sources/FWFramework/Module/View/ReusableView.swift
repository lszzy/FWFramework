//
//  ReusableView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - ReusableViewPool
/// 通用可重用视图缓存池，可继承
///
/// 使用方式如下，代码示例详见WebView：
/// 1. 应用启动完成时配置全局重用初始化句柄并调用enqueueReusableView(with: ReusableViewType.self)预加载第一个视图
/// 2. 重用视图初始化时调用：let reusableView = ReusableViewPool.shared.dequeueReusableView(with: ReusableViewType.self, viewHolder: self)
/// 3. 在需要预加载的场景中调用：reusableView.fw.preloadReusableView() 预加载下一个视图
/// 4. 在需要回收到缓存池时(一般控制器deinit)调用：ReusableViewPool.shared.enqueueReusableView(reusableView)
open class ReusableViewPool: NSObject {
    
    /// 单例模式对象，子类可直接调用
    public class var shared: Self {
        var instance = self.fw_property(forName: "shared") as? Self
        if let instance = instance { return instance }
        
        fw_synchronized {
            if let object = self.fw_property(forName: "shared") as? Self {
                instance = object
            } else {
                instance = self.init()
                self.fw_setProperty(instance, forName: "shared")
            }
        }
        return instance!
    }
    
    /// 最大缓存数量，默认5个
    open var maxReuseCount: Int = 5
    
    /// 最大预加载数量，默认1个
    open var maxPreloadCount: Int = 1
    
    /// 最大重用次数，默认为最大无限制
    open var maxReuseTimes: Int = .max
    
    private var dequeueReusableViews: [String: [UIView]] = [:]
    
    private var enqueueReusableViews: [String: [UIView]] = [:]
    
    private var lock: DispatchSemaphore = .init(value: 1)
    
    // MARK: - Lifecycle
    /// 初始化方法，内存警告时自动清理全部
    required public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(clearAllReusableViews), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    /// 析构方法
    deinit {
        NotificationCenter.default.removeObserver(self)
        dequeueReusableViews.removeAll()
        enqueueReusableViews.removeAll()
    }
    
    // MARK: - Public
    /// 获得一个可复用的视图
    /// - Parameters:
    ///   - reusableViewType: 可重用视图类型
    ///   - viewHolder: 视图的持有者，一般为所在控制器，持有者释放时会自动回收
    /// - Returns: 可复用的视图
    open func dequeueReusableView<T: UIView>(with reusableViewType: T.Type, viewHolder: NSObject?) -> T {
        recycleInvalidHolderReusableViews()
        let reusableView = getReusableView(with: reusableViewType)
        reusableView.fw_viewHolder = viewHolder
        return reusableView
    }
    
    /// 预加载一个可重用视图并将它放入到回收池中，最多不超过maxPreloadCount
    open func preloadReusableView<T: UIView>(with reusableViewType: T.Type) {
        lock.wait()
        let reusableIdentifier = NSStringFromClass(reusableViewType)
        var reusableViews = enqueueReusableViews[reusableIdentifier] ?? []
        if reusableViews.count < maxPreloadCount {
            let reusableView = initializeReusableView(with: reusableViewType)
            reusableViews.append(reusableView)
            enqueueReusableViews[reusableIdentifier] = reusableViews
        }
        lock.signal()
    }
    
    /// 回收可复用的视图
    open func recycleReusableView(_ reusableView: UIView?) {
        guard let reusableView = reusableView else { return }
        
        reusableView.removeFromSuperview()
        if reusableView.fw_reusedTimes >= maxReuseTimes || reusableView.fw_reuseInvalid {
            clearReusableView(reusableView)
            return
        }
        
        reusableView.reusableViewWillEnterPool()
        lock.wait()
        let reusableIdentifier = NSStringFromClass(type(of: reusableView))
        if var reusableViews = dequeueReusableViews[reusableIdentifier],
           reusableViews.contains(reusableView) {
            reusableViews.removeAll { $0 == reusableView }
            dequeueReusableViews[reusableIdentifier] = reusableViews
        }
        
        var reusableViews = enqueueReusableViews[reusableIdentifier] ?? []
        if reusableViews.count < maxReuseCount {
            reusableViews.append(reusableView)
            enqueueReusableViews[reusableIdentifier] = reusableViews
        }
        lock.signal()
    }
    
    /// 销毁指定的复用视图，并且从回收池里删除
    open func clearReusableView(_ reusableView: UIView?) {
        guard let reusableView = reusableView else { return }
        
        reusableView.reusableViewWillEnterPool()
        lock.wait()
        let reusableIdentifier = NSStringFromClass(type(of: reusableView))
        if var reusableViews = dequeueReusableViews[reusableIdentifier],
           reusableViews.contains(reusableView) {
            reusableViews.removeAll { $0 == reusableView }
            dequeueReusableViews[reusableIdentifier] = reusableViews
        }
        
        if var reusableViews = enqueueReusableViews[reusableIdentifier],
           reusableViews.contains(reusableView) {
            reusableViews.removeAll { $0 == reusableView }
            enqueueReusableViews[reusableIdentifier] = reusableViews
        }
        lock.signal()
    }
    
    /// 销毁在回收池中特定类的视图
    open func clearReusableViews<T: UIView>(with reusableViewType: T.Type) {
        let reusableIdentifier = NSStringFromClass(reusableViewType)
        lock.wait()
        if enqueueReusableViews.keys.contains(reusableIdentifier) {
            enqueueReusableViews.removeValue(forKey: reusableIdentifier)
        }
        lock.signal()
    }
    
    /// 销毁全部在回收池中的视图
    @objc open func clearAllReusableViews() {
        recycleInvalidHolderReusableViews()
        lock.wait()
        enqueueReusableViews.removeAll()
        lock.signal()
    }
    
    /// 重新刷新在回收池中的视图(触发willEnterPool)
    open func reloadAllReusableViews() {
        lock.wait()
        for reusableViews in enqueueReusableViews.values {
            for reusableView in reusableViews {
                reusableView.reusableViewWillEnterPool()
            }
        }
        lock.signal()
    }
    
    /// 判断回收池中是否包含特定类的视图
    open func containsReusableView<T: UIView>(with reusableViewType: T.Type) -> Bool {
        lock.wait()
        let reusableIdentifier = NSStringFromClass(reusableViewType)
        var contains = false
        if dequeueReusableViews.keys.contains(reusableIdentifier) ||
            enqueueReusableViews.keys.contains(reusableIdentifier) {
            contains = true
        }
        lock.signal()
        return contains
    }
    
    // MARK: - Private
    private func recycleInvalidHolderReusableViews() {
        let reusableViewDict = dequeueReusableViews
        if reusableViewDict.count > 0 {
            for reusableViews in reusableViewDict.values {
                for reusableView in reusableViews {
                    if reusableView.fw_viewHolder == nil {
                        recycleReusableView(reusableView)
                    }
                }
            }
        }
    }
    
    private func getReusableView<T: UIView>(with reusableViewType: T.Type) -> T {
        let reusableIdentifier = NSStringFromClass(reusableViewType)
        var enqueueReusableView: T?
        lock.wait()
        if var reusableViews = enqueueReusableViews[reusableIdentifier],
           reusableViews.count > 0 {
            enqueueReusableView = reusableViews.removeFirst() as? T
            enqueueReusableViews[reusableIdentifier] = reusableViews
        }
        
        let reusableView = enqueueReusableView ?? initializeReusableView(with: reusableViewType)
        var reusableViews = dequeueReusableViews[reusableIdentifier] ?? []
        reusableViews.append(reusableView)
        dequeueReusableViews[reusableIdentifier] = reusableViews
        lock.signal()
        
        reusableView.reusableViewWillLeavePool()
        return reusableView
    }
    
    private func initializeReusableView<T: UIView>(with reusableViewType: T.Type) -> T {
        let reusableView = reusableViewType.reusableViewInitialize()
        reusableView.reusableViewDidInitialize()
        return reusableView
    }
    
}

/// 可重用视图协议
public protocol ReusableViewProtocol {
    
    /// 初始化可重用视图，默认调用init(frame:)，必须调用super
    static func reusableViewInitialize() -> Self
    /// 可重用视图初始化完成，默认空实现，必须调用super
    func reusableViewDidInitialize()
    /// 即将进入回收池，默认空实现，必须调用super
    func reusableViewWillEnterPool()
    /// 即将离开回收池，默认空实现，必须调用super
    func reusableViewWillLeavePool()
    
}

@objc extension UIView: ReusableViewProtocol {
    
    /// 初始化可重用视图，默认调用init(frame:)，必须调用super
    open class func reusableViewInitialize() -> Self {
        return self.init(frame: .zero)
    }
    
    /// 可重用视图初始化完成，默认空实现，必须调用super
    open func reusableViewDidInitialize() {}
    
    /// 即将进入回收池，默认空实现，必须调用super
    open func reusableViewWillEnterPool() {}
    
    /// 即将离开回收池，默认空实现，必须调用super
    open func reusableViewWillLeavePool() {}
    
}

@_spi(FW) extension UIView {
    
    /// 视图持有者对象，弱引用
    public weak var fw_viewHolder: NSObject? {
        get { return fw_property(forName: "fw_viewHolder") as? NSObject }
        set { fw_setPropertyWeak(newValue, forName: "fw_viewHolder") }
    }
    
    /// 视图已重用次数
    public var fw_reusedTimes: Int {
        get { return fw_propertyInt(forName: "fw_reusedTimes") }
        set { fw_setPropertyInt(newValue, forName: "fw_reusedTimes") }
    }
    
    /// 标记重用失效，将自动从缓存池移除
    public var fw_reuseInvalid: Bool {
        get { return fw_propertyBool(forName: "fw_reuseInvalid") }
        set { fw_setPropertyBool(newValue, forName: "fw_reuseInvalid") }
    }
    
    /// 按需预加载下一个可重用视图，仅当缓存池包含当前视图类型时生效
    public func fw_preloadReusableView() {
        if ReusableViewPool.shared.containsReusableView(with: type(of: self)) {
            ReusableViewPool.shared.preloadReusableView(with: type(of: self))
        }
    }
    
}

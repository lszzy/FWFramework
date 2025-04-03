//
//  ReusableView.swift
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
    /// 视图持有者对象，弱引用
    public weak var viewHolder: NSObject? {
        get { property(forName: "viewHolder") as? NSObject }
        set { setPropertyWeak(newValue, forName: "viewHolder") }
    }

    /// 重用唯一标志，默认nil
    public var reuseIdentifier: String? {
        get { property(forName: "reuseIdentifier") as? String }
        set { setProperty(newValue, forName: "reuseIdentifier") }
    }

    /// 视图已重用次数，默认0
    public var reusedTimes: Int {
        get { propertyInt(forName: "reusedTimes") }
        set { setPropertyInt(newValue, forName: "reusedTimes") }
    }

    /// 标记重用准备中(true)，准备中的视图在完成(false)之前都不会被dequeue，默认false
    public var reusePreparing: Bool {
        get { propertyBool(forName: "reusePreparing") }
        set { setPropertyBool(newValue, forName: "reusePreparing") }
    }

    /// 标记重用失效，将自动从缓存池移除
    public var reuseInvalid: Bool {
        get { propertyBool(forName: "reuseInvalid") }
        set { setPropertyBool(newValue, forName: "reuseInvalid") }
    }

    /// 按需预加载下一个可重用视图，仅当前视图可重用时生效
    public func preloadReusableView() {
        guard let reuseIdentifier else { return }
        ReusableViewPool.shared.preloadReusableView(with: type(of: base), reuseIdentifier: reuseIdentifier)
    }
}

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
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if let instance = NSObject.fw.getAssociatedObject(self, key: #function) as? Self {
            return instance
        } else {
            let instance = self.init()
            NSObject.fw.setAssociatedObject(self, key: #function, value: instance)
            return instance
        }
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
    override public required init() {
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
    /// 获得一个指定类和唯一标志的可复用视图
    /// - Parameters:
    ///   - reusableViewType: 可重用视图类型
    ///   - viewHolder: 视图的持有者，一般为所在控制器，持有者释放时会自动回收
    ///   - reuseIdentifier: 重用附加唯一标志，默认空
    /// - Returns: 可复用的视图
    @MainActor open func dequeueReusableView<T: UIView>(with reusableViewType: T.Type, viewHolder: NSObject?, reuseIdentifier: String = "") -> T {
        recycleInvalidHolderReusableViews()
        let reusableView = getReusableView(with: reusableViewType, reuseIdentifier: reuseIdentifier)
        reusableView.fw.viewHolder = viewHolder
        return reusableView
    }

    /// 预加载一个指定类和唯一标志的可重用视图并将它放入到回收池中，最多不超过maxPreloadCount
    @MainActor open func preloadReusableView<T: UIView>(with reusableViewType: T.Type, reuseIdentifier: String = "") {
        var enqueueReusableView: T?
        lock.wait()
        let classIdentifier = NSStringFromClass(reusableViewType) + reuseIdentifier
        var reusableViews = enqueueReusableViews[classIdentifier] ?? []
        if reusableViews.count < maxPreloadCount {
            let reusableView = initializeReusableView(with: reusableViewType, reuseIdentifier: reuseIdentifier)
            enqueueReusableView = reusableView
            reusableViews.append(reusableView)
            enqueueReusableViews[classIdentifier] = reusableViews
        }
        lock.signal()

        enqueueReusableView?.reusableViewWillRecycle()
    }

    /// 回收可复用的视图
    @MainActor open func recycleReusableView(_ reusableView: UIView?) {
        guard let reusableView,
              let reuseIdentifier = reusableView.fw.reuseIdentifier else { return }

        reusableView.removeFromSuperview()
        if reusableView.fw.reusedTimes >= maxReuseTimes || reusableView.fw.reuseInvalid {
            clearReusableView(reusableView)
            return
        }

        reusableView.reusableViewWillRecycle()
        lock.wait()
        let classIdentifier = NSStringFromClass(type(of: reusableView)) + reuseIdentifier
        if var reusableViews = dequeueReusableViews[classIdentifier],
           reusableViews.contains(reusableView) {
            reusableViews.removeAll { $0 == reusableView }
            dequeueReusableViews[classIdentifier] = reusableViews
        }

        var reusableViews = enqueueReusableViews[classIdentifier] ?? []
        if reusableViews.count < maxReuseCount {
            reusableViews.append(reusableView)
            enqueueReusableViews[classIdentifier] = reusableViews
        }
        lock.signal()
    }

    /// 销毁指定的复用视图，并且从回收池里删除
    @MainActor open func clearReusableView(_ reusableView: UIView?) {
        guard let reusableView,
              let reuseIdentifier = reusableView.fw.reuseIdentifier else { return }

        lock.wait()
        let classIdentifier = NSStringFromClass(type(of: reusableView)) + reuseIdentifier
        if var reusableViews = dequeueReusableViews[classIdentifier],
           reusableViews.contains(reusableView) {
            reusableViews.removeAll { $0 == reusableView }
            dequeueReusableViews[classIdentifier] = reusableViews
        }

        if var reusableViews = enqueueReusableViews[classIdentifier],
           reusableViews.contains(reusableView) {
            reusableViews.removeAll { $0 == reusableView }
            enqueueReusableViews[classIdentifier] = reusableViews
        }
        lock.signal()
    }

    /// 销毁在回收池中特定类和唯一标志的视图
    open func clearReusableViews<T: UIView>(with reusableViewType: T.Type, reuseIdentifier: String = "") {
        let classIdentifier = NSStringFromClass(reusableViewType) + reuseIdentifier
        lock.wait()
        if enqueueReusableViews.keys.contains(classIdentifier) {
            enqueueReusableViews.removeValue(forKey: classIdentifier)
        }
        lock.signal()
    }

    /// 销毁全部在回收池中的视图
    @MainActor @objc open func clearAllReusableViews() {
        recycleInvalidHolderReusableViews()
        lock.wait()
        enqueueReusableViews.removeAll()
        lock.signal()
    }

    /// 重新刷新在回收池中的视图(触发willEnterPool)
    @MainActor open func reloadAllReusableViews() {
        lock.wait()
        for reusableViews in enqueueReusableViews.values {
            for reusableView in reusableViews {
                reusableView.reusableViewWillRecycle()
            }
        }
        lock.signal()
    }

    /// 判断回收池中是否包含特定类和唯一标志的视图
    open func containsReusableView<T: UIView>(with reusableViewType: T.Type, reuseIdentifier: String = "") -> Bool {
        lock.wait()
        let classIdentifier = NSStringFromClass(reusableViewType) + reuseIdentifier
        var contains = false
        if dequeueReusableViews.keys.contains(classIdentifier) ||
            enqueueReusableViews.keys.contains(classIdentifier) {
            contains = true
        }
        lock.signal()
        return contains
    }

    // MARK: - Private
    @MainActor private func recycleInvalidHolderReusableViews() {
        let reusableViewDict = dequeueReusableViews
        if reusableViewDict.count > 0 {
            for reusableViews in reusableViewDict.values {
                for reusableView in reusableViews {
                    if reusableView.fw.viewHolder == nil {
                        recycleReusableView(reusableView)
                    }
                }
            }
        }
    }

    @MainActor private func getReusableView<T: UIView>(with reusableViewType: T.Type, reuseIdentifier: String) -> T {
        let classIdentifier = NSStringFromClass(reusableViewType) + reuseIdentifier
        var enqueueReusableView: T?
        lock.wait()
        if var reusableViews = enqueueReusableViews[classIdentifier],
           let enqueueIndex = reusableViews.firstIndex(where: { !$0.fw.reusePreparing }) {
            enqueueReusableView = reusableViews.remove(at: enqueueIndex) as? T
            enqueueReusableViews[classIdentifier] = reusableViews
        }

        let reusableView = enqueueReusableView ?? initializeReusableView(with: reusableViewType, reuseIdentifier: reuseIdentifier)
        var reusableViews = dequeueReusableViews[classIdentifier] ?? []
        reusableViews.append(reusableView)
        dequeueReusableViews[classIdentifier] = reusableViews
        lock.signal()

        reusableView.reusableViewWillReuse()
        return reusableView
    }

    @MainActor private func initializeReusableView<T: UIView>(with reusableViewType: T.Type, reuseIdentifier: String) -> T {
        let reusableView = reusableViewType.reusableViewInitialize(reuseIdentifier: reuseIdentifier)
        reusableView.fw.reuseIdentifier = reuseIdentifier
        return reusableView
    }
}

/// 可重用视图协议
@MainActor public protocol ReusableViewProtocol {
    /// 初始化可重用视图，默认调用init(frame:)
    static func reusableViewInitialize(reuseIdentifier: String) -> Self
    /// 即将回收视图，默认清空viewHolder，必须调用super
    func reusableViewWillRecycle()
    /// 即将重用视图，默认重用次数+1，必须调用super
    func reusableViewWillReuse()
}

@objc extension UIView: ReusableViewProtocol {
    /// 初始化可重用视图，默认调用init(frame:)
    open class func reusableViewInitialize(reuseIdentifier: String) -> Self {
        self.init(frame: .zero)
    }

    /// 即将回收视图，默认清空viewHolder，必须调用super
    open func reusableViewWillRecycle() {
        fw.viewHolder = nil
    }

    /// 即将重用视图，默认重用次数+1，必须调用super
    open func reusableViewWillReuse() {
        fw.reusedTimes += 1
    }
}

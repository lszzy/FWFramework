//
//  RefreshPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - RefreshPlugin
/// 刷新插件协议，应用可自定义刷新插件实现
public protocol RefreshPlugin: AnyObject {

    // MARK: - Refreshing
    /// 是否正在刷新中
    func isRefreshing(scrollView: UIScrollView) -> Bool

    /// 是否显示刷新组件
    func shouldRefreshing(scrollView: UIScrollView) -> Bool

    /// 设置是否显示刷新组件
    func setShouldRefreshing(_ shouldRefreshing: Bool, scrollView: UIScrollView)

    /// 配置下拉刷新句柄
    func setRefreshing(block: @escaping () -> Void, scrollView: UIScrollView)

    /// 配置下拉刷新事件
    func setRefreshing(target: Any, action: Selector, scrollView: UIScrollView)

    /// 开始下拉刷新
    func beginRefreshing(scrollView: UIScrollView)

    /// 结束下拉刷新
    func endRefreshing(scrollView: UIScrollView)

    // MARK: - Loading
    /// 是否正在追加中
    func isLoading(scrollView: UIScrollView) -> Bool

    /// 是否显示追加组件
    func shouldLoading(scrollView: UIScrollView) -> Bool

    /// 设置是否显示追加组件
    func setShouldLoading(_ shouldLoading: Bool, scrollView: UIScrollView)

    /// 是否已追加完成，不能继续追加
    func loadingFinished(scrollView: UIScrollView) -> Bool

    /// 设置是否已追加完成，不能继续追加
    func setLoadingFinished(_ loadingFinished: Bool, scrollView: UIScrollView)

    /// 配置上拉追加句柄
    func setLoading(block: @escaping () -> Void, scrollView: UIScrollView)

    /// 配置上拉追加事件
    func setLoading(target: Any, action: Selector, scrollView: UIScrollView)

    /// 开始上拉追加
    func beginLoading(scrollView: UIScrollView)

    /// 结束上拉追加
    func endLoading(scrollView: UIScrollView)
    
}

extension RefreshPlugin {
    
    // MARK: - Refreshing
    /// 默认实现，是否正在刷新中
    public func isRefreshing(scrollView: UIScrollView) -> Bool {
        return RefreshPluginImpl.shared.isRefreshing(scrollView: scrollView)
    }

    /// 默认实现，是否显示刷新组件
    public func shouldRefreshing(scrollView: UIScrollView) -> Bool {
        return RefreshPluginImpl.shared.shouldRefreshing(scrollView: scrollView)
    }

    /// 默认实现，设置是否显示刷新组件
    public func setShouldRefreshing(_ shouldRefreshing: Bool, scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setShouldRefreshing(shouldRefreshing, scrollView: scrollView)
    }

    /// 默认实现，配置下拉刷新句柄
    public func setRefreshing(block: @escaping () -> Void, scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setRefreshing(block: block, scrollView: scrollView)
    }

    /// 默认实现，配置下拉刷新事件
    public func setRefreshing(target: Any, action: Selector, scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setRefreshing(target: target, action: action, scrollView: scrollView)
    }

    /// 默认实现，开始下拉刷新
    public func beginRefreshing(scrollView: UIScrollView) {
        RefreshPluginImpl.shared.beginRefreshing(scrollView: scrollView)
    }

    /// 默认实现，结束下拉刷新
    public func endRefreshing(scrollView: UIScrollView) {
        RefreshPluginImpl.shared.endRefreshing(scrollView: scrollView)
    }

    // MARK: - Loading
    /// 默认实现，是否正在追加中
    public func isLoading(scrollView: UIScrollView) -> Bool {
        return RefreshPluginImpl.shared.isLoading(scrollView: scrollView)
    }

    /// 默认实现，是否显示追加组件
    public func shouldLoading(scrollView: UIScrollView) -> Bool {
        return RefreshPluginImpl.shared.shouldLoading(scrollView: scrollView)
    }

    /// 默认实现，设置是否显示追加组件
    public func setShouldLoading(_ shouldLoading: Bool, scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setShouldLoading(shouldLoading, scrollView: scrollView)
    }

    /// 默认实现，是否已追加完成，不能继续追加
    public func loadingFinished(scrollView: UIScrollView) -> Bool {
        return RefreshPluginImpl.shared.loadingFinished(scrollView: scrollView)
    }

    /// 默认实现，设置是否已追加完成，不能继续追加
    public func setLoadingFinished(_ loadingFinished: Bool, scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setLoadingFinished(loadingFinished, scrollView: scrollView)
    }

    /// 默认实现，配置上拉追加句柄
    public func setLoading(block: @escaping () -> Void, scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setLoading(block: block, scrollView: scrollView)
    }

    /// 默认实现，配置上拉追加事件
    public func setLoading(target: Any, action: Selector, scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setLoading(target: target, action: action, scrollView: scrollView)
    }

    /// 默认实现，开始上拉追加
    public func beginLoading(scrollView: UIScrollView) {
        RefreshPluginImpl.shared.beginLoading(scrollView: scrollView)
    }

    /// 默认实现，结束上拉追加
    public func endLoading(scrollView: UIScrollView) {
        RefreshPluginImpl.shared.endLoading(scrollView: scrollView)
    }
    
}

// MARK: - UIScrollView+RefreshPlugin
@_spi(FW) extension UIScrollView {
    
    /// 自定义刷新插件，未设置时自动从插件池加载
    public var fw_refreshPlugin: RefreshPlugin! {
        get {
            if let refreshPlugin = fw_property(forName: "fw_refreshPlugin") as? RefreshPlugin {
                return refreshPlugin
            } else if let refreshPlugin = PluginManager.loadPlugin(RefreshPlugin.self) {
                return refreshPlugin
            }
            return RefreshPluginImpl.shared
        }
        set {
            fw_setProperty(newValue, forName: "fw_refreshPlugin")
        }
    }

    // MARK: - Refreshing
    /// 是否正在刷新中
    public var fw_isRefreshing: Bool {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        return plugin.isRefreshing(scrollView: self)
    }

    /// 是否显示刷新组件
    public var fw_shouldRefreshing: Bool {
        get {
            let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
            return plugin.shouldRefreshing(scrollView: self)
        }
        set {
            let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
            plugin.setShouldRefreshing(newValue, scrollView: self)
        }
    }

    /// 配置下拉刷新句柄
    public func fw_setRefreshing(block: @escaping () -> Void) {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.setRefreshing(block: block, scrollView: self)
    }

    /// 配置下拉刷新事件
    public func fw_setRefreshing(target: Any, action: Selector) {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.setRefreshing(target: target, action: action, scrollView: self)
    }

    /// 开始下拉刷新
    public func fw_beginRefreshing() {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.beginRefreshing(scrollView: self)
    }

    /// 结束下拉刷新
    public func fw_endRefreshing() {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.endRefreshing(scrollView: self)
    }
    
    /// 结束下拉刷新并标记是否加载完成
    public func fw_endRefreshing(finished: Bool) {
        self.fw_endRefreshing()
        self.fw_loadingFinished = finished
    }

    // MARK: - Loading
    /// 是否正在追加中
    public var fw_isLoading: Bool {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        return plugin.isLoading(scrollView: self)
    }

    /// 是否显示追加组件
    public var fw_shouldLoading: Bool {
        get {
            let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
            return plugin.shouldLoading(scrollView: self)
        }
        set {
            let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
            plugin.setShouldLoading(newValue, scrollView: self)
        }
    }
    
    /// 是否已加载完成，不能继续追加
    public var fw_loadingFinished: Bool {
        get {
            let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
            return plugin.loadingFinished(scrollView: self)
        }
        set {
            let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
            plugin.setLoadingFinished(newValue, scrollView: self)
        }
    }

    /// 配置上拉追加句柄
    public func fw_setLoading(block: @escaping () -> Void) {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.setLoading(block: block, scrollView: self)
    }

    /// 配置上拉追加事件
    public func fw_setLoading(target: Any, action: Selector) {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.setLoading(target: target, action: action, scrollView: self)
    }

    /// 开始上拉追加
    public func fw_beginLoading() {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.beginLoading(scrollView: self)
    }

    /// 结束上拉追加
    public func fw_endLoading() {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.endLoading(scrollView: self)
    }
    
    /// 结束上拉追加并标记是否加载完成
    public func fw_endLoading(finished: Bool) {
        self.fw_endLoading()
        self.fw_loadingFinished = finished
    }
    
}

@_spi(FW) extension UIScrollView {
    
    public func fw_addPullRefresh(block: @escaping () -> Void) {
        fw_addPullRefresh(block: block, target: nil, action: nil)
    }
    
    public func fw_addPullRefresh(target: Any, action: Selector) {
        fw_addPullRefresh(block: nil, target: target, action: action)
    }
    
    private func fw_addPullRefresh(block: (() -> Void)?, target: Any?, action: Selector?) {
        self.fw_pullRefreshView?.removeFromSuperview()
        
        let view = PullRefreshView(frame: CGRect(x: 0, y: -self.fw_pullRefreshHeight, width: self.bounds.size.width, height: self.fw_pullRefreshHeight))
        view.pullRefreshBlock = block
        view.target = target as? AnyObject
        view.action = action
        view.scrollView = self
        self.addSubview(view)
        
        view.originalInset = self.contentInset
        self.fw_pullRefreshView = view
        self.fw_showPullRefresh = true
    }
    
    public func fw_triggerPullRefresh() {
        if self.fw_pullRefreshView?.isAnimating ?? false { return }
        
        self.fw_pullRefreshView?.state = .triggered
        self.fw_pullRefreshView?.userTriggered = false
        self.fw_pullRefreshView?.startAnimating()
    }

    public var fw_pullRefreshView: PullRefreshView? {
        get {
            return fw_property(forName: "fw_pullRefreshView") as? PullRefreshView
        }
        set {
            fw_setProperty(newValue, forName: "fw_pullRefreshView")
        }
    }
    
    public var fw_pullRefreshHeight: CGFloat {
        get {
            let height = fw_propertyDouble(forName: "fw_pullRefreshHeight")
            return height > 0 ? height : PullRefreshView.height
        }
        set {
            fw_setPropertyDouble(newValue, forName: "fw_pullRefreshHeight")
        }
    }
    
    public var fw_showPullRefresh: Bool {
        get {
            if let pullRefreshView = self.fw_pullRefreshView {
                return !pullRefreshView.isHidden
            }
            return false
        }
        set {
            guard let pullRefreshView = self.fw_pullRefreshView else { return }
            
            pullRefreshView.isHidden = !newValue
            if !newValue {
                if pullRefreshView.isObserving {
                    self.removeObserver(pullRefreshView, forKeyPath: "contentOffset")
                    self.removeObserver(pullRefreshView, forKeyPath: "contentSize")
                    self.removeObserver(pullRefreshView, forKeyPath: "frame")
                    self.panGestureRecognizer.fw_unobserveProperty("state", target: pullRefreshView, action: #selector(PullRefreshView.gestureRecognizer(_:stateChanged:)))
                    pullRefreshView.resetScrollViewContentInset()
                    pullRefreshView.isObserving = false
                }
            } else {
                if !pullRefreshView.isObserving {
                    self.addObserver(pullRefreshView, forKeyPath: "contentOffset", options: .new, context: nil)
                    self.addObserver(pullRefreshView, forKeyPath: "contentSize", options: .new, context: nil)
                    self.addObserver(pullRefreshView, forKeyPath: "frame", options: .new, context: nil)
                    self.panGestureRecognizer.fw_observeProperty("state", target: pullRefreshView, action: #selector(pullRefreshView.gestureRecognizer(_:stateChanged:)))
                    pullRefreshView.isObserving = true
                    
                    pullRefreshView.setNeedsLayout()
                    pullRefreshView.layoutIfNeeded()
                    pullRefreshView.frame = CGRect(x: 0, y: -self.fw_pullRefreshHeight, width: self.bounds.size.width, height: self.fw_pullRefreshHeight)
                }
            }
        }
    }
    
    public func fw_addInfiniteScroll(block: @escaping () -> Void) {
        fw_addInfiniteScroll(block: block, target: nil, action: nil)
    }
    
    public func fw_addInfiniteScroll(target: Any, action: Selector) {
        fw_addInfiniteScroll(block: nil, target: target, action: action)
    }
    
    private func fw_addInfiniteScroll(block: (() -> Void)?, target: Any?, action: Selector?) {
        self.fw_infiniteScrollView?.removeFromSuperview()
        
        let view = InfiniteScrollView(frame: CGRect(x: 0, y: self.contentSize.height, width: self.bounds.size.width, height: self.fw_infiniteScrollHeight))
        view.infiniteScrollBlock = block
        view.target = target as? AnyObject
        view.action = action
        view.scrollView = self
        self.addSubview(view)
        
        view.originalInset = self.contentInset
        self.fw_infiniteScrollView = view
        self.fw_showInfiniteScroll = true
    }
    
    public func fw_triggerInfiniteScroll() {
        if self.fw_infiniteScrollView?.isAnimating ?? false { return }
        if self.fw_infiniteScrollView?.finished ?? false { return }
        
        self.fw_infiniteScrollView?.state = .triggered
        self.fw_infiniteScrollView?.userTriggered = false
        self.fw_infiniteScrollView?.startAnimating()
    }

    public var fw_infiniteScrollView: InfiniteScrollView? {
        get {
            return fw_property(forName: "fw_infiniteScrollView") as? InfiniteScrollView
        }
        set {
            fw_setProperty(newValue, forName: "fw_infiniteScrollView")
        }
    }
    
    public var fw_infiniteScrollHeight: CGFloat {
        get {
            let height = fw_propertyDouble(forName: "fw_infiniteScrollHeight")
            return height > 0 ? height : InfiniteScrollView.height
        }
        set {
            fw_setPropertyDouble(newValue, forName: "fw_infiniteScrollHeight")
        }
    }
    
    public var fw_showInfiniteScroll: Bool {
        get {
            if let infiniteScrollView = self.fw_infiniteScrollView {
                return !infiniteScrollView.isHidden
            }
            return false
        }
        set {
            guard let infiniteScrollView = self.fw_infiniteScrollView else { return }
            
            infiniteScrollView.isHidden = !newValue
            if !newValue {
                if infiniteScrollView.isObserving {
                    self.removeObserver(infiniteScrollView, forKeyPath: "contentOffset")
                    self.removeObserver(infiniteScrollView, forKeyPath: "contentSize")
                    self.panGestureRecognizer.fw_unobserveProperty("state", target: infiniteScrollView, action: #selector(InfiniteScrollView.gestureRecognizer(_:stateChanged:)))
                    infiniteScrollView.resetScrollViewContentInset()
                    infiniteScrollView.isObserving = false
                }
            } else {
                if !infiniteScrollView.isObserving {
                    self.addObserver(infiniteScrollView, forKeyPath: "contentOffset", options: .new, context: nil)
                    self.addObserver(infiniteScrollView, forKeyPath: "contentSize", options: .new, context: nil)
                    self.panGestureRecognizer.fw_observeProperty("state", target: infiniteScrollView, action: #selector(InfiniteScrollView.gestureRecognizer(_:stateChanged:)))
                    infiniteScrollView.setScrollViewContentInsetForInfiniteScrolling()
                    infiniteScrollView.isObserving = true
                    
                    infiniteScrollView.setNeedsLayout()
                    infiniteScrollView.layoutIfNeeded()
                    infiniteScrollView.frame = CGRect(x: 0, y: self.contentSize.height, width: infiniteScrollView.bounds.size.width, height: self.fw_infiniteScrollHeight)
                }
            }
        }
    }
    
    public var fw_infiniteScrollFinished: Bool {
        get {
            return self.fw_infiniteScrollView?.finished ?? false
        }
        set {
            self.fw_infiniteScrollView?.finished = newValue
        }
    }
    
}

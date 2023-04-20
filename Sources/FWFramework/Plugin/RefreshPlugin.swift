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
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.isRefreshing(_:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        return plugin.isRefreshing?(self) ?? false
    }

    /// 是否显示刷新组件
    public var fw_shouldRefreshing: Bool {
        get {
            var plugin: RefreshPlugin
            if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.shouldRefreshing(_:))) {
                plugin = refreshPlugin
            } else {
                plugin = RefreshPluginImpl.shared
            }
            return plugin.shouldRefreshing?(self) ?? false
        }
        set {
            var plugin: RefreshPlugin
            if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setShouldRefreshing(_:scrollView:))) {
                plugin = refreshPlugin
            } else {
                plugin = RefreshPluginImpl.shared
            }
            plugin.setShouldRefreshing?(newValue, scrollView: self)
        }
    }

    /// 配置下拉刷新句柄
    public func fw_setRefreshing(block: @escaping () -> Void) {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setRefreshingBlock(_:scrollView:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.setRefreshingBlock?(block, scrollView: self)
    }

    /// 配置下拉刷新事件
    public func fw_setRefreshing(target: Any, action: Selector) {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setRefreshingTarget(_:action:scrollView:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.setRefreshingTarget?(target, action: action, scrollView: self)
    }

    /// 开始下拉刷新
    public func fw_beginRefreshing() {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.beginRefreshing(_:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.beginRefreshing?(self)
    }

    /// 结束下拉刷新
    public func fw_endRefreshing() {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.endRefreshing(_:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.endRefreshing?(self)
    }

    // MARK: - Loading

    /// 是否正在追加中
    public var fw_isLoading: Bool {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.isLoading(_:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        return plugin.isLoading?(self) ?? false
    }

    /// 是否显示追加组件
    public var fw_shouldLoading: Bool {
        get {
            var plugin: RefreshPlugin
            if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.shouldLoading(_:))) {
                plugin = refreshPlugin
            } else {
                plugin = RefreshPluginImpl.shared
            }
            return plugin.shouldLoading?(self) ?? false
        }
        set {
            var plugin: RefreshPlugin
            if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setShouldLoading(_:scrollView:))) {
                plugin = refreshPlugin
            } else {
                plugin = RefreshPluginImpl.shared
            }
            plugin.setShouldLoading?(newValue, scrollView: self)
        }
    }
    
    /// 是否已加载完成，不能继续追加
    public var fw_loadingFinished: Bool {
        get {
            var plugin: RefreshPlugin
            if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.loadingFinished(_:))) {
                plugin = refreshPlugin
            } else {
                plugin = RefreshPluginImpl.shared
            }
            return plugin.loadingFinished?(self) ?? false
        }
        set {
            var plugin: RefreshPlugin
            if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setLoadingFinished(_:scrollView:))) {
                plugin = refreshPlugin
            } else {
                plugin = RefreshPluginImpl.shared
            }
            plugin.setLoadingFinished?(newValue, scrollView: self)
        }
    }

    /// 配置上拉追加句柄
    public func fw_setLoading(block: @escaping () -> Void) {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setLoading(_:scrollView:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.setLoading?(block, scrollView: self)
    }

    /// 配置上拉追加事件
    public func fw_setLoading(target: Any, action: Selector) {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setLoadingTarget(_:action:scrollView:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.setLoadingTarget?(target, action: action, scrollView: self)
    }

    /// 开始上拉追加
    public func fw_beginLoading() {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.beginLoading(_:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.beginLoading?(self)
    }

    /// 结束上拉追加
    public func fw_endLoading() {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.endLoading(_:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.endLoading?(self)
    }
    
}

@_spi(FW) extension UIScrollView {
    
    @objc(__fw_addPullRefreshWithBlock:)
    public func fw_addPullRefresh(block: @escaping () -> Void) {
        fw_addPullRefresh(block: block, target: nil, action: nil)
    }
    
    @objc(__fw_addPullRefreshWithTarget:action:)
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
    
    @objc(__fw_triggerPullRefresh)
    public func fw_triggerPullRefresh() {
        if self.fw_pullRefreshView?.isAnimating() ?? false { return }
        
        self.fw_pullRefreshView?.state = .triggered
        self.fw_pullRefreshView?.userTriggered = false
        self.fw_pullRefreshView?.startAnimating()
    }

    @objc(__fw_pullRefreshView)
    public var fw_pullRefreshView: PullRefreshView? {
        get {
            return fw_property(forName: "fw_pullRefreshView") as? PullRefreshView
        }
        set {
            fw_setProperty(newValue, forName: "fw_pullRefreshView")
        }
    }
    
    @objc(__fw_pullRefreshHeight)
    public var fw_pullRefreshHeight: CGFloat {
        get {
            let height = fw_propertyDouble(forName: "fw_pullRefreshHeight")
            return height > 0 ? height : PullRefreshView.height
        }
        set {
            fw_setPropertyDouble(newValue, forName: "fw_pullRefreshHeight")
        }
    }
    
    @objc(__fw_showPullRefresh)
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
                    pullRefreshView.resetScrollContentInset()
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
    
    @objc(__fw_addInfiniteScrollWithBlock:)
    public func fw_addInfiniteScroll(block: @escaping () -> Void) {
        fw_addInfiniteScroll(block: block, target: nil, action: nil)
    }
    
    @objc(__fw_addInfiniteScrollWithTarget:action:)
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
    
    @objc(__fw_triggerInfiniteScroll)
    public func fw_triggerInfiniteScroll() {
        if self.fw_infiniteScrollView?.isAnimating() ?? false { return }
        if self.fw_infiniteScrollView?.finished ?? false { return }
        
        self.fw_infiniteScrollView?.state = .triggered
        self.fw_infiniteScrollView?.userTriggered = false
        self.fw_infiniteScrollView?.startAnimating()
    }

    @objc(__fw_infiniteScrollView)
    public var fw_infiniteScrollView: InfiniteScrollView? {
        get {
            return fw_property(forName: "fw_infiniteScrollView") as? InfiniteScrollView
        }
        set {
            fw_setProperty(newValue, forName: "fw_infiniteScrollView")
        }
    }
    
    @objc(__fw_infiniteScrollHeight)
    public var fw_infiniteScrollHeight: CGFloat {
        get {
            let height = fw_propertyDouble(forName: "fw_infiniteScrollHeight")
            return height > 0 ? height : InfiniteScrollView.height
        }
        set {
            fw_setPropertyDouble(newValue, forName: "fw_infiniteScrollHeight")
        }
    }
    
    @objc(__fw_showInfiniteScroll)
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
    
    @objc(__fw_infiniteScrollFinished)
    public var fw_infiniteScrollFinished: Bool {
        get {
            return self.fw_infiniteScrollView?.finished ?? false
        }
        set {
            self.fw_infiniteScrollView?.finished = newValue
        }
    }
    
}

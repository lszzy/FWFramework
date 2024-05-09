//
//  RefreshPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UIScrollView
extension Wrapper where Base: UIScrollView {
    /// 自定义刷新插件，未设置时自动从插件池加载
    public var refreshPlugin: RefreshPlugin! {
        get { return base.fw_refreshPlugin }
        set { base.fw_refreshPlugin = newValue }
    }

    // MARK: - Refreshing
    /// 是否正在刷新中
    public var isRefreshing: Bool {
        return base.fw_isRefreshing
    }

    /// 是否显示刷新组件
    public var shouldRefreshing: Bool {
        get { return base.fw_shouldRefreshing }
        set { base.fw_shouldRefreshing = newValue }
    }

    /// 配置下拉刷新句柄
    public func setRefreshing(block: @escaping () -> Void, customBlock: ((Any) -> Void)? = nil) {
        base.fw_setRefreshing(block: block, customBlock: customBlock)
    }

    /// 配置下拉刷新事件
    public func setRefreshing(target: Any, action: Selector, customBlock: ((Any) -> Void)? = nil) {
        base.fw_setRefreshing(target: target, action: action, customBlock: customBlock)
    }

    /// 开始下拉刷新
    public func beginRefreshing() {
        base.fw_beginRefreshing()
    }

    /// 结束下拉刷新
    public func endRefreshing() {
        base.fw_endRefreshing()
    }
    
    /// 结束下拉刷新并标记是否加载完成，需在reloadData之后调用
    public func endRefreshing(finished: Bool) {
        base.fw_endRefreshing(finished: finished)
    }

    // MARK: - Loading
    /// 是否正在追加中
    public var isLoading: Bool {
        return base.fw_isLoading
    }

    /// 是否显示追加组件
    public var shouldLoading: Bool {
        get { return base.fw_shouldLoading }
        set { base.fw_shouldLoading = newValue }
    }
    
    /// 是否已加载完成，不能继续追加，需在reloadData之后调用
    public var loadingFinished: Bool {
        get { return base.fw_loadingFinished }
        set { base.fw_loadingFinished = newValue }
    }

    /// 配置上拉追加句柄
    public func setLoading(block: @escaping () -> Void, customBlock: ((Any) -> Void)? = nil) {
        base.fw_setLoading(block: block, customBlock: customBlock)
    }

    /// 配置上拉追加事件
    public func setLoading(target: Any, action: Selector, customBlock: ((Any) -> Void)? = nil) {
        base.fw_setLoading(target: target, action: action, customBlock: customBlock)
    }

    /// 开始上拉追加
    public func beginLoading() {
        base.fw_beginLoading()
    }

    /// 结束上拉追加
    public func endLoading() {
        base.fw_endLoading()
    }
    
    /// 结束上拉追加并标记是否加载完成，需在reloadData之后调用
    public func endLoading(finished: Bool) {
        base.fw_endLoading(finished: finished)
    }
}

// MARK: - Wrapper+UIScrollView
extension Wrapper where Base: UIScrollView {
    public func addPullRefresh(block: @escaping () -> Void) {
        base.fw_addPullRefresh(block: block)
    }
    
    public func addPullRefresh(target: Any, action: Selector) {
        base.fw_addPullRefresh(target: target, action: action)
    }
    
    public func triggerPullRefresh() {
        base.fw_triggerPullRefresh()
    }

    public var pullRefreshView: PullRefreshView? {
        return base.fw_pullRefreshView
    }
    
    public var showPullRefresh: Bool {
        get { return base.fw_showPullRefresh }
        set { base.fw_showPullRefresh = newValue }
    }
    
    public func addInfiniteScroll(block: @escaping () -> Void) {
        base.fw_addInfiniteScroll(block: block)
    }
    
    public func addInfiniteScroll(target: Any, action: Selector) {
        base.fw_addInfiniteScroll(target: target, action: action)
    }
    
    public func triggerInfiniteScroll() {
        base.fw_triggerInfiniteScroll()
    }

    public var infiniteScrollView: InfiniteScrollView? {
        return base.fw_infiniteScrollView
    }
    
    public var showInfiniteScroll: Bool {
        get { return base.fw_showInfiniteScroll }
        set { base.fw_showInfiniteScroll = newValue }
    }
    
    public var infiniteScrollFinished: Bool {
        get { return base.fw_infiniteScrollFinished }
        set { base.fw_infiniteScrollFinished = newValue }
    }
}

// MARK: - RefreshPlugin
/// 刷新插件协议，应用可自定义刷新插件实现
public protocol RefreshPlugin: AnyObject {

    // MARK: - Refreshing
    /// 是否正在刷新中
    func isRefreshing(in scrollView: UIScrollView) -> Bool

    /// 是否显示刷新组件
    func shouldRefreshing(in scrollView: UIScrollView) -> Bool

    /// 设置是否显示刷新组件
    func setShouldRefreshing(_ shouldRefreshing: Bool, in scrollView: UIScrollView)

    /// 配置下拉刷新句柄
    func setRefreshing(block: @escaping () -> Void, customBlock: ((Any) -> Void)?, in scrollView: UIScrollView)

    /// 配置下拉刷新事件
    func setRefreshing(target: Any, action: Selector, customBlock: ((Any) -> Void)?, in scrollView: UIScrollView)

    /// 开始下拉刷新
    func beginRefreshing(in scrollView: UIScrollView)

    /// 结束下拉刷新
    func endRefreshing(in scrollView: UIScrollView)

    // MARK: - Loading
    /// 是否正在追加中
    func isLoading(in scrollView: UIScrollView) -> Bool

    /// 是否显示追加组件
    func shouldLoading(in scrollView: UIScrollView) -> Bool

    /// 设置是否显示追加组件
    func setShouldLoading(_ shouldLoading: Bool, in scrollView: UIScrollView)

    /// 是否已追加完成，不能继续追加
    func loadingFinished(in scrollView: UIScrollView) -> Bool

    /// 设置是否已追加完成，不能继续追加
    func setLoadingFinished(_ loadingFinished: Bool, in scrollView: UIScrollView)

    /// 配置上拉追加句柄
    func setLoading(block: @escaping () -> Void, customBlock: ((Any) -> Void)?, in scrollView: UIScrollView)

    /// 配置上拉追加事件
    func setLoading(target: Any, action: Selector, customBlock: ((Any) -> Void)?, in scrollView: UIScrollView)

    /// 开始上拉追加
    func beginLoading(in scrollView: UIScrollView)

    /// 结束上拉追加
    func endLoading(in scrollView: UIScrollView)
    
}

extension RefreshPlugin {
    
    // MARK: - Refreshing
    /// 默认实现，是否正在刷新中
    public func isRefreshing(in scrollView: UIScrollView) -> Bool {
        return RefreshPluginImpl.shared.isRefreshing(in: scrollView)
    }

    /// 默认实现，是否显示刷新组件
    public func shouldRefreshing(in scrollView: UIScrollView) -> Bool {
        return RefreshPluginImpl.shared.shouldRefreshing(in: scrollView)
    }

    /// 默认实现，设置是否显示刷新组件
    public func setShouldRefreshing(_ shouldRefreshing: Bool, in scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setShouldRefreshing(shouldRefreshing, in: scrollView)
    }

    /// 默认实现，配置下拉刷新句柄
    public func setRefreshing(block: @escaping () -> Void, customBlock: ((Any) -> Void)?, in scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setRefreshing(block: block, customBlock: customBlock, in: scrollView)
    }

    /// 默认实现，配置下拉刷新事件
    public func setRefreshing(target: Any, action: Selector, customBlock: ((Any) -> Void)?, in scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setRefreshing(target: target, action: action, customBlock: customBlock, in: scrollView)
    }

    /// 默认实现，开始下拉刷新
    public func beginRefreshing(in scrollView: UIScrollView) {
        RefreshPluginImpl.shared.beginRefreshing(in: scrollView)
    }

    /// 默认实现，结束下拉刷新
    public func endRefreshing(in scrollView: UIScrollView) {
        RefreshPluginImpl.shared.endRefreshing(in: scrollView)
    }

    // MARK: - Loading
    /// 默认实现，是否正在追加中
    public func isLoading(in scrollView: UIScrollView) -> Bool {
        return RefreshPluginImpl.shared.isLoading(in: scrollView)
    }

    /// 默认实现，是否显示追加组件
    public func shouldLoading(in scrollView: UIScrollView) -> Bool {
        return RefreshPluginImpl.shared.shouldLoading(in: scrollView)
    }

    /// 默认实现，设置是否显示追加组件
    public func setShouldLoading(_ shouldLoading: Bool, in scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setShouldLoading(shouldLoading, in: scrollView)
    }

    /// 默认实现，是否已追加完成，不能继续追加
    public func loadingFinished(in scrollView: UIScrollView) -> Bool {
        return RefreshPluginImpl.shared.loadingFinished(in: scrollView)
    }

    /// 默认实现，设置是否已追加完成，不能继续追加
    public func setLoadingFinished(_ loadingFinished: Bool, in scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setLoadingFinished(loadingFinished, in: scrollView)
    }

    /// 默认实现，配置上拉追加句柄
    public func setLoading(block: @escaping () -> Void, customBlock: ((Any) -> Void)?, in scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setLoading(block: block, customBlock: customBlock, in: scrollView)
    }

    /// 默认实现，配置上拉追加事件
    public func setLoading(target: Any, action: Selector, customBlock: ((Any) -> Void)?, in scrollView: UIScrollView) {
        RefreshPluginImpl.shared.setLoading(target: target, action: action, customBlock: customBlock, in: scrollView)
    }

    /// 默认实现，开始上拉追加
    public func beginLoading(in scrollView: UIScrollView) {
        RefreshPluginImpl.shared.beginLoading(in: scrollView)
    }

    /// 默认实现，结束上拉追加
    public func endLoading(in scrollView: UIScrollView) {
        RefreshPluginImpl.shared.endLoading(in: scrollView)
    }
    
}

// MARK: - UIScrollView+RefreshPlugin
@_spi(FW) extension UIScrollView {
    
    /// 自定义刷新插件，未设置时自动从插件池加载
    public var fw_refreshPlugin: RefreshPlugin! {
        get {
            if let refreshPlugin = fw.property(forName: "fw_refreshPlugin") as? RefreshPlugin {
                return refreshPlugin
            } else if let refreshPlugin = PluginManager.loadPlugin(RefreshPlugin.self) {
                return refreshPlugin
            }
            return RefreshPluginImpl.shared
        }
        set {
            fw.setProperty(newValue, forName: "fw_refreshPlugin")
        }
    }

    // MARK: - Refreshing
    /// 是否正在刷新中
    public var fw_isRefreshing: Bool {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        return plugin.isRefreshing(in: self)
    }

    /// 是否显示刷新组件
    public var fw_shouldRefreshing: Bool {
        get {
            let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
            return plugin.shouldRefreshing(in: self)
        }
        set {
            let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
            plugin.setShouldRefreshing(newValue, in: self)
        }
    }

    /// 配置下拉刷新句柄
    public func fw_setRefreshing(block: @escaping () -> Void, customBlock: ((Any) -> Void)? = nil) {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.setRefreshing(block: block, customBlock: customBlock, in: self)
    }

    /// 配置下拉刷新事件
    public func fw_setRefreshing(target: Any, action: Selector, customBlock: ((Any) -> Void)? = nil) {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.setRefreshing(target: target, action: action, customBlock: customBlock, in: self)
    }

    /// 开始下拉刷新
    public func fw_beginRefreshing() {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.beginRefreshing(in: self)
    }

    /// 结束下拉刷新
    public func fw_endRefreshing() {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.endRefreshing(in: self)
    }
    
    /// 结束下拉刷新并标记是否加载完成，需在reloadData之后调用
    public func fw_endRefreshing(finished: Bool) {
        self.fw_endRefreshing()
        self.fw_loadingFinished = finished
    }

    // MARK: - Loading
    /// 是否正在追加中
    public var fw_isLoading: Bool {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        return plugin.isLoading(in: self)
    }

    /// 是否显示追加组件
    public var fw_shouldLoading: Bool {
        get {
            let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
            return plugin.shouldLoading(in: self)
        }
        set {
            let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
            plugin.setShouldLoading(newValue, in: self)
        }
    }
    
    /// 是否已加载完成，不能继续追加，需在reloadData之后调用
    public var fw_loadingFinished: Bool {
        get {
            let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
            return plugin.loadingFinished(in: self)
        }
        set {
            let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
            plugin.setLoadingFinished(newValue, in: self)
        }
    }

    /// 配置上拉追加句柄
    public func fw_setLoading(block: @escaping () -> Void, customBlock: ((Any) -> Void)? = nil) {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.setLoading(block: block, customBlock: customBlock, in: self)
    }

    /// 配置上拉追加事件
    public func fw_setLoading(target: Any, action: Selector, customBlock: ((Any) -> Void)? = nil) {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.setLoading(target: target, action: action, customBlock: customBlock, in: self)
    }

    /// 开始上拉追加
    public func fw_beginLoading() {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.beginLoading(in: self)
    }

    /// 结束上拉追加
    public func fw_endLoading() {
        let plugin = self.fw_refreshPlugin ?? RefreshPluginImpl.shared
        plugin.endLoading(in: self)
    }
    
    /// 结束上拉追加并标记是否加载完成，需在reloadData之后调用
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
        
        let view = PullRefreshView()
        view.frame = CGRect(x: 0, y: -view.height, width: self.bounds.size.width, height: view.height)
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
            return fw.property(forName: "fw_pullRefreshView") as? PullRefreshView
        }
        set {
            fw.setProperty(newValue, forName: "fw_pullRefreshView")
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
                    self.panGestureRecognizer.fw.unobserveProperty(\.state, target: pullRefreshView, action: #selector(PullRefreshView.gestureRecognizerStateChanged(_:)))
                    pullRefreshView.resetScrollViewContentInset(animated: false)
                    pullRefreshView.isObserving = false
                }
            } else {
                if !pullRefreshView.isObserving {
                    self.addObserver(pullRefreshView, forKeyPath: "contentOffset", options: .new, context: nil)
                    self.addObserver(pullRefreshView, forKeyPath: "contentSize", options: .new, context: nil)
                    self.addObserver(pullRefreshView, forKeyPath: "frame", options: .new, context: nil)
                    self.panGestureRecognizer.fw.observeProperty(\.state, target: pullRefreshView, action: #selector(pullRefreshView.gestureRecognizerStateChanged(_:)))
                    pullRefreshView.isObserving = true
                    
                    pullRefreshView.setNeedsLayout()
                    pullRefreshView.layoutIfNeeded()
                    pullRefreshView.frame = CGRect(x: 0, y: -pullRefreshView.height, width: self.bounds.size.width, height: pullRefreshView.height)
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
        
        let view = InfiniteScrollView()
        view.frame = CGRect(x: 0, y: self.contentSize.height, width: self.bounds.size.width, height: view.height)
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
            return fw.property(forName: "fw_infiniteScrollView") as? InfiniteScrollView
        }
        set {
            fw.setProperty(newValue, forName: "fw_infiniteScrollView")
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
                    self.panGestureRecognizer.fw.unobserveProperty(\.state, target: infiniteScrollView, action: #selector(InfiniteScrollView.gestureRecognizerStateChanged(_:)))
                    infiniteScrollView.resetScrollViewContentInset(animated: false)
                    infiniteScrollView.isObserving = false
                }
            } else {
                if !infiniteScrollView.isObserving {
                    self.addObserver(infiniteScrollView, forKeyPath: "contentOffset", options: .new, context: nil)
                    self.addObserver(infiniteScrollView, forKeyPath: "contentSize", options: .new, context: nil)
                    self.panGestureRecognizer.fw.observeProperty(\.state, target: infiniteScrollView, action: #selector(InfiniteScrollView.gestureRecognizerStateChanged(_:)))
                    infiniteScrollView.setScrollViewContentInsetForInfiniteScrolling(animated: false)
                    infiniteScrollView.isObserving = true
                    
                    infiniteScrollView.setNeedsLayout()
                    infiniteScrollView.layoutIfNeeded()
                    infiniteScrollView.frame = CGRect(x: 0, y: self.contentSize.height, width: infiniteScrollView.bounds.size.width, height: infiniteScrollView.height)
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

//
//  RefreshPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UIScrollView
@MainActor extension Wrapper where Base: UIScrollView {
    /// 自定义刷新插件，未设置时自动从插件池加载
    public var refreshPlugin: RefreshPlugin! {
        get {
            if let refreshPlugin = property(forName: "refreshPlugin") as? RefreshPlugin {
                return refreshPlugin
            } else if let refreshPlugin = PluginManager.loadPlugin(RefreshPlugin.self) {
                return refreshPlugin
            }
            return RefreshPluginImpl.shared
        }
        set {
            setProperty(newValue, forName: "refreshPlugin")
        }
    }

    // MARK: - Refreshing
    /// 是否正在刷新中
    public var isRefreshing: Bool {
        let plugin = refreshPlugin ?? RefreshPluginImpl.shared
        return plugin.isRefreshing(in: base)
    }

    /// 是否显示刷新组件
    public var shouldRefreshing: Bool {
        get {
            let plugin = refreshPlugin ?? RefreshPluginImpl.shared
            return plugin.shouldRefreshing(in: base)
        }
        set {
            let plugin = refreshPlugin ?? RefreshPluginImpl.shared
            plugin.setShouldRefreshing(newValue, in: base)
        }
    }

    /// 配置下拉刷新句柄
    public func setRefreshing(block: @escaping () -> Void, customBlock: ((Any) -> Void)? = nil) {
        let plugin = refreshPlugin ?? RefreshPluginImpl.shared
        plugin.setRefreshing(block: block, customBlock: customBlock, in: base)
    }

    /// 配置下拉刷新事件
    public func setRefreshing(target: Any, action: Selector, customBlock: ((Any) -> Void)? = nil) {
        let plugin = refreshPlugin ?? RefreshPluginImpl.shared
        plugin.setRefreshing(target: target, action: action, customBlock: customBlock, in: base)
    }

    /// 开始下拉刷新
    public func beginRefreshing() {
        let plugin = refreshPlugin ?? RefreshPluginImpl.shared
        plugin.beginRefreshing(in: base)
    }

    /// 结束下拉刷新
    public func endRefreshing() {
        let plugin = refreshPlugin ?? RefreshPluginImpl.shared
        plugin.endRefreshing(in: base)
    }
    
    /// 结束下拉刷新并标记是否加载完成，需在reloadData之后调用
    public func endRefreshing(finished: Bool) {
        endRefreshing()
        loadingFinished = finished
    }

    // MARK: - Loading
    /// 是否正在追加中
    public var isLoading: Bool {
        let plugin = refreshPlugin ?? RefreshPluginImpl.shared
        return plugin.isLoading(in: base)
    }

    /// 是否显示追加组件
    public var shouldLoading: Bool {
        get {
            let plugin = refreshPlugin ?? RefreshPluginImpl.shared
            return plugin.shouldLoading(in: base)
        }
        set {
            let plugin = refreshPlugin ?? RefreshPluginImpl.shared
            plugin.setShouldLoading(newValue, in: base)
        }
    }
    
    /// 是否已加载完成，不能继续追加，需在reloadData之后调用
    public var loadingFinished: Bool {
        get {
            let plugin = refreshPlugin ?? RefreshPluginImpl.shared
            return plugin.loadingFinished(in: base)
        }
        set {
            let plugin = refreshPlugin ?? RefreshPluginImpl.shared
            plugin.setLoadingFinished(newValue, in: base)
        }
    }

    /// 配置上拉追加句柄
    public func setLoading(block: @escaping () -> Void, customBlock: ((Any) -> Void)? = nil) {
        let plugin = refreshPlugin ?? RefreshPluginImpl.shared
        plugin.setLoading(block: block, customBlock: customBlock, in: base)
    }

    /// 配置上拉追加事件
    public func setLoading(target: Any, action: Selector, customBlock: ((Any) -> Void)? = nil) {
        let plugin = refreshPlugin ?? RefreshPluginImpl.shared
        plugin.setLoading(target: target, action: action, customBlock: customBlock, in: base)
    }

    /// 开始上拉追加
    public func beginLoading() {
        let plugin = refreshPlugin ?? RefreshPluginImpl.shared
        plugin.beginLoading(in: base)
    }

    /// 结束上拉追加
    public func endLoading() {
        let plugin = refreshPlugin ?? RefreshPluginImpl.shared
        plugin.endLoading(in: base)
    }
    
    /// 结束上拉追加并标记是否加载完成，需在reloadData之后调用
    public func endLoading(finished: Bool) {
        endLoading()
        loadingFinished = finished
    }
}

// MARK: - Wrapper+UIScrollView
@MainActor extension Wrapper where Base: UIScrollView {
    public func addPullRefresh(block: @escaping () -> Void) {
        addPullRefresh(block: block, target: nil, action: nil)
    }
    
    public func addPullRefresh(target: Any, action: Selector) {
        addPullRefresh(block: nil, target: target, action: action)
    }
    
    private func addPullRefresh(block: (() -> Void)?, target: Any?, action: Selector?) {
        pullRefreshView?.removeFromSuperview()
        
        let view = PullRefreshView()
        view.frame = CGRect(x: 0, y: -view.height, width: base.bounds.size.width, height: view.height)
        view.pullRefreshBlock = block
        view.target = target as? AnyObject
        view.action = action
        view.scrollView = base
        base.addSubview(view)
        
        view.originalInset = base.contentInset
        pullRefreshView = view
        showPullRefresh = true
    }
    
    public func triggerPullRefresh() {
        if pullRefreshView?.isAnimating ?? false { return }
        
        pullRefreshView?.state = .triggered
        pullRefreshView?.userTriggered = false
        pullRefreshView?.startAnimating()
    }

    public var pullRefreshView: PullRefreshView? {
        get {
            return property(forName: "pullRefreshView") as? PullRefreshView
        }
        set {
            setProperty(newValue, forName: "pullRefreshView")
        }
    }
    
    public var showPullRefresh: Bool {
        get {
            if let pullRefreshView = pullRefreshView {
                return !pullRefreshView.isHidden
            }
            return false
        }
        set {
            guard let pullRefreshView = pullRefreshView else { return }
            
            pullRefreshView.isHidden = !newValue
            if !newValue {
                if pullRefreshView.isObserving {
                    base.removeObserver(pullRefreshView, forKeyPath: "contentOffset")
                    base.removeObserver(pullRefreshView, forKeyPath: "contentSize")
                    base.removeObserver(pullRefreshView, forKeyPath: "frame")
                    base.panGestureRecognizer.fw.unobserveProperty(\.state, target: pullRefreshView, action: #selector(PullRefreshView.gestureRecognizerStateChanged(_:)))
                    pullRefreshView.resetScrollViewContentInset(animated: false)
                    pullRefreshView.isObserving = false
                }
            } else {
                if !pullRefreshView.isObserving {
                    base.addObserver(pullRefreshView, forKeyPath: "contentOffset", options: .new, context: nil)
                    base.addObserver(pullRefreshView, forKeyPath: "contentSize", options: .new, context: nil)
                    base.addObserver(pullRefreshView, forKeyPath: "frame", options: .new, context: nil)
                    base.panGestureRecognizer.fw.observeProperty(\.state, target: pullRefreshView, action: #selector(pullRefreshView.gestureRecognizerStateChanged(_:)))
                    pullRefreshView.isObserving = true
                    
                    pullRefreshView.setNeedsLayout()
                    pullRefreshView.layoutIfNeeded()
                    pullRefreshView.frame = CGRect(x: 0, y: -pullRefreshView.height, width: base.bounds.size.width, height: pullRefreshView.height)
                }
            }
        }
    }
    
    public func addInfiniteScroll(block: @escaping () -> Void) {
        addInfiniteScroll(block: block, target: nil, action: nil)
    }
    
    public func addInfiniteScroll(target: Any, action: Selector) {
        addInfiniteScroll(block: nil, target: target, action: action)
    }
    
    private func addInfiniteScroll(block: (() -> Void)?, target: Any?, action: Selector?) {
        infiniteScrollView?.removeFromSuperview()
        
        let view = InfiniteScrollView()
        view.frame = CGRect(x: 0, y: base.contentSize.height, width: base.bounds.size.width, height: view.height)
        view.infiniteScrollBlock = block
        view.target = target as? AnyObject
        view.action = action
        view.scrollView = base
        base.addSubview(view)
        
        view.originalInset = base.contentInset
        infiniteScrollView = view
        showInfiniteScroll = true
    }
    
    public func triggerInfiniteScroll() {
        if infiniteScrollView?.isAnimating ?? false { return }
        if infiniteScrollView?.finished ?? false { return }
        
        infiniteScrollView?.state = .triggered
        infiniteScrollView?.userTriggered = false
        infiniteScrollView?.startAnimating()
    }

    public var infiniteScrollView: InfiniteScrollView? {
        get {
            return property(forName: "infiniteScrollView") as? InfiniteScrollView
        }
        set {
            setProperty(newValue, forName: "infiniteScrollView")
        }
    }
    
    public var showInfiniteScroll: Bool {
        get {
            if let infiniteScrollView = infiniteScrollView {
                return !infiniteScrollView.isHidden
            }
            return false
        }
        set {
            guard let infiniteScrollView = infiniteScrollView else { return }
            
            infiniteScrollView.isHidden = !newValue
            if !newValue {
                if infiniteScrollView.isObserving {
                    base.removeObserver(infiniteScrollView, forKeyPath: "contentOffset")
                    base.removeObserver(infiniteScrollView, forKeyPath: "contentSize")
                    base.panGestureRecognizer.fw.unobserveProperty(\.state, target: infiniteScrollView, action: #selector(InfiniteScrollView.gestureRecognizerStateChanged(_:)))
                    infiniteScrollView.resetScrollViewContentInset(animated: false)
                    infiniteScrollView.isObserving = false
                }
            } else {
                if !infiniteScrollView.isObserving {
                    base.addObserver(infiniteScrollView, forKeyPath: "contentOffset", options: .new, context: nil)
                    base.addObserver(infiniteScrollView, forKeyPath: "contentSize", options: .new, context: nil)
                    base.panGestureRecognizer.fw.observeProperty(\.state, target: infiniteScrollView, action: #selector(InfiniteScrollView.gestureRecognizerStateChanged(_:)))
                    infiniteScrollView.setScrollViewContentInsetForInfiniteScrolling(animated: false)
                    infiniteScrollView.isObserving = true
                    
                    infiniteScrollView.setNeedsLayout()
                    infiniteScrollView.layoutIfNeeded()
                    infiniteScrollView.frame = CGRect(x: 0, y: base.contentSize.height, width: infiniteScrollView.bounds.size.width, height: infiniteScrollView.height)
                }
            }
        }
    }
    
    public var infiniteScrollFinished: Bool {
        get {
            return infiniteScrollView?.finished ?? false
        }
        set {
            infiniteScrollView?.finished = newValue
        }
    }
}

// MARK: - RefreshPlugin
/// 刷新插件协议，应用可自定义刷新插件实现
@MainActor public protocol RefreshPlugin: AnyObject {

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

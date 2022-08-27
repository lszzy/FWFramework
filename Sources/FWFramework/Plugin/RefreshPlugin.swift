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

extension Wrapper where Base: UIScrollView {
    
    /// 自定义刷新插件，未设置时自动从插件池加载
    public var refreshPlugin: RefreshPlugin? {
        get { return base.__fw_refreshPlugin }
        set { base.__fw_refreshPlugin = newValue }
    }

    // MARK: - Refreshing

    /// 是否正在刷新中
    public var isRefreshing: Bool {
        return base.__fw_isRefreshing
    }

    /// 是否显示刷新组件
    public var shouldRefreshing: Bool {
        get { return base.__fw_shouldRefreshing }
        set { base.__fw_shouldRefreshing = newValue }
    }

    /// 配置下拉刷新句柄
    public func setRefreshing(block: @escaping () -> Void) {
        base.__fw_setRefreshingBlock(block)
    }

    /// 配置下拉刷新事件
    public func setRefreshing(target: Any, action: Selector) {
        base.__fw_setRefreshingTarget(target, action: action)
    }

    /// 开始下拉刷新
    public func beginRefreshing() {
        base.__fw_beginRefreshing()
    }

    /// 结束下拉刷新
    public func endRefreshing() {
        base.__fw_endRefreshing()
    }

    // MARK: - Loading

    /// 是否正在追加中
    public var isLoading: Bool {
        return base.__fw_isLoading
    }

    /// 是否显示追加组件
    public var shouldLoading: Bool {
        get { return base.__fw_shouldLoading }
        set { base.__fw_shouldLoading = newValue }
    }
    
    /// 是否已加载完成，不能继续追加
    public var loadingFinished: Bool {
        get { return base.__fw_loadingFinished }
        set { base.__fw_loadingFinished = newValue }
    }

    /// 配置上拉追加句柄
    public func setLoading(block: @escaping () -> Void) {
        base.__fw_setLoading(block)
    }

    /// 配置上拉追加事件
    public func setLoading(target: Any, action: Selector) {
        base.__fw_setLoadingTarget(target, action: action)
    }

    /// 开始上拉追加
    public func beginLoading() {
        base.__fw_beginLoading()
    }

    /// 结束上拉追加
    public func endLoading() {
        base.__fw_endLoading()
    }
    
}

extension Wrapper where Base: UIScrollView {
    
    public func addPullRefresh(block: @escaping () -> Void) {
        base.__fw_addPullRefresh(block)
    }
    
    public func addPullRefresh(target: Any, action: Selector) {
        base.__fw_addPullRefresh(withTarget: target, action: action)
    }
    
    public func triggerPullRefresh() {
        base.__fw_triggerPullRefresh()
    }

    public var pullRefreshView: PullRefreshView? {
        return base.__fw_pullRefreshView
    }
    
    public var pullRefreshHeight: CGFloat {
        get { return base.__fw_pullRefreshHeight }
        set { base.__fw_pullRefreshHeight = newValue }
    }
    
    public var showPullRefresh: Bool {
        get { return base.__fw_showPullRefresh }
        set { base.__fw_showPullRefresh = newValue }
    }
    
    public func addInfiniteScroll(block: @escaping () -> Void) {
        base.__fw_addInfiniteScroll(block)
    }
    
    public func addInfiniteScroll(target: Any, action: Selector) {
        base.__fw_addInfiniteScroll(withTarget: target, action: action)
    }
    
    public func triggerInfiniteScroll() {
        base.__fw_triggerInfiniteScroll()
    }

    public var infiniteScrollView: InfiniteScrollView? {
        return base.__fw_infiniteScrollView
    }
    
    public var infiniteScrollHeight: CGFloat {
        get { return base.__fw_infiniteScrollHeight }
        set { base.__fw_infiniteScrollHeight = newValue }
    }
    
    public var showInfiniteScroll: Bool {
        get { return base.__fw_showInfiniteScroll }
        set { base.__fw_showInfiniteScroll = newValue }
    }
    
    public var infiniteScrollFinished: Bool {
        get { return base.__fw_infiniteScrollFinished }
        set { base.__fw_infiniteScrollFinished = newValue }
    }
    
}

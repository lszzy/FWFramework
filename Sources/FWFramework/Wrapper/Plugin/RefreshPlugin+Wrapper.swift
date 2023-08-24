//
//  RefreshPlugin+Wrapper.swift
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
    public func setRefreshing(block: @escaping () -> Void) {
        base.fw_setRefreshing(block: block)
    }

    /// 配置下拉刷新事件
    public func setRefreshing(target: Any, action: Selector) {
        base.fw_setRefreshing(target: target, action: action)
    }

    /// 开始下拉刷新
    public func beginRefreshing() {
        base.fw_beginRefreshing()
    }

    /// 结束下拉刷新
    public func endRefreshing() {
        base.fw_endRefreshing()
    }
    
    /// 结束下拉刷新并标记是否加载完成
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
    
    /// 是否已加载完成，不能继续追加
    public var loadingFinished: Bool {
        get { return base.fw_loadingFinished }
        set { base.fw_loadingFinished = newValue }
    }

    /// 配置上拉追加句柄
    public func setLoading(block: @escaping () -> Void) {
        base.fw_setLoading(block: block)
    }

    /// 配置上拉追加事件
    public func setLoading(target: Any, action: Selector) {
        base.fw_setLoading(target: target, action: action)
    }

    /// 开始上拉追加
    public func beginLoading() {
        base.fw_beginLoading()
    }

    /// 结束上拉追加
    public func endLoading() {
        base.fw_endLoading()
    }
    
    /// 结束上拉追加并标记是否加载完成
    public func endLoading(finished: Bool) {
        base.fw_endLoading(finished: finished)
    }
    
}

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
    
    public var pullRefreshHeight: CGFloat {
        get { return base.fw_pullRefreshHeight }
        set { base.fw_pullRefreshHeight = newValue }
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
    
    public var infiniteScrollHeight: CGFloat {
        get { return base.fw_infiniteScrollHeight }
        set { base.fw_infiniteScrollHeight = newValue }
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

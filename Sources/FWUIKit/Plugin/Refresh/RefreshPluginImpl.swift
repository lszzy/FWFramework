//
//  RefreshPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

/// 默认刷新插件
open class RefreshPluginImpl: NSObject, RefreshPlugin, @unchecked Sendable {
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = RefreshPluginImpl()

    /// 上拉追加是否显示完成视图，默认true
    open var showsFinishedView = true

    /// 下拉刷新自定义句柄，开启时自动调用
    open var pullRefreshBlock: (@MainActor @Sendable (PullRefreshView) -> Void)?

    /// 上拉追加自定义句柄，开启时自动调用
    open var infiniteScrollBlock: (@MainActor @Sendable (InfiniteScrollView) -> Void)?

    // MARK: - RefreshPlugin
    open func isRefreshing(in scrollView: UIScrollView) -> Bool {
        scrollView.fw.pullRefreshView?.state == .loading
    }

    open func shouldRefreshing(in scrollView: UIScrollView) -> Bool {
        scrollView.fw.showPullRefresh
    }

    open func setShouldRefreshing(_ shouldRefreshing: Bool, in scrollView: UIScrollView) {
        scrollView.fw.showPullRefresh = shouldRefreshing
    }

    open func setRefreshing(block: @escaping @MainActor @Sendable () -> Void, customBlock: (@MainActor @Sendable (Any) -> Void)?, in scrollView: UIScrollView) {
        scrollView.fw.addPullRefresh(block: block)

        if let pullRefreshView = scrollView.fw.pullRefreshView {
            pullRefreshBlock?(pullRefreshView)
            customBlock?(pullRefreshView)
        }
    }

    open func setRefreshing(target: Any, action: Selector, customBlock: (@MainActor @Sendable (Any) -> Void)?, in scrollView: UIScrollView) {
        scrollView.fw.addPullRefresh(target: target, action: action)

        if let pullRefreshView = scrollView.fw.pullRefreshView {
            pullRefreshBlock?(pullRefreshView)
            customBlock?(pullRefreshView)
        }
    }

    open func beginRefreshing(in scrollView: UIScrollView) {
        scrollView.fw.triggerPullRefresh()
    }

    open func endRefreshing(in scrollView: UIScrollView) {
        scrollView.fw.pullRefreshView?.stopAnimating()
    }

    open func isLoading(in scrollView: UIScrollView) -> Bool {
        scrollView.fw.infiniteScrollView?.state == .loading
    }

    open func shouldLoading(in scrollView: UIScrollView) -> Bool {
        scrollView.fw.showInfiniteScroll
    }

    open func setShouldLoading(_ shouldLoading: Bool, in scrollView: UIScrollView) {
        scrollView.fw.showInfiniteScroll = shouldLoading
    }

    open func loadingFinished(in scrollView: UIScrollView) -> Bool {
        scrollView.fw.infiniteScrollFinished
    }

    open func setLoadingFinished(_ loadingFinished: Bool, in scrollView: UIScrollView) {
        scrollView.fw.infiniteScrollFinished = loadingFinished
    }

    open func setLoading(block: @escaping @MainActor @Sendable () -> Void, customBlock: (@MainActor @Sendable (Any) -> Void)?, in scrollView: UIScrollView) {
        scrollView.fw.addInfiniteScroll(block: block)

        if let infiniteScrollView = scrollView.fw.infiniteScrollView {
            infiniteScrollView.showsFinishedView = showsFinishedView
            infiniteScrollBlock?(infiniteScrollView)
            customBlock?(infiniteScrollView)
        }
    }

    open func setLoading(target: Any, action: Selector, customBlock: (@MainActor @Sendable (Any) -> Void)?, in scrollView: UIScrollView) {
        scrollView.fw.addInfiniteScroll(target: target, action: action)

        if let infiniteScrollView = scrollView.fw.infiniteScrollView {
            infiniteScrollView.showsFinishedView = showsFinishedView
            infiniteScrollBlock?(infiniteScrollView)
            customBlock?(infiniteScrollView)
        }
    }

    open func beginLoading(in scrollView: UIScrollView) {
        scrollView.fw.triggerInfiniteScroll()
    }

    open func endLoading(in scrollView: UIScrollView) {
        scrollView.fw.infiniteScrollView?.stopAnimating()
    }
}

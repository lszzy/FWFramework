//
//  RefreshPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

/// 默认刷新插件
open class RefreshPluginImpl: NSObject, RefreshPlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = RefreshPluginImpl()
    
    /// 下拉刷新自定义句柄，开启时自动调用
    open var pullRefreshBlock: ((PullRefreshView) -> Void)?
    
    /// 上拉追加自定义句柄，开启时自动调用
    open var infiniteScrollBlock: ((InfiniteScrollView) -> Void)?
    
    // MARK: - RefreshPlugin
    open func isRefreshing(scrollView: UIScrollView) -> Bool {
        return scrollView.fw_pullRefreshView?.state == .loading
    }
    
    open func shouldRefreshing(scrollView: UIScrollView) -> Bool {
        return scrollView.fw_showPullRefresh
    }
    
    open func setShouldRefreshing(_ shouldRefreshing: Bool, scrollView: UIScrollView) {
        scrollView.fw_showPullRefresh = shouldRefreshing
    }
    
    open func setRefreshing(block: @escaping () -> Void, customBlock: ((Any) -> Void)?, scrollView: UIScrollView) {
        scrollView.fw_addPullRefresh(block: block)
        if let pullRefreshView = scrollView.fw_pullRefreshView {
            pullRefreshBlock?(pullRefreshView)
            customBlock?(pullRefreshView)
        }
    }
    
    open func setRefreshing(target: Any, action: Selector, customBlock: ((Any) -> Void)?, scrollView: UIScrollView) {
        scrollView.fw_addPullRefresh(target: target, action: action)
        if let pullRefreshView = scrollView.fw_pullRefreshView {
            pullRefreshBlock?(pullRefreshView)
            customBlock?(pullRefreshView)
        }
    }
    
    open func beginRefreshing(scrollView: UIScrollView) {
        scrollView.fw_triggerPullRefresh()
    }
    
    open func endRefreshing(scrollView: UIScrollView) {
        scrollView.fw_pullRefreshView?.stopAnimating()
    }
    
    open func isLoading(scrollView: UIScrollView) -> Bool {
        return scrollView.fw_infiniteScrollView?.state == .loading
    }
    
    open func shouldLoading(scrollView: UIScrollView) -> Bool {
        return scrollView.fw_showInfiniteScroll
    }
    
    open func setShouldLoading(_ shouldLoading: Bool, scrollView: UIScrollView) {
        scrollView.fw_showInfiniteScroll = shouldLoading
    }
    
    open func loadingFinished(scrollView: UIScrollView) -> Bool {
        return scrollView.fw_infiniteScrollFinished
    }
    
    open func setLoadingFinished(_ loadingFinished: Bool, scrollView: UIScrollView) {
        scrollView.fw_infiniteScrollFinished = loadingFinished
    }
    
    open func setLoading(block: @escaping () -> Void, customBlock: ((Any) -> Void)?, scrollView: UIScrollView) {
        scrollView.fw_addInfiniteScroll(block: block)
        if let infiniteScrollView = scrollView.fw_infiniteScrollView {
            infiniteScrollBlock?(infiniteScrollView)
            customBlock?(infiniteScrollView)
        }
    }
    
    open func setLoading(target: Any, action: Selector, customBlock: ((Any) -> Void)?, scrollView: UIScrollView) {
        scrollView.fw_addInfiniteScroll(target: target, action: action)
        if let infiniteScrollView = scrollView.fw_infiniteScrollView {
            infiniteScrollBlock?(infiniteScrollView)
            customBlock?(infiniteScrollView)
        }
    }
    
    open func beginLoading(scrollView: UIScrollView) {
        scrollView.fw_triggerInfiniteScroll()
    }
    
    open func endLoading(scrollView: UIScrollView) {
        scrollView.fw_infiniteScrollView?.stopAnimating()
    }
    
}

//
//  ScrollView+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - ScrollView+Toolkit
@available(iOS 13.0, *)
extension View {
    
    /// 配置ScrollView视图，仅调用一次，一般用于绑定下拉刷新、上拉追加等
    public func scrollViewConfigure(
        _ configuration: @escaping (UIScrollView) -> Void
    ) -> some View {
        return introspectScrollView { scrollView in
            guard scrollView.fw.property(forName: "scrollViewConfigure") == nil else { return }
            scrollView.fw.setProperty(NSNumber(value: true), forName: "scrollViewConfigure")
            
            configuration(scrollView)
        }
    }
    
    /// 绑定ScrollView下拉刷新插件，action必须调用completionHandler
    public func scrollViewRefreshing(
        shouldBegin: Binding<Bool>? = nil,
        action: @escaping (@escaping () -> Void) -> Void,
        customize: ((UIScrollView) -> Void)? = nil
    ) -> some View {
        return introspectScrollView { scrollView in
            if scrollView.fw.property(forName: "scrollViewRefreshing") == nil {
                scrollView.fw.setProperty(NSNumber(value: true), forName: "scrollViewRefreshing")
                
                scrollView.fw.setRefreshing { [weak scrollView] in
                    action({
                        scrollView?.fw.endRefreshing()
                    })
                }
                customize?(scrollView)
            }
            
            if shouldBegin?.wrappedValue == true {
                shouldBegin?.wrappedValue = false
                
                if !scrollView.fw.isRefreshing {
                    scrollView.fw.beginRefreshing()
                }
            }
        }
    }
    
    /// 绑定ScrollView上拉追加插件，action必须调用completionHandler，并指定是否已加载完成不能继续追加
    public func scrollViewLoading(
        shouldBegin: Binding<Bool>? = nil,
        shouldLoading: Bool? = nil,
        action: @escaping (@escaping (Bool) -> Void) -> Void,
        customize: ((UIScrollView) -> Void)? = nil
    ) -> some View {
        return introspectScrollView { scrollView in
            if scrollView.fw.property(forName: "scrollViewLoading") == nil {
                scrollView.fw.setProperty(NSNumber(value: true), forName: "scrollViewLoading")
                
                scrollView.fw.setLoading { [weak scrollView] in
                    action({ finished in
                        scrollView?.fw.endLoading()
                        scrollView?.fw.loadingFinished = finished
                    })
                }
                customize?(scrollView)
            }
            
            if let shouldLoading = shouldLoading,
               scrollView.fw.shouldLoading != shouldLoading {
                scrollView.fw.shouldLoading = shouldLoading
            }
            
            if shouldBegin?.wrappedValue == true {
                shouldBegin?.wrappedValue = false
                
                if !scrollView.fw.isLoading {
                    scrollView.fw.beginLoading()
                }
            }
        }
    }
    
    /// 显示ScrollView空界面插件，需手工切换，空界面显示时也可滚动
    public func showScrollEmpty(_ isShowing: Bool, customize: ((UIScrollView) -> Void)? = nil) -> some View {
        return introspectScrollView { scrollView in
            if isShowing {
                if let customize = customize {
                    customize(scrollView)
                } else {
                    scrollView.fw.showEmptyView()
                }
            } else {
                if scrollView.fw.hasEmptyView {
                    scrollView.fw.hideEmptyView()
                }
            }
        }
    }
    
}

#endif
//
//  ScrollView+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - ScrollView+Toolkit
@available(iOS 13.0, *)
extension View {
    
    /// 配置ScrollView视图，仅调用一次，一般用于绑定下拉刷新、上拉追加等
    public func scrollViewConfigure(
        _ configuration: @escaping (UIScrollView) -> Void
    ) -> some View {
        return introspectScrollView { scrollView in
            guard !scrollView.fw_propertyBool(forName: "scrollViewConfigure") else { return }
            scrollView.fw_setPropertyBool(true, forName: "scrollViewConfigure")
            
            configuration(scrollView)
        }
    }
    
    /// 绑定ScrollView下拉刷新插件，action必须调用completionHandler，并指定是否已加载完成不能继续追加
    public func scrollViewRefreshing(
        shouldBegin: Binding<Bool>? = nil,
        action: @escaping (@escaping (_ finished: Bool) -> Void) -> Void,
        customize: ((UIScrollView) -> Void)? = nil
    ) -> some View {
        return introspectScrollView { scrollView in
            if !scrollView.fw_propertyBool(forName: "scrollViewRefreshing") {
                scrollView.fw_setPropertyBool(true, forName: "scrollViewRefreshing")
                
                scrollView.fw_setRefreshing { [weak scrollView] in
                    action({ finished in
                        scrollView?.fw_endRefreshing()
                        scrollView?.fw_loadingFinished = finished
                    })
                }
                customize?(scrollView)
            }
            
            if shouldBegin?.wrappedValue == true {
                shouldBegin?.wrappedValue = false
                
                if !scrollView.fw_isRefreshing {
                    scrollView.fw_beginRefreshing()
                }
            }
        }
    }
    
    /// 绑定ScrollView上拉追加插件，action必须调用completionHandler，并指定是否已加载完成不能继续追加
    public func scrollViewLoading(
        shouldBegin: Binding<Bool>? = nil,
        shouldLoading: Bool? = nil,
        action: @escaping (@escaping (_ finished: Bool) -> Void) -> Void,
        customize: ((UIScrollView) -> Void)? = nil
    ) -> some View {
        return introspectScrollView { scrollView in
            if !scrollView.fw_propertyBool(forName: "scrollViewLoading") {
                scrollView.fw_setPropertyBool(true, forName: "scrollViewLoading")
                
                scrollView.fw_setLoading { [weak scrollView] in
                    action({ finished in
                        scrollView?.fw_endLoading()
                        scrollView?.fw_loadingFinished = finished
                    })
                }
                customize?(scrollView)
            }
            
            if let shouldLoading = shouldLoading,
               scrollView.fw_shouldLoading != shouldLoading {
                scrollView.fw_shouldLoading = shouldLoading
            }
            
            if shouldBegin?.wrappedValue == true {
                shouldBegin?.wrappedValue = false
                
                if !scrollView.fw_isLoading {
                    scrollView.fw_beginLoading()
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
                    scrollView.fw_showEmptyView()
                }
            } else {
                if scrollView.fw_hasEmptyView {
                    scrollView.fw_hideEmptyView()
                }
            }
        }
    }
    
}

#endif

//
//  List+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - List+Toolkit
@available(iOS 13.0, *)
extension View {
    
    /// 重置List样式，去除多余间距等，可指定背景色
    /// - Parameters:
    ///   - background: 自定义背景色，默认nil时不处理
    ///   - isPlainStyle: 是否是plain样式，默认false，如果是则会自动清除iOS16+多余的Header顶部间距
    /// - Returns: View
    public func resetListStyle(background: Color? = nil, isPlainStyle: Bool = false) -> some View {
        self.then(background) { view, color in
                if #available(iOS 16.0, *) {
                    return view.scrollContentBackground(.hidden)
                        .background(color)
                        .eraseToAnyView()
                } else {
                    return view.background(color)
                        .eraseToAnyView()
                }
            }
            .then(isPlainStyle && UIDevice.fw.iosVersion >= 16, body: { view in
                view.introspectCollectionView { collectionView in
                    guard collectionView.fw.property(forName: "resetListStyle") == nil else { return }
                    collectionView.fw.setProperty(NSNumber(value: true), forName: "resetListStyle")
                    
                    if #available(iOS 16.0, *) {
                        guard collectionView.collectionViewLayout is UICollectionViewCompositionalLayout else { return }
                        
                        var layoutConfig = UICollectionLayoutListConfiguration(appearance: .plain)
                        layoutConfig.showsSeparators = false
                        layoutConfig.headerMode = .supplementary
                        layoutConfig.headerTopPadding = 0
                        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
                    }
                }
            })
            .then(UIDevice.fw.iosVersion < 16) { view in
                view.introspectTableView { tableView in
                    if tableView.fw.property(forName: "resetListStyle") == nil {
                        tableView.fw.setProperty(NSNumber(value: true), forName: "resetListStyle")
                        
                        if #available(iOS 15.0, *) {
                            tableView.sectionHeaderTopPadding = 0
                        }
                    }
                    
                    tableView.separatorStyle = .none
                    tableView.separatorColor = .clear
                    if let background = background {
                        tableView.backgroundColor = background.toUIColor()
                    }
                }
            }
            .eraseToAnyView()
    }
    
    /// 重置Header|Footer样式，左对齐并去除多余间距，可指定背景色
    public func resetHeaderStyle(background: Color? = nil) -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .listRowInsets(.zero)
            .then({ view in
                if #available(iOS 15.0, *) {
                    return view.listSectionSeparator(.hidden)
                        .eraseToAnyView()
                } else {
                    return view.eraseToAnyView()
                }
            })
            .then(background, body: { view, color in
                view.background(color)
            })
            .eraseToAnyView()
    }
    
    /// 重置Cell样式，左对齐并隐藏分割线、去除多余间距，可指定背景色
    public func resetCellStyle(background: Color? = nil) -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .then { view in
                if #available(iOS 15.0, *) {
                    return view.listRowInsets(.zero)
                        .listRowSeparator(.hidden)
                        .eraseToAnyView()
                } else {
                    return view.listRowInsets(EdgeInsets(top: -1, leading: -1, bottom: -1, trailing: -1))
                        .eraseToAnyView()
                }
            }
            .then(background, body: { view, color in
                view.background(color)
            })
            .eraseToAnyView()
    }
    
    /// 配置List视图，仅调用一次，一般用于绑定下拉刷新、上拉追加等
    ///
    /// 注意：iOS16以上scrollView为UICollectionView，iOS16以下为UITableView
    public func listViewConfigure(
        _ configuration: @escaping (UIScrollView) -> Void
    ) -> some View {
        return introspectListView { scrollView in
            guard scrollView.fw.property(forName: "listViewConfigure") == nil else { return }
            scrollView.fw.setProperty(NSNumber(value: true), forName: "listViewConfigure")
            
            configuration(scrollView)
        }
    }
    
    /// 绑定List下拉刷新插件，action必须调用completionHandler，可指定是否已加载完成不能继续追加
    public func listViewRefreshing(
        shouldBegin: Binding<Bool>? = nil,
        action: @escaping (@escaping (_ finished: Bool?) -> Void) -> Void,
        customize: ((UIScrollView) -> Void)? = nil
    ) -> some View {
        return introspectListView { scrollView in
            if scrollView.fw.property(forName: "listViewRefreshing") == nil {
                scrollView.fw.setProperty(NSNumber(value: true), forName: "listViewRefreshing")
                
                scrollView.fw.setRefreshing { [weak scrollView] in
                    action({ finished in
                        scrollView?.fw.endRefreshing()
                        if let finished = finished {
                            scrollView?.fw.loadingFinished = finished
                        }
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
    
    /// 绑定List上拉追加插件，action必须调用completionHandler，可指定是否已加载完成不能继续追加
    public func listViewLoading(
        shouldBegin: Binding<Bool>? = nil,
        shouldLoading: Bool? = nil,
        action: @escaping (@escaping (_ finished: Bool?) -> Void) -> Void,
        customize: ((UIScrollView) -> Void)? = nil
    ) -> some View {
        return introspectListView { scrollView in
            if scrollView.fw.property(forName: "listViewLoading") == nil {
                scrollView.fw.setProperty(NSNumber(value: true), forName: "listViewLoading")
                
                scrollView.fw.setLoading { [weak scrollView] in
                    action({ finished in
                        scrollView?.fw.endLoading()
                        if let finished = finished {
                            scrollView?.fw.loadingFinished = finished
                        }
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
    
    /// 显示List空界面插件，需手工切换，空界面显示时也可滚动
    public func showListEmpty(_ isShowing: Bool, customize: ((UIScrollView) -> Void)? = nil) -> some View {
        return introspectListView { scrollView in
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

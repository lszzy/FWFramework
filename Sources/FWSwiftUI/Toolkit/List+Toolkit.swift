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
                        
                        tableView.fw.resetTableStyle()
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
        if #available(iOS 16.0, *) {
            return introspectCollectionView { collectionView in
                guard collectionView.fw.property(forName: "listViewConfigure") == nil else { return }
                collectionView.fw.setProperty(NSNumber(value: true), forName: "listViewConfigure")
                
                configuration(collectionView)
            }
        } else {
            return introspectTableView { tableView in
                guard tableView.fw.property(forName: "listViewConfigure") == nil else { return }
                tableView.fw.setProperty(NSNumber(value: true), forName: "listViewConfigure")
                
                configuration(tableView)
            }
        }
    }
    
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
    
}

#endif
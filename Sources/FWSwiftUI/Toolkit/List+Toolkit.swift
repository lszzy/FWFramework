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
    public func resetListStyle(background: Color? = nil) -> some View {
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
            .then(UIDevice.fw_iosVersion < 16) { view in
                view.introspectTableView { tableView in
                    if !tableView.fw_propertyBool(forName: "resetListStyle") {
                        tableView.fw_setPropertyBool(true, forName: "resetListStyle")
                        
                        tableView.fw_resetTableStyle()
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
                guard !collectionView.fw_propertyBool(forName: "listViewConfigure") else { return }
                collectionView.fw_setPropertyBool(true, forName: "listViewConfigure")
                
                configuration(collectionView)
            }
        } else {
            return introspectTableView { tableView in
                guard !tableView.fw_propertyBool(forName: "listViewConfigure") else { return }
                tableView.fw_setPropertyBool(true, forName: "listViewConfigure")
                
                configuration(tableView)
            }
        }
    }
    
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
    
}

#endif

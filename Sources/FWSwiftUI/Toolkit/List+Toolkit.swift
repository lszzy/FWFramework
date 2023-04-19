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
    
    /// 隐藏List分割线，需cell调用生效
    public func listSeparatorHidden() -> some View {
        if #available(iOS 15.0, *) {
            return listRowSeparator(.hidden)
        } else {
            return introspectTableView { tableView in
                tableView.separatorStyle = .none
            }
        }
    }
    
}

#endif

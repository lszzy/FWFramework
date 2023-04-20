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
            guard !scrollView.fw_propertyBool(forName: "scrollViewConfigure") else { return }
            scrollView.fw_setPropertyBool(true, forName: "scrollViewConfigure")
            
            configuration(scrollView)
        }
    }
    
}

#endif

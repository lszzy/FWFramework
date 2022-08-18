//
//  View+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - View+Toolkit
/// 注意：iOS13系统View在dismiss时可能不会触发onDisappear，可在关闭按钮事件中处理
@available(iOS 13.0, *)
extension View {
    
    /// 转换为AnyView
    public func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
    
}

#endif

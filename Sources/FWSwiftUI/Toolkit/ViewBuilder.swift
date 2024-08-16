//
//  ViewBuilder.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - Text+ViewBuilder
extension Text {
    
    /// 拼接行内多文本
    public static func concatenate(
        @ArrayResultBuilder<Text> _ items: () -> [Text]
    ) -> Self {
        items().reduce(Text(""), +)
    }
    
    /// 初始化并拼接行内多文本
    public init(
        @ArrayResultBuilder<Text> _ items: () -> [Text]
    ) {
        self = items().reduce(Text(""), +)
    }
    
    /// 拼接行内文本
    public func concatenate(
        @ViewBuilder _ builder: () -> Text
    ) -> Self {
        self + builder()
    }
    
}

#endif

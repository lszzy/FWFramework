//
//  Layout+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
import FWFramework
#endif

// MARK: - Layout+Toolkit
@available(iOS 13.0, *)
extension View {
    
    /// 设置相对frame
    public func frame(relativeWidth: CGFloat, relativeHeight: CGFloat? = nil, alignment: Alignment = .center) -> some View {
        var height: CGFloat?
        if let relativeHeight = relativeHeight {
            height = UIScreen.fw.relativeValue(relativeHeight)
        }
        return frame(width: UIScreen.fw.relativeValue(relativeWidth), height: height, alignment: alignment)
    }
    
    /// 设置相对frame
    public func frame(relativeHeight: CGFloat, alignment: Alignment = .center) -> some View {
        return frame(height: UIScreen.fw.relativeValue(relativeHeight), alignment: alignment)
    }
    
    /// 设置指定边相对间距
    public func padding(_ edges: Edge.Set = .all, relativeLength: CGFloat) -> some View {
        padding(edges, UIScreen.fw.relativeValue(relativeLength))
    }
    
    /// 设置相对圆角
    public func cornerRadius(relativeRadius: CGFloat, antialiased: Bool = true) -> some View {
        cornerRadius(UIScreen.fw.relativeValue(relativeRadius), antialiased: antialiased)
    }
    
    /// 设置相对不规则圆角
    public func cornerRadius(relativeRadius: CGFloat, corners: UIRectCorner) -> some View {
        cornerRadius(UIScreen.fw.relativeValue(relativeRadius), corners: corners)
    }
    
    /// 同时设置相对边框和圆角
    public func border<S: ShapeStyle>(_ content: S, relativeWidth: CGFloat, relativeRadius: CGFloat) -> some View {
        border(content, width: UIScreen.fw.relativeValue(relativeWidth), cornerRadius: UIScreen.fw.relativeValue(relativeRadius))
    }
    
    /// 设置相对宽度边框
    public func border<S>(_ content: S, relativeWidth: CGFloat) -> some View where S : ShapeStyle {
        border(content, width: UIScreen.fw.relativeValue(relativeWidth))
    }
    
    /// 设置相对尺寸阴影
    public func shadow(color: Color = Color(.sRGBLinear, white: 0, opacity: 0.33), relativeRadius: CGFloat, relativeX: CGFloat = 0, relativeY: CGFloat = 0) -> some View {
        shadow(color: color, radius: UIScreen.fw.relativeValue(relativeRadius), x: UIScreen.fw.relativeValue(relativeX), y: UIScreen.fw.relativeValue(relativeY))
    }
    
}

@available(iOS 13.0, *)
extension HStack {
    
    /// 初始化并指定相对间距
    public init(alignment: VerticalAlignment = .center, relativeSpacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.init(alignment: alignment, spacing: UIScreen.fw.relativeValue(relativeSpacing), content: content)
    }
    
}

@available(iOS 13.0, *)
extension VStack {
    
    /// 初始化并指定相对间距
    public init(alignment: HorizontalAlignment = .center, relativeSpacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.init(alignment: alignment, spacing: UIScreen.fw.relativeValue(relativeSpacing), content: content)
    }
    
}

@available(iOS 13.0, *)
extension Spacer {
    
    /// 初始化并指定相对最小长度
    public init(relativeMinLength: CGFloat) {
        self.init(minLength: UIScreen.fw.relativeValue(relativeMinLength))
    }
    
}

@available(iOS 13.0, *)
extension EdgeInsets {
    
    /// 自定义指定边相对长度，默认为0
    public init(_ edges: Edge.Set = .all, relativeLength: CGFloat) {
        self.init(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        if edges.contains(.top) { top = UIScreen.fw.relativeValue(relativeLength) }
        if edges.contains(.leading) { leading = UIScreen.fw.relativeValue(relativeLength) }
        if edges.contains(.bottom) { bottom = UIScreen.fw.relativeValue(relativeLength) }
        if edges.contains(.trailing) { trailing = UIScreen.fw.relativeValue(relativeLength) }
    }
    
}

@available(iOS 14.0, *)
extension LazyHStack {
    
    /// 初始化并指定相对间距
    public init(alignment: VerticalAlignment = .center, relativeSpacing: CGFloat, pinnedViews: PinnedScrollableViews = .init(), @ViewBuilder content: () -> Content) {
        self.init(alignment: alignment, spacing: UIScreen.fw.relativeValue(relativeSpacing), pinnedViews: pinnedViews, content: content)
    }
    
}

@available(iOS 14.0, *)
extension LazyVStack {
    
    /// 初始化并指定相对间距
    public init(alignment: HorizontalAlignment = .center, relativeSpacing: CGFloat, pinnedViews: PinnedScrollableViews = .init(), @ViewBuilder content: () -> Content) {
        self.init(alignment: alignment, spacing: UIScreen.fw.relativeValue(relativeSpacing), pinnedViews: pinnedViews, content: content)
    }
    
}

@available(iOS 14.0, *)
extension LazyHGrid {
    
    /// 初始化并指定相对间距
    public init(rows: [GridItem], alignment: VerticalAlignment = .center, relativeSpacing: CGFloat, pinnedViews: PinnedScrollableViews = .init(), @ViewBuilder content: () -> Content) {
        self.init(rows: rows, alignment: alignment, spacing: UIScreen.fw.relativeValue(relativeSpacing), pinnedViews: pinnedViews, content: content)
    }
    
}

@available(iOS 14.0, *)
extension LazyVGrid {
    
    /// 初始化并指定相对间距
    public init(columns: [GridItem], alignment: HorizontalAlignment = .center, relativeSpacing: CGFloat, pinnedViews: PinnedScrollableViews = .init(), @ViewBuilder content: () -> Content) {
        self.init(columns: columns, alignment: alignment, spacing: UIScreen.fw.relativeValue(relativeSpacing), pinnedViews: pinnedViews, content: content)
    }
    
}

#endif

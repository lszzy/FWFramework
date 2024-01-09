//
//  Button+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - OpacityButtonStyle
/// 透明度按钮样式，支持设置高亮和禁用时的透明度
public struct OpacityButtonStyle: ButtonStyle {
    
    public var disabled: Bool
    public var highlightedAlpha: CGFloat
    public var disabledAlpha: CGFloat
    
    public init(disabled: Bool = false, highlightedAlpha: CGFloat? = nil, disabledAlpha: CGFloat? = nil) {
        self.disabled = disabled
        self.highlightedAlpha = highlightedAlpha ?? UIButton.fw_highlightedAlpha
        self.disabledAlpha = disabledAlpha ?? UIButton.fw_disabledAlpha
    }
    
    public func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? highlightedAlpha : (disabled ? disabledAlpha : 1.0))
    }
    
}

// MARK: - View+Toolkit
extension View {
    
    /// 设置按钮高亮和禁用时的透明度，nil时使用默认
    public func opacityButtonStyle(disabled: Bool = false, highlightedAlpha: CGFloat? = nil, disabledAlpha: CGFloat? = nil) -> some View {
        self.buttonStyle(OpacityButtonStyle(disabled: disabled, highlightedAlpha: highlightedAlpha, disabledAlpha: disabledAlpha))
            .disabled(disabled)
    }
    
    /// 包装到Button并指定点击事件
    public func wrappedButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            self
        }
    }
    
}

#endif

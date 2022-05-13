//
//  BarAppearance.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/13.
//

import UIKit

extension Wrapper where Base: UINavigationBar {
    
    /// 导航栏iOS13+样式对象，用于自定义样式，默认透明
    @available(iOS 13.0, *)
    public var appearance: UINavigationBarAppearance {
        return base.__fw.appearance
    }

    /// 手工更新导航栏样式
    @available(iOS 13.0, *)
    public func updateAppearance() {
        base.__fw.updateAppearance()
    }

    /// 导航栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    public var isTranslucent: Bool {
        get { return base.__fw.isTranslucent }
        set { base.__fw.isTranslucent = newValue }
    }

    /// 设置前景颜色，包含文字和按钮等
    public var foregroundColor: UIColor? {
        get { return base.__fw.foregroundColor }
        set { base.__fw.foregroundColor = newValue }
    }

    /// 单独设置标题颜色，nil时显示前景颜色
    public var titleColor: UIColor? {
        get { return base.__fw.titleColor }
        set { base.__fw.titleColor = newValue }
    }

    /// 设置背景颜色(nil时透明)，兼容主题颜色，后设置生效
    public var backgroundColor: UIColor? {
        get { return base.__fw.backgroundColor }
        set { base.__fw.backgroundColor = newValue }
    }

    /// 设置背景图片(nil时透明)，兼容主题图片，后设置生效
    public var backgroundImage: UIImage? {
        get { return base.__fw.backgroundImage }
        set { base.__fw.backgroundImage = newValue }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    public var backgroundTransparent: Bool {
        get { return base.__fw.backgroundTransparent }
        set { base.__fw.backgroundTransparent = newValue }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
    public var shadowColor: UIColor? {
        get { return base.__fw.shadowColor }
        set { base.__fw.shadowColor = newValue }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
    public var shadowImage: UIImage? {
        get { return base.__fw.shadowImage }
        set { base.__fw.shadowImage = newValue }
    }

    /// 设置返回按钮图片，包含图片和转场Mask图片，自动偏移和系统左侧按钮位置保持一致
    public var backImage: UIImage? {
        get { return base.__fw.backImage }
        set { base.__fw.backImage = newValue }
    }
    
}

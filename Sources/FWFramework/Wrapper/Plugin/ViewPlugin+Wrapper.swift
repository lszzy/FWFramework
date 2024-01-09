//
//  ViewPlugin+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

extension Wrapper where Base: UIView {
    
    /// 自定义视图插件，未设置时自动从插件池加载
    public var viewPlugin: ViewPlugin! {
        get { return base.fw_viewPlugin }
        set { base.fw_viewPlugin = newValue }
    }

    /// 统一进度视图工厂方法
    public func progressView(style: ProgressViewStyle = .default) -> UIView & ProgressViewPlugin {
        return base.fw_progressView(style: style)
    }

    /// 统一指示器视图工厂方法
    public func indicatorView(style: IndicatorViewStyle = .default) -> UIView & IndicatorViewPlugin {
        return base.fw_indicatorView(style: style)
    }
    
    /// 统一进度视图工厂方法
    public static func progressView(style: ProgressViewStyle = .default) -> UIView & ProgressViewPlugin {
        return Base.fw_progressView(style: style)
    }

    /// 统一指示器视图工厂方法
    public static func indicatorView(style: IndicatorViewStyle = .default) -> UIView & IndicatorViewPlugin {
        return Base.fw_indicatorView(style: style)
    }
    
}

extension Wrapper where Base: UIActivityIndicatorView {
    
    /// 快速创建指示器，可指定颜色，默认白色
    public static func indicatorView(color: UIColor?) -> UIActivityIndicatorView {
        return Base.fw_indicatorView(color: color)
    }
    
}

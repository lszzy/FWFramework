//
//  ViewPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

extension Wrapper where Base: UIView {
    
    /// 自定义视图插件，未设置时自动从插件池加载
    public var viewPlugin: ViewPlugin? {
        get { return base.__fw_viewPlugin }
        set { base.__fw_viewPlugin = newValue }
    }

    /// 统一进度视图工厂方法
    public func progressView(style: ProgressViewStyle) -> UIView & ProgressViewPlugin {
        return base.__fw_progressView(withStyle: style)
    }

    /// 统一指示器视图工厂方法
    public func indicatorView(style: IndicatorViewStyle) -> UIView & IndicatorViewPlugin {
        return base.__fw_indicatorView(withStyle: style)
    }
    
    /// 统一进度视图工厂方法
    public static func progressView(style: ProgressViewStyle) -> UIView & ProgressViewPlugin {
        return Base.__fw_progressView(withStyle: style)
    }

    /// 统一指示器视图工厂方法
    public static func indicatorView(style: IndicatorViewStyle) -> UIView & IndicatorViewPlugin {
        return Base.__fw_indicatorView(withStyle: style)
    }
    
}

extension Wrapper where Base: UIActivityIndicatorView {
    
    /// 快速创建指示器，可指定颜色，默认白色
    public static func indicatorView(color: UIColor?) -> UIActivityIndicatorView {
        return Base.__fw_indicatorView(with: color)
    }
    
}

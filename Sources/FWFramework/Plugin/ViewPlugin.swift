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

@_spi(FW) extension UIView {
    
    /// 自定义视图插件，未设置时自动从插件池加载
    public var fw_viewPlugin: ViewPlugin! {
        get {
            if let viewPlugin = fw_property(forName: "fw_viewPlugin") as? ViewPlugin {
                return viewPlugin
            } else if let viewPlugin = PluginManager.loadPlugin(ViewPlugin.self) as? ViewPlugin {
                return viewPlugin
            }
            return ViewPluginImpl.shared
        }
        set {
            fw_setProperty(newValue, forName: "fw_viewPlugin")
        }
    }

    /// 统一进度视图工厂方法
    public func fw_progressView(style: ProgressViewStyle) -> UIView & ProgressViewPlugin {
        var plugin: ViewPlugin
        if let viewPlugin = fw_viewPlugin, viewPlugin.responds(to: #selector(viewPlugin.progressView(withStyle:))) {
            plugin = viewPlugin
        } else {
            plugin = ViewPluginImpl.shared
        }
        return plugin.progressView!(withStyle: style)
    }

    /// 统一指示器视图工厂方法
    public func fw_indicatorView(style: IndicatorViewStyle) -> UIView & IndicatorViewPlugin {
        var plugin: ViewPlugin
        if let viewPlugin = fw_viewPlugin, viewPlugin.responds(to: #selector(viewPlugin.indicatorView(withStyle:))) {
            plugin = viewPlugin
        } else {
            plugin = ViewPluginImpl.shared
        }
        return plugin.indicatorView!(withStyle: style)
    }
    
    /// 统一进度视图工厂方法
    @objc public static func fw_progressView(style: ProgressViewStyle) -> UIView & ProgressViewPlugin {
        var plugin: ViewPlugin
        if let viewPlugin = PluginManager.loadPlugin(ViewPlugin.self) as? ViewPlugin,
           viewPlugin.responds(to: #selector(viewPlugin.progressView(withStyle:))) {
            plugin = viewPlugin
        } else {
            plugin = ViewPluginImpl.shared
        }
        return plugin.progressView!(withStyle: style)
    }

    /// 统一指示器视图工厂方法
    @objc public static func fw_indicatorView(style: IndicatorViewStyle) -> UIView & IndicatorViewPlugin {
        var plugin: ViewPlugin
        if let viewPlugin = PluginManager.loadPlugin(ViewPlugin.self) as? ViewPlugin,
           viewPlugin.responds(to: #selector(viewPlugin.indicatorView(withStyle:))) {
            plugin = viewPlugin
        } else {
            plugin = ViewPluginImpl.shared
        }
        return plugin.indicatorView!(withStyle: style)
    }
    
}

@_spi(FW) extension UIActivityIndicatorView {
    
    /// 快速创建指示器，可指定颜色，默认白色
    @objc public static func fw_indicatorView(color: UIColor?) -> UIActivityIndicatorView {
        var indicatorStyle: UIActivityIndicatorView.Style
        if #available(iOS 13.0, *) {
            indicatorStyle = .medium
        } else {
            indicatorStyle = .white
        }
        let indicatorView = UIActivityIndicatorView(style: indicatorStyle)
        indicatorView.color = color ?? .white
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }
    
}

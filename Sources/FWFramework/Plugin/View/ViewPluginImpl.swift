//
//  ViewPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

/// 默认视图插件
open class ViewPluginImpl: NSObject, ViewPlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = ViewPluginImpl()
    
    /// 自定义进度视图生产句柄，默认nil时ProgressView
    open var customProgressView: ((ProgressViewStyle, ProgressViewScene) -> (UIView & ProgressViewPlugin)?)?
    
    /// 自定义指示器视图生产句柄，默认nil时UIActivityIndicatorView
    open var customIndicatorView: ((IndicatorViewStyle, IndicatorViewScene) -> (UIView & IndicatorViewPlugin)?)?
    
    // MARK: - ViewPlugin
    open func progressView(style: ProgressViewStyle, scene: ProgressViewScene) -> UIView & ProgressViewPlugin {
        let progressView = customProgressView?(style, scene) ?? ProgressView()
        progressView.indicatorSize = scene.indicatorSize
        progressView.indicatorColor = scene.indicatorColor
        return progressView
    }
    
    open func indicatorView(style: IndicatorViewStyle, scene: IndicatorViewScene) -> UIView & IndicatorViewPlugin {
        let indicatorView = customIndicatorView?(style, scene) ?? UIActivityIndicatorView.fw_indicatorView()
        indicatorView.indicatorSize = scene.indicatorSize
        indicatorView.indicatorColor = scene.indicatorColor
        return indicatorView
    }
    
}

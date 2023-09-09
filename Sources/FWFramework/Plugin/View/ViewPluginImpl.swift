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
    
    /// 自定义进度视图尺寸句柄，默认nil时{37,37}
    open var customProgressSize: ((ProgressViewStyle) -> CGSize)?
    
    /// 自定义进度视图颜色句柄，默认nil时default|preview都为白色
    open var customProgressColor: ((ProgressViewStyle) -> UIColor?)?
    
    /// 自定义进度视图生产句柄，会执行尺寸和颜色句柄，默认nil时ProgressView
    open var customProgressView: ((ProgressViewStyle) -> (UIView & ProgressViewPlugin)?)?
    
    /// 自定义指示器视图尺寸句柄，默认nil时{37,37}
    open var customIndicatorSize: ((IndicatorViewStyle) -> CGSize)?
    
    /// 自定义指示器视图颜色句柄，默认nil时default|placeholder为白色、refresh|empty|image为灰色
    open var customIndicatorColor: ((IndicatorViewStyle) -> UIColor?)?
    
    /// 自定义指示器视图生产句柄，会执行尺寸和颜色句柄，默认nil时UIActivityIndicatorView
    open var customIndicatorView: ((IndicatorViewStyle) -> (UIView & IndicatorViewPlugin)?)?
    
    // MARK: - ViewPlugin
    open func progressView(style: ProgressViewStyle) -> UIView & ProgressViewPlugin {
        let progressView = customProgressView?(style) ?? ProgressView()
        if let indicatorSize = customProgressSize?(style) {
            progressView.indicatorSize = indicatorSize
        }
        if let indicatorColor = customProgressColor?(style) {
            progressView.indicatorColor = indicatorColor
        } else {
            progressView.indicatorColor = .white
        }
        return progressView
    }
    
    open func indicatorView(style: IndicatorViewStyle) -> UIView & IndicatorViewPlugin {
        let indicatorView = customIndicatorView?(style) ?? UIActivityIndicatorView.fw_indicatorView()
        if let indicatorSize = customIndicatorSize?(style) {
            indicatorView.indicatorSize = indicatorSize
        }
        if let indicatorColor = customIndicatorColor?(style) {
            indicatorView.indicatorColor = indicatorColor
        } else {
            indicatorView.indicatorColor = (style == .default || style == .placeholder) ? .white : .gray
        }
        return indicatorView
    }
    
}

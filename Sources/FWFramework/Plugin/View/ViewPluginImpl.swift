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
    
    /// 全局配置大指示器预设尺寸，默认{37,37}
    public static var indicatorLargeSize: CGSize = CGSize(width: 37, height: 37)
    
    /// 全局配置中指示器预设尺寸，默认{20,20}
    public static var indicatorMediumSize: CGSize = CGSize(width: 20, height: 20)
    
    /// 全局配置指示器视图预设颜色，默认gray
    public static var indicatorViewColor: UIColor = .gray
    
    /// 自定义进度视图生产句柄，默认ProgressView
    open var customProgressView: ((ProgressViewStyle) -> UIView & ProgressViewPlugin)?
    
    /// 自定义指示器视图生产句柄，默认UIActivityIndicatorView
    open var customIndicatorView: ((IndicatorViewStyle) -> UIView & IndicatorViewPlugin)?
    
    // MARK: - ViewPlugin
    open func progressView(style: ProgressViewStyle) -> UIView & ProgressViewPlugin {
        if let customProgressView = customProgressView {
            return customProgressView(style)
        }
        
        let progressView = ProgressView()
        return progressView
    }
    
    open func indicatorView(style: IndicatorViewStyle) -> UIView & IndicatorViewPlugin {
        if let customIndicatorView = customIndicatorView {
            return customIndicatorView(style)
        }
        
        let indicatorView = UIActivityIndicatorView.fw_indicatorView(color: nil)
        return indicatorView
    }
    
}

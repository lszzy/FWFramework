//
//  ViewPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

/// 默认视图插件
open class ViewPluginImpl: NSObject, ViewPlugin, @unchecked Sendable {
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = ViewPluginImpl()

    /// 自定义进度视图生产句柄，默认nil时ProgressView
    open var customProgressView: (@MainActor @Sendable (ProgressViewStyle) -> (UIView & ProgressViewPlugin)?)?

    /// 自定义指示器视图生产句柄，默认nil时UIActivityIndicatorView
    open var customIndicatorView: (@MainActor @Sendable (IndicatorViewStyle) -> (UIView & IndicatorViewPlugin)?)?

    // MARK: - ViewPlugin
    open func progressView(style: ProgressViewStyle) -> UIView & ProgressViewPlugin {
        let progressView = customProgressView?(style) ?? ProgressView()
        if let indicatorSize = style.indicatorSize {
            progressView.indicatorSize = indicatorSize
        }
        if let indicatorColor = style.indicatorColor {
            progressView.indicatorColor = indicatorColor
        }
        return progressView
    }

    open func indicatorView(style: IndicatorViewStyle) -> UIView & IndicatorViewPlugin {
        let indicatorView = customIndicatorView?(style) ?? UIActivityIndicatorView.fw.indicatorView(color: nil)
        if let indicatorSize = style.indicatorSize {
            indicatorView.indicatorSize = indicatorSize
        }
        if let indicatorColor = style.indicatorColor {
            indicatorView.indicatorColor = indicatorColor
        }
        return indicatorView
    }
}

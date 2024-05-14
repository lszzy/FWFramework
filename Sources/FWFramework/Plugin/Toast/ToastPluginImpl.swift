//
//  ToastPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// 默认吐司插件
open class ToastPluginImpl: NSObject, ToastPlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = ToastPluginImpl()

    /// 显示吐司时是否执行淡入动画，默认YES
    open var fadeAnimated: Bool = true
    /// 消息吐司自动隐藏时间，默认2.0
    open var autoHideTime: TimeInterval = 2.0
    /// 加载吐司延迟隐藏时间，默认0.1
    open var delayHideTime: TimeInterval = 0.1
    /// 吐司自定义句柄，show方法自动调用
    open var customBlock: ((ToastView) -> Void)?
    /// 吐司重用句柄，show方法重用时自动调用
    open var reuseBlock: ((ToastView) -> Void)?

    /// 默认加载吐司文本句柄
    open var defaultLoadingText: (() -> NSAttributedString?)?
    /// 默认进度条吐司文本句柄
    open var defaultProgressText: (() -> NSAttributedString?)?
    /// 默认消息吐司文本句柄
    open var defaultMessageText: ((ToastStyle) -> NSAttributedString?)?

    /// 错误消息吐司文本格式化句柄，error生效，默认nil
    open var errorTextFormatter: ((Error?) -> AttributedStringParameter?)?
    /// 错误消息吐司样式格式化句柄，error生效，默认nil
    open var errorStyleFormatter: ((Error?) -> ToastStyle)?
    
    private var loadingViewTag: Int = 2011
    private var progressViewTag: Int = 2012
    private var messageViewTag: Int = 2013
    
    // MARK: - ToastPlugin
    open func showLoading(attributedText: NSAttributedString?, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView) {
        var loadingText = attributedText
        if loadingText == nil, defaultLoadingText != nil {
            loadingText = defaultLoadingText?()
        }
        
        if let toastView = view.fw.subview(tag: loadingViewTag) as? ToastView {
            toastView.invalidateTimer()
            view.bringSubviewToFront(toastView)
            toastView.attributedTitle = loadingText
            toastView.cancelBlock = cancelBlock
            
            reuseBlock?(toastView)
            return
        }
        
        let toastView = ToastView(type: .indicator)
        toastView.tag = loadingViewTag
        toastView.attributedTitle = loadingText
        toastView.cancelBlock = cancelBlock
        view.addSubview(toastView)
        toastView.fw.pinEdges(toSuperview: view.fw.toastInsets)
        
        self.customBlock?(toastView)
        customBlock?(toastView)
        toastView.show(animated: fadeAnimated)
    }
    
    open func hideLoading(delayed: Bool, in view: UIView) {
        guard let toastView = view.fw.subview(tag: loadingViewTag) as? ToastView else { return }
        
        if delayed {
            toastView.hide(afterDelay: delayHideTime)
        } else {
            toastView.hide()
        }
    }
    
    open func showingLoadingView(in view: UIView) -> UIView? {
        let toastView = view.fw.subview(tag: loadingViewTag) as? ToastView
        return toastView
    }
    
    open func showProgress(attributedText: NSAttributedString?, progress: CGFloat, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView) {
        var progressText = attributedText
        if progressText == nil, defaultProgressText != nil {
            progressText = defaultProgressText?()
        }
        
        if let toastView = view.fw.subview(tag: progressViewTag) as? ToastView {
            toastView.invalidateTimer()
            view.bringSubviewToFront(toastView)
            toastView.attributedTitle = progressText
            toastView.progress = progress
            toastView.cancelBlock = cancelBlock
            
            reuseBlock?(toastView)
            return
        }
        
        let toastView = ToastView(type: .progress)
        toastView.tag = progressViewTag
        toastView.attributedTitle = progressText
        toastView.progress = progress
        toastView.cancelBlock = cancelBlock
        view.addSubview(toastView)
        toastView.fw.pinEdges(toSuperview: view.fw.toastInsets)
        
        self.customBlock?(toastView)
        customBlock?(toastView)
        toastView.show(animated: fadeAnimated)
    }
    
    open func hideProgress(in view: UIView) {
        let toastView = view.fw.subview(tag: progressViewTag) as? ToastView
        toastView?.hide()
    }
    
    open func showingProgressView(in view: UIView) -> UIView? {
        let toastView = view.fw.subview(tag: progressViewTag) as? ToastView
        return toastView
    }
    
    open func showMessage(attributedText: NSAttributedString?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView) {
        var messageText = attributedText
        if messageText == nil, defaultMessageText != nil {
            messageText = defaultMessageText?(style)
        }
        guard (messageText?.length ?? 0) > 0 else { return }
        
        let previousView = view.fw.subview(tag: messageViewTag) as? ToastView
        let fadeAnimated = self.fadeAnimated && previousView == nil
        previousView?.hide()
        
        let toastView = ToastView(type: .text)
        toastView.tag = messageViewTag
        toastView.isUserInteractionEnabled = !interactive
        toastView.attributedTitle = messageText
        view.addSubview(toastView)
        toastView.fw.pinEdges(toSuperview: view.fw.toastInsets)
        
        self.customBlock?(toastView)
        customBlock?(toastView)
        toastView.show(animated: fadeAnimated)
        if autoHide {
            toastView.hide(afterDelay: autoHideTime, completion: completion)
        }
    }
    
    open func hideMessage(in view: UIView) {
        let toastView = view.fw.subview(tag: messageViewTag) as? ToastView
        toastView?.hide()
    }
    
    open func showingMessageView(in view: UIView) -> UIView? {
        let toastView = view.fw.subview(tag: messageViewTag) as? ToastView
        return toastView
    }
    
}

//
//  ToastPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

/// 默认吐司插件
open class ToastPluginImpl: NSObject, ToastPlugin, @unchecked Sendable {
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = ToastPluginImpl()

    /// 显示吐司时是否执行淡入动画，默认YES
    open var fadeAnimated: Bool = true
    /// 加载吐司延迟隐藏时间，默认0.1
    open var delayHideTime: TimeInterval = 0.1
    /// 消息吐司自动隐藏时间句柄，默认nil时为2.0
    open var autoHideTime: (@MainActor @Sendable (ToastStyle) -> TimeInterval)?
    /// 自定义吐司视图句柄，默认nil时自动处理，loading时为indicator，progress时为progress，其它为image
    open var customToastView: (@MainActor @Sendable (ToastStyle) -> ToastView?)?
    /// 自定义吐司容器句柄，style仅为loading|progress|default，默认nil时使用view
    open var customToastContainer: (@MainActor @Sendable (_ style: ToastStyle, _ view: UIView) -> UIView?)?
    /// 吐司自定义句柄，show方法自动调用
    open var customBlock: (@MainActor @Sendable (ToastView) -> Void)?
    /// 吐司重用句柄，show方法重用时自动调用
    open var reuseBlock: (@MainActor @Sendable (ToastView) -> Void)?

    /// 默认加载吐司文本句柄
    open var defaultLoadingText: (@MainActor @Sendable () -> NSAttributedString?)?
    /// 默认加载吐司详情句柄
    open var defaultLoadingDetail: (@MainActor @Sendable () -> NSAttributedString?)?
    /// 默认进度条吐司文本句柄
    open var defaultProgressText: (@MainActor @Sendable () -> NSAttributedString?)?
    /// 默认进度条吐司详情句柄
    open var defaultProgressDetail: (@MainActor @Sendable () -> NSAttributedString?)?
    /// 默认消息吐司文本句柄
    open var defaultMessageText: (@MainActor @Sendable (ToastStyle) -> NSAttributedString?)?
    /// 默认消息吐司详情句柄
    open var defaultMessageDetail: (@MainActor @Sendable (ToastStyle) -> NSAttributedString?)?

    /// 错误消息吐司文本格式化句柄，error生效，默认nil
    open var errorTextFormatter: (@MainActor @Sendable (Error?) -> AttributedStringParameter?)?
    /// 错误消息吐司详情格式化句柄，error生效，默认nil
    open var errorDetailFormatter: (@MainActor @Sendable (Error?) -> AttributedStringParameter?)?
    /// 错误消息吐司样式格式化句柄，error生效，默认nil
    open var errorStyleFormatter: (@MainActor @Sendable (Error?) -> ToastStyle)?

    private var loadingViewTag: Int = 2011
    private var progressViewTag: Int = 2012
    private var messageViewTag: Int = 2013

    // MARK: - ToastPlugin
    open func showLoading(
        attributedText: NSAttributedString?,
        attributedDetail: NSAttributedString?,
        cancelBlock: (@MainActor @Sendable () -> Void)?,
        customBlock: (@MainActor @Sendable (Any) -> Void)?,
        in view: UIView
    ) {
        var loadingText = attributedText
        if loadingText == nil, defaultLoadingText != nil {
            loadingText = defaultLoadingText?()
        }
        var loadingDetail = attributedDetail
        if loadingDetail == nil, defaultLoadingDetail != nil {
            loadingDetail = defaultLoadingDetail?()
        }

        let containerView = customToastContainer?(.loading, view) ?? view
        if let toastView = containerView.fw.subview(tag: loadingViewTag) as? ToastView {
            toastView.invalidateTimer()
            containerView.bringSubviewToFront(toastView)
            toastView.attributedTitle = loadingText
            toastView.attributedMessage = loadingDetail
            toastView.cancelBlock = cancelBlock

            reuseBlock?(toastView)
            return
        }

        let toastView = customToastView?(.loading) ?? ToastView(type: .indicator)
        toastView.style = .loading
        toastView.tag = loadingViewTag
        toastView.attributedTitle = loadingText
        toastView.attributedMessage = loadingDetail
        toastView.cancelBlock = cancelBlock
        containerView.addSubview(toastView)
        toastView.fw.pinEdges(toSuperview: containerView.fw.toastInsets, autoScale: false)

        self.customBlock?(toastView)
        customBlock?(toastView)
        toastView.show(animated: fadeAnimated)
    }

    open func hideLoading(delayed: Bool, in view: UIView) {
        let containerView = customToastContainer?(.loading, view) ?? view
        guard let toastView = containerView.fw.subview(tag: loadingViewTag) as? ToastView else { return }

        if delayed {
            toastView.hide(afterDelay: delayHideTime)
        } else {
            toastView.hide()
        }
    }

    open func showingLoadingView(in view: UIView) -> UIView? {
        let containerView = customToastContainer?(.loading, view) ?? view
        let toastView = containerView.fw.subview(tag: loadingViewTag) as? ToastView
        return toastView
    }

    open func showProgress(
        attributedText: NSAttributedString?,
        attributedDetail: NSAttributedString?,
        progress: CGFloat,
        cancelBlock: (@MainActor @Sendable () -> Void)?,
        customBlock: (@MainActor @Sendable (Any) -> Void)?,
        in view: UIView
    ) {
        var progressText = attributedText
        if progressText == nil, defaultProgressText != nil {
            progressText = defaultProgressText?()
        }
        var progressDetail = attributedDetail
        if progressDetail == nil, defaultProgressDetail != nil {
            progressDetail = defaultProgressDetail?()
        }

        let containerView = customToastContainer?(.progress, view) ?? view
        if let toastView = containerView.fw.subview(tag: progressViewTag) as? ToastView {
            toastView.invalidateTimer()
            containerView.bringSubviewToFront(toastView)
            toastView.attributedTitle = progressText
            toastView.attributedMessage = progressDetail
            toastView.progress = progress
            toastView.cancelBlock = cancelBlock

            reuseBlock?(toastView)
            return
        }

        let toastView = customToastView?(.progress) ?? ToastView(type: .progress)
        toastView.style = .progress
        toastView.tag = progressViewTag
        toastView.attributedTitle = progressText
        toastView.attributedMessage = progressDetail
        toastView.progress = progress
        toastView.cancelBlock = cancelBlock
        containerView.addSubview(toastView)
        toastView.fw.pinEdges(toSuperview: containerView.fw.toastInsets, autoScale: false)

        self.customBlock?(toastView)
        customBlock?(toastView)
        toastView.show(animated: fadeAnimated)
    }

    open func hideProgress(in view: UIView) {
        let containerView = customToastContainer?(.progress, view) ?? view
        let toastView = containerView.fw.subview(tag: progressViewTag) as? ToastView
        toastView?.hide()
    }

    open func showingProgressView(in view: UIView) -> UIView? {
        let containerView = customToastContainer?(.progress, view) ?? view
        let toastView = containerView.fw.subview(tag: progressViewTag) as? ToastView
        return toastView
    }

    open func showMessage(
        attributedText: NSAttributedString?,
        attributedDetail: NSAttributedString?,
        style: ToastStyle,
        autoHide: Bool,
        interactive: Bool,
        completion: (@MainActor @Sendable () -> Void)?,
        customBlock: (@MainActor @Sendable (Any) -> Void)?,
        in view: UIView
    ) {
        var messageText = attributedText
        if messageText == nil, defaultMessageText != nil {
            messageText = defaultMessageText?(style)
        }
        var messageDetail = attributedDetail
        if messageDetail == nil, defaultMessageDetail != nil {
            messageDetail = defaultMessageDetail?(style)
        }
        guard (messageText?.length ?? 0) > 0 || (messageDetail?.length ?? 0) > 0 else { return }

        let containerView = customToastContainer?(.default, view) ?? view
        let previousView = containerView.fw.subview(tag: messageViewTag) as? ToastView
        let fadeAnimated = fadeAnimated && previousView == nil
        previousView?.hide()

        let toastView = customToastView?(style) ?? ToastView(type: .image)
        toastView.style = style
        toastView.tag = messageViewTag
        toastView.isUserInteractionEnabled = !interactive
        toastView.attributedTitle = messageText
        toastView.attributedMessage = messageDetail
        containerView.addSubview(toastView)
        toastView.fw.pinEdges(toSuperview: containerView.fw.toastInsets, autoScale: false)

        self.customBlock?(toastView)
        customBlock?(toastView)
        toastView.show(animated: fadeAnimated)
        if autoHide {
            toastView.hide(afterDelay: autoHideTime?(style) ?? 2.0, completion: completion)
        }
    }

    open func hideMessage(in view: UIView) {
        let containerView = customToastContainer?(.default, view) ?? view
        let toastView = containerView.fw.subview(tag: messageViewTag) as? ToastView
        toastView?.hide()
    }

    open func showingMessageView(in view: UIView) -> UIView? {
        let containerView = customToastContainer?(.default, view) ?? view
        let toastView = containerView.fw.subview(tag: messageViewTag) as? ToastView
        return toastView
    }
}

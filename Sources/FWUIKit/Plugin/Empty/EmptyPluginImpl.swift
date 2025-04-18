//
//  EmptyPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

/// 默认空界面插件
open class EmptyPluginImpl: NSObject, EmptyPlugin, @unchecked Sendable {
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = EmptyPluginImpl()

    /// 显示空界面时是否执行淡入动画，默认YES
    open var fadeAnimated: Bool = true
    /// 空界面自定义句柄，show方法自动调用
    open var customBlock: (@MainActor @Sendable (PlaceholderView) -> Void)?

    /// 默认空界面文本句柄，非loading时才触发
    open var defaultText: (@MainActor @Sendable () -> AttributedStringParameter?)?
    /// 默认空界面详细文本句柄，非loading时才触发
    open var defaultDetail: (@MainActor @Sendable () -> AttributedStringParameter?)?
    /// 默认空界面图片句柄，非loading时才触发
    open var defaultImage: (@MainActor @Sendable () -> UIImage?)?
    /// 默认空界面动作按钮句柄，非loading时才触发
    open var defaultAction: (@MainActor @Sendable () -> AttributedStringParameter?)?

    /// 错误空界面文本格式化句柄，error生效，默认nil
    open var errorTextFormatter: (@MainActor @Sendable (Error?) -> AttributedStringParameter?)?
    /// 错误空界面详细文本格式化句柄，error生效，默认nil
    open var errorDetailFormatter: (@MainActor @Sendable (Error?) -> AttributedStringParameter?)?
    /// 错误空界面图片格式化句柄，error生效，默认nil
    open var errorImageFormatter: (@MainActor @Sendable (Error?) -> UIImage?)?
    /// 错误空界面动作按钮格式化句柄，error生效，默认nil
    open var errorActionFormatter: (@MainActor @Sendable (Error?) -> AttributedStringParameter?)?

    private var emptyViewTag: Int = 2021

    // MARK: - EmptyPlugin
    open func showEmptyView(
        text: NSAttributedString?,
        detail: NSAttributedString?,
        image: UIImage?,
        loading: Bool,
        actions: [NSAttributedString]?,
        block: (@MainActor @Sendable (Int, Any) -> Void)?,
        customBlock: (@MainActor @Sendable (Any) -> Void)?,
        in view: UIView
    ) {
        var emptyText = text
        if !loading, emptyText == nil, defaultText != nil {
            emptyText = defaultText?()?.attributedStringValue
        }
        var emptyDetail = detail
        if !loading, emptyDetail == nil, defaultDetail != nil {
            emptyDetail = defaultDetail?()?.attributedStringValue
        }
        var emptyImage = image
        if !loading, emptyImage == nil, defaultImage != nil {
            emptyImage = defaultImage?()
        }
        var emptyAction = (actions?.count ?? 0) > 0 ? actions?.first : nil
        if !loading, emptyAction == nil, block != nil, defaultAction != nil {
            emptyAction = defaultAction?()?.attributedStringValue
        }
        let emptyMoreAction = (actions?.count ?? 0) > 1 ? actions?[1] : nil

        let previousView = view.fw.subview(tag: emptyViewTag) as? PlaceholderView
        let fadeAnimated = fadeAnimated && previousView == nil
        previousView?.removeFromSuperview()

        let emptyView = PlaceholderView(frame: view.bounds)
        emptyView.tag = emptyViewTag
        view.addSubview(emptyView)
        emptyView.fw.pinEdges(toSuperview: view.fw.emptyInsets, autoScale: false)

        emptyView.setLoadingViewHidden(!loading)
        emptyView.setImage(emptyImage)
        emptyView.setTextLabelText(emptyText)
        emptyView.setDetailTextLabelText(emptyDetail)
        emptyView.setActionButtonTitle(emptyAction)
        emptyView.setMoreActionButtonTitle(emptyMoreAction)
        if block != nil {
            emptyView.actionButton.fw.addTouch { sender in
                block?(0, sender)
            }
        }
        if block != nil, emptyMoreAction != nil {
            emptyView.moreActionButton.fw.addTouch { sender in
                block?(1, sender)
            }
        }

        self.customBlock?(emptyView)
        customBlock?(emptyView)

        if fadeAnimated {
            emptyView.alpha = 0
            UIView.animate(withDuration: 0.25) {
                emptyView.alpha = 1.0
            }
        }
    }

    open func hideEmptyView(in view: UIView) {
        guard let emptyView = view.fw.subview(tag: emptyViewTag) else { return }

        if let overlayView = emptyView.superview as? ScrollOverlayView {
            emptyView.removeFromSuperview()
            overlayView.removeFromSuperview()
        } else {
            emptyView.removeFromSuperview()
        }
    }

    open func showingEmptyView(in view: UIView) -> UIView? {
        let emptyView = view.fw.subview(tag: emptyViewTag)
        return emptyView
    }
}

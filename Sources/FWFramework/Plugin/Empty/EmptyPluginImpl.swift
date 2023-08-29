//
//  EmptyPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

/// 默认空界面插件
open class EmptyPluginImpl: NSObject, EmptyPlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = EmptyPluginImpl()

    /// 显示空界面时是否执行淡入动画，默认YES
    open var fadeAnimated: Bool = true
    /// 空界面自定义句柄，show方法自动调用
    open var customBlock: ((PlaceholderView) -> Void)?

    /// 默认空界面文本句柄，非loading时才触发
    open var defaultText: (() -> Any?)?
    /// 默认空界面详细文本句柄，非loading时才触发
    open var defaultDetail: (() -> Any?)?
    /// 默认空界面图片句柄，非loading时才触发
    open var defaultImage: (() -> UIImage?)?
    /// 默认空界面动作按钮句柄，非loading时才触发
    open var defaultAction: (() -> Any?)?

    /// 错误空界面文本格式化句柄，error生效，默认nil
    open var errorTextFormatter: ((Error?) -> Any?)?
    /// 错误空界面详细文本格式化句柄，error生效，默认nil
    open var errorDetailFormatter: ((Error?) -> Any?)?
    /// 错误空界面图片格式化句柄，error生效，默认nil
    open var errorImageFormatter: ((Error?) -> UIImage?)?
    /// 错误空界面动作按钮格式化句柄，error生效，默认nil
    open var errorActionFormatter: ((Error?) -> Any?)?
    
    private var emptyViewTag: Int = 2021
    
    // MARK: - EmptyPlugin
    open func showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, actions: [Any]?, block: ((Int, Any) -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView) {
        var emptyText = text
        if !loading, emptyText == nil, defaultText != nil {
            emptyText = defaultText?()
        }
        var emptyDetail = detail
        if !loading, emptyDetail == nil, defaultDetail != nil {
            emptyDetail = defaultDetail?()
        }
        var emptyImage = image
        if !loading, emptyImage == nil, defaultImage != nil {
            emptyImage = defaultImage?()
        }
        var emptyAction = (actions?.count ?? 0) > 0 ? actions?.first : nil
        if !loading, emptyAction == nil, block != nil, defaultAction != nil {
            emptyAction = defaultAction?()
        }
        let emptyMoreAction = (actions?.count ?? 0) > 1 ? actions?[1] : nil
        
        let previousView = view.fw_subview(tag: emptyViewTag) as? PlaceholderView
        let fadeAnimated = self.fadeAnimated && previousView == nil
        previousView?.removeFromSuperview()
        
        let emptyView = PlaceholderView(frame: view.bounds)
        emptyView.tag = emptyViewTag
        view.addSubview(emptyView)
        emptyView.fw_pinEdges(toSuperview: view.fw_emptyInsets)

        self.customBlock?(emptyView)
        customBlock?(emptyView)
        
        emptyView.setLoadingViewHidden(!loading)
        emptyView.setImage(emptyImage)
        emptyView.setTextLabelText(emptyText)
        emptyView.setDetailTextLabelText(emptyDetail)
        emptyView.setActionButtonTitle(emptyAction)
        emptyView.setMoreActionButtonTitle(emptyMoreAction)
        if block != nil {
            emptyView.actionButton.fw_addTouch { sender in
                block?(0, sender)
            }
        }
        if block != nil, emptyMoreAction != nil {
            emptyView.moreActionButton.fw_addTouch { sender in
                block?(1, sender)
            }
        }
        
        if fadeAnimated {
            emptyView.alpha = 0
            UIView.animate(withDuration: 0.25) {
                emptyView.alpha = 1.0
            }
        }
    }
    
    open func hideEmptyView(_ view: UIView) {
        guard let emptyView = view.fw_subview(tag: emptyViewTag) else { return }
        
        if let overlayView = emptyView.superview as? ScrollOverlayView {
            emptyView.removeFromSuperview()
            overlayView.removeFromSuperview()
        } else {
            emptyView.removeFromSuperview()
        }
    }
    
    open func showingEmptyView(_ view: UIView) -> UIView? {
        let emptyView = view.fw_subview(tag: emptyViewTag)
        return emptyView
    }
    
}

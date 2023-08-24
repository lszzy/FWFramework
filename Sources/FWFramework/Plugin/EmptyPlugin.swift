//
//  EmptyPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

extension Wrapper where Base: UIView {
    
    /// 自定义空界面插件，未设置时自动从插件池加载
    public var emptyPlugin: EmptyPlugin? {
        get { return base.__fw_emptyPlugin }
        set { base.__fw_emptyPlugin = newValue }
    }
    
    /// 设置空界面外间距，默认zero
    public var emptyInsets: UIEdgeInsets {
        get { return base.__fw_emptyInsets }
        set { base.__fw_emptyInsets = newValue }
    }
    
    /// 获取正在显示的空界面视图
    public var showingEmptyView: UIView? {
        return base.__fw_showingEmpty
    }

    /// 是否显示空界面
    public var hasEmptyView: Bool {
        return base.__fw_hasEmptyView
    }

    /// 显示空界面加载视图
    public func showEmptyLoading() {
        base.__fw_showEmptyLoading()
    }

    /// 显示空界面，指定文本、详细文本、图片和动作按钮
    public func showEmptyView(text: Any? = nil, detail: Any? = nil, image: UIImage? = nil, action: Any? = nil, block: ((Any) -> Void)? = nil) {
        base.__fw_showEmpty(withText: text, detail: detail, image: image, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和动作按钮
    public func showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, action: Any?, block: ((Any) -> Void)?) {
        base.__fw_showEmpty(withText: text, detail: detail, image: image, loading: loading, action: action, block: block)
    }
    
    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和最多两个动作按钮
    public func showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, actions: [Any]?, block: ((Int, Any) -> Void)?) {
        base.__fw_showEmpty(withText: text, detail: detail, image: image, loading: loading, actions: actions, block: block)
    }

    /// 隐藏空界面
    public func hideEmptyView() {
        base.__fw_hideEmpty()
    }
    
}

extension Wrapper where Base: UIViewController {
    
    /// 设置空界面外间距，默认zero
    public var emptyInsets: UIEdgeInsets {
        get { return base.__fw_emptyInsets }
        set { base.__fw_emptyInsets = newValue }
    }
    
    /// 获取正在显示的空界面视图
    public var showingEmptyView: UIView? {
        return base.__fw_showingEmptyView
    }

    /// 是否显示空界面
    public var hasEmptyView: Bool {
        return base.__fw_hasEmptyView
    }

    /// 显示空界面加载视图
    public func showEmptyLoading() {
        base.__fw_showEmptyViewLoading()
    }

    /// 显示空界面，指定文本、详细文本、图片和动作按钮
    public func showEmptyView(text: Any? = nil, detail: Any? = nil, image: UIImage? = nil, action: Any? = nil, block: ((Any) -> Void)? = nil) {
        base.__fw_showEmptyView(withText: text, detail: detail, image: image, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和动作按钮
    public func showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, action: Any?, block: ((Any) -> Void)?) {
        base.__fw_showEmptyView(withText: text, detail: detail, image: image, loading: loading, action: action, block: block)
    }
    
    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和最多两个动作按钮
    public func showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, actions: [Any]?, block: ((Int, Any) -> Void)?) {
        base.__fw_showEmptyView(withText: text, detail: detail, image: image, loading: loading, actions: actions, block: block)
    }

    /// 隐藏空界面
    public func hideEmptyView() {
        base.__fw_hideEmptyView()
    }
    
}

extension Wrapper where Base: UIScrollView {
    
    /// 空界面代理，默认nil
    public weak var emptyViewDelegate: EmptyViewDelegate? {
        get { return base.__fw_emptyViewDelegate }
        set { base.__fw_emptyViewDelegate = newValue }
    }

    /// 刷新空界面
    public func reloadEmptyView() {
        base.__fw_reloadEmpty()
    }
    
    /// 当前数据总条数，默认自动获取tableView和collectionView，支持自定义覆盖(优先级高，小于0还原)
    public var totalDataCount: Int {
        get { return base.__fw_totalDataCount }
        set { base.__fw_totalDataCount = newValue }
    }
    
    /// 滚动视图自定义浮层，用于显示空界面等，兼容UITableView|UICollectionView
    public var overlayView: UIView {
        return base.__fw_overlayView
    }

    /// 是否显示自定义浮层
    public var hasOverlayView: Bool {
        return base.__fw_hasOverlayView
    }

    /// 显示自定义浮层，默认不执行渐变动画，自动添加到滚动视图顶部、表格视图底部
    public func showOverlayView(animated: Bool = false) {
        base.__fw_showOverlayView(animated: animated)
    }

    /// 隐藏自定义浮层，自动从滚动视图移除
    public func hideOverlayView() {
        base.__fw_hideOverlayView()
    }
    
}

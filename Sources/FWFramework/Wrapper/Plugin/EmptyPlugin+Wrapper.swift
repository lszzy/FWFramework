//
//  EmptyPlugin+Wrapper.swift
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
    public var emptyPlugin: EmptyPlugin! {
        get { return base.fw_emptyPlugin }
        set { base.fw_emptyPlugin = newValue }
    }
    
    /// 设置空界面外间距，默认zero
    public var emptyInsets: UIEdgeInsets {
        get { return base.fw_emptyInsets }
        set { base.fw_emptyInsets = newValue }
    }
    
    /// 获取正在显示的空界面视图
    public var showingEmptyView: UIView? {
        return base.fw_showingEmptyView
    }

    /// 是否显示空界面
    public var hasEmptyView: Bool {
        return base.fw_hasEmptyView
    }

    /// 显示空界面加载视图
    public func showEmptyLoading() {
        base.fw_showEmptyLoading()
    }
    
    /// 显示错误空界面
    public func showEmptyView(error: Error?, action: AttributedStringParameter? = nil, block: ((Any) -> Void)? = nil) {
        base.fw_showEmptyView(error: error, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片和动作按钮
    public func showEmptyView(text: AttributedStringParameter? = nil, detail: AttributedStringParameter? = nil, image: UIImage? = nil, action: AttributedStringParameter? = nil, block: ((Any) -> Void)? = nil) {
        base.fw_showEmptyView(text: text, detail: detail, image: image, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和动作按钮
    public func showEmptyView(text: AttributedStringParameter?, detail: AttributedStringParameter?, image: UIImage?, loading: Bool, action: AttributedStringParameter?, block: ((Any) -> Void)?, customBlock: ((Any) -> Void)? = nil) {
        base.fw_showEmptyView(text: text, detail: detail, image: image, loading: loading, action: action, block: block, customBlock: customBlock)
    }
    
    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和最多两个动作按钮
    public func showEmptyView(text: AttributedStringParameter?, detail: AttributedStringParameter?, image: UIImage?, loading: Bool, actions: [AttributedStringParameter]?, block: ((Int, Any) -> Void)?, customBlock: ((Any) -> Void)? = nil) {
        base.fw_showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: actions, block: block, customBlock: customBlock)
    }

    /// 隐藏空界面
    public func hideEmptyView() {
        base.fw_hideEmptyView()
    }
    
}

extension Wrapper where Base: UIViewController {
    
    /// 设置空界面外间距，默认zero
    public var emptyInsets: UIEdgeInsets {
        get { return base.fw_emptyInsets }
        set { base.fw_emptyInsets = newValue }
    }
    
    /// 获取正在显示的空界面视图
    public var showingEmptyView: UIView? {
        return base.fw_showingEmptyView
    }

    /// 是否显示空界面
    public var hasEmptyView: Bool {
        return base.fw_hasEmptyView
    }

    /// 显示空界面加载视图
    public func showEmptyLoading() {
        base.fw_showEmptyLoading()
    }
    
    /// 显示错误空界面
    public func showEmptyView(error: Error?, action: AttributedStringParameter? = nil, block: ((Any) -> Void)? = nil) {
        base.fw_showEmptyView(error: error, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片和动作按钮
    public func showEmptyView(text: AttributedStringParameter? = nil, detail: AttributedStringParameter? = nil, image: UIImage? = nil, action: AttributedStringParameter? = nil, block: ((Any) -> Void)? = nil) {
        base.fw_showEmptyView(text: text, detail: detail, image: image, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和动作按钮
    public func showEmptyView(text: AttributedStringParameter?, detail: AttributedStringParameter?, image: UIImage?, loading: Bool, action: AttributedStringParameter?, block: ((Any) -> Void)?, customBlock: ((Any) -> Void)? = nil) {
        base.fw_showEmptyView(text: text, detail: detail, image: image, loading: loading, action: action, block: block, customBlock: customBlock)
    }
    
    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和最多两个动作按钮
    public func showEmptyView(text: AttributedStringParameter?, detail: AttributedStringParameter?, image: UIImage?, loading: Bool, actions: [AttributedStringParameter]?, block: ((Int, Any) -> Void)?, customBlock: ((Any) -> Void)? = nil) {
        base.fw_showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: actions, block: block, customBlock: customBlock)
    }

    /// 隐藏空界面
    public func hideEmptyView() {
        base.fw_hideEmptyView()
    }
    
}

extension Wrapper where Base: UIScrollView {
    
    /// 空界面代理，默认nil。[DZNEmptyDataSet](https://github.com/dzenbot/DZNEmptyDataSet)
    public weak var emptyViewDelegate: EmptyViewDelegate? {
        get { return base.fw_emptyViewDelegate }
        set { base.fw_emptyViewDelegate = newValue }
    }

    /// 刷新空界面
    public func reloadEmptyView() {
        base.fw_reloadEmptyView()
    }
    
    /// 当前数据总条数，默认自动调用tableView和collectionView的dataSource，支持自定义覆盖(优先级高，小于0还原)
    ///
    /// 注意：此处为当前数据源总数，并非当前cell总数，即使tableView未reloadData也会返回新总数
    public var totalDataCount: Int {
        get { return base.fw_totalDataCount }
        set { base.fw_totalDataCount = newValue }
    }
    
    /// 滚动视图自定义浮层，用于显示空界面等，兼容UITableView|UICollectionView
    public var overlayView: UIView {
        return base.fw_overlayView
    }

    /// 是否显示自定义浮层
    public var hasOverlayView: Bool {
        return base.fw_hasOverlayView
    }

    /// 显示自定义浮层，默认不执行渐变动画，自动添加到滚动视图顶部、表格视图底部
    public func showOverlayView(animated: Bool = false) {
        base.fw_showOverlayView(animated: animated)
    }

    /// 隐藏自定义浮层，自动从滚动视图移除
    public func hideOverlayView() {
        base.fw_hideOverlayView()
    }
    
}

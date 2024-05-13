//
//  EmptyPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UIView
extension Wrapper where Base: UIView {
    /// 自定义空界面插件，未设置时自动从插件池加载
    public var emptyPlugin: EmptyPlugin! {
        get {
            if let emptyPlugin = property(forName: "emptyPlugin") as? EmptyPlugin {
                return emptyPlugin
            } else if let emptyPlugin = PluginManager.loadPlugin(EmptyPlugin.self) {
                return emptyPlugin
            }
            return EmptyPluginImpl.shared
        }
        set {
            setProperty(newValue, forName: "emptyPlugin")
        }
    }
    
    /// 设置空界面外间距，默认zero
    public var emptyInsets: UIEdgeInsets {
        get {
            var view: UIView = base
            if let scrollView = base as? UIScrollView {
                view = scrollView.fw.overlayView
            }
            if let value = view.fw.property(forName: "emptyInsets") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            var view: UIView = base
            if let scrollView = base as? UIScrollView {
                view = scrollView.fw.overlayView
            }
            view.fw.setProperty(NSValue(uiEdgeInsets: newValue), forName: "emptyInsets")
        }
    }
    
    /// 获取正在显示的空界面视图
    public var showingEmptyView: UIView? {
        let plugin = emptyPlugin ?? EmptyPluginImpl.shared
        if let scrollView = base as? UIScrollView {
            if scrollView.fw.hasOverlayView {
                return plugin.showingEmptyView(in: scrollView.fw.overlayView)
            }
            return nil
        } else {
            return plugin.showingEmptyView(in: base)
        }
    }

    /// 是否显示空界面
    public var hasEmptyView: Bool {
        return showingEmptyView != nil
    }

    /// 显示空界面加载视图
    public func showEmptyLoading() {
        showEmptyView(text: nil, detail: nil, image: nil, loading: true, action: nil, block: nil)
    }
    
    /// 显示错误空界面
    public func showEmptyView(error: Error?, action: AttributedStringParameter? = nil, block: ((Any) -> Void)? = nil) {
        showEmptyView(
            text: EmptyPluginImpl.shared.errorTextFormatter?(error) ?? error?.localizedDescription,
            detail: EmptyPluginImpl.shared.errorDetailFormatter?(error),
            image: EmptyPluginImpl.shared.errorImageFormatter?(error),
            action: block != nil ? (action ?? EmptyPluginImpl.shared.errorActionFormatter?(error)) : nil,
            block: block
        )
    }

    /// 显示空界面，指定文本、详细文本、图片和动作按钮
    public func showEmptyView(text: AttributedStringParameter? = nil, detail: AttributedStringParameter? = nil, image: UIImage? = nil, action: AttributedStringParameter? = nil, block: ((Any) -> Void)? = nil) {
        showEmptyView(text: text, detail: detail, image: image, loading: false, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和动作按钮
    public func showEmptyView(text: AttributedStringParameter?, detail: AttributedStringParameter?, image: UIImage?, loading: Bool, action: AttributedStringParameter?, block: ((Any) -> Void)?, customBlock: ((Any) -> Void)? = nil) {
        showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: action != nil ? [action!] : nil, block: block != nil ? { _, sender in block?(sender) } : nil, customBlock: customBlock)
    }
    
    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和最多两个动作按钮
    public func showEmptyView(text: AttributedStringParameter?, detail: AttributedStringParameter?, image: UIImage?, loading: Bool, actions: [AttributedStringParameter]?, block: ((Int, Any) -> Void)?, customBlock: ((Any) -> Void)? = nil) {
        let plugin = emptyPlugin ?? EmptyPluginImpl.shared
        if let scrollView = base as? UIScrollView {
            scrollView.fw.showOverlayView()
            plugin.showEmptyView(text: text?.attributedStringValue, detail: detail?.attributedStringValue, image: image, loading: loading, actions: actions?.map({ $0.attributedStringValue }), block: block, customBlock: customBlock, in: scrollView.fw.overlayView)
        } else {
            plugin.showEmptyView(text: text?.attributedStringValue, detail: detail?.attributedStringValue, image: image, loading: loading, actions: actions?.map({ $0.attributedStringValue }), block: block, customBlock: customBlock, in: base)
        }
    }

    /// 隐藏空界面
    public func hideEmptyView() {
        let plugin = emptyPlugin ?? EmptyPluginImpl.shared
        if let scrollView = base as? UIScrollView {
            plugin.hideEmptyView(in: scrollView.fw.overlayView)
            scrollView.fw.hideOverlayView()
        } else {
            plugin.hideEmptyView(in: base)
        }
    }
}

// MARK: - Wrapper+UIViewController
extension Wrapper where Base: UIViewController {
    /// 自定义空界面插件，未设置时自动从插件池加载
    public var emptyPlugin: EmptyPlugin! {
        get { return base.view.fw.emptyPlugin }
        set { base.view.fw.emptyPlugin = newValue }
    }
    
    /// 设置空界面外间距，默认zero
    public var emptyInsets: UIEdgeInsets {
        get { return base.view.fw.emptyInsets }
        set { base.view.fw.emptyInsets = newValue }
    }
    
    /// 获取正在显示的空界面视图
    public var showingEmptyView: UIView? {
        return base.view.fw.showingEmptyView
    }

    /// 是否显示空界面
    public var hasEmptyView: Bool {
        return base.view.fw.hasEmptyView
    }

    /// 显示空界面加载视图
    public func showEmptyLoading() {
        base.view.fw.showEmptyLoading()
    }
    
    /// 显示错误空界面
    public func showEmptyView(error: Error?, action: AttributedStringParameter? = nil, block: ((Any) -> Void)? = nil) {
        base.view.fw.showEmptyView(error: error, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片和动作按钮
    public func showEmptyView(text: AttributedStringParameter? = nil, detail: AttributedStringParameter? = nil, image: UIImage? = nil, action: AttributedStringParameter? = nil, block: ((Any) -> Void)? = nil) {
        base.view.fw.showEmptyView(text: text, detail: detail, image: image, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和动作按钮
    public func showEmptyView(text: AttributedStringParameter?, detail: AttributedStringParameter?, image: UIImage?, loading: Bool, action: AttributedStringParameter?, block: ((Any) -> Void)?, customBlock: ((Any) -> Void)? = nil) {
        base.view.fw.showEmptyView(text: text, detail: detail, image: image, loading: loading, action: action, block: block, customBlock: customBlock)
    }
    
    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和最多两个动作按钮
    public func showEmptyView(text: AttributedStringParameter?, detail: AttributedStringParameter?, image: UIImage?, loading: Bool, actions: [AttributedStringParameter]?, block: ((Int, Any) -> Void)?, customBlock: ((Any) -> Void)? = nil) {
        base.view.fw.showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: actions, block: block, customBlock: customBlock)
    }

    /// 隐藏空界面
    public func hideEmptyView() {
        base.view.fw.hideEmptyView()
    }
}

// MARK: - Wrapper+UIScrollView
extension Wrapper where Base: UIScrollView {
    /// 空界面代理，默认nil。[DZNEmptyDataSet](https://github.com/dzenbot/DZNEmptyDataSet)
    public weak var emptyViewDelegate: EmptyViewDelegate? {
        get {
            return property(forName: "emptyViewDelegate") as? EmptyViewDelegate
        }
        set {
            if newValue == nil { invalidateEmptyView() }
            setPropertyWeak(newValue, forName: "emptyViewDelegate")
            
            FrameworkAutoloader.swizzleEmptyPlugin()
        }
    }

    /// 刷新空界面
    public func reloadEmptyView() {
        guard let emptyViewDelegate = emptyViewDelegate else { return }
        
        var shouldDisplay = emptyViewDelegate.emptyViewForceDisplay(base)
        if !shouldDisplay {
            shouldDisplay = emptyViewDelegate.emptyViewShouldDisplay(base) && totalDataCount == 0
        }
        
        let hideSuccess = invalidateEmptyView()
        if shouldDisplay {
            setPropertyBool(true, forName: "invalidateEmptyView")
            
            base.isScrollEnabled = emptyViewDelegate.emptyViewShouldScroll(base)
            
            let fadeAnimated = EmptyPluginImpl.shared.fadeAnimated
            EmptyPluginImpl.shared.fadeAnimated = hideSuccess ? false : fadeAnimated
            emptyViewDelegate.showEmptyView(base)
            EmptyPluginImpl.shared.fadeAnimated = fadeAnimated
        }
    }
    
    /// 当前数据总条数，默认自动调用tableView和collectionView的dataSource，支持自定义覆盖(优先级高，小于0还原)
    ///
    /// 注意：此处为当前数据源总数，并非当前cell总数，即使tableView未reloadData也会返回新总数
    public var totalDataCount: Int {
        get {
            if let totalCount = propertyNumber(forName: "totalDataCount")?.intValue,
               totalCount >= 0 {
                return totalCount
            }
            
            var totalCount: Int = 0
            if let tableView = base as? UITableView {
                let dataSource = tableView.dataSource
                
                var sections: Int = 1
                if let dataSource = dataSource, dataSource.responds(to: #selector(UITableViewDataSource.numberOfSections(in:))) {
                    sections = dataSource.numberOfSections!(in: tableView)
                }
                
                if let dataSource = dataSource, dataSource.responds(to: #selector(UITableViewDataSource.tableView(_:numberOfRowsInSection:))) {
                    for section in 0 ..< sections {
                        totalCount += dataSource.tableView(tableView, numberOfRowsInSection: section)
                    }
                }
            } else if let collectionView = base as? UICollectionView {
                let dataSource = collectionView.dataSource
                
                var sections: Int = 1
                if let dataSource = dataSource, dataSource.responds(to: #selector(UICollectionViewDataSource.numberOfSections(in:))) {
                    sections = dataSource.numberOfSections!(in: collectionView)
                }
                
                if let dataSource = dataSource, dataSource.responds(to: #selector(UICollectionViewDataSource.collectionView(_:numberOfItemsInSection:))) {
                    for section in 0 ..< sections {
                        totalCount += dataSource.collectionView(collectionView, numberOfItemsInSection: section)
                    }
                }
            }
            return totalCount
        }
        set {
            setPropertyNumber(NSNumber(value: newValue), forName: "totalDataCount")
        }
    }
    
    @discardableResult
    private func invalidateEmptyView() -> Bool {
        if !propertyBool(forName: "invalidateEmptyView") { return false }
        setProperty(nil, forName: "invalidateEmptyView")
        
        base.isScrollEnabled = true
        
        if let emptyViewDelegate = emptyViewDelegate {
            emptyViewDelegate.hideEmptyView(base)
        } else {
            hideEmptyView()
        }
        return true
    }
    
    /// 滚动视图自定义浮层，用于显示空界面等，兼容UITableView|UICollectionView
    public var overlayView: UIView {
        if let overlayView = property(forName: "overlayView") as? UIView {
            return overlayView
        } else {
            let overlayView = ScrollOverlayView()
            overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlayView.isUserInteractionEnabled = true
            overlayView.backgroundColor = .clear
            overlayView.clipsToBounds = true
            
            setProperty(overlayView, forName: "overlayView")
            return overlayView
        }
    }

    /// 是否显示自定义浮层
    public var hasOverlayView: Bool {
        let overlayView = property(forName: "overlayView") as? UIView
        return overlayView != nil && overlayView?.superview != nil
    }

    /// 显示自定义浮层，默认不执行渐变动画，自动添加到滚动视图顶部、表格视图底部
    public func showOverlayView(animated: Bool = false) {
        let overlayView = overlayView
        if overlayView.superview == nil {
            (overlayView as? ScrollOverlayView)?.fadeAnimated = animated
            if (base is UITableView || base is UICollectionView) && base.subviews.count > 1 {
                base.insertSubview(overlayView, at: 0)
            } else {
                base.addSubview(overlayView)
            }
        }
    }

    /// 隐藏自定义浮层，自动从滚动视图移除
    public func hideOverlayView() {
        let overlayView = property(forName: "overlayView") as? UIView
        if overlayView != nil && overlayView?.superview != nil {
            overlayView?.removeFromSuperview()
        }
    }
}

// MARK: - EmptyPlugin
/// 空界面插件协议，应用可自定义空界面插件实现
public protocol EmptyPlugin: AnyObject {
    
    /// 显示空界面，指定文本、详细文本、图片、加载视图和最多两个动作按钮
    func showEmptyView(text: NSAttributedString?, detail: NSAttributedString?, image: UIImage?, loading: Bool, actions: [NSAttributedString]?, block: ((Int, Any) -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView)

    /// 隐藏空界面
    func hideEmptyView(in view: UIView)

    /// 获取正在显示的空界面视图
    func showingEmptyView(in view: UIView) -> UIView?
    
}

extension EmptyPlugin {
    
    /// 默认实现，显示空界面，指定文本、详细文本、图片、加载视图和最多两个动作按钮
    public func showEmptyView(text: NSAttributedString?, detail: NSAttributedString?, image: UIImage?, loading: Bool, actions: [NSAttributedString]?, block: ((Int, Any) -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView) {
        EmptyPluginImpl.shared.showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: actions, block: block, customBlock: customBlock, in: view)
    }

    /// 默认实现，隐藏空界面
    public func hideEmptyView(in view: UIView) {
        EmptyPluginImpl.shared.hideEmptyView(in: view)
    }

    /// 默认实现，获取正在显示的空界面视图
    public func showingEmptyView(in view: UIView) -> UIView? {
        return EmptyPluginImpl.shared.showingEmptyView(in: view)
    }
    
}

// MARK: - EmptyViewDelegate
/// 空界面代理协议
public protocol EmptyViewDelegate: AnyObject {
    
    /// 显示空界面，默认调用UIScrollView.showEmptyView
    func showEmptyView(_ scrollView: UIScrollView)

    /// 隐藏空界面，默认调用UIScrollView.hideEmptyView
    func hideEmptyView(_ scrollView: UIScrollView)

    /// 显示空界面时是否允许滚动，默认NO
    func emptyViewShouldScroll(_ scrollView: UIScrollView) -> Bool

    /// 无数据时是否显示空界面，默认YES
    func emptyViewShouldDisplay(_ scrollView: UIScrollView) -> Bool

    /// 有数据时是否强制显示空界面，默认NO
    func emptyViewForceDisplay(_ scrollView: UIScrollView) -> Bool
    
}

extension EmptyViewDelegate {
    
    /// 默认实现，显示空界面，默认调用UIScrollView.showEmptyView
    public func showEmptyView(_ scrollView: UIScrollView) {
        scrollView.fw.showEmptyView()
    }

    /// 默认实现，隐藏空界面，默认调用UIScrollView.hideEmptyView
    public func hideEmptyView(_ scrollView: UIScrollView) {
        scrollView.fw.hideEmptyView()
    }

    /// 默认实现，显示空界面时是否允许滚动，默认NO
    public func emptyViewShouldScroll(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    /// 默认实现，无数据时是否显示空界面，默认YES
    public func emptyViewShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return true
    }

    /// 默认实现，有数据时是否强制显示空界面，默认NO
    public func emptyViewForceDisplay(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
}

// MARK: - FrameworkAutoloader+EmptyPlugin
extension FrameworkAutoloader {
    
    private static var swizzleEmptyPluginFinished = false
    
    fileprivate static func swizzleEmptyPlugin() {
        guard !swizzleEmptyPluginFinished else { return }
        swizzleEmptyPluginFinished = true
        
        NSObject.fw.swizzleInstanceMethod(
            UITableView.self,
            selector: #selector(UITableView.reloadData),
            methodSignature: (@convention(c) (UITableView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UITableView) -> Void).self
        ) { store in { selfObject in
            selfObject.fw.reloadEmptyView()
            store.original(selfObject, store.selector)
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UITableView.self,
            selector: #selector(UITableView.endUpdates),
            methodSignature: (@convention(c) (UITableView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UITableView) -> Void).self
        ) { store in { selfObject in
            selfObject.fw.reloadEmptyView()
            store.original(selfObject, store.selector)
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UICollectionView.self,
            selector: #selector(UICollectionView.reloadData),
            methodSignature: (@convention(c) (UICollectionView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UICollectionView) -> Void).self
        ) { store in { selfObject in
            selfObject.fw.reloadEmptyView()
            store.original(selfObject, store.selector)
        }}
    }
    
}

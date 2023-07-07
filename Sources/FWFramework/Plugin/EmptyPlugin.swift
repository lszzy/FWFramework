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

@_spi(FW) extension UIView {
    
    /// 自定义空界面插件，未设置时自动从插件池加载
    public var fw_emptyPlugin: EmptyPlugin! {
        get {
            if let emptyPlugin = fw_property(forName: "fw_emptyPlugin") as? EmptyPlugin {
                return emptyPlugin
            } else if let emptyPlugin = PluginManager.loadPlugin(EmptyPlugin.self) {
                return emptyPlugin
            }
            return EmptyPluginImpl.shared
        }
        set {
            fw_setProperty(newValue, forName: "fw_emptyPlugin")
        }
    }
    
    /// 设置空界面外间距，默认zero
    @objc(__fw_emptyInsets)
    public var fw_emptyInsets: UIEdgeInsets {
        get {
            var view = self
            if let scrollView = self as? UIScrollView {
                view = scrollView.fw_overlayView
            }
            if let value = view.fw_property(forName: "fw_emptyInsets") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            var view = self
            if let scrollView = self as? UIScrollView {
                view = scrollView.fw_overlayView
            }
            view.fw_setProperty(NSValue(uiEdgeInsets: newValue), forName: "fw_emptyInsets")
        }
    }
    
    /// 获取正在显示的空界面视图
    public var fw_showingEmptyView: UIView? {
        var plugin: EmptyPlugin
        if let emptyPlugin = self.fw_emptyPlugin, emptyPlugin.responds(to: #selector(EmptyPlugin.showingEmpty(_:))) {
            plugin = emptyPlugin
        } else {
            plugin = EmptyPluginImpl.shared
        }
        
        if let scrollView = self as? UIScrollView {
            if scrollView.fw_hasOverlayView {
                return plugin.showingEmpty!(scrollView.fw_overlayView)
            }
            return nil
        } else {
            return plugin.showingEmpty!(self)
        }
    }

    /// 是否显示空界面
    public var fw_hasEmptyView: Bool {
        return fw_showingEmptyView != nil
    }

    /// 显示空界面加载视图
    public func fw_showEmptyLoading() {
        fw_showEmptyView(text: nil, detail: nil, image: nil, loading: true, action: nil, block: nil)
    }
    
    /// 显示错误空界面
    public func fw_showEmptyView(error: Error?, action: Any? = nil, block: ((Any) -> Void)? = nil) {
        fw_showEmptyView(
            text: EmptyPluginImpl.shared.errorTextFormatter?(error) ?? error?.localizedDescription,
            detail: EmptyPluginImpl.shared.errorDetailFormatter?(error),
            image: EmptyPluginImpl.shared.errorImageFormatter?(error),
            action: action ?? EmptyPluginImpl.shared.errorActionFormatter?(error),
            block: block
        )
    }

    /// 显示空界面，指定文本、详细文本、图片和动作按钮
    public func fw_showEmptyView(text: Any? = nil, detail: Any? = nil, image: UIImage? = nil, action: Any? = nil, block: ((Any) -> Void)? = nil) {
        fw_showEmptyView(text: text, detail: detail, image: image, loading: false, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和动作按钮
    public func fw_showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, action: Any?, block: ((Any) -> Void)?) {
        fw_showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: action != nil ? [action!] : nil, block: block != nil ? { _, sender in block?(sender) } : nil)
    }
    
    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和最多两个动作按钮
    public func fw_showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, actions: [Any]?, block: ((Int, Any) -> Void)?) {
        var plugin: EmptyPlugin
        if let emptyPlugin = self.fw_emptyPlugin, emptyPlugin.responds(to: #selector(EmptyPlugin.showEmptyView(withText:detail:image:loading:actions:block:in:))) {
            plugin = emptyPlugin
        } else {
            plugin = EmptyPluginImpl.shared
        }
        
        if let scrollView = self as? UIScrollView {
            scrollView.fw_showOverlayView()
            plugin.showEmptyView?(withText: text, detail: detail, image: image, loading: loading, actions: actions, block: block, in: scrollView.fw_overlayView)
        } else {
            plugin.showEmptyView?(withText: text, detail: detail, image: image, loading: loading, actions: actions, block: block, in: self)
        }
    }

    /// 隐藏空界面
    public func fw_hideEmptyView() {
        var plugin: EmptyPlugin
        if let emptyPlugin = self.fw_emptyPlugin, emptyPlugin.responds(to: #selector(EmptyPlugin.hideEmpty(_:))) {
            plugin = emptyPlugin
        } else {
            plugin = EmptyPluginImpl.shared
        }
        
        if let scrollView = self as? UIScrollView {
            plugin.hideEmpty?(scrollView.fw_overlayView)
            scrollView.fw_hideOverlayView()
        } else {
            plugin.hideEmpty?(self)
        }
    }
    
}

@_spi(FW) extension UIViewController {
    
    /// 设置空界面外间距，默认zero
    public var fw_emptyInsets: UIEdgeInsets {
        get { return self.view.fw_emptyInsets }
        set { self.view.fw_emptyInsets = newValue }
    }
    
    /// 获取正在显示的空界面视图
    public var fw_showingEmptyView: UIView? {
        return self.view.fw_showingEmptyView
    }

    /// 是否显示空界面
    public var fw_hasEmptyView: Bool {
        return self.view.fw_hasEmptyView
    }

    /// 显示空界面加载视图
    public func fw_showEmptyLoading() {
        self.view.fw_showEmptyLoading()
    }
    
    /// 显示错误空界面
    public func fw_showEmptyView(error: Error?, action: Any? = nil, block: ((Any) -> Void)? = nil) {
        self.view.fw_showEmptyView(error: error, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片和动作按钮
    @objc(__fw_showEmptyViewWithText:detail:image:action:block:)
    public func fw_showEmptyView(text: Any? = nil, detail: Any? = nil, image: UIImage? = nil, action: Any? = nil, block: ((Any) -> Void)? = nil) {
        self.view.fw_showEmptyView(text: text, detail: detail, image: image, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和动作按钮
    public func fw_showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, action: Any?, block: ((Any) -> Void)?) {
        self.view.fw_showEmptyView(text: text, detail: detail, image: image, loading: loading, action: action, block: block)
    }
    
    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和最多两个动作按钮
    public func fw_showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, actions: [Any]?, block: ((Int, Any) -> Void)?) {
        self.view.fw_showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: actions, block: block)
    }

    /// 隐藏空界面
    public func fw_hideEmptyView() {
        self.view.fw_hideEmptyView()
    }
    
}

@_spi(FW) extension UIScrollView {
    
    /// 空界面代理，默认nil。[DZNEmptyDataSet](https://github.com/dzenbot/DZNEmptyDataSet)
    public weak var fw_emptyViewDelegate: EmptyViewDelegate? {
        get {
            return fw_property(forName: "fw_emptyViewDelegate") as? EmptyViewDelegate
        }
        set {
            if newValue == nil { self.fw_invalidateEmptyView() }
            fw_setPropertyWeak(newValue, forName: "fw_emptyViewDelegate")
            
            UIScrollView.fw_enableEmptyPlugin()
        }
    }

    /// 刷新空界面
    public func fw_reloadEmptyView() {
        guard let emptyViewDelegate = self.fw_emptyViewDelegate else { return }
        
        var shouldDisplay = false
        if emptyViewDelegate.responds(to: #selector(EmptyViewDelegate.emptyViewForceDisplay(_:))) {
            shouldDisplay = emptyViewDelegate.emptyViewForceDisplay!(self)
        }
        if !shouldDisplay {
            if emptyViewDelegate.responds(to: #selector(EmptyViewDelegate.emptyViewShouldDisplay(_:))) {
                shouldDisplay = emptyViewDelegate.emptyViewShouldDisplay!(self) && self.fw_emptyItemsCount() == 0
            } else {
                shouldDisplay = self.fw_emptyItemsCount() == 0
            }
        }
        
        let hideSuccess = self.fw_invalidateEmptyView()
        if shouldDisplay {
            fw_setPropertyBool(true, forName: "fw_invalidateEmptyView")
            
            if emptyViewDelegate.responds(to: #selector(EmptyViewDelegate.emptyViewShouldScroll(_:))) {
                self.isScrollEnabled = emptyViewDelegate.emptyViewShouldScroll!(self)
            } else {
                self.isScrollEnabled = false
            }
            
            let fadeAnimated = EmptyPluginImpl.shared.fadeAnimated
            EmptyPluginImpl.shared.fadeAnimated = hideSuccess ? false : fadeAnimated
            if emptyViewDelegate.responds(to: #selector(EmptyViewDelegate.showEmpty(_:))) {
                emptyViewDelegate.showEmpty?(self)
            } else {
                self.fw_showEmptyView()
            }
            EmptyPluginImpl.shared.fadeAnimated = fadeAnimated
        }
    }
    
    @discardableResult
    private func fw_invalidateEmptyView() -> Bool {
        if !fw_propertyBool(forName: "fw_invalidateEmptyView") { return false }
        fw_setProperty(nil, forName: "fw_invalidateEmptyView")
        
        self.isScrollEnabled = true
        
        if self.fw_emptyViewDelegate?.responds(to: #selector(EmptyViewDelegate.hideEmpty(_:))) ?? false {
            self.fw_emptyViewDelegate?.hideEmpty?(self)
        } else {
            self.fw_hideEmptyView()
        }
        return true
    }
    
    private func fw_emptyItemsCount() -> Int {
        var items: Int = 0
        if let tableView = self as? UITableView {
            let dataSource = tableView.dataSource
            
            var sections: Int = 1
            if let dataSource = dataSource, dataSource.responds(to: #selector(UITableViewDataSource.numberOfSections(in:))) {
                sections = dataSource.numberOfSections!(in: tableView)
            }
            
            if let dataSource = dataSource, dataSource.responds(to: #selector(UITableViewDataSource.tableView(_:numberOfRowsInSection:))) {
                for section in 0 ..< sections {
                    items += dataSource.tableView(tableView, numberOfRowsInSection: section)
                }
            }
        } else if let collectionView = self as? UICollectionView {
            let dataSource = collectionView.dataSource
            
            var sections: Int = 1
            if let dataSource = dataSource, dataSource.responds(to: #selector(UICollectionViewDataSource.numberOfSections(in:))) {
                sections = dataSource.numberOfSections!(in: collectionView)
            }
            
            if let dataSource = dataSource, dataSource.responds(to: #selector(UICollectionViewDataSource.collectionView(_:numberOfItemsInSection:))) {
                for section in 0 ..< sections {
                    items += dataSource.collectionView(collectionView, numberOfItemsInSection: section)
                }
            }
        }
        return items
    }
    
    private static func fw_enableEmptyPlugin() {
        guard !fw_staticEmptyPluginEnabled else { return }
        fw_staticEmptyPluginEnabled = true
        
        NSObject.fw_swizzleInstanceMethod(
            UITableView.self,
            selector: #selector(UITableView.reloadData),
            methodSignature: (@convention(c) (UITableView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UITableView) -> Void).self
        ) { store in { selfObject in
            selfObject.fw_reloadEmptyView()
            store.original(selfObject, store.selector)
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UITableView.self,
            selector: #selector(UITableView.endUpdates),
            methodSignature: (@convention(c) (UITableView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UITableView) -> Void).self
        ) { store in { selfObject in
            selfObject.fw_reloadEmptyView()
            store.original(selfObject, store.selector)
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UICollectionView.self,
            selector: #selector(UICollectionView.reloadData),
            methodSignature: (@convention(c) (UICollectionView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UICollectionView) -> Void).self
        ) { store in { selfObject in
            selfObject.fw_reloadEmptyView()
            store.original(selfObject, store.selector)
        }}
    }
    
    private static var fw_staticEmptyPluginEnabled = false
    
    /// 滚动视图自定义浮层，用于显示空界面等，兼容UITableView|UICollectionView
    public var fw_overlayView: UIView {
        if let overlayView = fw_property(forName: "fw_overlayView") as? UIView {
            return overlayView
        } else {
            let overlayView = ScrollOverlayView()
            overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlayView.isUserInteractionEnabled = true
            overlayView.backgroundColor = .clear
            overlayView.clipsToBounds = true
            
            fw_setProperty(overlayView, forName: "fw_overlayView")
            return overlayView
        }
    }

    /// 是否显示自定义浮层
    public var fw_hasOverlayView: Bool {
        let overlayView = fw_property(forName: "fw_overlayView") as? UIView
        return overlayView != nil && overlayView?.superview != nil
    }

    /// 显示自定义浮层，默认不执行渐变动画，自动添加到滚动视图顶部、表格视图底部
    public func fw_showOverlayView(animated: Bool = false) {
        let overlayView = self.fw_overlayView
        if overlayView.superview == nil {
            (overlayView as? ScrollOverlayView)?.fadeAnimated = animated
            if (self is UITableView || self is UICollectionView) && self.subviews.count > 1 {
                self.insertSubview(overlayView, at: 0)
            } else {
                self.addSubview(overlayView)
            }
        }
    }

    /// 隐藏自定义浮层，自动从滚动视图移除
    public func fw_hideOverlayView() {
        let overlayView = fw_property(forName: "fw_overlayView") as? UIView
        if overlayView != nil && overlayView?.superview != nil {
            overlayView?.removeFromSuperview()
        }
    }
    
}

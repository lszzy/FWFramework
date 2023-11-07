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

// MARK: - EmptyPlugin
/// 空界面插件协议，应用可自定义空界面插件实现
public protocol EmptyPlugin: AnyObject {
    
    /// 显示空界面，指定文本、详细文本、图片、加载视图和最多两个动作按钮
    func showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, actions: [Any]?, block: ((Int, Any) -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView)

    /// 隐藏空界面
    func hideEmptyView(in view: UIView)

    /// 获取正在显示的空界面视图
    func showingEmptyView(in view: UIView) -> UIView?
    
}

extension EmptyPlugin {
    
    /// 默认实现，显示空界面，指定文本、详细文本、图片、加载视图和最多两个动作按钮
    public func showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, actions: [Any]?, block: ((Int, Any) -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView) {
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
        scrollView.fw_showEmptyView()
    }

    /// 默认实现，隐藏空界面，默认调用UIScrollView.hideEmptyView
    public func hideEmptyView(_ scrollView: UIScrollView) {
        scrollView.fw_hideEmptyView()
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

// MARK: - UIView+EmptyPlugin
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
        let plugin = self.fw_emptyPlugin ?? EmptyPluginImpl.shared
        if let scrollView = self as? UIScrollView {
            if scrollView.fw_hasOverlayView {
                return plugin.showingEmptyView(in: scrollView.fw_overlayView)
            }
            return nil
        } else {
            return plugin.showingEmptyView(in: self)
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
    public func fw_showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, action: Any?, block: ((Any) -> Void)?, customBlock: ((Any) -> Void)? = nil) {
        fw_showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: action != nil ? [action!] : nil, block: block != nil ? { _, sender in block?(sender) } : nil, customBlock: customBlock)
    }
    
    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和最多两个动作按钮
    public func fw_showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, actions: [Any]?, block: ((Int, Any) -> Void)?, customBlock: ((Any) -> Void)? = nil) {
        let plugin = self.fw_emptyPlugin ?? EmptyPluginImpl.shared
        if let scrollView = self as? UIScrollView {
            scrollView.fw_showOverlayView()
            plugin.showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: actions, block: block, customBlock: customBlock, in: scrollView.fw_overlayView)
        } else {
            plugin.showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: actions, block: block, customBlock: customBlock, in: self)
        }
    }

    /// 隐藏空界面
    public func fw_hideEmptyView() {
        let plugin = self.fw_emptyPlugin ?? EmptyPluginImpl.shared
        if let scrollView = self as? UIScrollView {
            plugin.hideEmptyView(in: scrollView.fw_overlayView)
            scrollView.fw_hideOverlayView()
        } else {
            plugin.hideEmptyView(in: self)
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
    public func fw_showEmptyView(text: Any? = nil, detail: Any? = nil, image: UIImage? = nil, action: Any? = nil, block: ((Any) -> Void)? = nil) {
        self.view.fw_showEmptyView(text: text, detail: detail, image: image, action: action, block: block)
    }

    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和动作按钮
    public func fw_showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, action: Any?, block: ((Any) -> Void)?, customBlock: ((Any) -> Void)? = nil) {
        self.view.fw_showEmptyView(text: text, detail: detail, image: image, loading: loading, action: action, block: block, customBlock: customBlock)
    }
    
    /// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和最多两个动作按钮
    public func fw_showEmptyView(text: Any?, detail: Any?, image: UIImage?, loading: Bool, actions: [Any]?, block: ((Int, Any) -> Void)?, customBlock: ((Any) -> Void)? = nil) {
        self.view.fw_showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: actions, block: block, customBlock: customBlock)
    }

    /// 隐藏空界面
    public func fw_hideEmptyView() {
        self.view.fw_hideEmptyView()
    }
    
}

// MARK: - UIScrollView+EmptyViewDelegate
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
        
        var shouldDisplay = emptyViewDelegate.emptyViewForceDisplay(self)
        if !shouldDisplay {
            shouldDisplay = emptyViewDelegate.emptyViewShouldDisplay(self) && self.fw_totalDataCount == 0
        }
        
        let hideSuccess = self.fw_invalidateEmptyView()
        if shouldDisplay {
            fw_setPropertyBool(true, forName: "fw_invalidateEmptyView")
            
            self.isScrollEnabled = emptyViewDelegate.emptyViewShouldScroll(self)
            
            let fadeAnimated = EmptyPluginImpl.shared.fadeAnimated
            EmptyPluginImpl.shared.fadeAnimated = hideSuccess ? false : fadeAnimated
            emptyViewDelegate.showEmptyView(self)
            EmptyPluginImpl.shared.fadeAnimated = fadeAnimated
        }
    }
    
    /// 当前数据总条数，默认自动调用tableView和collectionView的dataSource，支持自定义覆盖(优先级高，小于0还原)
    ///
    /// 注意：此处为当前数据源总数，并非当前cell总数，即使tableView未reloadData也会返回新总数
    public var fw_totalDataCount: Int {
        get {
            if let totalCount = fw_propertyNumber(forName: "fw_totalDataCount")?.intValue,
               totalCount >= 0 {
                return totalCount
            }
            
            var totalCount: Int = 0
            if let tableView = self as? UITableView {
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
            } else if let collectionView = self as? UICollectionView {
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
            fw_setPropertyNumber(NSNumber(value: newValue), forName: "fw_totalDataCount")
        }
    }
    
    @discardableResult
    private func fw_invalidateEmptyView() -> Bool {
        if !fw_propertyBool(forName: "fw_invalidateEmptyView") { return false }
        fw_setProperty(nil, forName: "fw_invalidateEmptyView")
        
        self.isScrollEnabled = true
        
        if let emptyViewDelegate = self.fw_emptyViewDelegate {
            emptyViewDelegate.hideEmptyView(self)
        } else {
            self.fw_hideEmptyView()
        }
        return true
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

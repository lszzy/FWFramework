//
//  RefreshPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

@_spi(FW) @objc extension UIScrollView {
    
    /// 自定义刷新插件，未设置时自动从插件池加载
    public var fw_refreshPlugin: RefreshPlugin! {
        get {
            if let refreshPlugin = fw_property(forName: "fw_refreshPlugin") as? RefreshPlugin {
                return refreshPlugin
            } else if let refreshPlugin = PluginManager.loadPlugin(RefreshPlugin.self) as? RefreshPlugin {
                return refreshPlugin
            }
            return RefreshPluginImpl.shared
        }
        set {
            fw_setProperty(newValue, forName: "fw_refreshPlugin")
        }
    }

    // MARK: - Refreshing

    /// 是否正在刷新中
    public var fw_isRefreshing: Bool {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.isRefreshing(_:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        return plugin.isRefreshing?(self) ?? false
    }

    /// 是否显示刷新组件
    public var fw_shouldRefreshing: Bool {
        get {
            var plugin: RefreshPlugin
            if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.shouldRefreshing(_:))) {
                plugin = refreshPlugin
            } else {
                plugin = RefreshPluginImpl.shared
            }
            return plugin.shouldRefreshing?(self) ?? false
        }
        set {
            var plugin: RefreshPlugin
            if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setShouldRefreshing(_:scrollView:))) {
                plugin = refreshPlugin
            } else {
                plugin = RefreshPluginImpl.shared
            }
            plugin.setShouldRefreshing?(newValue, scrollView: self)
        }
    }

    /// 配置下拉刷新句柄
    public func fw_setRefreshing(block: @escaping () -> Void) {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setRefreshingBlock(_:scrollView:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.setRefreshingBlock?(block, scrollView: self)
    }

    /// 配置下拉刷新事件
    public func fw_setRefreshing(target: Any, action: Selector) {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setRefreshingTarget(_:action:scrollView:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.setRefreshingTarget?(target, action: action, scrollView: self)
    }

    /// 开始下拉刷新
    public func fw_beginRefreshing() {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.beginRefreshing(_:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.beginRefreshing?(self)
    }

    /// 结束下拉刷新
    public func fw_endRefreshing() {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.endRefreshing(_:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.endRefreshing?(self)
    }

    // MARK: - Loading

    /// 是否正在追加中
    public var fw_isLoading: Bool {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.isLoading(_:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        return plugin.isLoading?(self) ?? false
    }

    /// 是否显示追加组件
    public var fw_shouldLoading: Bool {
        get {
            var plugin: RefreshPlugin
            if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.shouldLoading(_:))) {
                plugin = refreshPlugin
            } else {
                plugin = RefreshPluginImpl.shared
            }
            return plugin.shouldLoading?(self) ?? false
        }
        set {
            var plugin: RefreshPlugin
            if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setShouldLoading(_:scrollView:))) {
                plugin = refreshPlugin
            } else {
                plugin = RefreshPluginImpl.shared
            }
            plugin.setShouldLoading?(newValue, scrollView: self)
        }
    }
    
    /// 是否已加载完成，不能继续追加
    public var fw_loadingFinished: Bool {
        get {
            var plugin: RefreshPlugin
            if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.loadingFinished(_:))) {
                plugin = refreshPlugin
            } else {
                plugin = RefreshPluginImpl.shared
            }
            return plugin.loadingFinished?(self) ?? false
        }
        set {
            var plugin: RefreshPlugin
            if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setLoadingFinished(_:scrollView:))) {
                plugin = refreshPlugin
            } else {
                plugin = RefreshPluginImpl.shared
            }
            plugin.setLoadingFinished?(newValue, scrollView: self)
        }
    }

    /// 配置上拉追加句柄
    public func fw_setLoading(block: @escaping () -> Void) {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setLoading(_:scrollView:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.setLoading?(block, scrollView: self)
    }

    /// 配置上拉追加事件
    public func fw_setLoading(target: Any, action: Selector) {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.setLoadingTarget(_:action:scrollView:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.setLoadingTarget?(target, action: action, scrollView: self)
    }

    /// 开始上拉追加
    public func fw_beginLoading() {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.beginLoading(_:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.beginLoading?(self)
    }

    /// 结束上拉追加
    public func fw_endLoading() {
        var plugin: RefreshPlugin
        if let refreshPlugin = self.fw_refreshPlugin, refreshPlugin.responds(to: #selector(RefreshPlugin.endLoading(_:))) {
            plugin = refreshPlugin
        } else {
            plugin = RefreshPluginImpl.shared
        }
        plugin.endLoading?(self)
    }
    
}

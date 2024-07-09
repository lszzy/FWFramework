//
//  Configuration.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - Configuration
/// 配置基类，使用时继承即可
///
/// 默认自动查找模板类名格式优先级如下：
/// 1. 当前模块.[配置类]+Template
/// 2. 主项目.[配置类]+Template
/// 3. 当前模块.[配置类]+DefaultTemplate
@objc(ObjCConfiguration)
open class Configuration: NSObject {
    
    /// 单例模式对象，子类可直接调用
    public class var shared: Self {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if let instance = NSObject.fw.getAssociatedObject(self, key: #function) as? Self {
            return instance
        } else {
            let instance = self.init()
            NSObject.fw.setAssociatedObject(self, key: #function, value: instance)
            instance.initializeConfiguration()
            return instance
        }
    }
    
    /// 当前所使用配置模板
    open var configurationTemplate: ConfigurationTemplateProtocol? {
        didSet {
            configurationTemplate?.applyConfiguration()
        }
    }
    
    /// 初始化方法
    required public override init() {
        super.init()
    }
    
    /// 初始化配置，无需手工调用，子类可重写
    open func initializeConfiguration() {
        // 1. 当前模块.[配置类]+Template
        let className = NSStringFromClass(type(of: self))
        let classSuffix = className.components(separatedBy: ".").last ?? ""
        let applicationName = Bundle.main.object(forInfoDictionaryKey: kCFBundleExecutableKey as String) as? String ?? ""
        var templateClass: AnyClass? = NSClassFromString(className + "Template")
        // 2. 主项目.[配置类]+Template
        if templateClass == nil { templateClass = NSClassFromString("\(applicationName).\(classSuffix)Template") }
        // 3. 当前模块.[配置类]+DefaultTemplate
        if templateClass == nil { templateClass = NSClassFromString(className + "DefaultTemplate") }
        
        if let templateClass = templateClass as? ConfigurationTemplateProtocol.Type {
            self.configurationTemplate = templateClass.init()
        }
    }
    
}

// MARK: - ConfigurationTemplateProtocol
/// 配置模板协议，配置模板类需实现
public protocol ConfigurationTemplateProtocol {
    /// 初始化方法
    init()
    /// 应用配置方法
    func applyConfiguration()
}

// MARK: - ConfigurationTemplate
/// 配置模板基类，使用时继承即可
@objc(ObjCConfigurationTemplate)
open class ConfigurationTemplate: NSObject, ConfigurationTemplateProtocol {
    
    /// 初始化方法
    required public override init() {
        super.init()
    }
    
    /// 应用配置方法，子类重写
    open func applyConfiguration() {
        // 启用全局导航栏返回拦截
        // UINavigationController.fw.enablePopProxy()
        // 启用全局导航栏转场优化
        // UINavigationController.fw.enableBarTransition()
        
        // 设置默认导航栏样式
        // let defaultAppearance = NavigationBarAppearance()
        // defaultAppearance.foregroundColor = UIColor.black
        // 1. 指定导航栏背景色
        // defaultAppearance.backgroundColor = UIColor.white
        // 2. 设置导航栏样式全透明
        // defaultAppearance.backgroundTransparent = true
        // defaultAppearance.shadowColor = nil
        // NavigationBarAppearance.setAppearance(defaultAppearance, for: .default)
        
        // 配置通用样式和兼容性
        // UITableView.fw.resetTableStyle()
        // UITableView.fw.resetTableConfiguration = nil
        // UIButton.fw.highlightedAlpha = 0.5
        // UIButton.fw.disabledAlpha = 0.3
        
        // 配置弹窗插件及默认文案
        // PluginManager.registerPlugin(AlertPlugin.self, object: AlertControllerImpl.self)
        // AlertPluginImpl.shared.defaultCloseButton = nil
        // AlertPluginImpl.shared.defaultCancelButton = nil
        // AlertPluginImpl.shared.defaultConfirmButton = nil
        
        // 配置空界面插件默认文案
        // EmptyPluginImpl.shared.defaultText = nil
        // EmptyPluginImpl.shared.defaultDetail = nil
        // EmptyPluginImpl.shared.defaultImage = nil
        // EmptyPluginImpl.shared.defaultAction = nil
        
        // 配置图片选择、浏览和下拉刷新插件
        // PluginManager.registerPlugin(ImagePickerPlugin.self, object: ImagePickerControllerImpl.self)
        // PluginManager.registerPlugin(ImagePreviewPlugin.self, object: ImagePreviewPluginImpl.self)
        // PluginManager.registerPlugin(RefreshPlugin.self, object: RefreshPluginImpl.self)
        
        // 配置吐司插件
        // ToastPluginImpl.shared.delayHideTime = 2.0
        // ToastPluginImpl.shared.defaultLoadingText = nil
        // ToastPluginImpl.shared.defaultLoadingDetail = nil
        // ToastPluginImpl.shared.defaultProgressText = nil
        // ToastPluginImpl.shared.defaultProgressDetail = nil
        // ToastPluginImpl.shared.defaultMessageText = nil
        // ToastPluginImpl.shared.defaultMessageDetail = nil
        
        // 配置进度视图和指示器视图插件
        // ViewPluginImpl.shared.customIndicatorView = nil
        // ViewPluginImpl.shared.customProgressView = nil
    }
    
}

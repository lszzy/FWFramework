//
//  Language+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - WrapperGlobal+Language
extension WrapperGlobal {
    
    /// 读取本地化字符串
    ///
    /// - Parameters:
    ///   - key: 本地化键名
    ///   - table: 本地化表名，默认Localizable.strings
    /// - Returns: 本地化字符串
    public static func localized(_ key: String, _ table: String? = nil) -> String {
        return Bundle.fw_localizedString(key, table: table)
    }
    
}

// MARK: - String+Language
extension Wrapper where Base == String {
    /// 快速读取本地化语言
    public var localized: String {
        return Bundle.fw_localizedString(self.base)
    }
    
    /// 快速读取本地化语言，指定Bundle
    /// - Parameter bundle: 语言所在Bundle，默认主Bundle
    /// - Returns: 本地化字符串
    public func localized(_ bundle: Bundle?) -> String {
        return Bundle.fw_localizedString(self.base, bundle: bundle)
    }
    
    /// 快速读取本地化语言，指定表名和Bundle
    /// - Parameters:
    ///   - table: 本地化表名，默认Localizable.strings
    ///   - bundle: 语言所在Bundle，默认主Bundle
    /// - Returns: 本地化字符串
    public func localized(_ table: String?, _ bundle: Bundle? = nil) -> String {
        return Bundle.fw_localizedString(self.base, table: table, bundle: bundle)
    }
}

// MARK: - Bundle+Language
extension Wrapper where Base: Bundle {
    
    // MARK: - Bundle
    /// 根据本地化语言加载当前bundle内语言文件，支持动态切换
    public func localizedBundle() -> Bundle {
        return base.fw_localizedBundle()
    }

    /// 加载当前bundle内指定语言文件，加载失败返回nil
    public func localizedBundle(language: String?) -> Bundle? {
        return base.fw_localizedBundle(language: language)
    }
    
    // MARK: - Main
    /// 读取应用当前语言，如果localizedLanguage存在则返回，否则返回systemLanguage
    public static var currentLanguage: String? {
        return Base.fw_currentLanguage
    }

    /// 读取应用系统语言，返回preferredLocalizations(支持应用设置，不含区域)，示例：zh-Hans|en
    public static var systemLanguage: String? {
        return Base.fw_systemLanguage
    }

    /// 读取或设置自定义本地化语言，未自定义时为空。(语言值对应本地化文件存在才会立即生效，如zh-Hans|en)，为空时清空自定义，会触发通知。默认只处理mainBundle语言，如果需要处理三方SDK和系统组件语言，详见Bundle分类
    public static var localizedLanguage: String? {
        get { return Base.fw_localizedLanguage }
        set { Base.fw_localizedLanguage = newValue }
    }

    /// 读取本地化字符串，可指定table，strings文件需位于mainBundle，支持动态切换
    public static func localizedString(_ key: String, table: String? = nil) -> String {
        return Base.fw_localizedString(key, table: table)
    }
    
    // MARK: - Bundle
    /// 加载指定名称bundle对象，bundle文件需位于mainBundle
    public static func bundle(name: String) -> Bundle? {
        return Base.fw_bundle(name: name)
    }

    /// 加载指定类所在bundle对象，可指定子目录名称，一般用于Framework内bundle文件
    public static func bundle(with clazz: AnyClass, name: String?) -> Bundle? {
        return Base.fw_bundle(with: clazz, name: name)
    }

    /// 读取指定bundle内strings文件本地化字符串，支持动态切换
    public static func localizedString(_ key: String, bundle: Bundle?) -> String {
        return Base.fw_localizedString(key, bundle: bundle)
    }

    /// 读取指定bundle内strings文件本地化字符串，指定table，支持动态切换
    public static func localizedString(_ key: String, table: String?, bundle: Bundle?) -> String {
        return Base.fw_localizedString(key, table: table, bundle: bundle)
    }
    
    /// 读取当前bundle的可执行程序名称，一般和模块名称相同
    public var executableName: String {
        return base.fw_executableName
    }
    
}

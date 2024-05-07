//
//  Language.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - WrapperGlobal
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

// MARK: - Wrapper+String
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

// MARK: - Wrapper+Bundle
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
    /// 读取应用可用语言列表
    public static var availableLanguages: [String] {
        return Base.fw_availableLanguages
    }
    
    /// 读取指定语言显示名称，可指定本地化标识(默认当前语言)
    public static func languageName(for language: String, localeIdentifier: String? = nil) -> String {
        return Base.fw_languageName(for: language, localeIdentifier: localeIdentifier)
    }
    
    /// 读取应用当前语言，如果localizedLanguage存在则返回，否则返回systemLanguage
    public static var currentLanguage: String? {
        return Base.fw_currentLanguage
    }

    /// 读取当前系统语言，不满足需求时可自定义，兼容应用设置且不含区域，示例：zh-Hans
    public static var systemLanguage: String? {
        get { return Base.fw_systemLanguage }
        set { Base.fw_systemLanguage = newValue }
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

// MARK: - Notification+Language
extension Notification.Name {
    
    /// 本地化语言改变通知，object为本地化语言名称
    public static let LanguageChanged = Notification.Name("FWLanguageChangedNotification")
    
}

// MARK: - String+Language
@_spi(FW) extension String {
    
    /// 快速读取本地化语言
    public var fw_localized: String {
        return Bundle.fw_localizedString(self)
    }
    
    /// 快速读取本地化语言，指定Bundle
    /// - Parameter bundle: 语言所在Bundle，默认主Bundle
    /// - Returns: 本地化字符串
    public func fw_localized(_ bundle: Bundle?) -> String {
        return Bundle.fw_localizedString(self, bundle: bundle)
    }
    
    /// 快速读取本地化语言，指定表名和Bundle
    /// - Parameters:
    ///   - table: 本地化表名，默认Localizable.strings
    ///   - bundle: 语言所在Bundle，默认主Bundle
    /// - Returns: 本地化字符串
    public func fw_localized(_ table: String?, _ bundle: Bundle? = nil) -> String {
        return Bundle.fw_localizedString(self, table: table, bundle: bundle)
    }
    
}

// MARK: - Bundle+Language
@_spi(FW) extension Bundle {
    
    private class TargetBundle: Bundle {
        
        override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
            if let bundle = fw_property(forName: "fw_localizedBundle") as? Bundle {
                return bundle.localizedString(forKey: key, value: value, table: tableName)
            } else {
                return super.localizedString(forKey: key, value: value, table: tableName)
            }
        }
        
    }
    
    // MARK: - Bundle
    /// 根据本地化语言加载当前bundle内语言文件，支持动态切换
    public func fw_localizedBundle() -> Bundle {
        if self.isKind(of: TargetBundle.self) { return self }
        fw_synchronized {
            if !self.isKind(of: TargetBundle.self) {
                object_setClass(self, TargetBundle.self)
                
                if let language = Bundle.fw_localizedLanguage {
                    self.fw_languageChanged(Notification(name: .LanguageChanged, object: language))
                }
                
                NotificationCenter.default.addObserver(self, selector: #selector(Bundle.fw_languageChanged(_:)), name: .LanguageChanged, object: nil)
            }
        }
        return self
    }

    /// 加载当前bundle内指定语言文件，加载失败返回nil
    public func fw_localizedBundle(language: String?) -> Bundle? {
        guard let language = language,
              let path = path(forResource: language, ofType: "lproj") else { return nil }
        return Bundle(path: path)
    }
    
    @objc private func fw_languageChanged(_ notification: Notification) {
        let language = notification.object as? String
        let bundle = fw_localizedBundle(language: language)
        fw_setProperty(bundle, forName: "fw_localizedBundle")
    }
    
    // MARK: - Main
    /// 读取应用可用语言列表
    public static var fw_availableLanguages: [String] {
        var languages = Bundle.main.localizations
        if let baseIndex = languages.firstIndex(of: "Base") {
            languages.remove(at: baseIndex)
        }
        return languages
    }
    
    /// 读取指定语言显示名称，可指定本地化标识(默认当前语言)
    public static func fw_languageName(for language: String, localeIdentifier: String? = nil) -> String {
        guard let localeIdentifier = localeIdentifier ?? fw_currentLanguage else { return "" }
        let locale: NSLocale = NSLocale(localeIdentifier: localeIdentifier)
        return locale.displayName(forKey: NSLocale.Key.identifier, value: language) ?? ""
    }
    
    /// 读取应用当前语言，如果localizedLanguage存在则返回，否则返回systemLanguage
    public static var fw_currentLanguage: String? {
        return fw_localizedLanguage ?? fw_systemLanguage
    }

    /// 读取当前系统语言，不满足需求时可自定义，兼容应用设置且不含区域，示例：zh-Hans
    ///
    /// 备注：
    /// 1. Bundle.main.preferredLocalizations只包含语言信息，只返回App支持的语言，示例：zh-Hans；注意localizedLanguage重置为nil后需下次启动才能获取到当前系统语言
    /// 2. Locale.preferredLanguages包含语言和区域信息，可能返回App不支持的语言，示例：zh-Hans-CN；注意localizedLanguage重置为nil后无需下次启动即可获取到当前系统语言
    public static var fw_systemLanguage: String? {
        get {
            if let language = _fw_systemLanguage {
                return language
            }
            return Bundle.main.preferredLocalizations.first
        }
        set {
            _fw_systemLanguage = newValue
        }
    }
    private static var _fw_systemLanguage: String?

    /// 读取或设置自定义本地化语言，未自定义时为空。(语言值对应本地化文件存在才会立即生效，如zh-Hans|en)，为空时清空自定义，会触发通知。默认只处理mainBundle语言，如果需要处理三方SDK和系统组件语言，详见Bundle分类
    public static var fw_localizedLanguage: String? {
        get {
            return UserDefaults.standard.string(forKey: "FWLocalizedLanguage")
        }
        set {
            if let language = newValue {
                UserDefaults.standard.set(language, forKey: "FWLocalizedLanguage")
                UserDefaults.standard.set([language], forKey: "AppleLanguages")
                UserDefaults.standard.synchronize()
            } else {
                UserDefaults.standard.removeObject(forKey: "FWLocalizedLanguage")
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                UserDefaults.standard.synchronize()
            }
            fw_localizedChanged(newValue)
            
            NotificationCenter.default.post(name: .LanguageChanged, object: newValue)
        }
    }

    /// 读取本地化字符串，可指定table，strings文件需位于mainBundle，支持动态切换
    public static func fw_localizedString(_ key: String, table: String? = nil) -> String {
        return Bundle.main.localizedString(forKey: key, value: nil, table: table)
    }
    
    fileprivate static func fw_localizedChanged(_ language: String?) {
        fw_synchronized {
            if object_getClass(Bundle.main) != TargetBundle.self {
                object_setClass(Bundle.main, TargetBundle.self)
            }
        }
        
        var bundle: Bundle?
        if let language = language,
           let path = Bundle.main.path(forResource: language, ofType: "lproj") {
            bundle = Bundle(path: path)
        }
        Bundle.main.fw_setProperty(bundle, forName: "fw_localizedBundle")
    }
    
    // MARK: - Bundle
    /// 加载指定名称bundle对象，bundle文件需位于mainBundle
    public static func fw_bundle(name: String) -> Bundle? {
        guard let path = Bundle.main.path(forResource: name, ofType: name.hasSuffix(".bundle") ? nil : "bundle") else { return nil }
        return Bundle(path: path)
    }

    /// 加载指定类所在bundle对象，可指定子目录名称，一般用于Framework内bundle文件
    public static func fw_bundle(with clazz: AnyClass, name: String?) -> Bundle? {
        let bundle = Bundle(for: clazz)
        guard let name = name, !name.isEmpty else { return bundle }
        guard let path = bundle.path(forResource: name, ofType: name.hasSuffix(".bundle") ? nil : "bundle") else { return nil }
        return Bundle(path: path)
    }

    /// 读取指定bundle内strings文件本地化字符串，支持动态切换
    public static func fw_localizedString(_ key: String, bundle: Bundle?) -> String {
        return fw_localizedString(key, table: nil, bundle: bundle)
    }

    /// 读取指定bundle内strings文件本地化字符串，指定table，支持动态切换
    public static func fw_localizedString(_ key: String, table: String?, bundle: Bundle?) -> String {
        if let bundle = bundle {
            return bundle.fw_localizedBundle().localizedString(forKey: key, value: nil, table: table)
        } else {
            return Bundle.main.localizedString(forKey: key, value: nil, table: table)
        }
    }
    
    /// 读取当前bundle的可执行程序名称，一般和模块名称相同
    public var fw_executableName: String {
        return executableURL?.lastPathComponent ?? ""
    }
    
}

// MARK: - FrameworkAutoloader+Language
extension FrameworkAutoloader {
    
    @objc static func loadToolkit_Language() {
        if let language = Bundle.fw_localizedLanguage {
            Bundle.fw_localizedChanged(language)
        }
    }
    
}

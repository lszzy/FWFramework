//
//  Theme.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/13.
//

import UIKit

extension Wrapper where Base: UIColor {
    
    /// 动态创建主题色，分别指定浅色和深色
    public static func themeLight(_ light: UIColor, dark: UIColor) -> UIColor {
        return UIColor.__fw.themeLight(light, dark: dark)
    }

    /// 动态创建主题色，指定提供句柄
    public static func themeColor(_ provider: @escaping (ThemeStyle) -> UIColor) -> UIColor {
        return UIColor.__fw.themeColor(provider)
    }

    /// 动态创建主题色，指定名称，兼容iOS11+系统方式(仅iOS13+支持动态颜色)和手工指定。失败时返回clear防止崩溃
    public static func themeNamed(_ name: String) -> UIColor {
        return UIColor.__fw.themeNamed(name)
    }

    /// 动态创建主题色，指定名称和bundle，兼容iOS11+系统方式(仅iOS13+支持动态颜色)和手工指定。失败时返回clear防止崩溃
    public static func themeNamed(_ name: String, bundle: Bundle?) -> UIColor {
        return UIColor.__fw.themeNamed(name, bundle: bundle)
    }

    /// 手工单个注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
    public static func setThemeColor(_ color: UIColor?, forName: String) {
        UIColor.__fw.setThemeColor(color, forName: forName)
    }

    /// 手工批量注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
    public static func setThemeColors(_ nameColors: [String: UIColor]) {
        UIColor.__fw.setThemeColors(nameColors)
    }
    
}

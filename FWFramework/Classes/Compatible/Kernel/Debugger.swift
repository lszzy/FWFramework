//
//  Debugger.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/13.
//

import UIKit
#if FWMacroSPM
import FWFramework
#endif

extension Wrapper where Base: NSObject {
    /// 获取当前对象的所有 @property、方法，父类的方法也会分别列出
    public var methodList: String {
        return base.__fw_methodList
    }
    
    /// 获取当前对象的所有 @property、方法，不包含父类的
    public var shortMethodList: String {
        return base.__fw_shortMethodList
    }
    
    /// 当前对象的所有 Ivar 变量
    public var ivarList: String {
        return base.__fw_ivarList
    }
}

extension Wrapper where Base: UIView {
    /// 获取当前 UIView 层级树信息
    public var viewInfo: String {
        return base.__fw_viewInfo
    }

    /// 是否需要添加debug背景色，默认NO
    public var showDebugColor: Bool {
        get { return base.__fw_showDebugColor }
        set { base.__fw_showDebugColor = newValue }
    }

    /// 是否每个view的背景色随机，如果不随机则统一使用半透明红色，默认NO
    public var randomDebugColor: Bool {
        get { return base.__fw_randomDebugColor }
        set { base.__fw_randomDebugColor = newValue }
    }

    /// 是否需要添加debug边框，默认NO
    public var showDebugBorder: Bool {
        get { return base.__fw_showDebugBorder }
        set { base.__fw_showDebugBorder = newValue }
    }

    /// 指定debug边框的颜色，默认半透明红色
    public var debugBorderColor: UIColor {
        get { return base.__fw_debugBorderColor }
        set { base.__fw_debugBorderColor = newValue }
    }
}

extension Wrapper where Base: UILabel {
    /**
     调试功能，打开后会在 label 第一行文字里把 descender、xHeight、capHeight、lineHeight 所在的位置以线条的形式标记出来。
     对这些属性的解释可以看这篇文章 https://www.rightpoint.com/rplabs/ios-tracking-typography
     */
    public var showPrincipalLines: Bool {
        get { return base.__fw_showPrincipalLines }
        set { base.__fw_showPrincipalLines = newValue }
    }

    /**
     当打开 showPrincipalLines 时，通过这个属性控制线条的颜色，默认为 半透明红色
     */
    public var principalLineColor: UIColor {
        get { return base.__fw_principalLineColor }
        set { base.__fw_principalLineColor = newValue }
    }
}

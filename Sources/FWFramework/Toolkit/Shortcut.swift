//
//  Shortcut.swift
//  FWFramework
//
//  Created by wuyong on 2023/7/14.
//

import UIKit

// MARK: - Adaptive+Shortcut
extension CGFloat {
    
    /// 获取相对设计图宽度等比例缩放值
    public var relativeValue: CGFloat { UIScreen.fw.relativeValue(self) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public var fixedValue: CGFloat { UIScreen.fw.fixedValue(self) }
    /// 获取基于当前设备的倍数像素取整值
    public var flatValue: CGFloat { UIScreen.fw.flatValue(self) }
    /// 获取向上取整值
    public var ceilValue: CGFloat { Darwin.ceil(self) }
    
    /// 获取相对设计图宽度等比例缩放值
    @available(*, deprecated, renamed: "relativeValue", message: "Use relativeValue instead")
    public var relative: CGFloat { relativeValue }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    @available(*, deprecated, renamed: "fixedValue", message: "Use fixedValue instead")
    public var fixed: CGFloat { fixedValue }
    /// 获取基于当前设备的倍数像素取整值
    @available(*, deprecated, renamed: "flatValue", message: "Use flatValue instead")
    public var flat: CGFloat { flatValue }
    /// 获取向上取整值
    @available(*, deprecated, renamed: "ceilValue", message: "Use ceilValue instead")
    public var ceil: CGFloat { ceilValue }
    
}

extension CGSize {
    
    /// 获取相对设计图宽度等比例缩放size
    public var relativeValue: CGSize { CGSize(width: width.relativeValue, height: height.relativeValue) }
    /// 获取相对设计图宽度等比例缩放时的固定size
    public var fixedValue: CGSize { CGSize(width: width.fixedValue, height: height.fixedValue) }
    /// 获取基于当前设备的倍数像素取整size
    public var flatValue: CGSize { CGSize(width: width.flatValue, height: height.flatValue) }
    /// 获取向上取整size
    public var ceilValue: CGSize { CGSize(width: width.ceilValue, height: height.ceilValue) }
    
    /// 获取相对设计图宽度等比例缩放size
    @available(*, deprecated, renamed: "relativeValue", message: "Use relativeValue instead")
    public var relative: CGSize { relativeValue }
    /// 获取相对设计图宽度等比例缩放时的固定size
    @available(*, deprecated, renamed: "fixedValue", message: "Use fixedValue instead")
    public var fixed: CGSize { fixedValue }
    /// 获取基于当前设备的倍数像素取整size
    @available(*, deprecated, renamed: "flatValue", message: "Use flatValue instead")
    public var flat: CGSize { flatValue }
    /// 获取向上取整size
    @available(*, deprecated, renamed: "ceilValue", message: "Use ceilValue instead")
    public var ceil: CGSize { ceilValue }
    
}

extension CGPoint {
    
    /// 获取相对设计图宽度等比例缩放point
    public var relativeValue: CGPoint { CGPoint(x: x.relativeValue, y: y.relativeValue) }
    /// 获取相对设计图宽度等比例缩放时的固定point
    public var fixedValue: CGPoint { CGPoint(x: x.fixedValue, y: y.fixedValue) }
    /// 获取基于当前设备的倍数像素取整point
    public var flatValue: CGPoint { CGPoint(x: x.flatValue, y: y.flatValue) }
    /// 获取向上取整point
    public var ceilValue: CGPoint { CGPoint(x: x.ceilValue, y: y.ceilValue) }
    
    /// 获取相对设计图宽度等比例缩放point
    @available(*, deprecated, renamed: "relativeValue", message: "Use relativeValue instead")
    public var relative: CGPoint { relativeValue }
    /// 获取相对设计图宽度等比例缩放时的固定point
    @available(*, deprecated, renamed: "fixedValue", message: "Use fixedValue instead")
    public var fixed: CGPoint { fixedValue }
    /// 获取基于当前设备的倍数像素取整point
    @available(*, deprecated, renamed: "flatValue", message: "Use flatValue instead")
    public var flat: CGPoint { flatValue }
    /// 获取向上取整point
    @available(*, deprecated, renamed: "ceilValue", message: "Use ceilValue instead")
    public var ceil: CGPoint { ceilValue }
    
}

extension CGRect {
    
    /// 获取相对设计图宽度等比例缩放rect
    public var relativeValue: CGRect { CGRect(origin: origin.relativeValue, size: size.relativeValue) }
    /// 获取相对设计图宽度等比例缩放时的固定rect
    public var fixedValue: CGRect { CGRect(origin: origin.fixedValue, size: size.fixedValue) }
    /// 获取基于当前设备的倍数像素取整rect
    public var flatValue: CGRect { CGRect(origin: origin.flatValue, size: size.flatValue) }
    /// 获取向上取整rect
    public var ceilValue: CGRect { CGRect(origin: origin.ceilValue, size: size.ceilValue) }
    
    /// 获取相对设计图宽度等比例缩放rect
    @available(*, deprecated, renamed: "relativeValue", message: "Use relativeValue instead")
    public var relative: CGRect { relativeValue }
    /// 获取相对设计图宽度等比例缩放时的固定rect
    @available(*, deprecated, renamed: "fixedValue", message: "Use fixedValue instead")
    public var fixed: CGRect { fixedValue }
    /// 获取基于当前设备的倍数像素取整rect
    @available(*, deprecated, renamed: "flatValue", message: "Use flatValue instead")
    public var flat: CGRect { flatValue }
    /// 获取向上取整rect
    @available(*, deprecated, renamed: "ceilValue", message: "Use ceilValue instead")
    public var ceil: CGRect { ceilValue }
    
}

extension UIEdgeInsets {
    
    /// 获取相对设计图宽度等比例缩放insets
    public var relativeValue: UIEdgeInsets { UIEdgeInsets(top: top.relativeValue, left: left.relativeValue, bottom: bottom.relativeValue, right: right.relativeValue) }
    /// 获取相对设计图宽度等比例缩放时的固定insets
    public var fixedValue: UIEdgeInsets { UIEdgeInsets(top: top.fixedValue, left: left.fixedValue, bottom: bottom.fixedValue, right: right.fixedValue) }
    /// 获取基于当前设备的倍数像素取整insets
    public var flatValue: UIEdgeInsets { UIEdgeInsets(top: top.flatValue, left: left.flatValue, bottom: bottom.flatValue, right: right.flatValue) }
    /// 获取向上取整insets
    public var ceilValue: UIEdgeInsets { UIEdgeInsets(top: top.ceilValue, left: left.ceilValue, bottom: bottom.ceilValue, right: right.ceilValue) }
    
    /// 获取相对设计图宽度等比例缩放insets
    @available(*, deprecated, renamed: "relativeValue", message: "Use relativeValue instead")
    public var relative: UIEdgeInsets { relativeValue }
    /// 获取相对设计图宽度等比例缩放时的固定insets
    @available(*, deprecated, renamed: "fixedValue", message: "Use fixedValue instead")
    public var fixed: UIEdgeInsets { fixedValue }
    /// 获取基于当前设备的倍数像素取整insets
    @available(*, deprecated, renamed: "flatValue", message: "Use flatValue instead")
    public var flat: UIEdgeInsets { flatValue }
    /// 获取向上取整insets
    @available(*, deprecated, renamed: "ceilValue", message: "Use ceilValue instead")
    public var ceil: UIEdgeInsets { ceilValue }
    
}

extension Int {
    
    /// 获取相对设计图宽度等比例缩放值
    public var relativeValue: CGFloat { UIScreen.fw.relativeValue(CGFloat(self)) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public var fixedValue: CGFloat { UIScreen.fw.fixedValue(CGFloat(self)) }
    /// 获取基于当前设备的倍数像素取整值
    public var flatValue: CGFloat { UIScreen.fw.flatValue(CGFloat(self)) }
    /// 获取向上取整值
    public var ceilValue: CGFloat { Darwin.ceil(CGFloat(self)) }
    
    /// 获取相对设计图宽度等比例缩放值
    @available(*, deprecated, renamed: "relativeValue", message: "Use relativeValue instead")
    public var relative: CGFloat { relativeValue }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    @available(*, deprecated, renamed: "fixedValue", message: "Use fixedValue instead")
    public var fixed: CGFloat { fixedValue }
    /// 获取基于当前设备的倍数像素取整值
    @available(*, deprecated, renamed: "flatValue", message: "Use flatValue instead")
    public var flat: CGFloat { flatValue }
    /// 获取向上取整值
    @available(*, deprecated, renamed: "ceilValue", message: "Use ceilValue instead")
    public var ceil: CGFloat { ceilValue }
    
}

extension Float {
    
    /// 获取相对设计图宽度等比例缩放值
    public var relativeValue: CGFloat { UIScreen.fw.relativeValue(CGFloat(self)) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public var fixedValue: CGFloat { UIScreen.fw.fixedValue(CGFloat(self)) }
    /// 获取基于当前设备的倍数像素取整值
    public var flatValue: CGFloat { UIScreen.fw.flatValue(CGFloat(self)) }
    /// 获取向上取整值
    public var ceilValue: CGFloat { Darwin.ceil(CGFloat(self)) }
    
    /// 获取相对设计图宽度等比例缩放值
    @available(*, deprecated, renamed: "relativeValue", message: "Use relativeValue instead")
    public var relative: CGFloat { relativeValue }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    @available(*, deprecated, renamed: "fixedValue", message: "Use fixedValue instead")
    public var fixed: CGFloat { fixedValue }
    /// 获取基于当前设备的倍数像素取整值
    @available(*, deprecated, renamed: "flatValue", message: "Use flatValue instead")
    public var flat: CGFloat { flatValue }
    /// 获取向上取整值
    @available(*, deprecated, renamed: "ceilValue", message: "Use ceilValue instead")
    public var ceil: CGFloat { ceilValue }
    
}

extension Double {
    
    /// 获取相对设计图宽度等比例缩放值
    public var relativeValue: CGFloat { UIScreen.fw.relativeValue(CGFloat(self)) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public var fixedValue: CGFloat { UIScreen.fw.fixedValue(CGFloat(self)) }
    /// 获取基于当前设备的倍数像素取整值
    public var flatValue: CGFloat { UIScreen.fw.flatValue(CGFloat(self)) }
    /// 获取向上取整值
    public var ceilValue: CGFloat { Darwin.ceil(CGFloat(self)) }
    
    /// 获取相对设计图宽度等比例缩放值
    @available(*, deprecated, renamed: "relativeValue", message: "Use relativeValue instead")
    public var relative: CGFloat { relativeValue }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    @available(*, deprecated, renamed: "fixedValue", message: "Use fixedValue instead")
    public var fixed: CGFloat { fixedValue }
    /// 获取基于当前设备的倍数像素取整值
    @available(*, deprecated, renamed: "flatValue", message: "Use flatValue instead")
    public var flat: CGFloat { flatValue }
    /// 获取向上取整值
    @available(*, deprecated, renamed: "ceilValue", message: "Use ceilValue instead")
    public var ceil: CGFloat { ceilValue }
    
}

// MARK: - AutoLayout+Shortcut
extension UIView {
    
    /// 链式布局对象
    public var layoutChain: LayoutChain { fw.layoutChain }
    
    /// 链式布局对象
    @available(*, deprecated, renamed: "layoutChain", message: "Use layoutChain instead")
    public var chain: LayoutChain { layoutChain }
    
    /// 链式布局闭包
    @discardableResult
    public func layoutMaker(_ closure: (_ make: LayoutChain) -> Void) -> Self {
        fw.layoutMaker(closure)
        return self
    }
    
}

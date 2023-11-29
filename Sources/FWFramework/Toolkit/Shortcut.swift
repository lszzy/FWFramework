//
//  Shortcut.swift
//  FWFramework
//
//  Created by wuyong on 2023/7/14.
//

// MARK: - Adaptive+Shortcut
extension CGFloat {
    
    /// 获取相对设计图宽度等比例缩放值
    public var relative: CGFloat { UIScreen.fw_relativeValue(self) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public var fixed: CGFloat { UIScreen.fw_fixedValue(self) }
    /// 获取基于当前设备的倍数像素取整值
    public var flat: CGFloat { UIScreen.fw_flatValue(self) }
    
}

extension CGSize {
    
    /// 获取相对设计图宽度等比例缩放size
    public var relative: CGSize { CGSize(width: width.relative, height: height.relative) }
    /// 获取相对设计图宽度等比例缩放时的固定size
    public var fixed: CGSize { CGSize(width: width.fixed, height: height.fixed) }
    /// 获取基于当前设备的倍数像素取整size
    public var flat: CGSize { CGSize(width: width.flat, height: height.flat) }
    
}

extension CGPoint {
    
    /// 获取相对设计图宽度等比例缩放point
    public var relative: CGPoint { CGPoint(x: x.relative, y: y.relative) }
    /// 获取相对设计图宽度等比例缩放时的固定point
    public var fixed: CGPoint { CGPoint(x: x.fixed, y: y.fixed) }
    /// 获取基于当前设备的倍数像素取整point
    public var flat: CGPoint { CGPoint(x: x.flat, y: y.flat) }
    
}

extension CGRect {
    
    /// 获取相对设计图宽度等比例缩放rect
    public var relative: CGRect { CGRect(origin: origin.relative, size: size.relative) }
    /// 获取相对设计图宽度等比例缩放时的固定rect
    public var fixed: CGRect { CGRect(origin: origin.fixed, size: size.fixed) }
    /// 获取基于当前设备的倍数像素取整rect
    public var flat: CGRect { CGRect(origin: origin.flat, size: size.flat) }
    
}

extension UIEdgeInsets {
    
    /// 获取相对设计图宽度等比例缩放insets
    public var relative: UIEdgeInsets { UIEdgeInsets(top: top.relative, left: left.relative, bottom: bottom.relative, right: right.relative) }
    /// 获取相对设计图宽度等比例缩放时的固定insets
    public var fixed: UIEdgeInsets { UIEdgeInsets(top: top.fixed, left: left.fixed, bottom: bottom.fixed, right: right.fixed) }
    /// 获取基于当前设备的倍数像素取整insets
    public var flat: UIEdgeInsets { UIEdgeInsets(top: top.flat, left: left.flat, bottom: bottom.flat, right: right.flat) }
    
}

extension Int {
    
    /// 获取相对设计图宽度等比例缩放值
    public var relative: CGFloat { UIScreen.fw_relativeValue(CGFloat(self)) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public var fixed: CGFloat { UIScreen.fw_fixedValue(CGFloat(self)) }
    /// 获取基于当前设备的倍数像素取整值
    public var flat: CGFloat { UIScreen.fw_flatValue(CGFloat(self)) }
    
}

extension Float {
    
    /// 获取相对设计图宽度等比例缩放值
    public var relative: CGFloat { UIScreen.fw_relativeValue(CGFloat(self)) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public var fixed: CGFloat { UIScreen.fw_fixedValue(CGFloat(self)) }
    /// 获取基于当前设备的倍数像素取整值
    public var flat: CGFloat { UIScreen.fw_flatValue(CGFloat(self)) }
    
}

extension Double {
    
    /// 获取相对设计图宽度等比例缩放值
    public var relative: CGFloat { UIScreen.fw_relativeValue(CGFloat(self)) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public var fixed: CGFloat { UIScreen.fw_fixedValue(CGFloat(self)) }
    /// 获取基于当前设备的倍数像素取整值
    public var flat: CGFloat { UIScreen.fw_flatValue(CGFloat(self)) }
    
}

// MARK: - AutoLayout+Shortcut
extension UIView {
    
    /// 链式布局对象
    public var chain: LayoutChain { fw_layoutChain }
    
}

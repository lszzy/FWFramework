//
//  UIKit.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/13.
//

import UIKit

extension Wrapper where Base: UIView {
    
    /// 绘制单边或多边边框视图。使用AutoLayout
    public func setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat) {
        base.__fw.setBorderView(edge, color: color, width: width)
    }

    /// 绘制单边或多边边框。使用AutoLayout
    public func setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat, leftInset: CGFloat, rightInset: CGFloat) {
        base.__fw.setBorderView(edge, color: color, width: width, leftInset: leftInset, rightInset: rightInset)
    }
    
}

extension Wrapper where Base: UILabel {
    
    /// 添加点击手势并自动识别NSLinkAttributeName属性点击时触发回调block
    public func addLinkGesture(_ block: @escaping (Any) -> Void) {
        base.__fw.addLinkGesture(block)
    }
    
}

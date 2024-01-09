//
//  DrawerView+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

extension Wrapper where Base: UIView {
    
    /// 抽屉拖拽视图，绑定抽屉拖拽效果后才存在
    public var drawerView: DrawerView? {
        get { return base.fw_drawerView }
        set { base.fw_drawerView = newValue }
    }
    
    /**
     设置抽屉拖拽效果。如果view为滚动视图，自动处理与滚动视图pan手势冲突的问题
     
     @param direction 拖拽方向，如向上拖动视图时为Up，默认向上
     @param positions 抽屉位置，至少两级，相对于view父视图的originY位置
     @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
     @param positionChanged 抽屉视图位移回调，参数为相对父视图的origin位置和是否拖拽完成的标记
     @return 抽屉拖拽视图
     */
    @discardableResult
    public func drawerView(_ direction: UISwipeGestureRecognizer.Direction, positions: [CGFloat], kickbackHeight: CGFloat, positionChanged: ((CGFloat, Bool) -> Void)? = nil) -> DrawerView {
        return base.fw_drawerView(direction, positions: positions, kickbackHeight: kickbackHeight, positionChanged: positionChanged)
    }
    
}

extension Wrapper where Base: UIScrollView {
    
    /// 外部滚动视图是否位于顶部固定位置，在顶部时不能滚动
    public var drawerSuperviewFixed: Bool {
        get { return base.fw_drawerSuperviewFixed }
        set { base.fw_drawerSuperviewFixed = newValue }
    }

    /// 外部滚动视图scrollViewDidScroll调用，参数为固定的位置
    public func drawerSuperviewDidScroll(_ position: CGFloat) {
        base.fw_drawerSuperviewDidScroll(position)
    }

    /// 内嵌滚动视图scrollViewDidScroll调用，参数为外部滚动视图
    public func drawerSubviewDidScroll(_ superview: UIScrollView) {
        base.fw_drawerSubviewDidScroll(superview)
    }
    
}

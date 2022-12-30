//
//  DrawerView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

/// 视图抽屉拖拽效果分类
@_spi(FW) @objc extension UIView {
    
    /// 抽屉拖拽视图，绑定抽屉拖拽效果后才存在
    public var fw_drawerView: DrawerView? {
        get {
            return fw_property(forName: "fw_drawerView") as? DrawerView
        }
        set {
            fw_setProperty(newValue, forName: "fw_drawerView")
        }
    }
    
    /**
     设置抽屉拖拽效果。如果view为滚动视图，自动处理与滚动视图pan手势冲突的问题
     
     @param direction 拖拽方向，如向上拖动视图时为Up，默认向上
     @param positions 抽屉位置，至少两级，相对于view父视图的originY位置
     @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
     @param callback 抽屉视图位移回调，参数为相对父视图的origin位置和是否拖拽完成的标记
     @return 抽屉拖拽视图
     */
    @discardableResult
    public func fw_drawerView(_ direction: UISwipeGestureRecognizer.Direction, positions: [NSNumber], kickbackHeight: CGFloat, callback: ((CGFloat, Bool) -> Void)? = nil) -> DrawerView {
        let drawerView = DrawerView(view: self)
        if direction.rawValue > 0 {
            drawerView.direction = direction
        }
        drawerView.positions = positions
        drawerView.kickbackHeight = kickbackHeight
        drawerView.callback = callback
        return drawerView
    }
    
}

/// 滚动视图纵向手势冲突无缝滑动分类，需允许同时识别多个手势
@_spi(FW) @objc extension UIScrollView {
    
    /// 外部滚动视图是否位于顶部固定位置，在顶部时不能滚动
    public var fw_drawerSuperviewFixed: Bool {
        get { return fw_propertyBool(forName: "fw_drawerSuperviewFixed") }
        set { fw_setPropertyBool(newValue, forName: "fw_drawerSuperviewFixed") }
    }

    /// 外部滚动视图scrollViewDidScroll调用，参数为固定的位置
    public func fw_drawerSuperviewDidScroll(_ position: CGFloat) {
        if self.contentOffset.y >= position {
            self.fw_drawerSuperviewFixed = true
        }
        if self.fw_drawerSuperviewFixed {
            self.contentOffset = CGPoint(x: self.contentOffset.x, y: position)
        }
    }

    /// 内嵌滚动视图scrollViewDidScroll调用，参数为外部滚动视图
    public func fw_drawerSubviewDidScroll(_ superview: UIScrollView) {
        if self.contentOffset.y <= 0 {
            superview.fw_drawerSuperviewFixed = false
        }
        if !superview.fw_drawerSuperviewFixed {
            self.contentOffset = CGPoint(x: self.contentOffset.x, y: 0)
        }
    }
    
}

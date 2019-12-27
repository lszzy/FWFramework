//
//  FWTabAnimated.swift
//  FWFramework
//
//  Created by wuyong on 2019/12/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

// MARK: - FWTabComponentManager

extension FWTabComponentManager {
    @discardableResult
    public func animation(_ index: Int) -> FWTabBaseComponent? {
        return self._oc_animation()?(index)
    }
    
    @discardableResult
    public func animations(_ location: Int, _ length: Int) -> [FWTabBaseComponent]? {
        return self._oc_animations()?(location, length)
    }
    
    @discardableResult
    public func animations(indexs: Int ...) -> [FWTabBaseComponent]? {
        return self._oc_animationsWithIndexs()(indexs)
    }
}

// MARK: - Array

extension Array where Element: FWTabBaseComponent {
    @discardableResult
    public func left(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_left()(value)!
    }
    
    @discardableResult
    public func right(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_right()(value)!
    }
    
    @discardableResult
    public func up(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_up()(value)!
    }
    
    @discardableResult
    public func down(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_down()(value)!
    }
    
    @discardableResult
    public func width(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_width()(value)!
    }
    
    @discardableResult
    public func height(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_height()(value)!
    }
    
    @discardableResult
    public func radius(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_radius()(value)!
    }
    
    @discardableResult
    public func reducedWidth(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_reducedWidth()(value)!
    }
    
    @discardableResult
    public func reducedHeight(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_reducedHeight()(value)!
    }
    
    @discardableResult
    public func reducedRadius(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_reducedRadius()(value)!
    }
    
    @discardableResult
    public func line(_ value: Int) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_line()(value)!
    }
    
    @discardableResult
    public func space(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_space()(value)!
    }
    
    @discardableResult
    public func remove() -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_remove()()!
    }
    
    @discardableResult
    public func placeholder(_ value: String) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_placeholder()(value)!
    }
    
    @discardableResult
    public func x(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_x()(value)!
    }
    
    @discardableResult
    public func y(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_y()(value)!
    }
    
    @discardableResult
    public func color(_ value: UIColor) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_color()(value)!
    }
    
    @discardableResult
    public func dropIndex(_ value: Int) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_dropIndex()(value)!
    }
    
    @discardableResult
    public func dropFromIndex(_ value: Int) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_dropFromIndex()(value)!
    }
    
    @discardableResult
    public func removeOnDrop() -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_removeOnDrop()()!
    }
    
    @discardableResult
    public func dropStayTime(_ value: CGFloat) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_dropStayTime()(value)!
    }
}

// MARK: - FWTabBaseComponent

extension FWTabBaseComponent {
    @discardableResult
    public func left(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_left()(value)!
    }
    
    @discardableResult
    public func right(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_right()(value)!
    }
    
    @discardableResult
    public func up(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_up()(value)!
    }
    
    @discardableResult
    public func down(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_down()(value)!
    }
    
    @discardableResult
    public func width(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_width()(value)!
    }
    
    @discardableResult
    public func height(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_height()(value)!
    }
    
    @discardableResult
    public func radius(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_radius()(value)!
    }
    
    @discardableResult
    public func reducedWidth(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_reducedWidth()(value)!
    }
    
    @discardableResult
    public func reducedHeight(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_reducedHeight()(value)!
    }
    
    @discardableResult
    public func reducedRadius(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_reducedRadius()(value)!
    }
    
    @discardableResult
    public func x(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_x()(value)!
    }
    
    @discardableResult
    public func y(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_y()(value)!
    }
    
    @discardableResult
    public func line(_ value: Int) -> FWTabBaseComponent {
        return self._oc_line()(value)!
    }
    
    @discardableResult
    public func space(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_space()(value)!
    }
    
    @discardableResult
    public func lastLineScale(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_lastLineScale()(value)!
    }
    
    @discardableResult
    public func remove() -> FWTabBaseComponent {
        return self._oc_remove()()!
    }
    
    @discardableResult
    public func placeholder(_ value: String) -> FWTabBaseComponent {
        return self._oc_placeholder()(value)!
    }
    
    @discardableResult
    public func toLongAnimation() -> FWTabBaseComponent {
        return self._oc_toLongAnimation()()!
    }
    
    @discardableResult
    public func toShortAnimation() -> FWTabBaseComponent {
        return self._oc_toShortAnimation()()!
    }
    
    @discardableResult
    public func cancelAlignCenter() -> FWTabBaseComponent {
        return self._oc_cancelAlignCenter()()!
    }
    
    @discardableResult
    public func color(_ value: UIColor) -> FWTabBaseComponent {
        return self._oc_color()(value)!
    }
    
    @discardableResult
    public func dropIndex(_ value: Int) -> FWTabBaseComponent {
        return self._oc_dropIndex()(value)!
    }
    
    @discardableResult
    public func dropFromIndex(_ value: Int) -> FWTabBaseComponent {
        return self._oc_dropFromIndex()(value)!
    }
    
    @discardableResult
    public func removeOnDrop() -> FWTabBaseComponent {
        return self._oc_removeOnDrop()()!
    }
    
    @discardableResult
    public func dropStayTime(_ value: CGFloat) -> FWTabBaseComponent {
        return self._oc_dropStayTime()(value)!
    }
}

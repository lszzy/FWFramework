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
    public func line(_ value: Int) -> [FWTabBaseComponent] {
        return (self as NSArray)._oc_line()(value)!
    }
}

// MARK: - FWTabBaseComponent

extension FWTabBaseComponent {
    @discardableResult
    public func remove() -> FWTabBaseComponent {
        return self._oc_remove()()!
    }
}

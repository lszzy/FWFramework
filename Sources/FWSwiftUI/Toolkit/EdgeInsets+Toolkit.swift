//
//  EdgeInsets+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI

extension EdgeInsets {
    
    /// 静态zero边距
    public static var zero: Self { .init() }
    
    /// 自定义指定边长度，默认为0
    public init(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) {
        self.init(top: 0, leading: 0, bottom: 0, trailing: 0)
        guard let length = length else { return }
        
        if edges.contains(.top) { top = length }
        if edges.contains(.leading) { leading = length }
        if edges.contains(.bottom) { bottom = length }
        if edges.contains(.trailing) { trailing = length }
    }
    
}

#endif

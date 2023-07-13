//
//  EmptyView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - ScrollOverlayView
/// 滚动视图自定义浮层视图
open class ScrollOverlayView: UIView {
    
    /// 添加到父视图时是否执行动画，默认false
    open var fadeAnimated: Bool = false
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if fadeAnimated {
            fadeAnimated = false
            frame = CGRect(x: 0, y: 0, width: superview?.bounds.size.width ?? 0, height: superview?.bounds.size.height ?? 0)
            alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.alpha = 1.0
            }
        } else {
            frame = CGRect(x: 0, y: 0, width: superview?.bounds.size.width ?? 0, height: superview?.bounds.size.height ?? 0)
        }
    }
    
}

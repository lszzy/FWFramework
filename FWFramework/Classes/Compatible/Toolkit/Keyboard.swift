//
//  Keyboard.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/13.
//

import UIKit

extension Wrapper where Base: UITextField {
    
    /// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
    public var touchResign: Bool {
        get { return base.__fw.touchResign }
        set { base.__fw.touchResign = newValue }
    }
    
    /// 获取键盘弹出时的高度，对应Key为UIKeyboardFrameEndUserInfoKey
    public func keyboardHeight(_ notification: Notification) -> CGFloat {
        return base.__fw.keyboardHeight(notification)
    }

    /// 执行键盘跟随动画，支持AutoLayout，可通过keyboardHeight:获取键盘高度
    public func keyboardAnimate(_ notification: Notification, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        base.__fw.keyboardAnimate(notification, animations: animations, completion: completion)
    }
    
}

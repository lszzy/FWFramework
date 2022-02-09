//
//  FWRelative.swift
//  FWFramework
//
//  Created by wuyong on 2020/9/8.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit
#if FWFrameworkSPM
import FWFramework
#endif

// MARK: - UIScreen+FWRelative

/// 当前屏幕宽度缩放比例
public var FWScaleWidth: CGFloat { return UIScreen.fwScaleWidth }
/// 当前屏幕高度缩放比例
public var FWScaleHeight: CGFloat { return UIScreen.fwScaleHeight }

// MARK: - UIFont+FWRelative

/// 快速创建等比例缩放系统字体
///
/// - Parameters:
///   - size: 设计图字体字号
///   - weight: 字重可选，默认Regular
/// - Returns: 等比例缩放UIFont
public func FWFontRelative(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
    return UIFont.fwFontRelative(size, weight: weight)
}

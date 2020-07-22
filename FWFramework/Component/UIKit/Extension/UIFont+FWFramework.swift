//
//  UIFont+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2020/7/17.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation

/// 快速创建系统字体
///
/// - Parameters:
///   - size: 字体字号
///   - weight: 字重可选，默认Regular
/// - Returns: UIFont
public func FWFontSize(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
    return UIFont.systemFont(ofSize: size, weight: weight)
}

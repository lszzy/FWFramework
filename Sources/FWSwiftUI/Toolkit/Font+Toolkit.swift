//
//  Font+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
import FWFramework
#endif

@available(iOS 13.0, *)
extension Font {
    
    /// 全局自定义字体句柄，优先调用
    public static var fontBlock: ((CGFloat, Font.Weight) -> Font)?
    
    /// 返回系统Thin字体
    public static func thinFont(size: CGFloat) -> Font {
        return font(size: size, weight: .thin)
    }
    
    /// 返回系统Light字体
    public static func lightFont(size: CGFloat) -> Font {
        return font(size: size, weight: .light)
    }
    
    /// 返回系统Medium字体
    public static func mediumFont(size: CGFloat) -> Font {
        return font(size: size, weight: .medium)
    }
    
    /// 返回系统Semibold字体
    public static func semiboldFont(size: CGFloat) -> Font {
        return font(size: size, weight: .semibold)
    }
    
    /// 返回系统Bold字体
    public static func boldFont(size: CGFloat) -> Font {
        return font(size: size, weight: .bold)
    }

    /// 创建指定尺寸和weight的系统字体
    public static func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let block = fontBlock {
            return block(size, weight)
        }
        
        let fontSize = UIFont.fw.autoScale ? UIScreen.fw.relativeValue(size) : size
        return .system(size: fontSize, weight: weight)
    }
    
}

#endif

//
//  QuartzCore.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/16.
//

import QuartzCore

// MARK: - CADisplayLink+QuartzCore
/// 如果block参数不会被持有并后续执行，可声明为NS_NOESCAPE，不会触发循环引用
extension Wrapper where Base: CADisplayLink {
    
    /// 创建CADisplayLink，使用target-action，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameters:
    ///   - target: 目标
    ///   - selector: 方法
    /// - Returns: CADisplayLink
    public static func commonDisplayLink(target: Any, selector: Selector) -> CADisplayLink {
        return Base.__fw.commonDisplayLink(withTarget: target, selector: selector)
    }

    /// 创建CADisplayLink，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameter block: 代码块
    /// - Returns: CADisplayLink
    public static func commonDisplayLink(block: @escaping (CADisplayLink) -> Void) -> CADisplayLink {
        return Base.__fw.commonDisplayLink(block)
    }

    /// 创建CADisplayLink，使用block，需要调用addToRunLoop:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
    ///
    /// 示例：[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes]
    /// - Parameter block: 代码块
    /// - Returns: CADisplayLink
    public static func displayLink(block: @escaping (CADisplayLink) -> Void) -> CADisplayLink {
        return Base.__fw.displayLink(block)
    }
    
}

// MARK: - CAAnimation+QuartzCore
extension Wrapper where Base: CAAnimation {
    
    /// 设置动画开始回调，需要在add之前添加，因为add时会自动拷贝一份对象
    public var startBlock: ((CAAnimation) -> Void)? {
        get { return base.__fw.startBlock }
        set { base.__fw.startBlock = newValue }
    }

    /// 设置动画停止回调
    public var stopBlock: ((CAAnimation, Bool) -> Void)? {
        get { return base.__fw.stopBlock }
        set { base.__fw.stopBlock = newValue }
    }
    
}

// MARK: - CALayer+QuartzCore
extension Wrapper where Base: CALayer {
    
    /// 设置主题背景色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeBackgroundColor: UIColor? {
        get { return base.__fw.themeBackgroundColor }
        set { base.__fw.themeBackgroundColor = newValue }
    }

    /// 设置主题边框色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeBorderColor: UIColor? {
        get { return base.__fw.themeBorderColor }
        set { base.__fw.themeBorderColor = newValue }
    }

    /// 设置主题阴影色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeShadowColor: UIColor? {
        get { return base.__fw.themeShadowColor }
        set { base.__fw.themeShadowColor = newValue }
    }

    /// 设置主题内容图片，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeContents: UIImage? {
        get { return base.__fw.themeContents }
        set { base.__fw.themeContents = newValue }
    }
    
}

// MARK: - CAGradientLayer+QuartzCore
extension Wrapper where Base: CAGradientLayer {
    
    /// 设置主题渐变色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeColors: [UIColor]? {
        get { return base.__fw.themeColors }
        set { base.__fw.themeColors = newValue }
    }
    
}

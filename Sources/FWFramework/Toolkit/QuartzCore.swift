//
//  QuartzCore.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
import QuartzCore

// MARK: - Wrapper+CADisplayLink
/// 如果block参数不会被持有并后续执行，可声明为NS_NOESCAPE，不会触发循环引用
extension Wrapper where Base: CADisplayLink {
    /// 创建CADisplayLink，使用target-action，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameters:
    ///   - target: 目标
    ///   - selector: 方法
    /// - Returns: CADisplayLink
    public static func commonDisplayLink(target: Any, selector: Selector) -> CADisplayLink {
        return Base.fw_commonDisplayLink(target: target, selector: selector)
    }

    /// 创建CADisplayLink，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameter block: 代码块
    /// - Returns: CADisplayLink
    public static func commonDisplayLink(block: @escaping (CADisplayLink) -> Void) -> CADisplayLink {
        return Base.fw_commonDisplayLink(block: block)
    }

    /// 创建CADisplayLink，使用block，需要调用addToRunLoop:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
    ///
    /// 示例：[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes]
    /// - Parameter block: 代码块
    /// - Returns: CADisplayLink
    public static func displayLink(block: @escaping (CADisplayLink) -> Void) -> CADisplayLink {
        return Base.fw_displayLink(block: block)
    }
}

// MARK: - Wrapper+CAAnimation
extension Wrapper where Base: CAAnimation {
    /// 设置动画开始回调，需要在add之前添加，因为add时会自动拷贝一份对象
    public var startBlock: ((CAAnimation) -> Void)? {
        get { base.fw_startBlock }
        set { base.fw_startBlock = newValue }
    }

    /// 设置动画停止回调
    public var stopBlock: ((CAAnimation, Bool) -> Void)? {
        get { base.fw_stopBlock }
        set { base.fw_stopBlock = newValue }
    }
}

// MARK: - Wrapper+CALayer
extension Wrapper where Base: CALayer {
    /// 设置主题背景色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeBackgroundColor: UIColor? {
        get { base.fw_themeBackgroundColor }
        set { base.fw_themeBackgroundColor = newValue }
    }

    /// 设置主题边框色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeBorderColor: UIColor? {
        get { base.fw_themeBorderColor }
        set { base.fw_themeBorderColor = newValue }
    }

    /// 设置主题阴影色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeShadowColor: UIColor? {
        get { base.fw_themeShadowColor }
        set { base.fw_themeShadowColor = newValue }
    }

    /// 设置主题内容图片，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeContents: UIImage? {
        get { base.fw_themeContents }
        set { base.fw_themeContents = newValue }
    }
    
    /// 设置阴影颜色、偏移和半径
    public func setShadowColor(_ color: UIColor?, offset: CGSize, radius: CGFloat) {
        base.fw_setShadowColor(color, offset: offset, radius: radius)
    }
    
    /// 移除所有支持动画属性的默认动画，需要一个不带动画的layer时使用
    public func removeDefaultAnimations() {
        base.fw_removeDefaultAnimations()
    }
    
    /// 生成图片截图，默认大小为frame.size
    public func snapshotImage(size: CGSize = .zero) -> UIImage? {
        return base.fw_snapshotImage(size: size)
    }
}

// MARK: - Wrapper+CAGradientLayer
extension Wrapper where Base: CAGradientLayer {
    /// 设置主题渐变色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeColors: [UIColor]? {
        get { base.fw_themeColors }
        set { base.fw_themeColors = newValue }
    }
    
    /**
     *  创建渐变层，需手工addLayer
     *
     *  @param frame      渐变区域
     *  @param colors     渐变颜色，CGColor数组，如[黑，白，黑]
     *  @param locations  渐变位置，0~1，如[0.25, 0.5, 0.75]对应颜色为[0-0.25黑,0.25-0.5黑渐变白,0.5-0.75白渐变黑,0.75-1黑]
     *  @param startPoint 渐变开始点，设置渐变方向，左上点为(0,0)，右下点为(1,1)
     *  @param endPoint   渐变结束点
     *  @return 渐变Layer
     */
    public static func gradientLayer(
        _ frame: CGRect,
        colors: [Any],
        locations: [NSNumber]?,
        startPoint: CGPoint,
        endPoint: CGPoint
    ) -> CAGradientLayer {
        return Base.fw_gradientLayer(frame, colors: colors, locations: locations, startPoint: startPoint, endPoint: endPoint)
    }
}

// MARK: - Wrapper+UIView
extension Wrapper where Base: UIView {
    /**
     绘制形状路径，需要在drawRect中调用
     
     @param bezierPath 绘制路径
     @param strokeWidth 绘制宽度
     @param strokeColor 绘制颜色
     @param fillColor 填充颜色
     */
    public func drawBezierPath(_ bezierPath: UIBezierPath, strokeWidth: CGFloat, strokeColor: UIColor, fillColor: UIColor?) {
        base.fw_drawBezierPath(bezierPath, strokeWidth: strokeWidth, strokeColor: strokeColor, fillColor: fillColor)
    }

    /**
     绘制渐变颜色，需要在drawRect中调用，支持四个方向，默认向下Down
     
     @param rect 绘制区域
     @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
     @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
     @param direction 渐变方向，自动计算startPoint和endPoint，支持四个方向，默认向下Down
     */
    public func drawLinearGradient(_ rect: CGRect, colors: [Any], locations: UnsafePointer<CGFloat>?, direction: UISwipeGestureRecognizer.Direction) {
        base.fw_drawLinearGradient(rect, colors: colors, locations: locations, direction: direction)
    }

    /**
     绘制渐变颜色，需要在drawRect中调用
     
     @param rect 绘制区域
     @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
     @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
     @param startPoint 渐变开始点，需要根据rect计算
     @param endPoint 渐变结束点，需要根据rect计算
     */
    public func drawLinearGradient(_ rect: CGRect, colors: [Any], locations: UnsafePointer<CGFloat>?, startPoint: CGPoint, endPoint: CGPoint) {
        base.fw_drawLinearGradient(rect, colors: colors, locations: locations, startPoint: startPoint, endPoint: endPoint)
    }

    /**
     *  添加渐变Layer
     *
     *  @param frame      渐变区域
     *  @param colors     渐变颜色，CGColor数组，如[黑，白，黑]
     *  @param locations  渐变位置，0~1，如[0.25, 0.5, 0.75]对应颜色为[0-0.25黑,0.25-0.5黑渐变白,0.5-0.75白渐变黑,0.75-1黑]
     *  @param startPoint 渐变开始点，设置渐变方向，左上点为(0,0)，右下点为(1,1)
     *  @param endPoint   渐变结束点
     *  @return 渐变Layer
     */
    @discardableResult
    public func addGradientLayer(_ frame: CGRect, colors: [Any], locations: [NSNumber]?, startPoint: CGPoint, endPoint: CGPoint) -> CAGradientLayer {
        return base.fw_addGradientLayer(frame, colors: colors, locations: locations, startPoint: startPoint, endPoint: endPoint)
    }

    /**
     添加虚线Layer
     
     @param rect 虚线区域，从中心绘制
     @param lineLength 虚线的宽度
     @param lineSpacing 虚线的间距
     @param lineColor 虚线的颜色
     @return 虚线Layer
     */
    @discardableResult
    public func addDashLayer(_ rect: CGRect, lineLength: CGFloat, lineSpacing: CGFloat, lineColor: UIColor) -> CALayer {
        return base.fw_addDashLayer(rect, lineLength: lineLength, lineSpacing: lineSpacing, lineColor: lineColor)
    }
    
    // MARK: - Animation
    /**
     添加UIView动画，使用默认动画参数
     @note 如果动画过程中需要获取进度，可通过添加CADisplayLink访问self.layer.presentationLayer获取，下同
     
     @param block       动画代码块
     @param duration   持续时间
     @param options    动画选项，默认7<<16
     @param completion 完成事件
     */
    public func addAnimation(block: @escaping () -> Void, duration: TimeInterval, options: UIView.AnimationOptions? = nil, completion: ((Bool) -> Void)? = nil) {
        base.fw_addAnimation(block: block, duration: duration, options: options, completion: completion)
    }

    /**
     添加UIView动画
     
     @param curve      动画速度
     @param transition 动画类型
     @param duration   持续时间，默认0.2
     @param animations 动画句柄
     @param completion 完成事件
     */
    public func addAnimation(curve: UIView.AnimationOptions, transition: UIView.AnimationOptions, duration: TimeInterval, animations: (() -> Void)? = nil, completion: ((Bool) -> Void)? = nil) {
        base.fw_addAnimation(curve: curve, transition: transition, duration: duration, animations: animations, completion: completion)
    }

    /**
     添加CABasicAnimation动画
     
     @param keyPath    动画路径
     @param fromValue  开始值
     @param toValue    结束值
     @param duration   持续时间，0为默认(0.25秒)
     @param completion 完成事件
     @return CABasicAnimation
     */
    @discardableResult
    public func addAnimation(keyPath: String, fromValue: Any, toValue: Any, duration: CFTimeInterval, completion: ((Bool) -> Void)? = nil) -> CABasicAnimation {
        return base.fw_addAnimation(keyPath: keyPath, fromValue: fromValue, toValue: toValue, duration: duration, completion: completion)
    }

    /**
     添加转场动画，可指定animationsEnabled，一般用于window切换rootViewController
     
     @param options   动画选项
     @param block      动画代码块
     @param duration  持续时间
     @param animationsEnabled 是否启用动画，默认true
     @param completion 完成事件
     */
    public func addTransition(options: UIView.AnimationOptions = [], block: @escaping () -> Void, duration: TimeInterval, animationsEnabled: Bool = true, completion: ((Bool) -> Void)? = nil) {
        base.fw_addTransition(options: options, block: block, duration: duration, animationsEnabled: animationsEnabled, completion: completion)
    }

    /**
     添加CATransition转场动画
     备注：移除动画可调用[self fwRemoveAnimation]
     
     @param type           动画类型
     @param subtype        子类型
     @param timingFunction 动画速度
     @param duration       持续时间，0为默认(0.25秒)
     @param completion     完成事件
     @return CATransition
     */
    @discardableResult
    public func addTransition(type: CATransitionType, subtype: CATransitionSubtype?, timingFunction: CAMediaTimingFunction?, duration: CFTimeInterval, completion: ((Bool) -> Void)? = nil) -> CATransition {
        return base.fw_addTransition(type: type, subtype: subtype, timingFunction: timingFunction, duration: duration, completion: completion)
    }

    /// 移除单个框架视图动画
    public func removeAnimation() {
        base.fw_removeAnimation()
    }

    /// 移除所有视图动画
    public func removeAllAnimations() {
        base.fw_removeAllAnimations()
    }

    /**
     *  绘制动画
     *
     *  @param layer      CAShapeLayer层
     *  @param duration   持续时间
     *  @param completion 完成回调
     *  @return CABasicAnimation
     */
    @discardableResult
    public func stroke(layer: CAShapeLayer, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) -> CABasicAnimation {
        return base.fw_stroke(layer: layer, duration: duration, completion: completion)
    }

    /**
     *  水平摇摆动画
     *
     *  @param times      摇摆次数，默认10
     *  @param delta      摇摆宽度，默认5
     *  @param duration   单次时间，默认0.03
     *  @param completion 完成回调
     */
    public func shake(times: Int, delta: CGFloat, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.fw_shake(times: times, delta: delta, duration: duration, completion: completion)
    }

    /**
     *  渐显隐动画
     *
     *  @param alpha      透明度
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func fade(alpha: CGFloat, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.fw_fade(alpha: alpha, duration: duration, completion: completion)
    }

    /**
     *  渐变代码块动画
     *
     *  @param block      动画代码块，比如调用imageView.setImage:方法
     *  @param duration   持续时长，建议0.5
     *  @param completion 完成回调
     */
    public func fade(block: @escaping () -> Void, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.fw_fade(block: block, duration: duration, completion: completion)
    }

    /**
     *  旋转动画
     *
     *  @param degree     旋转度数，备注：逆时针需设置-179.99。使用CAAnimation无此问题
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func rotate(degree: CGFloat, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.fw_rotate(degree: degree, duration: duration, completion: completion)
    }

    /**
     *  缩放动画
     *
     *  @param scaleX     X轴缩放率
     *  @param scaleY     Y轴缩放率
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func scale(scaleX: CGFloat, scaleY: CGFloat, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.fw_scale(scaleX: scaleX, scaleY: scaleY, duration: duration, completion: completion)
    }

    /**
     *  移动动画
     *
     *  @param point      目标点
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func move(point: CGPoint, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.fw_move(point: point, duration: duration, completion: completion)
    }

    /**
     *  移动变化动画
     *
     *  @param frame      目标区域
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func move(frame: CGRect, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.fw_move(frame: frame, duration: duration, completion: completion)
    }
    
    /**
     取消动画效果执行block
     
     @param block 动画代码块
     @param completion 完成事件
     */
    public static func animateNone(block: @escaping () -> Void, completion: (() -> Void)? = nil) {
        Base.fw_animateNone(block: block, completion: completion)
    }

    /**
     执行block动画完成后执行指定回调
     
     @param block 动画代码块
     @param completion 完成事件
     */
    public static func animate(block: () -> Void, completion: (() -> Void)? = nil) {
        Base.fw_animate(block: block, completion: completion)
    }
    
    // MARK: - Drag
    /// 是否启用拖动，默认NO
    public var dragEnabled: Bool {
        get { return base.fw_dragEnabled }
        set { base.fw_dragEnabled = newValue }
    }

    /// 拖动手势，延迟加载
    public var dragGesture: UIPanGestureRecognizer {
        return base.fw_dragGesture
    }

    /// 设置拖动限制区域，默认CGRectZero，无限制
    public var dragLimit: CGRect {
        get { return base.fw_dragLimit }
        set { base.fw_dragLimit = newValue }
    }

    /// 设置拖动动作有效区域，默认self.frame
    public var dragArea: CGRect {
        get { return base.fw_dragArea }
        set { base.fw_dragArea = newValue }
    }

    /// 是否允许横向拖动(X)，默认YES
    public var dragHorizontal: Bool {
        get { return base.fw_dragHorizontal }
        set { base.fw_dragHorizontal = newValue }
    }

    /// 是否允许纵向拖动(Y)，默认YES
    public var dragVertical: Bool {
        get { return base.fw_dragVertical }
        set { base.fw_dragVertical = newValue }
    }

    /// 开始拖动回调
    public var dragStartedBlock: ((UIView) -> Void)? {
        get { return base.fw_dragStartedBlock }
        set { base.fw_dragStartedBlock = newValue }
    }

    /// 拖动移动回调
    public var dragMovedBlock: ((UIView) -> Void)? {
        get { return base.fw_dragMovedBlock }
        set { base.fw_dragMovedBlock = newValue }
    }

    /// 结束拖动回调
    public var dragEndedBlock: ((UIView) -> Void)? {
        get { return base.fw_dragEndedBlock }
        set { base.fw_dragEndedBlock = newValue }
    }
}

// MARK: - CADisplayLink+QuartzCore
/// 如果block参数不会被持有并后续执行，可声明为NS_NOESCAPE，不会触发循环引用
@_spi(FW) extension CADisplayLink {
    
    /// 创建CADisplayLink，使用target-action，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameters:
    ///   - target: 目标
    ///   - selector: 方法
    /// - Returns: CADisplayLink
    public static func fw_commonDisplayLink(target: Any, selector: Selector) -> CADisplayLink {
        let displayLink = CADisplayLink(target: target, selector: selector)
        displayLink.add(to: .current, forMode: .common)
        return displayLink
    }

    /// 创建CADisplayLink，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameter block: 代码块
    /// - Returns: CADisplayLink
    public static func fw_commonDisplayLink(block: @escaping (CADisplayLink) -> Void) -> CADisplayLink {
        let displayLink = fw_displayLink(block: block)
        displayLink.add(to: .current, forMode: .common)
        return displayLink
    }

    /// 创建CADisplayLink，使用block，需要调用addToRunLoop:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
    ///
    /// 示例：[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes]
    /// - Parameter block: 代码块
    /// - Returns: CADisplayLink
    public static func fw_displayLink(block: @escaping (CADisplayLink) -> Void) -> CADisplayLink {
        let displayLink = CADisplayLink(target: CADisplayLink.self, selector: #selector(CADisplayLink.fw_displayLinkAction(_:)))
        displayLink.fw.setPropertyCopy(block, forName: "fw_displayLinkAction")
        return displayLink
    }
    
    @objc private class func fw_displayLinkAction(_ displayLink: CADisplayLink) {
        let block = displayLink.fw.property(forName: "fw_displayLinkAction") as? (CADisplayLink) -> Void
        block?(displayLink)
    }
    
}

// MARK: - CAAnimation+QuartzCore
@_spi(FW) extension CAAnimation {
    
    /// 设置动画开始回调，需要在add之前添加，因为add时会自动拷贝一份对象
    public var fw_startBlock: ((CAAnimation) -> Void)? {
        get {
            let target = fw_animationTarget(false)
            return target?.startBlock
        }
        set {
            let target = fw_animationTarget(true)
            target?.startBlock = newValue
            self.delegate = target
        }
    }

    /// 设置动画停止回调
    public var fw_stopBlock: ((CAAnimation, Bool) -> Void)? {
        get {
            let target = fw_animationTarget(false)
            return target?.stopBlock
        }
        set {
            let target = fw_animationTarget(true)
            target?.stopBlock = newValue
            self.delegate = target
        }
    }
    
    private func fw_animationTarget(_ lazyload: Bool) -> AnimationTarget? {
        var target = fw.property(forName: "fw_animationTarget") as? AnimationTarget
        if target == nil && lazyload {
            target = AnimationTarget()
            fw.setProperty(target, forName: "fw_animationTarget")
        }
        return target
    }
    
    private class AnimationTarget: NSObject, CAAnimationDelegate {
        
        var startBlock: ((CAAnimation) -> Void)?
        var stopBlock: ((CAAnimation, Bool) -> Void)?
        
        func animationDidStart(_ anim: CAAnimation) {
            startBlock?(anim)
        }
        
        func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
            stopBlock?(anim, flag)
        }
        
    }
    
}

// MARK: - CALayer+QuartzCore
@_spi(FW) extension CALayer {
    
    /// 设置主题背景色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var fw_themeBackgroundColor: UIColor? {
        get {
            return fw.property(forName: "fw_themeBackgroundColor") as? UIColor
        }
        set {
            fw.setProperty(newValue, forName: "fw_themeBackgroundColor")
            self.backgroundColor = newValue?.cgColor
        }
    }

    /// 设置主题边框色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var fw_themeBorderColor: UIColor? {
        get {
            return fw.property(forName: "fw_themeBorderColor") as? UIColor
        }
        set {
            fw.setProperty(newValue, forName: "fw_themeBorderColor")
            self.borderColor = newValue?.cgColor
        }
    }

    /// 设置主题阴影色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var fw_themeShadowColor: UIColor? {
        get {
            return fw.property(forName: "fw_themeShadowColor") as? UIColor
        }
        set {
            fw.setProperty(newValue, forName: "fw_themeShadowColor")
            self.shadowColor = newValue?.cgColor
        }
    }

    /// 设置主题内容图片，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var fw_themeContents: UIImage? {
        get {
            return fw.property(forName: "fw_themeContents") as? UIImage
        }
        set {
            fw.setProperty(newValue, forName: "fw_themeContents")
            self.contents = newValue?.fw_image?.cgImage
        }
    }
    
    /// 设置阴影颜色、偏移和半径
    public func fw_setShadowColor(_ color: UIColor?, offset: CGSize, radius: CGFloat) {
        self.shadowColor = color?.cgColor
        self.shadowOffset = offset
        self.shadowRadius = radius
        self.shadowOpacity = 1.0
    }
    
    /// 移除所有支持动画属性的默认动画，需要一个不带动画的layer时使用
    public func fw_removeDefaultAnimations() {
        var actions: [String: CAAction] = [
            NSStringFromSelector(#selector(getter: bounds)): NSNull(),
            NSStringFromSelector(#selector(getter: position)): NSNull(),
            NSStringFromSelector(#selector(getter: zPosition)): NSNull(),
            NSStringFromSelector(#selector(getter: anchorPoint)): NSNull(),
            NSStringFromSelector(#selector(getter: anchorPointZ)): NSNull(),
            NSStringFromSelector(#selector(getter: transform)): NSNull(),
            NSStringFromSelector(#selector(getter: isHidden)): NSNull(),
            NSStringFromSelector(#selector(getter: isDoubleSided)): NSNull(),
            NSStringFromSelector(#selector(getter: sublayerTransform)): NSNull(),
            NSStringFromSelector(#selector(getter: masksToBounds)): NSNull(),
            NSStringFromSelector(#selector(getter: contents)): NSNull(),
            NSStringFromSelector(#selector(getter: contentsRect)): NSNull(),
            NSStringFromSelector(#selector(getter: contentsScale)): NSNull(),
            NSStringFromSelector(#selector(getter: contentsCenter)): NSNull(),
            NSStringFromSelector(#selector(getter: minificationFilterBias)): NSNull(),
            NSStringFromSelector(#selector(getter: backgroundColor)): NSNull(),
            NSStringFromSelector(#selector(getter: cornerRadius)): NSNull(),
            NSStringFromSelector(#selector(getter: borderWidth)): NSNull(),
            NSStringFromSelector(#selector(getter: borderColor)): NSNull(),
            NSStringFromSelector(#selector(getter: opacity)): NSNull(),
            NSStringFromSelector(#selector(getter: compositingFilter)): NSNull(),
            NSStringFromSelector(#selector(getter: filters)): NSNull(),
            NSStringFromSelector(#selector(getter: backgroundFilters)): NSNull(),
            NSStringFromSelector(#selector(getter: shouldRasterize)): NSNull(),
            NSStringFromSelector(#selector(getter: rasterizationScale)): NSNull(),
            NSStringFromSelector(#selector(getter: shadowColor)): NSNull(),
            NSStringFromSelector(#selector(getter: shadowOpacity)): NSNull(),
            NSStringFromSelector(#selector(getter: shadowOffset)): NSNull(),
            NSStringFromSelector(#selector(getter: shadowRadius)): NSNull(),
            NSStringFromSelector(#selector(getter: shadowPath)): NSNull(),
            NSStringFromSelector(#selector(getter: maskedCorners)): NSNull(),
        ]
        
        if self is CAShapeLayer {
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.path))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.fillColor))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.strokeColor))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.strokeStart))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.strokeEnd))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.lineWidth))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.miterLimit))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.lineDashPhase))] = NSNull()
        }
        
        if self is CAGradientLayer {
            actions[NSStringFromSelector(#selector(getter: CAGradientLayer.colors))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAGradientLayer.locations))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAGradientLayer.startPoint))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAGradientLayer.endPoint))] = NSNull()
        }
        
        self.actions = actions
    }
    
    /// 生成图片截图，默认大小为frame.size
    public func fw_snapshotImage(size: CGSize = .zero) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size.equalTo(.zero) ? self.frame.size : size, false, UIScreen.main.scale)
        if let context = UIGraphicsGetCurrentContext() {
            self.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
    
    open override func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)
        
        if let themeBackgroundColor = fw_themeBackgroundColor {
            self.backgroundColor = themeBackgroundColor.cgColor
        }
        if let themeBorderColor = fw_themeBorderColor {
            self.borderColor = themeBorderColor.cgColor
        }
        if let themeShadowColor = fw_themeShadowColor {
            self.shadowColor = themeShadowColor.cgColor
        }
        if let themeContents = fw_themeContents, themeContents.fw_isThemeImage {
            self.contents = themeContents.fw_image?.cgImage
        }
    }
    
}

// MARK: - CAGradientLayer+QuartzCore
@_spi(FW) extension CAGradientLayer {
    
    /// 设置主题渐变色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var fw_themeColors: [UIColor]? {
        get {
            return fw.property(forName: "fw_themeColors") as? [UIColor]
        }
        set {
            fw.setProperty(newValue, forName: "fw_themeColors")
            self.colors = newValue?.map({ $0.cgColor })
        }
    }
    
    /**
     *  创建渐变层，需手工addLayer
     *
     *  @param frame      渐变区域
     *  @param colors     渐变颜色，CGColor数组，如[黑，白，黑]
     *  @param locations  渐变位置，0~1，如[0.25, 0.5, 0.75]对应颜色为[0-0.25黑,0.25-0.5黑渐变白,0.5-0.75白渐变黑,0.75-1黑]
     *  @param startPoint 渐变开始点，设置渐变方向，左上点为(0,0)，右下点为(1,1)
     *  @param endPoint   渐变结束点
     *  @return 渐变Layer
     */
    public static func fw_gradientLayer(
        _ frame: CGRect,
        colors: [Any],
        locations: [NSNumber]?,
        startPoint: CGPoint,
        endPoint: CGPoint
    ) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.colors = colors
        gradientLayer.locations = locations
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        return gradientLayer
    }
    
    open override func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)
        
        if let themeColors = fw_themeColors {
            self.colors = themeColors.map({ $0.cgColor })
        }
    }
    
}

// MARK: - UIView+QuartzCore
@_spi(FW) extension UIView {
    
    /**
     绘制形状路径，需要在drawRect中调用
     
     @param bezierPath 绘制路径
     @param strokeWidth 绘制宽度
     @param strokeColor 绘制颜色
     @param fillColor 填充颜色
     */
    public func fw_drawBezierPath(
        _ bezierPath: UIBezierPath,
        strokeWidth: CGFloat,
        strokeColor: UIColor,
        fillColor: UIColor?
    ) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        
        context.setLineWidth(strokeWidth)
        context.setLineCap(.round)
        strokeColor.setStroke()
        context.addPath(bezierPath.cgPath)
        context.strokePath()
        
        if let fillColor = fillColor {
            fillColor.setFill()
            context.addPath(bezierPath.cgPath)
            context.fillPath()
        }
        
        context.restoreGState()
    }

    /**
     绘制渐变颜色，需要在drawRect中调用，支持四个方向，默认向下Down
     
     @param rect 绘制区域
     @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
     @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
     @param direction 渐变方向，自动计算startPoint和endPoint，支持四个方向，默认向下Down
     */
    public func fw_drawLinearGradient(
        _ rect: CGRect,
        colors: [Any],
        locations: UnsafePointer<CGFloat>?,
        direction: UISwipeGestureRecognizer.Direction
    ) {
        let linePoints = UIBezierPath.fw_linePoints(rect: rect, direction: direction)
        let startPoint = linePoints.first?.cgPointValue ?? .zero
        let endPoint = linePoints.last?.cgPointValue ?? .zero
        return fw_drawLinearGradient(rect, colors: colors, locations: locations, startPoint: startPoint, endPoint: endPoint)
    }

    /**
     绘制渐变颜色，需要在drawRect中调用
     
     @param rect 绘制区域
     @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
     @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
     @param startPoint 渐变开始点，需要根据rect计算
     @param endPoint 渐变结束点，需要根据rect计算
     */
    public func fw_drawLinearGradient(
        _ rect: CGRect,
        colors: [Any],
        locations: UnsafePointer<CGFloat>?,
        startPoint: CGPoint,
        endPoint: CGPoint
    ) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        
        context.addRect(rect)
        context.clip()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) {
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }
        
        context.restoreGState()
    }

    /**
     *  添加渐变Layer
     *
     *  @param frame      渐变区域
     *  @param colors     渐变颜色，CGColor数组，如[黑，白，黑]
     *  @param locations  渐变位置，0~1，如[0.25, 0.5, 0.75]对应颜色为[0-0.25黑,0.25-0.5黑渐变白,0.5-0.75白渐变黑,0.75-1黑]
     *  @param startPoint 渐变开始点，设置渐变方向，左上点为(0,0)，右下点为(1,1)
     *  @param endPoint   渐变结束点
     *  @return 渐变Layer
     */
    @discardableResult
    public func fw_addGradientLayer(
        _ frame: CGRect,
        colors: [Any],
        locations: [NSNumber]?,
        startPoint: CGPoint,
        endPoint: CGPoint
    ) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.colors = colors
        gradientLayer.locations = locations
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        
        self.layer.addSublayer(gradientLayer)
        return gradientLayer
    }

    /**
     添加虚线Layer
     
     @param rect 虚线区域，从中心绘制
     @param lineLength 虚线的宽度
     @param lineSpacing 虚线的间距
     @param lineColor 虚线的颜色
     @return 虚线Layer
     */
    @discardableResult
    public func fw_addDashLayer(
        _ rect: CGRect,
        lineLength: CGFloat,
        lineSpacing: CGFloat,
        lineColor: UIColor
    ) -> CALayer {
        let dashLayer = CAShapeLayer()
        dashLayer.frame = rect
        dashLayer.fillColor = UIColor.clear.cgColor
        dashLayer.strokeColor = lineColor.cgColor
        
        let isVertical = lineLength + lineSpacing > rect.size.width
        dashLayer.lineWidth = isVertical ? CGRectGetWidth(rect) : CGRectGetHeight(rect)
        dashLayer.lineJoin = .round
        dashLayer.lineDashPattern = [NSNumber(value: lineLength), NSNumber(value: lineSpacing)]
        
        let path = UIBezierPath()
        if isVertical {
            path.move(to: CGPoint(x: CGRectGetWidth(rect) / 2.0, y: 0))
            path.addLine(to: CGPoint(x: CGRectGetWidth(rect) / 2.0, y: CGRectGetHeight(rect)))
        } else {
            path.move(to: CGPoint(x: 0, y: CGRectGetHeight(rect) / 2.0))
            path.addLine(to: CGPoint(x: CGRectGetWidth(rect), y: CGRectGetHeight(rect) / 2.0))
        }
        dashLayer.path = path.cgPath
        self.layer.addSublayer(dashLayer)
        return dashLayer
    }
    
    // MARK: - Animation
    /**
     添加UIView动画，使用默认动画参数
     @note 如果动画过程中需要获取进度，可通过添加CADisplayLink访问self.layer.presentationLayer获取，下同
     
     @param block       动画代码块
     @param duration   持续时间
     @param options    动画选项，默认7<<16
     @param completion 完成事件
     */
    public func fw_addAnimation(
        block: @escaping () -> Void,
        duration: TimeInterval,
        options: UIView.AnimationOptions? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        // 注意：AutoLayout动画需要调用父视图(如控制器self.view)的layoutIfNeeded更新布局才能生效
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options ?? .init(rawValue: 7<<16),
            animations: block,
            completion: completion
        )
    }

    /**
     添加UIView动画
     
     @param curve      动画速度
     @param transition 动画类型
     @param duration   持续时间，默认0.2
     @param animations 动画句柄
     @param completion 完成事件
     */
    public func fw_addAnimation(
        curve: UIView.AnimationOptions,
        transition: UIView.AnimationOptions,
        duration: TimeInterval,
        animations: (() -> Void)? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        UIView.transition(
            with: self,
            duration: duration,
            options: curve.union(transition),
            animations: animations,
            completion: completion
        )
    }

    /**
     添加CABasicAnimation动画
     
     @param keyPath    动画路径
     @param fromValue  开始值
     @param toValue    结束值
     @param duration   持续时间，0为默认(0.25秒)
     @param completion 完成事件
     @return CABasicAnimation
     */
    @discardableResult
    public func fw_addAnimation(
        keyPath: String,
        fromValue: Any,
        toValue: Any,
        duration: CFTimeInterval,
        completion: ((Bool) -> Void)? = nil
    ) -> CABasicAnimation {
        // keyPath支持值如下：
        // transform.rotation[.(x|y|z)]: 轴旋转动画
        // transform.scale[.(x|y|z)]: 轴缩放动画
        // transform.translation[.(x|y|z)]: 轴平移动画
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = fromValue
        animation.toValue = toValue
        // 默认值0.25
        animation.duration = duration
        
        // 设置完成事件，需要在add之前设置才能生效，因为add时会copy动画对象
        if completion != nil {
            animation.fw_stopBlock = { _, finished in
                completion?(finished)
            }
        }
        
        self.layer.add(animation, forKey: "FWAnimation")
        return animation
    }

    /**
     添加转场动画，可指定animationsEnabled，一般用于window切换rootViewController
     
     @param options   动画选项
     @param block      动画代码块
     @param duration  持续时间
     @param animationsEnabled 是否启用动画，默认true
     @param completion 完成事件
     */
    public func fw_addTransition(
        options: UIView.AnimationOptions = [],
        block: @escaping () -> Void,
        duration: TimeInterval,
        animationsEnabled: Bool = true,
        completion: ((Bool) -> Void)? = nil
    ) {
        UIView.transition(
            with: self,
            duration: duration,
            options: options,
            animations: {
                let wasEnabled = UIView.areAnimationsEnabled
                UIView.setAnimationsEnabled(animationsEnabled)
                block()
                UIView.setAnimationsEnabled(wasEnabled)
            },
            completion: completion
        )
    }

    /**
     添加CATransition转场动画
     备注：移除动画可调用[self fwRemoveAnimation]
     
     @param type           动画类型
     @param subtype        子类型
     @param timingFunction 动画速度
     @param duration       持续时间，0为默认(0.25秒)
     @param completion     完成事件
     @return CATransition
     */
    @discardableResult
    public func fw_addTransition(
        type: CATransitionType,
        subtype: CATransitionSubtype?,
        timingFunction: CAMediaTimingFunction?,
        duration: CFTimeInterval,
        completion: ((Bool) -> Void)? = nil
    ) -> CATransition {
        // 默认动画完成后自动移除，removedOnCompletion为YES
        let transition = CATransition()
        
        /** type
         *
         *  各种动画效果
         *  kCATransitionFade           交叉淡化过渡(不支持过渡方向)，同fade，默认效果
         *  kCATransitionMoveIn         新视图移到旧视图上面
         *  kCATransitionPush           新视图把旧视图推出去
         *  kCATransitionReveal         显露效果(将旧视图移开,显示下面的新视图)
         *
         *  @"fade"                     交叉淡化过渡(不支持过渡方向)，默认效果
         *  @"moveIn"                   新视图移到旧视图上面
         *  @"push"                     新视图把旧视图推出去
         *  @"reveal"                   显露效果(将旧视图移开,显示下面的新视图)
         *
         *  @"cube"                     立方体翻滚效果
         *  @"pageCurl"                 向上翻一页
         *  @"pageUnCurl"               向下翻一页
         *  @"suckEffect"               收缩效果，类似系统最小化窗口时的神奇效果(不支持过渡方向)
         *  @"rippleEffect"             滴水效果,(不支持过渡方向)
         *  @"oglFlip"                  上下左右翻转效果
         *  @"rotate"                   旋转效果
         *  @"cameraIrisHollowOpen"     相机镜头打开效果(不支持过渡方向)
         *  @"cameraIrisHollowClose"    相机镜头关上效果(不支持过渡方向)
         */
        transition.type = type
        
        /** subtype
         *
         *  各种动画方向
         *
         *  kCATransitionFromRight;      同字面意思(下同)
         *  kCATransitionFromLeft;
         *  kCATransitionFromTop;
         *  kCATransitionFromBottom;
         *
         *  当type为@"rotate"(旋转)的时候,它也有几个对应的subtype,分别为:
         *  90cw    逆时针旋转90°
         *  90ccw   顺时针旋转90°
         *  180cw   逆时针旋转180°
         *  180ccw  顺时针旋转180°
          *
         *  type与subtype的对应关系(必看),如果对应错误,动画不会显现.
         *  http://iphonedevwiki.net/index.php/CATransition
         */
        transition.subtype = subtype
        
        /** timingFunction
         *
         *  用于变化起点和终点之间的插值计算,形象点说它决定了动画运行的节奏,比如是均匀变化(相同时间变化量相同)还是
         *  先快后慢,先慢后快还是先慢再快再慢.
         *
         *  动画的开始与结束的快慢,有五个预置分别为(下同):
         *  kCAMediaTimingFunctionLinear            线性,即匀速
         *  kCAMediaTimingFunctionEaseIn            先慢后快
         *  kCAMediaTimingFunctionEaseOut           先快后慢
         *  kCAMediaTimingFunctionEaseInEaseOut     先慢后快再慢
         *  kCAMediaTimingFunctionDefault           实际效果是动画中间比较快.
          */
        transition.timingFunction = timingFunction
        
        // 动画持续时间，默认为0.25秒，传0即可
        transition.duration = duration
        
        // 设置完成事件
        if completion != nil {
            transition.fw_stopBlock = { _, finished in
                completion?(finished)
            }
        }
        
        // 所有核心动画和特效都是基于CAAnimation(作用于CALayer)
        self.layer.add(transition, forKey: "FWAnimation")
        return transition
    }

    /// 移除单个框架视图动画
    public func fw_removeAnimation() {
        self.layer.removeAnimation(forKey: "FWAnimation")
    }

    /// 移除所有视图动画
    public func fw_removeAllAnimations() {
        self.layer.removeAllAnimations()
    }

    /**
     *  绘制动画
     *
     *  @param layer      CAShapeLayer层
     *  @param duration   持续时间
     *  @param completion 完成回调
     *  @return CABasicAnimation
     */
    @discardableResult
    public func fw_stroke(
        layer: CAShapeLayer,
        duration: TimeInterval,
        completion: ((Bool) -> Void)? = nil
    ) -> CABasicAnimation {
        // strokeEnd动画，仅CAShapeLayer支持
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        animation.fromValue = NSNumber(value: 0)
        animation.toValue = NSNumber(value: 1)
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.autoreverses = false
        
        // 设置完成事件
        if completion != nil {
            animation.fw_stopBlock = { _, finished in
                completion?(finished)
            }
        }
        
        layer.add(animation, forKey: "FWAnimation")
        return animation
    }

    /**
     *  水平摇摆动画
     *
     *  @param times      摇摆次数，默认10
     *  @param delta      摇摆宽度，默认5
     *  @param duration   单次时间，默认0.03
     *  @param completion 完成回调
     */
    public func fw_shake(
        times: Int,
        delta: CGFloat,
        duration: TimeInterval,
        completion: ((Bool) -> Void)? = nil
    ) {
        fw_shake(
            times: times > 0 ? times : 10,
            delta: delta > 0 ? delta : 5,
            duration: duration > 0 ? duration : 0.03,
            direction: 1,
            currentTimes: 0,
            completion: completion
        )
    }
    
    private func fw_shake(
        times: Int,
        delta: CGFloat,
        duration: TimeInterval,
        direction: CGFloat,
        currentTimes: Int,
        completion: ((Bool) -> Void)? = nil
    ) {
        // 是否是文本输入框
        let isTextField = self is UITextField
        UIView.animate(withDuration: duration) {
            if isTextField {
                // 水平摇摆
                self.transform = CGAffineTransformMakeTranslation(delta * direction, 0)
                // 垂直摇摆
                // self.transform = CGAffineTransformMakeTranslation(0, delta * direction)
            } else {
                // 水平摇摆
                self.layer.setAffineTransform(CGAffineTransformMakeTranslation(delta * direction, 0))
                // 垂直摇摆
                // self.layer.setAffineTransform(CGAffineTransformMakeTranslation(0, delta * direction))
            }
        } completion: { finished in
            if currentTimes >= times {
                UIView.animate(withDuration: duration) {
                    if isTextField {
                        self.transform = .identity
                    } else {
                        self.layer.setAffineTransform(.identity)
                    }
                } completion: { finished in
                    completion?(finished)
                }
                return
            }
            self.fw_shake(
                times: times - 1,
                delta: delta,
                duration: duration,
                direction: direction * -1,
                currentTimes: currentTimes + 1,
                completion: completion
            )
        }
    }

    /**
     *  渐显隐动画
     *
     *  @param alpha      透明度
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func fw_fade(
        alpha: CGFloat,
        duration: TimeInterval,
        completion: ((Bool) -> Void)? = nil
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveLinear,
            animations: {
                self.alpha = alpha
            },
            completion: completion
        )
    }

    /**
     *  渐变代码块动画
     *
     *  @param block      动画代码块，比如调用imageView.setImage:方法
     *  @param duration   持续时长，建议0.5
     *  @param completion 完成回调
     */
    public func fw_fade(
        block: @escaping () -> Void,
        duration: TimeInterval,
        completion: ((Bool) -> Void)? = nil
    ) {
        UIView.transition(
            with: self,
            duration: duration,
            options: [.transitionCrossDissolve, .allowUserInteraction],
            animations: block,
            completion: completion
        )
    }

    /**
     *  旋转动画
     *
     *  @param degree     旋转度数，备注：逆时针需设置-179.99。使用CAAnimation无此问题
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func fw_rotate(
        degree: CGFloat,
        duration: TimeInterval,
        completion: ((Bool) -> Void)? = nil
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveLinear,
            animations: {
                self.transform = CGAffineTransformRotate(self.transform, degree * .pi / 180.0)
            },
            completion: completion
        )
    }

    /**
     *  缩放动画
     *
     *  @param scaleX     X轴缩放率
     *  @param scaleY     Y轴缩放率
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func fw_scale(
        scaleX: CGFloat,
        scaleY: CGFloat,
        duration: TimeInterval,
        completion: ((Bool) -> Void)? = nil
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveLinear,
            animations: {
                self.transform = CGAffineTransformScale(self.transform, scaleX, scaleY)
            },
            completion: completion
        )
    }

    /**
     *  移动动画
     *
     *  @param point      目标点
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func fw_move(
        point: CGPoint,
        duration: TimeInterval,
        completion: ((Bool) -> Void)? = nil
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveLinear,
            animations: {
                self.frame = CGRect(origin: point, size: self.frame.size)
            },
            completion: completion
        )
    }

    /**
     *  移动变化动画
     *
     *  @param frame      目标区域
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func fw_move(
        frame: CGRect,
        duration: TimeInterval,
        completion: ((Bool) -> Void)? = nil
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveLinear,
            animations: {
                self.frame = frame
            },
            completion: completion
        )
    }
    
    /**
     取消动画效果执行block
     
     @param block 动画代码块
     @param completion 完成事件
     */
    public static func fw_animateNone(
        block: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        UIView.animate(withDuration: 0, animations: block) { _ in
            completion?()
        }
    }

    /**
     执行block动画完成后执行指定回调
     
     @param block 动画代码块
     @param completion 完成事件
     */
    public static func fw_animate(
        block: () -> Void,
        completion: (() -> Void)? = nil
    ) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        block()
        CATransaction.commit()
    }
    
    // MARK: - Drag
    /// 是否启用拖动，默认NO
    public var fw_dragEnabled: Bool {
        get { return self.fw_dragGesture.isEnabled }
        set { self.fw_dragGesture.isEnabled = newValue }
    }

    /// 拖动手势，延迟加载
    public var fw_dragGesture: UIPanGestureRecognizer {
        if let gesture = fw.property(forName: "fw_dragGesture") as? UIPanGestureRecognizer {
            return gesture
        } else {
            // 初始化拖动手势，默认禁用
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(UIView.fw_dragHandler(_:)))
            gesture.maximumNumberOfTouches = 1
            gesture.minimumNumberOfTouches = 1
            gesture.cancelsTouchesInView = false
            gesture.isEnabled = false
            self.fw_dragArea = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            self.addGestureRecognizer(gesture)
            
            fw.setProperty(gesture, forName: "fw_dragGesture")
            return gesture
        }
    }

    /// 设置拖动限制区域，默认CGRectZero，无限制
    public var fw_dragLimit: CGRect {
        get {
            if let value = fw.property(forName: "fw_dragLimit") as? NSValue {
                return value.cgRectValue
            }
            return .zero
        }
        set {
            if newValue.equalTo(.zero) || newValue.contains(self.frame) {
                fw.setProperty(NSValue(cgRect: newValue), forName: "fw_dragLimit")
            }
        }
    }

    /// 设置拖动动作有效区域，默认self.frame
    public var fw_dragArea: CGRect {
        get {
            if let value = fw.property(forName: "fw_dragArea") as? NSValue {
                return value.cgRectValue
            }
            return .zero
        }
        set {
            let reletiveFrame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            if reletiveFrame.contains(newValue) {
                fw.setProperty(NSValue(cgRect: newValue), forName: "fw_dragArea")
            }
        }
    }

    /// 是否允许横向拖动(X)，默认true
    public var fw_dragHorizontal: Bool {
        get {
            if let number = fw.propertyNumber(forName: "fw_dragHorizontal") {
                return number.boolValue
            }
            return true
        }
        set {
            fw.setPropertyNumber(NSNumber(value: newValue), forName: "fw_dragHorizontal")
        }
    }

    /// 是否允许纵向拖动(Y)，默认true
    public var fw_dragVertical: Bool {
        get {
            if let number = fw.propertyNumber(forName: "fw_dragVertical") {
                return number.boolValue
            }
            return true
        }
        set {
            fw.setPropertyNumber(NSNumber(value: newValue), forName: "fw_dragVertical")
        }
    }

    /// 开始拖动回调
    public var fw_dragStartedBlock: ((UIView) -> Void)? {
        get { return fw.property(forName: "fw_dragStartedBlock") as? (UIView) -> Void }
        set { fw.setPropertyCopy(newValue, forName: "fw_dragStartedBlock") }
    }

    /// 拖动移动回调
    public var fw_dragMovedBlock: ((UIView) -> Void)? {
        get { return fw.property(forName: "fw_dragMovedBlock") as? (UIView) -> Void }
        set { fw.setPropertyCopy(newValue, forName: "fw_dragMovedBlock") }
    }

    /// 结束拖动回调
    public var fw_dragEndedBlock: ((UIView) -> Void)? {
        get { return fw.property(forName: "fw_dragEndedBlock") as? (UIView) -> Void }
        set { fw.setPropertyCopy(newValue, forName: "fw_dragEndedBlock") }
    }
    
    @objc private func fw_dragHandler(_ sender: UIPanGestureRecognizer) {
        // 检查是否能够在拖动区域拖动
        let locationInView = sender.location(in: self)
        if !self.fw_dragArea.contains(locationInView) &&
            sender.state == .began {
            return
        }
        
        if sender.state == .began {
            let locationInSuperview = sender.location(in: self.superview)
            self.layer.anchorPoint = CGPoint(x: locationInView.x / self.bounds.width, y: locationInView.y / self.bounds.height)
            self.center = locationInSuperview
        }
        
        if sender.state == .began && self.fw_dragStartedBlock != nil {
            self.fw_dragStartedBlock?(self)
        }
        
        if sender.state == .changed && self.fw_dragMovedBlock != nil {
            self.fw_dragMovedBlock?(self)
        }
        
        if sender.state == .ended && self.fw_dragEndedBlock != nil {
            self.fw_dragEndedBlock?(self)
        }
        
        let translation = sender.translation(in: self.superview)
        var newOriginX = CGRectGetMinX(self.frame) + (self.fw_dragHorizontal ? translation.x : 0)
        var newOriginY = CGRectGetMinY(self.frame) + (self.fw_dragVertical ? translation.y : 0)
        
        let cagingArea = self.fw_dragLimit
        let cagingAreaOriginX = CGRectGetMinX(cagingArea)
        let cagingAreaOriginY = CGRectGetMinY(cagingArea)
        let cagingAreaRightSide = cagingAreaOriginX + CGRectGetWidth(cagingArea)
        let cagingAreaBottomSide = cagingAreaOriginY + CGRectGetHeight(cagingArea)
        
        if !cagingArea.equalTo(.zero) {
            // 确保视图在限制区域内
            if newOriginX <= cagingAreaOriginX ||
                newOriginX + CGRectGetWidth(self.frame) >= cagingAreaRightSide {
                newOriginX = CGRectGetMinX(self.frame)
            }
            
            if newOriginY <= cagingAreaOriginY ||
                newOriginY + CGRectGetHeight(self.frame) >= cagingAreaBottomSide {
                newOriginY = CGRectGetMinY(self.frame)
            }
        }
        
        self.frame = CGRect(x: newOriginX, y: newOriginY, width: CGRectGetWidth(self.frame), height: CGRectGetHeight(self.frame))
        sender.setTranslation(.zero, in: self.superview)
    }
    
}

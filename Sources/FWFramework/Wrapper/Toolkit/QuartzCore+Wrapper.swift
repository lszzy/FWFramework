//
//  QuartzCore+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
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

// MARK: - CAAnimation+QuartzCore
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

// MARK: - CALayer+QuartzCore
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

// MARK: - CAGradientLayer+QuartzCore
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

// MARK: - UIView+QuartzCore
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
     
     @param block      动画代码块
     @param duration   持续时间
     @param completion 完成事件
     */
    public func addAnimation(block: @escaping () -> Void, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.fw_addAnimation(block: block, duration: duration, completion: completion)
    }

    /**
     添加UIView动画
     
     @param curve      动画速度
     @param transition 动画类型
     @param duration   持续时间，默认0.2
     @param completion 完成事件
     */
    public func addAnimation(curve: UIView.AnimationCurve, transition: UIView.AnimationTransition, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.fw_addAnimation(curve: curve, transition: transition, duration: duration, completion: completion)
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
     
     @param option     动画选项
     @param block      动画代码块
     @param duration   持续时间
     @param animationsEnabled 是否启用动画，默认true
     @param completion 完成事件
     */
    public func addTransition(option: UIView.AnimationOptions = [], block: @escaping () -> Void, duration: TimeInterval, animationsEnabled: Bool = true, completion: ((Bool) -> Void)? = nil) {
        base.fw_addTransition(option: option, block: block, duration: duration, animationsEnabled: animationsEnabled, completion: completion)
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

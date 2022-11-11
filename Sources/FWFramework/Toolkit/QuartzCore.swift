//
//  QuartzCore.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import QuartzCore
#if FWMacroSPM
import FWObjC
#endif

// MARK: - CADisplayLink+QuartzCore
/// 如果block参数不会被持有并后续执行，可声明为NS_NOESCAPE，不会触发循环引用
extension Wrapper where Base: CADisplayLink {
    
    /// 创建CADisplayLink，使用target-action，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameters:
    ///   - target: 目标
    ///   - selector: 方法
    /// - Returns: CADisplayLink
    public static func commonDisplayLink(target: Any, selector: Selector) -> CADisplayLink {
        let displayLink = CADisplayLink(target: target, selector: selector)
        displayLink.add(to: .current, forMode: .common)
        return displayLink
    }

    /// 创建CADisplayLink，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
    /// - Parameter block: 代码块
    /// - Returns: CADisplayLink
    public static func commonDisplayLink(block: @escaping (CADisplayLink) -> Void) -> CADisplayLink {
        let displayLink = displayLink(block: block)
        displayLink.add(to: .current, forMode: .common)
        return displayLink
    }

    /// 创建CADisplayLink，使用block，需要调用addToRunLoop:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
    ///
    /// 示例：[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes]
    /// - Parameter block: 代码块
    /// - Returns: CADisplayLink
    public static func displayLink(block: @escaping (CADisplayLink) -> Void) -> CADisplayLink {
        let displayLink = CADisplayLink(target: CADisplayLink.self, selector: #selector(CADisplayLink.__displayLinkAction(_:)))
        objc_setAssociatedObject(displayLink, &CADisplayLink.__displayLinkActionKey, block, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        return displayLink
    }
    
}

extension CADisplayLink {
    
    fileprivate static var __displayLinkActionKey = "displayLinkAction"
    
    @objc fileprivate class func __displayLinkAction(_ displayLink: CADisplayLink) {
        let block = objc_getAssociatedObject(displayLink, &CADisplayLink.__displayLinkActionKey) as? (CADisplayLink) -> Void
        block?(displayLink)
    }
    
}

// MARK: - CAAnimation+QuartzCore
extension Wrapper where Base: CAAnimation {
    
    /// 设置动画开始回调，需要在add之前添加，因为add时会自动拷贝一份对象
    public var startBlock: ((CAAnimation) -> Void)? {
        get { return base.__fw_startBlock }
        set { base.__fw_startBlock = newValue }
    }

    /// 设置动画停止回调
    public var stopBlock: ((CAAnimation, Bool) -> Void)? {
        get { return base.__fw_stopBlock }
        set { base.__fw_stopBlock = newValue }
    }
    
}

// MARK: - CALayer+QuartzCore
extension Wrapper where Base: CALayer {
    
    /// 设置主题背景色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeBackgroundColor: UIColor? {
        get {
            return property(forName: "themeBackgroundColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "themeBackgroundColor")
            base.backgroundColor = newValue?.cgColor
        }
    }

    /// 设置主题边框色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeBorderColor: UIColor? {
        get {
            return property(forName: "themeBorderColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "themeBorderColor")
            base.borderColor = newValue?.cgColor
        }
    }

    /// 设置主题阴影色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeShadowColor: UIColor? {
        get {
            return property(forName: "themeShadowColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "themeShadowColor")
            base.shadowColor = newValue?.cgColor
        }
    }

    /// 设置主题内容图片，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeContents: UIImage? {
        get {
            return property(forName: "themeContents") as? UIImage
        }
        set {
            setProperty(newValue, forName: "themeContents")
            base.contents = newValue?.fw.image?.cgImage
        }
    }
    
    /// 设置阴影颜色、偏移和半径
    public func setShadowColor(_ color: UIColor?, offset: CGSize, radius: CGFloat) {
        base.shadowColor = color?.cgColor
        base.shadowOffset = offset
        base.shadowRadius = radius
        base.shadowOpacity = 1.0
    }
    
    /// 生成图片截图，默认大小为frame.size
    public func snapshotImage(size: CGSize = .zero) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size.equalTo(.zero) ? base.frame.size : size, false, UIScreen.main.scale)
        if let context = UIGraphicsGetCurrentContext() {
            base.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
    
    fileprivate func notifyThemeChanged() {
        if let themeBackgroundColor = themeBackgroundColor {
            base.backgroundColor = themeBackgroundColor.cgColor
        }
        if let themeBorderColor = themeBorderColor {
            base.borderColor = themeBorderColor.cgColor
        }
        if let themeShadowColor = themeShadowColor {
            base.shadowColor = themeShadowColor.cgColor
        }
        if let themeContents = themeContents, themeContents.fw.isThemeImage {
            base.contents = themeContents.fw.image?.cgImage
        }
    }
    
}

extension CALayer {
    
    @objc open override func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)
        
        fw.notifyThemeChanged()
    }
    
}

// MARK: - CAGradientLayer+QuartzCore
extension Wrapper where Base: CAGradientLayer {
    
    /// 设置主题渐变色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeColors: [UIColor]? {
        get {
            return property(forName: "themeColors") as? [UIColor]
        }
        set {
            setProperty(newValue, forName: "themeColors")
            base.colors = newValue?.map({ $0.cgColor })
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
    public static func gradientLayer(
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
    
}

extension CAGradientLayer {
    
    @objc open override func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)
        
        if let themeColors = fw.themeColors {
            self.colors = themeColors.map({ $0.cgColor })
        }
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
        base.__fw_draw(bezierPath, strokeWidth: strokeWidth, stroke: strokeColor, fill: fillColor)
    }

    /**
     绘制渐变颜色，需要在drawRect中调用，支持四个方向，默认向下Down
     
     @param rect 绘制区域
     @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
     @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
     @param direction 渐变方向，自动计算startPoint和endPoint，支持四个方向，默认向下Down
     */
    public func drawLinearGradient(_ rect: CGRect, colors: [Any], locations: UnsafePointer<CGFloat>?, direction: UISwipeGestureRecognizer.Direction) {
        base.__fw_drawLinearGradient(rect, colors: colors, locations: locations, direction: direction)
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
        base.__fw_drawLinearGradient(rect, colors: colors, locations: locations, start: startPoint, end: endPoint)
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
        return base.__fw_addGradientLayer(frame, colors: colors, locations: locations, start: startPoint, end: endPoint)
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
        return base.__fw_addDashLayer(rect, lineLength: lineLength, lineSpacing: lineSpacing, lineColor: lineColor)
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
        base.__fw_addAnimation(block, duration: duration, completion: completion)
    }

    /**
     添加UIView动画
     
     @param curve      动画速度
     @param transition 动画类型
     @param duration   持续时间，默认0.2
     @param completion 完成事件
     */
    public func addAnimation(curve: UIView.AnimationCurve, transition: UIView.AnimationTransition, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.__fw_addAnimation(with: curve, transition: transition, duration: duration, completion: completion)
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
        return base.__fw_addAnimation(withKeyPath: keyPath, fromValue: fromValue, toValue: toValue, duration: duration, completion: completion)
    }

    /**
     添加转场动画，可指定animationsEnabled，一般用于window切换rootViewController
     
     @param option     动画选项
     @param block      动画代码块
     @param duration   持续时间
     @param animationsEnabled 是否启用动画
     @param completion 完成事件
     */
    public func addTransition(option: UIView.AnimationOptions = [], block: @escaping () -> Void, duration: TimeInterval, animationsEnabled: Bool, completion: ((Bool) -> Void)? = nil) {
        base.__fw_addTransition(option: option, block: block, duration: duration, animationsEnabled: animationsEnabled, completion: completion)
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
    public func addTransition(type: String, subtype: String?, timingFunction: String?, duration: CFTimeInterval, completion: ((Bool) -> Void)? = nil) -> CATransition {
        return base.__fw_addTransition(withType: type, subtype: subtype, timingFunction: timingFunction, duration: duration, completion: completion)
    }

    /// 移除单个框架视图动画
    public func removeAnimation() {
        base.__fw_removeAnimation()
    }

    /// 移除所有视图动画
    public func removeAllAnimations() {
        base.__fw_removeAllAnimations()
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
        return base.__fw_stroke(with: layer, duration: duration, completion: completion)
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
        base.__fw_shake(withTimes: times, delta: delta, duration: duration, completion: completion)
    }

    /**
     *  渐显隐动画
     *
     *  @param alpha      透明度
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func fade(alpha: Float, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.__fw_fade(withAlpha: alpha, duration: duration, completion: completion)
    }

    /**
     *  渐变代码块动画
     *
     *  @param block      动画代码块，比如调用imageView.setImage:方法
     *  @param duration   持续时长，建议0.5
     *  @param completion 完成回调
     */
    public func fade(block: @escaping () -> Void, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.__fw_fade(block, duration: duration, completion: completion)
    }

    /**
     *  旋转动画
     *
     *  @param degree     旋转度数，备注：逆时针需设置-179.99。使用CAAnimation无此问题
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func rotate(degree: CGFloat, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.__fw_rotate(withDegree: degree, duration: duration, completion: completion)
    }

    /**
     *  缩放动画
     *
     *  @param scaleX     X轴缩放率
     *  @param scaleY     Y轴缩放率
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func scale(scaleX: Float, scaleY: Float, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.__fw_scale(withScaleX: scaleX, scaleY: scaleY, duration: duration, completion: completion)
    }

    /**
     *  移动动画
     *
     *  @param point      目标点
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func move(point: CGPoint, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.__fw_move(with: point, duration: duration, completion: completion)
    }

    /**
     *  移动变化动画
     *
     *  @param frame      目标区域
     *  @param duration   持续时长
     *  @param completion 完成回调
     */
    public func move(frame: CGRect, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        base.__fw_move(withFrame: frame, duration: duration, completion: completion)
    }
    
    /**
     取消动画效果执行block
     
     @param block 动画代码块
     @param completion 完成事件
     */
    public static func animateNone(block: () -> Void, completion: (() -> Void)? = nil) {
        Base.__fw_animateNone(block, completion: completion)
    }

    /**
     执行block动画完成后执行指定回调
     
     @param block 动画代码块
     @param completion 完成事件
     */
    public static func animate(block: () -> Void, completion: (() -> Void)? = nil) {
        Base.__fw_animate(block, completion: completion)
    }
    
    // MARK: - Drag
    /// 是否启用拖动，默认NO
    public var dragEnabled: Bool {
        get { return base.__fw_dragEnabled }
        set { base.__fw_dragEnabled = newValue }
    }

    /// 拖动手势，延迟加载
    public var dragGesture: UIPanGestureRecognizer {
        return base.__fw_dragGesture
    }

    /// 设置拖动限制区域，默认CGRectZero，无限制
    public var dragLimit: CGRect {
        get { return base.__fw_dragLimit }
        set { base.__fw_dragLimit = newValue }
    }

    /// 设置拖动动作有效区域，默认self.frame
    public var dragArea: CGRect {
        get { return base.__fw_dragArea }
        set { base.__fw_dragArea = newValue }
    }

    /// 是否允许横向拖动(X)，默认YES
    public var dragHorizontal: Bool {
        get { return base.__fw_dragHorizontal }
        set { base.__fw_dragHorizontal = newValue }
    }

    /// 是否允许纵向拖动(Y)，默认YES
    public var dragVertical: Bool {
        get { return base.__fw_dragVertical }
        set { base.__fw_dragVertical = newValue }
    }

    /// 开始拖动回调
    public var dragStartedBlock: ((UIView) -> Void)? {
        get { return base.__fw_dragStartedBlock }
        set { base.__fw_dragStartedBlock = newValue }
    }

    /// 拖动移动回调
    public var dragMovedBlock: ((UIView) -> Void)? {
        get { return base.__fw_dragMovedBlock }
        set { base.__fw_dragMovedBlock = newValue }
    }

    /// 结束拖动回调
    public var dragEndedBlock: ((UIView) -> Void)? {
        get { return base.__fw_dragEndedBlock }
        set { base.__fw_dragEndedBlock = newValue }
    }
    
}

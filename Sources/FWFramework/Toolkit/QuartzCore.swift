//
//  QuartzCore.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import QuartzCore
import UIKit

// MARK: - Wrapper+CADisplayLink
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
    public static func commonDisplayLink(block: @escaping @Sendable (CADisplayLink) -> Void) -> CADisplayLink {
        let displayLink = displayLink(block: block)
        displayLink.add(to: .current, forMode: .common)
        return displayLink
    }

    /// 创建CADisplayLink，使用block，需要调用addToRunLoop:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
    ///
    /// 示例：[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes]
    /// - Parameter block: 代码块
    /// - Returns: CADisplayLink
    public static func displayLink(block: @escaping @Sendable (CADisplayLink) -> Void) -> CADisplayLink {
        let displayLink = CADisplayLink(target: CADisplayLink.self, selector: #selector(CADisplayLink.innerDisplayLinkAction(_:)))
        displayLink.fw.setPropertyCopy(block, forName: "displayLinkAction")
        return displayLink
    }
}

// MARK: - Wrapper+CAAnimation
extension Wrapper where Base: CAAnimation {
    /// 设置动画开始回调，需要在add之前添加，因为add时会自动拷贝一份对象
    public var startBlock: (@Sendable (CAAnimation) -> Void)? {
        get {
            let target = animationTarget(false)
            return target?.startBlock
        }
        set {
            let target = animationTarget(true)
            target?.startBlock = newValue
            base.delegate = target
        }
    }

    /// 设置动画停止回调
    public var stopBlock: (@Sendable (CAAnimation, Bool) -> Void)? {
        get {
            let target = animationTarget(false)
            return target?.stopBlock
        }
        set {
            let target = animationTarget(true)
            target?.stopBlock = newValue
            base.delegate = target
        }
    }

    private func animationTarget(_ lazyload: Bool) -> AnimationTarget? {
        var target = property(forName: "animationTarget") as? AnimationTarget
        if target == nil && lazyload {
            target = AnimationTarget()
            setProperty(target, forName: "animationTarget")
        }
        return target
    }
}

// MARK: - Wrapper+CALayer
extension Wrapper where Base: CALayer {
    /// 设置主题背景色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeBackgroundColor: UIColor? {
        get {
            property(forName: "themeBackgroundColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "themeBackgroundColor")
            base.backgroundColor = newValue?.cgColor
        }
    }

    /// 设置主题边框色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeBorderColor: UIColor? {
        get {
            property(forName: "themeBorderColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "themeBorderColor")
            base.borderColor = newValue?.cgColor
        }
    }

    /// 设置主题阴影色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeShadowColor: UIColor? {
        get {
            property(forName: "themeShadowColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "themeShadowColor")
            base.shadowColor = newValue?.cgColor
        }
    }

    /// 设置主题内容图片，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeContents: UIImage? {
        get {
            property(forName: "themeContents") as? UIImage
        }
        set {
            setProperty(newValue, forName: "themeContents")
            base.contents = newValue?.fw.image?.cgImage
        }
    }

    /// 设置阴影颜色、偏移和半径
    public func setShadowColor(
        _ color: UIColor?,
        offset: CGSize,
        radius: CGFloat
    ) {
        base.shadowColor = color?.cgColor
        base.shadowOffset = offset
        base.shadowRadius = radius
        base.shadowOpacity = 1.0
    }

    /// 移除所有支持动画属性的默认动画，需要一个不带动画的layer时使用
    public func removeDefaultAnimations() {
        var actions: [String: CAAction] = [
            NSStringFromSelector(#selector(getter: CALayer.bounds)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.position)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.zPosition)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.anchorPoint)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.anchorPointZ)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.transform)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.isHidden)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.isDoubleSided)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.sublayerTransform)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.masksToBounds)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.contents)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.contentsRect)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.contentsScale)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.contentsCenter)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.minificationFilterBias)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.backgroundColor)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.cornerRadius)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.borderWidth)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.borderColor)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.opacity)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.compositingFilter)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.filters)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.backgroundFilters)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.shouldRasterize)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.rasterizationScale)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.shadowColor)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.shadowOpacity)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.shadowOffset)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.shadowRadius)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.shadowPath)): NSNull(),
            NSStringFromSelector(#selector(getter: CALayer.maskedCorners)): NSNull()
        ]

        if base is CAShapeLayer {
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.path))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.fillColor))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.strokeColor))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.strokeStart))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.strokeEnd))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.lineWidth))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.miterLimit))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAShapeLayer.lineDashPhase))] = NSNull()
        }

        if base is CAGradientLayer {
            actions[NSStringFromSelector(#selector(getter: CAGradientLayer.colors))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAGradientLayer.locations))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAGradientLayer.startPoint))] = NSNull()
            actions[NSStringFromSelector(#selector(getter: CAGradientLayer.endPoint))] = NSNull()
        }

        base.actions = actions
    }

    /// 生成图片截图，默认大小为frame.size
    public func snapshotImage(size: CGSize = .zero) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size.equalTo(.zero) ? base.frame.size : size, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            base.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
}

// MARK: - Wrapper+CAGradientLayer
extension Wrapper where Base: CAGradientLayer {
    /// 设置主题渐变色，启用主题订阅后可跟随系统改变，清空时需置为nil
    public var themeColors: [UIColor]? {
        get {
            property(forName: "themeColors") as? [UIColor]
        }
        set {
            setProperty(newValue, forName: "themeColors")
            base.colors = newValue?.map(\.cgColor)
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

// MARK: - Wrapper+UIView
@MainActor extension Wrapper where Base: UIView {
    /**
     绘制形状路径，需要在drawRect中调用

     @param bezierPath 绘制路径
     @param strokeWidth 绘制宽度
     @param strokeColor 绘制颜色
     @param fillColor 填充颜色
     */
    public func drawBezierPath(
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

        if let fillColor {
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
    public func drawLinearGradient(
        _ rect: CGRect,
        colors: [Any],
        locations: UnsafePointer<CGFloat>?,
        direction: UISwipeGestureRecognizer.Direction
    ) {
        let linePoints = UIBezierPath.fw.linePoints(rect: rect, direction: direction)
        let startPoint = linePoints.first?.cgPointValue ?? .zero
        let endPoint = linePoints.last?.cgPointValue ?? .zero
        return drawLinearGradient(rect, colors: colors, locations: locations, startPoint: startPoint, endPoint: endPoint)
    }

    /**
     绘制渐变颜色，需要在drawRect中调用

     @param rect 绘制区域
     @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
     @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
     @param startPoint 渐变开始点，需要根据rect计算
     @param endPoint 渐变结束点，需要根据rect计算
     */
    public func drawLinearGradient(
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
    public func addGradientLayer(
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

        base.layer.addSublayer(gradientLayer)
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
    public func addDashLayer(
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
        base.layer.addSublayer(dashLayer)
        return dashLayer
    }

    // MARK: - Animation
    /**
     添加UIView动画，使用默认动画参数
     @note 如果动画过程中需要获取进度，可通过添加CADisplayLink访问layer.presentationLayer获取，下同

     @param block       动画代码块
     @param duration   持续时间
     @param options    动画选项，默认7<<16
     @param completion 完成事件
     */
    public func addAnimation(
        block: @escaping @MainActor @Sendable () -> Void,
        duration: TimeInterval,
        options: UIView.AnimationOptions? = nil,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        // 注意：AutoLayout动画需要调用父视图(如控制器view)的layoutIfNeeded更新布局才能生效
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options ?? .init(rawValue: 7 << 16),
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
    public func addAnimation(
        curve: UIView.AnimationOptions,
        transition: UIView.AnimationOptions,
        duration: TimeInterval,
        animations: (@MainActor @Sendable () -> Void)? = nil,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        UIView.transition(
            with: base,
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
    public func addAnimation(
        keyPath: String,
        fromValue: Any,
        toValue: Any,
        duration: CFTimeInterval,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
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
            animation.fw.stopBlock = { @Sendable _, finished in
                DispatchQueue.fw.mainAsync {
                    completion?(finished)
                }
            }
        }

        base.layer.add(animation, forKey: "FWAnimation")
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
    public func addTransition(
        options: UIView.AnimationOptions = [],
        block: @escaping @MainActor @Sendable () -> Void,
        duration: TimeInterval,
        animationsEnabled: Bool = true,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        UIView.transition(
            with: base,
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
     备注：移除动画可调用removeAnimation

     @param type           动画类型
     @param subtype        子类型
     @param timingFunction 动画速度
     @param duration       持续时间，0为默认(0.25秒)
     @param completion     完成事件
     @return CATransition
     */
    @discardableResult
    public func addTransition(
        type: CATransitionType,
        subtype: CATransitionSubtype?,
        timingFunction: CAMediaTimingFunction?,
        duration: CFTimeInterval,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
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
            transition.fw.stopBlock = { @Sendable _, finished in
                DispatchQueue.fw.mainAsync {
                    completion?(finished)
                }
            }
        }

        // 所有核心动画和特效都是基于CAAnimation(作用于CALayer)
        base.layer.add(transition, forKey: "FWAnimation")
        return transition
    }

    /// 移除单个框架视图动画，key默认FWAnimation
    public func removeAnimation(forKey key: String = "FWAnimation") {
        base.layer.removeAnimation(forKey: key)
    }

    /// 移除所有视图动画
    public func removeAllAnimations() {
        base.layer.removeAllAnimations()
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
    public func stroke(
        layer: CAShapeLayer,
        duration: TimeInterval,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
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
            animation.fw.stopBlock = { @Sendable _, finished in
                DispatchQueue.fw.mainAsync {
                    completion?(finished)
                }
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
    public func shake(
        times: Int,
        delta: CGFloat,
        duration: TimeInterval,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        shake(
            times: times > 0 ? times : 10,
            delta: delta > 0 ? delta : 5,
            duration: duration > 0 ? duration : 0.03,
            direction: 1,
            currentTimes: 0,
            completion: completion
        )
    }

    private func shake(
        times: Int,
        delta: CGFloat,
        duration: TimeInterval,
        direction: CGFloat,
        currentTimes: Int,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        // 是否是文本输入框
        let isTextField = base is UITextField
        UIView.animate(withDuration: duration) { [weak base] in
            if isTextField {
                // 水平摇摆
                base?.transform = CGAffineTransformMakeTranslation(delta * direction, 0)
                // 垂直摇摆
                // base?.transform = CGAffineTransformMakeTranslation(0, delta * direction)
            } else {
                // 水平摇摆
                base?.layer.setAffineTransform(CGAffineTransformMakeTranslation(delta * direction, 0))
                // 垂直摇摆
                // base?.layer.setAffineTransform(CGAffineTransformMakeTranslation(0, delta * direction))
            }
        } completion: { [weak base] finished in
            if currentTimes >= times {
                UIView.animate(withDuration: duration) {
                    if isTextField {
                        base?.transform = .identity
                    } else {
                        base?.layer.setAffineTransform(.identity)
                    }
                } completion: { finished in
                    completion?(finished)
                }
                return
            }

            base?.fw.shake(
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
    public func fade(
        alpha: CGFloat,
        duration: TimeInterval,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        let strongBase = base
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveLinear,
            animations: {
                strongBase.alpha = alpha
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
    public func fade(
        block: @escaping @MainActor @Sendable () -> Void,
        duration: TimeInterval,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        UIView.transition(
            with: base,
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
    public func rotate(
        degree: CGFloat,
        duration: TimeInterval,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        let strongBase = base
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveLinear,
            animations: {
                strongBase.transform = CGAffineTransformRotate(strongBase.transform, degree * .pi / 180.0)
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
    public func scale(
        scaleX: CGFloat,
        scaleY: CGFloat,
        duration: TimeInterval,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        let strongBase = base
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveLinear,
            animations: {
                strongBase.transform = CGAffineTransformScale(strongBase.transform, scaleX, scaleY)
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
    public func move(
        point: CGPoint,
        duration: TimeInterval,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        let strongBase = base
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveLinear,
            animations: {
                strongBase.frame = CGRect(origin: point, size: strongBase.frame.size)
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
    public func move(
        frame: CGRect,
        duration: TimeInterval,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        let strongBase = base
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveLinear,
            animations: {
                strongBase.frame = frame
            },
            completion: completion
        )
    }

    /**
     取消动画效果执行block

     @param block 动画代码块
     @param completion 完成事件
     */
    public static func animateNone(
        block: @escaping @MainActor @Sendable () -> Void,
        completion: (@MainActor @Sendable () -> Void)? = nil
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
    public static func animate(
        block: @MainActor @Sendable () -> Void,
        completion: (@MainActor @Sendable () -> Void)? = nil
    ) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        block()
        CATransaction.commit()
    }

    // MARK: - Drag
    /// 是否启用拖动，默认NO
    public var dragEnabled: Bool {
        get { dragGesture.isEnabled }
        set { dragGesture.isEnabled = newValue }
    }

    /// 拖动手势，延迟加载
    public var dragGesture: UIPanGestureRecognizer {
        if let gesture = property(forName: "dragGesture") as? UIPanGestureRecognizer {
            return gesture
        } else {
            // 初始化拖动手势，默认禁用
            let gesture = UIPanGestureRecognizer(target: base, action: #selector(UIView.innerDragHandler(_:)))
            gesture.maximumNumberOfTouches = 1
            gesture.minimumNumberOfTouches = 1
            gesture.cancelsTouchesInView = false
            gesture.isEnabled = false
            dragArea = CGRect(x: 0, y: 0, width: base.frame.width, height: base.frame.height)
            base.addGestureRecognizer(gesture)

            setProperty(gesture, forName: "dragGesture")
            return gesture
        }
    }

    /// 设置拖动限制区域，默认CGRectZero，无限制
    public var dragLimit: CGRect {
        get {
            if let value = property(forName: "dragLimit") as? NSValue {
                return value.cgRectValue
            }
            return .zero
        }
        set {
            if newValue.equalTo(.zero) || newValue.contains(base.frame) {
                setProperty(NSValue(cgRect: newValue), forName: "dragLimit")
            }
        }
    }

    /// 设置拖动动作有效区域，默认frame
    public var dragArea: CGRect {
        get {
            if let value = property(forName: "dragArea") as? NSValue {
                return value.cgRectValue
            }
            return .zero
        }
        set {
            let reletiveFrame = CGRect(x: 0, y: 0, width: base.frame.width, height: base.frame.height)
            if reletiveFrame.contains(newValue) {
                setProperty(NSValue(cgRect: newValue), forName: "dragArea")
            }
        }
    }

    /// 是否允许横向拖动(X)，默认YES
    public var dragHorizontal: Bool {
        get {
            if let number = propertyNumber(forName: "dragHorizontal") {
                return number.boolValue
            }
            return true
        }
        set {
            setPropertyNumber(NSNumber(value: newValue), forName: "dragHorizontal")
        }
    }

    /// 是否允许纵向拖动(Y)，默认YES
    public var dragVertical: Bool {
        get {
            if let number = propertyNumber(forName: "dragVertical") {
                return number.boolValue
            }
            return true
        }
        set {
            setPropertyNumber(NSNumber(value: newValue), forName: "dragVertical")
        }
    }

    /// 开始拖动回调
    public var dragStartedBlock: ((UIView) -> Void)? {
        get { property(forName: "dragStartedBlock") as? (UIView) -> Void }
        set { setPropertyCopy(newValue, forName: "dragStartedBlock") }
    }

    /// 拖动移动回调
    public var dragMovedBlock: ((UIView) -> Void)? {
        get { property(forName: "dragMovedBlock") as? (UIView) -> Void }
        set { setPropertyCopy(newValue, forName: "dragMovedBlock") }
    }

    /// 结束拖动回调
    public var dragEndedBlock: ((UIView) -> Void)? {
        get { property(forName: "dragEndedBlock") as? (UIView) -> Void }
        set { setPropertyCopy(newValue, forName: "dragEndedBlock") }
    }
}

// MARK: - CADisplayLink+QuartzCore
extension CADisplayLink {
    @objc fileprivate class func innerDisplayLinkAction(_ displayLink: CADisplayLink) {
        let block = displayLink.fw.property(forName: "displayLinkAction") as? @Sendable (CADisplayLink) -> Void
        block?(displayLink)
    }
}

// MARK: - CALayer+QuartzCore
extension CALayer {
    override open func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)

        if let themeBackgroundColor = fw.themeBackgroundColor {
            backgroundColor = themeBackgroundColor.cgColor
        }
        if let themeBorderColor = fw.themeBorderColor {
            borderColor = themeBorderColor.cgColor
        }
        if let themeShadowColor = fw.themeShadowColor {
            shadowColor = themeShadowColor.cgColor
        }
        if let themeContents = fw.themeContents, themeContents.fw.isThemeImage {
            contents = themeContents.fw.image?.cgImage
        }
    }
}

// MARK: - CAGradientLayer+QuartzCore
extension CAGradientLayer {
    override open func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)

        if let themeColors = fw.themeColors {
            colors = themeColors.map(\.cgColor)
        }
    }
}

// MARK: - UIView+QuartzCore
extension UIView {
    @objc fileprivate func innerDragHandler(_ sender: UIPanGestureRecognizer) {
        // 检查是否能够在拖动区域拖动
        let locationInView = sender.location(in: self)
        if !fw.dragArea.contains(locationInView) &&
            sender.state == .began {
            return
        }

        if sender.state == .began {
            let locationInSuperview = sender.location(in: superview)
            layer.anchorPoint = CGPoint(x: locationInView.x / bounds.width, y: locationInView.y / bounds.height)
            center = locationInSuperview
        }

        if sender.state == .began && fw.dragStartedBlock != nil {
            fw.dragStartedBlock?(self)
        }

        if sender.state == .changed && fw.dragMovedBlock != nil {
            fw.dragMovedBlock?(self)
        }

        if sender.state == .ended && fw.dragEndedBlock != nil {
            fw.dragEndedBlock?(self)
        }

        let translation = sender.translation(in: superview)
        var newOriginX = CGRectGetMinX(frame) + (fw.dragHorizontal ? translation.x : 0)
        var newOriginY = CGRectGetMinY(frame) + (fw.dragVertical ? translation.y : 0)

        let cagingArea = fw.dragLimit
        let cagingAreaOriginX = CGRectGetMinX(cagingArea)
        let cagingAreaOriginY = CGRectGetMinY(cagingArea)
        let cagingAreaRightSide = cagingAreaOriginX + CGRectGetWidth(cagingArea)
        let cagingAreaBottomSide = cagingAreaOriginY + CGRectGetHeight(cagingArea)

        if !cagingArea.equalTo(.zero) {
            // 确保视图在限制区域内
            if newOriginX <= cagingAreaOriginX ||
                newOriginX + CGRectGetWidth(frame) >= cagingAreaRightSide {
                newOriginX = CGRectGetMinX(frame)
            }

            if newOriginY <= cagingAreaOriginY ||
                newOriginY + CGRectGetHeight(frame) >= cagingAreaBottomSide {
                newOriginY = CGRectGetMinY(frame)
            }
        }

        frame = CGRect(x: newOriginX, y: newOriginY, width: CGRectGetWidth(frame), height: CGRectGetHeight(frame))
        sender.setTranslation(.zero, in: superview)
    }
}

// MARK: - AnimationTarget
private class AnimationTarget: NSObject, CAAnimationDelegate, @unchecked Sendable {
    var startBlock: (@Sendable (CAAnimation) -> Void)?
    var stopBlock: (@Sendable (CAAnimation, Bool) -> Void)?

    func animationDidStart(_ anim: CAAnimation) {
        startBlock?(anim)
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        stopBlock?(anim, flag)
    }
}

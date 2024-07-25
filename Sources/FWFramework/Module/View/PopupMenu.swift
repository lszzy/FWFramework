//
//  PopupMenu.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// 弹出菜单箭头方向
public enum PopupMenuArrowDirection: Int {
    case top = 0
    case bottom
    case left
    case right
    case none
}

/// 弹出菜单路径
public class PopupMenuPath {
    
    public static func maskLayer(
        rect: CGRect,
        rectCorner: UIRectCorner,
        cornerRadius: CGFloat,
        arrowWidth: CGFloat,
        arrowHeight: CGFloat,
        arrowPosition: CGFloat,
        arrowDirection: PopupMenuArrowDirection
    ) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = bezierPath(rect: rect, rectCorner: rectCorner, cornerRadius: cornerRadius, borderWidth: 0, borderColor: nil, backgroundColor: nil, arrowWidth: arrowWidth, arrowHeight: arrowHeight, arrowPosition: arrowPosition, arrowDirection: arrowDirection).cgPath
        return shapeLayer
    }

    public static func bezierPath(
        rect: CGRect,
        rectCorner: UIRectCorner,
        cornerRadius: CGFloat,
        borderWidth: CGFloat,
        borderColor: UIColor?,
        backgroundColor: UIColor?,
        arrowWidth: CGFloat,
        arrowHeight: CGFloat,
        arrowPosition: CGFloat,
        arrowDirection: PopupMenuArrowDirection
    ) -> UIBezierPath {
        let bezierPath = UIBezierPath()
        if let borderColor = borderColor {
            borderColor.setStroke()
        }
        if let backgroundColor = backgroundColor {
            backgroundColor.setFill()
        }
        bezierPath.lineWidth = borderWidth
        
        let rect = CGRect(x: borderWidth / 2, y: borderWidth / 2, width: rect.size.width - borderWidth, height: rect.size.height - borderWidth)
        var arrowPosition = arrowPosition
        var topRightRadius: CGFloat = 0
        var topLeftRadius: CGFloat = 0
        var bottomRightRadius: CGFloat = 0
        var bottomLeftRadius: CGFloat = 0
        var topRightArcCenter: CGPoint = .zero
        var topLeftArcCenter: CGPoint = .zero
        var bottomRightArcCenter: CGPoint = .zero
        var bottomLeftArcCenter: CGPoint = .zero

        if rectCorner.contains(.topLeft) {
            topLeftRadius = cornerRadius
        }
        if rectCorner.contains(.topRight) {
            topRightRadius = cornerRadius
        }
        if rectCorner.contains(.bottomLeft) {
            bottomLeftRadius = cornerRadius
        }
        if rectCorner.contains(.bottomRight) {
            bottomRightRadius = cornerRadius
        }
        
        if arrowDirection == .top {
            topLeftArcCenter = CGPoint(x: topLeftRadius + rect.origin.x, y: arrowHeight + topLeftRadius + rect.origin.x)
            topRightArcCenter = CGPoint(x: rect.size.width - topRightRadius + rect.origin.x, y: arrowHeight + topRightRadius + rect.origin.x)
            bottomLeftArcCenter = CGPoint(x: bottomLeftRadius + rect.origin.x, y: rect.size.height - bottomLeftRadius + rect.origin.x)
            bottomRightArcCenter = CGPoint(x: rect.size.width - bottomRightRadius + rect.origin.x, y: rect.size.height - bottomRightRadius + rect.origin.x)
            
            if arrowPosition < topLeftRadius + arrowWidth / 2 {
                arrowPosition = topLeftRadius + arrowWidth / 2
            } else if arrowPosition > rect.size.width - topRightRadius - arrowWidth / 2 {
                arrowPosition = rect.size.width - topRightRadius - arrowWidth / 2
            }
            
            bezierPath.move(to: CGPoint(x: arrowPosition - arrowWidth / 2, y: arrowHeight + rect.origin.x))
            bezierPath.addLine(to: CGPoint(x: arrowPosition, y: rect.origin.y + rect.origin.x))
            bezierPath.addLine(to: CGPoint(x: arrowPosition + arrowWidth / 2, y: arrowHeight + rect.origin.x))
            bezierPath.addLine(to: CGPoint(x: rect.size.width - topRightRadius, y: arrowHeight + rect.origin.x))
            bezierPath.addArc(withCenter: topRightArcCenter, radius: topRightRadius, startAngle: CGFloat.pi * 3 / 2, endAngle: 2 * CGFloat.pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: rect.size.width + rect.origin.x, y: rect.size.height - bottomRightRadius - rect.origin.x))
            bezierPath.addArc(withCenter: bottomRightArcCenter, radius: bottomRightRadius, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: bottomLeftRadius + rect.origin.x, y: rect.size.height + rect.origin.x))
            bezierPath.addArc(withCenter: bottomLeftArcCenter, radius: bottomLeftRadius, startAngle: CGFloat.pi / 2, endAngle: CGFloat.pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: rect.origin.x, y: arrowHeight + topLeftRadius + rect.origin.x))
            bezierPath.addArc(withCenter: topLeftArcCenter, radius: topLeftRadius, startAngle: CGFloat.pi, endAngle: CGFloat.pi * 3 / 2, clockwise: true)
        } else if arrowDirection == .bottom {
            topLeftArcCenter = CGPoint(x: topLeftRadius + rect.origin.x, y: topLeftRadius + rect.origin.x)
            topRightArcCenter = CGPoint(x: rect.size.width - topRightRadius + rect.origin.x, y: topRightRadius + rect.origin.x)
            bottomLeftArcCenter = CGPoint(x: bottomLeftRadius + rect.origin.x, y: rect.size.height - bottomLeftRadius + rect.origin.x - arrowHeight)
            bottomRightArcCenter = CGPoint(x: rect.size.width - bottomRightRadius + rect.origin.x, y: rect.size.height - bottomRightRadius + rect.origin.x - arrowHeight)
            
            if arrowPosition < bottomLeftRadius + arrowWidth / 2 {
                arrowPosition = bottomLeftRadius + arrowWidth / 2
            } else if arrowPosition > rect.size.width - bottomRightRadius - arrowWidth / 2 {
                arrowPosition = rect.size.width - bottomRightRadius - arrowWidth / 2
            }
            
            bezierPath.move(to: CGPoint(x: arrowPosition + arrowWidth / 2, y: rect.size.height - arrowHeight + rect.origin.x))
            bezierPath.addLine(to: CGPoint(x: arrowPosition, y: rect.size.height + rect.origin.x))
            bezierPath.addLine(to: CGPoint(x: arrowPosition - arrowWidth / 2, y: rect.size.height - arrowHeight + rect.origin.x))
            bezierPath.addLine(to: CGPoint(x: bottomLeftRadius + rect.origin.x, y: rect.size.height - arrowHeight + rect.origin.x))
            bezierPath.addArc(withCenter: bottomLeftArcCenter, radius: bottomLeftRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: rect.origin.x, y: topLeftRadius + rect.origin.x))
            bezierPath.addArc(withCenter: topLeftArcCenter, radius: topLeftRadius, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: rect.size.width - topRightRadius + rect.origin.x, y: rect.origin.x))
            bezierPath.addArc(withCenter: topRightArcCenter, radius: topRightRadius, startAngle: .pi * 3 / 2, endAngle: 2 * .pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: rect.size.width + rect.origin.x, y: rect.size.height - bottomRightRadius - rect.origin.x - arrowHeight))
            bezierPath.addArc(withCenter: bottomRightArcCenter, radius: bottomRightRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        } else if arrowDirection == .left {
            topLeftArcCenter = CGPoint(x: topLeftRadius + rect.origin.x + arrowHeight, y: topLeftRadius + rect.origin.x)
            topRightArcCenter = CGPoint(x: rect.size.width - topRightRadius + rect.origin.x, y: topRightRadius + rect.origin.x)
            bottomLeftArcCenter = CGPoint(x: bottomLeftRadius + rect.origin.x + arrowHeight, y: rect.size.height - bottomLeftRadius + rect.origin.x)
            bottomRightArcCenter = CGPoint(x: rect.size.width - bottomRightRadius + rect.origin.x, y: rect.size.height - bottomRightRadius + rect.origin.x)
            
            if arrowPosition < topLeftRadius + arrowWidth / 2 {
                arrowPosition = topLeftRadius + arrowWidth / 2
            } else if arrowPosition > rect.size.height - bottomLeftRadius - arrowWidth / 2 {
                arrowPosition = rect.size.height - bottomLeftRadius - arrowWidth / 2
            }
            
            bezierPath.move(to: CGPoint(x: arrowHeight + rect.origin.x, y: arrowPosition + arrowWidth / 2))
            bezierPath.addLine(to: CGPoint(x: rect.origin.x, y: arrowPosition))
            bezierPath.addLine(to: CGPoint(x: arrowHeight + rect.origin.x, y: arrowPosition - arrowWidth / 2))
            bezierPath.addLine(to: CGPoint(x: arrowHeight + rect.origin.x, y: topLeftRadius + rect.origin.x))
            bezierPath.addArc(withCenter: topLeftArcCenter, radius: topLeftRadius, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: rect.size.width - topRightRadius, y: rect.origin.x))
            bezierPath.addArc(withCenter: topRightArcCenter, radius: topRightRadius, startAngle: .pi * 3 / 2, endAngle: 2 * .pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: rect.size.width + rect.origin.x, y: rect.size.height - bottomRightRadius - rect.origin.x))
            bezierPath.addArc(withCenter: bottomRightArcCenter, radius: bottomRightRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: arrowHeight + bottomLeftRadius + rect.origin.x, y: rect.size.height + rect.origin.x))
            bezierPath.addArc(withCenter: bottomLeftArcCenter, radius: bottomLeftRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        } else if arrowDirection == .right {
            topLeftArcCenter = CGPoint(x: topLeftRadius + rect.origin.x, y: topLeftRadius + rect.origin.x)
            topRightArcCenter = CGPoint(x: rect.size.width - topRightRadius + rect.origin.x - arrowHeight, y: topRightRadius + rect.origin.x)
            bottomLeftArcCenter = CGPoint(x: bottomLeftRadius + rect.origin.x, y: rect.size.height - bottomLeftRadius + rect.origin.x)
            bottomRightArcCenter = CGPoint(x: rect.size.width - bottomRightRadius + rect.origin.x - arrowHeight, y: rect.size.height - bottomRightRadius + rect.origin.x)
            
            if arrowPosition < topRightRadius + arrowWidth / 2 {
                arrowPosition = topRightRadius + arrowWidth / 2
            } else if arrowPosition > rect.size.height - bottomRightRadius - arrowWidth / 2 {
                arrowPosition = rect.size.height - bottomRightRadius - arrowWidth / 2
            }
            
            bezierPath.move(to: CGPoint(x: rect.size.width - arrowHeight + rect.origin.x, y: arrowPosition - arrowWidth / 2))
            bezierPath.addLine(to: CGPoint(x: rect.size.width + rect.origin.x, y: arrowPosition))
            bezierPath.addLine(to: CGPoint(x: rect.size.width - arrowHeight + rect.origin.x, y: arrowPosition + arrowWidth / 2))
            bezierPath.addLine(to: CGPoint(x: rect.size.width - arrowHeight + rect.origin.x, y: rect.size.height - bottomRightRadius - rect.origin.x))
            bezierPath.addArc(withCenter: bottomRightArcCenter, radius: bottomRightRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: bottomLeftRadius + rect.origin.x, y: rect.size.height + rect.origin.x))
            bezierPath.addArc(withCenter: bottomLeftArcCenter, radius: bottomLeftRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: rect.origin.x, y: arrowHeight + topLeftRadius + rect.origin.x))
            bezierPath.addArc(withCenter: topLeftArcCenter, radius: topLeftRadius, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: rect.size.width - topRightRadius + rect.origin.x - arrowHeight, y: rect.origin.x))
            bezierPath.addArc(withCenter: topRightArcCenter, radius: topRightRadius, startAngle: .pi * 3 / 2, endAngle: 2 * .pi, clockwise: true)
        } else if arrowDirection == .none {
            topLeftArcCenter = CGPoint(x: topLeftRadius + rect.origin.x, y: topLeftRadius + rect.origin.x)
            topRightArcCenter = CGPoint(x: rect.size.width - topRightRadius + rect.origin.x, y: topRightRadius + rect.origin.x)
            bottomLeftArcCenter = CGPoint(x: bottomLeftRadius + rect.origin.x, y: rect.size.height - bottomLeftRadius + rect.origin.x)
            bottomRightArcCenter = CGPoint(x: rect.size.width - bottomRightRadius + rect.origin.x, y: rect.size.height - bottomRightRadius + rect.origin.x)
            bezierPath.move(to: CGPoint(x: topLeftRadius + rect.origin.x, y: rect.origin.y))
            bezierPath.addLine(to: CGPoint(x: rect.size.width - topRightRadius, y: rect.origin.y))
            bezierPath.addArc(withCenter: topRightArcCenter, radius: topRightRadius, startAngle: .pi * 3 / 2, endAngle: 2 * .pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: rect.size.width + rect.origin.x, y: rect.size.height - bottomRightRadius - rect.origin.y))
            bezierPath.addArc(withCenter: bottomRightArcCenter, radius: bottomRightRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: bottomLeftRadius + rect.origin.x, y: rect.size.height + rect.origin.y))
            bezierPath.addArc(withCenter: bottomLeftArcCenter, radius: bottomLeftRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: rect.origin.x, y: arrowHeight + topLeftRadius + rect.origin.y))
            bezierPath.addArc(withCenter: topLeftArcCenter, radius: topLeftRadius, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: true)
        }
        
        bezierPath.close()
        return bezierPath
    }
    
}

/// 屏幕转向管理器
@MainActor open class PopupMenuDeviceOrientationManager: NSObject {
    
    /// 根据屏幕旋转方向自动旋转 Default is YES
    open var autoRotateWhenDeviceOrientationChanged: Bool = true
    
    open var deviceOrientationDidChangeHandler: ((UIInterfaceOrientation) -> Void)?
    
    private var isGeneratingDeviceOrientationNotifications = false
    
    /// 开始监听
    open func startMonitorDeviceOrientation() {
        guard autoRotateWhenDeviceOrientationChanged else { return }
        isGeneratingDeviceOrientationNotifications = UIDevice.current.isGeneratingDeviceOrientationNotifications
        if !isGeneratingDeviceOrientationNotifications {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    /// 停止监听
    open func stopMonitorDeviceOrientation() {
        guard autoRotateWhenDeviceOrientationChanged else { return }
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        if !isGeneratingDeviceOrientationNotifications {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
    }
    
    @objc func deviceOrientationDidChange(_ notify: Notification) {
        guard autoRotateWhenDeviceOrientationChanged else { return }
        let orientation = UIWindow.fw.mainScene?.interfaceOrientation
        if let orientation = orientation, orientation != .unknown {
            DispatchQueue.main.async { [weak self] in
                self?.deviceOrientationDidChangeHandler?(orientation)
            }
        }
    }
    
}

/// 弹出菜单动画样式
public enum PopupMenuAnimationStyle: Int {
    case scale = 0
    case fade
    case none
    case custom
}

/// 弹出菜单动画管理器
@MainActor open class PopupMenuAnimationManager: NSObject {
    
    /// 动画类型，默认style
    open var style: PopupMenuAnimationStyle = .scale {
        didSet { configAnimation() }
    }
    
    /// 显示动画，自定义可用
    open var showAnimation: CAAnimation? {
        get {
            return _showAnimation
        }
        set {
            _showAnimation = newValue
            configAnimation()
        }
    }
    private var _showAnimation: CAAnimation?
    
    /// 隐藏动画，自定义可用
    open var dismissAnimation: CAAnimation? {
        get {
            return _dismissAnimation
        }
        set {
            _dismissAnimation = newValue
            configAnimation()
        }
    }
    private var _dismissAnimation: CAAnimation?
    
    /// 动画时间，默认0.25
    open var duration: CFTimeInterval = 0.25 {
        didSet { configAnimation() }
    }
    
    /// 动画视图
    open weak var animationView: UIView?
    
    private var showAnimationHandler: (() -> Void)?
    private var dismissAnimationHandler: (() -> Void)?
    private let showAnimationKey = "showAnimation"
    private let dismissAnimationKey = "dismissAnimation"
    
    open func displayShowAnimationCompletion(_ completion: (() -> Void)? = nil) {
        showAnimationHandler = completion
        guard let showAnimation = showAnimation else {
            showAnimationHandler?()
            return
        }
        
        showAnimation.delegate = self
        animationView?.layer.add(showAnimation, forKey: showAnimationKey)
    }
    
    open func displayDismissAnimationCompletion(_ completion: (() -> Void)? = nil) {
        dismissAnimationHandler = completion
        guard let dismissAnimation = dismissAnimation else {
            dismissAnimationHandler?()
            return
        }
        
        dismissAnimation.delegate = self
        animationView?.layer.add(dismissAnimation, forKey: dismissAnimationKey)
    }
    
    open func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if animationView?.layer.animation(forKey: showAnimationKey) == anim {
            animationView?.layer.removeAnimation(forKey: showAnimationKey)
            _showAnimation?.delegate = nil
            _showAnimation = nil
            showAnimationHandler?()
        } else if animationView?.layer.animation(forKey: dismissAnimationKey) == anim {
            animationView?.layer.removeAnimation(forKey: dismissAnimationKey)
            _dismissAnimation?.delegate = nil
            _dismissAnimation = nil
            dismissAnimationHandler?()
        }
    }
    
    private func configAnimation() {
        switch style {
        case .fade:
            let showAnimation = getBasicAnimation(keyPath: "opacity")
            showAnimation.fillMode = .backwards
            showAnimation.fromValue = NSNumber(value: 0)
            showAnimation.toValue = NSNumber(value: 1)
            _showAnimation = showAnimation
            
            let dismissAnimation = getBasicAnimation(keyPath: "opacity")
            dismissAnimation.fillMode = .forwards
            dismissAnimation.fromValue = NSNumber(value: 1)
            dismissAnimation.toValue = NSNumber(value: 0)
            _dismissAnimation = dismissAnimation
        case .none:
            _showAnimation = nil
            _dismissAnimation = nil
        case .custom:
            break
        default:
            let showAnimation = getBasicAnimation(keyPath: "transform.scale")
            showAnimation.fillMode = .backwards
            showAnimation.fromValue = NSNumber(value: 0.1)
            showAnimation.toValue = NSNumber(value: 1)
            _showAnimation = showAnimation
            
            let dismissAnimation = getBasicAnimation(keyPath: "transform.scale")
            dismissAnimation.fillMode = .forwards
            dismissAnimation.fromValue = NSNumber(value: 1)
            dismissAnimation.toValue = NSNumber(value: 0.1)
            _dismissAnimation = dismissAnimation
        }
    }
    
    private func getBasicAnimation(keyPath: String) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.isRemovedOnCompletion = false
        animation.duration = duration
        return animation
    }
    
}

#if compiler(>=6.0)
extension PopupMenuAnimationManager: @preconcurrency CAAnimationDelegate {}
#else
extension PopupMenuAnimationManager: CAAnimationDelegate {}
#endif

/// 箭头方向优先级，当控件超出屏幕时会自动调整成反方向
public enum PopupMenuPriorityDirection: Int {
    case top = 0
    case bottom
    case left
    case right
    case none
}

/// 弹出菜单事件代理
@objc public protocol PopupMenuDelegate {
    @objc optional func popupMenuBeganDismiss(_ popupMenu: PopupMenu)
    @objc optional func popupMenuDidDismiss(_ popupMenu: PopupMenu)
    @objc optional func popupMenuBeganShow(_ popupMenu: PopupMenu)
    @objc optional func popupMenuDidShow(_ popupMenu: PopupMenu)
    
    /// 点击事件回调
    @objc optional func popupMenu(_ popupMenu: PopupMenu, didSelectAt index: Int)
    /// 自定义cell，高度为itemheight，建议cell背景色为透明，否则切的圆角显示不出来
    @objc optional func popupMenu(_ popupMenu: PopupMenu, cellForRowAt index: Int) -> UITableViewCell?
}

/// 弹出菜单
///
/// [YBPopupMenu](https://github.com/lyb5834/YBPopupMenu)
open class PopupMenu: UIView, UITableViewDataSource, UITableViewDelegate {
    
    /// 标题数组，支持String|NSAttributedString，需show之前调用
    open var titles: [Any] = []
    
    /// 图片数组，支持String|UIImage，需show之前调用
    open var images: [Any] = []
    
    /// 圆角半径
    open var cornerRadius: CGFloat = 5.0
    
    /// 自定义圆角，当自动调整方向时corner会自动转换至镜像方向
    open var rectCorner: UIRectCorner = .allCorners
    
    /// 是否显示阴影，默认true
    open var showsShadow = true {
        didSet {
            layer.shadowOpacity = showsShadow ? 0.5 : 0
            layer.shadowOffset = .zero
            layer.shadowRadius = showsShadow ? 2.0 : 0
        }
    }
    
    /// 是否显示灰色蒙层，默认true
    open var showsMaskView = true {
        didSet {
            menuMaskView.isHidden = !showsMaskView
        }
    }
    
    /// 自定义灰色蒙层颜色，默认黑色、透明度0.1，可设置为透明等
    open var maskViewColor: UIColor? = UIColor.black.withAlphaComponent(0.1) {
        didSet {
            menuMaskView.backgroundColor = maskViewColor
        }
    }
    
    /// 选择菜单项后消失，默认true
    open var dismissOnSelected = true
    
    /// 点击菜单外消失，默认true
    open var dismissOnTouchOutside = true
    
    /// 自定义字体，默认15号普通
    open var font: UIFont? = UIFont.systemFont(ofSize: 15)
    
    /// 自定义颜色，默认黑色
    open var textColor: UIColor? = .black
    
    /// 设置偏移距离
    open var offset: CGFloat = 0
    
    /// 设置边框宽度
    open var borderWidth: CGFloat = 0
    
    /// 设置边框颜色
    open var borderColor: UIColor? = .lightGray
    
    /// 箭头宽度
    open var arrowWidth: CGFloat = 15
    
    /// 箭头高度
    open var arrowHeight: CGFloat = 10
    
    /// 箭头位置，默认居中，只有箭头优先级为left|right|none时需要设置
    open var arrowPosition: CGFloat = 0
    
    /// 箭头方向
    open var arrowDirection: PopupMenuArrowDirection = .top
    
    /// 箭头优先方向，默认top，当控件超出屏幕时会自动调整箭头位置
    open var priorityDirection: PopupMenuPriorityDirection = .top
    
    /// 可见的最大行数
    open var maxVisibleCount: Int = 5
    
    /// menu背景色
    open var menuBackgroundColor: UIColor? = .white
    
    /// item高度，默认44
    open var itemHeight: CGFloat = 44
    
    /// 距离最近的屏幕的距离，默认10
    open var minSpace: CGFloat = 10
    
    /// 是否显示分割线，默认true
    open var showsSeparator = true
    
    /// 自定义分割线高度，默认0.5
    open var separatorHeight: CGFloat = 0.5
    
    /// 自定义分割线颜色
    open var separatorColor: UIColor? = .lightGray
    
    /// 自定义分割线偏移，默认zero
    open var separatorInsets: UIEdgeInsets = .zero
    
    /// 自定义imageView的位置偏移，默认zero不生效
    open var imageEdgeInsets: UIEdgeInsets = .zero
    
    /// 自定义textLabel的位置偏移，默认zero不生效
    open var titleEdgeInsets: UIEdgeInsets = .zero
    
    /// 点击事件回调句柄
    open var didSelectItemBlock: ((Int) -> Void)?
    
    /// 自定义cell句柄，优先级低于delegate
    open var customCellBlock: ((PopupMenu, Int) -> UITableViewCell?)?
    
    /// 屏幕旋转管理
    open var orientationManager: PopupMenuDeviceOrientationManager = .init()
    
    /// 动画管理
    open var animationManager: PopupMenuAnimationManager = .init()
    
    /// 事件代理
    open weak var delegate: PopupMenuDelegate?
    
    /// 表格视图
    open lazy var tableView: UITableView = {
        let result = UITableView(frame: .zero, style: .plain)
        result.backgroundColor = UIColor.clear
        result.tableFooterView = UIView()
        result.delegate = self
        result.dataSource = self
        result.separatorStyle = .none
        if #available(iOS 15.0, *) {
            result.sectionHeaderTopPadding = 0
        }
        return result
    }()
    
    /// 灰色蒙层
    open lazy var menuMaskView: UIView = {
        let result = UIView(frame: .zero)
        result.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        result.alpha = 1
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(touchOutSide))
        result.addGestureRecognizer(tapGesture)
        return result
    }()
    
    /// 自定义容器视图，需show之前调用
    open weak var containerView: UIView? {
        get {
            return _containerView ?? UIWindow.fw.main
        }
        set {
            _containerView = newValue
        }
    }
    private weak var _containerView: UIView?
    
    /// 获取容器bounds
    open var containerBounds: CGRect {
        return containerView?.bounds ?? UIScreen.main.bounds
    }
    
    /// 自定义依赖视图，优先级高于point，需show之前调用
    open weak var relyView: UIView?
    
    /// 自定义弹出位置，优先级低于relyView，需show之前调用
    open var point: CGPoint = .zero
    
    /// 自定义菜单宽度，需show之前调用
    private var itemWidth: CGFloat = 0
    
    private var relyRect: CGRect = .zero
    private var isCornerChanged = false
    private var isChangeDirection = false
    
    /// 在指定位置弹出，可指定容器视图
    @discardableResult
    open class func show(in containerView: UIView? = nil, at point: CGPoint, titles: [Any]?, icons: [Any]? = nil, menuWidth: CGFloat, customize: ((PopupMenu) -> Void)? = nil) -> PopupMenu {
        let popupMenu = PopupMenu()
        popupMenu.containerView = containerView
        popupMenu.point = point
        popupMenu.titles = titles ?? []
        popupMenu.images = icons ?? []
        popupMenu.itemWidth = menuWidth
        customize?(popupMenu)
        popupMenu.show()
        return popupMenu
    }
    
    /// 依赖指定view弹出，可指定容器视图
    @discardableResult
    open class func show(in containerView: UIView? = nil, relyOn view: UIView?, titles: [Any]?, icons: [Any]? = nil, menuWidth: CGFloat, customize: ((PopupMenu) -> Void)? = nil) -> PopupMenu {
        let popupMenu = PopupMenu()
        popupMenu.containerView = containerView
        popupMenu.relyView = view
        popupMenu.titles = titles ?? []
        popupMenu.images = icons ?? []
        popupMenu.itemWidth = menuWidth
        customize?(popupMenu)
        popupMenu.show()
        return popupMenu
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        animationManager.animationView = self
        
        layer.shadowOpacity = 0.5
        layer.shadowOffset = .zero
        layer.shadowRadius = 2.0
        alpha = 1
        backgroundColor = .clear
        addSubview(tableView)
        
        orientationManager.deviceOrientationDidChangeHandler = { [weak self] orientation in
            if orientation == .portrait || orientation == .landscapeLeft || orientation == .landscapeRight {
                if self?.relyView != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self?.calculateRealPointIfNeed()
                        self?.updateUI()
                    }
                } else {
                    self?.updateUI()
                }
            }
        }
    }
    
    /// 显示
    open func show() {
        orientationManager.startMonitorDeviceOrientation()
        if relyView != nil {
            calculateRealPointIfNeed()
        }
        updateUI()
        containerView?.addSubview(menuMaskView)
        containerView?.addSubview(self)
        delegate?.popupMenuBeganShow?(self)
        animationManager.displayShowAnimationCompletion { [weak self] in
            guard let self = self else { return }
            self.delegate?.popupMenuDidShow?(self)
        }
    }
    
    /// 隐藏
    open func dismiss() {
        orientationManager.stopMonitorDeviceOrientation()
        delegate?.popupMenuBeganDismiss?(self)
        animationManager.displayDismissAnimationCompletion { [weak self] in
            guard let self = self else { return }
            self.delegate?.popupMenuDidDismiss?(self)
            self.delegate = nil
            self.removeFromSuperview()
            self.menuMaskView.removeFromSuperview()
        }
    }
    
    // MARK: - UITableView
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = delegate?.popupMenu?(self, cellForRowAt: indexPath.row) {
            return cell
        } else if let cell = customCellBlock?(self, indexPath.row) {
            return cell
        }
        
        let cell: PopupMenuCell
        let cellIdentifier = "PopupMenu"
        if let reuseCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? PopupMenuCell {
            cell = reuseCell
        } else {
            cell = PopupMenuCell(style: .default, reuseIdentifier: cellIdentifier)
            cell.textLabel?.numberOfLines = 0
        }
        
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = textColor
        cell.textLabel?.font = font
        if let attributedTitle = titles[indexPath.row] as? NSAttributedString {
            cell.textLabel?.attributedText = attributedTitle
        } else {
            cell.textLabel?.text = titles[indexPath.row] as? String
        }
        
        if images.count >= indexPath.row + 1 {
            if let imageName = images[indexPath.row] as? String {
                cell.imageView?.image = UIImage(named: imageName)
            } else {
                cell.imageView?.image = images[indexPath.row] as? UIImage
            }
        } else {
            cell.imageView?.image = nil
        }
        
        cell.customSeparatorColor = separatorColor
        cell.customSeparatorInsets = separatorInsets
        cell.customSeparatorHeight = separatorHeight
        cell.showsCustomSeparator = indexPath.row < (titles.count - 1) ? showsSeparator : false
        cell.imageEdgeInsets = imageEdgeInsets
        cell.textEdgeInsets = titleEdgeInsets
        return cell
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return itemHeight
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if dismissOnSelected {
            dismiss()
        }
        
        delegate?.popupMenu?(self, didSelectAt: indexPath.row)
        didSelectItemBlock?(indexPath.row)
    }
    
    // MARK: - Private
    open override var frame: CGRect {
        didSet {
            if arrowDirection == .top {
                tableView.frame = CGRect(x: borderWidth, y: borderWidth + arrowHeight, width: frame.size.width - borderWidth * 2, height: frame.size.height - arrowHeight)
            } else if arrowDirection == .bottom {
                tableView.frame = CGRect(x: borderWidth, y: borderWidth, width: frame.size.width - borderWidth * 2, height: frame.size.height - arrowHeight)
            } else if arrowDirection == .left {
                tableView.frame = CGRect(x: borderWidth + arrowHeight, y: borderWidth, width: frame.size.width - borderWidth * 2 - arrowHeight, height: frame.size.height)
            } else if arrowDirection == .right {
                tableView.frame = CGRect(x: borderWidth, y: borderWidth, width: frame.size.width - borderWidth * 2 - arrowHeight, height: frame.size.height)
            }
        }
    }
    
    open override func draw(_ rect: CGRect) {
        let bezierPath = PopupMenuPath.bezierPath(rect: rect, rectCorner: rectCorner, cornerRadius: cornerRadius, borderWidth: borderWidth, borderColor: borderColor, backgroundColor: menuBackgroundColor, arrowWidth: arrowWidth, arrowHeight: arrowHeight, arrowPosition: arrowPosition, arrowDirection: arrowDirection)
        bezierPath.fill()
        bezierPath.stroke()
    }
    
    @objc private func touchOutSide() {
        if dismissOnTouchOutside {
            dismiss()
        }
    }
    
    private func calculateRealPointIfNeed() {
        let absoluteRect = relyView?.convert(relyView?.bounds ?? .zero, to: containerView) ?? .zero
        let relyPoint = CGPoint(x: absoluteRect.origin.x + absoluteRect.size.width / 2, y: absoluteRect.origin.y + absoluteRect.size.height)
        self.relyRect = absoluteRect
        self.point = relyPoint
    }
    
    private func updateUI() {
        let containerSize = containerBounds.size
        menuMaskView.frame = CGRect(x: 0, y: 0, width: containerSize.width, height: containerSize.height)
        var height: CGFloat = 0
        if titles.count > maxVisibleCount {
            height = itemHeight * CGFloat(maxVisibleCount) + borderWidth * 2
            tableView.bounces = true
        } else {
            height = itemHeight * CGFloat(titles.count) + borderWidth * 2
            tableView.bounces = false
        }
        isChangeDirection = false
        if priorityDirection == .top {
            if point.y + height + arrowHeight > containerSize.height - minSpace {
                arrowDirection = .bottom
                isChangeDirection = true
            } else {
                arrowDirection = .top
                isChangeDirection = false
            }
        } else if priorityDirection == .bottom {
            if point.y - height - arrowHeight < minSpace {
                arrowDirection = .top
                isChangeDirection = true
            } else {
                arrowDirection = .bottom
                isChangeDirection = false
            }
        } else if priorityDirection == .left {
            if point.x + itemWidth + arrowHeight > containerSize.width - minSpace {
                arrowDirection = .right
                isChangeDirection = true
            } else {
                arrowDirection = .left
                isChangeDirection = false
            }
        } else if priorityDirection == .right {
            if point.x - itemWidth - arrowHeight < minSpace {
                arrowDirection = .left
                isChangeDirection = true
            } else {
                arrowDirection = .right
                isChangeDirection = false
            }
        }
        
        setArrowPosition()
        setRelyRect()
        if arrowDirection == .top {
            let y = isChangeDirection ? point.y : point.y
            if arrowPosition > itemWidth / 2 {
                self.frame = CGRect(x: containerSize.width - minSpace - itemWidth, y: y, width: itemWidth, height: height + arrowHeight)
            } else if arrowPosition < itemWidth / 2 {
                self.frame = CGRect(x: minSpace, y: y, width: itemWidth, height: height + arrowHeight)
            } else {
                self.frame = CGRect(x: point.x - itemWidth / 2, y: y, width: itemWidth, height: height + arrowHeight)
            }
        } else if arrowDirection == .bottom {
            let y = isChangeDirection ? point.y - arrowHeight - height : point.y - arrowHeight - height
            if arrowPosition > itemWidth / 2 {
                self.frame = CGRect(x: containerSize.width - minSpace - itemWidth, y: y, width: itemWidth, height: height + arrowHeight)
            } else if arrowPosition < itemWidth / 2 {
                self.frame = CGRect(x: minSpace, y: y, width: itemWidth, height: height + arrowHeight)
            } else {
                self.frame = CGRect(x: point.x - itemWidth / 2, y: y, width: itemWidth, height: height + arrowHeight)
            }
        } else if arrowDirection == .left {
            let x = isChangeDirection ? point.x : point.x
            if arrowPosition < itemHeight / 2 {
                self.frame = CGRect(x: x, y: point.y - arrowPosition, width: itemWidth + arrowHeight, height: height)
            } else if arrowPosition > itemHeight / 2 {
                self.frame = CGRect(x: x, y: point.y - arrowPosition, width: itemWidth + arrowHeight, height: height)
            } else {
                self.frame = CGRect(x: x, y: point.y - arrowPosition, width: itemWidth + arrowHeight, height: height)
            }
        } else if arrowDirection == .right {
            let x = isChangeDirection ? point.x - itemWidth - arrowHeight : point.x - itemWidth - arrowHeight
            if arrowPosition < itemHeight / 2 {
                self.frame = CGRect(x: x, y: point.y - arrowPosition, width: itemWidth + arrowHeight, height: height)
            } else if arrowPosition > itemHeight / 2 {
                self.frame = CGRect(x: x, y: point.y - arrowPosition, width: itemWidth + arrowHeight, height: height)
            } else {
                self.frame = CGRect(x: x, y: point.y - arrowPosition, width: itemWidth + arrowHeight, height: height)
            }
        }

        if isChangeDirection {
            changeRectCorner()
        }
        setAnchorPoint()
        setOffset()
        tableView.reloadData()
        setNeedsDisplay()
    }
    
    private func setRelyRect() {
        guard !relyRect.equalTo(CGRect.zero) else {
            return
        }
        
        if arrowDirection == .top {
            point.y = relyRect.size.height + relyRect.origin.y
        } else if arrowDirection == .bottom {
            point.y = relyRect.origin.y
        } else if arrowDirection == .left {
            point = CGPoint(x: relyRect.origin.x + relyRect.size.width, y: relyRect.origin.y + relyRect.size.height / 2)
        } else {
            point = CGPoint(x: relyRect.origin.x, y: relyRect.origin.y + relyRect.size.height / 2)
        }
    }
    
    private func changeRectCorner() {
        if isCornerChanged || rectCorner == UIRectCorner.allCorners {
            return
        }
        var haveTopLeftCorner = false
        var haveTopRightCorner = false
        var haveBottomLeftCorner = false
        var haveBottomRightCorner = false
        if rectCorner.contains(.topLeft) {
            haveTopLeftCorner = true
        }
        if rectCorner.contains(.topRight) {
            haveTopRightCorner = true
        }
        if rectCorner.contains(.bottomLeft) {
            haveBottomLeftCorner = true
        }
        if rectCorner.contains(.bottomRight) {
            haveBottomRightCorner = true
        }
        
        if arrowDirection == .top || arrowDirection == .bottom {
            if haveTopLeftCorner {
                rectCorner.insert(.bottomLeft)
            } else {
                rectCorner.remove(.bottomLeft)
            }
            if haveTopRightCorner {
                rectCorner.insert(.bottomRight)
            } else {
                rectCorner.remove(.bottomRight)
            }
            if haveBottomLeftCorner {
                rectCorner.insert(.topLeft)
            } else {
                rectCorner.remove(.topLeft)
            }
            if haveBottomRightCorner {
                rectCorner.insert(.topRight)
            } else {
                rectCorner.remove(.topRight)
            }
        } else if arrowDirection == .left || arrowDirection == .right {
            if haveTopLeftCorner {
                rectCorner.insert(.topRight)
            } else {
                rectCorner.remove(.topRight)
            }
            if haveTopRightCorner {
                rectCorner.insert(.topLeft)
            } else {
                rectCorner.remove(.topLeft)
            }
            if haveBottomLeftCorner {
                rectCorner.insert(.bottomRight)
            } else {
                rectCorner.remove(.bottomRight)
            }
            if haveBottomRightCorner {
                rectCorner.insert(.bottomLeft)
            } else {
                rectCorner.remove(.bottomLeft)
            }
        }
        
        isCornerChanged = true
    }
    
    private func setOffset() {
        if itemWidth == 0 { return }
        
        var originRect = frame
        if arrowDirection == .top {
            originRect.origin.y += offset
        } else if arrowDirection == .bottom {
            originRect.origin.y -= offset
        } else if arrowDirection == .left {
            originRect.origin.x += offset
        } else if arrowDirection == .right {
            originRect.origin.x -= offset
        }
        frame = originRect
    }
    
    private func setAnchorPoint() {
        if itemWidth == 0 { return }
        
        let menuHeight = getMenuTotalHeight()
        var point = CGPoint(x: 0.5, y: 0.5)
        if arrowDirection == .top {
            point = CGPoint(x: arrowPosition / itemWidth, y: 0)
        } else if arrowDirection == .bottom {
            point = CGPoint(x: arrowPosition / itemWidth, y: 1)
        } else if arrowDirection == .left {
            point = CGPoint(x: 0, y: arrowPosition / menuHeight)
        } else if arrowDirection == .right {
            point = CGPoint(x: 1, y: arrowPosition / menuHeight)
        }
        
        let originRect = frame
        layer.anchorPoint = point
        frame = originRect
    }
    
    private func setArrowPosition() {
        if priorityDirection == .none { return }
        
        if arrowDirection == .top || arrowDirection == .bottom {
            let containerSize = containerBounds.size
            if point.x + itemWidth / 2 > containerSize.width - minSpace {
                arrowPosition = itemWidth - (containerSize.width - minSpace - point.x)
            } else if point.x < itemWidth / 2 + minSpace {
                arrowPosition = point.x - minSpace
            } else {
                arrowPosition = itemWidth / 2
            }
        }
    }
    
    private func getMenuTotalHeight() -> CGFloat {
        var menuHeight: CGFloat = 0
        if titles.count > maxVisibleCount {
            menuHeight = itemHeight * CGFloat(maxVisibleCount) + borderWidth * 2
        } else {
            menuHeight = itemHeight * CGFloat(titles.count) + borderWidth * 2
        }
        return menuHeight
    }
    
}

class PopupMenuCell: UITableViewCell {
    
    var showsCustomSeparator = true {
        didSet { setNeedsDisplay() }
    }
    var customSeparatorColor: UIColor? = .lightGray {
        didSet { setNeedsDisplay() }
    }
    var customSeparatorHeight: CGFloat = 0.5 {
        didSet { setNeedsDisplay() }
    }
    var customSeparatorInsets: UIEdgeInsets = .zero {
        didSet { setNeedsDisplay() }
    }
    var imageEdgeInsets: UIEdgeInsets = .zero {
        didSet { setNeedsDisplay() }
    }
    var textEdgeInsets: UIEdgeInsets = .zero {
        didSet { setNeedsDisplay() }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let hasImageInset = imageView?.image != nil && imageEdgeInsets != .zero
        let hasTextInset = (textLabel?.text?.count ?? 0) > 0 && textEdgeInsets != .zero
        if !hasImageInset && !hasTextInset { return }
        
        var imageViewFrame = imageView?.frame ?? .zero
        var textLabelFrame = textLabel?.frame ?? .zero
        
        if hasImageInset {
            imageViewFrame.origin.x += imageEdgeInsets.left - imageEdgeInsets.right
            imageViewFrame.origin.y += imageEdgeInsets.top - imageEdgeInsets.bottom
            
            textLabelFrame.origin.x += imageEdgeInsets.left
            textLabelFrame.size.width = min(textLabelFrame.width, contentView.bounds.width - textLabelFrame.minX)
        }
        if hasTextInset {
            textLabelFrame.origin.x += textEdgeInsets.left - textEdgeInsets.right
            textLabelFrame.origin.y += textEdgeInsets.top - textEdgeInsets.bottom
            textLabelFrame.size.width = min(textLabelFrame.width, contentView.bounds.width - textLabelFrame.minX)
        }
        
        imageView?.frame = imageViewFrame
        textLabel?.frame = textLabelFrame
    }
    
    override func draw(_ rect: CGRect) {
        if !showsCustomSeparator { return }
        let bezierPath = UIBezierPath(rect: CGRect(x: customSeparatorInsets.left, y: rect.size.height - customSeparatorHeight + customSeparatorInsets.top - customSeparatorInsets.bottom, width: rect.size.width - customSeparatorInsets.left - customSeparatorInsets.right, height: customSeparatorHeight))
        customSeparatorColor?.setFill()
        bezierPath.fill(with: .normal, alpha: 1)
        bezierPath.close()
    }
    
}

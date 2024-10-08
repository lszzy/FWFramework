//
//  AlertController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - AlertController
/// 弹窗控制器样式枚举
public enum AlertControllerStyle: Int, Sendable {
    /// 从单侧弹出(顶/左/底/右)
    case actionSheet = 0
    /// 从中间弹出
    case alert
}

/// 弹窗动画类型枚举
public enum AlertAnimationType: Int, Sendable {
    /// 默认动画，actionSheet为fromBottom，alert为shrink
    case `default` = 0
    /// 从底部弹出
    case fromBottom
    /// 从顶部弹出
    case fromTop
    /// 从右边弹出
    case fromRight
    /// 从左边弹出
    case fromLeft
    /// 收缩动画
    case shrink
    /// 发散动画
    case expand
    /// 渐变动画
    case fade
    /// 无动画
    case none
}

/// 自定义弹窗控制器样式配置类
public class AlertControllerAppearance: NSObject, @unchecked Sendable {
    /// 单例模式，统一设置样式
    public static let appearance = AlertControllerAppearance()

    /// 自定义首选动作句柄，默认nil，跟随系统
    public var preferredActionBlock: (@MainActor @Sendable (_ alertController: AlertController) -> AlertAction?)?

    /// 标题颜色，仅全局生效，默认nil
    public var titleColor: UIColor?
    /// 标题字体，仅全局生效，默认nil
    public var titleFont: UIFont?
    /// 消息颜色，仅全局生效，默认nil
    public var messageColor: UIColor?
    /// 消息字体，仅全局生效，默认nil
    public var messageFont: UIFont?

    /// 默认动作颜色，仅全局生效，默认nil
    public var actionColor: UIColor?
    /// 首选动作颜色，仅全局生效，默认nil
    public var preferredActionColor: UIColor?
    /// 取消动作颜色，仅全局生效，默认nil
    public var cancelActionColor: UIColor?
    /// 警告动作颜色，仅全局生效，默认nil
    public var destructiveActionColor: UIColor?
    /// 禁用动作颜色，仅全局生效，默认nil
    public var disabledActionColor: UIColor?

    /// 自定义配置项
    public var lineWidth: CGFloat = 1.0 / UIScreen.fw.screenScale
    public var cancelLineWidth: CGFloat = 8.0
    public var contentInsets: UIEdgeInsets = .init(top: 20, left: 15, bottom: 20, right: 15)
    public var actionHeight: CGFloat = 55
    public var actionFont: UIFont? = UIFont.systemFont(ofSize: 18)
    public var actionBoldFont: UIFont? = UIFont.boldSystemFont(ofSize: 18)
    public var imageTitleSpacing: CGFloat = 16.0
    public var titleMessageSpacing: CGFloat = 8.0
    public var textFieldHeight: CGFloat = 30
    public var textFieldTopMargin: CGFloat = 0
    public var textFieldSpacing: CGFloat = 0

    public var normalColor: UIColor? = AlertControllerAppearance.dynamicColorPairs(light: UIColor.white.withAlphaComponent(0.7), dark: UIColor(red: 44.0 / 255.0, green: 44.0 / 255.0, blue: 44.0 / 255.0, alpha: 1.0))
    public var selectedColor: UIColor? = AlertControllerAppearance.dynamicColorPairs(light: UIColor.gray.withAlphaComponent(0.1), dark: UIColor(red: 55.0 / 255.0, green: 55.0 / 255.0, blue: 55.0 / 255.0, alpha: 1.0))
    public var lineColor: UIColor? = AlertControllerAppearance.dynamicColorPairs(light: UIColor.gray.withAlphaComponent(0.3), dark: UIColor(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 60.0 / 255.0, alpha: 1.0))
    public var cancelLineColor: UIColor? = AlertControllerAppearance.dynamicColorPairs(light: UIColor.gray.withAlphaComponent(0.15), dark: UIColor(red: 29.0 / 255.0, green: 29.0 / 255.0, blue: 29.0 / 255.0, alpha: 1.0))
    public var lightLineColor: UIColor? = UIColor.gray.withAlphaComponent(0.3)
    public var darkLineColor: UIColor? = UIColor(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 60.0 / 255.0, alpha: 1.0)
    public var containerBackgroundColor: UIColor? = AlertControllerAppearance.dynamicColorPairs(light: UIColor.white, dark: UIColor.black)
    public var titleDynamicColor: UIColor? = AlertControllerAppearance.dynamicColorPairs(light: UIColor.black, dark: UIColor.white)
    public var textFieldBackgroundColor: UIColor? = AlertControllerAppearance.dynamicColorPairs(light: UIColor(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 247.0 / 255.0, alpha: 1.0), dark: UIColor(red: 54.0 / 255.0, green: 54.0 / 255.0, blue: 54.0 / 255.0, alpha: 1.0))
    public var alertRedColor: UIColor? = UIColor.systemRed
    public var grayColor: UIColor? = UIColor.gray
    public var textFieldCornerRadius: CGFloat = 6.0
    public var textFieldCustomBlock: (@MainActor @Sendable (UITextField) -> Void)?

    public var alertCornerRadius: CGFloat = 6.0
    public var alertEdgeDistance: CGFloat = 50
    public var sheetCornerRadius: CGFloat = 13
    public var sheetEdgeDistance: CGFloat = 70
    public var sheetContainerTransparent: Bool = false
    public var sheetContainerInsets: UIEdgeInsets = .zero

    /// 是否启用Controller样式，设置后自动启用
    public var controllerEnabled: Bool {
        titleColor != nil || titleFont != nil || messageColor != nil || messageFont != nil
    }

    /// 是否启用Action样式，设置后自动启用
    public var actionEnabled: Bool {
        actionColor != nil || preferredActionColor != nil || cancelActionColor != nil || destructiveActionColor != nil || disabledActionColor != nil
    }

    static func dynamicColorPairs(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }

    static func staticColorPairs(light: UIColor, dark: UIColor) -> UIColor {
        let mode = UITraitCollection.current.userInterfaceStyle
        if mode == .dark {
            return dark
        } else if mode == .light {
            return light
        } else {
            return light
        }
    }
}

/// 自定义弹窗控制器事件代理
@MainActor @objc public protocol AlertControllerDelegate {
    /// 将要present
    @objc optional func willPresentAlertController(_ alertController: AlertController)
    /// 已经present
    @objc optional func didPresentAlertController(_ alertController: AlertController)
    /// 将要dismiss
    @objc optional func willDismissAlertController(_ alertController: AlertController)
    /// 已经dismiss
    @objc optional func didDismissAlertController(_ alertController: AlertController)
}

/// 自定义弹窗控制器
///
/// [SPAlertController](https://github.com/SPStore/SPAlertController)
open class AlertController: UIViewController, UIViewControllerTransitioningDelegate {
    /// 获取所有动作
    open private(set) var actions: [AlertAction] = []

    /// 设置首选动作
    open var preferredAction: AlertAction? {
        didSet {
            for action in actions {
                if action.titleFont == alertAppearance.actionBoldFont {
                    action.titleFont = alertAppearance.actionFont
                }
                if action.isPreferred {
                    action.isPreferred = false
                }
            }
            preferredAction?.titleFont = alertAppearance.actionBoldFont
            preferredAction?.isPreferred = true
        }
    }

    /// 获取所有输入框
    open private(set) var textFields: [UITextField]? = []

    /// 主标题
    override open var title: String? {
        didSet {
            if isViewLoaded {
                // 如果条件为真，说明外界在对title赋值之前就已经使用了self.view，先走了viewDidLoad方法，如果先走的viewDidLoad，需要在title的setter方法中重新设置数据,以下setter方法中的条件同理
                headerView.titleLabel.text = title
                // 文字发生变化后再更新布局，这里更新布局也不是那么重要，因为headerView中的布局方法只有当AlertController被present后才会走一次，而那时候，一般title,titleFont、message、messageFont等都是最新值，这里防止的是：在AlertController被present后的某个时刻再去设置title,titleFont等，我们要更新布局
                // 这个if条件的意思是当AlertController被present后的某个时刻设置了title，如果在present之前设置的就不用更新，系统会主动更新
                if presentationController?.presentingViewController != nil {
                    headerView.setNeedsUpdateConstraints()
                }
            }
        }
    }

    /// 副标题
    open var message: String? {
        didSet {
            if isViewLoaded {
                headerView.messageLabel.text = message
                if presentationController?.presentingViewController != nil {
                    headerView.setNeedsUpdateConstraints()
                }
            }
        }
    }

    /// 弹窗样式，默认Default
    open var alertStyle: AlertStyle = .default
    /// 动画类型
    open var animationType: AlertAnimationType {
        get {
            _animationType
        }
        set {
            if newValue == .default {
                _animationType = preferredStyle == .alert ? .shrink : .fromBottom
            } else {
                _animationType = newValue
            }
        }
    }

    private var _animationType: AlertAnimationType = .default
    /// 主标题(富文本)
    open var attributedTitle: NSAttributedString? {
        didSet {
            if isViewLoaded {
                headerView.titleLabel.attributedText = attributedTitle
                if presentationController?.presentingViewController != nil {
                    headerView.setNeedsUpdateConstraints()
                }
            }
        }
    }

    /// 副标题(富文本)
    open var attributedMessage: NSAttributedString? {
        didSet {
            if isViewLoaded {
                headerView.messageLabel.attributedText = attributedMessage
                if presentationController?.presentingViewController != nil {
                    headerView.setNeedsUpdateConstraints()
                }
            }
        }
    }

    /// 头部图标，位置处于title之上,大小取决于图片本身大小
    open var image: UIImage? {
        didSet {
            if isViewLoaded {
                headerView.imageView.image = image
                if presentationController?.presentingViewController != nil {
                    headerView.setNeedsUpdateConstraints()
                }
            }
        }
    }

    /// 主标题颜色
    open var titleColor: UIColor? {
        didSet {
            if isViewLoaded {
                headerView.titleLabel.textColor = titleColor
            }
        }
    }

    /// 主标题字体,默认18,加粗
    open var titleFont: UIFont? = UIFont.boldSystemFont(ofSize: 18) {
        didSet {
            if isViewLoaded {
                headerView.titleLabel.font = titleFont
                if presentationController?.presentingViewController != nil {
                    headerView.setNeedsUpdateConstraints()
                }
            }
        }
    }

    /// 副标题颜色
    open var messageColor: UIColor? {
        didSet {
            if isViewLoaded {
                headerView.messageLabel.textColor = messageColor
            }
        }
    }

    /// 副标题字体,默认16,未加粗
    open var messageFont: UIFont? = UIFont.systemFont(ofSize: 16) {
        didSet {
            if isViewLoaded {
                headerView.messageLabel.font = messageFont
                if presentationController?.presentingViewController != nil {
                    headerView.setNeedsUpdateConstraints()
                }
            }
        }
    }

    /// 对齐方式(包括主标题和副标题)
    open var textAlignment: NSTextAlignment = .center {
        didSet {
            headerView.titleLabel.textAlignment = textAlignment
            headerView.messageLabel.textAlignment = textAlignment
        }
    }

    /// 头部图标的限制大小,默认无穷大
    open var imageLimitSize: CGSize = .init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude) {
        didSet {
            if isViewLoaded {
                headerView.imageLimitSize = imageLimitSize
                if presentationController?.presentingViewController != nil {
                    headerView.setNeedsUpdateConstraints()
                }
            }
        }
    }

    /// 图片的tintColor,当外部的图片使用了AlwaysTemplate的渲染模式时,该属性可起到作用
    open var imageTintColor: UIColor? {
        didSet {
            if isViewLoaded {
                headerView.imageView.tintColor = imageTintColor
            }
        }
    }

    /// action水平排列还是垂直排列
    /// actionSheet样式下:默认为UILayoutConstraintAxisVertical(垂直排列), 如果设置为UILayoutConstraintAxisHorizontal(水平排列)，则除去取消样式action之外的其余action将水平排列
    /// alert样式下:当actions的个数大于2，或者某个action的title显示不全时为UILayoutConstraintAxisVertical(垂直排列)，否则默认为UILayoutConstraintAxisHorizontal(水平排列)，此样式下设置该属性可以修改所有action的排列方式
    /// 不论哪种样式，只要外界设置了该属性，永远以外界设置的优先
    open var actionAxis: NSLayoutConstraint.Axis {
        get {
            _actionAxis
        }
        set {
            _actionAxis = newValue
            // 调用该setter方法则认为是强制布局，该setter方法只有外界能调，这样才能判断外界有没有调用actionAxis的setter方法，从而是否按照外界的指定布局方式进行布局
            isForceLayout = true
            if isViewLoaded {
                updateActionAxis()
            }
        }
    }

    private var _actionAxis: NSLayoutConstraint.Axis = .vertical
    /// 距离屏幕边缘的最小间距
    /// alert样式下该属性是指对话框四边与屏幕边缘之间的距离，此样式下默认值随设备变化，actionSheet样式下是指弹出边的对立边与屏幕之间的距离，比如如果从右边弹出，那么该属性指的就是对话框左边与屏幕之间的距离，此样式下默认值为70
    open var minDistanceToEdges: CGFloat = 0 {
        didSet {
            if isViewLoaded {
                setupPreferredMaxLayoutWidth(for: headerView.titleLabel)
                setupPreferredMaxLayoutWidth(for: headerView.messageLabel)
                if presentationController?.presentingViewController != nil {
                    layoutAlertControllerView()
                    headerView.setNeedsUpdateConstraints()
                    actionSequenceView.setNeedsUpdateConstraints()
                }
            }
        }
    }

    /// Alert样式下默认6.0f，ActionSheet样式下默认13.0f，去除半径设置为0即可
    open var cornerRadius: CGFloat = 0 {
        didSet {
            if preferredStyle == .alert {
                containerView.layer.cornerRadius = cornerRadius
                containerView.layer.masksToBounds = true
            } else {
                if cornerRadius > 0 {
                    var corner: UIRectCorner = [.topLeft, .topRight]
                    switch _animationType {
                    case .fromBottom:
                        corner = [.topLeft, .topRight]
                    case .fromTop:
                        corner = [.bottomLeft, .bottomRight]
                    case .fromLeft:
                        corner = [.topRight, .bottomRight]
                    case .fromRight:
                        corner = [.topLeft, .bottomLeft]
                    default:
                        break
                    }
                    if let _containerView,
                       let maskLayer = _containerView.layer.mask as? CAShapeLayer {
                        maskLayer.path = UIBezierPath(roundedRect: _containerView.bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath
                        maskLayer.frame = _containerView.bounds
                    }
                } else {
                    _containerView?.layer.mask = nil
                }
            }
        }
    }

    /// 对话框的偏移量，y值为正向下偏移，为负向上偏移；x值为正向右偏移，为负向左偏移，该属性只对Alert样式有效,键盘的frame改变会自动偏移，如果手动设置偏移只会取手动设置的
    open var offsetForAlert: CGPoint {
        get {
            _offsetForAlert
        }
        set {
            setOffsetForAlert(newValue, animated: false)
        }
    }

    private var _offsetForAlert: CGPoint = .zero
    /// 是否需要对话框拥有毛玻璃,默认为NO
    open var needDialogBlur: Bool = false {
        didSet {
            if needDialogBlur {
                containerView.backgroundColor = .clear
                if dimmingKnockoutBackdropView == nil {
                    let viewClass = NSClassFromString(String(format: "%@%@%@", "_U", "IDimmingKnockou", "tBackdropView")) as? UIView.Type
                    if let viewObject = viewClass?.init(frame: .zero) {
                        let viewSelector = NSSelectorFromString("setStyle:")
                        if viewObject.responds(to: viewSelector) {
                            _ = viewObject.perform(viewSelector, with: UIBlurEffect.Style.light)
                        }
                        dimmingKnockoutBackdropView = viewObject
                    } else {
                        let blur = UIBlurEffect(style: .extraLight)
                        dimmingKnockoutBackdropView = UIVisualEffectView(effect: blur)
                    }
                    if let dimmingKnockoutBackdropView {
                        dimmingKnockoutBackdropView.frame = containerView.bounds
                        dimmingKnockoutBackdropView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        containerView.insertSubview(dimmingKnockoutBackdropView, at: 0)
                    }
                }
            } else {
                dimmingKnockoutBackdropView?.removeFromSuperview()
                dimmingKnockoutBackdropView = nil
                if _customAlertView != nil {
                    containerView.backgroundColor = .clear
                } else if preferredStyle == .actionSheet, alertAppearance.sheetContainerTransparent {
                    containerView.backgroundColor = .clear
                } else {
                    containerView.backgroundColor = alertAppearance.containerBackgroundColor
                }
            }
        }
    }

    /// 是否含有自定义TextField,键盘的frame改变会自动偏移,默认为NO
    open var hasCustomTextField: Bool = false
    /// 是否单击背景退出对话框,默认为YES
    open var tapBackgroundViewDismiss: Bool = true
    /// 是否点击动作按钮退出动画框,默认为YES
    open var tapActionDismiss: Bool = true

    /// 单击背景dismiss完成回调，默认nil
    open var dismissCompletion: (() -> Void)?
    /// 事件代理
    open weak var delegate: AlertControllerDelegate?
    /// 弹出框样式
    open private(set) var preferredStyle: AlertControllerStyle = .actionSheet
    /// 自定义样式，默认为样式单例
    open var alertAppearance: AlertControllerAppearance {
        appearance ?? AlertControllerAppearance.appearance
    }

    var backgroundViewAppearanceStyle: UIBlurEffect.Style?
    var backgroundViewAlpha: CGFloat = 0.5
    private var customViewSize: CGSize = .zero
    private var customHeaderSpacing: CGFloat = 0
    private var dimmingKnockoutBackdropView: UIView?
    private var headerActionLineConstraints: [NSLayoutConstraint] = []
    private var componentViewConstraints: [NSLayoutConstraint] = []
    private var componentActionLineConstraints: [NSLayoutConstraint] = []
    private var alertControllerViewConstraints: [NSLayoutConstraint] = []
    private var headerViewConstraints: [NSLayoutConstraint] = []
    private var actionSequenceViewConstraints: [NSLayoutConstraint] = []
    private var otherActions: [AlertAction] = []
    // 是否强制排列，外界设置了actionAxis属性认为是强制
    private var isForceLayout = false
    // 是否强制偏移，外界设置了offsetForAlert属性认为是强制
    private var isForceOffset = false
    private var appearance: AlertControllerAppearance?
    private var maxWidth: CGFloat {
        if preferredStyle == .alert {
            return min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - minDistanceToEdges * 2
        } else {
            return UIScreen.main.bounds.size.width
        }
    }

    private lazy var alertControllerView: UIView = {
        let result = UIView()
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()

    private var containerView: UIView {
        if let result = _containerView {
            return result
        }

        let result = UIView()
        if preferredStyle == .alert {
            result.layer.cornerRadius = cornerRadius
            result.layer.masksToBounds = true
        } else {
            if cornerRadius > 0 {
                let maskLayer = CAShapeLayer()
                result.layer.mask = maskLayer
            }
        }
        alertControllerView.addSubview(result)
        if preferredStyle == .actionSheet, alertAppearance.sheetContainerTransparent {
            result.fw.pinEdges(toSuperview: alertAppearance.sheetContainerInsets, autoScale: false)
        } else {
            result.frame = alertControllerView.bounds
            result.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        _containerView = result
        return result
    }

    private weak var _containerView: UIView?

    private lazy var alertView: UIView = {
        let result = UIView()
        result.frame = alertControllerView.bounds
        result.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if customAlertView == nil {
            containerView.addSubview(result)
        }
        return result
    }()

    private lazy var headerView: AlertHeaderScrollView = {
        let result = AlertHeaderScrollView(appearance: appearance)
        result.backgroundColor = alertAppearance.normalColor
        result.translatesAutoresizingMaskIntoConstraints = false
        result.headerViewSafeAreaDidChangedBlock = { [weak self] in
            guard let self else { return }
            setupPreferredMaxLayoutWidth(for: headerView.titleLabel)
            setupPreferredMaxLayoutWidth(for: headerView.messageLabel)
        }
        if customHeaderView == nil {
            alertView.addSubview(result)
        }
        return result
    }()

    private lazy var actionSequenceView: AlertActionSequenceView = {
        let result = AlertActionSequenceView(appearance: appearance)
        result.preferredStyle = preferredStyle
        result.cornerRadius = cornerRadius
        result.translatesAutoresizingMaskIntoConstraints = false
        result.buttonClickedInActionViewBlock = { [weak self] index, actionView in
            guard let self else { return }
            let action = actions[index]
            if tapActionDismiss {
                dismiss(animated: true) {
                    action.handler?(action)
                }
            } else {
                actionView.actionButton.backgroundColor = actionView.alertAppearance.normalColor
                action.handler?(action)
            }
        }
        if actions.count > 0, customActionSequenceView == nil {
            alertView.addSubview(result)
        }
        return result
    }()

    private lazy var headerActionLine: AlertActionItemSeparatorView = {
        let result = AlertActionItemSeparatorView(appearance: appearance)
        result.translatesAutoresizingMaskIntoConstraints = false
        if (headerView.superview != nil || customHeaderView?.superview != nil) && (actionSequenceView.superview != nil || customActionSequenceView?.superview != nil) {
            alertView.addSubview(result)
        }
        return result
    }()

    private lazy var componentActionLine: AlertActionItemSeparatorView = {
        let result = AlertActionItemSeparatorView(appearance: appearance)
        result.translatesAutoresizingMaskIntoConstraints = false
        if componentView?.superview != nil && (actionSequenceView.superview != nil || customActionSequenceView?.superview != nil) {
            alertView.addSubview(result)
        }
        return result
    }()

    private var customAlertView: UIView? {
        if let result = _customAlertView, result.superview == nil {
            if customViewSize.equalTo(.zero) {
                customViewSize = sizeForCustomView(result)
            }
            // 必须在在下面2行代码之前获取_customViewSize
            result.frame = alertControllerView.bounds
            result.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            containerView.addSubview(result)
        }
        return _customAlertView
    }

    private var _customAlertView: UIView?

    private var customHeaderView: UIView? {
        if let result = _customHeaderView, result.superview == nil {
            if customViewSize.equalTo(.zero) {
                customViewSize = sizeForCustomView(result)
            }
            result.translatesAutoresizingMaskIntoConstraints = false
            alertView.addSubview(result)
        }
        return _customHeaderView
    }

    private var _customHeaderView: UIView?

    private var customActionSequenceView: UIView? {
        if let result = _customActionSequenceView, result.superview == nil {
            if customViewSize.equalTo(.zero) {
                customViewSize = sizeForCustomView(result)
            }
            result.translatesAutoresizingMaskIntoConstraints = false
            alertView.addSubview(result)
        }
        return _customActionSequenceView
    }

    private var _customActionSequenceView: UIView?

    private var componentView: UIView? {
        if let result = _componentView, result.superview == nil {
            assert(headerActionLine.superview != nil, "Due to the -componentView is added between the -head and the -action section, the -head and -action must exist together")
            if customViewSize.equalTo(.zero) {
                customViewSize = sizeForCustomView(result)
            }
            result.translatesAutoresizingMaskIntoConstraints = false
            alertView.addSubview(result)
        }
        return _componentView
    }

    private var _componentView: UIView?

    /// 创建控制器(默认对话框)
    public convenience init(title: String?, message: String?, preferredStyle: AlertControllerStyle, animationType: AlertAnimationType = .default, appearance: AlertControllerAppearance? = nil) {
        self.init(title: title, message: message, customAlertView: nil, customHeaderView: nil, customActionSequenceView: nil, componentView: nil, preferredStyle: preferredStyle, animationType: animationType, appearance: appearance)
    }

    /// 创建控制器(自定义整个对话框)
    public convenience init(customAlertView: UIView, preferredStyle: AlertControllerStyle, animationType: AlertAnimationType = .default, appearance: AlertControllerAppearance? = nil) {
        self.init(title: nil, message: nil, customAlertView: customAlertView, customHeaderView: nil, customActionSequenceView: nil, componentView: nil, preferredStyle: preferredStyle, animationType: animationType, appearance: appearance)
    }

    /// 创建控制器(自定义对话框的头部)
    public convenience init(customHeaderView: UIView, preferredStyle: AlertControllerStyle, animationType: AlertAnimationType = .default, appearance: AlertControllerAppearance? = nil) {
        self.init(title: nil, message: nil, customAlertView: nil, customHeaderView: customHeaderView, customActionSequenceView: nil, componentView: nil, preferredStyle: preferredStyle, animationType: animationType, appearance: appearance)
    }

    /// 创建控制器(自定义对话框的action部分)
    public convenience init(customActionSequenceView: UIView, title: String?, message: String?, preferredStyle: AlertControllerStyle, animationType: AlertAnimationType = .default, appearance: AlertControllerAppearance? = nil) {
        self.init(title: title, message: message, customAlertView: nil, customHeaderView: nil, customActionSequenceView: customActionSequenceView, componentView: nil, preferredStyle: preferredStyle, animationType: animationType, appearance: appearance)
    }

    private init(title: String?, message: String?, customAlertView: UIView?, customHeaderView: UIView?, customActionSequenceView: UIView?, componentView: UIView?, preferredStyle: AlertControllerStyle, animationType: AlertAnimationType, appearance: AlertControllerAppearance?) {
        super.init(nibName: nil, bundle: nil)
        self.appearance = appearance
        didInitialize()

        self.title = title
        self.message = message
        self.preferredStyle = preferredStyle
        self.animationType = animationType
        if preferredStyle == .alert {
            self.minDistanceToEdges = alertAppearance.alertEdgeDistance
            self.cornerRadius = alertAppearance.alertCornerRadius
            self._actionAxis = .horizontal
        } else {
            self.minDistanceToEdges = alertAppearance.sheetEdgeDistance
            self.cornerRadius = alertAppearance.sheetCornerRadius
            self._actionAxis = .vertical
        }
        self._customAlertView = customAlertView
        self._customHeaderView = customHeaderView
        self._customActionSequenceView = customActionSequenceView
        self._componentView = componentView
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        didInitialize()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func didInitialize() {
        providesPresentationContextTransitionStyle = true
        definesPresentationContext = true
        modalPresentationStyle = .custom
        transitioningDelegate = self

        titleColor = alertAppearance.titleDynamicColor
        messageColor = alertAppearance.grayColor
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override open func loadView() {
        view = alertControllerView
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        configureHeaderView()
        let needBlur = needDialogBlur
        needDialogBlur = needBlur
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isForceOffset && ((_customAlertView == nil && _customHeaderView == nil && _customActionSequenceView == nil && _componentView == nil) || hasCustomTextField) {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameWillChange(_:)), name: UIApplication.keyboardWillChangeFrameNotification, object: nil)
        }
        if let firstTextField = textFields?.first {
            if !firstTextField.isFirstResponder {
                firstTextField.becomeFirstResponder()
            }
        }
    }

    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setupPreferredMaxLayoutWidth(for: headerView.titleLabel)
        setupPreferredMaxLayoutWidth(for: headerView.messageLabel)
        layoutAlertControllerView()
        layoutChildViews()

        if preferredStyle == .actionSheet {
            let radius = cornerRadius
            cornerRadius = radius
        }
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        handleIncompleteTextDisplay()
    }

    /// 添加动作
    open func addAction(_ action: AlertAction) {
        var actions = actions
        actions.append(action)
        self.actions = actions

        // alert样式不论是否为取消样式的按钮，都直接按顺序添加
        if preferredStyle == .alert {
            if action.style != .cancel {
                otherActions.append(action)
            }
            actionSequenceView.addAction(action)
            // actionSheet样式
        } else {
            if action.style == .cancel {
                actionSequenceView.addCancelAction(action)
            } else {
                otherActions.append(action)
                actionSequenceView.addAction(action)
            }
        }

        // 如果为NO,说明外界没有设置actionAxis，此时按照默认方式排列
        if !isForceLayout {
            if preferredStyle == .alert {
                // alert样式下，action的个数大于2时垂直排列
                if self.actions.count > 2 {
                    // 本框架任何一处都不允许调用actionAxis的setter方法，如果调用了则无法判断是外界调用还是内部调用
                    _actionAxis = .vertical
                    updateActionAxis()
                    // action的个数小于等于2，action水平排列
                } else {
                    _actionAxis = .horizontal
                    updateActionAxis()
                }
                // actionSheet样式下默认垂直排列
            } else {
                _actionAxis = .vertical
                updateActionAxis()
            }
        } else {
            updateActionAxis()
        }

        // 这个block是保证外界在添加action之后再设置action属性时依然生效；当使用时在addAction之后再设置action的属性时，会回调这个block
        action.propertyChangedBlock = { [weak self] action, needUpdateConstraints in
            if self?.preferredStyle == .alert {
                // alert样式下：arrangedSubviews数组和actions是对应的
                if let index = self?.actions.firstIndex(of: action) {
                    let actionView = self?.actionSequenceView.stackView.arrangedSubviews[index] as? AlertControllerActionView
                    actionView?.action = action
                }
                if self?.presentationController?.presentingViewController != nil {
                    // 文字显示不全处理
                    self?.handleIncompleteTextDisplay()
                }
            } else {
                if action.style == .cancel {
                    // cancelView中只有唯一的一个actionView
                    let actionView = self?.actionSequenceView.cancelView.subviews.last as? AlertControllerActionView
                    actionView?.action = action
                } else {
                    // actionSheet样式下：arrangedSubviews数组和otherActions是对应的
                    if let index = self?.otherActions.firstIndex(of: action) {
                        let actionView = self?.actionSequenceView.stackView.arrangedSubviews[index] as? AlertControllerActionView
                        actionView?.action = action
                    }
                }
            }
            if self?.presentationController?.presentingViewController != nil && needUpdateConstraints {
                // 如果在present完成后的某个时刻再去设置action的属性，字体等改变需要更新布局
                self?.actionSequenceView.setNeedsUpdateConstraints()
            }
        }
    }

    /// 添加文本输入框，一旦添加后就会仅回调一次configurationHandler
    open func addTextField(configurationHandler: (@MainActor @Sendable (UITextField) -> Void)? = nil) {
        assert(preferredStyle == .alert, "AlertController does not allow 'addTextFieldWithConfigurationHandler:' to be called in the style of AlertControllerStyleActionSheet")
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = alertAppearance.textFieldBackgroundColor
        // 系统的UITextBorderStyleLine样式线条过于黑，所以自己设置
        textField.layer.borderWidth = alertAppearance.lineWidth
        // 这里设置的颜色是静态的，动态设置CGColor,还需要监听深浅模式的切换
        textField.layer.borderColor = AlertControllerAppearance.staticColorPairs(light: alertAppearance.lineColor ?? .clear, dark: alertAppearance.darkLineColor ?? .clear).cgColor
        textField.layer.cornerRadius = alertAppearance.textFieldCornerRadius
        textField.layer.masksToBounds = true
        // 在左边设置一张view，充当光标左边的间距，否则光标紧贴textField不美观
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftView?.isUserInteractionEnabled = false
        textField.leftViewMode = .always
        textField.font = UIFont.systemFont(ofSize: 14)
        // 去掉textField键盘上部的联想条
        textField.autocorrectionType = .no
        textField.addTarget(self, action: #selector(textFieldDidEndOnExit(_:)), for: .editingDidEndOnExit)
        alertAppearance.textFieldCustomBlock?(textField)

        var textFields = textFields ?? []
        textFields.append(textField)
        self.textFields = textFields
        headerView.addTextField(textField)
        configurationHandler?(textField)
    }

    /// 设置alert样式下的偏移量,动画为NO则跟属性offsetForAlert等效
    open func setOffsetForAlert(_ offsetForAlert: CGPoint, animated: Bool) {
        _offsetForAlert = offsetForAlert
        isForceOffset = true
        makeViewOffset(animated: animated)
    }

    /// 设置action与下一个action之间的间距, action仅限于非取消样式，必须在'-addAction:'之后设置，nil时设置header与action间距
    open func setCustomSpacing(_ spacing: CGFloat, afterAction action: AlertAction?) {
        guard let action else {
            customHeaderSpacing = spacing
            return
        }
        if action.style == .cancel {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "*** warning in -[AlertController setCustomSpacing:afterAction:]: 'the -action must not be a action with AlertActionStyleCancel style'")
            #endif
        } else if !otherActions.contains(action) {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "*** warning in -[AlertController setCustomSpacing:afterAction:]: 'the -action must be contained in the -actions array, not a action with AlertActionStyleCancel style'")
            #endif
        } else {
            if let index = otherActions.firstIndex(of: action) {
                actionSequenceView.setCustomSpacing(spacing, afterActionIndex: index)
            }
        }
    }

    /// 获取action与下一个action之间的间距, action仅限于非取消样式，必须在'-addAction:'之后获取，nil时获取header与action间距
    open func customSpacingAfterAction(_ action: AlertAction?) -> CGFloat {
        guard let action else {
            return customHeaderSpacing
        }
        if let index = otherActions.firstIndex(of: action) {
            return actionSequenceView.customSpacing(afterActionIndex: index)
        }
        return 0
    }

    /// 设置蒙层的外观样式,可通过alpha调整透明度
    open func setBackgroundViewAppearanceStyle(_ style: UIBlurEffect.Style?, alpha: CGFloat) {
        backgroundViewAppearanceStyle = style
        backgroundViewAlpha = alpha
    }

    /// 插入一个组件view，位置处于头部和action部分之间，要求头部和action部分同时存在
    open func insertComponentView(_ componentView: UIView) {
        _componentView = componentView
    }

    /// 更新自定义view的size，比如屏幕旋转，自定义view的大小发生了改变，可通过该方法更新size
    open func updateCustomViewSize(_ size: CGSize) {
        customViewSize = size
        layoutAlertControllerView()
        layoutChildViews()
    }

    func layoutAlertControllerView() {
        guard alertControllerView.superview != nil else { return }
        if alertControllerViewConstraints.count > 0 {
            NSLayoutConstraint.deactivate(alertControllerViewConstraints)
            alertControllerViewConstraints.removeAll()
        }
        if preferredStyle == .alert {
            layoutAlertControllerViewForAlertStyle()
        } else {
            layoutAlertControllerViewForActionSheetStyle()
        }
    }

    private func layoutAlertControllerViewForAlertStyle() {
        var alertControllerViewConstraints = [NSLayoutConstraint]()
        let topValue = minDistanceToEdges
        let bottomValue = minDistanceToEdges
        let maxWidth = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) - minDistanceToEdges * 2
        let maxHeight = UIScreen.main.bounds.size.height - topValue - bottomValue
        if customAlertView == nil {
            // 当屏幕旋转的时候，为了保持alert样式下的宽高不变，因此取MIN(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)
            alertControllerViewConstraints.append(NSLayoutConstraint(item: alertControllerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: maxWidth))
        } else {
            alertControllerViewConstraints.append(NSLayoutConstraint(item: alertControllerView, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: maxWidth))
            if customViewSize.width > 0 {
                // 如果宽度没有值，则会假定customAlertView水平方向能由子控件撑起
                let customWidth = min(customViewSize.width, maxWidth)
                alertControllerViewConstraints.append(NSLayoutConstraint(item: alertControllerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: customWidth))
            }
            if customViewSize.height > 0 {
                // 如果高度没有值，则会假定customAlertView垂直方向能由子控件撑起
                let customHeight = min(customViewSize.height, maxHeight)
                alertControllerViewConstraints.append(NSLayoutConstraint(item: alertControllerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: customHeight))
            }
        }
        let topConstraint = NSLayoutConstraint(item: alertControllerView, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: alertControllerView.superview, attribute: .top, multiplier: 1.0, constant: topValue)
        // 这里优先级为999.0是为了小于垂直中心的优先级，如果含有文本输入框，键盘弹出后，特别是旋转到横屏后，对话框的空间比较小，这个时候优先偏移垂直中心，顶部优先级按理说应该会被忽略，但是由于子控件含有scrollView，所以该优先级仍然会被激活，子控件显示不全scrollView可以滑动。如果外界自定义了整个对话框，且自定义的view上含有文本输入框，子控件不含有scrollView，顶部间距会被忽略
        topConstraint.priority = .init(999)
        alertControllerViewConstraints.append(topConstraint)
        let bottomConstraint = NSLayoutConstraint(item: alertControllerView, attribute: .bottom, relatedBy: .lessThanOrEqual, toItem: alertControllerView.superview, attribute: .bottom, multiplier: 1.0, constant: -bottomValue)
        bottomConstraint.priority = .init(999)
        alertControllerViewConstraints.append(bottomConstraint)
        alertControllerViewConstraints.append(NSLayoutConstraint(item: alertControllerView, attribute: .centerX, relatedBy: .equal, toItem: alertControllerView.superview, attribute: .centerX, multiplier: 1.0, constant: _offsetForAlert.x))
        alertControllerViewConstraints.append(NSLayoutConstraint(item: alertControllerView, attribute: .centerY, relatedBy: .equal, toItem: alertControllerView.superview, attribute: .centerY, multiplier: 1.0, constant: (isBeingPresented && !isBeingDismissed) ? 0 : _offsetForAlert.y))
        NSLayoutConstraint.activate(alertControllerViewConstraints)
        self.alertControllerViewConstraints = alertControllerViewConstraints
    }

    private func layoutAlertControllerViewForActionSheetStyle() {
        switch animationType {
        case .fromBottom:
            layoutAlertControllerViewForAnimationType(hv: "H", equalAttribute: .bottom, notEqualAttribute: .top, lessOrGreaterRelation: .greaterThanOrEqual)
        case .fromTop:
            layoutAlertControllerViewForAnimationType(hv: "H", equalAttribute: .top, notEqualAttribute: .bottom, lessOrGreaterRelation: .lessThanOrEqual)
        case .fromLeft:
            layoutAlertControllerViewForAnimationType(hv: "V", equalAttribute: .left, notEqualAttribute: .right, lessOrGreaterRelation: .lessThanOrEqual)
        case .fromRight:
            layoutAlertControllerViewForAnimationType(hv: "V", equalAttribute: .right, notEqualAttribute: .left, lessOrGreaterRelation: .lessThanOrEqual)
        default:
            layoutAlertControllerViewForAnimationType(hv: "H", equalAttribute: .bottom, notEqualAttribute: .top, lessOrGreaterRelation: .greaterThanOrEqual)
        }
    }

    private func layoutAlertControllerViewForAnimationType(hv: String, equalAttribute: NSLayoutConstraint.Attribute, notEqualAttribute: NSLayoutConstraint.Attribute, lessOrGreaterRelation relation: NSLayoutConstraint.Relation) {
        var alertControllerViewConstraints = [NSLayoutConstraint]()
        if customAlertView == nil {
            alertControllerViewConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "\(hv):|-0-[alertControllerView]-0-|", metrics: nil, views: ["alertControllerView": alertControllerView]))
        } else {
            let centerXorY: NSLayoutConstraint.Attribute = hv == "H" ? .centerX : .centerY
            alertControllerViewConstraints.append(NSLayoutConstraint(item: alertControllerView, attribute: centerXorY, relatedBy: .equal, toItem: alertControllerView.superview, attribute: centerXorY, multiplier: 1.0, constant: 0))
            if customViewSize.width > 0 {
                // 如果宽度没有值，则会假定customAlertViewh水平方向能由子控件撑起
                var alertControllerViewWidth: CGFloat = 0
                if hv == "H" {
                    alertControllerViewWidth = min(customViewSize.width, UIScreen.main.bounds.size.width)
                } else {
                    alertControllerViewWidth = min(customViewSize.width, UIScreen.main.bounds.size.width - minDistanceToEdges)
                }
                alertControllerViewConstraints.append(NSLayoutConstraint(item: alertControllerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: alertControllerViewWidth))
            }
            if customViewSize.height > 0 {
                // 如果高度没有值，则会假定customAlertViewh垂直方向能由子控件撑起
                var alertControllerViewHeight: CGFloat = 0
                if hv == "H" {
                    alertControllerViewHeight = min(customViewSize.height, UIScreen.main.bounds.size.height - minDistanceToEdges)
                } else {
                    alertControllerViewHeight = min(customViewSize.height, UIScreen.main.bounds.size.height)
                }
                alertControllerViewConstraints.append(NSLayoutConstraint(item: alertControllerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: alertControllerViewHeight))
            }
        }
        alertControllerViewConstraints.append(NSLayoutConstraint(item: alertControllerView, attribute: equalAttribute, relatedBy: .equal, toItem: alertControllerView.superview, attribute: equalAttribute, multiplier: 1.0, constant: 0))
        let someSideConstraint = NSLayoutConstraint(item: alertControllerView, attribute: notEqualAttribute, relatedBy: relation, toItem: alertControllerView.superview, attribute: notEqualAttribute, multiplier: 1.0, constant: minDistanceToEdges)
        someSideConstraint.priority = .init(999)
        alertControllerViewConstraints.append(someSideConstraint)
        NSLayoutConstraint.activate(alertControllerViewConstraints)
        self.alertControllerViewConstraints = alertControllerViewConstraints
    }

    private func layoutChildViews() {
        // 对头部布局
        layoutHeaderView()
        // 对头部和action部分之间的分割线布局
        layoutHeaderActionLine()
        // 对组件view布局
        layoutComponentView()
        // 对组件view与action部分之间的分割线布局
        layoutComponentActionLine()
        // 对action部分布局
        layoutActionSequenceView()
    }

    private func layoutHeaderView() {
        let headerView = customHeaderView ?? headerView
        guard headerView.superview != nil else { return }
        if preferredStyle == .actionSheet && alertAppearance.sheetContainerTransparent {
            headerView.backgroundColor = alertAppearance.containerBackgroundColor
            headerView.layer.cornerRadius = cornerRadius
            headerView.layer.masksToBounds = true
        }

        if self.headerViewConstraints.count > 0 {
            NSLayoutConstraint.deactivate(self.headerViewConstraints)
            self.headerViewConstraints.removeAll()
        }
        var headerViewConstraints = [NSLayoutConstraint]()
        if customHeaderView == nil {
            headerViewConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[headerView]-0-|", metrics: nil, views: ["headerView": headerView]))
        } else {
            if customViewSize.width > 0 {
                let maxWidth = maxWidth
                let headerViewWidth = min(maxWidth, customViewSize.width)
                headerViewConstraints.append(NSLayoutConstraint(item: headerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: headerViewWidth))
            }
            if customViewSize.height > 0 {
                let customHeightConstraint = NSLayoutConstraint(item: headerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: customViewSize.height)
                customHeightConstraint.priority = .defaultHigh
                headerViewConstraints.append(customHeightConstraint)
            }
            headerViewConstraints.append(NSLayoutConstraint(item: headerView, attribute: .centerX, relatedBy: .equal, toItem: alertView, attribute: .centerX, multiplier: 1.0, constant: 0))
        }
        headerViewConstraints.append(NSLayoutConstraint(item: headerView, attribute: .top, relatedBy: .equal, toItem: alertView, attribute: .top, multiplier: 1.0, constant: 0))
        if headerActionLine.superview == nil {
            headerViewConstraints.append(NSLayoutConstraint(item: headerView, attribute: .bottom, relatedBy: .equal, toItem: alertView, attribute: .bottom, multiplier: 1.0, constant: 0))
        }
        NSLayoutConstraint.activate(headerViewConstraints)
        self.headerViewConstraints = headerViewConstraints
    }

    private func layoutHeaderActionLine() {
        guard headerActionLine.superview != nil else { return }
        let headerView = customHeaderView ?? headerView
        let actionSequenceView = customActionSequenceView ?? actionSequenceView
        if self.headerActionLineConstraints.count > 0 {
            NSLayoutConstraint.deactivate(self.headerActionLineConstraints)
            self.headerActionLineConstraints.removeAll()
        }

        var headerActionLineConstraints = [NSLayoutConstraint]()
        headerActionLineConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[headerActionLine]-0-|", metrics: nil, views: ["headerActionLine": headerActionLine]))
        headerActionLineConstraints.append(NSLayoutConstraint(item: headerActionLine, attribute: .top, relatedBy: .equal, toItem: headerView, attribute: .bottom, multiplier: 1.0, constant: 0))
        if componentView?.superview == nil {
            headerActionLineConstraints.append(NSLayoutConstraint(item: headerActionLine, attribute: .bottom, relatedBy: .equal, toItem: actionSequenceView, attribute: .top, multiplier: 1.0, constant: 0))
        }
        var headerSpacing = alertAppearance.lineWidth
        if customHeaderSpacing > 0 {
            headerSpacing = customHeaderSpacing
        } else if preferredStyle == .actionSheet && alertAppearance.sheetContainerTransparent {
            headerSpacing = alertAppearance.cancelLineWidth
        }
        headerActionLineConstraints.append(NSLayoutConstraint(item: headerActionLine, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: headerSpacing))

        NSLayoutConstraint.activate(headerActionLineConstraints)
        self.headerActionLineConstraints = headerActionLineConstraints
    }

    private func layoutComponentView() {
        guard let componentView, componentView.superview != nil else { return }
        if preferredStyle == .actionSheet && alertAppearance.sheetContainerTransparent {
            componentView.backgroundColor = alertAppearance.containerBackgroundColor
            componentView.layer.cornerRadius = cornerRadius
            componentView.layer.masksToBounds = true
        }

        if self.componentViewConstraints.count > 0 {
            NSLayoutConstraint.deactivate(self.componentViewConstraints)
            self.componentViewConstraints.removeAll()
        }

        var componentViewConstraints = [NSLayoutConstraint]()
        componentViewConstraints.append(NSLayoutConstraint(item: componentView, attribute: .top, relatedBy: .equal, toItem: headerActionLine, attribute: .bottom, multiplier: 1.0, constant: 0))
        componentViewConstraints.append(NSLayoutConstraint(item: componentView, attribute: .bottom, relatedBy: .equal, toItem: componentActionLine, attribute: .top, multiplier: 1.0, constant: 0))
        componentViewConstraints.append(NSLayoutConstraint(item: componentView, attribute: .centerX, relatedBy: .equal, toItem: alertView, attribute: .centerX, multiplier: 1.0, constant: 0))
        if customViewSize.height > 0 {
            let heightConstraint = NSLayoutConstraint(item: componentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: customViewSize.height)
            heightConstraint.priority = .defaultHigh
            componentViewConstraints.append(heightConstraint)
        }
        if customViewSize.width > 0 {
            let maxWidth = maxWidth
            let componentViewWidth = min(maxWidth, customViewSize.width)
            componentViewConstraints.append(NSLayoutConstraint(item: componentView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: componentViewWidth))
        }
        NSLayoutConstraint.activate(componentViewConstraints)
        self.componentViewConstraints = componentViewConstraints
    }

    private func layoutComponentActionLine() {
        guard componentActionLine.superview != nil else { return }
        if self.componentActionLineConstraints.count > 0 {
            NSLayoutConstraint.deactivate(self.componentActionLineConstraints)
            self.componentActionLineConstraints.removeAll()
        }
        var componentActionLineConstraints = [NSLayoutConstraint]()
        componentActionLineConstraints.append(NSLayoutConstraint(item: componentActionLine, attribute: .bottom, relatedBy: .equal, toItem: actionSequenceView, attribute: .top, multiplier: 1.0, constant: 0))
        componentActionLineConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[componentActionLine]-0-|", metrics: nil, views: ["componentActionLine": componentActionLine]))
        componentActionLineConstraints.append(NSLayoutConstraint(item: componentActionLine, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: alertAppearance.lineWidth))
        NSLayoutConstraint.activate(componentActionLineConstraints)
        self.componentActionLineConstraints = componentActionLineConstraints
    }

    private func layoutActionSequenceView() {
        let actionSequenceView = customActionSequenceView ?? actionSequenceView
        guard actionSequenceView.superview != nil else { return }

        if self.actionSequenceViewConstraints.count > 0 {
            NSLayoutConstraint.deactivate(self.actionSequenceViewConstraints)
            self.actionSequenceViewConstraints.removeAll()
        }

        var actionSequenceViewConstraints = [NSLayoutConstraint]()
        if customActionSequenceView == nil {
            actionSequenceViewConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[actionSequenceView]-0-|", metrics: nil, views: ["actionSequenceView": actionSequenceView]))
        } else {
            if customViewSize.width > 0 {
                let maxWidth = maxWidth
                if customViewSize.width > maxWidth {
                    customViewSize.width = maxWidth
                }
                actionSequenceViewConstraints.append(NSLayoutConstraint(item: actionSequenceView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: customViewSize.width))
            }
            if customViewSize.height > 0 {
                let customHeightConstraint = NSLayoutConstraint(item: actionSequenceView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: customViewSize.height)
                customHeightConstraint.priority = .defaultHigh
                actionSequenceViewConstraints.append(customHeightConstraint)
            }
            actionSequenceViewConstraints.append(NSLayoutConstraint(item: actionSequenceView, attribute: .centerX, relatedBy: .equal, toItem: alertView, attribute: .centerX, multiplier: 1.0, constant: 0))
        }
        if headerActionLine.superview == nil {
            actionSequenceViewConstraints.append(NSLayoutConstraint(item: actionSequenceView, attribute: .top, relatedBy: .equal, toItem: alertView, attribute: .top, multiplier: 1.0, constant: 0))
        }
        actionSequenceViewConstraints.append(NSLayoutConstraint(item: actionSequenceView, attribute: .bottom, relatedBy: .equal, toItem: alertView, attribute: .bottom, multiplier: 1.0, constant: 0))

        NSLayoutConstraint.activate(actionSequenceViewConstraints)
        self.actionSequenceViewConstraints = actionSequenceViewConstraints
    }

    private func handleIncompleteTextDisplay() {
        guard !isForceLayout, preferredStyle == .alert else { return }
        for action in actions {
            // 预估按钮宽度
            let preButtonWidth = (min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) - minDistanceToEdges * 2 - alertAppearance.lineWidth * CGFloat(actions.count - 1)) / CGFloat(actions.count) - action.titleEdgeInsets.left - action.titleEdgeInsets.right
            // 如果action的标题文字总宽度，大于按钮的contentRect的宽度，则说明水平排列会导致文字显示不全，此时垂直排列
            if let attributedTitle = action.attributedTitle {
                if ceil(attributedTitle.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: alertAppearance.actionHeight), options: .usesLineFragmentOrigin, context: nil).size.width) > preButtonWidth {
                    _actionAxis = .vertical
                    updateActionAxis()
                    actionSequenceView.setNeedsUpdateConstraints()
                    // 一定要break，只要有一个按钮文字过长就垂直排列
                    break
                }
            } else {
                if ceil((action.title as? NSString)?.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: alertAppearance.actionHeight), options: .usesLineFragmentOrigin, attributes: [.font: action.titleFont as Any], context: nil).size.width ?? 0) > preButtonWidth {
                    _actionAxis = .vertical
                    updateActionAxis()
                    actionSequenceView.setNeedsUpdateConstraints()
                    break
                }
            }
        }
    }

    private func configureHeaderView() {
        if image != nil {
            headerView.imageLimitSize = imageLimitSize
            headerView.imageView.image = image
            headerView.imageView.tintColor = imageTintColor
            headerView.setNeedsUpdateConstraints()
        }
        if (attributedTitle?.length ?? 0) > 0 {
            headerView.titleLabel.attributedText = attributedTitle
            setupPreferredMaxLayoutWidth(for: headerView.titleLabel)
        } else if (title?.count ?? 0) > 0 {
            headerView.titleLabel.text = title
            headerView.titleLabel.font = titleFont
            headerView.titleLabel.textColor = titleColor
            headerView.titleLabel.textAlignment = textAlignment
            setupPreferredMaxLayoutWidth(for: headerView.titleLabel)
        }
        if (attributedMessage?.length ?? 0) > 0 {
            headerView.messageLabel.attributedText = attributedMessage
            setupPreferredMaxLayoutWidth(for: headerView.messageLabel)
        } else if (message?.count ?? 0) > 0 {
            headerView.messageLabel.text = message
            headerView.messageLabel.font = messageFont
            headerView.messageLabel.textColor = messageColor
            headerView.messageLabel.textAlignment = textAlignment
            setupPreferredMaxLayoutWidth(for: headerView.messageLabel)
        }
    }

    private func setupPreferredMaxLayoutWidth(for label: UILabel) {
        if preferredStyle == .alert {
            label.preferredMaxLayoutWidth = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) - minDistanceToEdges * 2 - headerView.contentEdgeInsets.left - headerView.contentEdgeInsets.right
        } else {
            label.preferredMaxLayoutWidth = UIScreen.main.bounds.size.width - headerView.contentEdgeInsets.left - headerView.contentEdgeInsets.right
        }
    }

    @objc private func textFieldDidEndOnExit(_ textField: UITextField) {
        if let textFields,
           let index = textFields.firstIndex(of: textField),
           textFields.count > index + 1 {
            let nextTextField = textFields[index + 1]
            textField.resignFirstResponder()
            nextTextField.becomeFirstResponder()
        }
    }

    @objc private func keyboardFrameWillChange(_ notification: Notification) {
        if !isForceOffset && (_offsetForAlert.y == 0 || (textFields?.last?.isFirstResponder ?? false) || hasCustomTextField) {
            let keyboardEndFrame = (notification.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
            let diff = abs((UIScreen.main.bounds.size.height - keyboardEndFrame.origin.y) * 0.5)
            _offsetForAlert.y = -diff
            makeViewOffset(animated: true)
        }
    }

    private func updateActionAxis() {
        actionSequenceView.axis = _actionAxis
        if _actionAxis == .vertical {
            actionSequenceView.stackViewDistribution = .fillProportionally
        } else {
            actionSequenceView.stackViewDistribution = .fillEqually
        }
    }

    private func makeViewOffset(animated: Bool) {
        if !isBeingPresented && !isBeingDismissed {
            layoutAlertControllerView()
            if animated {
                UIView.animate(withDuration: 0.25) {
                    self.view.superview?.layoutIfNeeded()
                }
            }
        }
    }

    private func sizeForCustomView(_ customView: UIView) -> CGSize {
        customView.layoutIfNeeded()
        let settingSize = customView.frame.size
        let fittingSize = customView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: max(settingSize.width, fittingSize.width), height: max(settingSize.height, fittingSize.height))
    }

    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        AlertAnimation(isPresenting: true)
    }

    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        view.endEditing(true)
        return AlertAnimation(isPresenting: false)
    }

    open func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        AlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

/// 自定义弹窗展示控制器
open class AlertPresentationController: UIPresentationController {
    private var overlayView: AlertOverlayView {
        if let overlayView = _overlayView {
            return overlayView
        }

        let overlayView = AlertOverlayView()
        _overlayView = overlayView
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapOverlayView))
        overlayView.addGestureRecognizer(tap)
        containerView?.addSubview(overlayView)
        return overlayView
    }

    private weak var _overlayView: AlertOverlayView?

    override public init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override open func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        overlayView.frame = containerView?.bounds ?? .zero
    }

    override open func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
    }

    override open func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let alertController = presentedViewController as? AlertController else { return }

        overlayView.setAppearanceStyle(alertController.backgroundViewAppearanceStyle, alpha: alertController.backgroundViewAlpha)
        // 遮罩的alpha值从0～1变化，UIViewControllerTransitionCoordinator协是一个过渡协调器，当执行模态过渡或push过渡时，可以对视图中的其他部分做动画
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate { [weak self] _ in
                self?.overlayView.alpha = 1.0
            }
        } else {
            overlayView.alpha = 1.0
        }
        alertController.delegate?.willPresentAlertController?(alertController)
    }

    override open func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        guard let alertController = presentedViewController as? AlertController else { return }

        alertController.delegate?.didPresentAlertController?(alertController)
    }

    override open func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        // 遮罩的alpha值从1～0变化，UIViewControllerTransitionCoordinator协议执行动画可以保证和转场动画同步
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate { [weak self] _ in
                self?.overlayView.alpha = 0
            }
        } else {
            overlayView.alpha = 0
        }
        if let alertController = presentedViewController as? AlertController {
            alertController.delegate?.willDismissAlertController?(alertController)
        }
    }

    override open func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            _overlayView?.removeFromSuperview()
            _overlayView = nil
        }
        if let alertController = presentedViewController as? AlertController {
            alertController.delegate?.didDismissAlertController?(alertController)
        }
    }

    override open var frameOfPresentedViewInContainerView: CGRect {
        presentedView?.frame ?? .zero
    }

    @objc func tapOverlayView() {
        guard let alertController = presentedViewController as? AlertController else { return }
        if alertController.tapBackgroundViewDismiss {
            alertController.dismiss(animated: true, completion: alertController.dismissCompletion)
        }
    }
}

/// 自定义弹窗动画
open class AlertAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    private var presenting = false

    public init(isPresenting: Bool) {
        super.init()
        self.presenting = isPresenting
    }

    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.25
    }

    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if presenting {
            presentAnimationTransition(transitionContext)
        } else {
            dismissAnimationTransition(transitionContext)
        }
    }

    private func presentAnimationTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let alertController = transitionContext.viewController(forKey: .to) as? AlertController else { return }

        switch alertController.animationType {
        case .fromBottom:
            raiseUpWhenPresent(for: alertController, transitionContext: transitionContext)
        case .fromTop:
            dropDownWhenPresent(for: alertController, transitionContext: transitionContext)
        case .fromRight:
            fromRightWhenPresent(for: alertController, transitionContext: transitionContext)
        case .fromLeft:
            fromLeftWhenPresent(for: alertController, transitionContext: transitionContext)
        case .shrink:
            shrinkWhenPresent(for: alertController, transitionContext: transitionContext)
        case .expand:
            expandWhenPresent(for: alertController, transitionContext: transitionContext)
        case .fade:
            alphaWhenPresent(for: alertController, transitionContext: transitionContext)
        case .none:
            noneWhenPresent(for: alertController, transitionContext: transitionContext)
        default:
            break
        }
    }

    private func dismissAnimationTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let alertController = transitionContext.viewController(forKey: .from) as? AlertController else { return }

        switch alertController.animationType {
        case .fromBottom:
            dismissCorrespondingRaiseUp(for: alertController, transitionContext: transitionContext)
        case .fromTop:
            dismissCorrespondingDropDown(for: alertController, transitionContext: transitionContext)
        case .fromRight:
            dismissCorrespondingFromRight(for: alertController, transitionContext: transitionContext)
        case .fromLeft:
            dismissCorrespondingFromLeft(for: alertController, transitionContext: transitionContext)
        case .shrink:
            dismissCorrespondingShrink(for: alertController, transitionContext: transitionContext)
        case .expand:
            dismissCorrespondingExpand(for: alertController, transitionContext: transitionContext)
        case .fade:
            dismissCorrespondingAlpha(for: alertController, transitionContext: transitionContext)
        case .none:
            dismissCorrespondingNone(for: alertController, transitionContext: transitionContext)
        default:
            break
        }
    }

    // 从底部弹出
    private func raiseUpWhenPresent(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.addSubview(alertController.view)

        // 标记需要刷新布局
        containerView.setNeedsLayout()
        // 在有标记刷新布局的情况下立即布局，这行代码很重要，第一：立即布局会立即调用AlertController的viewWillLayoutSubviews的方法，第二：立即布局后可以获取到alertController.view的frame,不仅如此，走了viewWillLayoutSubviews键盘就会弹出，此后可以获取到alertController.offset
        containerView.layoutIfNeeded()

        // 这3行代码不能放在[containerView layoutIfNeeded]之前，如果放在之前，[containerView layoutIfNeeded]强制布局后会将以下设置的frame覆盖
        var controlViewFrame = alertController.view.frame
        controlViewFrame.origin.y = UIScreen.main.bounds.height
        alertController.view.frame = controlViewFrame

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut) {
            var controlViewFrame = alertController.view.frame
            if alertController.preferredStyle == .actionSheet {
                controlViewFrame.origin.y = UIScreen.main.bounds.height - controlViewFrame.height
            } else {
                controlViewFrame.origin.y = (UIScreen.main.bounds.height - controlViewFrame.height) / 2.0
                self.offsetCenter(alertController)
            }
            alertController.view.frame = controlViewFrame
        } completion: { finished in
            transitionContext.completeTransition(finished)
            alertController.layoutAlertControllerView()
        }
    }

    private func dismissCorrespondingRaiseUp(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
            var controlViewFrame = alertController.view.frame
            controlViewFrame.origin.y = UIScreen.main.bounds.height
            alertController.view.frame = controlViewFrame
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }

    // 从右边弹出
    private func fromRightWhenPresent(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.addSubview(alertController.view)

        // 标记需要刷新布局
        containerView.setNeedsLayout()
        // 在有标记刷新布局的情况下立即布局，这行代码很重要，第一：立即布局会立即调用AlertController的viewWillLayoutSubviews的方法，第二：立即布局后可以获取到alertController.view的frame,不仅如此，走了viewWillLayoutSubviews键盘就会弹出，此后可以获取到alertController.offset
        containerView.layoutIfNeeded()

        // 这3行代码不能放在[containerView layoutIfNeeded]之前，如果放在之前，[containerView layoutIfNeeded]强制布局后会将以下设置的frame覆盖
        var controlViewFrame = alertController.view.frame
        controlViewFrame.origin.x = UIScreen.main.bounds.width
        alertController.view.frame = controlViewFrame
        if alertController.preferredStyle == .alert {
            offsetCenter(alertController)
        }

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut) {
            var controlViewFrame = alertController.view.frame
            if alertController.preferredStyle == .actionSheet {
                controlViewFrame.origin.x = UIScreen.main.bounds.width - controlViewFrame.width
            } else {
                controlViewFrame.origin.x = (UIScreen.main.bounds.width - controlViewFrame.width) / 2.0
            }
            alertController.view.frame = controlViewFrame
        } completion: { finished in
            transitionContext.completeTransition(finished)
            alertController.layoutAlertControllerView()
        }
    }

    private func dismissCorrespondingFromRight(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
            var controlViewFrame = alertController.view.frame
            controlViewFrame.origin.x = UIScreen.main.bounds.width
            alertController.view.frame = controlViewFrame
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }

    // 从左边弹出
    private func fromLeftWhenPresent(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.addSubview(alertController.view)

        // 标记需要刷新布局
        containerView.setNeedsLayout()
        // 在有标记刷新布局的情况下立即布局，这行代码很重要，第一：立即布局会立即调用AlertController的viewWillLayoutSubviews的方法，第二：立即布局后可以获取到alertController.view的frame,不仅如此，走了viewWillLayoutSubviews键盘就会弹出，此后可以获取到alertController.offset
        containerView.layoutIfNeeded()

        // 这3行代码不能放在[containerView layoutIfNeeded]之前，如果放在之前，[containerView layoutIfNeeded]强制布局后会将以下设置的frame覆盖
        var controlViewFrame = alertController.view.frame
        controlViewFrame.origin.x = -controlViewFrame.size.width
        alertController.view.frame = controlViewFrame
        if alertController.preferredStyle == .alert {
            offsetCenter(alertController)
        }

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut) {
            var controlViewFrame = alertController.view.frame
            if alertController.preferredStyle == .actionSheet {
                controlViewFrame.origin.x = 0
            } else {
                controlViewFrame.origin.x = (UIScreen.main.bounds.width - controlViewFrame.width) / 2.0
            }
            alertController.view.frame = controlViewFrame
        } completion: { finished in
            transitionContext.completeTransition(finished)
            alertController.layoutAlertControllerView()
        }
    }

    private func dismissCorrespondingFromLeft(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
            var controlViewFrame = alertController.view.frame
            controlViewFrame.origin.x = -controlViewFrame.size.width
            alertController.view.frame = controlViewFrame
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }

    // 从顶部弹出
    private func dropDownWhenPresent(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.addSubview(alertController.view)

        // 标记需要刷新布局
        containerView.setNeedsLayout()
        // 在有标记刷新布局的情况下立即布局，这行代码很重要，第一：立即布局会立即调用AlertController的viewWillLayoutSubviews的方法，第二：立即布局后可以获取到alertController.view的frame,不仅如此，走了viewWillLayoutSubviews键盘就会弹出，此后可以获取到alertController.offset
        containerView.layoutIfNeeded()

        // 这3行代码不能放在[containerView layoutIfNeeded]之前，如果放在之前，[containerView layoutIfNeeded]强制布局后会将以下设置的frame覆盖
        var controlViewFrame = alertController.view.frame
        controlViewFrame.origin.y = -controlViewFrame.size.height
        alertController.view.frame = controlViewFrame

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut) {
            var controlViewFrame = alertController.view.frame
            if alertController.preferredStyle == .actionSheet {
                controlViewFrame.origin.y = 0
            } else {
                controlViewFrame.origin.y = (UIScreen.main.bounds.height - controlViewFrame.height) / 2.0
                self.offsetCenter(alertController)
            }
            alertController.view.frame = controlViewFrame
        } completion: { finished in
            transitionContext.completeTransition(finished)
            alertController.layoutAlertControllerView()
        }
    }

    private func dismissCorrespondingDropDown(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
            var controlViewFrame = alertController.view.frame
            controlViewFrame.origin.y = -controlViewFrame.size.height
            alertController.view.frame = controlViewFrame
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }

    // Alpha动画
    private func alphaWhenPresent(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.addSubview(alertController.view)

        // 标记需要刷新布局
        containerView.setNeedsLayout()
        // 在有标记刷新布局的情况下立即布局，这行代码很重要，第一：立即布局会立即调用AlertController的viewWillLayoutSubviews的方法，第二：立即布局后可以获取到alertController.view的frame,不仅如此，走了viewWillLayoutSubviews键盘就会弹出，此后可以获取到alertController.offset
        containerView.layoutIfNeeded()

        alertController.view.alpha = 0
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveLinear) {
            self.offsetCenter(alertController)
            alertController.view.alpha = 1.0
        } completion: { finished in
            transitionContext.completeTransition(finished)
            alertController.layoutAlertControllerView()
        }
    }

    private func dismissCorrespondingAlpha(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveLinear) {
            alertController.view.alpha = 0
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }

    // 发散动画
    private func expandWhenPresent(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.addSubview(alertController.view)

        // 标记需要刷新布局
        containerView.setNeedsLayout()
        // 在有标记刷新布局的情况下立即布局，这行代码很重要，第一：立即布局会立即调用AlertController的viewWillLayoutSubviews的方法，第二：立即布局后可以获取到alertController.view的frame,不仅如此，走了viewWillLayoutSubviews键盘就会弹出，此后可以获取到alertController.offset
        containerView.layoutIfNeeded()

        alertController.view.transform = .init(scaleX: 0.9, y: 0.9)
        alertController.view.alpha = 0
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveLinear) {
            self.offsetCenter(alertController)
            alertController.view.transform = .identity
            alertController.view.alpha = 1.0
        } completion: { finished in
            transitionContext.completeTransition(finished)
            alertController.layoutAlertControllerView()
        }
    }

    private func dismissCorrespondingExpand(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveLinear) {
            alertController.view.transform = .identity
            alertController.view.alpha = 0
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }

    // 收缩动画
    private func shrinkWhenPresent(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.addSubview(alertController.view)

        // 标记需要刷新布局
        containerView.setNeedsLayout()
        // 在有标记刷新布局的情况下立即布局，这行代码很重要，第一：立即布局会立即调用AlertController的viewWillLayoutSubviews的方法，第二：立即布局后可以获取到alertController.view的frame,不仅如此，走了viewWillLayoutSubviews键盘就会弹出，此后可以获取到alertController.offset
        containerView.layoutIfNeeded()

        alertController.view.transform = .init(scaleX: 1.1, y: 1.1)
        alertController.view.alpha = 0
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveLinear) {
            self.offsetCenter(alertController)
            alertController.view.transform = .identity
            alertController.view.alpha = 1.0
        } completion: { finished in
            transitionContext.completeTransition(finished)
            alertController.layoutAlertControllerView()
        }
    }

    private func dismissCorrespondingShrink(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        dismissCorrespondingExpand(for: alertController, transitionContext: transitionContext)
    }

    // 无动画
    private func noneWhenPresent(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.addSubview(alertController.view)
        transitionContext.completeTransition(transitionContext.isAnimated)
    }

    private func dismissCorrespondingNone(for alertController: AlertController, transitionContext: UIViewControllerContextTransitioning) {
        transitionContext.completeTransition(transitionContext.isAnimated)
    }

    private func offsetCenter(_ alertController: AlertController) {
        guard alertController.offsetForAlert != .zero else { return }

        var controlViewCenter = alertController.view.center
        controlViewCenter.x = UIScreen.main.bounds.width / 2.0 + alertController.offsetForAlert.x
        controlViewCenter.y = UIScreen.main.bounds.height / 2.0 + alertController.offsetForAlert.y
        alertController.view.center = controlViewCenter
    }
}

// MARK: - AlertAction
/// 弹窗动作样式枚举
public enum AlertActionStyle: Int, Sendable {
    /// 默认样式
    case `default` = 0
    /// 取消样式,字体加粗
    case cancel
    /// 红色字体样式
    case destructive
}

/// 弹窗动作
@MainActor public class AlertAction: NSObject {
    /// action的标题
    public var title: String? {
        didSet { propertyChangedBlock?(self, true) }
    }

    /// action的富文本标题
    public var attributedTitle: NSAttributedString? {
        didSet { propertyChangedBlock?(self, true) }
    }

    /// action的图标，位于title的左边
    public var image: UIImage? {
        didSet { propertyChangedBlock?(self, true) }
    }

    /// title跟image之间的间距
    public var imageTitleSpacing: CGFloat = 0 {
        didSet { propertyChangedBlock?(self, true) }
    }

    /// 渲染颜色,当外部的图片使用了UIImageRenderingModeAlwaysTemplate时,使用该属性可改变图片的颜色
    public var tintColor: UIColor?

    /// 是否能点击,默认为YES
    public var isEnabled: Bool = true {
        didSet {
            let preferred = isPreferred
            isPreferred = preferred

            propertyChangedBlock?(self, false)
        }
    }

    /// 是否是首选动作,默认为NO
    public var isPreferred: Bool = false {
        didSet {
            if attributedTitle != nil || (title?.count ?? 0) < 1 || !alertAppearance.actionEnabled { return }

            var titleColor: UIColor?
            if !isEnabled {
                titleColor = alertAppearance.disabledActionColor
            } else if isPreferred {
                titleColor = alertAppearance.preferredActionColor
            } else if style == .destructive {
                titleColor = alertAppearance.destructiveActionColor
            } else if style == .cancel {
                titleColor = alertAppearance.cancelActionColor
            } else {
                titleColor = alertAppearance.actionColor
            }
            if titleColor != nil {
                self.titleColor = titleColor
            }
        }
    }

    /// action的标题颜色,这个颜色只是普通文本的颜色，富文本颜色需要用NSForegroundColorAttributeName
    public var titleColor: UIColor? {
        didSet { propertyChangedBlock?(self, false) }
    }

    /// action的标题字体,如果文字太长显示不全，会自动改变字体自适应按钮宽度，最多压缩文字为原来的0.5倍封顶
    public var titleFont: UIFont? {
        didSet { propertyChangedBlock?(self, true) }
    }

    /// action的标题的内边距，如果在不改变字体的情况下想增大action的高度，可以设置该属性的top和bottom值,默认UIEdgeInsetsMake(0, 15, 0, 15)
    public var titleEdgeInsets: UIEdgeInsets = .init(top: 0, left: 15, bottom: 0, right: 15)

    /// 样式
    public private(set) var style: AlertActionStyle = .default

    /// 自定义样式，默认为样式单例
    public var alertAppearance: AlertControllerAppearance {
        appearance ?? AlertControllerAppearance.appearance
    }

    var appearance: AlertControllerAppearance?
    var handler: ((AlertAction) -> Void)?
    var propertyChangedBlock: ((_ action: AlertAction, _ needUpdateConstraints: Bool) -> Void)?

    public init(title: String?, style: AlertActionStyle, appearance: AlertControllerAppearance? = nil, handler: ((AlertAction) -> Void)?) {
        super.init()
        self.appearance = appearance
        self.title = title
        self.style = style
        self.handler = handler

        if style == .destructive {
            self.titleColor = alertAppearance.alertRedColor
            self.titleFont = alertAppearance.actionFont
        } else if style == .cancel {
            self.titleColor = alertAppearance.titleDynamicColor
            self.titleFont = alertAppearance.actionBoldFont
        } else {
            self.titleColor = alertAppearance.titleDynamicColor
            self.titleFont = alertAppearance.actionFont
        }
    }

    override public init() {
        super.init()

        self.titleColor = alertAppearance.titleDynamicColor
        self.titleFont = alertAppearance.actionFont
    }
}

// MARK: - AlertView
class AlertOverlayView: UIView {
    private weak var effectView: UIVisualEffectView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAppearanceStyle(_ style: UIBlurEffect.Style?, alpha: CGFloat) {
        if let style {
            backgroundColor = UIColor.clear
            let blurEffect = UIBlurEffect(style: style)
            let effectView = UIVisualEffectView(effect: blurEffect)
            effectView.frame = bounds
            effectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            effectView.isUserInteractionEnabled = false
            effectView.alpha = alpha
            addSubview(effectView)
            self.effectView = effectView
        } else {
            effectView?.removeFromSuperview()
            effectView = nil
            backgroundColor = UIColor(white: 0, alpha: alpha < 0 ? 0.5 : alpha)
            self.alpha = 0
        }
    }
}

class AlertActionItemSeparatorView: UIView {
    var customBackgroundColor: UIColor?
    private var appearance: AlertControllerAppearance?

    private var alertAppearance: AlertControllerAppearance {
        appearance ?? AlertControllerAppearance.appearance
    }

    init(appearance: AlertControllerAppearance?) {
        super.init(frame: .zero)
        self.appearance = appearance
        backgroundColor = alertAppearance.lineColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if customBackgroundColor != nil {
            backgroundColor = customBackgroundColor
        } else if min(frame.width, frame.height) > alertAppearance.lineWidth {
            backgroundColor = alertAppearance.cancelLineColor
        } else {
            backgroundColor = alertAppearance.lineColor
        }
    }
}

class AlertHeaderScrollView: UIScrollView {
    var headerViewSafeAreaDidChangedBlock: (() -> Void)?
    var imageLimitSize: CGSize = .zero
    var contentEdgeInsets: UIEdgeInsets = .zero
    private var textFields: [UITextField] = []
    private var appearance: AlertControllerAppearance?

    private var alertAppearance: AlertControllerAppearance {
        appearance ?? AlertControllerAppearance.appearance
    }

    private var appearanceContentInsets: UIEdgeInsets {
        let contentInsets = alertAppearance.contentInsets
        return UIEdgeInsets(top: ceil(contentInsets.top), left: ceil(contentInsets.left), bottom: ceil(contentInsets.bottom), right: ceil(contentInsets.right))
    }

    private lazy var contentView: UIView = {
        let result = UIView()
        result.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(result)
        return result
    }()

    var titleLabel: UILabel {
        if let result = _titleLabel {
            return result
        }

        let result = UILabel()
        result.font = UIFont.boldSystemFont(ofSize: 18)
        result.textAlignment = .center
        result.textColor = alertAppearance.titleDynamicColor
        result.numberOfLines = 0
        result.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(result)
        _titleLabel = result
        return result
    }

    private weak var _titleLabel: UILabel?

    var messageLabel: UILabel {
        if let result = _messageLabel {
            return result
        }

        let result = UILabel()
        result.font = UIFont.systemFont(ofSize: 18)
        result.textAlignment = .center
        result.textColor = alertAppearance.grayColor
        result.numberOfLines = 0
        result.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(result)
        _messageLabel = result
        return result
    }

    private weak var _messageLabel: UILabel?

    var imageView: UIImageView {
        if let result = _imageView {
            return result
        }

        let result = UIImageView()
        result.translatesAutoresizingMaskIntoConstraints = false
        contentView.insertSubview(result, at: 0)
        _imageView = result
        return result
    }

    private weak var _imageView: UIImageView?

    private var textFieldView: UIStackView {
        if let result = _textFieldView {
            return result
        }

        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.distribution = .fillEqually
        result.axis = .vertical
        result.spacing = alertAppearance.textFieldSpacing
        if !textFields.isEmpty {
            contentView.addSubview(result)
        }
        _textFieldView = result
        return result
    }

    private weak var _textFieldView: UIStackView?

    init(appearance: AlertControllerAppearance?) {
        super.init(frame: .zero)
        self.appearance = appearance
        showsHorizontalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        self.contentEdgeInsets = appearanceContentInsets
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let resolvedColor = alertAppearance.lineColor?.resolvedColor(with: traitCollection)
        for textField in textFields {
            textField.layer.borderColor = resolvedColor?.cgColor
        }
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        let contentInsets = appearanceContentInsets
        let safeTop = safeAreaInsets.top < contentInsets.top ? contentInsets.top : safeAreaInsets.top + 10
        let safeLeft = safeAreaInsets.left < contentInsets.left ? contentInsets.left : safeAreaInsets.left
        let safeBottom = safeAreaInsets.bottom < contentInsets.bottom ? contentInsets.bottom : safeAreaInsets.bottom + 6
        let safeRight = safeAreaInsets.right < contentInsets.right ? contentInsets.right : safeAreaInsets.right
        contentEdgeInsets = UIEdgeInsets(top: safeTop, left: safeLeft, bottom: safeBottom, right: safeRight)
        // 更新Label的最大预估宽度
        headerViewSafeAreaDidChangedBlock?()
        setNeedsUpdateConstraints()
    }

    override func updateConstraints() {
        super.updateConstraints()
        NSLayoutConstraint.deactivate(constraints)
        NSLayoutConstraint.deactivate(contentView.constraints)

        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[contentView]-0-|", metrics: nil, views: ["contentView": contentView]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[contentView]-0-|", metrics: nil, views: ["contentView": contentView]))
        NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0).isActive = true
        let equalHeightConstraint = NSLayoutConstraint(item: contentView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0)
        equalHeightConstraint.priority = .init(998)
        equalHeightConstraint.isActive = true

        let imageView = _imageView
        let textFieldView = _textFieldView
        let marginInsets = contentEdgeInsets

        if let imageView, let image = imageView.image {
            var imageViewConstraints: [NSLayoutConstraint] = []
            imageViewConstraints.append(NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: min(image.size.width, imageLimitSize.width)))
            imageViewConstraints.append(NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: min(image.size.height, imageLimitSize.height)))
            imageViewConstraints.append(NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1.0, constant: 0))
            imageViewConstraints.append(NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: marginInsets.top))
            if (_titleLabel?.text?.count ?? 0) > 0 || (_titleLabel?.attributedText?.length ?? 0) > 0 {
                imageViewConstraints.append(NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: _titleLabel, attribute: .top, multiplier: 1.0, constant: -alertAppearance.imageTitleSpacing))
            } else if (_messageLabel?.text?.count ?? 0) > 0 || (_messageLabel?.attributedText?.length ?? 0) > 0 {
                imageViewConstraints.append(NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: _messageLabel, attribute: .top, multiplier: 1.0, constant: -alertAppearance.imageTitleSpacing))
            } else if textFields.count > 0 {
                imageViewConstraints.append(NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: textFieldView, attribute: .top, multiplier: 1.0, constant: -alertAppearance.imageTitleSpacing))
            } else {
                imageViewConstraints.append(NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: -marginInsets.bottom))
            }
            NSLayoutConstraint.activate(imageViewConstraints)
        }

        var titleLabelConstraints: [NSLayoutConstraint] = []
        var labels: [UILabel] = []
        if let titleLabel = _titleLabel, (titleLabel.text?.count ?? 0) > 0 || (titleLabel.attributedText?.length ?? 0) > 0 {
            labels.insert(titleLabel, at: 0)
        }
        if let messageLabel = _messageLabel, (messageLabel.text?.count ?? 0) > 0 || (messageLabel.attributedText?.length ?? 0) > 0 {
            labels.append(messageLabel)
        }
        for (idx, label) in labels.enumerated() {
            titleLabelConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==leftMargin)-[label]-(==rightMargin)-|", metrics: ["leftMargin": NSNumber(value: marginInsets.left), "rightMargin": NSNumber(value: marginInsets.right)], views: ["label": label]))
            if idx == 0 {
                if imageView?.image == nil {
                    titleLabelConstraints.append(NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: marginInsets.top))
                }
            }
            if idx == labels.count - 1 {
                if textFields.count > 0 {
                    titleLabelConstraints.append(NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: textFieldView, attribute: .top, multiplier: 1.0, constant: -(alertAppearance.textFieldTopMargin > 0 ? alertAppearance.textFieldTopMargin : marginInsets.bottom)))
                } else {
                    titleLabelConstraints.append(NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: -marginInsets.bottom))
                }
            }
            if idx > 0 {
                titleLabelConstraints.append(NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: labels[idx - 1], attribute: .bottom, multiplier: 1.0, constant: alertAppearance.titleMessageSpacing))
            }
        }
        NSLayoutConstraint.activate(titleLabelConstraints)

        if textFields.count > 0, let textFieldView {
            var textFieldViewConstraints: [NSLayoutConstraint] = []
            if labels.count < 1, imageView?.image == nil {
                textFieldViewConstraints.append(NSLayoutConstraint(item: textFieldView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: marginInsets.top))
            }
            textFieldViewConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==leftMargin)-[textFieldView]-(==rightMargin)-|", metrics: ["leftMargin": NSNumber(value: marginInsets.left), "rightMargin": NSNumber(value: marginInsets.right)], views: ["textFieldView": textFieldView]))
            textFieldViewConstraints.append(NSLayoutConstraint(item: textFieldView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: -marginInsets.bottom))
            NSLayoutConstraint.activate(textFieldViewConstraints)
        }

        // systemLayoutSizeFittingSize:方法获取子控件撑起contentView后的高度，如果子控件是UILabel，那么子label必须设置preferredMaxLayoutWidth,否则当label多行文本时计算不准确
        NSLayoutConstraint(item: contentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height).isActive = true
    }

    func addTextField(_ textField: UITextField) {
        textFields.append(textField)
        textFieldView.addArrangedSubview(textField)
        NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: alertAppearance.textFieldHeight).isActive = true
        setNeedsUpdateConstraints()
    }
}

class AlertControllerActionView: UIView {
    var afterSpacing: CGFloat = 0
    private weak var target: AnyObject?
    private var methodAction: Selector?
    private var actionButtonConstraints: [NSLayoutConstraint] = []
    private var appearance: AlertControllerAppearance?

    var action: AlertAction? {
        didSet {
            guard let action else { return }

            actionButton.titleLabel?.font = action.titleFont
            if action.isEnabled {
                actionButton.setTitleColor(action.titleColor, for: .normal)
            } else {
                actionButton.setTitleColor(action.titleColor?.withAlphaComponent(0.4), for: .normal)
            }

            // 注意不能赋值给按钮的titleEdgeInsets，当只有文字时，按钮的titleEdgeInsets设置top和bottom值无效
            actionButton.contentEdgeInsets = action.titleEdgeInsets
            actionButton.isEnabled = action.isEnabled
            actionButton.tintColor = action.tintColor
            if let attributedTitle = action.attributedTitle {
                // 这里之所以要设置按钮颜色为黑色，是因为如果外界在addAction:之后设置按钮的富文本，那么富文本的颜色在没有采用NSForegroundColorAttributeName的情况下会自动读取按钮上普通文本的颜色，在addAction:之前设置会保持默认色(黑色)，为了在addAction:前后设置富文本保持统一，这里先将按钮置为黑色，富文本就会是黑色
                actionButton.setTitleColor(alertAppearance.titleDynamicColor, for: .normal)
                if attributedTitle.string.contains("\n") || attributedTitle.string.contains("\r") {
                    actionButton.titleLabel?.lineBreakMode = .byWordWrapping
                }
                actionButton.setAttributedTitle(attributedTitle, for: .normal)

                // 设置完富文本之后，还原按钮普通文本的颜色，其实这行代码加不加都不影响，只是为了让按钮普通文本的颜色保持跟action.titleColor一致
                actionButton.setTitleColor(action.titleColor, for: .normal)
            } else {
                let actionTitle = action.title ?? ""
                if actionTitle.contains("\n") || actionTitle.contains("\r") {
                    actionButton.titleLabel?.lineBreakMode = .byWordWrapping
                }
                actionButton.setTitle(action.title, for: .normal)
            }
            actionButton.setImage(action.image, for: .normal)
            actionButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: action.imageTitleSpacing, bottom: 0, right: -action.imageTitleSpacing)
            actionButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -action.imageTitleSpacing, bottom: 0, right: action.imageTitleSpacing)
        }
    }

    var alertAppearance: AlertControllerAppearance {
        appearance ?? AlertControllerAppearance.appearance
    }

    lazy var actionButton: UIButton = {
        let result = UIButton(type: .custom)
        result.backgroundColor = alertAppearance.normalColor
        result.translatesAutoresizingMaskIntoConstraints = false
        result.titleLabel?.textAlignment = .center
        result.titleLabel?.adjustsFontSizeToFitWidth = true
        result.titleLabel?.baselineAdjustment = .alignCenters
        result.titleLabel?.minimumScaleFactor = 0.5
        // 手指按下然后在按钮有效事件范围内抬起
        result.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        // 手指按下或者手指按下后往外拽再往内拽
        result.addTarget(self, action: #selector(touchDown(_:)), for: [.touchDown, .touchDragInside])
        // 手指被迫停止、手指按下后往外拽或者取消，取消的可能性:比如点击的那一刻突然来电话
        result.addTarget(self, action: #selector(touchDragExit(_:)), for: [.touchDragExit, .touchUpOutside, .touchCancel])
        self.addSubview(result)
        return result
    }()

    init(appearance: AlertControllerAppearance?) {
        super.init(frame: .zero)
        self.appearance = appearance
        self.afterSpacing = alertAppearance.lineWidth
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        let actionTitleInsets = action?.titleEdgeInsets ?? .zero
        actionButton.contentEdgeInsets = UIEdgeInsets(top: safeAreaInsets.top + actionTitleInsets.top, left: safeAreaInsets.left + actionTitleInsets.left, bottom: safeAreaInsets.bottom + actionTitleInsets.bottom, right: safeAreaInsets.right + actionTitleInsets.right)
        setNeedsUpdateConstraints()
    }

    override func updateConstraints() {
        super.updateConstraints()

        if self.actionButtonConstraints.count > 0 {
            NSLayoutConstraint.deactivate(self.actionButtonConstraints)
            self.actionButtonConstraints.removeAll()
        }

        var actionButtonConstraints: [NSLayoutConstraint] = []
        actionButtonConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[actionButton]-0-|", metrics: nil, views: ["actionButton": actionButton]))
        actionButtonConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[actionButton]-0-|", metrics: nil, views: ["actionButton": actionButton]))
        // 按钮必须确认高度，因为其父视图及父视图的父视图乃至根视图都没有设置高度，而且必须用NSLayoutRelationEqual，如果用NSLayoutRelationGreaterThanOrEqual,虽然也能撑起父视图，但是当某个按钮的高度有所变化以后，stackView会将其余按钮按的高度同比增减。
        let labelH = actionButton.titleLabel?.intrinsicContentSize.height ?? 0
        let topBottomInsetsSum = actionButton.contentEdgeInsets.top + actionButton.contentEdgeInsets.bottom
        // 文字的上下间距之和,等于FW_ACTION_HEIGHT-默认字体大小,这是为了保证文字上下有一个固定间距值，不至于使文字靠按钮太紧，,由于按钮内容默认垂直居中，所以最终的顶部或底部间距为topBottom_marginSum/2.0,这个间距，几乎等于18号字体时，最小高度为49时的上下间距
        let topBottomMarginSum = alertAppearance.actionHeight - (alertAppearance.actionFont?.lineHeight ?? 0)
        let buttonH = labelH + topBottomInsetsSum + topBottomMarginSum
        var relation: NSLayoutConstraint.Relation = .equal
        if let stackView = superview as? UIStackView, stackView.axis == .horizontal {
            relation = .greaterThanOrEqual
        }
        let buttonHConstraint = NSLayoutConstraint(item: actionButton, attribute: .height, relatedBy: relation, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: buttonH)
        buttonHConstraint.priority = .init(999)
        actionButtonConstraints.append(buttonHConstraint)
        let minHConstraint = NSLayoutConstraint(item: actionButton, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: alertAppearance.actionHeight + topBottomInsetsSum)
        minHConstraint.priority = .required
        addConstraints(actionButtonConstraints)
        self.actionButtonConstraints = actionButtonConstraints
    }

    func addTarget(_ target: AnyObject?, action methodAction: Selector?) {
        self.target = target
        self.methodAction = methodAction
    }

    @objc private func touchUpInside(_ sender: UIButton) {
        if let target, let methodAction, target.responds(to: methodAction) {
            _ = target.perform(methodAction, with: self)
        }
    }

    @objc private func touchDown(_ sender: UIButton) {
        sender.backgroundColor = alertAppearance.selectedColor
    }

    @objc private func touchDragExit(_ sender: UIButton) {
        sender.backgroundColor = alertAppearance.normalColor
    }
}

class AlertActionSequenceView: UIView {
    var preferredStyle: AlertControllerStyle = .actionSheet
    var cornerRadius: CGFloat = 0
    var cancelAction: AlertAction?
    var actions: [AlertAction] = []
    var stackViewDistribution: UIStackView.Distribution = .fillProportionally {
        didSet {
            stackView.distribution = stackViewDistribution
            setNeedsUpdateConstraints()
        }
    }

    var axis: NSLayoutConstraint.Axis = .vertical {
        didSet {
            stackView.axis = axis
            setNeedsUpdateConstraints()
        }
    }

    var buttonClickedInActionViewBlock: ((_ index: Int, _ actionView: AlertControllerActionView) -> Void)?
    private var actionLineConstraints: [NSLayoutConstraint] = []
    private var appearance: AlertControllerAppearance?

    private var alertAppearance: AlertControllerAppearance {
        appearance ?? AlertControllerAppearance.appearance
    }

    private lazy var scrollView: UIScrollView = {
        let result = UIScrollView()
        result.showsHorizontalScrollIndicator = false
        result.translatesAutoresizingMaskIntoConstraints = false
        result.contentInsetAdjustmentBehavior = .never
        result.bounces = false
        if preferredStyle == .actionSheet, alertAppearance.sheetContainerTransparent {
            result.backgroundColor = alertAppearance.containerBackgroundColor
            result.layer.cornerRadius = cornerRadius
            result.layer.masksToBounds = true
        }
        if (cancelAction != nil && actions.count > 1) || (cancelAction == nil && actions.count > 0) {
            addSubview(result)
        }
        return result
    }()

    private lazy var contentView: UIView = {
        let result = UIView()
        result.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(result)
        return result
    }()

    lazy var cancelView: UIView = {
        let result = UIView()
        result.translatesAutoresizingMaskIntoConstraints = false
        if preferredStyle == .actionSheet, alertAppearance.sheetContainerTransparent {
            result.backgroundColor = alertAppearance.containerBackgroundColor
            result.layer.cornerRadius = cornerRadius
            result.layer.masksToBounds = true
        }
        if cancelAction != nil {
            addSubview(result)
        }
        return result
    }()

    private lazy var cancelActionLine: AlertActionItemSeparatorView = {
        let result = AlertActionItemSeparatorView(appearance: appearance)
        result.translatesAutoresizingMaskIntoConstraints = false
        if preferredStyle == .actionSheet, alertAppearance.sheetContainerTransparent {
            result.customBackgroundColor = .clear
        }
        if cancelView.superview != nil, scrollView.superview != nil {
            addSubview(result)
        }
        return result
    }()

    lazy var stackView: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.distribution = .fillProportionally
        result.spacing = alertAppearance.lineWidth
        result.axis = .vertical
        contentView.addSubview(result)
        return result
    }()

    init(appearance: AlertControllerAppearance?) {
        super.init(frame: .zero)
        self.appearance = appearance
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCustomSpacing(_ spacing: CGFloat, afterActionIndex index: Int) {
        guard let actionView = stackView.arrangedSubviews[index] as? AlertControllerActionView else { return }
        actionView.afterSpacing = spacing
        stackView.setCustomSpacing(spacing, after: actionView)
        updateLineConstraints()
    }

    func customSpacing(afterActionIndex index: Int) -> CGFloat {
        guard let actionView = stackView.arrangedSubviews[index] as? AlertControllerActionView else { return 0 }
        return stackView.customSpacing(after: actionView)
    }

    func addAction(_ action: AlertAction) {
        actions.append(action)
        let actionView = AlertControllerActionView(appearance: appearance)
        actionView.action = action
        actionView.addTarget(self, action: #selector(buttonClicked(in:)))
        stackView.addArrangedSubview(actionView)

        // arrangedSubviews个数大于1，说明本次添加至少是第2次添加，此时要加一条分割线
        if stackView.arrangedSubviews.count > 1 {
            addLine(for: stackView)
        }
        setNeedsUpdateConstraints()
    }

    func addCancelAction(_ action: AlertAction) {
        assert(cancelAction == nil, "AlertController can only have one action with a style of AlertActionStyleCancel")
        cancelAction = action
        actions.append(action)
        let actionView = AlertControllerActionView(appearance: appearance)
        actionView.translatesAutoresizingMaskIntoConstraints = false
        actionView.action = action
        actionView.addTarget(self, action: #selector(buttonClicked(in:)))
        cancelView.addSubview(actionView)
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[cancelActionView]-0-|", metrics: nil, views: ["cancelActionView": actionView]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[cancelActionView]-0-|", metrics: nil, views: ["cancelActionView": actionView]))
        setNeedsUpdateConstraints()
    }

    private func addLine(for stackView: UIStackView) {
        let actionLine = AlertActionItemSeparatorView(appearance: appearance)
        actionLine.translatesAutoresizingMaskIntoConstraints = false
        // 这里必须用addSubview:，不能用addArrangedSubview:,因为分割线不参与排列布局
        stackView.addSubview(actionLine)
    }

    private func filteredArray(from array: [UIView], notIn otherArray: [UIView]) -> [UIView] {
        let predicate = NSPredicate(format: "NOT (SELF in %@)", otherArray as NSArray)
        let subArray = (array as NSArray).filtered(using: predicate)
        return subArray as? [UIView] ?? []
    }

    private func updateLineConstraints() {
        guard stackView.arrangedSubviews.count > 1 else { return }
        let lines = filteredArray(from: stackView.subviews, notIn: stackView.arrangedSubviews)
        if stackView.arrangedSubviews.count < lines.count { return }

        if self.actionLineConstraints.count > 0 {
            NSLayoutConstraint.deactivate(self.actionLineConstraints)
            self.actionLineConstraints.removeAll()
        }

        var actionLineConstraints: [NSLayoutConstraint] = []
        for (index, actionLine) in lines.enumerated() {
            let actionView1 = stackView.arrangedSubviews[index] as? AlertControllerActionView
            let actionView2 = stackView.arrangedSubviews[index + 1]
            if axis == .horizontal {
                actionLineConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[actionLine]-0-|", metrics: nil, views: ["actionLine": actionLine]))
                actionLineConstraints.append(NSLayoutConstraint(item: actionLine, attribute: .left, relatedBy: .equal, toItem: actionView1, attribute: .right, multiplier: 1.0, constant: 0))
                actionLineConstraints.append(NSLayoutConstraint(item: actionLine, attribute: .right, relatedBy: .equal, toItem: actionView2, attribute: .left, multiplier: 1.0, constant: 0))
                actionLineConstraints.append(NSLayoutConstraint(item: actionLine, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: actionView1?.afterSpacing ?? 0))
            } else {
                actionLineConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[actionLine]-0-|", metrics: nil, views: ["actionLine": actionLine]))
                actionLineConstraints.append(NSLayoutConstraint(item: actionLine, attribute: .top, relatedBy: .equal, toItem: actionView1, attribute: .bottom, multiplier: 1.0, constant: 0))
                actionLineConstraints.append(NSLayoutConstraint(item: actionLine, attribute: .bottom, relatedBy: .equal, toItem: actionView2, attribute: .top, multiplier: 1.0, constant: 0))
                actionLineConstraints.append(NSLayoutConstraint(item: actionLine, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: actionView1?.afterSpacing ?? 0))
            }
        }
        NSLayoutConstraint.activate(actionLineConstraints)
        self.actionLineConstraints = actionLineConstraints
    }

    override func updateConstraints() {
        super.updateConstraints()
        NSLayoutConstraint.deactivate(constraints)

        if scrollView.superview != nil {
            var scrollViewConstraints: [NSLayoutConstraint] = []
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[scrollView]-0-|", metrics: nil, views: ["scrollView": scrollView]))
            scrollViewConstraints.append(NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0))
            if cancelActionLine.superview != nil {
                scrollViewConstraints.append(NSLayoutConstraint(item: scrollView, attribute: .bottom, relatedBy: .equal, toItem: cancelActionLine, attribute: .top, multiplier: 1.0, constant: 0))
            } else {
                scrollViewConstraints.append(NSLayoutConstraint(item: scrollView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0))
            }
            NSLayoutConstraint.activate(scrollViewConstraints)

            NSLayoutConstraint.deactivate(scrollView.constraints)
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[contentView]-0-|", metrics: nil, views: ["contentView": contentView]))
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[contentView]-0-|", metrics: nil, views: ["contentView": contentView]))
            NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .width, multiplier: 1.0, constant: 0).isActive = true
            let equalHeightConstraint = NSLayoutConstraint(item: contentView, attribute: .height, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 1.0, constant: 0)
            // 横向两个按钮时取消始终在左边，纵向两个按钮时取消始终在下边，和系统一致
            if actions.count == 2, actions.last?.style == .cancel {
                let actionView = stackView.arrangedSubviews.last as? AlertControllerActionView
                if axis == .vertical {
                    if let actionView, actionView.action?.style != .cancel {
                        stackView.insertArrangedSubview(actionView, at: 0)
                    }
                } else {
                    if let actionView, actionView.action?.style == .cancel {
                        stackView.insertArrangedSubview(actionView, at: 0)
                    }
                }
            }
            // 计算scrolView的最小和最大高度，下面这个if语句是保证当actions的g总个数大于4时，scrollView的高度至少为4个半FW_ACTION_HEIGHT的高度，否则自适应内容
            var minHeight: CGFloat = 0
            if axis == .vertical {
                if cancelAction != nil {
                    // 如果有取消按钮且action总个数大于4，则除去取消按钮之外的其余部分的高度至少为3个半FW_ACTION_HEIGHT的高度,即加上取消按钮就是总高度至少为4个半FW_ACTION_HEIGHT的高度
                    if actions.count > 4 {
                        minHeight = alertAppearance.actionHeight * 3.5
                        // 优先级为997，必须小于998.0，因为头部如果内容过多时高度也会有限制，头部的优先级为998.0.这里定的规则是，当头部和action部分同时过多时，头部的优先级更高，但是它不能高到以至于action部分小于最小高度
                        equalHeightConstraint.priority = .init(997)
                        // 如果有取消按钮但action的个数大不于4，则该多高就显示多高
                    } else {
                        equalHeightConstraint.priority = .init(1000)
                    }
                } else {
                    if actions.count > 4 {
                        minHeight = alertAppearance.actionHeight * 4.5
                        equalHeightConstraint.priority = .init(997)
                    } else {
                        equalHeightConstraint.priority = .init(1000)
                    }
                }
            } else {
                minHeight = alertAppearance.actionHeight
            }
            let minHeightConstraint = NSLayoutConstraint(item: scrollView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: minHeight)
            // 优先级不能大于对话框的最小顶部间距的优先级(999.0)
            minHeightConstraint.priority = .init(999)
            minHeightConstraint.isActive = true
            equalHeightConstraint.isActive = true

            NSLayoutConstraint.deactivate(contentView.constraints)
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[stackView]-0-|", metrics: nil, views: ["stackView": stackView]))
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[stackView]-0-|", metrics: nil, views: ["stackView": stackView]))

            updateLineConstraints()
        }

        if cancelActionLine.superview != nil {
            var cancelActionLineConstraints: [NSLayoutConstraint] = []
            cancelActionLineConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[cancelActionLine]-0-|", metrics: nil, views: ["cancelActionLine": cancelActionLine]))
            cancelActionLineConstraints.append(NSLayoutConstraint(item: cancelActionLine, attribute: .bottom, relatedBy: .equal, toItem: cancelView, attribute: .top, multiplier: 1.0, constant: 0))
            cancelActionLineConstraints.append(NSLayoutConstraint(item: cancelActionLine, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: alertAppearance.cancelLineWidth))
            NSLayoutConstraint.activate(cancelActionLineConstraints)
        }

        if cancelAction != nil {
            var cancelViewConstraints: [NSLayoutConstraint] = []
            cancelViewConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[cancelView]-0-|", metrics: nil, views: ["cancelView": cancelView]))
            cancelViewConstraints.append(NSLayoutConstraint(item: cancelView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0))
            if cancelActionLine.superview == nil {
                cancelViewConstraints.append(NSLayoutConstraint(item: cancelView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0))
            }
            NSLayoutConstraint.activate(cancelViewConstraints)
        }
    }

    @objc private func buttonClicked(in actionView: AlertControllerActionView) {
        if let action = actionView.action,
           let index = actions.firstIndex(of: action) {
            buttonClickedInActionViewBlock?(index, actionView)
        }
    }
}

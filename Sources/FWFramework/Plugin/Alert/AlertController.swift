//
//  AlertController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - AlertController
/// 弹窗控制器样式枚举
public enum AlertControllerStyle: Int {
    /// 从单侧弹出(顶/左/底/右)
    case actionSheet = 0
    /// 从中间弹出
    case alert
}

/// 弹窗动画类型枚举
public enum AlertAnimationType: Int {
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
public class AlertControllerAppearance: NSObject {
    
    /// 单例模式，统一设置样式
    public static let appearance = AlertControllerAppearance()
    
    /// 自定义首选动作句柄，默认nil，跟随系统
    public var preferredActionBlock: ((_ alertController: AlertControllerImpl) -> AlertAction?)?
    
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
    public var lineWidth: CGFloat = 1.0 / UIScreen.main.scale
    public var cancelLineWidth: CGFloat = 8.0
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 15)
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
    public var textFieldCustomBlock: ((UITextField) -> Void)?
    
    public var alertCornerRadius: CGFloat = 6.0
    public var alertEdgeDistance: CGFloat = (min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 275.0) / 2.0
    public var sheetCornerRadius: CGFloat = 13
    public var sheetEdgeDistance: CGFloat = 70
    public var sheetContainerTransparent: Bool = false
    public var sheetContainerInsets: UIEdgeInsets = .zero
    
    /// 是否启用Controller样式，设置后自动启用
    public var controllerEnabled: Bool {
        return titleColor != nil || titleFont != nil || messageColor != nil || messageFont != nil
    }
    
    /// 是否启用Action样式，设置后自动启用
    public var actionEnabled: Bool {
        return actionColor != nil || preferredActionColor != nil || cancelActionColor != nil || destructiveActionColor != nil || disabledActionColor != nil
    }

    static func dynamicColorPairs(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? dark : light
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
@objc public protocol AlertControllerDelegate {
    
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
open class AlertController: UIViewController {
    
    /// 获取所有动作
    open var actions: [AlertAction] {
        return []
    }
    
    /// 设置首选动作
    open var preferredAction: AlertAction?
    
    /// 获取所有输入框
    open var textFields: [UITextField]? {
        return nil
    }
    
    /// 主标题
    open override var title: String? {
        get {
            
        }
        set {
            
        }
    }
    /// 副标题
    open var message: String?
    /// 弹窗样式，默认Default
    open var alertStyle: AlertStyle = .default
    /// 动画类型
    open var animationType: AlertAnimationType
    /// 主标题(富文本)
    open var attributedTitle: NSAttributedString?
    /// 副标题(富文本)
    open var attributedMessage: NSAttributedString?
    /// 头部图标，位置处于title之上,大小取决于图片本身大小
    open var image: UIImage?
    
    /// 主标题颜色
    open var titleColor: UIColor?
    /// 主标题字体,默认18,加粗
    open var titleFont: UIFont?
    /// 副标题颜色
    open var messageColor: UIColor?
    /// 副标题字体,默认16,未加粗
    open var messageFont: UIFont?
    /// 对齐方式(包括主标题和副标题)
    open var textAlignment: NSTextAlignment = .center
    /// 头部图标的限制大小,默认无穷大
    open var imageLimitSize: CGSize = .zero
    /// 图片的tintColor,当外部的图片使用了AlwaysTemplate的渲染模式时,该属性可起到作用
    open var imageTintColor: UIColor?
    
    /// action水平排列还是垂直排列
    /// actionSheet样式下:默认为UILayoutConstraintAxisVertical(垂直排列), 如果设置为UILayoutConstraintAxisHorizontal(水平排列)，则除去取消样式action之外的其余action将水平排列
    /// alert样式下:当actions的个数大于2，或者某个action的title显示不全时为UILayoutConstraintAxisVertical(垂直排列)，否则默认为UILayoutConstraintAxisHorizontal(水平排列)，此样式下设置该属性可以修改所有action的排列方式
    /// 不论哪种样式，只要外界设置了该属性，永远以外界设置的优先
    open var actionAxis: NSLayoutConstraint.Axis
    /// 距离屏幕边缘的最小间距
    /// alert样式下该属性是指对话框四边与屏幕边缘之间的距离，此样式下默认值随设备变化，actionSheet样式下是指弹出边的对立边与屏幕之间的距离，比如如果从右边弹出，那么该属性指的就是对话框左边与屏幕之间的距离，此样式下默认值为70
    open var minDistanceToEdges: CGFloat
    /// Alert样式下默认6.0f，ActionSheet样式下默认13.0f，去除半径设置为0即可
    open var cornerRadius: CGFloat
    /// 对话框的偏移量，y值为正向下偏移，为负向上偏移；x值为正向右偏移，为负向左偏移，该属性只对Alert样式有效,键盘的frame改变会自动偏移，如果手动设置偏移只会取手动设置的
    open var offsetForAlert: CGPoint
    /// 是否需要对话框拥有毛玻璃,默认为YES
    open var needDialogBlur: Bool
    /// 是否含有自定义TextField,键盘的frame改变会自动偏移,默认为NO
    open var customTextField: Bool
    /// 是否单击背景退出对话框,默认为YES
    open var tapBackgroundViewDismiss: Bool
    /// 是否点击动作按钮退出动画框,默认为YES
    open var tapActionDismiss: Bool
    
    /// 单击背景dismiss完成回调，默认nil
    open var dismissCompletion: (() -> Void)?
    /// 事件代理
    open weak var delegate: AlertControllerDelegate?
    /// 弹出框样式
    open private(set) var preferredStyle: AlertControllerStyle
    /// 自定义样式，默认为样式单例
    open var alertAppearance: AlertControllerAppearance
    
    var backgroundViewAppearanceStyle: UIBlurEffect.Style?
    var backgroundViewAlpha: CGFloat
    
    /// 创建控制器(默认对话框)
    public init(title: String?, message: String?, preferredStyle: AlertControllerStyle, animationType: AlertAnimationType = .default, appearance: AlertControllerAppearance? = nil) {
        
    }
    
    /// 创建控制器(自定义整个对话框)
    public init(customAlertView: UIView, preferredStyle: AlertControllerStyle, animationType: AlertAnimationType = .default, appearance: AlertControllerAppearance? = nil) {
        
    }
    
    /// 创建控制器(自定义对话框的头部)
    public init(customHeaderView: UIView, preferredStyle: AlertControllerStyle, animationType: AlertAnimationType = .default, appearance: AlertControllerAppearance? = nil) {
        
    }
    
    /// 创建控制器(自定义对话框的action部分)
    public init(customActionSequenceView: UIView, title: String?, message: String?, preferredStyle: AlertControllerStyle, animationType: AlertAnimationType = .default, appearance: AlertControllerAppearance? = nil) {
        
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 添加动作
    open func addAction(_ action: AlertAction) {
        
    }
    
    /// 添加文本输入框，一旦添加后就会仅回调一次configurationHandler
    open func addTextField(configurationHandler: ((UITextField) -> Void)? = nil) {
        
    }
    
    /// 设置alert样式下的偏移量,动画为NO则跟属性offsetForAlert等效
    open func setOffsetForAlert(_ offsetForAlert: CGPoint, animated: Bool) {
        
    }
    
    /// 设置action与下一个action之间的间距, action仅限于非取消样式，必须在'-addAction:'之后设置，nil时设置header与action间距
    open func setCustomSpacing(_ spacing: CGFloat, afterAction action: AlertAction?) {
        
    }
    
    /// 获取action与下一个action之间的间距, action仅限于非取消样式，必须在'-addAction:'之后获取，nil时获取header与action间距
    open func customSpacingAfterAction(_ action: AlertAction?) -> CGFloat {
        return 0
    }
    
    /// 设置蒙层的外观样式,可通过alpha调整透明度
    open func setBackgroundViewAppearanceStyle(_ style: UIBlurEffect.Style?, alpha: CGFloat) {
        
    }
    
    /// 插入一个组件view，位置处于头部和action部分之间，要求头部和action部分同时存在
    open func insertComponentView(_ componentView: UIView) {
        
    }
    
    /// 更新自定义view的size，比如屏幕旋转，自定义view的大小发生了改变，可通过该方法更新size
    open func updateCustomViewSize(_ size: CGSize) {
        
    }
    
    func layoutAlertControllerView() {
        
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
        self.containerView?.addSubview(overlayView)
        return overlayView
    }
    private weak var _overlayView: AlertOverlayView?
    
    public override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        overlayView.frame = self.containerView?.bounds ?? .zero
    }
    
    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
    }
    
    open override func presentationTransitionWillBegin() {
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
    
    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        guard let alertController = presentedViewController as? AlertController else { return }
        
        alertController.delegate?.didPresentAlertController?(alertController)
    }
    
    open override func dismissalTransitionWillBegin() {
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
    
    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            _overlayView?.removeFromSuperview()
            _overlayView = nil
        }
        if let alertController = presentedViewController as? AlertController {
            alertController.delegate?.didDismissAlertController?(alertController)
        }
    }
    
    open override var frameOfPresentedViewInContainerView: CGRect {
        return self.presentedView?.frame ?? .zero
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
        return 0.25
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
            self.offsetCenter(alertController)
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
            self.offsetCenter(alertController)
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
public enum AlertActionStyle: Int {
    /// 默认样式
    case `default` = 0
    /// 取消样式,字体加粗
    case cancel
    /// 红色字体样式
    case destructive
}

/// 弹窗动作
public class AlertAction: NSObject, NSCopying {
    
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
        didSet { propertyChangedBlock?(self, false) }
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
    public var titleEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    
    /// 样式
    public private(set) var style: AlertActionStyle = .default
    
    /// 自定义样式，默认为样式单例
    public var alertAppearance: AlertControllerAppearance {
        return appearance ?? AlertControllerAppearance.appearance
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
    
    public override init() {
        super.init()
        
        self.titleColor = alertAppearance.titleDynamicColor
        self.titleFont = alertAppearance.actionFont
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = AlertAction(title: title, style: style, appearance: appearance, handler: handler)
        copy.attributedTitle = attributedTitle
        copy.image = image
        copy.imageTitleSpacing = imageTitleSpacing
        copy.tintColor = tintColor
        copy.isEnabled = isEnabled
        copy.titleColor = titleColor
        copy.titleFont = titleFont
        copy.titleEdgeInsets = titleEdgeInsets
        copy.propertyChangedBlock = propertyChangedBlock
        return copy
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
        if let style = style {
            self.backgroundColor = UIColor.clear
            let blurEffect = UIBlurEffect(style: style)
            let effectView = UIVisualEffectView(effect: blurEffect)
            effectView.frame = self.bounds
            effectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            effectView.isUserInteractionEnabled = false
            effectView.alpha = alpha
            self.addSubview(effectView)
            self.effectView = effectView
        } else {
            effectView?.removeFromSuperview()
            effectView = nil
            self.backgroundColor = UIColor(white: 0, alpha: alpha < 0 ? 0.5 : alpha)
            self.alpha = 0
        }
    }
    
}

class AlertActionItemSeparatorView: UIView {
    
    var customBackgroundColor: UIColor?
    private var appearance: AlertControllerAppearance?
    
    private var alertAppearance: AlertControllerAppearance {
        return appearance ?? AlertControllerAppearance.appearance
    }
    
    init(appearance: AlertControllerAppearance?) {
        super.init(frame: .zero)
        self.appearance = appearance
        self.backgroundColor = alertAppearance.lineColor
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
    private var textFields: [UITextField] = []
    private var contentEdgeInsets: UIEdgeInsets = .zero
    private var appearance: AlertControllerAppearance?
    
    private var alertAppearance: AlertControllerAppearance {
        return appearance ?? AlertControllerAppearance.appearance
    }
    
    private var appearanceContentInsets: UIEdgeInsets {
        var contentInsets = alertAppearance.contentInsets
        return UIEdgeInsets(top: ceil(contentInsets.top), left: ceil(contentInsets.left), bottom: ceil(contentInsets.bottom), right: ceil(contentInsets.right))
    }
    
    private lazy var contentView: UIView = {
        let result = UIView()
        result.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(result)
        return result
    }()
    
    private var titleLabel: UILabel {
        if let result = _titleLabel {
            return result
        }
        
        let result = UILabel()
        result.font = UIFont.boldSystemFont(ofSize: 18)
        result.textAlignment = .center
        result.textColor = alertAppearance.titleDynamicColor
        result.numberOfLines = 0
        result.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(result)
        _titleLabel = result
        return result
    }
    private weak var _titleLabel: UILabel?
    
    private var messageLabel: UILabel {
        if let result = _messageLabel {
            return result
        }
        
        let result = UILabel()
        result.font = UIFont.systemFont(ofSize: 18)
        result.textAlignment = .center
        result.textColor = alertAppearance.grayColor
        result.numberOfLines = 0
        result.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(result)
        _messageLabel = result
        return result
    }
    private weak var _messageLabel: UILabel?
    
    private var imageView: UIImageView {
        if let result = _imageView {
            return result
        }
        
        let result = UIImageView()
        result.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.insertSubview(result, at: 0)
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
            self.contentView.addSubview(result)
        }
        _textFieldView = result
        return result
    }
    private weak var _textFieldView: UIStackView?
    
    init(appearance: AlertControllerAppearance?) {
        super.init(frame: .zero)
        self.appearance = appearance
        self.showsHorizontalScrollIndicator = false
        self.contentInsetAdjustmentBehavior = .never
        self.contentEdgeInsets = appearanceContentInsets
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let resolvedColor = alertAppearance.lineColor?.resolvedColor(with: traitCollection)
        textFields.forEach { textField in
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
        NSLayoutConstraint.deactivate(self.constraints)
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
    }
    
    func addTextField(_ textField: UITextField) {
        textFields.append(textField)
        textFieldView.addArrangedSubview(textField)
        NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: alertAppearance.textFieldHeight).isActive = true
        setNeedsUpdateConstraints()
    }
    
}

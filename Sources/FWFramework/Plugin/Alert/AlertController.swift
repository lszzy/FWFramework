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
    open func setBackgroundViewAppearanceStyle(_ style: UIBlurEffect.Style, alpha: CGFloat) {
        
    }
    
    /// 插入一个组件view，位置处于头部和action部分之间，要求头部和action部分同时存在
    open func insertComponentView(_ componentView: UIView) {
        
    }
    
    /// 更新自定义view的size，比如屏幕旋转，自定义view的大小发生了改变，可通过该方法更新size
    open func updateCustomViewSize(_ size: CGSize) {
        
    }
    
}

/// 自定义弹窗展示控制器
open class AlertPresentationController: UIPresentationController {
    
    
    
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
        
    }
    
    private func dismissAnimationTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        
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

//
//  ViewTransition.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - AnimatedTransition
/// 转场动画类型
public enum AnimatedTransitionType: Int {
    /// 转场未开始
    case none = 0
    /// push转场
    case push
    /// pop转场
    case pop
    /// present转场
    case present
    /// dismiss转场
    case dismiss
}

/// 转场动画类，默认透明度变化
open class AnimatedTransition: UIPercentDrivenInteractiveTransition,
                               UIViewControllerAnimatedTransitioning,
                               UIViewControllerTransitioningDelegate,
                               UINavigationControllerDelegate {
    
    // MARK: - Transition
    /// 创建系统转场单例，不支持交互手势转场
    public static let system: AnimatedTransition = {
        let transition = AnimatedTransition()
        transition.isSystem = true
        return transition
    }()
    
    /// 设置动画句柄
    open var transitionBlock: ((AnimatedTransition) -> Void)?

    /// 动画持续时间，必须大于0，默认0.35秒(默认设置completionSpeed为0.35)
    open var transitionDuration: TimeInterval = 0.35

    /// 获取动画类型，默认根据上下文判断
    open var transitionType: AnimatedTransitionType = .none
    
    /// 创建动画转场
    public override init() {
        super.init()
        self.completionSpeed = 0.35
    }
    
    /// 创建动画句柄转场
    public convenience init(block: ((AnimatedTransition) -> Void)?) {
        self.init()
        self.transitionBlock = block
    }

    // MARK: - Interactive
    /// 是否启用交互pan手势进行pop|dismiss，默认NO。可使用父类属性设置交互动画
    open var interactEnabled = false {
        didSet {
            gestureRecognizer.isEnabled = interactEnabled
        }
    }

    /// 是否启用screenEdge交互手势，默认NO，gestureRecognizer加载前设置生效
    open var interactScreenEdge = false

    /// 指定交互pan手势对象，默认PanGestureRecognizer，可设置交互方向，滚动视图等
    open lazy var gestureRecognizer: UIPanGestureRecognizer = {
        if interactScreenEdge {
            let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(gestureRecognizerAction(_:)))
            gesture.edges = .left
            return gesture
        } else {
            let gesture = PanGestureRecognizer(target: self, action: #selector(gestureRecognizerAction(_:)))
            return gesture
        }
    }() {
        didSet {
            gestureRecognizer.addTarget(self, action: #selector(gestureRecognizerAction(_:)))
        }
    }

    /// 是否正在交互中，手势开始才会标记为YES，手势结束标记为NO
    open private(set) var isInteractive = false

    /// 自定义交互句柄，可根据手势state处理不同状态的交互，返回YES执行默认交互，返回NO不执行。默认为空，执行默认交互
    open var interactBlock: ((UIPanGestureRecognizer) -> Bool)?

    /// 自定义dismiss关闭动画完成回调，默认nil
    open var dismissCompletion: (() -> Void)?
    
    /// 手工绑定交互控制器，添加pan手势，需要vc.view存在时调用才生效。默认自动绑定，如果自定义interactBlock，必须手工绑定
    open func interact(with viewController: UIViewController) {
        guard viewController.view != nil else { return }
        
        if viewController.view.gestureRecognizers?.contains(gestureRecognizer) ?? false { return }
        viewController.view.addGestureRecognizer(gestureRecognizer)
    }

    // MARK: - Presentation
    /// 是否启用默认展示控制器，启用后自动设置presentationBlock返回PresentationController，默认NO
    open var presentationEnabled: Bool {
        get {
            return presentationBlock != nil
        }
        set {
            if newValue == presentationEnabled { return }
            if newValue {
                presentationBlock = { presented, presenting in
                    return PresentationController(presentedViewController: presented, presenting: presenting)
                }
            } else {
                presentationBlock = nil
            }
        }
    }

    /// 设置展示控制器创建句柄，自定义弹出效果。present时建议设置modalPresentationStyle为Custom
    open var presentationBlock: ((UIViewController, UIViewController?) -> UIPresentationController)?
    
    // MARK: - Private
    private var isSystem = false
    
    private var interactBegan: (() -> Void)?
    
    @objc private func gestureRecognizerAction(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            isInteractive = true
            
            var shouldBegin = true
            if let interactBlock = interactBlock {
                shouldBegin = interactBlock(gestureRecognizer)
            }
            if shouldBegin && interactBegan != nil {
                interactBegan?()
            }
        case .changed:
            var interactChanged = true
            if let interactBlock = interactBlock {
                interactChanged = interactBlock(gestureRecognizer)
            }
            if interactChanged {
                var percent: CGFloat
                if let gestureRecognizer = gestureRecognizer as? PanGestureRecognizer {
                    percent = gestureRecognizer.swipePercent
                } else {
                    let transition = gestureRecognizer.translation(in: gestureRecognizer.view)
                    let viewWidth = gestureRecognizer.view?.bounds.size.width ?? 0
                    percent = viewWidth > 0 ? max(0, min(1, transition.x / viewWidth)) : 0
                }
                
                self.update(percent)
            }
        case .cancelled, .failed, .ended:
            isInteractive = false
            
            var interactEnded = true
            if let interactBlock = interactBlock {
                interactEnded = interactBlock(gestureRecognizer)
            }
            if interactEnded {
                var finished = false
                if gestureRecognizer.state == .cancelled || gestureRecognizer.state == .failed {
                    finished = false
                } else if percentComplete >= 0.5 {
                    finished = true
                } else if let gestureRecognizer = gestureRecognizer as? PanGestureRecognizer {
                    let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)
                    let transition = gestureRecognizer.translation(in: gestureRecognizer.view)
                    switch gestureRecognizer.direction {
                    case .up:
                        if velocity.y <= -100 && abs(transition.x) < abs(transition.y) { finished = true }
                    case .left:
                        if velocity.x <= -100 && abs(transition.x) > abs(transition.y) { finished = true }
                    case .down:
                        if velocity.y >= 100 && abs(transition.x) < abs(transition.y) { finished = true }
                    case .right:
                        if velocity.x >= 100 && abs(transition.x) > abs(transition.y) { finished = true }
                    default:
                        break
                    }
                } else {
                    let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)
                    let transition = gestureRecognizer.translation(in: gestureRecognizer.view)
                    if velocity.x >= 100 && abs(transition.x) > abs(transition.y) { finished = true }
                }
                
                if finished {
                    self.finish()
                } else {
                    self.cancel()
                }
            }
        default:
            break
        }
    }
    
    private func interactiveTransition(for transition: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if transitionType == .dismiss || transitionType == .pop {
            if !isSystem && interactEnabled && isInteractive {
                return self
            }
        }
        return nil
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionType = .present
        // 自动设置和绑定dismiss交互转场，在dismiss前设置生效
        if !isSystem && interactEnabled && interactBlock == nil {
            interactBegan = { [weak presented] in
                presented?.dismiss(animated: true, completion: nil)
            }
            interact(with: presented)
        }
        return !isSystem ? self : nil
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionType = .dismiss
        return !isSystem ? self : nil
    }
    
    open func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition(for: animator)
    }
    
    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition(for: animator)
    }
    
    open func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if presentationBlock != nil {
            return presentationBlock?(presented, presenting)
        }
        return nil
    }
    
    // MARK: - UINavigationControllerDelegate
    open func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            // push时检查toVC的转场代理
            let transition = toVC.fw_viewTransition ?? self
            transition.transitionType = .push
            // 自动设置和绑定pop交互转场，在pop前设置生效
            if !transition.isSystem && transition.interactEnabled && transition.interactBlock == nil {
                transition.interactBegan = {
                    navigationController.popViewController(animated: true)
                }
                transition.interact(with: toVC)
            }
            return !transition.isSystem ? transition : nil
        } else if operation == .pop {
            // pop时检查fromVC的转场代理
            let transition = fromVC.fw_viewTransition ?? self
            transition.transitionType = .pop
            return !transition.isSystem ? transition : nil
        }
        return nil
    }
    
    open func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition(for: animationController)
    }
    
    // MARK: - UIViewControllerAnimatedTransitioning
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return (transitionContext?.isAnimated ?? false) ? self.transitionDuration : 0
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        if self.transitionBlock != nil {
            self.transitionBlock?(self)
        } else {
            self.animate()
        }
    }
    
    // MARK: - Animate
    /// 转场上下文，只读
    open private(set) weak var transitionContext: UIViewControllerContextTransitioning?

    /// 标记动画开始(自动添加视图到容器)
    open func start() {
        
    }

    /// 执行动画，子类重写，可选
    open func animate() {
        
    }

    /// 自动标记动画完成(根据transitionContext是否被取消判断)
    open func complete() {
        
    }
    
}

// MARK: - SwipeAnimatedTransition
/// 滑动转场动画类，默认上下
open class SwipeAnimatedTransition: AnimatedTransition {
    
    /// 创建滑动转场，指定进入(push|present)和消失(pop|dismiss)方向
    public convenience init(inDirection: UISwipeGestureRecognizer.Direction, outDirection: UISwipeGestureRecognizer.Direction) {
        self.init()
        self.inDirection = inDirection
        self.outDirection = outDirection
    }

    /// 指定进入(push|present)方向，默认上滑Up
    open var inDirection: UISwipeGestureRecognizer.Direction = .up
    /// 指定消失(pop|dismiss)方向，默认下滑Down
    open var outDirection: UISwipeGestureRecognizer.Direction = .down
    
}

// MARK: - TransformAnimatedTransition
/// 形变转场动画类，默认缩放
open class TransformAnimatedTransition: AnimatedTransition {
    
    /// 创建形变转场，指定进入(push|present)和消失(pop|dismiss)形变
    public convenience init(inTransform: CGAffineTransform, outTransform: CGAffineTransform) {
        self.init()
        self.inTransform = inTransform
        self.outTransform = outTransform
    }

    /// 指定进入(push|present)形变，默认缩放0.01
    open var inTransform: CGAffineTransform = .init(scaleX: 0.01, y: 0.01)
    /// 指定消失(pop|dismiss)形变，默认缩放0.01
    open var outTransform: CGAffineTransform = .init(scaleX: 0.01, y: 0.01)
    
}

// MARK: - PresentationController
/// 自定义展示控制器。默认显示暗色背景动画且弹出视图占满容器，可通过属性自定义
open class PresentationController: UIPresentationController {
    
    /// 是否显示暗色背景，默认YES
    open var showDimming = true
    /// 是否可以点击暗色背景关闭，默认YES。如果弹出视图占满容器，手势不生效(因为弹出视图挡住了暗色背景)
    open var dimmingClick = true
    /// 是否执行暗黑背景透明度动画，默认YES
    open var dimmingAnimated = true
    /// 暗色背景颜色，默认黑色，透明度0.5
    open var dimmingColor: UIColor?
    /// 设置点击暗色背景关闭完成回调，默认nil
    open var dismissCompletion: (() -> Void)?

    /// 设置弹出视图的圆角位置，默认左上和右上。如果弹出视图占满容器，不生效需弹出视图自定义
    open var rectCorner: UIRectCorner = []
    /// 设置弹出视图的圆角半径，默认0无圆角。如果弹出视图占满容器，不生效需弹出视图自定义
    open var cornerRadius: CGFloat = 0

    /// 自定义弹出视图的frame计算block，默认nil占满容器，优先级高
    open var frameBlock: ((PresentationController) -> CGRect)?
    /// 设置弹出视图的frame，默认CGRectZero占满容器，优先级中
    open var presentedFrame: CGRect = .zero
    /// 设置弹出视图的居中size，默认CGSizeZero占满容器，优先级中
    open var presentedSize: CGSize = .zero
    /// 设置弹出视图的顶部距离，默认0占满容器，优先级低
    open var verticalInset: CGFloat = 0
    
}

// MARK: - PanGestureRecognizer
/// 自动处理与滚动视图pan手势在指定方向的冲突，默认设置delegate为自身。如果找到滚动视图则处理之，否则同父类
open class PanGestureRecognizer: UIPanGestureRecognizer {
    
    /// 是否自动检测滚动视图，默认YES。如需手工指定，请禁用之
    open var autoDetected = true

    /// 是否按下就立即转换Began状态，默认NO，需要等待移动才会触发Began
    open var instantBegan = false

    /// 指定滚动视图，自动处理与滚动视图pan手势在指定方向的冲突。自动设置默认delegate为自身
    open weak var scrollView: UIScrollView?

    /// 指定与滚动视图pan手势的冲突交互方向，默认向下
    open var direction: UISwipeGestureRecognizer.Direction = .down

    /// 获取当前手势在指定交互方向的滑动进度
    open var swipePercent: CGFloat = 0

    /// 指定当前手势在指定交互方向的最大识别距离，默认0，无限制
    open var maximumDistance: CGFloat = 0

    /// 自定义Failed判断句柄。默认判定失败时直接修改状态为Failed，可设置此block修改判定条件
    open var shouldFailed: ((PanGestureRecognizer) -> Bool)?

    /// 自定义shouldBegin判断句柄
    open var shouldBegin: ((PanGestureRecognizer) -> Bool)?

    /// 自定义shouldBeRequiredToFail判断句柄
    open var shouldBeRequiredToFail: ((UIGestureRecognizer) -> Bool)?

    /// 自定义shouldRequireFailure判断句柄
    open var shouldRequireFailure: ((UIGestureRecognizer) -> Bool)?
    
}

// MARK: - UIViewController+ViewTransition
@_spi(FW) extension UIViewController {
    
    private class PresentationTarget: NSObject, UIPopoverPresentationControllerDelegate {
        
        var isPopover = false
        var shouldDismiss = true
        
        func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
            return self.isPopover ? .none : controller.presentationStyle
        }
        
        func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
            return self.shouldDismiss
        }
        
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            return self.shouldDismiss
        }
        
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            presentationController.presentedViewController.fw_presentationDidDismiss?()
        }
        
    }
    
    /// 视图控制器present|dismiss转场。注意会修改transitioningDelegate，且会强引用之；如需weak引用，请直接设置transitioningDelegate
    public var fw_modalTransition: AnimatedTransition? {
        get {
            return fw_property(forName: "fw_modalTransition") as? AnimatedTransition
        }
        set {
            // 注意：App退出后台时如果弹出页面，整个present动画不会执行。如果需要设置遮罩层等，需要在viewDidAppear中处理兼容
            // 设置delegation动画，nil时清除delegate动画
            self.transitioningDelegate = newValue
            // 强引用，防止被自动释放，nil时释放引用
            fw_setProperty(newValue, forName: "fw_modalTransition")
        }
    }

    /// 视图控制器push|pop转场，代理导航控制器转场，需在fwNavigationTransition设置后生效
    @objc(__fw_viewTransition)
    public var fw_viewTransition: AnimatedTransition? {
        get {
            return fw_property(forName: "fw_viewTransition") as? AnimatedTransition
        }
        set {
            fw_setProperty(newValue, forName: "fw_viewTransition")
        }
    }

    /// 自定义控制器present系统转场(蒙层渐变，内容向上动画)，会设置fwModalTransition
    @discardableResult
    public func fw_setPresentTransition(_ presentationBlock: ((PresentationController) -> Void)? = nil) -> AnimatedTransition {
        let modalTransition = SwipeAnimatedTransition()
        modalTransition.presentationBlock = { presented, presenting in
            let presentationController = PresentationController(presentedViewController: presented, presenting: presenting)
            presentationBlock?(presentationController)
            return presentationController
        }
        self.modalPresentationStyle = .custom
        self.fw_modalTransition = modalTransition
        return modalTransition
    }

    /// 自定义控制器alert缩放转场(蒙层渐变，内容缩放动画)，会设置fwModalTransition
    @discardableResult
    public func fw_setAlertTransition(_ presentationBlock: ((PresentationController) -> Void)? = nil) -> AnimatedTransition {
        let modalTransition = TransformAnimatedTransition(inTransform: .init(scaleX: 1.1, y: 1.1), outTransform: .identity)
        modalTransition.presentationBlock = { presented, presenting in
            let presentationController = PresentationController(presentedViewController: presented, presenting: presenting)
            presentationBlock?(presentationController)
            return presentationController
        }
        self.modalPresentationStyle = .custom
        self.fw_modalTransition = modalTransition
        return modalTransition
    }
    
    /// 自定义控制器fade渐变转场(蒙层和内容渐变动画)，会设置fwModalTransition;
    @discardableResult
    public func fw_setFadeTransition(_ presentationBlock: ((PresentationController) -> Void)? = nil) -> AnimatedTransition {
        let modalTransition = AnimatedTransition()
        modalTransition.presentationBlock = { presented, presenting in
            let presentationController = PresentationController(presentedViewController: presented, presenting: presenting)
            presentationBlock?(presentationController)
            return presentationController
        }
        self.modalPresentationStyle = .custom
        self.fw_modalTransition = modalTransition
        return modalTransition
    }
    
    /// 设置iOS13默认present手势下拉dismiss时的回调block，仅iOS13生效，自动触发，手工dismiss不会触发。会自动设置presentationController.delegate
    public var fw_presentationDidDismiss: (() -> Void)? {
        get {
            return fw_property(forName: "fw_presentationDidDismiss") as? () -> Void
        }
        set {
            fw_setPropertyCopy(newValue, forName: "fw_presentationDidDismiss")
            if #available(iOS 13.0, *) {
                self.presentationController?.delegate = self.fw_presentationTarget
            }
        }
    }

    /// 自定义控制器popover弹出效果(preferredContentSize设置大小)，会自动设置modalPresentationStyle和popoverPresentationController.delegate
    public func fw_setPopoverPresentation(_ presentationBlock: ((UIPopoverPresentationController) -> Void)?, shouldDismiss: Bool) {
        self.modalPresentationStyle = .popover
        self.fw_presentationTarget.isPopover = true
        self.fw_presentationTarget.shouldDismiss = shouldDismiss
        self.popoverPresentationController?.delegate = self.fw_presentationTarget
        if let popoverController = self.popoverPresentationController {
            presentationBlock?(popoverController)
        }
    }
    
    private var fw_presentationTarget: PresentationTarget {
        if let target = fw_property(forName: "fw_presentationTarget") as? PresentationTarget {
            return target
        } else {
            let target = PresentationTarget()
            fw_setProperty(target, forName: "fw_presentationTarget")
            return target
        }
    }
    
}

// MARK: - UIView+ViewTransition
@_spi(FW) extension UIView {
    
    /// 转场添加到指定控制器(pinEdges占满父视图)，返回父容器视图。VC.tabBarController.view > VC.navigationController.view > VC.view
    @discardableResult
    public func fw_transition(to viewController: UIViewController, pinEdges: Bool = true) -> UIView {
        let ancestorView = viewController.fw_ancestorView
        ancestorView.addSubview(self)
        if pinEdges {
            self.fw_pinEdges()
            ancestorView.setNeedsLayout()
            ancestorView.layoutIfNeeded()
        }
        return ancestorView
    }

    /// 包装到转场控制器(pinEdges占满父视图)，返回创建的控制器
    public func fw_wrappedTransitionController(_ pinEdges: Bool = true) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.addSubview(self)
        if pinEdges {
            self.fw_pinEdges()
            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()
        }
        return viewController
    }

    /// 自定义视图模拟present系统转场(蒙层渐变，内容向上动画)
    public func fw_setPresentTransition(_ transitionType: AnimatedTransitionType, contentView: UIView?, completion: ((Bool) -> Void)? = nil) {
        let transitionIn = transitionType == .push || transitionType == .present
        if transitionIn {
            self.alpha = 0
            contentView?.transform = .init(translationX: 0, y: contentView?.frame.size.height ?? 0)
            UIView.animate(withDuration: 0.25) {
                contentView?.transform = .identity
                self.alpha = 1
            } completion: { finished in
                completion?(finished)
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                contentView?.transform = .init(translationX: 0, y: contentView?.frame.size.height ?? 0)
                self.alpha = 0
            } completion: { finished in
                contentView?.transform = .identity
                self.removeFromSuperview()
                completion?(finished)
            }
        }
    }

    /// 自定义视图模拟alert缩放转场(蒙层渐变，内容缩放动画)
    public func fw_setAlertTransition(_ transitionType: AnimatedTransitionType, completion: ((Bool) -> Void)? = nil) {
        let transitionIn = transitionType == .push || transitionType == .present
        if transitionIn {
            self.alpha = 0
            self.transform = .init(scaleX: 1.1, y: 1.1)
            UIView.animate(withDuration: 0.25) {
                self.transform = .identity
                self.alpha = 1
            } completion: { finished in
                completion?(finished)
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.alpha = 0
            } completion: { finished in
                self.removeFromSuperview()
                completion?(finished)
            }
        }
    }

    /// 自定义视图模拟fade渐变转场(蒙层和内容渐变动画)
    public func fw_setFadeTransition(_ transitionType: AnimatedTransitionType, completion: ((Bool) -> Void)? = nil) {
        let transitionIn = transitionType == .push || transitionType == .present
        if transitionIn {
            self.alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.alpha = 1
            } completion: { finished in
                completion?(finished)
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.alpha = 0
            } completion: { finished in
                self.removeFromSuperview()
                completion?(finished)
            }
        }
    }
    
}

// MARK: - UINavigationController+ViewTransition
@_spi(FW) extension UINavigationController {
    
    /// 导航控制器push|pop转场。注意会修改delegate，且会强引用之，一直生效直到设置为nil。如需weak引用，请直接设置delegate
    public var fw_navigationTransition: AnimatedTransition? {
        get {
            return fw_property(forName: "fw_navigationTransition") as? AnimatedTransition
        }
        set {
            // 设置delegate动画，nil时清理delegate动画，无需清理CA动画
            self.delegate = newValue
            // 强引用，防止被自动释放，nil时释放引用
            fw_setProperty(newValue, forName: "fw_navigationTransition")
        }
    }
    
}

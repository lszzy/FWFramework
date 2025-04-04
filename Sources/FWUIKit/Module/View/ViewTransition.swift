//
//  ViewTransition.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - Wrapper+UIViewController
@MainActor extension Wrapper where Base: UIViewController {
    /// 视图控制器present|dismiss转场。注意会修改transitioningDelegate，且会强引用之；如需weak引用，请直接设置transitioningDelegate
    public var modalTransition: AnimatedTransition? {
        get {
            property(forName: "modalTransition") as? AnimatedTransition
        }
        set {
            // 注意：App退出后台时如果弹出页面，整个present动画不会执行。如果需要设置遮罩层等，需要在viewDidAppear中处理兼容
            // 设置delegation动画，nil时清除delegate动画
            base.transitioningDelegate = newValue
            // 强引用，防止被自动释放，nil时释放引用
            setProperty(newValue, forName: "modalTransition")
        }
    }

    /// 视图控制器push|pop转场，代理导航控制器转场，需在fwNavigationTransition设置后生效
    public var viewTransition: AnimatedTransition? {
        get {
            property(forName: "viewTransition") as? AnimatedTransition
        }
        set {
            setProperty(newValue, forName: "viewTransition")
        }
    }

    /// 自定义控制器present系统转场(蒙层渐变，内容默认向上动画)，会设置fwModalTransition
    @discardableResult
    public func setPresentTransition(_ presentationBlock: (@MainActor @Sendable (PresentationController) -> Void)? = nil, edge: UIRectEdge = .bottom) -> AnimatedTransition {
        let animatedTransition = SwipeAnimatedTransition(edge: edge)
        animatedTransition.presentationBlock = { presented, presenting in
            let presentationController = PresentationController(presentedViewController: presented, presenting: presenting)
            presentationBlock?(presentationController)
            return presentationController
        }
        base.modalPresentationStyle = .custom
        modalTransition = animatedTransition
        return animatedTransition
    }

    /// 自定义控制器alert缩放转场(蒙层渐变，内容缩放动画)，会设置fwModalTransition
    @discardableResult
    public func setAlertTransition(_ presentationBlock: (@MainActor @Sendable (PresentationController) -> Void)? = nil) -> AnimatedTransition {
        let animatedTransition = TransformAnimatedTransition.alertTransition()
        animatedTransition.presentationBlock = { presented, presenting in
            let presentationController = PresentationController(presentedViewController: presented, presenting: presenting)
            presentationBlock?(presentationController)
            return presentationController
        }
        base.modalPresentationStyle = .custom
        modalTransition = animatedTransition
        return animatedTransition
    }

    /// 自定义控制器fade渐变转场(蒙层和内容渐变动画)，会设置fwModalTransition;
    @discardableResult
    public func setFadeTransition(_ presentationBlock: (@MainActor @Sendable (PresentationController) -> Void)? = nil) -> AnimatedTransition {
        let animatedTransition = AnimatedTransition()
        animatedTransition.presentationBlock = { presented, presenting in
            let presentationController = PresentationController(presentedViewController: presented, presenting: presenting)
            presentationBlock?(presentationController)
            return presentationController
        }
        base.modalPresentationStyle = .custom
        modalTransition = animatedTransition
        return animatedTransition
    }

    /// 设置iOS13默认present手势下拉dismiss时的回调block，仅iOS13生效，自动触发，手工dismiss不会触发。会自动设置presentationController.delegate
    public var presentationDidDismiss: (() -> Void)? {
        get {
            property(forName: "presentationDidDismiss") as? () -> Void
        }
        set {
            setPropertyCopy(newValue, forName: "presentationDidDismiss")
            base.presentationController?.delegate = presentationTarget
        }
    }

    /// 自定义控制器popover弹出效果(preferredContentSize设置大小)，会自动设置modalPresentationStyle和popoverPresentationController.delegate
    public func setPopoverPresentation(_ presentationBlock: (@MainActor @Sendable (UIPopoverPresentationController) -> Void)?, shouldDismiss: Bool) {
        base.modalPresentationStyle = .popover
        presentationTarget.isPopover = true
        presentationTarget.shouldDismiss = shouldDismiss
        base.popoverPresentationController?.delegate = presentationTarget
        if let popoverController = base.popoverPresentationController {
            presentationBlock?(popoverController)
        }
    }

    private var presentationTarget: PresentationTarget {
        if let target = property(forName: "presentationTarget") as? PresentationTarget {
            return target
        } else {
            let target = PresentationTarget()
            setProperty(target, forName: "presentationTarget")
            return target
        }
    }
}

// MARK: - Wrapper+UIView
@MainActor extension Wrapper where Base: UIView {
    /// 转场添加到指定控制器(pinEdges占满父视图)，返回父容器视图。默认inAncestorView开启时查找顺序：VC.tabBarController.view > VC.navigationController.view > VC.view
    @discardableResult
    public func transition(to viewController: UIViewController, inAncestorView: Bool = true, pinEdges aPinEdges: Bool = true) -> UIView {
        let ancestorView: UIView = inAncestorView ? viewController.fw.ancestorView : viewController.view
        ancestorView.addSubview(base)
        if aPinEdges {
            pinEdges(autoScale: false)
            ancestorView.setNeedsLayout()
            ancestorView.layoutIfNeeded()
        }
        return ancestorView
    }

    /// 包装到转场控制器(pinEdges占满父视图)，返回创建的控制器
    public func wrappedTransitionController(_ aPinEdges: Bool = true) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.addSubview(base)
        if aPinEdges {
            pinEdges(autoScale: false)
            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()
        }
        return viewController
    }

    /// 自定义视图模拟present系统转场(蒙层渐变，内容默认向上动画)
    public func setPresentTransition(_ transitionType: AnimatedTransitionType, contentView: UIView?, edge: UIRectEdge = .bottom, completion: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        let transform: CGAffineTransform
        switch edge {
        case .top:
            transform = .init(translationX: 0, y: -(contentView?.frame.size.height ?? 0))
        case .left:
            transform = .init(translationX: -(contentView?.frame.size.width ?? 0), y: 0)
        case .right:
            transform = .init(translationX: contentView?.frame.size.width ?? 0, y: 0)
        default:
            transform = .init(translationX: 0, y: contentView?.frame.size.height ?? 0)
        }

        let transitionIn = transitionType == .push || transitionType == .present
        if transitionIn {
            base.alpha = 0
            contentView?.transform = transform
            let strongBase = base
            UIView.animate(withDuration: 0.25) {
                contentView?.transform = .identity
                strongBase.alpha = 1
            } completion: { finished in
                completion?(finished)
            }
        } else {
            let strongBase = base
            UIView.animate(withDuration: 0.25) {
                contentView?.transform = transform
                strongBase.alpha = 0
            } completion: { finished in
                contentView?.transform = .identity
                strongBase.removeFromSuperview()
                completion?(finished)
            }
        }
    }

    /// 自定义视图模拟alert缩放转场(蒙层渐变，内容缩放动画)
    public func setAlertTransition(_ transitionType: AnimatedTransitionType, completion: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        let transitionIn = transitionType == .push || transitionType == .present
        if transitionIn {
            base.alpha = 0
            base.transform = .init(scaleX: 1.1, y: 1.1)
            let strongBase = base
            UIView.animate(withDuration: 0.25) {
                strongBase.transform = .identity
                strongBase.alpha = 1
            } completion: { finished in
                completion?(finished)
            }
        } else {
            let strongBase = base
            UIView.animate(withDuration: 0.25) {
                strongBase.alpha = 0
            } completion: { finished in
                strongBase.removeFromSuperview()
                completion?(finished)
            }
        }
    }

    /// 自定义视图模拟fade渐变转场(蒙层和内容渐变动画)
    public func setFadeTransition(_ transitionType: AnimatedTransitionType, completion: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        let transitionIn = transitionType == .push || transitionType == .present
        if transitionIn {
            base.alpha = 0
            let strongBase = base
            UIView.animate(withDuration: 0.25) {
                strongBase.alpha = 1
            } completion: { finished in
                completion?(finished)
            }
        } else {
            let strongBase = base
            UIView.animate(withDuration: 0.25) {
                strongBase.alpha = 0
            } completion: { finished in
                strongBase.removeFromSuperview()
                completion?(finished)
            }
        }
    }
}

// MARK: - Wrapper+UINavigationController
@MainActor extension Wrapper where Base: UINavigationController {
    /// 导航控制器push|pop转场。注意会修改delegate，且会强引用之，一直生效直到设置为nil。如需weak引用，请直接设置delegate
    public var navigationTransition: AnimatedTransition? {
        get {
            property(forName: "navigationTransition") as? AnimatedTransition
        }
        set {
            // 设置delegate动画，nil时清理delegate动画，无需清理CA动画
            base.delegate = newValue
            // 强引用，防止被自动释放，nil时释放引用
            setProperty(newValue, forName: "navigationTransition")
        }
    }
}

// MARK: - AnimatedTransition
/// 转场动画类型
public enum AnimatedTransitionType: Int, Sendable {
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

    /// 动画持续时间，必须大于0，默认同completionSpeed为0.35秒
    open var transitionDuration: TimeInterval = 0.35

    /// 获取动画类型，默认根据上下文判断
    open var transitionType: AnimatedTransitionType {
        get {
            // 如果自定义type，优先使用之
            if _transitionType != .none { return _transitionType }
            // 自动根据上下文获取type
            guard let transitionContext else { return .none }

            let fromVC = transitionContext.viewController(forKey: .from)
            let toVC = transitionContext.viewController(forKey: .to)
            // 导航栏为同一个时为push|pop
            if let fromNav = fromVC?.navigationController, let toNav = toVC?.navigationController, fromNav == toNav {
                let toIndex = toNav.viewControllers.firstIndex(of: toVC!)
                let fromIndex = fromNav.viewControllers.firstIndex(of: fromVC!)
                if let fromIndex, let toIndex, toIndex > fromIndex {
                    return .push
                } else {
                    return .pop
                }
            } else {
                if toVC?.presentingViewController == fromVC {
                    return .present
                } else {
                    return .dismiss
                }
            }
        }
        set {
            _transitionType = newValue
        }
    }

    private var _transitionType: AnimatedTransitionType = .none

    /// 创建动画转场
    override public init() {
        super.init()
        completionSpeed = 0.35
    }

    /// 创建动画句柄转场
    public convenience init(block: (@MainActor @Sendable (AnimatedTransition) -> Void)?) {
        self.init()
        self.transitionBlock = block
    }

    // MARK: - Interactive
    /// 是否启用交互pan手势进行pop|dismiss，默认false。可使用父类属性设置交互动画
    open var interactEnabled = false {
        didSet {
            _gestureRecognizer?.isEnabled = interactEnabled
        }
    }

    /// 指定与滚动视图pan手势的冲突交互方向，默认向下
    open var interactDirection: UISwipeGestureRecognizer.Direction = .down {
        didSet {
            (_gestureRecognizer as? PanGestureRecognizer)?.direction = interactDirection
        }
    }

    /// 是否启用screenEdge交互手势进行pop|dismiss，默认false。与gestureRecognizer可共存
    open var interactScreenEdge = false {
        didSet {
            _screenEdgeGestureRecognizer?.isEnabled = interactScreenEdge
        }
    }

    /// 是否正在交互中，手势开始才会标记为YES，手势结束标记为NO
    open private(set) var isInteracting = false

    /// 是否正在以交互方式dismiss|pop，需开启交互pan手势或screenEdge手势
    open private(set) var isInteractDismissing = false

    /// 自定义交互句柄，可根据手势state处理不同状态的交互，返回YES执行默认交互，返回NO不执行。默认为空，执行默认交互
    open var interactBlock: ((UIPanGestureRecognizer) -> Bool)?

    /// 自定义交互时dismiss关闭动画完成回调(仅交互才会触发)，默认nil
    open var interactDismissCompletion: (() -> Void)?

    /// 自定义dismiss关闭动画完成回调(交互和非交互都会触发)，默认nil
    open var dismissCompletion: (() -> Void)?

    /// 当前交互pan手势对象，默认PanGestureRecognizer，可设置交互方向，滚动视图等
    open var gestureRecognizer: UIPanGestureRecognizer {
        get {
            if let gesture = _gestureRecognizer {
                return gesture
            } else {
                let gesture = PanGestureRecognizer(target: self, action: #selector(gestureRecognizerAction(_:)))
                gesture.direction = interactDirection
                _gestureRecognizer = gesture
                return gesture
            }
        }
        set {
            _gestureRecognizer = newValue
            newValue.addTarget(self, action: #selector(gestureRecognizerAction(_:)))
        }
    }

    private var _gestureRecognizer: UIPanGestureRecognizer?

    /// 当前交互screenEdge手势对象，可设置交互边，默认left
    open var screenEdgeGestureRecognizer: UIScreenEdgePanGestureRecognizer {
        get {
            if let screenEdgeGesture = _screenEdgeGestureRecognizer {
                return screenEdgeGesture
            } else {
                let screenEdgeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(gestureRecognizerAction(_:)))
                screenEdgeGesture.edges = .left
                _screenEdgeGestureRecognizer = screenEdgeGesture
                return screenEdgeGesture
            }
        }
        set {
            _screenEdgeGestureRecognizer = newValue
            newValue.addTarget(self, action: #selector(gestureRecognizerAction(_:)))
        }
    }

    private var _screenEdgeGestureRecognizer: UIScreenEdgePanGestureRecognizer?

    /// 手工绑定交互控制器，添加pan手势或screenEdge手势，需要vc.view存在时调用才生效。默认自动绑定，如果自定义interactBlock，必须手工绑定
    open func interact(with viewController: UIViewController) {
        guard viewController.view != nil else { return }

        let gestureRecognizers = viewController.view.gestureRecognizers ?? []
        if interactEnabled, !gestureRecognizers.contains(gestureRecognizer) {
            viewController.view.addGestureRecognizer(gestureRecognizer)
        }
        if interactScreenEdge, !gestureRecognizers.contains(screenEdgeGestureRecognizer) {
            viewController.view.addGestureRecognizer(screenEdgeGestureRecognizer)
        }
    }

    // MARK: - Presentation
    /// 是否启用默认展示控制器，启用后自动设置presentationBlock返回PresentationController，默认false
    open var presentationEnabled: Bool {
        get {
            presentationBlock != nil
        }
        set {
            if newValue == presentationEnabled { return }
            if newValue {
                presentationBlock = { presented, presenting in
                    PresentationController(presentedViewController: presented, presenting: presenting)
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

    private var shouldInteract: Bool {
        !isSystem && (interactEnabled || interactScreenEdge)
    }

    private var interactBegan: (() -> Void)?

    @objc private func gestureRecognizerAction(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            isInteracting = true

            var shouldBegin = true
            if let interactBlock {
                shouldBegin = interactBlock(gestureRecognizer)
            }
            if shouldBegin && interactBegan != nil {
                interactBegan?()
            }
        case .changed:
            var interactChanged = true
            if let interactBlock {
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

                update(percent)
            }
        case .cancelled, .failed, .ended:
            isInteracting = false

            var interactEnded = true
            if let interactBlock {
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
                    finish()
                } else {
                    cancel()
                }
            }
        default:
            break
        }
    }

    private func interactiveTransition(for transition: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if transitionType == .dismiss || transitionType == .pop {
            if shouldInteract && isInteracting {
                isInteractDismissing = true
                return self
            }
        }
        isInteractDismissing = false
        return nil
    }

    // MARK: - UIViewControllerTransitioningDelegate
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionType = .present
        // 自动设置和绑定dismiss交互转场，在dismiss前设置生效
        if shouldInteract && interactBlock == nil {
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
        interactiveTransition(for: animator)
    }

    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactiveTransition(for: animator)
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
            let transition = toVC.fw.viewTransition ?? self
            transition.transitionType = .push
            // 自动设置和绑定pop交互转场，在pop前设置生效
            if transition.shouldInteract && transition.interactBlock == nil {
                transition.interactBegan = {
                    navigationController.popViewController(animated: true)
                }
                transition.interact(with: toVC)
            }
            return !transition.isSystem ? transition : nil
        } else if operation == .pop {
            // pop时检查fromVC的转场代理
            let transition = fromVC.fw.viewTransition ?? self
            transition.transitionType = .pop
            return !transition.isSystem ? transition : nil
        }
        return nil
    }

    open func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactiveTransition(for: animationController)
    }

    // MARK: - UIViewControllerAnimatedTransitioning
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        (transitionContext?.isAnimated ?? false) ? transitionDuration : 0
    }

    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext

        if transitionBlock != nil {
            transitionBlock?(self)
        } else {
            animate()
        }
    }

    // MARK: - Animate
    /// 转场上下文，只读
    open private(set) weak var transitionContext: UIViewControllerContextTransitioning?

    /// 标记动画开始(自动添加视图到容器)
    open func start() {
        let fromView = transitionContext?.view(forKey: .from)
        let toView = transitionContext?.view(forKey: .to)
        switch transitionType {
        // push时fromView在下，toView在上
        case .push:
            if let fromView { transitionContext?.containerView.addSubview(fromView) }
            if let toView { transitionContext?.containerView.addSubview(toView) }
        // pop时fromView在上，toView在下
        case .pop:
            if let toView { transitionContext?.containerView.addSubview(toView) }
            if let fromView { transitionContext?.containerView.addSubview(fromView) }
        // present时使用toView做动画
        case .present:
            if let toView { transitionContext?.containerView.addSubview(toView) }
        // dismiss时使用fromView做动画
        case .dismiss:
            if let fromView { transitionContext?.containerView.addSubview(fromView) }
        default:
            break
        }
    }

    /// 执行动画，子类重写，可选
    open func animate() {
        // 子类可重写，默认alpha动画
        let type = transitionType
        let transitionIn = type == .push || type == .present
        let transitionView = transitionIn ? transitionContext?.view(forKey: .to) : transitionContext?.view(forKey: .from)

        start()
        if transitionIn { transitionView?.alpha = 0 }
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveLinear) {
            transitionView?.alpha = transitionIn ? 1 : 0
        } completion: { _ in
            self.complete()
        }
    }

    /// 自动标记动画完成(根据transitionContext是否被取消判断)
    open func complete() {
        let type = transitionType
        let didComplete = !(transitionContext?.transitionWasCancelled ?? false)
        transitionContext?.completeTransition(didComplete)

        if didComplete, type == .dismiss {
            if isInteractDismissing { interactDismissCompletion?() }
            dismissCompletion?()
        }
    }
}

// MARK: - SwipeAnimatedTransition
/// 滑动转场动画类，默认上下
open class SwipeAnimatedTransition: AnimatedTransition {
    /// 创建滑动转场，指定转场边缘方向
    public convenience init(edge: UIRectEdge) {
        let inDirection: UISwipeGestureRecognizer.Direction
        let outDirection: UISwipeGestureRecognizer.Direction
        switch edge {
        case .top:
            inDirection = .down
            outDirection = .up
        case .left:
            inDirection = .right
            outDirection = .left
        case .right:
            inDirection = .left
            outDirection = .right
        default:
            inDirection = .up
            outDirection = .down
        }
        self.init(inDirection: inDirection, outDirection: outDirection)
    }

    /// 创建滑动转场，指定进入(push|present)和消失(pop|dismiss)方向
    public convenience init(inDirection: UISwipeGestureRecognizer.Direction, outDirection: UISwipeGestureRecognizer.Direction) {
        self.init()
        self.inDirection = inDirection
        self.outDirection = outDirection
        interactDirection = outDirection
    }

    /// 指定进入(push|present)方向，默认上滑Up
    open var inDirection: UISwipeGestureRecognizer.Direction = .up
    /// 指定消失(pop|dismiss)方向，默认下滑Down
    open var outDirection: UISwipeGestureRecognizer.Direction = .down {
        didSet { interactDirection = outDirection }
    }

    override open func animate() {
        let type = transitionType
        let transitionIn = type == .push || type == .present
        let direction = transitionIn ? inDirection : outDirection
        var offset: CGVector
        switch direction {
        case .left:
            offset = CGVector(dx: -1, dy: 0)
        case .right:
            offset = CGVector(dx: 1, dy: 0)
        case .up:
            offset = CGVector(dx: 0, dy: -1)
        default:
            offset = CGVector(dx: 0, dy: 1)
        }

        let fromVC = transitionContext?.viewController(forKey: .from)
        let toVC = transitionContext?.viewController(forKey: .to)
        let fromView = transitionContext?.view(forKey: .from)
        let toView = transitionContext?.view(forKey: .to)
        var fromFrame: CGRect = .zero
        if let fromVC {
            fromFrame = transitionContext?.initialFrame(for: fromVC) ?? .zero
        }
        var toFrame: CGRect = .zero
        if let toVC {
            toFrame = transitionContext?.finalFrame(for: toVC) ?? .zero
        }

        if transitionIn {
            if let toView {
                transitionContext?.containerView.addSubview(toView)
            }
            toView?.frame = animateFrame(frame: toFrame, offset: offset, initial: true, show: transitionIn)
            fromView?.frame = fromFrame
        } else {
            if let fromView {
                transitionContext?.containerView.addSubview(fromView)
                if let toView {
                    transitionContext?.containerView.insertSubview(toView, belowSubview: fromView)
                }
            }
            fromView?.frame = animateFrame(frame: fromFrame, offset: offset, initial: true, show: transitionIn)
            toView?.frame = toFrame
        }

        UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
            if transitionIn {
                toView?.frame = self.animateFrame(frame: toFrame, offset: offset, initial: false, show: transitionIn)
            } else {
                fromView?.frame = self.animateFrame(frame: fromFrame, offset: offset, initial: false, show: transitionIn)
            }
        } completion: { _ in
            if self.transitionContext?.transitionWasCancelled ?? false {
                toView?.removeFromSuperview()
            }
            self.complete()
        }
    }

    private func animateFrame(frame: CGRect, offset: CGVector, initial: Bool, show: Bool) -> CGRect {
        var vectorValue = offset.dx == 0 ? offset.dy : offset.dx
        var flag: CGFloat = 0
        if initial {
            vectorValue = vectorValue > 0 ? -vectorValue : vectorValue
            flag = show ? vectorValue : 0
        } else {
            vectorValue = vectorValue > 0 ? vectorValue : -vectorValue
            flag = show ? 0 : vectorValue
        }

        let offsetX = frame.size.width * offset.dx * flag
        let offsetY = frame.size.height * offset.dy * flag
        return CGRectOffset(frame, offsetX, offsetY)
    }
}

// MARK: - TransformAnimatedTransition
/// 形变转场动画类，默认缩放
open class TransformAnimatedTransition: AnimatedTransition {
    /// 创建Alert转场动画
    public static func alertTransition() -> TransformAnimatedTransition {
        TransformAnimatedTransition(inTransform: .init(scaleX: 1.1, y: 1.1), outTransform: .identity)
    }

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
    /// 是否启用透明度动画，默认true
    open var alphaAnimation = true

    override open func animate() {
        let type = transitionType
        let transitionIn = type == .push || type == .present
        let transitionView = transitionIn ? transitionContext?.view(forKey: .to) : transitionContext?.view(forKey: .from)

        start()
        if transitionIn {
            transitionView?.transform = inTransform
            if alphaAnimation {
                transitionView?.alpha = 0
            }
        }
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveLinear) {
            transitionView?.transform = transitionIn ? .identity : self.outTransform
            if self.alphaAnimation {
                transitionView?.alpha = transitionIn ? 1 : 0
            }
        } completion: { _ in
            self.complete()
        }
    }
}

// MARK: - PresentationController
/// 自定义展示控制器。默认显示暗色背景动画且弹出视图占满容器，可通过属性自定义
open class PresentationController: UIPresentationController {
    /// 是否显示暗色背景，默认true
    open var showDimming = true {
        didSet {
            dimmingView.isHidden = !showDimming
        }
    }

    /// 是否可以点击暗色背景关闭，默认true。如果弹出视图占满容器，手势不生效(因为弹出视图挡住了暗色背景)，也可开启弹出视图isPenetrable让手势强制生效
    open var dimmingClick = true {
        didSet {
            dimmingView.isUserInteractionEnabled = dimmingClick
        }
    }

    /// 是否执行暗黑背景透明度动画，默认true
    open var dimmingAnimated = true
    /// 暗色背景颜色，默认黑色，透明度0.5
    open var dimmingColor: UIColor? = UIColor.black.withAlphaComponent(0.5)
    /// 设置点击暗色背景关闭时是否执行动画，默认true
    open var dismissAnimated = true
    /// 设置点击暗色背景关闭完成回调(非交互才会触发)，默认nil
    open var dismissCompletion: (() -> Void)?

    /// 设置弹出视图的圆角位置，默认左上和右上。如果弹出视图占满容器，不生效需弹出视图自定义
    open var rectCorner: UIRectCorner = [.topLeft, .topRight]
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
    /// 设置弹出视图的横向距离，默认0占满容器，优先级低
    open var horizontalInset: CGFloat = 0

    private lazy var dimmingView: UIView = {
        let result = UIView(frame: containerView?.bounds ?? .zero)
        result.backgroundColor = dimmingColor
        result.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapAction(_:)))
        result.addGestureRecognizer(tapGesture)
        return result
    }()

    @objc func onTapAction(_ sender: Any) {
        presentedViewController.dismiss(animated: dismissAnimated, completion: dismissCompletion)
    }

    // MARK: - Override
    override open func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        presentedView?.frame = frameOfPresentedViewInContainerView
        if cornerRadius > 0 {
            presentedView?.layer.masksToBounds = true
            if rectCorner.contains(.allCorners) {
                presentedView?.layer.cornerRadius = cornerRadius
            } else {
                presentedView?.fw.setCornerLayer(rectCorner, radius: cornerRadius)
            }
        }
        dimmingView.frame = containerView?.bounds ?? .zero
        containerView?.insertSubview(dimmingView, at: 0)

        if dimmingAnimated {
            dimmingView.alpha = 0
            presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 1
            }, completion: nil)
        }
    }

    override open func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        if dimmingAnimated {
            presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0
            }, completion: nil)
        }
    }

    override open func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            dimmingView.removeFromSuperview()
        }
    }

    override open var frameOfPresentedViewInContainerView: CGRect {
        if let frameBlock {
            return frameBlock(self)
        } else if !CGRectEqualToRect(presentedFrame, .zero) {
            return presentedFrame
        } else if !CGSizeEqualToSize(presentedSize, .zero) {
            var frame = CGRect(x: 0, y: 0, width: presentedSize.width, height: presentedSize.height)
            frame.origin.x = ((containerView?.bounds.size.width ?? .zero) - presentedSize.width) / 2
            frame.origin.y = ((containerView?.bounds.size.height ?? .zero) - presentedSize.height) / 2
            return frame
        } else {
            var frame = containerView?.bounds ?? .zero
            if verticalInset != 0 {
                frame.origin.y = verticalInset
                frame.size.height -= verticalInset
            }
            if horizontalInset != 0 {
                frame.origin.x = horizontalInset
                frame.size.width -= horizontalInset * 2
            }
            return frame
        }
    }
}

// MARK: - PanGestureRecognizer
/// 自动处理与滚动视图pan手势在指定方向的冲突，默认设置delegate为自身。如果找到滚动视图则处理之，否则同父类
open class PanGestureRecognizer: UIPanGestureRecognizer, UIGestureRecognizerDelegate {
    /// 是否自动检测滚动视图，默认true。如需手工指定，请禁用之
    open var autoDetected = true

    /// 是否按下就立即转换Began状态，默认false，需要等待移动才会触发Began
    open var instantBegan = false

    /// 指定滚动视图，自动处理与滚动视图pan手势在指定方向的冲突。自动设置默认delegate为自身
    open weak var scrollView: UIScrollView?

    /// 指定与滚动视图pan手势的冲突交互方向，默认向下
    open var direction: UISwipeGestureRecognizer.Direction = .down

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

    /// 获取当前手势在指定交互方向的滑动进度
    open var swipePercent: CGFloat {
        guard let view,
              view.bounds.size.width > 0,
              view.bounds.size.height > 0 else { return 0 }

        var percent: CGFloat = 0
        let transition = translation(in: view)
        switch direction {
        case .left:
            percent = -transition.x / view.bounds.size.width
        case .right:
            percent = transition.x / view.bounds.size.width
        case .up:
            percent = -transition.y / view.bounds.size.height
        default:
            percent = transition.y / view.bounds.size.height
        }
        return max(0, min(percent, 1))
    }

    private var isFailed: Bool?

    override public init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        delegate = self
    }

    public convenience init() {
        self.init(target: nil, action: nil)
    }

    // MARK: - Override
    override open func reset() {
        super.reset()
        isFailed = nil
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if instantBegan && state == .began { return }
        super.touchesBegan(touches, with: event)
        if instantBegan { state = .began }
    }

    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard let scrollView, scrollView.isScrollEnabled else { return }

        if direction == .up || direction == .down {
            if !scrollView.fw.canScrollVertical { return }
        } else {
            if !scrollView.fw.canScrollHorizontal { return }
        }

        if state == .failed { return }
        if let isFailed {
            if isFailed {
                state = .failed
            }
            return
        }

        let velocity = velocity(in: view)
        let location = touches.first?.location(in: view) ?? .zero
        let prevLocation = touches.first?.previousLocation(in: view) ?? .zero
        if velocity == .zero && location == prevLocation { return }

        var isFailed = false
        switch direction {
        case .down:
            let edgeOffset = scrollView.fw.contentOffset(of: .top).y
            if (abs(velocity.x) < abs(velocity.y)) && (location.y > prevLocation.y) && (scrollView.contentOffset.y <= edgeOffset) {
                isFailed = false
            } else if scrollView.contentOffset.y >= edgeOffset {
                isFailed = true
            }
        case .up:
            let edgeOffset = scrollView.fw.contentOffset(of: .bottom).y
            if (abs(velocity.x) < abs(velocity.y)) && (location.y < prevLocation.y) && (scrollView.contentOffset.y >= edgeOffset) {
                isFailed = false
            } else if scrollView.contentOffset.y <= edgeOffset {
                isFailed = true
            }
        case .right:
            let edgeOffset = scrollView.fw.contentOffset(of: .left).x
            if (abs(velocity.y) < abs(velocity.x)) && (location.x > prevLocation.x) && (scrollView.contentOffset.x <= edgeOffset) {
                isFailed = false
            } else if scrollView.contentOffset.x >= edgeOffset {
                isFailed = true
            }
        case .left:
            let edgeOffset = scrollView.fw.contentOffset(of: .right).x
            if (abs(velocity.y) < abs(velocity.x)) && (location.x < prevLocation.x) && (scrollView.contentOffset.x >= edgeOffset) {
                isFailed = false
            } else if scrollView.contentOffset.x <= edgeOffset {
                isFailed = true
            }
        default:
            break
        }

        if isFailed, let shouldFailed {
            isFailed = shouldFailed(self)
        }

        if isFailed {
            state = .failed
            self.isFailed = true
        } else {
            self.isFailed = false
        }
    }

    // MARK: - UIGestureRecognizerDelegate
    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldBegin {
            return shouldBegin(self)
        }
        if maximumDistance <= 0 { return true }

        let location = gestureRecognizer.location(in: gestureRecognizer.view)
        switch direction {
        case .left:
            return (gestureRecognizer.view?.bounds.size.width ?? .zero) - location.x <= maximumDistance
        case .right:
            return location.x <= maximumDistance
        case .up:
            return (gestureRecognizer.view?.bounds.size.height ?? .zero) - location.y <= maximumDistance
        default:
            return location.y <= maximumDistance
        }
    }

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UIPanGestureRecognizer,
           let otherScrollView = otherGestureRecognizer.view as? UIScrollView {
            if autoDetected {
                if direction == .up || direction == .down {
                    if otherScrollView.fw.canScrollHorizontal { return false }
                } else {
                    if otherScrollView.fw.canScrollVertical { return false }
                }

                if otherScrollView != scrollView { scrollView = otherScrollView }
                return true
            } else {
                if scrollView == otherScrollView {
                    return true
                }
            }
        }
        return false
    }

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UIPanGestureRecognizer,
           let otherScrollView = otherGestureRecognizer.view as? UIScrollView {
            if autoDetected {
                if direction == .up || direction == .down {
                    if otherScrollView.fw.canScrollHorizontal { return false }
                } else {
                    if otherScrollView.fw.canScrollVertical { return false }
                }

                if otherScrollView != scrollView { scrollView = otherScrollView }
                if let shouldBeRequiredToFail {
                    return shouldBeRequiredToFail(otherGestureRecognizer)
                }
                return true
            } else {
                if scrollView == otherScrollView {
                    if let shouldBeRequiredToFail {
                        return shouldBeRequiredToFail(otherGestureRecognizer)
                    }
                    return true
                }
            }
        }
        return false
    }

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldRequireFailure {
            return shouldRequireFailure(otherGestureRecognizer)
        }
        return false
    }
}

// MARK: - PresentationTarget
private class PresentationTarget: NSObject, UIPopoverPresentationControllerDelegate {
    var isPopover = false
    var shouldDismiss = true

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        isPopover ? .none : controller.presentationStyle
    }

    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        shouldDismiss
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        shouldDismiss
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        presentationController.presentedViewController.fw.presentationDidDismiss?()
    }
}

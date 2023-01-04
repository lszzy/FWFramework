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
        let modalTransition = TransformAnimatedTransition(in: .init(scaleX: 1.1, y: 1.1), outTransform: .identity)
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

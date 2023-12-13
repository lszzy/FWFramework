//
//  ViewTransition+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

extension Wrapper where Base: UIViewController {
    
    /// 视图控制器present|dismiss转场。注意会修改transitioningDelegate，且会强引用之；如需weak引用，请直接设置transitioningDelegate
    public var modalTransition: AnimatedTransition? {
        get { return base.fw_modalTransition }
        set { base.fw_modalTransition = newValue }
    }

    /// 视图控制器push|pop转场，代理导航控制器转场，需在fwNavigationTransition设置后生效
    public var viewTransition: AnimatedTransition? {
        get { return base.fw_viewTransition }
        set { base.fw_viewTransition = newValue }
    }

    /// 自定义控制器present系统转场(蒙层渐变，内容向上动画)，会设置fwModalTransition
    @discardableResult
    public func setPresentTransition(_ presentationBlock: ((PresentationController) -> Void)? = nil) -> AnimatedTransition {
        return base.fw_setPresentTransition(presentationBlock)
    }

    /// 自定义控制器alert缩放转场(蒙层渐变，内容缩放动画)，会设置fwModalTransition
    @discardableResult
    public func setAlertTransition(_ presentationBlock: ((PresentationController) -> Void)? = nil) -> AnimatedTransition {
        return base.fw_setAlertTransition(presentationBlock)
    }
    
    /// 自定义控制器fade渐变转场(蒙层和内容渐变动画)，会设置fwModalTransition;
    @discardableResult
    public func setFadeTransition(_ presentationBlock: ((PresentationController) -> Void)? = nil) -> AnimatedTransition {
        return base.fw_setFadeTransition(presentationBlock)
    }
    
    /// 设置iOS13默认present手势下拉dismiss时的回调block，仅iOS13生效，自动触发，手工dismiss不会触发。会自动设置presentationController.delegate
    public var presentationDidDismiss: (() -> Void)? {
        get { return base.fw_presentationDidDismiss }
        set { base.fw_presentationDidDismiss = newValue }
    }

    /// 自定义控制器popover弹出效果(preferredContentSize设置大小)，会自动设置modalPresentationStyle和popoverPresentationController.delegate
    public func setPopoverPresentation(_ presentationBlock: ((UIPopoverPresentationController) -> Void)?, shouldDismiss: Bool) {
        base.fw_setPopoverPresentation(presentationBlock, shouldDismiss: shouldDismiss)
    }
    
}

extension Wrapper where Base: UIView {
    
    /// 转场添加到指定控制器(pinEdges占满父视图)，返回父容器视图。VC.tabBarController.view > VC.navigationController.view > VC.view
    @discardableResult
    public func transition(to viewController: UIViewController, pinEdges: Bool = true) -> UIView {
        return base.fw_transition(to: viewController, pinEdges: pinEdges)
    }

    /// 包装到转场控制器(pinEdges占满父视图)，返回创建的控制器
    public func wrappedTransitionController(_ pinEdges: Bool = true) -> UIViewController {
        return base.fw_wrappedTransitionController(pinEdges)
    }

    /// 自定义视图模拟present系统转场(蒙层渐变，内容向上动画)
    public func setPresentTransition(_ transitionType: AnimatedTransitionType, contentView: UIView?, completion: ((Bool) -> Void)? = nil) {
        base.fw_setPresentTransition(transitionType, contentView: contentView, completion: completion)
    }

    /// 自定义视图模拟alert缩放转场(蒙层渐变，内容缩放动画)
    public func setAlertTransition(_ transitionType: AnimatedTransitionType, completion: ((Bool) -> Void)? = nil) {
        base.fw_setAlertTransition(transitionType, completion: completion)
    }

    /// 自定义视图模拟fade渐变转场(蒙层和内容渐变动画)
    public func setFadeTransition(_ transitionType: AnimatedTransitionType, completion: ((Bool) -> Void)? = nil) {
        base.fw_setFadeTransition(transitionType, completion: completion)
    }
    
}

extension Wrapper where Base: UINavigationController {
    
    /// 导航控制器push|pop转场。注意会修改delegate，且会强引用之，一直生效直到设置为nil。如需weak引用，请直接设置delegate
    public var navigationTransition: AnimatedTransition? {
        get { return base.fw_navigationTransition }
        set { base.fw_navigationTransition = newValue }
    }
    
}

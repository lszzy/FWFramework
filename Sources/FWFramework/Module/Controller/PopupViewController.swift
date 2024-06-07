//
//  PopupViewController.swift
//  FWFramework
//
//  Created by wuyong on 2024/6/7.
//

import UIKit

// MARK: - PopupConfiguration
/// 弹窗配置类
open class PopupConfiguration {
    
    /// 弹出位置枚举
    public enum Position: Int {
        case bottom = 0
        case top
        case left
        case right
        case center
    }
    
    /// 弹出位置，默认bottom
    open var position: Position = .bottom
    /// 弹出视图的内边距，随位置变化，默认0
    open var padding: CGFloat = 0
    /// 弹出视图的圆角半径，随位置变化，默认0无圆角
    open var cornerRadius: CGFloat = 0
    /// 弹出视图的背景颜色，默认白色
    open var backgroundColor: UIColor? = UIColor.white
    
    /// 是否显示暗色背景，默认YES
    open var showDimming = true
    /// 是否可以点击暗色背景关闭，默认YES
    open var dimmingClick = true
    /// 是否执行暗黑背景透明度动画，默认YES
    open var dimmingAnimated = true
    /// 暗色背景颜色，默认黑色，透明度0.5
    open var dimmingColor: UIColor? = UIColor.black.withAlphaComponent(0.5)
    
    /// 中心弹窗时是否执行alert动画，默认true，否则fade动画，仅center生效
    open var alertAnimation = true
    /// 动画持续时间，必须大于0，默认同completionSpeed为0.35秒
    open var animationDuration: TimeInterval = 0.35
    /// 动画完成速度，默认0.35
    open var completionSpeed: CGFloat = 0.35
    /// 底部弹窗时是否启用screenEdge交互手势，默认false，仅bottom生效
    open var interactScreenEdge = false
    
    /// 设置点击暗色背景关闭时是否执行动画，默认true
    open var dismissAnimated = true
    /// 设置点击暗色背景关闭完成回调，默认nil
    open var dismissCompletion: (() -> Void)?
    
    public init() {}
}

// MARK: - PopupViewControllerProtocol
/// 弹窗视图控制器协议，可覆写
public protocol PopupViewControllerProtocol: ViewControllerProtocol {

    /// 弹窗内容容器视图，高度(或宽度，视位置而定)需内容撑开，内容子视图需要添加到此视图上
    var popupView: UIView { get }
    
    /// 弹窗背景视图，占满view，非内容视图可添加到此视图上
    var popupBackground: UIView { get }
    
    /// 当前只读弹窗配置，自动调用setupPopupConfiguration
    var popupConfiguration: PopupConfiguration { get }
    
    /// 初始化弹窗配置，默认空实现
    func setupPopupConfiguration(_ configuration: PopupConfiguration)

    /// 渲染弹窗内容视图，setupSubviews之前调用，默认空实现
    func setupPopupView()

    /// 渲染弹窗内容视图布局，setupSubviews之前调用，默认空实现
    func setupPopupLayout()
    
    /// 弹窗包装到导航控制器，同步设置导航控制器转场动画，弹窗需要push时使用，默认已实现
    func wrappedNavigationController() -> UINavigationController
    
}

extension PopupViewControllerProtocol where Self: UIViewController {
    
    /// 弹窗内容容器视图，高度(或宽度，视位置而定)需内容撑开，内容子视图需要添加到此视图上
    public var popupView: UIView {
        if let result = fw.property(forName: "popupView") as? UIView {
            return result
        } else {
            let result = UIView()
            fw.setProperty(result, forName: "popupView")
            return result
        }
    }
    
    /// 弹窗背景视图，占满view，非内容视图可添加到此视图上
    public var popupBackground: UIView {
        if let result = fw.property(forName: "popupBackground") as? UIView {
            return result
        } else {
            let result = UIView()
            result.backgroundColor = .clear
            fw.setProperty(result, forName: "popupBackground")
            return result
        }
    }
    
    /// 当前只读弹窗配置，自动调用setupPopupConfiguration
    public var popupConfiguration: PopupConfiguration {
        if let result = fw.property(forName: "popupConfiguration") as? PopupConfiguration {
            return result
        } else {
            let result = PopupConfiguration()
            setupPopupConfiguration(result)
            fw.setProperty(result, forName: "popupConfiguration")
            return result
        }
    }
    
    /// 初始化弹窗配置，默认空实现
    public func setupPopupConfiguration(_ configuration: PopupConfiguration) {}

    /// 渲染弹窗内容视图，setupSubviews之前调用，默认空实现
    public func setupPopupView() {}

    /// 渲染弹窗内容视图布局，setupSubviews之前调用，默认空实现
    public func setupPopupLayout() {}
    
    /// 弹窗包装到导航控制器，同步设置导航控制器转场动画，弹窗需要push时使用，默认已实现
    public func wrappedNavigationController() -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: self)
        navigationController.modalPresentationStyle = .custom
        navigationController.fw.modalTransition = self.fw.modalTransition
        return navigationController
    }
    
}

// MARK: - ViewControllerManager+PopupViewControllerProtocol
internal extension ViewControllerManager {
    
    func popupViewControllerInit(_ viewController: UIViewController) {
        guard let popupController = viewController as? UIViewController & PopupViewControllerProtocol else { return }
        
        let popupConfiguration = popupController.popupConfiguration
        let modalTransition: AnimatedTransition
        switch popupConfiguration.position {
        case .top:
            modalTransition = SwipeAnimatedTransition(inDirection: .down, outDirection: .up)
        case .left:
            modalTransition = SwipeAnimatedTransition(inDirection: .right, outDirection: .left)
        case .right:
            modalTransition = SwipeAnimatedTransition(inDirection: .left, outDirection: .right)
        case .center:
            modalTransition = popupConfiguration.alertAnimation ? TransformAnimatedTransition.alertTransition() : AnimatedTransition()
        default:
            modalTransition = SwipeAnimatedTransition()
            if popupConfiguration.interactScreenEdge {
                modalTransition.interactEnabled = true
                modalTransition.interactScreenEdge = true
                modalTransition.dismissCompletion = popupConfiguration.dismissCompletion
            }
        }
        
        modalTransition.transitionDuration = popupConfiguration.animationDuration
        modalTransition.completionSpeed = popupConfiguration.completionSpeed
        modalTransition.presentationBlock = { [weak popupController] presented, presenting in
            let presentation = PresentationController(presentedViewController: presented, presenting: presenting)
            presentation.showDimming = popupController?.popupConfiguration.showDimming ?? true
            presentation.dimmingClick = false
            presentation.dimmingAnimated = popupController?.popupConfiguration.dimmingAnimated ?? true
            presentation.dimmingColor = popupController?.popupConfiguration.dimmingColor
            return presentation
        }
        
        viewController.fw.navigationBarHidden = true
        viewController.modalPresentationStyle = .custom
        viewController.fw.modalTransition = modalTransition
    }
    
    func popupViewControllerViewDidLoad(_ viewController: UIViewController) {
        guard let viewController = viewController as? UIViewController & PopupViewControllerProtocol else { return }
        
        viewController.view.backgroundColor = .clear
        
        let popupConfiguration = viewController.popupConfiguration
        let popupBackground = viewController.popupBackground
        popupBackground.isUserInteractionEnabled = popupConfiguration.dimmingClick
        popupBackground.fw.addTapGesture { [weak viewController] _ in
            viewController?.dismiss(animated: viewController?.popupConfiguration.dismissAnimated ?? true, completion: viewController?.popupConfiguration.dismissCompletion)
        }
        viewController.view.addSubview(popupBackground)
        
        let popupView = viewController.popupView
        popupView.backgroundColor = popupConfiguration.backgroundColor
        viewController.view.addSubview(popupView)
        
        popupBackground.fw.pinEdges()
        switch popupConfiguration.position {
        case .top:
            viewController.popupView.fw.pinEdge(toSuperview: .top)
            viewController.popupView.fw.pinHorizontal(toSuperview: popupConfiguration.padding)
                .forEach { $0.fw.autoScaleLayout = false }
        case .left:
            viewController.popupView.fw.pinEdge(toSuperview: .left)
            viewController.popupView.fw.pinVertical(toSuperview: popupConfiguration.padding)
                .forEach { $0.fw.autoScaleLayout = false }
        case .right:
            viewController.popupView.fw.pinEdge(toSuperview: .right)
            viewController.popupView.fw.pinVertical(toSuperview: popupConfiguration.padding)
                .forEach { $0.fw.autoScaleLayout = false }
        case .center:
            viewController.popupView.fw.alignAxis(toSuperview: .centerY)
            viewController.popupView.fw.pinHorizontal(toSuperview: popupConfiguration.padding)
                .forEach { $0.fw.autoScaleLayout = false }
        default:
            viewController.popupView.fw.pinEdge(toSuperview: .bottom)
            viewController.popupView.fw.pinHorizontal(toSuperview: popupConfiguration.padding)
                .forEach { $0.fw.autoScaleLayout = false }
        }
        
        hookPopupViewController?(viewController)
        
        viewController.setupPopupView()
        viewController.setupPopupLayout()
        popupView.setNeedsLayout()
        popupView.layoutIfNeeded()
    }
    
    func popupViewControllerViewDidLayoutSubviews(_ viewController: UIViewController) {
        guard let viewController = viewController as? UIViewController & PopupViewControllerProtocol else { return }
        
        let popupConfiguration = viewController.popupConfiguration
        switch popupConfiguration.position {
        case .top:
            viewController.popupView.fw.setCornerLayer([.bottomLeft, .bottomRight], radius: popupConfiguration.cornerRadius)
        case .left:
            viewController.popupView.fw.setCornerLayer([.topRight, .bottomRight], radius: popupConfiguration.cornerRadius)
        case .right:
            viewController.popupView.fw.setCornerLayer([.topLeft, .bottomLeft], radius: popupConfiguration.cornerRadius)
        case .center:
            viewController.popupView.fw.setCornerRadius(popupConfiguration.cornerRadius)
        default:
            viewController.popupView.fw.setCornerLayer([.topLeft, .topRight], radius: popupConfiguration.cornerRadius)
        }
    }
    
}

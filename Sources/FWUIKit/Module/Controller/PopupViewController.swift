//
//  PopupViewController.swift
//  FWFramework
//
//  Created by wuyong on 2024/6/7.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - PopupConfiguration
/// 弹窗配置类
open class PopupConfiguration {
    /// 弹出视图的内边距，随位置变化，默认0
    open var padding: CGFloat = 0
    /// 弹出视图的圆角半径，随位置变化，默认0无圆角
    open var cornerRadius: CGFloat = 0
    /// 弹出视图的背景颜色，默认白色
    open var backgroundColor: UIColor? = UIColor.white

    /// 动画边缘方向，默认bottom，与centerAnimation互斥
    open var animationEdge: UIRectEdge = .bottom
    /// 是否中心弹窗动画，默认false，与animationEdge互斥
    open var centerAnimation = false
    /// 中心弹窗时是否执行alert动画，默认true，否则fade动画，仅centerAnimation生效
    open var alertAnimation = true
    /// 动画持续时间，必须大于0，默认同completionSpeed为0.35秒
    open var animationDuration: TimeInterval = 0.35
    /// 动画完成速度，默认0.35
    open var completionSpeed: CGFloat = 0.35
    /// 是否启用交互pan手势进行pop|dismiss，默认false，仅animationEdge生效
    open var interactEnabled = false
    /// 是否启用screenEdge交互手势进行pop|dismiss，默认false，仅animationEdge为left|right时生效
    open var interactScreenEdge = false

    /// 是否显示暗色背景，默认YES
    open var showDimming = true
    /// 是否可以点击暗色背景关闭，默认YES
    open var dimmingClick = true
    /// 是否执行暗黑背景透明度动画，默认YES
    open var dimmingAnimated = true
    /// 暗色背景颜色，默认黑色，透明度0.5
    open var dimmingColor: UIColor? = UIColor.black.withAlphaComponent(0.5)

    /// 设置点击暗色背景关闭时是否执行动画，默认true
    open var dismissAnimated = true
    /// 设置弹窗关闭完成回调(交互和非交互都会触发)，默认nil
    open var dismissCompletion: (@MainActor @Sendable () -> Void)?

    public init() {}
}

// MARK: - PopupViewControllerProtocol
/// 弹窗视图控制器协议，可覆写
@MainActor public protocol PopupViewControllerProtocol: ViewControllerProtocol {
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
        navigationController.fw.modalTransition = fw.modalTransition
        return navigationController
    }
}

// MARK: - ViewControllerManager+PopupViewControllerProtocol
extension ViewControllerManager {
    @MainActor func popupViewControllerInit(_ viewController: UIViewController) {
        guard let popupController = viewController as? UIViewController & PopupViewControllerProtocol else { return }

        let popupConfiguration = popupController.popupConfiguration
        let modalTransition: AnimatedTransition
        if popupConfiguration.centerAnimation {
            modalTransition = popupConfiguration.alertAnimation ? TransformAnimatedTransition.alertTransition() : AnimatedTransition()
        } else {
            modalTransition = SwipeAnimatedTransition(edge: popupConfiguration.animationEdge)
            modalTransition.interactEnabled = popupConfiguration.interactEnabled
            modalTransition.interactDismissCompletion = popupConfiguration.dismissCompletion
            if popupConfiguration.animationEdge == .top || popupConfiguration.animationEdge == .bottom {
                modalTransition.interactScreenEdge = popupConfiguration.interactScreenEdge
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

    @MainActor func popupViewControllerViewDidLoad(_ viewController: UIViewController) {
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

        popupBackground.fw.pinEdges(autoScale: false)
        if popupConfiguration.centerAnimation {
            viewController.popupView.fw.alignAxis(toSuperview: .centerY, autoScale: false)
            viewController.popupView.fw.pinHorizontal(toSuperview: popupConfiguration.padding, autoScale: false)
        } else {
            switch popupConfiguration.animationEdge {
            case .top:
                viewController.popupView.fw.pinEdge(toSuperview: .top, autoScale: false)
                viewController.popupView.fw.pinHorizontal(toSuperview: popupConfiguration.padding, autoScale: false)
            case .left:
                viewController.popupView.fw.pinEdge(toSuperview: .left, autoScale: false)
                viewController.popupView.fw.pinVertical(toSuperview: popupConfiguration.padding, autoScale: false)
            case .right:
                viewController.popupView.fw.pinEdge(toSuperview: .right, autoScale: false)
                viewController.popupView.fw.pinVertical(toSuperview: popupConfiguration.padding, autoScale: false)
            default:
                viewController.popupView.fw.pinEdge(toSuperview: .bottom, autoScale: false)
                viewController.popupView.fw.pinHorizontal(toSuperview: popupConfiguration.padding, autoScale: false)
            }
        }

        hookPopupViewController?(viewController)

        viewController.setupPopupView()
        viewController.setupPopupLayout()
        popupView.setNeedsLayout()
        popupView.layoutIfNeeded()
    }

    @MainActor func popupViewControllerViewDidLayoutSubviews(_ viewController: UIViewController) {
        guard let viewController = viewController as? UIViewController & PopupViewControllerProtocol else { return }

        let popupConfiguration = viewController.popupConfiguration
        if popupConfiguration.centerAnimation {
            viewController.popupView.fw.setCornerRadius(popupConfiguration.cornerRadius)
        } else {
            switch popupConfiguration.animationEdge {
            case .top:
                viewController.popupView.fw.setCornerLayer([.bottomLeft, .bottomRight], radius: popupConfiguration.cornerRadius)
            case .left:
                viewController.popupView.fw.setCornerLayer([.topRight, .bottomRight], radius: popupConfiguration.cornerRadius)
            case .right:
                viewController.popupView.fw.setCornerLayer([.topLeft, .bottomLeft], radius: popupConfiguration.cornerRadius)
            default:
                viewController.popupView.fw.setCornerLayer([.topLeft, .topRight], radius: popupConfiguration.cornerRadius)
            }
        }
    }
}

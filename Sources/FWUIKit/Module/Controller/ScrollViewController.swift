//
//  ScrollViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - ScrollViewControllerProtocol
/// 滚动视图控制器协议，可覆写
@MainActor public protocol ScrollViewControllerProtocol: ViewControllerProtocol {
    /// 滚动视图，默认不显示滚动条
    var scrollView: UIScrollView { get }

    /// 内容容器视图，自动撑开，子视图需要添加到此视图上
    var contentView: UIView { get }

    /// 渲染滚动视图，setupSubviews之前调用，默认空实现
    func setupScrollView()

    /// 渲染滚动视图布局，setupSubviews之前调用，默认铺满
    func setupScrollLayout()
}

extension ScrollViewControllerProtocol where Self: UIViewController {
    /// 滚动视图，默认不显示滚动条
    public var scrollView: UIScrollView {
        if let result = fw.property(forName: "scrollView") as? UIScrollView {
            return result
        } else {
            let result = UIScrollView()
            result.showsVerticalScrollIndicator = false
            result.showsHorizontalScrollIndicator = false
            fw.setProperty(result, forName: "scrollView")
            return result
        }
    }

    /// 内容容器视图，自动撑开，子视图需要添加到此视图上
    public var contentView: UIView {
        if let result = fw.property(forName: "contentView") as? UIView {
            return result
        } else {
            let result = UIView()
            fw.setProperty(result, forName: "contentView")
            return result
        }
    }

    /// 渲染滚动视图，setupSubviews之前调用，默认空实现
    public func setupScrollView() {}

    /// 渲染滚动视图布局，setupSubviews之前调用，默认铺满
    public func setupScrollLayout() {
        scrollView.fw.pinEdges(autoScale: false)
    }
}

// MARK: - ViewControllerManager+ScrollViewControllerProtocol
extension ViewControllerManager {
    @MainActor func scrollViewControllerViewDidLoad(_ viewController: UIViewController) {
        guard let viewController = viewController as? UIViewController & ScrollViewControllerProtocol else { return }

        let scrollView = viewController.scrollView
        if let popupController = viewController as? PopupViewControllerProtocol {
            popupController.popupView.addSubview(scrollView)
        } else {
            viewController.view.addSubview(scrollView)
        }

        let contentView = viewController.contentView
        scrollView.addSubview(contentView)
        contentView.fw.pinEdges(autoScale: false)

        hookScrollViewController?(viewController)

        viewController.setupScrollView()
        viewController.setupScrollLayout()
        scrollView.setNeedsLayout()
        scrollView.layoutIfNeeded()
    }
}

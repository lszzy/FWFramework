//
//  NavigationView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

/// 导航栏配置，兼容AnyView和UIKit对象
@MainActor public struct NavigationBarConfiguration {
    public var leading: Any?
    public var title: Any?
    public var trailing: Any?
    public var background: Any?
    public var style: NavigationBarStyle?
    public var appearance: (@MainActor @Sendable () -> NavigationBarAppearance)?
    public var customize: (@MainActor @Sendable (UIViewController) -> Void)?

    public init(
        leading: Any? = nil,
        title: Any? = nil,
        trailing: Any? = nil,
        background: Any? = nil,
        style: NavigationBarStyle? = nil,
        appearance: (@MainActor @Sendable () -> NavigationBarAppearance)? = nil,
        customize: (@MainActor @Sendable (UIViewController) -> Void)? = nil
    ) {
        self.leading = leading
        self.title = title
        self.trailing = trailing
        self.background = background
        self.style = style
        self.appearance = appearance
        self.customize = customize
    }

    public func configure(
        viewController: UIViewController
    ) {
        if let leading = leading as? AnyView {
            if viewController.navigationItem.leftBarButtonItem == nil {
                viewController.navigationItem.leftBarButtonItem = .init(customView: HostingView(rootView: leading))
            } else if let view = viewController.navigationItem.leftBarButtonItem?.customView as? HostingView<AnyView> {
                view.rootView = leading
            } else {
                viewController.navigationItem.leftBarButtonItem?.customView = HostingView(rootView: leading)
            }
        } else if let leading {
            viewController.fw.leftBarItem = leading
        }

        if let title = title as? AnyView {
            if let view = viewController.navigationItem.titleView as? HostingView<AnyView> {
                view.rootView = title
            } else {
                viewController.navigationItem.titleView = HostingView(rootView: title)
            }
        } else if let title {
            if let titleView = title as? UIView {
                viewController.navigationItem.titleView = titleView
            } else if let titleString = title as? String {
                viewController.navigationItem.title = titleString
            }
        }

        if let trailing = trailing as? AnyView {
            if viewController.navigationItem.rightBarButtonItem == nil {
                viewController.navigationItem.rightBarButtonItem = .init(customView: HostingView(rootView: trailing))
            } else if let view = viewController.navigationItem.rightBarButtonItem?.customView as? HostingView<AnyView> {
                view.rootView = trailing
            } else {
                viewController.navigationItem.rightBarButtonItem?.customView = HostingView(rootView: trailing)
            }
        } else if let trailing {
            viewController.fw.rightBarItem = trailing
        }

        viewController.navigationItem.leftItemsSupplementBackButton = false
        viewController.navigationItem.leftBarButtonItem?.customView?.sizeToFit()
        viewController.navigationItem.titleView?.sizeToFit()
        viewController.navigationItem.rightBarButtonItem?.customView?.sizeToFit()

        if let appearance {
            viewController.fw.navigationBarAppearance = appearance()
        } else if let style {
            viewController.fw.navigationBarStyle = style
        } else if let background {
            let appearance = NavigationBarAppearance()
            if let color = background as? Color {
                appearance.backgroundColor = color.toUIColor()
            } else if let uiColor = background as? UIColor {
                appearance.backgroundColor = uiColor
            } else if let image = background as? UIImage {
                appearance.backgroundImage = image
            } else if let transparent = background as? Bool {
                appearance.backgroundTransparent = transparent
            }
            viewController.fw.navigationBarAppearance = appearance
        }

        customize?(viewController)
    }
}

@MainActor extension View {
    /// 配置导航栏SwiftUI左侧、标题、右侧视图和背景
    public func navigationBarConfigure<Leading: View, Title: View, Trailing: View>(
        leading: Leading,
        title: Title,
        trailing: Trailing,
        background: Color? = nil
    ) -> some View {
        navigationBarConfigure(NavigationBarConfiguration(
            leading: AnyView(leading),
            title: AnyView(title),
            trailing: AnyView(trailing),
            background: background
        ))
    }

    /// 配置导航栏SwiftUI左侧、标题视图和背景
    public func navigationBarConfigure<Leading: View, Title: View>(
        leading: Leading,
        title: Title,
        background: Color? = nil
    ) -> some View {
        navigationBarConfigure(NavigationBarConfiguration(
            leading: AnyView(leading),
            title: AnyView(title),
            background: background
        ))
    }

    /// 配置导航栏SwiftUI标题视图和背景
    public func navigationBarConfigure<Title: View>(
        title: Title,
        background: Color? = nil
    ) -> some View {
        navigationBarConfigure(NavigationBarConfiguration(
            title: AnyView(title),
            background: background
        ))
    }

    /// 配置导航栏SwiftUI标题、右侧视图和背景
    public func navigationBarConfigure<Title: View, Trailing: View>(
        title: Title,
        trailing: Trailing,
        background: Color? = nil
    ) -> some View {
        navigationBarConfigure(NavigationBarConfiguration(
            title: AnyView(title),
            trailing: AnyView(trailing),
            background: background
        ))
    }

    /// 配置导航栏左侧、标题、右侧按钮和背景，兼容AnyView和UIKit对象
    public func navigationBarConfigure(
        leading: Any?,
        title: Any?,
        trailing: Any? = nil,
        background: Any? = nil
    ) -> some View {
        navigationBarConfigure(NavigationBarConfiguration(
            leading: leading,
            title: title,
            trailing: trailing,
            background: background
        ))
    }

    /// 配置当前导航栏
    public func navigationBarConfigure(
        _ configuration: NavigationBarConfiguration,
        viewContext: ViewContext? = nil
    ) -> some View {
        viewControllerConfigure({ viewController in
            configuration.configure(viewController: viewController)
        }, viewContext: viewContext)
    }
}

#endif

//
//  ViewConfigure.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - View+Configure
@MainActor extension View {
    /// 初始化当前顶部视图控制器，仅调用一次
    public func viewControllerInitialize(
        _ initialization: @escaping @MainActor @Sendable (UIViewController) -> Void,
        viewContext: ViewContext? = nil
    ) -> some View {
        viewControllerConfigure({ viewController in
            guard !viewController.fw.propertyBool(forName: "viewControllerInitialize") else { return }
            viewController.fw.setPropertyBool(true, forName: "viewControllerInitialize")

            initialization(viewController)
        }, viewContext: viewContext)
    }

    /// 配置当前顶部视图控制器，可调用多次
    public func viewControllerConfigure(
        _ configuration: @escaping @MainActor @Sendable (UIViewController) -> Void,
        viewContext: ViewContext? = nil
    ) -> some View {
        introspect(.view, on: .iOS(.all)) { view in
            if let viewController = viewContext?.viewController {
                configuration(viewController)
                return
            }

            var hostingView: UIView?
            var superview = view.superview
            while let s = superview {
                if NSStringFromClass(type(of: s)).contains("HostingView") {
                    hostingView = s
                    break
                }
                superview = s.superview
            }
            guard let hostingView else {
                return
            }

            var viewController: UIViewController?
            if let superController = hostingView.superview?.fw.viewController,
               !(superController is UINavigationController) && !(superController is UITabBarController) {
                viewController = superController
            } else {
                viewController = hostingView.fw.viewController
            }
            guard let viewController else {
                return
            }

            if let targetController = viewController.navigationController?.viewControllers.reversed()
                .first(where: { hostingView.isDescendant(of: $0.view) }) {
                configuration(targetController)
            } else {
                configuration(viewController)
            }
        }
    }

    /// 初始化当前SwiftUI视图对应UIView，仅调用一次。仅适用于有对应UIView的视图(如Text等)，不支持Layer视图(如VStack等)
    public func hostingViewInitialize(
        _ initialization: @escaping @MainActor @Sendable (UIView) -> Void
    ) -> some View {
        hostingViewConfigure { hostingView in
            guard !hostingView.fw.propertyBool(forName: "hostingViewInitialize") else { return }
            hostingView.fw.setPropertyBool(true, forName: "hostingViewInitialize")

            initialization(hostingView)
        }
    }

    /// 配置当前SwiftUI视图对应UIView，可调用多次。仅适用于有对应UIView的视图(如Text等)，不支持Layer视图(如VStack等)
    public func hostingViewConfigure(
        _ configuration: @escaping @MainActor @Sendable (UIView) -> Void
    ) -> some View {
        introspect(.view, on: .iOS(.all)) { hostingView in
            configuration(hostingView)
        }
    }
}

// MARK: - ScrollView+Configure
@MainActor extension View {
    /// 初始化ScrollView视图，仅调用一次，一般用于绑定下拉刷新、上拉追加等
    public func scrollViewInitialize(
        _ initialization: @escaping @MainActor @Sendable (UIScrollView) -> Void
    ) -> some View {
        scrollViewConfigure { scrollView in
            guard !scrollView.fw.propertyBool(forName: "scrollViewInitialize") else { return }
            scrollView.fw.setPropertyBool(true, forName: "scrollViewInitialize")

            initialization(scrollView)
        }
    }

    /// 配置ScrollView视图，可调用多次
    public func scrollViewConfigure(
        _ configuration: @escaping @MainActor @Sendable (UIScrollView) -> Void
    ) -> some View {
        introspect(.scrollView, on: .iOS(.all)) { scrollView in
            configuration(scrollView)
        }
    }

    /// 绑定ScrollView下拉刷新插件，action必须调用completionHandler，可指定是否已加载完成不能继续追加
    public func scrollViewRefreshing(
        shouldBegin: Binding<Bool>? = nil,
        loadingFinished: Binding<Bool?>? = nil,
        action: @escaping @MainActor @Sendable (@escaping @MainActor @Sendable (_ finished: Bool?) -> Void) -> Void,
        customize: (@MainActor @Sendable (UIScrollView) -> Void)? = nil
    ) -> some View {
        scrollViewConfigure { scrollView in
            if !scrollView.fw.propertyBool(forName: "scrollViewRefreshing") {
                scrollView.fw.setPropertyBool(true, forName: "scrollViewRefreshing")

                scrollView.fw.setRefreshing { [weak scrollView] in
                    action { finished in
                        scrollView?.fw.endRefreshing()
                        if let finished {
                            scrollView?.fw.loadingFinished = finished
                        }
                    }
                }
                customize?(scrollView)
            }

            if shouldBegin?.wrappedValue == true {
                shouldBegin?.wrappedValue = false

                if !scrollView.fw.isRefreshing {
                    scrollView.fw.beginRefreshing()
                }
            }

            if let finished = loadingFinished?.wrappedValue {
                loadingFinished?.wrappedValue = nil

                scrollView.fw.loadingFinished = finished
            }
        }
    }

    /// 绑定ScrollView上拉追加插件，action必须调用completionHandler，可指定是否已加载完成不能继续追加
    public func scrollViewLoading(
        shouldBegin: Binding<Bool>? = nil,
        loadingFinished: Binding<Bool?>? = nil,
        action: @escaping @MainActor @Sendable (@escaping @MainActor @Sendable (_ finished: Bool?) -> Void) -> Void,
        customize: (@MainActor @Sendable (UIScrollView) -> Void)? = nil
    ) -> some View {
        scrollViewConfigure { scrollView in
            if !scrollView.fw.propertyBool(forName: "scrollViewLoading") {
                scrollView.fw.setPropertyBool(true, forName: "scrollViewLoading")

                scrollView.fw.setLoading { [weak scrollView] in
                    action { finished in
                        scrollView?.fw.endLoading()
                        if let finished {
                            scrollView?.fw.loadingFinished = finished
                        }
                    }
                }
                customize?(scrollView)
            }

            if shouldBegin?.wrappedValue == true {
                shouldBegin?.wrappedValue = false

                if !scrollView.fw.isLoading {
                    scrollView.fw.beginLoading()
                }
            }

            if let finished = loadingFinished?.wrappedValue {
                loadingFinished?.wrappedValue = nil

                scrollView.fw.loadingFinished = finished
            }
        }
    }

    /// 显示ScrollView空界面插件，需手工切换，空界面显示时也可滚动
    public func showScrollEmpty(_ isShowing: Bool, customize: (@MainActor @Sendable (UIScrollView) -> Void)? = nil) -> some View {
        scrollViewConfigure { scrollView in
            if isShowing {
                if let customize {
                    customize(scrollView)
                } else {
                    scrollView.fw.showEmptyView()
                }
            } else {
                if scrollView.fw.hasEmptyView {
                    scrollView.fw.hideEmptyView()
                }
            }
        }
    }
}

// MARK: - List+Configure
@MainActor extension View {
    /// 重置List样式，去除多余间距等，可指定背景色
    /// - Parameters:
    ///   - background: 自定义背景色，默认nil时不处理
    ///   - isPlainStyle: 是否是plain样式，默认false，如果是则会自动清除iOS16+多余的Header顶部间距
    /// - Returns: View
    public func resetListStyle(background: Color? = nil, isPlainStyle: Bool = false) -> some View {
        then(background) { view, color in
            if #available(iOS 16.0, *) {
                return view.scrollContentBackground(.hidden)
                    .background(color)
                    .eraseToAnyView()
            } else {
                return view.background(color)
                    .eraseToAnyView()
            }
        }
        .then(isPlainStyle && UIDevice.fw.iosVersion >= 16, body: { view in
            view.introspect(.list, on: .iOS(.v16Later)) { collectionView in
                guard !collectionView.fw.propertyBool(forName: "resetListStyle") else { return }
                collectionView.fw.setPropertyBool(true, forName: "resetListStyle")

                if #available(iOS 16.0, *) {
                    guard collectionView.collectionViewLayout is UICollectionViewCompositionalLayout else { return }

                    var layoutConfig = UICollectionLayoutListConfiguration(appearance: .plain)
                    layoutConfig.showsSeparators = false
                    layoutConfig.headerMode = .supplementary
                    layoutConfig.headerTopPadding = 0
                    collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
                }
            }
        })
        .then(UIDevice.fw.iosVersion < 16) { view in
            view.introspect(.list, on: .iOS(.v15Earlier)) { tableView in
                if !tableView.fw.propertyBool(forName: "resetListStyle") {
                    tableView.fw.setPropertyBool(true, forName: "resetListStyle")

                    if #available(iOS 15.0, *) {
                        tableView.sectionHeaderTopPadding = 0
                    }
                }

                tableView.separatorStyle = .none
                tableView.separatorColor = .clear
                if let background {
                    tableView.backgroundColor = background.toUIColor()
                }
            }
        }
        .eraseToAnyView()
    }

    /// 重置Header|Footer样式，左对齐并去除多余间距，可指定背景色
    public func resetHeaderStyle(background: Color? = nil) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .listRowInsets(.zero)
            .then { view in
                if #available(iOS 15.0, *) {
                    return view.listSectionSeparator(.hidden)
                        .eraseToAnyView()
                } else {
                    return view.eraseToAnyView()
                }
            }
            .then(background, body: { view, color in
                view.background(color)
            })
            .eraseToAnyView()
    }

    /// 重置Cell样式，左对齐并隐藏分割线、去除多余间距，可指定背景色
    public func resetCellStyle(background: Color? = nil) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .then { view in
                if #available(iOS 15.0, *) {
                    return view.listRowInsets(.zero)
                        .listRowSeparator(.hidden)
                        .eraseToAnyView()
                } else {
                    return view.listRowInsets(EdgeInsets(top: -1, leading: -1, bottom: -1, trailing: -1))
                        .eraseToAnyView()
                }
            }
            .then(background, body: { view, color in
                view.background(color)
            })
            .eraseToAnyView()
    }

    /// 初始化List视图，仅调用一次，一般用于绑定下拉刷新、上拉追加等
    ///
    /// 注意：iOS16以上scrollView为UICollectionView，iOS16以下为UITableView
    public func listViewInitialize(
        _ initialization: @escaping @MainActor @Sendable (UIScrollView) -> Void
    ) -> some View {
        listViewConfigure { scrollView in
            guard !scrollView.fw.propertyBool(forName: "listViewInitialize") else { return }
            scrollView.fw.setPropertyBool(true, forName: "listViewInitialize")

            initialization(scrollView)
        }
    }

    /// 配置List视图，可调用多次
    ///
    /// 注意：iOS16以上scrollView为UICollectionView，iOS16以下为UITableView
    public func listViewConfigure(
        _ configuration: @escaping @MainActor @Sendable (UIScrollView) -> Void
    ) -> some View {
        introspect(.list, on: .iOS(.v15Earlier)) { tableView in
            configuration(tableView)
        }
        .introspect(.list, on: .iOS(.v16Later)) { collectionView in
            configuration(collectionView)
        }
    }

    /// 绑定List下拉刷新插件，action必须调用completionHandler，可指定是否已加载完成不能继续追加
    public func listViewRefreshing(
        shouldBegin: Binding<Bool>? = nil,
        loadingFinished: Binding<Bool?>? = nil,
        action: @escaping @MainActor @Sendable (@escaping @MainActor @Sendable (_ finished: Bool?) -> Void) -> Void,
        customize: (@MainActor @Sendable (UIScrollView) -> Void)? = nil
    ) -> some View {
        listViewConfigure { scrollView in
            if !scrollView.fw.propertyBool(forName: "listViewRefreshing") {
                scrollView.fw.setPropertyBool(true, forName: "listViewRefreshing")

                scrollView.fw.setRefreshing { [weak scrollView] in
                    action { finished in
                        scrollView?.fw.endRefreshing()
                        if let finished {
                            scrollView?.fw.loadingFinished = finished
                        }
                    }
                }
                customize?(scrollView)
            }

            if shouldBegin?.wrappedValue == true {
                shouldBegin?.wrappedValue = false

                if !scrollView.fw.isRefreshing {
                    scrollView.fw.beginRefreshing()
                }
            }

            if let finished = loadingFinished?.wrappedValue {
                loadingFinished?.wrappedValue = nil

                scrollView.fw.loadingFinished = finished
            }
        }
    }

    /// 绑定List上拉追加插件，action必须调用completionHandler，可指定是否已加载完成不能继续追加
    public func listViewLoading(
        shouldBegin: Binding<Bool>? = nil,
        loadingFinished: Binding<Bool?>? = nil,
        action: @escaping @MainActor @Sendable (@escaping @MainActor @Sendable (_ finished: Bool?) -> Void) -> Void,
        customize: (@MainActor @Sendable (UIScrollView) -> Void)? = nil
    ) -> some View {
        listViewConfigure { scrollView in
            if !scrollView.fw.propertyBool(forName: "listViewLoading") {
                scrollView.fw.setPropertyBool(true, forName: "listViewLoading")

                scrollView.fw.setLoading { [weak scrollView] in
                    action { finished in
                        scrollView?.fw.endLoading()
                        if let finished {
                            scrollView?.fw.loadingFinished = finished
                        }
                    }
                }
                customize?(scrollView)
            }

            if shouldBegin?.wrappedValue == true {
                shouldBegin?.wrappedValue = false

                if !scrollView.fw.isLoading {
                    scrollView.fw.beginLoading()
                }
            }

            if let finished = loadingFinished?.wrappedValue {
                loadingFinished?.wrappedValue = nil

                scrollView.fw.loadingFinished = finished
            }
        }
    }

    /// 显示List空界面插件，需手工切换，空界面显示时也可滚动
    public func showListEmpty(_ isShowing: Bool, customize: (@MainActor @Sendable (UIScrollView) -> Void)? = nil) -> some View {
        listViewConfigure { scrollView in
            if isShowing {
                if let customize {
                    customize(scrollView)
                } else {
                    scrollView.fw.showEmptyView()
                }
            } else {
                if scrollView.fw.hasEmptyView {
                    scrollView.fw.hideEmptyView()
                }
            }
        }
    }
}

// MARK: - TextField+Configure
@MainActor extension View {
    /// 初始化TextField视图，仅调用一次，一般用于配置键盘管理，自动聚焦等
    public func textFieldInitialize(
        _ initialization: @escaping @MainActor @Sendable (UITextField) -> Void,
        autoFocus viewContext: ViewContext? = nil
    ) -> some View {
        textFieldConfigure { textField in
            guard !textField.fw.propertyBool(forName: "textFieldInitialize") else { return }
            textField.fw.setPropertyBool(true, forName: "textFieldInitialize")

            if let viewController = viewContext?.viewController {
                viewController.fw.observeLifecycleState { [weak textField] vc, state in
                    if state == .didAppear {
                        textField?.becomeFirstResponder()
                    } else if state == .willDisappear {
                        vc.view.endEditing(true)
                    }
                }
            }

            initialization(textField)
        }
    }

    /// 配置TextField视图，可调用多次
    public func textFieldConfigure(
        _ configuration: @escaping @MainActor @Sendable (UITextField) -> Void
    ) -> some View {
        introspect(.textField, on: .iOS(.all)) { textField in
            configuration(textField)
        }
    }

    /// 初始化TextView视图，仅调用一次，一般用于配置键盘管理，自动聚焦等
    public func textViewInitialize(
        _ initialization: @escaping @MainActor @Sendable (UITextView) -> Void,
        autoFocus viewContext: ViewContext? = nil
    ) -> some View {
        textViewConfigure { textView in
            guard !textView.fw.propertyBool(forName: "textViewInitialize") else { return }
            textView.fw.setPropertyBool(true, forName: "textViewInitialize")

            if let viewController = viewContext?.viewController {
                viewController.fw.observeLifecycleState { [weak textView] vc, state in
                    if state == .didAppear {
                        textView?.becomeFirstResponder()
                    } else if state == .willDisappear {
                        vc.view.endEditing(true)
                    }
                }
            }

            initialization(textView)
        }
    }

    /// 配置TextView视图，可调用多次
    public func textViewConfigure(
        _ configuration: @escaping @MainActor @Sendable (UITextView) -> Void
    ) -> some View {
        introspect(.textEditor, on: .iOS(.v14Later)) { textView in
            configuration(textView)
        }
    }
}

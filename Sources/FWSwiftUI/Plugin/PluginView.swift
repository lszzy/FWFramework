//
//  PluginView.swift
//  
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
import FWFramework
#endif

// MARK: - LoadingPluginView
/// 加载插件视图包装器
@available(iOS 13.0, *)
public struct LoadingPluginView: UIViewRepresentable {
    
    var text: Any?
    var cancelBlock: (() -> Void)?
    
    public init(text: Any? = nil) {
        self.text = text
    }
    
    public func text(_ text: Any?) -> Self {
        var result = self
        result.text = text
        return result
    }
    
    public func onCancel(_ action: (() -> Void)?) -> Self {
        var result = self
        result.cancelBlock = action
        return result
    }
    
    // MARK: - UIViewRepresentable
    public typealias UIViewType = UIView
    
    public func makeUIView(context: Context) -> UIView {
        let uiView = UIView()
        uiView.fw.showLoading(text: text, cancel: cancelBlock)
        return uiView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        uiView.fw.showLoading(text: text, cancel: cancelBlock)
    }
    
    public static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        uiView.fw.hideLoading()
    }
}

// MARK: - ProgressPluginView
/// 进度插件视图包装器
@available(iOS 13.0, *)
public struct ProgressPluginView: UIViewRepresentable {
    
    var progress: CGFloat?
    var text: Any?
    var cancelBlock: (() -> Void)?
    
    public init(_ progress: CGFloat? = nil) {
        self.progress = progress
    }
    
    public func progress(_ progress: CGFloat?) -> Self {
        var result = self
        result.progress = progress
        return result
    }
    
    public func text(_ text: Any?) -> Self {
        var result = self
        result.text = text
        return result
    }
    
    public func onCancel(_ action: (() -> Void)?) -> Self {
        var result = self
        result.cancelBlock = action
        return result
    }
    
    // MARK: - UIViewRepresentable
    public typealias UIViewType = UIView
    
    public func makeUIView(context: Context) -> UIView {
        let uiView = UIView()
        if let progress = progress {
            uiView.fw.showProgress(progress, text: text, cancel: cancelBlock)
        }
        return uiView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        if let progress = progress {
            uiView.fw.showProgress(progress, text: text, cancel: cancelBlock)
        } else {
            uiView.fw.hideProgress()
        }
    }
    
    public static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        uiView.fw.hideProgress()
    }
}

// MARK: - EmptyPluginView
/// 空界面插件视图包装器
@available(iOS 13.0, *)
public struct EmptyPluginView: UIViewRepresentable {
    
    var text: String? = nil
    var detail: String? = nil
    var image: UIImage? = nil
    var loading: Bool = false
    var actions: [String]? = nil
    var block: ((Int, Any) -> Void)? = nil
    
    public init() {}
    
    public func text(_ text: String?) -> Self {
        var result = self
        result.text = text
        return result
    }
    
    public func detail(_ detail: String?) -> Self {
        var result = self
        result.detail = detail
        return result
    }
    
    public func image(_ image: UIImage?) -> Self {
        var result = self
        result.image = image
        return result
    }
    
    public func loading(_ loading: Bool) -> Self {
        var result = self
        result.loading = loading
        return result
    }

    public func action(_ action: String?, block: ((Any) -> Void)?) -> Self {
        var result = self
        if let action = action {
            result.actions = [action]
        } else {
            result.actions = nil
        }
        if let block = block {
            result.block = { _, sender in
                block(sender)
            }
        } else {
            result.block = nil
        }
        return result
    }
    
    public func actions(_ actions: [String]?, block: ((Int, Any) -> Void)?) -> Self {
        var result = self
        result.actions = actions
        result.block = block
        return result
    }
    
    // MARK: - UIViewRepresentable
    public typealias UIViewType = UIView
    
    public func makeUIView(context: Context) -> UIView {
        let uiView = UIView()
        uiView.fw.showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: actions, block: block)
        return uiView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        uiView.fw.showEmptyView(text: text, detail: detail, image: image, loading: loading, actions: actions, block: block)
    }
    
    public static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        uiView.fw.hideEmptyView()
    }
}

// MARK: - View+PluginView
@available(iOS 13.0, *)
extension View {
    
    // MARK: - Plugin
    /// 显示通用控制器插件，自动切换
    public func showPlugin(_ isShowing: Binding<Bool>, customize: @escaping (UIViewController) -> Void) -> some View {
        return then(isShowing.wrappedValue) { view in
            view.viewControllerConfigure { viewController in
                isShowing.wrappedValue = false
                customize(viewController)
            }
        }
    }
    
    /// 显示控制器弹窗插件，自动切换
    public func showAlert(_ isShowing: Binding<Bool>, customize: @escaping (UIViewController) -> Void) -> some View {
        return showPlugin(isShowing, customize: customize)
    }
    
    /// 显示控制器消息吐司插件，自动切换
    public func showToast(_ isShowing: Binding<Bool>, customize: @escaping (UIViewController) -> Void) -> some View {
        return showPlugin(isShowing, customize: customize)
    }
    
    /// 显示控制器空界面插件，需手工切换
    public func showEmpty(_ isShowing: Bool, customize: ((UIViewController) -> Void)? = nil) -> some View {
        return viewControllerConfigure { viewController in
            if isShowing {
                if let customize = customize {
                    customize(viewController)
                } else {
                    viewController.fw.showEmptyView()
                }
            } else {
                viewController.fw.hideEmptyView()
            }
        }
    }
    
    /// 显示控制器加载吐司插件，需手工切换
    public func showLoading(_ isShowing: Bool, customize: ((UIViewController) -> Void)? = nil) -> some View {
        return viewControllerConfigure { viewController in
            if isShowing {
                if let customize = customize {
                    customize(viewController)
                } else {
                    viewController.fw.showLoading()
                }
            } else {
                viewController.fw.hideLoading()
            }
        }
    }
    
    /// 显示控制器进度吐司插件，需手工切换
    public func showProgress(_ isShowing: Bool, customize: @escaping (UIViewController) -> Void) -> some View {
        return viewControllerConfigure { viewController in
            if isShowing {
                customize(viewController)
            } else {
                viewController.fw.hideProgress()
            }
        }
    }
    
    // MARK: - PluginView
    /// 显示通用插件视图，需手工切换
    public func showPluginView<Plugin: View>(
        _ isShowing: Bool = true,
        @ViewBuilder builder: @escaping () -> Plugin
    ) -> some View {
        ZStack {
            self
            if isShowing {
                builder()
            }
        }
    }
    
    /// 显示空界面插件视图，需手工切换
    public func showEmptyView(
        _ isShowing: Bool = true,
        builder: (() -> EmptyPluginView)? = nil
    ) -> some View {
        showPluginView(isShowing, builder: builder ?? {
            EmptyPluginView()
        })
    }
    
    /// 显示加载插件视图，需手工切换
    public func showLoadingView(
        _ isShowing: Bool = true,
        builder: (() -> LoadingPluginView)? = nil
    ) -> some View {
        showPluginView(isShowing, builder: builder ?? {
            LoadingPluginView()
        })
    }
    
    /// 显示进度插件视图，需手工切换
    public func showProgressView(
        _ isShowing: Bool = true,
        builder: @escaping () -> ProgressPluginView
    ) -> some View {
        showPluginView(isShowing, builder: builder)
    }
    
}

#endif
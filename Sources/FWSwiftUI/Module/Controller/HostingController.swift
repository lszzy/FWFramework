//
//  HostingController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - HostingController
/// SwiftUI控制器包装类，可将View事件用delegate代理到VC，兼容ViewControllerProtocol
///
/// Controller在MVVM中也为View的角色，可持有ViewModel，负责生命周期和界面跳转
open class HostingController: UIHostingController<AnyView> {
    // MARK: - Lifecyecle
    public init() {
        super.init(rootView: AnyView(EmptyView()))
        let isSetup = FrameworkConfiguration.isViewControllerProtocol?(self) ?? false
        if !isSetup {
            didInitialize()
        }
    }

    @MainActor public dynamic required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: AnyView(EmptyView()))
        let isSetup = FrameworkConfiguration.isViewControllerProtocol?(self) ?? false
        if !isSetup {
            didInitialize()
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        let isSetup = FrameworkConfiguration.isViewControllerProtocol?(self) ?? false
        if !isSetup {
            setupNavbar()
            setupSubviews()
            setupLayout()
        }
    }

    // MARK: - Setup
    /// 初始化完成，init自动调用，子类重写
    open func didInitialize() {}
    
    /// 初始化导航栏，viewDidLoad自动调用，子类重写
    open func setupNavbar() {}

    /// 初始化子视图，viewDidLoad自动调用，子类重写，可结合StateView实现状态机
    open func setupSubviews() {}

    /// 初始化布局，viewDidLoad自动调用，子类重写
    open func setupLayout() {}
}

#endif

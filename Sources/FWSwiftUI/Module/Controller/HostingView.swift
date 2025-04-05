//
//  HostingView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - HostingView
/// SwiftUI视图包装类
///
/// [SwiftUIX](https://github.com/SwiftUIX/SwiftUIX)
open class HostingView<Content: View>: UIView {
    // MARK: - Accessor
    public var shouldResizeToFitContent: Bool {
        get { rootViewHostingController.shouldResizeToFitContent }
        set { rootViewHostingController.shouldResizeToFitContent = newValue }
    }

    public var rootView: Content {
        get { rootViewHostingController.rootView.content }
        set {
            rootViewHostingController.rootView.content = newValue
            if shouldResizeToFitContent {
                invalidateIntrinsicContentSize()
            }
        }
    }

    private let rootViewHostingController: ContentHostingController

    struct ContentContainer: View {
        weak var parent: ContentHostingController?
        var content: Content

        var body: some View {
            content.onChangeOfFrame { [weak parent] _ in
                guard let parent else { return }
                if parent.shouldResizeToFitContent {
                    parent.view.invalidateIntrinsicContentSize()
                }
            }
            .frame(
                maxWidth: UIView.layoutFittingExpandedSize.width,
                maxHeight: UIView.layoutFittingExpandedSize.height,
                alignment: .center
            )
        }
    }

    class ContentHostingController: UIHostingController<ContentContainer> {
        weak var _navigationController: UINavigationController?
        var shouldResizeToFitContent: Bool = false

        override var navigationController: UINavigationController? {
            super.navigationController ?? _navigationController
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            view.backgroundColor = .clear
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            if shouldResizeToFitContent {
                view.invalidateIntrinsicContentSize()
            }
        }
    }

    // MARK: - Lifecycle
    public required init(rootView: Content) {
        self.rootViewHostingController = .init(rootView: .init(parent: nil, content: rootView))
        rootViewHostingController.rootView.parent = rootViewHostingController
        super.init(frame: .zero)

        addSubview(rootViewHostingController.view)
        rootViewHostingController.view.fw.pinEdges(autoScale: false)
        rootViewHostingController.view.backgroundColor = .clear
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func invalidateIntrinsicContentSize() {
        rootViewHostingController.view.invalidateIntrinsicContentSize()
        super.invalidateIntrinsicContentSize()
    }

    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: superview)
        let viewController = superview?.fw.viewController
        rootViewHostingController._navigationController = viewController?.navigationController ?? (viewController as? UINavigationController)
    }

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        let viewController = superview?.fw.viewController
        rootViewHostingController._navigationController = viewController?.navigationController ?? (viewController as? UINavigationController)
    }

    override open var intrinsicContentSize: CGSize {
        rootViewHostingController.view.intrinsicContentSize
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        rootViewHostingController.sizeThatFits(in: size)
    }

    override open func sizeToFit() {
        if let superview {
            frame.size = rootViewHostingController.sizeThatFits(in: superview.frame.size)
        } else {
            frame.size = rootViewHostingController.view.intrinsicContentSize
        }
    }

    override open func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        if shouldResizeToFitContent {
            invalidateIntrinsicContentSize()
        }
    }
}

// MARK: - View+HostingView
@MainActor extension View {
    /// 快速包装到HostingView
    public func wrappedHostingView(
        shouldResizeToFitContent: Bool = false
    ) -> HostingView<AnyView> {
        let hostingView = HostingView(rootView: AnyView(self))
        hostingView.shouldResizeToFitContent = shouldResizeToFitContent
        return hostingView
    }
}

#endif

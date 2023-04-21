//
//  HostingView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
import FWFramework
#endif

// MARK: - HostingView
/// SwiftUI视图包装类
///
/// [SwiftUIX](https://github.com/SwiftUIX/SwiftUIX)
@available(iOS 13.0, *)
open class HostingView<Content: View>: UIView {
    
    // MARK: - Accessor
    public var rootView: Content {
        get { contentHostingController.rootView.content }
        set { contentHostingController.rootView.content = newValue }
    }
    
    private let contentHostingController: ContentHostingController
    
    struct ContentContainer: View {
        weak var parent: ContentHostingController?
        
        var content: Content
        
        var body: some View {
            content
        }
    }
    
    class ContentHostingController: UIHostingController<ContentContainer> {
        weak var _navigationController: UINavigationController?
        
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
    }
    
    // MARK: - Lifecycle
    public required init(rootView: Content) {
        self.contentHostingController = .init(rootView: .init(parent: nil, content: rootView))
        self.contentHostingController.rootView.parent = contentHostingController
        super.init(frame: .zero)
                
        addSubview(contentHostingController.view)
        contentHostingController.view.backgroundColor = .clear
        contentHostingController.view.fw_pinEdges()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: superview)
        
        let viewController = superview?.fw_viewController
        contentHostingController._navigationController = viewController?.navigationController ?? (viewController as? UINavigationController)
    }
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        let viewController = superview?.fw_viewController
        contentHostingController._navigationController = viewController?.navigationController ?? (viewController as? UINavigationController)
    }
    
    open override var frame: CGRect {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    open override var bounds: CGRect {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    override open var intrinsicContentSize: CGSize {
        contentHostingController.view.intrinsicContentSize
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentHostingController.view.intrinsicContentSize
    }
    
}

// MARK: - View+HostingView
@available(iOS 13.0, *)
extension View {
    
    /// 快速包装到HostingView
    public func wrappedHostingView() -> HostingView<AnyView> {
        return HostingView(rootView: AnyView(self))
    }
    
}

#endif

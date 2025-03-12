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
        get {
            rootViewHostingController.shouldResizeToFitContent
        } set {
            rootViewHostingController.shouldResizeToFitContent = newValue
        }
    }
    
    public var rootView: Content {
        get {
            rootViewHostingController.rootView.content
        } set {
            rootViewHostingController.rootView.content = newValue
            
            if shouldResizeToFitContent {
                invalidateIntrinsicContentSize()
            }
        }
    }

    private let rootViewHostingController: _ContentHostingController

    struct _ContentContainer: View {
        weak var parent: _ContentHostingController?
        
        var content: Content
        
        var body: some View {
            content.onChangeOfFrame { [weak parent] _ in
                guard let parent = parent else {
                    return
                }
                
                if parent.shouldResizeToFitContent {
                    parent.view.invalidateIntrinsicContentSize()
                }
            }
            .frame(maxWidth: UIView.layoutFittingExpandedSize.width, maxHeight: UIView.layoutFittingExpandedSize.height, alignment: .center)
        }
    }

    class _ContentHostingController: UIHostingController<_ContentContainer> {
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
        
        public func sizeThatFits(
            _ proposal: LayoutSizeProposal
        ) -> CGSize {
            self.sizeThatFits(proposal, layoutImmediately: true)
        }
        
        public func sizeThatFits(
            _ sizeProposal: LayoutSizeProposal,
            layoutImmediately: Bool
        ) -> CGSize {
            let targetSize = sizeProposal._targetSize
            let fitSize = sizeProposal._fitSize

            guard !sizeProposal.fixedSize else {
                var result = targetSize
                
                if layoutImmediately {
                    view.sizeToFit()
                }
                
                let intrinsicContentSize = view.intrinsicContentSize
                
                if !intrinsicContentSize.width._isInvalidForIntrinsicContentSize {
                    result.width = intrinsicContentSize.width
                }
                
                if !intrinsicContentSize.height._isInvalidForIntrinsicContentSize {
                    result.height = intrinsicContentSize.height
                }
                
                return result
            }

            if layoutImmediately {
                view.setNeedsLayout()
                view.layoutIfNeeded()
            }

            var result: CGSize = sizeThatFits(in: fitSize)

            switch (result.width, result.height)  {
                case (UIView.layoutFittingExpandedSize.width, UIView.layoutFittingExpandedSize.height), (.greatestFiniteMagnitude, .greatestFiniteMagnitude), (.infinity, .infinity):
                    result = sizeThatFits(
                        in: targetSize.clamped(to: sizeProposal.size.maximum)
                    )
                case (UIView.layoutFittingExpandedSize.width, _), (.greatestFiniteMagnitude, _), (.infinity, _):
                    if !targetSize.width.isZero {
                        result = sizeThatFits(
                            in: CGSize(
                                width: targetSize.clamped(to: sizeProposal.size.maximum).width,
                                height: fitSize.height
                            )
                        )
                    }
                case (_, UIView.layoutFittingExpandedSize.height), (_, .greatestFiniteMagnitude), (_, .infinity):
                    if !targetSize.height.isZero {
                        result = sizeThatFits(
                            in: CGSize(
                                width: fitSize.width,
                                height: targetSize.clamped(to: sizeProposal.size.maximum).height
                            )
                        )
                    }
                case (.zero, 1...): do {
                    result = sizeThatFits(
                        in: CGSize(
                            width: UIView.layoutFittingExpandedSize.width,
                            height: fitSize.height
                        )
                    )
                }
                case (1..., .zero): do {
                    result = sizeThatFits(
                        in: CGSize(
                            width: fitSize.width,
                            height: UIView.layoutFittingExpandedSize.width
                        )
                    )
                }
                case (.zero, .zero): do {
                    result = sizeThatFits(
                        in: UIView.layoutFittingExpandedSize
                    )
                }
                default:
                    break
            }

            result = CGSize(
                width: sizeProposal.fit.horizontal == .required
                    ? targetSize.width
                    : result.width,
                height: sizeProposal.fit.vertical == .required
                    ? targetSize.height
                    : result.height
            )

            if result.width.isZero && !result.height.isZero {
                result = .init(width: 1, height: result.height)
            } else if !result.width.isZero && result.height.isZero {
                result = .init(width: result.width, height: 1)
            }

            return result.clamped(to: sizeProposal.size.maximum)
        }
    }

    // MARK: - Lifecycle
    public required init(rootView: Content) {
        self.rootViewHostingController = .init(rootView: .init(parent: nil, content: rootView))
        self.rootViewHostingController.rootView.parent = rootViewHostingController

        super.init(frame: .zero)
                
        addSubview(rootViewHostingController.view)
        
        rootViewHostingController.view.fw.pinEdges(autoScale: false)
        rootViewHostingController.view.backgroundColor = .clear
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func invalidateIntrinsicContentSize() {
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

    override open func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        rootViewHostingController.sizeThatFits(.init(targetSize: targetSize))
    }
    
    override open func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        rootViewHostingController.sizeThatFits(
            .init(
                targetSize: targetSize,
                horizontalFittingPriority: horizontalFittingPriority,
                verticalFittingPriority: verticalFittingPriority
            )
        )
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        systemLayoutSizeFitting(size)
    }
    
    override open func sizeToFit() {
        if let superview = superview {
            frame.size = rootViewHostingController.sizeThatFits(in: superview.frame.size)
        } else {
            frame.size = rootViewHostingController.sizeThatFits(nil)
        }
    }
    
    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        
        if shouldResizeToFitContent {
            invalidateIntrinsicContentSize()
        }
    }
}

// MARK: - View+HostingView
@MainActor extension View {
    /// 快速包装到HostingView
    public func wrappedHostingView() -> HostingView<AnyView> {
        HostingView(rootView: AnyView(self))
    }
    
    /// Frame改变时触发动作
    public func onChangeOfFrame(
        threshold: CGFloat? = nil,
        onAppear: Bool = false,
        perform action: @escaping (CGSize) -> Void
    ) -> some View {
        modifier(_OnChangeOfFrame(threshold: threshold, action: action, onAppear: onAppear))
    }
}

// MARK: - _OnChangeOfFrame
private struct _OnChangeOfFrame: ViewModifier {
    let threshold: CGFloat?
    let action: (CGSize) -> Void
    let onAppear: Bool

    @ViewStorage var oldSize: CGSize? = nil
    
    func body(content: Content) -> some View {
        content.background {
            GeometryReader { proxy in
                InvisibleView()
                    .onAppear {
                        self.oldSize = proxy.size
                        
                        if onAppear {
                            self.action(proxy.size)
                        }
                    }
                    ._onChange(of: proxy.size) { newSize in
                        if let oldSize {
                            if let threshold {
                                guard !(abs(oldSize.width - newSize.width) < threshold && abs(oldSize.height - newSize.height) < threshold) else {
                                    return
                                }
                            } else {
                                guard oldSize != newSize else {
                                    return
                                }
                            }
                            
                            action(newSize)
                            
                            self.oldSize = newSize
                        } else {
                            self.oldSize = newSize
                        }
                    }
            }
            .allowsHitTesting(false)
            .accessibility(hidden: true)
        }
    }
}

extension View {
    @_disfavoredOverload
    @inlinable
    public func background<Background: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ background: () -> Background
    ) -> some View {
        self.background(background(), alignment: alignment)
    }
    
    @ViewBuilder
    public func _onChange<V: Equatable>(
        of value: V,
        perform action: @escaping (V) -> Void
    ) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { oldValue, newValue in
                action(newValue)
            }
        } else if #available(iOS 14.0, *) {
            onChange(of: value, perform: action)
        } else {
            OnChangeOfValue(base: self, value: value, action: action)
        }
    }
}

private struct OnChangeOfValue<Base: View, Value: Equatable>: View {
    private class ValueBox {
        private var savedValue: Value?
        
        func update(value: Value) -> Bool {
            guard value != savedValue else {
                return false
            }
            
            savedValue = value
            
            return true
        }
    }
    
    let base: Base
    let value: Value
    let action: (Value) -> Void
    
    @State private var valueBox = ValueBox()
    @State private var oldValue: Value?
    
    public var body: some View {
        if valueBox.update(value: value) {
            DispatchQueue.main.async {
                action(value)
                
                oldValue = value
            }
        }
        
        return base
    }
}

public struct LayoutSizeProposal: Hashable {
    public struct _SizingConstraints: Hashable {
        public fileprivate(set) var minimum: OptionalDimensions
        public fileprivate(set) var target: OptionalDimensions
        public fileprivate(set) var maximum: OptionalDimensions
        
        public init(
            minimum: OptionalDimensions,
            target: OptionalDimensions,
            maximum: OptionalDimensions
        ) {
            self.minimum = minimum
            self.target = target
            self.maximum = maximum
        }
        
        public init(
            target: OptionalDimensions,
            maximum: OptionalDimensions
        ) {
            self.init(minimum: nil, target: target, maximum: maximum)
        }
    }
    
    public struct _Fit: Hashable {
        public let horizontal: UILayoutPriority?
        public let vertical: UILayoutPriority?
        
        public init(horizontal: UILayoutPriority?, vertical: UILayoutPriority?) {
            self.horizontal = horizontal
            self.vertical = vertical
        }
    }
    
    @usableFromInline
    fileprivate(set) var size: _SizingConstraints
    @usableFromInline
    fileprivate(set) var fit: _Fit
    
    var fixedSize: Bool {
        if fit.horizontal == .required && fit.vertical == .required {
            return true
        } else {
            return false
        }
    }
}

extension LayoutSizeProposal {
    public init(
        size: (target: OptionalDimensions, max: OptionalDimensions),
        fit: _Fit
    ) {
        self.size = .init(minimum: nil, target: size.target, maximum: size.max)
        self.fit = fit
    }

    public init(
        targetSize: OptionalDimensions,
        maximumSize: OptionalDimensions,
        horizontalFittingPriority: UILayoutPriority? = nil,
        verticalFittingPriority: UILayoutPriority? = nil
    ) {
        self.size = .init(minimum: nil, target: targetSize, maximum: maximumSize)
        self.fit = .init(horizontal: horizontalFittingPriority, vertical: verticalFittingPriority)
    }
    
    public init<T: _CustomOptionalDimensionsConvertible>(
        targetSize: T,
        horizontalFittingPriority: UILayoutPriority? = nil,
        verticalFittingPriority: UILayoutPriority? = nil
    ) {
        self.init(
            targetSize: .init(targetSize),
            maximumSize: nil,
            horizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
    }
    
    public init<T: _CustomOptionalDimensionsConvertible>(
        _ size: T,
        fixedSize: (horizontal: Bool, vertical: Bool)? = nil
    ) {
        self.init(
            targetSize: size,
            horizontalFittingPriority: fixedSize.map({ $0.horizontal ? .required : .defaultLow }),
            verticalFittingPriority: fixedSize.map({ $0.vertical ? .required : .defaultLow })
        )
    }
    
    public init(width: CGFloat?, height: CGFloat?) {
        self.init(OptionalDimensions(width: width, height: height), fixedSize: nil)
    }
    
    public init(
        fixedSize: (horizontal: Bool, vertical: Bool)
    ) {
        self.init(OptionalDimensions(), fixedSize: fixedSize)
    }

    public init<T0: _CustomOptionalDimensionsConvertible, T1: _CustomOptionalDimensionsConvertible>(
        targetSize: T0,
        maximumSize: T1,
        horizontalFittingPriority: UILayoutPriority? = nil,
        verticalFittingPriority: UILayoutPriority? = nil
    ) {
        self.init(
            targetSize: .init(targetSize),
            maximumSize: .init(maximumSize),
            horizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
    }
}

extension LayoutSizeProposal {
    var _targetSize: CGSize {
        let width = size.target.width ?? ((fit.horizontal ?? .defaultLow) != .required ? UIView.layoutFittingExpandedSize.width : UIView.layoutFittingCompressedSize.width)
        let height = size.target.height ?? ((fit.vertical ?? .defaultLow) != .required ? UIView.layoutFittingExpandedSize.height : UIView.layoutFittingCompressedSize.height)
        
        return CGSize(width: width, height: height)
    }
    
    var _fitSize: CGSize {
        let targetWidth = size.target.clamped(to: size.maximum).width
        let targetHeight = size.target.clamped(to: size.maximum).height

        let width = fit.horizontal == .required
            ? (targetWidth ?? UIView.layoutFittingCompressedSize.width)
            : (size.maximum.width ?? UIView.layoutFittingExpandedSize.width)
        
        let height = fit.vertical == .required
            ? (targetHeight ?? UIView.layoutFittingCompressedSize.height)
            : (size.maximum.height ?? UIView.layoutFittingExpandedSize.height)
        
        return CGSize(width: width, height: height)
    }
}

extension LayoutSizeProposal: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init(
            targetSize: nil,
            maximumSize: nil,
            horizontalFittingPriority: nil,
            verticalFittingPriority: nil
        )
    }
}

public protocol _CustomOptionalDimensionsConvertible {
    func _toOptionalDimensions() -> OptionalDimensions
}

@_frozen
public struct OptionalDimensions: ExpressibleByNilLiteral, Hashable {
    public static var greatestFiniteDimensions: OptionalDimensions {
        .init(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
    }
    
    public static var infinite: OptionalDimensions {
        .init(width: .infinity, height: .infinity)
    }

    public var width: CGFloat?
    public var height: CGFloat?
    
    public init(width: CGFloat?, height: CGFloat?) {
        self.width = width
        self.height = height
    }
    
    public init<T: _CustomOptionalDimensionsConvertible>(_ size: T) {
        self = size._toOptionalDimensions()
    }
    
    public init<T: _CustomOptionalDimensionsConvertible>(_ size: T?) {
        if let size = size {
            self.init(size)
        } else {
            self.init(nilLiteral: ())
        }
    }

    public init(nilLiteral: ()) {
        self.init(width: nil, height: nil)
    }
        
    public init() {
        
    }
}

extension OptionalDimensions {
    public mutating func clamp(to dimensions: OptionalDimensions) {
        if let maxWidth = dimensions.width {
            if let width = self.width {
                self.width = min(width, maxWidth)
            } else {
                self.width = maxWidth
            }
        }
        
        if let maxHeight = dimensions.height {
            if let height = self.height {
                self.height = min(height, maxHeight)
            } else {
                self.height = maxHeight
            }
        }
    }
    
    public func clamped(to dimensions: OptionalDimensions?) -> Self {
        guard let dimensions = dimensions else {
            return self
        }

        var result = self
        
        result.clamp(to: dimensions)
        
        return result
    }
}

extension CGSize {
    public mutating func clamp(to dimensions: OptionalDimensions) {
        if let maxWidth = dimensions.width {
            width = min(width, maxWidth)
        }
        
        if let maxHeight = dimensions.height {
            height = min(height, maxHeight)
        }
    }
    
    public func clamped(to dimensions: OptionalDimensions) -> Self {
        var result = self
        
        result.clamp(to: dimensions)
        
        return result
    }
}

extension CGSize: _CustomOptionalDimensionsConvertible {
    public func _toOptionalDimensions() -> OptionalDimensions {
        .init(width: width, height: height)
    }
}

extension OptionalDimensions: _CustomOptionalDimensionsConvertible {
    public func _toOptionalDimensions() -> OptionalDimensions {
        self
    }
}

extension CGFloat {
    @_optimize(speed)
    @inline(__always)
    var _isInvalidForIntrinsicContentSize: Bool {
        guard isNormal else {
            return true
        }
        
        switch self {
            case UIView.noIntrinsicMetric:
                return false
            case CGFloat.greatestFiniteMagnitude:
                return true
            case CGFloat.infinity:
                return true
            case 10000000.0:
                return true
            case 10000000000.0:
                return true
            default:
                return false
        }
    }
}

#endif

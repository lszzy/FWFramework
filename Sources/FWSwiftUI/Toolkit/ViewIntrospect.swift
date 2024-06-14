//
//  ViewIntrospect.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - Introspect
/// The scope of introspection i.e. where introspect should look to find
/// the desired target view relative to the applied `.introspect(...)`
/// modifier.
///
/// [SwiftUI-Introspect](https://github.com/siteline/SwiftUI-Introspect)
public struct IntrospectionScope: OptionSet {
    /// Look within the `receiver` of the `.introspect(...)` modifier.
    public static let receiver = Self(rawValue: 1 << 0)
    /// Look for an `ancestor` relative to the `.introspect(...)` modifier.
    public static let ancestor = Self(rawValue: 1 << 1)

    @_spi(FW) public let rawValue: UInt

    @_spi(FW) public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

extension View {
    /// Introspects a SwiftUI view to find its underlying UIKit/AppKit instance.
    ///
    /// - Parameters:
    ///   - viewType: The type of view to be introspected.
    ///   - platforms: A list of `PlatformViewVersions` that specify platform-specific entities associated with the view, with one or more corresponding version numbers.
    ///   - scope: An optional `IntrospectionScope` that specifies the scope of introspection.
    ///   - customize: A closure that hands over the underlying UIKit/AppKit instance ready for customization.
    ///
    /// Here's an example usage:
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State var date = Date()
    ///
    ///     var body: some View {
    ///         DatePicker("Pick a date", selection: $date)
    ///             .introspect(.datePicker, on: .iOS(.all)) {
    ///                 print(type(of: $0)) // UIDatePicker
    ///             }
    ///     }
    /// }
    /// ```
    public func introspect<SwiftUIViewType: IntrospectableViewType, PlatformSpecificEntity: PlatformEntity>(
        _ viewType: SwiftUIViewType,
        on platforms: (PlatformViewVersionPredicate<SwiftUIViewType, PlatformSpecificEntity>)...,
        scope: IntrospectionScope? = nil,
        customize: @escaping (PlatformSpecificEntity) -> Void
    ) -> some View {
        self.modifier(IntrospectModifier(viewType, platforms: platforms, scope: scope, customize: customize))
    }
}

struct IntrospectModifier<SwiftUIViewType: IntrospectableViewType, PlatformSpecificEntity: PlatformEntity>: ViewModifier {
    let id = IntrospectionViewID()
    let scope: IntrospectionScope
    let selector: IntrospectionSelector<PlatformSpecificEntity>?
    let customize: (PlatformSpecificEntity) -> Void

    init(
        _ viewType: SwiftUIViewType,
        platforms: [PlatformViewVersionPredicate<SwiftUIViewType, PlatformSpecificEntity>],
        scope: IntrospectionScope?,
        customize: @escaping (PlatformSpecificEntity) -> Void
    ) {
        self.scope = scope ?? viewType.scope
        self.selector = platforms.lazy.compactMap(\.selector).first
        self.customize = customize
    }

    func body(content: Content) -> some View {
        if let selector {
            content
                .background(
                    Group {
                        // box up content for more accurate `.view` introspection
                        if SwiftUIViewType.self == ViewType.self {
                            Color.white
                                .opacity(0)
                                .accessibility(hidden: true)
                        }
                    }
                )
                .background(
                    IntrospectionAnchorView(id: id)
                        .frame(width: 0, height: 0)
                        .accessibility(hidden: true)
                )
                .overlay(
                    IntrospectionView(id: id, selector: { selector($0, scope) }, customize: customize)
                        .frame(width: 0, height: 0)
                        .accessibility(hidden: true)
                )
        } else {
            content
        }
    }
}

public protocol PlatformEntity: AnyObject {
    associatedtype Base: PlatformEntity

    @_spi(FW)
    var ancestor: Base? { get }

    @_spi(FW)
    var descendants: [Base] { get }

    @_spi(FW)
    func isDescendant(of other: Base) -> Bool
}

extension PlatformEntity {
    @_spi(FW)
    public var ancestor: Base? { nil }

    @_spi(FW)
    public var descendants: [Base] { [] }

    @_spi(FW)
    public func isDescendant(of other: Base) -> Bool { false }
}

extension PlatformEntity {
    @_spi(FW)
    public var ancestors: some Sequence<Base> {
        sequence(first: self~, next: { $0.ancestor~ }).dropFirst()
    }

    @_spi(FW)
    public var allDescendants: some Sequence<Base> {
        recursiveSequence([self~], children: { $0.descendants~ }).dropFirst()
    }

    func nearestCommonAncestor(with other: Base) -> Base? {
        var nearestAncestor: Base? = self~

        while let currentEntity = nearestAncestor, !other.isDescendant(of: currentEntity~) {
            nearestAncestor = currentEntity.ancestor~
        }

        return nearestAncestor
    }

    func allDescendants(between bottomEntity: Base, and topEntity: Base) -> some Sequence<Base> {
        self.allDescendants
            .lazy
            .drop(while: { $0 !== bottomEntity })
            .prefix(while: { $0 !== topEntity })
    }

    func receiver<PlatformSpecificEntity: PlatformEntity>(
        ofType type: PlatformSpecificEntity.Type
    ) -> PlatformSpecificEntity? {
        let frontEntity = self
        guard
            let backEntity = frontEntity.introspectionAnchorEntity,
            let commonAncestor = backEntity.nearestCommonAncestor(with: frontEntity~)
        else {
            return nil
        }

        return commonAncestor
            .allDescendants(between: backEntity~, and: frontEntity~)
            .filter { !$0.isIntrospectionPlatformEntity }
            .compactMap { $0 as? PlatformSpecificEntity }
            .first
    }

    func ancestor<PlatformSpecificEntity: PlatformEntity>(
        ofType type: PlatformSpecificEntity.Type
    ) -> PlatformSpecificEntity? {
        self.ancestors
            .lazy
            .filter { !$0.isIntrospectionPlatformEntity }
            .compactMap { $0 as? PlatformSpecificEntity }
            .first
    }
}

extension PlatformView: PlatformEntity {
    @_spi(FW)
    public var ancestor: PlatformView? {
        superview
    }

    @_spi(FW)
    public var descendants: [PlatformView] {
        subviews
    }
}

extension PlatformViewController: PlatformEntity {
    @_spi(FW)
    public var ancestor: PlatformViewController? {
        parent
    }

    @_spi(FW)
    public var descendants: [PlatformViewController] {
        children
    }

    @_spi(FW)
    public func isDescendant(of other: PlatformViewController) -> Bool {
        self.ancestors.contains(other)
    }
}

extension UIPresentationController: PlatformEntity {
    public typealias Base = UIPresentationController
}

// MARK: - IntrospectableViewType
public protocol IntrospectableViewType {
    /// The scope of introspection for this particular view type, i.e. where introspect
    /// should look to find the desired target view relative to the applied
    /// `.introspect(...)` modifier.
    ///
    /// While the scope can be overridden by the user in their `.introspect(...)` call,
    /// most of the time it's preferable to defer to the view type's own scope,
    /// as it guarantees introspection is working as intended by the vendor.
    ///
    /// Defaults to `.receiver` if left unimplemented, which is a sensible one in
    /// most cases if you're looking to implement your own view type.
    var scope: IntrospectionScope { get }
}

extension IntrospectableViewType {
    public var scope: IntrospectionScope { .receiver }
}

// MARK: - IntrospectionSelector
@_spi(FW)
public struct IntrospectionSelector<Target: PlatformEntity> {
    @_spi(FW)
    public static var `default`: Self { .from(Target.self, selector: { $0 }) }

    @_spi(FW)
    public static func from<Entry: PlatformEntity>(_ entryType: Entry.Type, selector: @escaping (Entry) -> Target?) -> Self {
        .init(
            receiverSelector: { controller in
                controller.as(Entry.Base.self)?.receiver(ofType: Entry.self).flatMap(selector)
            },
            ancestorSelector: { controller in
                controller.as(Entry.Base.self)?.ancestor(ofType: Entry.self).flatMap(selector)
            }
        )
    }

    private var receiverSelector: (_IntrospectionPlatformViewController) -> Target?
    private var ancestorSelector: (_IntrospectionPlatformViewController) -> Target?

    private init(
        receiverSelector: @escaping (_IntrospectionPlatformViewController) -> Target?,
        ancestorSelector: @escaping (_IntrospectionPlatformViewController) -> Target?
    ) {
        self.receiverSelector = receiverSelector
        self.ancestorSelector = ancestorSelector
    }

    @_spi(FW)
    public func withReceiverSelector(_ selector: @escaping (PlatformViewController) -> Target?) -> Self {
        var copy = self
        copy.receiverSelector = selector
        return copy
    }

    @_spi(FW)
    public func withAncestorSelector(_ selector: @escaping (PlatformViewController) -> Target?) -> Self {
        var copy = self
        copy.ancestorSelector = selector
        return copy
    }

    func callAsFunction(_ controller: _IntrospectionPlatformViewController, _ scope: IntrospectionScope) -> Target? {
        if
            scope.contains(.receiver),
            let target = receiverSelector(controller)
        {
            return target
        }
        if
            scope.contains(.ancestor),
            let target = ancestorSelector(controller)
        {
            return target
        }
        return nil
    }
}

extension PlatformViewController {
    func `as`<Base: PlatformEntity>(_ baseType: Base.Type) -> (any PlatformEntity)? {
        if Base.self == PlatformView.self {
            return viewIfLoaded
        } else if Base.self == PlatformViewController.self {
            return self
        }
        return nil
    }
}

// MARK: - IntrospectionView
typealias IntrospectionViewID = UUID

fileprivate enum IntrospectionStore {
    static var shared: [IntrospectionViewID: Pair] = [:]

    struct Pair {
        weak var controller: _IntrospectionPlatformViewController?
        weak var anchor: _IntrospectionAnchorPlatformViewController?
    }
}

extension PlatformEntity {
    var introspectionAnchorEntity: Base? {
        if let introspectionController = self as? _IntrospectionPlatformViewController {
            return IntrospectionStore.shared[introspectionController.id]?.anchor~
        }
        if
            let view = self as? PlatformView,
            let introspectionController = view.introspectionController
        {
            return IntrospectionStore.shared[introspectionController.id]?.anchor?.view~
        }
        return nil
    }
}

struct IntrospectionAnchorView: PlatformViewControllerRepresentable {
    typealias UIViewControllerType = _IntrospectionAnchorPlatformViewController

    @Binding
    private var observed: Void // workaround for state changes not triggering view updates

    let id: IntrospectionViewID

    init(id: IntrospectionViewID) {
        self._observed = .constant(())
        self.id = id
    }

    func makePlatformViewController(context: Context) -> _IntrospectionAnchorPlatformViewController {
        _IntrospectionAnchorPlatformViewController(id: id)
    }

    func updatePlatformViewController(_ controller: _IntrospectionAnchorPlatformViewController, context: Context) {}

    static func dismantlePlatformViewController(_ controller: _IntrospectionAnchorPlatformViewController, coordinator: Coordinator) {}
}

final class _IntrospectionAnchorPlatformViewController: PlatformViewController {
    init(id: IntrospectionViewID) {
        super.init(nibName: nil, bundle: nil)
        self.isIntrospectionPlatformEntity = true
        IntrospectionStore.shared[id, default: .init()].anchor = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.isIntrospectionPlatformEntity = true
    }
}

struct IntrospectionView<Target: PlatformEntity>: PlatformViewControllerRepresentable {
    typealias UIViewControllerType = _IntrospectionPlatformViewController

    final class TargetCache {
        weak var target: Target?
    }

    @Binding
    private var observed: Void // workaround for state changes not triggering view updates
    private let id: IntrospectionViewID
    private let selector: (_IntrospectionPlatformViewController) -> Target?
    private let customize: (Target) -> Void

    init(
        id: IntrospectionViewID,
        selector: @escaping (_IntrospectionPlatformViewController) -> Target?,
        customize: @escaping (Target) -> Void
    ) {
        self._observed = .constant(())
        self.id = id
        self.selector = selector
        self.customize = customize
    }

    func makeCoordinator() -> TargetCache {
        TargetCache()
    }

    func makePlatformViewController(context: Context) -> _IntrospectionPlatformViewController {
        let controller = _IntrospectionPlatformViewController(id: id) { controller in
            guard let target = selector(controller) else {
                return
            }
            context.coordinator.target = target
            customize(target)
            controller.handler = nil
        }

        // - Workaround -
        // iOS/tvOS 13 sometimes need a nudge on the next run loop.
        if #available(iOS 14, tvOS 14, *) {} else {
            DispatchQueue.main.async { [weak controller] in
                controller?.handler?()
            }
        }

        return controller
    }

    func updatePlatformViewController(_ controller: _IntrospectionPlatformViewController, context: Context) {
        guard let target = context.coordinator.target ?? selector(controller) else {
            return
        }
        customize(target)
    }

    static func dismantlePlatformViewController(_ controller: _IntrospectionPlatformViewController, coordinator: Coordinator) {
        controller.handler = nil
    }
}

final class _IntrospectionPlatformViewController: PlatformViewController {
    let id: IntrospectionViewID
    var handler: (() -> Void)? = nil

    fileprivate init(
        id: IntrospectionViewID,
        handler: ((_IntrospectionPlatformViewController) -> Void)?
    ) {
        self.id = id
        super.init(nibName: nil, bundle: nil)
        self.handler = { [weak self] in
            guard let self = self else {
                return
            }
            handler?(self)
        }
        self.isIntrospectionPlatformEntity = true
        IntrospectionStore.shared[id, default: .init()].controller = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        parent?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.introspectionController = self
        view.isIntrospectionPlatformEntity = true
        handler?()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        handler?()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        handler?()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handler?()
    }
}

extension PlatformView {
    fileprivate var introspectionController: _IntrospectionPlatformViewController? {
        get {
            let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
            return objc_getAssociatedObject(self, key) as? _IntrospectionPlatformViewController
        }
        set {
            let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
            objc_setAssociatedObject(self, key, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

extension PlatformEntity {
    var isIntrospectionPlatformEntity: Bool {
        get {
            let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
            return objc_getAssociatedObject(self, key) as? Bool ?? false
        }
        set {
            let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
            objc_setAssociatedObject(self, key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - PlatformVersion
public enum PlatformVersionCondition {
    case past
    case current
    case future
}

public protocol PlatformVersion {
    var condition: PlatformVersionCondition? { get }
}

extension PlatformVersion {
    public var isCurrent: Bool {
        condition == .current
    }

    public var isCurrentOrPast: Bool {
        condition == .current || condition == .past
    }
}

public struct iOSVersion: PlatformVersion {
    public let condition: PlatformVersionCondition?

    public init(condition: () -> PlatformVersionCondition?) {
        self.condition = condition()
    }
}

extension iOSVersion {
    public static let v13 = iOSVersion {
        if #available(iOS 14, *) {
            return .past
        }
        if #available(iOS 13, *) {
            return .current
        }
        return .future
    }

    public static let v14 = iOSVersion {
        if #available(iOS 15, *) {
            return .past
        }
        if #available(iOS 14, *) {
            return .current
        }
        return .future
    }

    public static let v15 = iOSVersion {
        if #available(iOS 16, *) {
            return .past
        }
        if #available(iOS 15, *) {
            return .current
        }
        return .future
    }
    
    public static let v16 = iOSVersion {
        if #available(iOS 17, *) {
            return .past
        }
        if #available(iOS 16, *) {
            return .current
        }
        return .future
    }
    
    public static let v17 = iOSVersion {
        if #available(iOS 18, *) {
            return .past
        }
        if #available(iOS 17, *) {
            return .current
        }
        return .future
    }

    public static let v18 = iOSVersion {
        if #available(iOS 18, *) {
            return .current
        }
        return .future
    }
    
    public static func earlier(_ version: iOSVersion, from: iOSVersion? = nil) -> iOSVersion {
        return iOSVersion {
            if version.condition == .current || version.condition == .future {
                if let from = from {
                    return from.isCurrentOrPast ? .current : .future
                }
                return .current
            }
            return .future
        }
    }
    
    public static func later(_ version: iOSVersion) -> iOSVersion {
        return iOSVersion {
            return version.isCurrentOrPast ? .current : .future
        }
    }
    
    public static let all = iOSVersion {
        return .current
    }
}

// MARK: - PlatformView
public typealias PlatformView = UIView

public typealias PlatformViewController = UIViewController

typealias _PlatformViewControllerRepresentable = UIViewControllerRepresentable

protocol PlatformViewControllerRepresentable: _PlatformViewControllerRepresentable {
    typealias ViewController = UIViewControllerType

    func makePlatformViewController(context: Context) -> ViewController
    func updatePlatformViewController(_ controller: ViewController, context: Context)
    static func dismantlePlatformViewController(_ controller: ViewController, coordinator: Coordinator)
}

extension PlatformViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        makePlatformViewController(context: context)
    }
    func updateUIViewController(_ controller: ViewController, context: Context) {
        updatePlatformViewController(controller, context: context)
    }
    static func dismantleUIViewController(_ controller: ViewController, coordinator: Coordinator) {
        dismantlePlatformViewController(controller, coordinator: coordinator)
    }
}

// MARK: - PlatformViewVersion
public struct PlatformViewVersionPredicate<SwiftUIViewType: IntrospectableViewType, PlatformSpecificEntity: PlatformEntity> {
    let selector: IntrospectionSelector<PlatformSpecificEntity>?

    private init<Version: PlatformVersion>(
        _ versions: [PlatformViewVersion<Version, SwiftUIViewType, PlatformSpecificEntity>],
        matches: (PlatformViewVersion<Version, SwiftUIViewType, PlatformSpecificEntity>) -> Bool
    ) {
        if let matchingVersion = versions.first(where: matches) {
            self.selector = matchingVersion.selector ?? .default
        } else {
            self.selector = nil
        }
    }

    public static func iOS(_ versions: (iOSViewVersion<SwiftUIViewType, PlatformSpecificEntity>)...) -> Self {
        Self(versions, matches: \.isCurrent)
    }

    @_spi(FW)
    public static func iOS(_ versions: PartialRangeFrom<iOSViewVersion<SwiftUIViewType, PlatformSpecificEntity>>) -> Self {
        Self([versions.lowerBound], matches: \.isCurrentOrPast)
    }
}

public typealias iOSViewVersion<SwiftUIViewType: IntrospectableViewType, PlatformSpecificEntity: PlatformEntity> =
    PlatformViewVersion<iOSVersion, SwiftUIViewType, PlatformSpecificEntity>

public enum PlatformViewVersion<Version: PlatformVersion, SwiftUIViewType: IntrospectableViewType, PlatformSpecificEntity: PlatformEntity> {
    @_spi(FW) case available(Version, IntrospectionSelector<PlatformSpecificEntity>?)
    @_spi(FW) case unavailable

    @_spi(FW) public init(for version: Version, selector: IntrospectionSelector<PlatformSpecificEntity>? = nil) {
        self = .available(version, selector)
    }

    @_spi(FW) public static func unavailable(file: StaticString = #file, line: UInt = #line) -> Self {
        #if DEBUG
        let filePath = file.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        Logger.debug(group: Logger.fw.moduleName, "\n===========RUNTIME ERROR===========\nIf you're seeing this, someone forgot to mark %@:%@ as unavailable.\nThis won't have any effect, but it should be disallowed altogether.", fileName, "\(line)")
        #endif
        return .unavailable
    }

    private var version: Version? {
        if case .available(let version, _) = self {
            return version
        } else {
            return nil
        }
    }

    fileprivate var selector: IntrospectionSelector<PlatformSpecificEntity>? {
        if case .available(_, let selector) = self {
            return selector
        } else {
            return nil
        }
    }

    fileprivate var isCurrent: Bool {
        version?.isCurrent ?? false
    }

    fileprivate var isCurrentOrPast: Bool {
        version?.isCurrentOrPast ?? false
    }
}

extension PlatformViewVersion: Comparable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        true
    }
}

// MARK: - Utils
postfix operator ~

postfix func ~ <LHS, T>(lhs: LHS) -> T {
    lhs as! T
}

postfix func ~ <LHS, T>(lhs: LHS?) -> T? {
    lhs as? T
}

func recursiveSequence<S: Sequence>(_ sequence: S, children: @escaping (S.Element) -> S) -> AnySequence<S.Element> {
    AnySequence {
        var mainIterator = sequence.makeIterator()
        // Current iterator, or `nil` if all sequences are exhausted:
        var iterator: AnyIterator<S.Element>?

        return AnyIterator {
            guard let iterator, let element = iterator.next() else {
                if let element = mainIterator.next() {
                    iterator = recursiveSequence(children(element), children: children).makeIterator()
                    return element
                }
                return nil
            }
            return element
        }
    }
}

// MARK: - ViewTypes
/// An abstract representation of a generic SwiftUI view type.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         HStack {
///             Image(systemName: "scribble")
///             Text("Some text")
///         }
///         .introspect(.view, on: .iOS(.all)) {
///             print(type(of: $0)) // some subclass of UIView
///         }
///     }
/// }
/// ```
public struct ViewType: IntrospectableViewType {}

extension IntrospectableViewType where Self == ViewType {
    public static var view: Self { .init() }
}

extension iOSViewVersion<ViewType, UIView> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

// MARK: - ColorPicker
/// An abstract representation of the `ColorPicker` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     @State var color = Color.red
///
///     var body: some View {
///         ColorPicker("Pick a color", selection: $color)
///             .introspect(.colorPicker, on: .iOS(.v14Later)) {
///                 print(type(of: $0)) // UIColorPicker
///             }
///     }
/// }
/// ```
public struct ColorPickerType: IntrospectableViewType {}

extension IntrospectableViewType where Self == ColorPickerType {
    public static var colorPicker: Self { .init() }
}

@available(iOS 14, *)
extension iOSViewVersion<ColorPickerType, UIColorWell> {
    @available(*, unavailable, message: "ColorPicker isn't available on iOS 13")
    public static let v13 = Self.unavailable()
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v14Later = Self(for: .later(.v14))
    @available(*, unavailable, message: "ColorPicker isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - DatePicker
/// An abstract representation of the `DatePicker` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     @State var date = Date()
///
///     var body: some View {
///         DatePicker("Pick a date", selection: $date)
///             .introspect(.datePicker, on: .iOS(.all)) {
///                 print(type(of: $0)) // UIDatePicker
///             }
///     }
/// }
/// ```
public struct DatePickerType: IntrospectableViewType {}

extension IntrospectableViewType where Self == DatePickerType {
    public static var datePicker: Self { .init() }
}

extension iOSViewVersion<DatePickerType, UIDatePicker> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

// MARK: - DatePickerWithCompactStyle
/// An abstract representation of the `DatePicker` type in SwiftUI, with `.compact` style.
///
/// ```swift
/// struct ContentView: View {
///     @State var date = Date()
///
///     var body: some View {
///         DatePicker("Pick a date", selection: $date)
///             .datePickerStyle(.compact)
///             .introspect(.datePicker(style: .compact), on: .iOS(.v14Later)) {
///                 print(type(of: $0)) // UIDatePicker
///             }
///     }
/// }
/// ```
public struct DatePickerWithCompactStyleType: IntrospectableViewType {
    public enum Style {
        case compact
    }
}

extension IntrospectableViewType where Self == DatePickerWithCompactStyleType {
    public static func datePicker(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<DatePickerWithCompactStyleType, UIDatePicker> {
    @available(*, unavailable, message: ".datePickerStyle(.compact) isn't available on iOS 13")
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v14Later = Self(for: .later(.v14))
    @available(*, unavailable, message: ".datePickerStyle(.compact) isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - DatePickerWithGraphicalStyle
/// An abstract representation of the `DatePicker` type in SwiftUI, with `.graphical` style.
///
/// ```swift
/// struct ContentView: View {
///     @State var date = Date()
///
///     var body: some View {
///         DatePicker("Pick a date", selection: $date)
///             .datePickerStyle(.graphical)
///             .introspect(.datePicker(style: .graphical), on: .iOS(.v14Later)) {
///                 print(type(of: $0)) // UIDatePicker
///             }
///     }
/// }
/// ```
public struct DatePickerWithGraphicalStyleType: IntrospectableViewType {
    public enum Style {
        case graphical
    }
}

extension IntrospectableViewType where Self == DatePickerWithGraphicalStyleType {
    public static func datePicker(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<DatePickerWithGraphicalStyleType, UIDatePicker> {
    @available(*, unavailable, message: ".datePickerStyle(.graphical) isn't available on iOS 13")
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v14Later = Self(for: .later(.v14))
    @available(*, unavailable, message: ".datePickerStyle(.graphical) isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - DatePickerWithWheelStyle
/// An abstract representation of the `DatePicker` type in SwiftUI, with `.wheel` style.
///
/// ```swift
/// struct ContentView: View {
///     @State var date = Date()
///
///     var body: some View {
///         DatePicker("Pick a date", selection: $date)
///             .datePickerStyle(.wheel)
///             .introspect(.datePicker(style: .wheel), on: .iOS(.all)) {
///                 print(type(of: $0)) // UIDatePicker
///             }
///     }
/// }
/// ```
public struct DatePickerWithWheelStyleType: IntrospectableViewType {
    public enum Style {
        case wheel
    }
}

extension IntrospectableViewType where Self == DatePickerWithWheelStyleType {
    public static func datePicker(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<DatePickerWithWheelStyleType, UIDatePicker> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

// MARK: - Form
/// An abstract representation of the `Form` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         Form {
///             Text("Item 1")
///             Text("Item 2")
///             Text("Item 3")
///         }
///         .introspect(.form, on: .iOS(.v15Earlier)) {
///             print(type(of: $0)) // UITableView
///         }
///         .introspect(.form, on: .iOS(.v16Later)) {
///             print(type(of: $0)) // UICollectionView
///         }
///     }
/// }
/// ```
public struct FormType: IntrospectableViewType {}

extension IntrospectableViewType where Self == FormType {
    public static var form: Self { .init() }
}

extension iOSViewVersion<FormType, UITableView> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v15Earlier = Self(for: .earlier(.v15))
}

extension iOSViewVersion<FormType, UICollectionView> {
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v16Later = Self(for: .later(.v16))
    @available(*, unavailable, message: ".form isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - FormWithGroupedStyle
/// An abstract representation of the `Form` type in SwiftUI, with `.grouped` style.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         Form {
///             Text("Item 1")
///             Text("Item 2")
///             Text("Item 3")
///         }
///         .formStyle(.grouped)
///         .introspect(.form(style: .grouped), on: .iOS(.v16Later)) {
///             print(type(of: $0)) // UITableView
///         }
///     }
/// }
/// ```
public struct FormWithGroupedStyleType: IntrospectableViewType {
    public enum Style {
        case grouped
    }
}

extension IntrospectableViewType where Self == FormWithGroupedStyleType {
    public static func form(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<FormWithGroupedStyleType, UITableView> {
    @available(*, unavailable, message: ".formStyle(.grouped) isn't available on iOS 13")
    public static let v13 = Self.unavailable()
    @available(*, unavailable, message: ".formStyle(.grouped) isn't available on iOS 14")
    public static let v14 = Self.unavailable()
    @available(*, unavailable, message: ".formStyle(.grouped) isn't available on iOS 15")
    public static let v15 = Self.unavailable()
}

extension iOSViewVersion<FormWithGroupedStyleType, UICollectionView> {
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v16Later = Self(for: .later(.v16))
    @available(*, unavailable, message: ".formStyle(.grouped) isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - FullScreenCover
/// An abstract representation of `.fullScreenCover` in SwiftUI.
///
/// ```swift
/// public struct ContentView: View {
///     @State var isPresented = false
///
///     public var body: some View {
///         Button("Present", action: { isPresented = true })
///             .fullScreenCover(isPresented: $isPresented) {
///                 Button("Dismiss", action: { isPresented = false })
///                     .introspect(.fullScreenCover, on: .iOS(.v14Later)) {
///                         print(type(of: $0)) // UIPresentationController
///                     }
///             }
///     }
/// }
/// ```
public struct FullScreenCoverType: IntrospectableViewType {
    public var scope: IntrospectionScope { .ancestor }
}

extension IntrospectableViewType where Self == FullScreenCoverType {
    public static var fullScreenCover: Self { .init() }
}

extension iOSViewVersion<FullScreenCoverType, UIPresentationController> {
    @available(*, unavailable, message: ".fullScreenCover isn't available on iOS 13")
    public static let v13 = Self.unavailable()
    public static let v14 = Self(for: .v14, selector: selector)
    public static let v15 = Self(for: .v15, selector: selector)
    public static let v16 = Self(for: .v16, selector: selector)
    public static let v17 = Self(for: .v17, selector: selector)
    public static let v18 = Self(for: .v18, selector: selector)
    public static let v14Later = Self(for: .later(.v14), selector: selector)
    @available(*, unavailable, message: ".fullScreenCover isn't available on all iOS")
    public static let all = Self.unavailable()

    private static var selector: IntrospectionSelector<UIPresentationController> {
        .from(UIViewController.self, selector: \.presentationController)
    }
}

// MARK: - List
/// An abstract representation of the `List` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         List {
///             Text("Item 1")
///             Text("Item 2")
///             Text("Item 3")
///         }
///         .introspect(.list, on: .iOS(.v15Earlier)) {
///             print(type(of: $0)) // UITableView
///         }
///         .introspect(.list, on: .iOS(.v16Later)) {
///             print(type(of: $0)) // UICollectionView
///         }
///     }
/// }
/// ```
public struct ListType: IntrospectableViewType {
    public enum Style {
        case plain
    }
}

extension IntrospectableViewType where Self == ListType {
    public static var list: Self { .init() }
    public static func list(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<ListType, UITableView> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v15Earlier = Self(for: .earlier(.v15))
}

extension iOSViewVersion<ListType, UICollectionView> {
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v16Later = Self(for: .later(.v16))
    @available(*, unavailable, message: ".list isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - ListWithGroupedStyle
/// An abstract representation of the `List` type in SwiftUI, with `.grouped` style.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         List {
///             Text("Item 1")
///             Text("Item 2")
///             Text("Item 3")
///         }
///         .listStyle(.grouped)
///         .introspect(.list(style: .grouped), on: .iOS(.v15Earlier)) {
///             print(type(of: $0)) // UITableView
///         }
///         .introspect(.list(style: .grouped), on: .iOS(.v16Later)) {
///             print(type(of: $0)) // UICollectionView
///         }
///     }
/// }
/// ```
public struct ListWithGroupedStyleType: IntrospectableViewType {
    public enum Style {
        case grouped
    }
}

extension IntrospectableViewType where Self == ListWithGroupedStyleType {
    public static func list(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<ListWithGroupedStyleType, UITableView> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v15Earlier = Self(for: .earlier(.v15))
}

extension iOSViewVersion<ListWithGroupedStyleType, UICollectionView> {
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v16Later = Self(for: .later(.v16))
    @available(*, unavailable, message: ".listStyle(.grouped) isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - ListWithInsetGroupedStyleType
/// An abstract representation of the `List` type in SwiftUI, with `.insetGrouped` style.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         List {
///             Text("Item 1")
///             Text("Item 2")
///             Text("Item 3")
///         }
///         .listStyle(.insetGrouped)
///         .introspect(.list(style: .insetGrouped), on: .iOS(.v15Earlier14)) {
///             print(type(of: $0)) // UITableView
///         }
///         .introspect(.list(style: .insetGrouped), on: .iOS(.v16Later)) {
///             print(type(of: $0)) // UICollectionView
///         }
///     }
/// }
/// ```
public struct ListWithInsetGroupedStyleType: IntrospectableViewType {
    public enum Style {
        case insetGrouped
    }
}

extension IntrospectableViewType where Self == ListWithInsetGroupedStyleType {
    public static func list(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<ListWithInsetGroupedStyleType, UITableView> {
    @available(*, unavailable, message: ".listStyle(.insetGrouped) isn't available on iOS 13")
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v15Earlier14 = Self(for: .earlier(.v15, from: .v14))
}

extension iOSViewVersion<ListWithInsetGroupedStyleType, UICollectionView> {
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v16Later = Self(for: .later(.v16))
    @available(*, unavailable, message: ".listStyle(.insetGrouped) isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - ListWithInsetStyle
/// An abstract representation of the `List` type in SwiftUI, with `.inset` style.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         List {
///             Text("Item 1")
///             Text("Item 2")
///             Text("Item 3")
///         }
///         .listStyle(.inset)
///         .introspect(.list(style: .inset), on: .iOS(.v15Earlier14)) {
///             print(type(of: $0)) // UITableView
///         }
///         .introspect(.list(style: .inset), on: .iOS(.v16Later)) {
///             print(type(of: $0)) // UICollectionView
///         }
///     }
/// }
/// ```
public struct ListWithInsetStyleType: IntrospectableViewType {
    public enum Style {
        case inset
    }
}

extension IntrospectableViewType where Self == ListWithInsetStyleType {
    public static func list(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<ListWithInsetStyleType, UITableView> {
    @available(*, unavailable, message: ".listStyle(.inset) isn't available on iOS 13")
    public static let v13 = Self.unavailable()
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v15Earlier14 = Self(for: .earlier(.v15, from: .v14))
}

extension iOSViewVersion<ListWithInsetStyleType, UICollectionView> {
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v16Later = Self(for: .later(.v16))
    @available(*, unavailable, message: ".listStyle(.inset) isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - ListWithSidebarStyle
/// An abstract representation of the `List` type in SwiftUI, with `.sidebar` style.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         List {
///             Text("Item 1")
///             Text("Item 2")
///             Text("Item 3")
///         }
///         .listStyle(.sidebar)
///         .introspect(.list(style: .sidebar), on: .iOS(.v15Earlier14)) {
///             print(type(of: $0)) // UITableView
///         }
///         .introspect(.list(style: .sidebar), on: .iOS(.v16Later)) {
///             print(type(of: $0)) // UICollectionView
///         }
///     }
/// }
/// ```
public struct ListWithSidebarStyleType: IntrospectableViewType {
    public enum Style {
        case sidebar
    }
}

extension IntrospectableViewType where Self == ListWithSidebarStyleType {
    public static func list(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<ListWithSidebarStyleType, UITableView> {
    @available(*, unavailable, message: ".listStyle(.sidebar) isn't available on iOS 13")
    public static let v13 = Self.unavailable()
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v15Earlier14 = Self(for: .earlier(.v15, from: .v14))
}

extension iOSViewVersion<ListWithSidebarStyleType, UICollectionView> {
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v16Later = Self(for: .later(.v16))
    @available(*, unavailable, message: ".listStyle(.sidebar) isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - ListCell
/// An abstract representation of a `List` cell type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         List {
///             ForEach(1...3, id: \.self) { int in
///                 Text("Item \(int)")
///                     .introspect(.listCell, on: .iOS(.v15Earlier)) {
///                         print(type(of: $0)) // UITableViewCell
///                     }
///                     .introspect(.listCell, on: .iOS(.v16Later)) {
///                         print(type(of: $0)) // UICollectionViewCell
///                     }
///             }
///         }
///     }
/// }
/// ```
public struct ListCellType: IntrospectableViewType {
    public var scope: IntrospectionScope { .ancestor }
}

extension IntrospectableViewType where Self == ListCellType {
    public static var listCell: Self { .init() }
}

extension iOSViewVersion<ListCellType, UITableViewCell> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v15Earlier = Self(for: .earlier(.v15))
}

extension iOSViewVersion<ListCellType, UICollectionViewCell> {
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v16Later = Self(for: .later(.v16))
    @available(*, unavailable, message: ".listCell isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - NavigationSplitView
/// An abstract representation of the `NavigationSplitView` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         NavigationSplitView {
///             Text("Root")
///         } detail: {
///             Text("Detail")
///         }
///         .introspect(.navigationSplitView, on: .iOS(.v16Later)) {
///             print(type(of: $0)) // UISplitViewController
///         }
///     }
/// }
/// ```
public struct NavigationSplitViewType: IntrospectableViewType {}

extension IntrospectableViewType where Self == NavigationSplitViewType {
    public static var navigationSplitView: Self { .init() }
}

extension iOSViewVersion<NavigationSplitViewType, UISplitViewController> {
    @available(*, unavailable, message: "NavigationSplitView isn't available on iOS 13")
    public static let v13 = Self.unavailable()
    @available(*, unavailable, message: "NavigationSplitView isn't available on iOS 14")
    public static let v14 = Self.unavailable()
    @available(*, unavailable, message: "NavigationSplitView isn't available on iOS 15")
    public static let v15 = Self.unavailable()

    public static let v16 = Self(for: .v16, selector: selector)
    public static let v17 = Self(for: .v17, selector: selector)
    public static let v18 = Self(for: .v18, selector: selector)
    public static let v16Later = Self(for: .later(.v16), selector: selector)
    @available(*, unavailable, message: "NavigationSplitView isn't available on all iOS")
    public static let all = Self.unavailable()

    private static var selector: IntrospectionSelector<UISplitViewController> {
        .default.withAncestorSelector(\.splitViewController)
    }
}

// MARK: - NavigationStack
/// An abstract representation of the `NavigationStack` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         NavigationStack {
///             Text("Root")
///         }
///         .introspect(.navigationStack, on: .iOS(.v16Later)) {
///             print(type(of: $0)) // UINavigationController
///         }
///     }
/// }
/// ```
public struct NavigationStackType: IntrospectableViewType {}

extension IntrospectableViewType where Self == NavigationStackType {
    public static var navigationStack: Self { .init() }
}

extension iOSViewVersion<NavigationStackType, UINavigationController> {
    @available(*, unavailable, message: "NavigationStack isn't available on iOS 13")
    public static let v13 = Self.unavailable()
    @available(*, unavailable, message: "NavigationStack isn't available on iOS 14")
    public static let v14 = Self.unavailable()
    @available(*, unavailable, message: "NavigationStack isn't available on iOS 15")
    public static let v15 = Self.unavailable()

    public static let v16 = Self(for: .v16, selector: selector)
    public static let v17 = Self(for: .v17, selector: selector)
    public static let v18 = Self(for: .v18, selector: selector)
    public static let v16Later = Self(for: .later(.v16), selector: selector)
    @available(*, unavailable, message: "NavigationStack isn't available on all iOS")
    public static let all = Self.unavailable()

    private static var selector: IntrospectionSelector<UINavigationController> {
        .default.withAncestorSelector(\.navigationController)
    }
}

// MARK: - NavigationViewWithColumnsStyle
/// An abstract representation of the `NavigationView` type in SwiftUI, with `.columns` style.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         NavigationView {
///             Text("Root")
///         }
///         .navigationViewStyle(DoubleColumnNavigationViewStyle())
///         .introspect(.navigationView(style: .columns), on: .iOS(.all)) {
///             print(type(of: $0)) // UISplitViewController
///         }
///     }
/// }
/// ```
public struct NavigationViewWithColumnsStyleType: IntrospectableViewType {
    public enum Style {
        case columns
    }
}

extension IntrospectableViewType where Self == NavigationViewWithColumnsStyleType {
    public static func navigationView(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<NavigationViewWithColumnsStyleType, UISplitViewController> {
    public static let v13 = Self(for: .v13, selector: selector)
    public static let v14 = Self(for: .v14, selector: selector)
    public static let v15 = Self(for: .v15, selector: selector)
    public static let v16 = Self(for: .v16, selector: selector)
    public static let v17 = Self(for: .v17, selector: selector)
    public static let v18 = Self(for: .v18, selector: selector)
    public static let all = Self(for: .all, selector: selector)

    private static var selector: IntrospectionSelector<UISplitViewController> {
        .default.withAncestorSelector(\.splitViewController)
    }
}

// MARK: - NavigationViewWithStackStyle
/// An abstract representation of the `NavigationView` type in SwiftUI, with `.stack` style.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         NavigationView {
///             Text("Root")
///         }
///         .navigationViewStyle(.stack)
///         .introspect(.navigationView(style: .stack), on: .iOS(.all)) {
///             print(type(of: $0)) // UINavigationController
///         }
///     }
/// }
/// ```
public struct NavigationViewWithStackStyleType: IntrospectableViewType {
    public enum Style {
        case stack
    }
}

extension IntrospectableViewType where Self == NavigationViewWithStackStyleType {
    public static func navigationView(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<NavigationViewWithStackStyleType, UINavigationController> {
    public static let v13 = Self(for: .v13, selector: selector)
    public static let v14 = Self(for: .v14, selector: selector)
    public static let v15 = Self(for: .v15, selector: selector)
    public static let v16 = Self(for: .v16, selector: selector)
    public static let v17 = Self(for: .v17, selector: selector)
    public static let v18 = Self(for: .v18, selector: selector)
    public static let all = Self(for: .all, selector: selector)

    private static var selector: IntrospectionSelector<UINavigationController> {
        .default.withAncestorSelector(\.navigationController)
    }
}

// MARK: - PageControl
/// An abstract representation of the page control type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         TabView {
///             Text("Page 1").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.red)
///             Text("Page 2").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.blue)
///         }
///         .tabViewStyle(.page(indexDisplayMode: .always))
///         .introspect(.pageControl, on: .iOS(.v14Later)) {
///             print(type(of: $0)) // UIPageControl
///         }
///     }
/// }
/// ```
public struct PageControlType: IntrospectableViewType {}

extension IntrospectableViewType where Self == PageControlType {
    public static var pageControl: Self { .init() }
}

extension iOSViewVersion<PageControlType, UIPageControl> {
    @available(*, unavailable, message: ".tabViewStyle(.page) isn't available on iOS 13")
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v14Later = Self(for: .later(.v14))
    @available(*, unavailable, message: ".tabViewStyle(.page) isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - PickerWithSegmentedStyle
/// An abstract representation of the `Picker` type in SwiftUI, with `.segmented` style.
///
/// ```swift
/// struct ContentView: View {
///     @State var selection = "1"
///
///     var body: some View {
///         Picker("Pick a number", selection: $selection) {
///             Text("1").tag("1")
///             Text("2").tag("2")
///             Text("3").tag("3")
///         }
///         .pickerStyle(.segmented)
///         .introspect(.picker(style: .segmented), on: .iOS(.all)) {
///             print(type(of: $0)) // UISegmentedControl
///         }
///     }
/// }
/// ```
public struct PickerWithSegmentedStyleType: IntrospectableViewType {
    public enum Style {
        case segmented
    }
}

extension IntrospectableViewType where Self == PickerWithSegmentedStyleType {
    public static func picker(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<PickerWithSegmentedStyleType, UISegmentedControl> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

// MARK: - PickerWithWheelStyle
/// An abstract representation of the `Picker` type in SwiftUI, with `.wheel` style.
///
/// ```swift
/// struct ContentView: View {
///     @State var selection = "1"
///
///     var body: some View {
///         Picker("Pick a number", selection: $selection) {
///             Text("1").tag("1")
///             Text("2").tag("2")
///             Text("3").tag("3")
///         }
///         .pickerStyle(.wheel)
///         .introspect(.picker(style: .wheel), on: .iOS(.all)) {
///             print(type(of: $0)) // UIPickerView
///         }
///     }
/// }
/// ```
public struct PickerWithWheelStyleType: IntrospectableViewType {
    public enum Style {
        case wheel
    }
}

extension IntrospectableViewType where Self == PickerWithWheelStyleType {
    public static func picker(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<PickerWithWheelStyleType, UIPickerView> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

// MARK: - Popover
/// An abstract representation of `.popover` in SwiftUI.
///
/// ```swift
/// public struct ContentView: View {
///     @State var isPresented = false
///
///     public var body: some View {
///         Button("Present", action: { isPresented = true })
///             .popover(isPresented: $isPresented) {
///                 Button("Dismiss", action: { isPresented = false })
///                     .introspect(.popover, on: .iOS(.all)) {
///                         print(type(of: $0)) // UIPopoverPresentationController
///                     }
///             }
///     }
/// }
/// ```
public struct PopoverType: IntrospectableViewType {
    public var scope: IntrospectionScope { .ancestor }
}

extension IntrospectableViewType where Self == PopoverType {
    public static var popover: Self { .init() }
}

extension iOSViewVersion<PopoverType, UIPopoverPresentationController> {
    public static let v13 = Self(for: .v13, selector: selector)
    public static let v14 = Self(for: .v14, selector: selector)
    public static let v15 = Self(for: .v15, selector: selector)
    public static let v16 = Self(for: .v16, selector: selector)
    public static let v17 = Self(for: .v17, selector: selector)
    public static let v18 = Self(for: .v18, selector: selector)
    public static let all = Self(for: .all, selector: selector)

    private static var selector: IntrospectionSelector<UIPopoverPresentationController> {
        .from(UIViewController.self, selector: \.popoverPresentationController)
    }
}

// MARK: - ProgressViewWithCircularStyle
/// An abstract representation of the `ProgressView` type in SwiftUI, with `.circular` style.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         ProgressView(value: 0.5)
///             .progressViewStyle(.circular)
///             .introspect(.progressView(style: .circular), on: .iOS(.v14Later)) {
///                 print(type(of: $0)) // UIActivityIndicatorView
///             }
///     }
/// }
/// ```
public struct ProgressViewWithCircularStyleType: IntrospectableViewType {
    public enum Style {
        case circular
    }
}

extension IntrospectableViewType where Self == ProgressViewWithCircularStyleType {
    public static func progressView(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<ProgressViewWithCircularStyleType, UIActivityIndicatorView> {
    @available(*, unavailable, message: ".progressViewStyle(.circular) isn't available on iOS 13")
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v14Later = Self(for: .later(.v14))
    @available(*, unavailable, message: ".progressViewStyle(.circular) isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - ProgressViewWithLinearStyle
/// An abstract representation of the `ProgressView` type in SwiftUI, with `.linear` style.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         ProgressView(value: 0.5)
///             .progressViewStyle(.linear)
///             .introspect(.progressView(style: .linear), on: .iOS(.v14Later)) {
///                 print(type(of: $0)) // UIProgressView
///             }
///     }
/// }
/// ```
public struct ProgressViewWithLinearStyleType: IntrospectableViewType {
    public enum Style {
        case linear
    }
}

extension IntrospectableViewType where Self == ProgressViewWithLinearStyleType {
    public static func progressView(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<ProgressViewWithLinearStyleType, UIProgressView> {
    @available(*, unavailable, message: ".progressViewStyle(.linear) isn't available on iOS 13")
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v14Later = Self(for: .later(.v14))
    @available(*, unavailable, message: ".progressViewStyle(.linear) isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - ScrollView
/// An abstract representation of the `ScrollView` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         ScrollView {
///             Text("Item")
///         }
///         .introspect(.scrollView, on: .iOS(.all)) {
///             print(type(of: $0)) // UIScrollView
///         }
///     }
/// }
/// ```
public struct ScrollViewType: IntrospectableViewType {}

extension IntrospectableViewType where Self == ScrollViewType {
    public static var scrollView: Self { .init() }
}

extension iOSViewVersion<ScrollViewType, UIScrollView> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

// MARK: - SearchField
/// An abstract representation of the search field displayed via the `.searchable` modifier in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     @State var searchTerm = ""
///
///     var body: some View {
///         NavigationView {
///             Text("Root")
///                 .searchable(text: $searchTerm)
///         }
///         .navigationViewStyle(.stack)
///         .introspect(.searchField, on: .iOS(.v15Later)) {
///             print(type(of: $0)) // UISearchBar
///         }
///     }
/// }
/// ```
public struct SearchFieldType: IntrospectableViewType {}

extension IntrospectableViewType where Self == SearchFieldType {
    public static var searchField: Self { .init() }
}

extension iOSViewVersion<SearchFieldType, UISearchBar> {
    @available(*, unavailable, message: ".searchable isn't available on iOS 13")
    public static let v13 = Self.unavailable()
    @available(*, unavailable, message: ".searchable isn't available on iOS 14")
    public static let v14 = Self.unavailable()
    public static let v15 = Self(for: .v15, selector: selector)
    public static let v16 = Self(for: .v16, selector: selector)
    public static let v17 = Self(for: .v17, selector: selector)
    public static let v18 = Self(for: .v18, selector: selector)
    public static let v15Later = Self(for: .later(.v15), selector: selector)
    @available(*, unavailable, message: ".searchable isn't available on all iOS")
    public static let all = Self.unavailable()

    private static var selector: IntrospectionSelector<UISearchBar> {
        .from(UINavigationController.self) {
            $0.viewIfLoaded?.allDescendants.lazy.compactMap { $0 as? UISearchBar }.first
        }
    }
}

// MARK: - SecureField
/// An abstract representation of the `SecureField` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     @State var text = "Lorem ipsum"
///
///     var body: some View {
///         SecureField("Secure Field", text: $text)
///             .introspect(.secureField, on: .iOS(.all)) {
///                 print(type(of: $0)) // UISecureField
///             }
///     }
/// }
/// ```
public struct SecureFieldType: IntrospectableViewType {}

extension IntrospectableViewType where Self == SecureFieldType {
    public static var secureField: Self { .init() }
}

extension iOSViewVersion<SecureFieldType, UITextField> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

// MARK: - Sheet
/// An abstract representation of `.sheet` in SwiftUI.
///
/// ```swift
/// public struct ContentView: View {
///     @State var isPresented = false
///
///     public var body: some View {
///         Button("Present", action: { isPresented = true })
///             .sheet(isPresented: $isPresented) {
///                 Button("Dismiss", action: { isPresented = false })
///                     .introspect(.sheet, on: .iOS(.all)) {
///                         print(type(of: $0)) // UIPresentationController
///                     }
///             }
///     }
/// }
/// ```
public struct SheetType: IntrospectableViewType {
    public var scope: IntrospectionScope { .ancestor }
}

extension IntrospectableViewType where Self == SheetType {
    public static var sheet: Self { .init() }
}

extension iOSViewVersion<SheetType, UIPresentationController> {
    public static let v13 = Self(for: .v13, selector: selector)
    public static let v14 = Self(for: .v14, selector: selector)
    public static let v15 = Self(for: .v15, selector: selector)
    public static let v16 = Self(for: .v16, selector: selector)
    public static let v17 = Self(for: .v17, selector: selector)
    public static let v18 = Self(for: .v18, selector: selector)
    public static let all = Self(for: .all, selector: selector)

    private static var selector: IntrospectionSelector<UIPresentationController> {
        .from(UIViewController.self, selector: \.presentationController)
    }
}

@available(iOS 15, *)
extension iOSViewVersion<SheetType, UISheetPresentationController> {
    @_disfavoredOverload
    public static let v15 = Self(for: .v15, selector: selector)
    @_disfavoredOverload
    public static let v16 = Self(for: .v16, selector: selector)
    @_disfavoredOverload
    public static let v17 = Self(for: .v17, selector: selector)
    @_disfavoredOverload
    public static let v18 = Self(for: .v18, selector: selector)
    @_disfavoredOverload
    public static let v15Later = Self(for: .later(.v15), selector: selector)

    private static var selector: IntrospectionSelector<UISheetPresentationController> {
        .from(UIViewController.self, selector: \.sheetPresentationController)
    }
}

// MARK: - Slider
/// An abstract representation of the `Slider` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     @State var selection = 0.5
///
///     var body: some View {
///         Slider(value: $selection, in: 0...1)
///             .introspect(.slider, on: .iOS(.all)) {
///                 print(type(of: $0)) // UISlider
///             }
///     }
/// }
/// ```
public struct SliderType: IntrospectableViewType {}

extension IntrospectableViewType where Self == SliderType {
    public static var slider: Self { .init() }
}

extension iOSViewVersion<SliderType, UISlider> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

// MARK: - Stepper
/// An abstract representation of the `Stepper` type in SwiftUI.
///
/// ### iOS
///
/// ```swift
/// struct ContentView: View {
///     @State var selection = 5
///
///     var body: some View {
///         Stepper("Select a number", value: $selection, in: 0...10)
///             .introspect(.stepper, on: .iOS(.all)) {
///                 print(type(of: $0)) // UIStepper
///             }
///     }
/// }
/// ```
public struct StepperType: IntrospectableViewType {}

extension IntrospectableViewType where Self == StepperType {
    public static var stepper: Self { .init() }
}

extension iOSViewVersion<StepperType, UIStepper> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

// MARK: - Table
/// An abstract representation of the `Table` type in SwiftUI, with any style.
///
/// ```swift
/// struct ContentView: View {
///     struct Purchase: Identifiable {
///         let id = UUID()
///         let price: Decimal
///     }
///
///     var body: some View {
///         Table(of: Purchase.self) {
///             TableColumn("Base price") { purchase in
///                 Text(purchase.price, format: .currency(code: "USD"))
///             }
///             TableColumn("With 15% tip") { purchase in
///                 Text(purchase.price * 1.15, format: .currency(code: "USD"))
///             }
///             TableColumn("With 20% tip") { purchase in
///                 Text(purchase.price * 1.2, format: .currency(code: "USD"))
///             }
///         } rows: {
///             TableRow(Purchase(price: 20))
///             TableRow(Purchase(price: 50))
///             TableRow(Purchase(price: 75))
///         }
///         .introspect(.table, on: .iOS(.v16Later)) {
///             print(type(of: $0)) // UICollectionView
///         }
///     }
/// }
/// ```
public struct TableType: IntrospectableViewType {}

extension IntrospectableViewType where Self == TableType {
    public static var table: Self { .init() }
}

extension iOSViewVersion<TableType, UICollectionView> {
    @available(*, unavailable, message: "Table isn't available on iOS 13")
    public static let v13 = Self(for: .v13)
    @available(*, unavailable, message: "Table isn't available on iOS 14")
    public static let v14 = Self(for: .v14)
    @available(*, unavailable, message: "Table isn't available on iOS 15")
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v16Later = Self(for: .later(.v16))
    @available(*, unavailable, message: "Table isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - TabView
/// An abstract representation of the `TabView` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         TabView {
///             Text("Tab 1").tabItem { Text("Tab 1") }
///             Text("Tab 2").tabItem { Text("Tab 2") }
///         }
///         .introspect(.tabView, on: .iOS(.all)) {
///             print(type(of: $0)) // UITabBarController
///         }
///     }
/// }
/// ```
public struct TabViewType: IntrospectableViewType {}

extension IntrospectableViewType where Self == TabViewType {
    public static var tabView: Self { .init() }
}

extension iOSViewVersion<TabViewType, UITabBarController> {
    public static let v13 = Self(for: .v13, selector: selector)
    public static let v14 = Self(for: .v14, selector: selector)
    public static let v15 = Self(for: .v15, selector: selector)
    public static let v16 = Self(for: .v16, selector: selector)
    public static let v17 = Self(for: .v17, selector: selector)
    public static let v18 = Self(for: .v18, selector: selector)
    public static let all = Self(for: .all, selector: selector)

    private static var selector: IntrospectionSelector<UITabBarController> {
        .default.withAncestorSelector(\.tabBarController)
    }
}

// MARK: - TabViewWithPageStyle
/// An abstract representation of the `TabView` type in SwiftUI, with `.page` style.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         TabView {
///             Text("Page 1").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.red)
///             Text("Page 2").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.blue)
///         }
///         .tabViewStyle(.page(indexDisplayMode: .always))
///         .introspect(.tabView(style: .page), on: .iOS(.v14Later)) {
///             print(type(of: $0)) // UICollectionView
///         }
///     }
/// }
/// ```
public struct TabViewWithPageStyleType: IntrospectableViewType {
    public enum Style {
        case page
    }
}

extension IntrospectableViewType where Self == TabViewWithPageStyleType {
    public static func tabView(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<TabViewWithPageStyleType, UICollectionView> {
    @available(*, unavailable, message: "TabView {}.tabViewStyle(.page) isn't available on iOS 13")
    public static let v13 = Self.unavailable()
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v14Later = Self(for: .later(.v14))
    @available(*, unavailable, message: "TabView {}.tabViewStyle(.page) isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - TextEditor
/// An abstract representation of the `TextEditor` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     @State var text = "Lorem ipsum"
///
///     var body: some View {
///         TextEditor(text: $text)
///             .introspect(.textEditor, on: .iOS(.v14Later)) {
///                 print(type(of: $0)) // UITextView
///             }
///     }
/// }
/// ```
public struct TextEditorType: IntrospectableViewType {}

extension IntrospectableViewType where Self == TextEditorType {
    public static var textEditor: Self { .init() }
}

extension iOSViewVersion<TextEditorType, UITextView> {
    @available(*, unavailable, message: "TextEditor isn't available on iOS 13")
    public static let v13 = Self.unavailable()
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v14Later = Self(for: .later(.v14))
    @available(*, unavailable, message: "TextEditor isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - TextField
/// An abstract representation of the `TextField` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     @State var text = "Lorem ipsum"
///
///     var body: some View {
///         TextField("Text Field", text: $text)
///             .introspect(.textField, on: .iOS(.all)) {
///                 print(type(of: $0)) // UITextField
///             }
///     }
/// }
/// ```
public struct TextFieldType: IntrospectableViewType {}

extension IntrospectableViewType where Self == TextFieldType {
    public static var textField: Self { .init() }
}

extension iOSViewVersion<TextFieldType, UITextField> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

// MARK: - TextFieldWithVerticalAxis
/// An abstract representation of the `TextField` type in SwiftUI, with `.vertical` axis.
///
/// ```swift
/// struct ContentView: View {
///     @State var text = "Lorem ipsum"
///
///     var body: some View {
///         TextField("Text Field", text: $text, axis: .vertical)
///             .introspect(.textField(axis: .vertical), on: .iOS(.v16Later)) {
///                 print(type(of: $0)) // UITextView
///             }
///     }
/// }
/// ```
public struct TextFieldWithVerticalAxisType: IntrospectableViewType {
    public enum Axis {
        case vertical
    }
}

extension IntrospectableViewType where Self == TextFieldWithVerticalAxisType {
    public static func textField(axis: Self.Axis) -> Self { .init() }
}

extension iOSViewVersion<TextFieldWithVerticalAxisType, UITextView> {
    @available(*, unavailable, message: "TextField(..., axis: .vertical) isn't available on iOS 13")
    public static let v13 = Self.unavailable()
    @available(*, unavailable, message: "TextField(..., axis: .vertical) isn't available on iOS 14")
    public static let v14 = Self.unavailable()
    @available(*, unavailable, message: "TextField(..., axis: .vertical) isn't available on iOS 15")
    public static let v15 = Self.unavailable()

    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let v16Later = Self(for: .later(.v16))
    @available(*, unavailable, message: "TextField(..., axis: .vertical) isn't available on all iOS")
    public static let all = Self.unavailable()
}

// MARK: - Toggle
/// An abstract representation of the `Toggle` type in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     @State var isOn = false
///
///     var body: some View {
///         Toggle("Toggle", isOn: $isOn)
///             .introspect(.toggle, on: .iOS(.all)) {
///                 print(type(of: $0)) // UISwitch
///             }
///     }
/// }
/// ```
public struct ToggleType: IntrospectableViewType {}

extension IntrospectableViewType where Self == ToggleType {
    public static var toggle: Self { .init() }
}

extension iOSViewVersion<ToggleType, UISwitch> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

// MARK: - ToggleWithSwitchStyle
/// An abstract representation of the `Toggle` type in SwiftUI, with `.switch` style.
///
/// ```swift
/// struct ContentView: View {
///     @State var isOn = false
///
///     var body: some View {
///         Toggle("Switch", isOn: $isOn)
///             .toggleStyle(.switch)
///             .introspect(.toggle(style: .switch), on: .iOS(.all)) {
///                 print(type(of: $0)) // UISwitch
///             }
///     }
/// }
/// ```
public struct ToggleWithSwitchStyleType: IntrospectableViewType {
    public enum Style {
        case `switch`
    }
}

extension IntrospectableViewType where Self == ToggleWithSwitchStyleType {
    public static func toggle(style: Self.Style) -> Self { .init() }
}

extension iOSViewVersion<ToggleWithSwitchStyleType, UISwitch> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

// MARK: - Window
/// An abstract representation of a view's window in SwiftUI.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         Text("Content")
///             .introspect(.window, on: .iOS(.all)) {
///                 print(type(of: $0)) // UIWindow
///             }
///     }
/// }
/// ```
public struct WindowType: IntrospectableViewType {}

extension IntrospectableViewType where Self == WindowType {
    public static var window: Self { .init() }
}

extension iOSViewVersion<WindowType, UIWindow> {
    public static let v13 = Self(for: .v13, selector: selector)
    public static let v14 = Self(for: .v14, selector: selector)
    public static let v15 = Self(for: .v15, selector: selector)
    public static let v16 = Self(for: .v16, selector: selector)
    public static let v17 = Self(for: .v17, selector: selector)
    public static let v18 = Self(for: .v18, selector: selector)
    public static let all = Self(for: .all, selector: selector)

    private static var selector: IntrospectionSelector<UIWindow> {
        .from(UIView.self, selector: \.window)
    }
}

/// An abstract representation of the receiving SwiftUI view's view controller,
/// or the closest ancestor view controller if missing.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         NavigationView {
///             Text("Root").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.red)
///                 .introspect(.viewController, on: .iOS(.all)) {
///                     print(type(of: $0)) // some subclass of UIHostingController
///                 }
///         }
///         .navigationViewStyle(.stack)
///         .introspect(.viewController, on: .iOS(.all)) {
///             print(type(of: $0)) // UINavigationController
///         }
///     }
/// }
/// ```
public struct ViewControllerType: IntrospectableViewType {
    public var scope: IntrospectionScope { [.receiver, .ancestor] }
}

extension IntrospectableViewType where Self == ViewControllerType {
    public static var viewController: Self { .init() }
}

extension iOSViewVersion<ViewControllerType, UIViewController> {
    public static let v13 = Self(for: .v13)
    public static let v14 = Self(for: .v14)
    public static let v15 = Self(for: .v15)
    public static let v16 = Self(for: .v16)
    public static let v17 = Self(for: .v17)
    public static let v18 = Self(for: .v18)
    public static let all = Self(for: .all)
}

#endif

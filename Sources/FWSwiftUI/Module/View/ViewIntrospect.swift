//
//  ViewIntrospect.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Introspect
/// Utility methods to inspect the UIKit view hierarchy.
///
/// [SwiftUI-Introspect](https://github.com/siteline/SwiftUI-Introspect)
public enum Introspect {
    
    /// Finds a subview of the specified type.
    /// This method will recursively look for this view.
    /// Returns nil if it can't find a view of the specified type.
    public static func findChild<AnyViewType: UIView>(
        ofType type: AnyViewType.Type,
        in root: UIView
    ) -> AnyViewType? {
        for subview in root.subviews {
            if let typed = subview as? AnyViewType {
                return typed
            } else if let typed = findChild(ofType: type, in: subview) {
                return typed
            }
        }
        return nil
    }
    
    /// Finds a child view controller of the specified type.
    /// This method will recursively look for this child.
    /// Returns nil if it can't find a view of the specified type.
    public static func findChild<AnyViewControllerType: UIViewController>(
        ofType type: AnyViewControllerType.Type,
        in root: UIViewController
    ) -> AnyViewControllerType? {
        for child in root.children {
            if let typed = child as? AnyViewControllerType {
                return typed
            } else if let typed = findChild(ofType: type, in: child) {
                return typed
            }
        }
        return root as? AnyViewControllerType
    }
    
    /// Finds a subview of the specified type.
    /// This method will recursively look for this view.
    /// Returns nil if it can't find a view of the specified type.
    public static func findChildUsingFrame<AnyViewType: UIView>(
        ofType type: AnyViewType.Type,
        in root: UIView,
        from originalEntry: UIView
    ) -> AnyViewType? {
        var children: [AnyViewType] = []
        for subview in root.subviews {
            if let typed = subview as? AnyViewType {
                children.append(typed)
            } else if let typed = findChild(ofType: type, in: subview) {
                children.append(typed)
            }
        }
        
        if children.count > 1 {
            for child in children {
                let converted = child.convert(
                    CGPoint(x: originalEntry.frame.size.width / 2, y: originalEntry.frame.size.height / 2),
                    from: originalEntry
                )
                if CGRect(origin: .zero, size: child.frame.size).contains(converted) {
                    return child
                }
            }
            return nil
        }
        
        return children.first
    }
    
    /// Finds a previous sibling that contains a view of the specified type.
    /// This method inspects siblings recursively.
    /// Returns nil if no sibling contains the specified type.
    public static func previousSibling<AnyViewType: UIView>(
        containing type: AnyViewType.Type,
        from entry: UIView
    ) -> AnyViewType? {
        
        guard let superview = entry.superview,
            let entryIndex = superview.subviews.firstIndex(of: entry),
            entryIndex > 0
        else {
            return nil
        }
        
        for subview in superview.subviews[0..<entryIndex].reversed() {
            if let typed = findChild(ofType: type, in: subview) {
                return typed
            }
        }
        
        return nil
    }
    
    /// Finds a previous sibling that is of the specified type.
    /// This method inspects siblings recursively.
    /// Returns nil if no sibling contains the specified type.
    public static func previousSibling<AnyViewType: UIView>(
        ofType type: AnyViewType.Type,
        from entry: UIView
    ) -> AnyViewType? {
        
        guard let superview = entry.superview,
            let entryIndex = superview.subviews.firstIndex(of: entry),
            entryIndex > 0
        else {
            return nil
        }
        
        for subview in superview.subviews[0..<entryIndex].reversed() {
            if let typed = subview as? AnyViewType {
                return typed
            }
        }
        
        return nil
    }
    
    /// Finds a previous sibling that contains a view controller of the specified type.
    /// This method inspects siblings recursively.
    /// Returns nil if no sibling contains the specified type.
    @available(macOS, unavailable)
    public static func previousSibling<AnyViewControllerType: UIViewController>(
        containing type: AnyViewControllerType.Type,
        from entry: UIViewController
    ) -> AnyViewControllerType? {
        
        guard let parent = entry.parent,
            let entryIndex = parent.children.firstIndex(of: entry),
            entryIndex > 0
        else {
            return nil
        }
        
        for child in parent.children[0..<entryIndex].reversed() {
            if let typed = findChild(ofType: type, in: child) {
                return typed
            }
        }
        
        return nil
    }
    
    /// Finds a previous sibling that is a view controller of the specified type.
    /// This method does not inspect siblings recursively.
    /// Returns nil if no sibling is of the specified type.
    public static func previousSibling<AnyViewControllerType: UIViewController>(
        ofType type: AnyViewControllerType.Type,
        from entry: UIViewController
    ) -> AnyViewControllerType? {
        
        guard let parent = entry.parent,
            let entryIndex = parent.children.firstIndex(of: entry),
            entryIndex > 0
        else {
            return nil
        }
        
        for child in parent.children[0..<entryIndex].reversed() {
            if let typed = child as? AnyViewControllerType {
                return typed
            }
        }
        
        return nil
    }
    
    /// Finds a next sibling that contains a view of the specified type.
    /// This method inspects siblings recursively.
    /// Returns nil if no sibling contains the specified type.
    public static func nextSibling<AnyViewType: UIView>(
        containing type: AnyViewType.Type,
        from entry: UIView
    ) -> AnyViewType? {
        
        guard let superview = entry.superview,
            let entryIndex = superview.subviews.firstIndex(of: entry)
        else {
            return nil
        }
        
        for subview in superview.subviews[entryIndex..<superview.subviews.endIndex] {
            if let typed = findChild(ofType: type, in: subview) {
                return typed
            }
        }
        
        return nil
    }
    
    /// Finds a next sibling that if of the specified type.
    /// This method inspects siblings recursively.
    /// Returns nil if no sibling contains the specified type.
    public static func nextSibling<AnyViewType: UIView>(
        ofType type: AnyViewType.Type,
        from entry: UIView
    ) -> AnyViewType? {
        
        guard let superview = entry.superview,
            let entryIndex = superview.subviews.firstIndex(of: entry)
        else {
            return nil
        }
        
        for subview in superview.subviews[entryIndex..<superview.subviews.endIndex] {
            if let typed = subview as? AnyViewType {
                return typed
            }
        }
        
        return nil
    }
    
    /// Finds an ancestor of the specified type.
    /// If it reaches the top of the view without finding the specified view type, it returns nil.
    public static func findAncestor<AnyViewType: UIView>(ofType type: AnyViewType.Type, from entry: UIView) -> AnyViewType? {
        var superview = entry.superview
        while let s = superview {
            if let typed = s as? AnyViewType {
                return typed
            }
            superview = s.superview
        }
        return nil
    }
    
    /// Finds an ancestor of the specified type.
    /// If it reaches the top of the view without finding the specified view type, it returns nil.
    public static func findAncestorOrAncestorChild<AnyViewType: UIView>(ofType type: AnyViewType.Type, from entry: UIView) -> AnyViewType? {
        var superview = entry.superview
        while let s = superview {
            if let typed = s as? AnyViewType ?? findChildUsingFrame(ofType: type, in: s, from: entry) {
                return typed
            }
            superview = s.superview
        }
        return nil
    }
    
    /// Finds the hosting view of a specific subview.
    /// Hosting views generally contain subviews for one specific SwiftUI element.
    /// For instance, if there are multiple text fields in a VStack, the hosting view will contain those text fields (and their host views, see below).
    /// Returns nil if it couldn't find a hosting view. This should never happen when called with an IntrospectionView.
    public static func findHostingView(from entry: UIView) -> UIView? {
        var superview = entry.superview
        while let s = superview {
            if NSStringFromClass(type(of: s)).contains("HostingView") {
                return s
            }
            superview = s.superview
        }
        return nil
    }
    
    /// Finds the view host of a specific view.
    /// SwiftUI wraps each UIView within a ViewHost, then within a HostingView.
    /// Returns nil if it couldn't find a view host. This should never happen when called with an IntrospectionView.
    public static func findViewHost(from entry: UIView) -> UIView? {
        var superview = entry.superview
        while let s = superview {
            if NSStringFromClass(type(of: s)).contains("ViewHost") {
                return s
            }
            superview = s.superview
        }
        return nil
    }
}

public enum TargetViewSelector {
    public static func siblingContaining<TargetView: UIView>(from entry: UIView) -> TargetView? {
        guard let viewHost = Introspect.findViewHost(from: entry) else {
            return nil
        }
        return Introspect.previousSibling(containing: TargetView.self, from: viewHost)
    }

    public static func siblingContainingOrAncestor<TargetView: UIView>(from entry: UIView) -> TargetView? {
        if let sibling: TargetView = siblingContaining(from: entry) {
            return sibling
        }
        return Introspect.findAncestor(ofType: TargetView.self, from: entry)
    }
    
    public static func siblingContainingOrAncestorOrAncestorChild<TargetView: UIView>(from entry: UIView) -> TargetView? {
        if let sibling: TargetView = siblingContaining(from: entry) {
            return sibling
        }
        return Introspect.findAncestorOrAncestorChild(ofType: TargetView.self, from: entry)
    }
    
    public static func siblingOfType<TargetView: UIView>(from entry: UIView) -> TargetView? {
        guard let viewHost = Introspect.findViewHost(from: entry) else {
            return nil
        }
        return Introspect.previousSibling(ofType: TargetView.self, from: viewHost)
    }

    public static func siblingOfTypeOrAncestor<TargetView: UIView>(from entry: UIView) -> TargetView? {
        if let sibling: TargetView = siblingOfType(from: entry) {
            return sibling
        }
        return Introspect.findAncestor(ofType: TargetView.self, from: entry)
    }

    public static func ancestorOrSiblingContaining<TargetView: UIView>(from entry: UIView) -> TargetView? {
        if let tableView = Introspect.findAncestor(ofType: TargetView.self, from: entry) {
            return tableView
        }
        return siblingContaining(from: entry)
    }
    
    public static func ancestorOrSiblingOfType<TargetView: UIView>(from entry: UIView) -> TargetView? {
        if let tableView = Introspect.findAncestor(ofType: TargetView.self, from: entry) {
            return tableView
        }
        return siblingOfType(from: entry)
    }
}

// MARK: - UIKitIntrospectionViewController
/// Introspection UIViewController that is inserted alongside the target view controller.
@available(iOS 13.0, tvOS 13.0, macOS 10.15.0, *)
public class IntrospectionUIViewController: UIViewController {
    required init() {
        super.init(nibName: nil, bundle: nil)
        view = IntrospectionUIView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// This is the same logic as IntrospectionView but for view controllers. Please see details above.
@available(iOS 13.0, tvOS 13.0, macOS 10.15.0, *)
public struct UIKitIntrospectionViewController<TargetViewControllerType: UIViewController>: UIViewControllerRepresentable {
    
    let selector: (IntrospectionUIViewController) -> TargetViewControllerType?
    let customize: (TargetViewControllerType) -> Void
    
    public init(
        selector: @escaping (UIViewController) -> TargetViewControllerType?,
        customize: @escaping (TargetViewControllerType) -> Void
    ) {
        self.selector = selector
        self.customize = customize
    }
    
    public func makeUIViewController(
        context: UIViewControllerRepresentableContext<UIKitIntrospectionViewController>
    ) -> IntrospectionUIViewController {
        let viewController = IntrospectionUIViewController()
        viewController.accessibilityLabel = "IntrospectionUIViewController<\(TargetViewControllerType.self)>"
        viewController.view.accessibilityLabel = "IntrospectionUIView<\(TargetViewControllerType.self)>"
        (viewController.view as? IntrospectionUIView)?.moveToWindowHandler = { [weak viewController] in
            guard let viewController = viewController else { return }
            DispatchQueue.main.async {
                guard let targetView = self.selector(viewController) else {
                    return
                }
                self.customize(targetView)
            }
        }
        return viewController
    }
    
    public func updateUIViewController(
        _ viewController: IntrospectionUIViewController,
        context: UIViewControllerRepresentableContext<UIKitIntrospectionViewController>
    ) {
        guard let targetView = self.selector(viewController) else {
            return
        }
        self.customize(targetView)
    }
    
    public static func dismantleUIViewController(_ viewController: IntrospectionUIViewController, coordinator: ()) {
        (viewController.view as? IntrospectionUIView)?.moveToWindowHandler = nil
    }
}

// MARK: - UIKitIntrospectionView
/// Introspection UIView that is inserted alongside the target view.
@available(iOS 13.0, *)
public class IntrospectionUIView: UIView {
    
    var moveToWindowHandler: (() -> Void)?
    
    required init() {
        super.init(frame: .zero)
        isHidden = true
        isUserInteractionEnabled = false
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        moveToWindowHandler?()
    }
}

/// Introspection View that is injected into the UIKit hierarchy alongside the target view.
/// After `updateUIView` is called, it calls `selector` to find the target view, then `customize` when the target view is found.
@available(iOS 13.0, tvOS 13.0, macOS 10.15.0, *)
public struct UIKitIntrospectionView<TargetViewType: UIView>: UIViewRepresentable {
    
    /// Method that introspects the view hierarchy to find the target view.
    /// First argument is the introspection view itself, which is contained in a view host alongside the target view.
    let selector: (IntrospectionUIView) -> TargetViewType?
    
    /// User-provided customization method for the target view.
    let customize: (TargetViewType) -> Void
    
    public init(
        selector: @escaping (IntrospectionUIView) -> TargetViewType?,
        customize: @escaping (TargetViewType) -> Void
    ) {
        self.selector = selector
        self.customize = customize
    }
    
    public func makeUIView(context: UIViewRepresentableContext<UIKitIntrospectionView>) -> IntrospectionUIView {
        let view = IntrospectionUIView()
        view.accessibilityLabel = "IntrospectionUIView<\(TargetViewType.self)>"
        view.moveToWindowHandler = { [weak view] in
            guard let view = view else { return }
            DispatchQueue.main.async {
                guard let targetView = self.selector(view) else {
                    return
                }
                self.customize(targetView)
            }
        }
        return view
    }

    /// When `updateUiView` is called after creating the Introspection view, it is not yet in the UIKit hierarchy.
    /// At this point, `introspectionView.superview.superview` is nil and we can't access the target UIKit view.
    /// To workaround this, we wait until the runloop is done inserting the introspection view in the hierarchy, then run the selector.
    /// Finding the target view fails silently if the selector yield no result. This happens when `updateUIView`
    /// gets called when the introspection view gets removed from the hierarchy.
    public func updateUIView(
        _ view: IntrospectionUIView,
        context: UIViewRepresentableContext<UIKitIntrospectionView>
    ) {
        guard let targetView = self.selector(view) else {
            return
        }
        self.customize(targetView)
    }
    
    public static func dismantleUIView(_ view: IntrospectionUIView, coordinator: ()) {
        view.moveToWindowHandler = nil
    }
}

// MARK: - ViewExtensions
@available(iOS 13.0, tvOS 13.0, macOS 10.15.0, *)
extension View {
    
    public func inject<SomeView>(_ view: SomeView) -> some View where SomeView: View {
        overlay(view.frame(width: 0, height: 0))
    }
    
    /// Finds a `TargetView` from a `SwiftUI.View`
    public func introspect<TargetView: UIView>(
        selector: @escaping (IntrospectionUIView) -> TargetView?,
        customize: @escaping (TargetView) -> ()
    ) -> some View {
        inject(UIKitIntrospectionView(
            selector: selector,
            customize: customize
        ))
    }
    
    /// Finds a `UINavigationController` from any view embedded in a `SwiftUI.NavigationView`.
    public func introspectNavigationController(customize: @escaping (UINavigationController) -> ()) -> some View {
        inject(UIKitIntrospectionViewController(
            selector: { introspectionViewController in
                
                // Search in ancestors
                if let navigationController = introspectionViewController.navigationController {
                    return navigationController
                }
                
                // Search in siblings
                return Introspect.previousSibling(containing: UINavigationController.self, from: introspectionViewController)
            },
            customize: customize
        ))
    }
    
    /// Finds a `UISplitViewController` from  a `SwiftUI.NavigationView` with style `DoubleColumnNavigationViewStyle`.
    public func introspectSplitViewController(customize: @escaping (UISplitViewController) -> ()) -> some View {
            inject(UIKitIntrospectionViewController(
                selector: { introspectionViewController in
                    
                    // Search in ancestors
                    if let splitViewController = introspectionViewController.splitViewController {
                        return splitViewController
                    }
                    
                    // Search in siblings
                    return Introspect.previousSibling(containing: UISplitViewController.self, from: introspectionViewController)
                },
                customize: customize
            ))
        }
    
    /// Finds the containing `UIViewController` of a SwiftUI view.
    public func introspectViewController(customize: @escaping (UIViewController) -> ()) -> some View {
        inject(UIKitIntrospectionViewController(
            selector: { $0.parent },
            customize: customize
        ))
    }

    /// Finds a `UITabBarController` from any SwiftUI view embedded in a `SwiftUI.TabView`
    public func introspectTabBarController(customize: @escaping (UITabBarController) -> ()) -> some View {
        inject(UIKitIntrospectionViewController(
            selector: { introspectionViewController in
                
                // Search in ancestors
                if let navigationController = introspectionViewController.tabBarController {
                    return navigationController
                }
                
                // Search in siblings
                return Introspect.previousSibling(ofType: UITabBarController.self, from: introspectionViewController)
            },
            customize: customize
        ))
    }
    
    /// Finds a `UISearchController` from a `SwiftUI.View` with a `.searchable` modifier
    @available(iOS 15, *)
    public func introspectSearchController(customize: @escaping (UISearchController) -> ()) -> some View {
        introspectNavigationController { navigationController in
            let navigationBar = navigationController.navigationBar
            if let searchController = navigationBar.topItem?.searchController {
                customize(searchController)
            }
        }
    }
    
    /// Finds a `UITableView` from a `SwiftUI.List`, or `SwiftUI.List` child.
    public func introspectTableView(customize: @escaping (UITableView) -> ()) -> some View {
        introspect(selector: TargetViewSelector.ancestorOrSiblingContaining, customize: customize)
    }
    
    /// Finds a `UITableViewCell` from a `SwiftUI.List`, or `SwiftUI.List` child. You can attach this directly to the element inside the list.
    public func introspectTableViewCell(customize: @escaping (UITableViewCell) -> ()) -> some View {
        introspect(selector: TargetViewSelector.ancestorOrSiblingContaining, customize: customize)
    }
    
    /// Finds a `UICollectionView` from a `SwiftUI.List`, or `SwiftUI.List` child for iOS16+.
    public func introspectCollectionView(customize: @escaping (UICollectionView) -> ()) -> some View {
        introspect(selector: TargetViewSelector.ancestorOrSiblingContaining, customize: customize)
    }
    
    /// Finds a `UICollectionViewCell` from a `SwiftUI.List`, or `SwiftUI.List` child for iOS16+. You can attach this directly to the element inside the list.
    public func introspectCollectionViewCell(customize: @escaping (UICollectionViewCell) -> ()) -> some View {
        introspect(selector: TargetViewSelector.ancestorOrSiblingContaining, customize: customize)
    }

    /// Finds a `UIScrollView` from a `SwiftUI.ScrollView`, or `SwiftUI.ScrollView` child.
    public func introspectScrollView(customize: @escaping (UIScrollView) -> ()) -> some View {
        if #available(iOS 14.0, tvOS 14.0, macOS 11.0, *) {
            return introspect(selector: TargetViewSelector.siblingOfTypeOrAncestor, customize: customize)
        } else {
            return introspect(selector: TargetViewSelector.siblingContainingOrAncestor, customize: customize)
        }
    }

    /// Finds the horizontal `UIScrollView` from a `SwiftUI.TabBarView` with tab style `SwiftUI.PageTabViewStyle`.
    ///
    /// Customize is called with a `UICollectionView` wrapper, and the horizontal `UIScrollView`.
    @available(iOS 14, tvOS 14, *)
    public func introspectPagedTabView(customize: @escaping (UICollectionView, UIScrollView) -> ()) -> some View {
        if #available(iOS 16, *) {
            return introspect(selector: TargetViewSelector.ancestorOrSiblingContaining, customize: { (collectionView: UICollectionView) in
                customize(collectionView, collectionView)
            })
        } else {
            return introspect(selector: TargetViewSelector.ancestorOrSiblingContaining, customize: { (collectionView: UICollectionView) in
                for subview in collectionView.subviews {
                    if NSStringFromClass(type(of: subview)).contains("EmbeddedScrollView"), let scrollView = subview as? UIScrollView {
                        customize(collectionView, scrollView)
                        break
                    }
                }
            })
        }
    }

    /// Finds a `UITextField` from a `SwiftUI.TextField`
    public func introspectTextField(customize: @escaping (UITextField) -> ()) -> some View {
        introspect(selector: TargetViewSelector.siblingContainingOrAncestorOrAncestorChild, customize: customize)
    }

    /// Finds a `UITextView` from a `SwiftUI.TextEditor`
    public func introspectTextView(customize: @escaping (UITextView) -> ()) -> some View {
        introspect(selector: TargetViewSelector.siblingContaining, customize: customize)
    }
    
    /// Finds a `UISwitch` from a `SwiftUI.Toggle`
    @available(tvOS, unavailable)
    public func introspectSwitch(customize: @escaping (UISwitch) -> ()) -> some View {
        introspect(selector: TargetViewSelector.siblingContaining, customize: customize)
    }
    
    /// Finds a `UISlider` from a `SwiftUI.Slider`
    @available(tvOS, unavailable)
    public func introspectSlider(customize: @escaping (UISlider) -> ()) -> some View {
        introspect(selector: TargetViewSelector.siblingContaining, customize: customize)
    }
    
    /// Finds a `UIStepper` from a `SwiftUI.Stepper`
    @available(tvOS, unavailable)
    public func introspectStepper(customize: @escaping (UIStepper) -> ()) -> some View {
        introspect(selector: TargetViewSelector.siblingContaining, customize: customize)
    }
    
    /// Finds a `UIDatePicker` from a `SwiftUI.DatePicker`
    @available(tvOS, unavailable)
    public func introspectDatePicker(customize: @escaping (UIDatePicker) -> ()) -> some View {
        introspect(selector: TargetViewSelector.siblingContaining, customize: customize)
    }
    
    /// Finds a `UISegmentedControl` from a `SwiftUI.Picker` with style `SegmentedPickerStyle`
    public func introspectSegmentedControl(customize: @escaping (UISegmentedControl) -> ()) -> some View {
        introspect(selector: TargetViewSelector.siblingContaining, customize: customize)
    }
    
    /// Finds a `UIColorWell` from a `SwiftUI.ColorPicker`
    @available(iOS 14.0, *)
    @available(tvOS, unavailable)
    public func introspectColorWell(customize: @escaping (UIColorWell) -> ()) -> some View {
        introspect(selector: TargetViewSelector.siblingContaining, customize: customize)
    }
    
    /// Finds a `UICollectionView` for iOS16+ or `UITableView` for iOS15-  from a `SwiftUI.List`
    public func introspectListView(customize: @escaping (UIScrollView) -> ()) -> some View {
        if #available(iOS 16.0, *) {
            return introspectCollectionView { collectionView in
                customize(collectionView)
            }
        } else {
            return introspectTableView { tableView in
                customize(tableView)
            }
        }
    }
}

#endif

#if canImport(MapKit)
import MapKit

@available(iOS 13.0, tvOS 13.0, macOS 10.15.0, *)
extension View {
    /// Finds an `MKMapView` from a `SwiftUI.Map`
    @available(iOS 14, tvOS 14, macOS 11, *)
    public func introspectMapView(customize: @escaping (MKMapView) -> ()) -> some View {
        introspect(selector: TargetViewSelector.siblingContaining, customize: customize)
    }
}
#endif

//
//  HostingNavigation.swift
//  FWFramework
//
//  Created by wuyong on 2025/3/12.
//

#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// [SwiftUIX](https://github.com/SwiftUIX/SwiftUIX)
extension View {
    @inlinable
    public func _configureUINavigationController(
        _ configure: @escaping (UINavigationController) -> Void
    ) -> some View {
        func _configure(_ viewController: UIViewController) {
            if let navigationController = viewController.navigationController {
                configure(navigationController)
            } else {
                DispatchQueue.main.async {
                    guard let navigationController = viewController.navigationController else {
                        return
                    }
                    
                    configure(navigationController)
                }
            }
        }
        
        return onViewControllerResolution { viewController in
            _configure(viewController)
        } onAppear: { viewController in
            _configure(viewController)
        }
    }
    
    @inlinable
    public func _configureUINavigationBar(
        _ configure: @escaping (UINavigationBar) -> Void
    ) -> some View {
        _configureUINavigationController {
            configure($0.navigationBar)
        }
    }
}

extension View {
    @inlinable
    public func navigationBarColor(_ color: Color?) -> some View {
        _configureUINavigationBar { navigationBar in
            navigationBar.backgroundColor = color?.toUIColor()
            navigationBar.barTintColor = color?.toUIColor()
        }
    }
    
    @inlinable
    public func navigationBarTint(_ color: Color?) -> some View {
        _configureUINavigationBar { navigationBar in
            navigationBar.tintColor = color?.toUIColor()
        }
    }

    @inlinable
    public func navigationBarTranslucent(_ translucent: Bool) -> some View {
        _configureUINavigationBar { navigationBar in
            navigationBar.isTranslucent = translucent
        }
    }
    
    @inlinable
    public func navigationBarTransparent(_ transparent: Bool) -> some View {
        _configureUINavigationBar { navigationBar in
            navigationBar.isDefaultTransparent = transparent
        }
    }
}

extension View {
    public func onViewControllerResolution(
        perform action: @escaping (UIViewController) -> ()
    ) -> some View {
        background(
            ViewControllerResolver(
                onInsertion: action,
                onAppear: { _ in },
                onDisappear: { _ in },
                onRemoval: { _ in }
            )
            .allowsHitTesting(false)
            .accessibility(hidden: true)
        )
    }
    
    @_disfavoredOverload
    public func onViewControllerResolution(
        perform resolutionAction: @escaping (UIViewController) -> () = { _ in },
        onAppear: @escaping (UIViewController) -> () = { _ in },
        onDisappear: @escaping (UIViewController) -> () = { _ in },
        onRemoval deresolutionAction: @escaping (UIViewController) -> () = { _ in }
    ) -> some View {
        background(
            ViewControllerResolver(
                onInsertion: resolutionAction,
                onAppear: onAppear,
                onDisappear: onDisappear,
                onRemoval: deresolutionAction
            )
            .allowsHitTesting(false)
            .accessibility(hidden: true)
        )
    }
}

fileprivate struct ViewControllerResolver: UIViewControllerRepresentable {
    class ViewControllerType: UIViewController {
        var onInsertion: (UIViewController) -> Void = { _ in }
        var onAppear: (UIViewController) -> Void = { _ in }
        var onDisappear: (UIViewController) -> Void = { _ in }
        var onRemoval: (UIViewController) -> Void = { _ in }
        
        private weak var resolvedParent: UIViewController?
        
        private func resolveIfNecessary(withParent parent: UIViewController?) {
            guard let parent = parent, resolvedParent == nil else {
                return
            }
            
            resolvedParent = parent
            
            onInsertion(parent)
        }
        
        private func deresolveIfNecessary() {
            guard let parent = resolvedParent else {
                return
            }
            
            onRemoval(parent)
        }
        
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            
            if let parent = parent {
                resolveIfNecessary(withParent: parent)
            } else {
                deresolveIfNecessary()
            }
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            resolvedParent.map(onAppear)
        }
        
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            
            resolvedParent.map(onDisappear)
        }
        
        override func removeFromParent() {
            super.removeFromParent()
            
            deresolveIfNecessary()
        }
    }
    
    var onInsertion: (UIViewController) -> Void
    var onAppear: (UIViewController) -> Void
    var onDisappear: (UIViewController) -> Void
    var onRemoval: (UIViewController) -> Void
    
    func makeUIViewController(context: Context) -> ViewControllerType {
        ViewControllerType()
    }
    
    func updateUIViewController(_ viewController: ViewControllerType, context: Context) {
        viewController.onInsertion = onInsertion
        viewController.onAppear = onAppear
        viewController.onDisappear = onDisappear
        viewController.onRemoval = onRemoval
    }
}

extension UINavigationBar {
    @inlinable
    var isDefaultTransparent: Bool {
        get {
            return true
                && backgroundImage(for: .default)?.size == .zero
                && shadowImage?.size == .zero
        } set {
            setBackgroundImage(newValue ? UIImage() : nil, for: .default)
            shadowImage = newValue ? UIImage() : nil
        }
    }
}

#endif

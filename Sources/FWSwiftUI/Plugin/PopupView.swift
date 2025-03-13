//
//  PopupView.swift
//  FWFramework
//
//  Created by wuyong on 2025/3/11.
//

#if canImport(SwiftUI)
import Combine
import SwiftUI
import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

/// [PopupView](https://github.com/exyte/PopupView)
@available(iOS 14.0, *)
public struct Popup<PopupContent: View>: ViewModifier {
    init(params: Popup<PopupContent>.PopupParameters,
         view: @escaping () -> PopupContent,
         popupPresented: Bool,
         shouldShowContent: Binding<Bool>,
         showContent: Bool,
         positionIsCalculatedCallback: @escaping () -> Void,
         animationCompletedCallback: @escaping () -> Void,
         dismissCallback: @escaping (PopupDismissSource) -> Void) {
        self.type = params.type
        self.displayMode = params.displayMode
        self.position = params.position ?? params.type.defaultPosition
        self.appearFrom = params.appearFrom
        self.disappearTo = params.disappearTo
        self.verticalPadding = params.type.verticalPadding
        self.horizontalPadding = params.type.horizontalPadding
        self.useSafeAreaInset = params.type.useSafeAreaInset
        self.useKeyboardSafeArea = params.useKeyboardSafeArea
        self.animation = params.animation
        self.dragToDismiss = params.dragToDismiss
        self.dragToDismissDistance = params.dragToDismissDistance
        self.closeOnTap = params.closeOnTap

        self.view = view

        self.popupPresented = popupPresented
        self.shouldShowContent = shouldShowContent
        self.showContent = showContent
        self.positionIsCalculatedCallback = positionIsCalculatedCallback
        self.animationCompletedCallback = animationCompletedCallback
        self.dismissCallback = dismissCallback
    }

    public enum PopupType {
        case `default`
        case toast
        case floater(verticalPadding: CGFloat = 10, horizontalPadding: CGFloat = 10, useSafeAreaInset: Bool = true)
        case scroll(headerView: AnyView)

        var defaultPosition: Position {
            if case .default = self {
                return .center
            }
            return .bottom
        }

        var verticalPadding: CGFloat {
            if case let .floater(verticalPadding, _, _) = self {
                return verticalPadding
            }
            return 0
        }

        var horizontalPadding: CGFloat {
            if case let .floater(_, horizontalPadding, _) = self {
                return horizontalPadding
            }
            return 0
        }

        var useSafeAreaInset: Bool {
            if case let .floater(_, _, use) = self {
                return use
            }
            return false
        }
    }

    public enum DisplayMode {
        case overlay // place the popup above the content in a ZStack
        case sheet // using .fullscreenSheet
        case window // using UIWindow
    }

    public enum Position {
        case topLeading
        case top
        case topTrailing

        case leading
        case center // usual popup
        case trailing

        case bottomLeading
        case bottom
        case bottomTrailing

        var isTop: Bool {
            [.topLeading, .top, .topTrailing].contains(self)
        }

        var isVerticalCenter: Bool {
            [.leading, .center, .trailing].contains(self)
        }

        var isBottom: Bool {
            [.bottomLeading, .bottom, .bottomTrailing].contains(self)
        }

        var isLeading: Bool {
            [.topLeading, .leading, .bottomLeading].contains(self)
        }

        var isHorizontalCenter: Bool {
            [.top, .center, .bottom].contains(self)
        }

        var isTrailing: Bool {
            [.topTrailing, .trailing, .bottomTrailing].contains(self)
        }
    }

    public enum AppearAnimation {
        case topSlide
        case bottomSlide
        case leftSlide
        case rightSlide
        case centerScale
    }

    public struct PopupParameters {
        var type: PopupType = .default
        var displayMode: DisplayMode = .window

        var position: Position?

        var appearFrom: AppearAnimation?
        var disappearTo: AppearAnimation?

        var animation: Animation = .easeOut(duration: 0.3)

        /// If nil - never hides on its own
        var autohideIn: Double?

        /// Should allow dismiss by dragging - default is `true`
        var dragToDismiss: Bool = true

        /// Minimum distance to drag to dismiss
        var dragToDismissDistance: CGFloat?

        /// Should close on tap - default is `true`
        var closeOnTap: Bool = true

        /// Should close on tap outside - default is `false`
        var closeOnTapOutside: Bool = false

        /// Background color for outside area
        var backgroundColor: Color = .clear

        /// Custom background view for outside area
        var backgroundView: AnyView?

        /// move up for keyboardHeight when it is displayed
        var useKeyboardSafeArea: Bool = false

        /// called when when dismiss animation starts
        var willDismissCallback: (PopupDismissSource) -> Void = { _ in }

        /// called when when dismiss animation ends
        var dismissCallback: (PopupDismissSource) -> Void = { _ in }

        public func type(_ type: PopupType) -> PopupParameters {
            var params = self
            params.type = type
            return params
        }

        public func displayMode(_ displayMode: DisplayMode) -> PopupParameters {
            var params = self
            params.displayMode = displayMode
            return params
        }

        public func position(_ position: Position) -> PopupParameters {
            var params = self
            params.position = position
            return params
        }

        public func appearFrom(_ appearFrom: AppearAnimation) -> PopupParameters {
            var params = self
            params.appearFrom = appearFrom
            return params
        }

        public func disappearTo(_ disappearTo: AppearAnimation) -> PopupParameters {
            var params = self
            params.disappearTo = disappearTo
            return params
        }

        public func animation(_ animation: Animation) -> PopupParameters {
            var params = self
            params.animation = animation
            return params
        }

        public func autohideIn(_ autohideIn: Double?) -> PopupParameters {
            var params = self
            params.autohideIn = autohideIn
            return params
        }

        /// Should allow dismiss by dragging - default is `true`
        public func dragToDismiss(_ dragToDismiss: Bool) -> PopupParameters {
            var params = self
            params.dragToDismiss = dragToDismiss
            return params
        }

        /// Minimum distance to drag to dismiss
        public func dragToDismissDistance(_ dragToDismissDistance: CGFloat) -> PopupParameters {
            var params = self
            params.dragToDismissDistance = dragToDismissDistance
            return params
        }

        /// Should close on tap - default is `true`
        public func closeOnTap(_ closeOnTap: Bool) -> PopupParameters {
            var params = self
            params.closeOnTap = closeOnTap
            return params
        }

        /// Should close on tap outside - default is `false`
        public func closeOnTapOutside(_ closeOnTapOutside: Bool) -> PopupParameters {
            var params = self
            params.closeOnTapOutside = closeOnTapOutside
            return params
        }

        public func backgroundColor(_ backgroundColor: Color) -> PopupParameters {
            var params = self
            params.backgroundColor = backgroundColor
            return params
        }

        public func backgroundView<BackgroundView: View>(_ backgroundView: () -> (BackgroundView)) -> PopupParameters {
            var params = self
            params.backgroundView = AnyView(backgroundView())
            return params
        }

        public func useKeyboardSafeArea(_ useKeyboardSafeArea: Bool) -> PopupParameters {
            var params = self
            params.useKeyboardSafeArea = useKeyboardSafeArea
            return params
        }

        // MARK: - dismiss callbacks
        public func willDismissCallback(_ dismissCallback: @escaping (PopupDismissSource) -> Void) -> PopupParameters {
            var params = self
            params.willDismissCallback = dismissCallback
            return params
        }

        public func willDismissCallback(_ dismissCallback: @escaping () -> Void) -> PopupParameters {
            var params = self
            params.willDismissCallback = { _ in
                dismissCallback()
            }
            return params
        }

        public func dismissCallback(_ dismissCallback: @escaping (PopupDismissSource) -> Void) -> PopupParameters {
            var params = self
            params.dismissCallback = dismissCallback
            return params
        }

        public func dismissCallback(_ dismissCallback: @escaping () -> Void) -> PopupParameters {
            var params = self
            params.dismissCallback = { _ in
                dismissCallback()
            }
            return params
        }
    }

    private enum DragState {
        case inactive
        case dragging(translation: CGSize)

        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case let .dragging(translation):
                return translation
            }
        }

        var isDragging: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
    }

    // MARK: - Public Properties
    var type: PopupType
    var displayMode: DisplayMode
    var position: Position
    var appearFrom: AppearAnimation?
    var disappearTo: AppearAnimation?
    var verticalPadding: CGFloat
    var horizontalPadding: CGFloat
    var useSafeAreaInset: Bool
    var useKeyboardSafeArea: Bool

    var animation: Animation

    /// Should close on tap - default is `true`
    var closeOnTap: Bool

    /// Should allow dismiss by dragging
    var dragToDismiss: Bool

    /// Minimum distance to drag to dismiss
    var dragToDismissDistance: CGFloat?

    /// Variable showing changes in isPresented/item, used here to determine direction of animation (showing or hiding)
    var popupPresented: Bool

    /// Trigger popup showing/hiding animations and...
    var shouldShowContent: Binding<Bool>

    /// ... once hiding animation is finished remove popup from the memory using this flag
    var showContent: Bool

    /// called when all the offsets are calculated, so everything is ready for animation
    var positionIsCalculatedCallback: () -> Void

    /// called on showing/hiding sliding animation completed
    var animationCompletedCallback: () -> Void

    /// Call dismiss callback with dismiss source
    var dismissCallback: (PopupDismissSource) -> Void

    var view: () -> PopupContent

    // MARK: - Private Properties
    @StateObject var keyboardHeightHelper = KeyboardHeightHelper()

    /// The rect and safe area of the hosting controller
    @State private var presenterContentRect: CGRect = .zero

    /// The rect and safe area of popup content
    @State private var sheetContentRect: CGRect = .zero

    @State private var safeAreaInsets: EdgeInsets = .init()

    /// Variables used to control what is animated and what is not
    @State var actualCurrentOffset = KeyboardHeightHelper.pointFarAwayFromScreen
    @State var actualScale = 1.0
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape

    // MARK: - Drag to dismiss
    /// Drag to dismiss gesture state
    @GestureState private var dragState = DragState.inactive

    /// Last position for drag gesture
    @State private var lastDragPosition: CGSize = .zero

    // MARK: - Drag to dismiss with scroll
    /// UIScrollView delegate, needed for calling didEndDragging
    @StateObject private var scrollViewDelegate = PopupScrollViewDelegate()

    /// Position when the scroll content offset became less than 0
    @State private var scrollViewOffset: CGSize = .zero

    /// Height of scrollView content that will be displayed on the screen
    @State var scrollViewContentHeight = 0.0

    // MARK: - Position calculations
    /// The offset when the popup is displayed
    private var displayedOffsetY: CGFloat {
        if displayMode != .overlay {
            if position.isTop {
                return verticalPadding + (useSafeAreaInset ? 0 : -safeAreaInsets.top)
            }
            if position.isVerticalCenter {
                return (screenHeight - sheetContentRect.height) / 2 - safeAreaInsets.top
            }
            if position.isBottom {
                return screenHeight - sheetContentRect.height
                    - (useKeyboardSafeArea ? keyboardHeightHelper.keyboardHeight : 0)
                    - verticalPadding
                    - (useSafeAreaInset ? safeAreaInsets.bottom : 0)
                    - safeAreaInsets.top
            }
        }

        if position.isTop {
            return verticalPadding + (useSafeAreaInset ? 0 : -safeAreaInsets.top)
        }
        if position.isVerticalCenter {
            return (presenterContentRect.height - sheetContentRect.height) / 2
        }
        if position.isBottom {
            return presenterContentRect.height
                - sheetContentRect.height
                - (useKeyboardSafeArea ? keyboardHeightHelper.keyboardHeight : 0)
                - verticalPadding
                + safeAreaInsets.bottom
                - (useSafeAreaInset ? safeAreaInsets.bottom : 0)
        }
        return 0
    }

    /// The offset when the popup is displayed
    private var displayedOffsetX: CGFloat {
        if displayMode != .overlay {
            if position.isLeading {
                return horizontalPadding + (useSafeAreaInset ? safeAreaInsets.leading : 0)
            }
            if position.isHorizontalCenter {
                return (screenWidth - sheetContentRect.width) / 2 - safeAreaInsets.leading
            }
            if position.isTrailing {
                return screenWidth - sheetContentRect.width - horizontalPadding - (useSafeAreaInset ? safeAreaInsets.trailing : 0)
            }
        }

        if position.isLeading {
            return horizontalPadding + (useSafeAreaInset ? safeAreaInsets.leading : 0)
        }
        if position.isHorizontalCenter {
            return (presenterContentRect.width - sheetContentRect.width) / 2
        }
        if position.isTrailing {
            return presenterContentRect.width - sheetContentRect.width - horizontalPadding - (useSafeAreaInset ? safeAreaInsets.trailing : 0)
        }
        return 0
    }

    /// The offset when the popup is hidden
    private var hiddenOffset: CGPoint {
        if sheetContentRect.isEmpty {
            return KeyboardHeightHelper.pointFarAwayFromScreen
        }

        // appearing animation
        if popupPresented {
            return hiddenOffset(calculatedAppearFrom)
        }
        // hiding animation
        else {
            return hiddenOffset(calculatedDisappearTo)
        }
    }

    func hiddenOffset(_ appearAnimation: AppearAnimation) -> CGPoint {
        switch appearAnimation {
        case .topSlide:
            return CGPoint(x: displayedOffsetX, y: -presenterContentRect.minY - safeAreaInsets.top - sheetContentRect.height)
        case .bottomSlide:
            return CGPoint(x: displayedOffsetX, y: screenHeight)
        case .leftSlide:
            return CGPoint(x: -screenWidth, y: displayedOffsetY)
        case .rightSlide:
            return CGPoint(x: screenWidth, y: displayedOffsetY)
        case .centerScale:
            return CGPoint(x: displayedOffsetX, y: displayedOffsetY)
        }
    }

    /// Passes the desired position to actualCurrentOffset allowing to animate selectively
    private var targetCurrentOffset: CGPoint {
        shouldShowContent.wrappedValue ? CGPoint(x: displayedOffsetX, y: displayedOffsetY) : hiddenOffset
    }

    // MARK: - Scale calculations
    /// The scale when the popup is displayed
    private var displayedScale: CGFloat {
        1
    }

    /// The scale when the popup is hidden
    private var hiddenScale: CGFloat {
        if popupPresented, calculatedAppearFrom == .centerScale {
            return 0
        } else if !popupPresented, calculatedDisappearTo == .centerScale {
            return 0
        }
        return 1
    }

    /// Passes the desired scale to actualScale allowing to animate selectively
    private var targetScale: CGFloat {
        shouldShowContent.wrappedValue ? displayedScale : hiddenScale
    }

    // MARK: - Appear position direction calculations
    private var calculatedAppearFrom: AppearAnimation {
        let from: AppearAnimation
        if let appearFrom {
            from = appearFrom
        } else if position.isLeading {
            from = .leftSlide
        } else if position.isTrailing {
            from = .rightSlide
        } else if position == .top {
            from = .topSlide
        } else {
            from = .bottomSlide
        }
        return from
    }

    private var calculatedDisappearTo: AppearAnimation {
        let to: AppearAnimation
        if let disappearTo {
            to = disappearTo
        } else if let appearFrom {
            to = appearFrom
        } else if position.isLeading {
            to = .leftSlide
        } else if position.isTrailing {
            to = .rightSlide
        } else if position == .top {
            to = .topSlide
        } else {
            to = .bottomSlide
        }
        return to
    }

    private func configure(scrollView: UIScrollView) {
        scrollViewDelegate.scrollView = scrollView
        scrollViewDelegate.addGestureIfNeeded()

        DispatchQueue.main.async {
            scrollViewContentHeight = scrollView.contentSize.height
        }

        scrollViewDelegate.didReachTop = { value in
            scrollViewOffset = CGSize(width: 0, height: -value)
        }

        let referenceY = sheetContentRect.height / 3
        scrollViewDelegate.scrollEnded = { value in
            if -value >= referenceY {
                dismissCallback(.drag)
            } else {
                withAnimation {
                    scrollViewOffset = .zero
                }
            }
        }

        scrollView.delegate = scrollViewDelegate
    }

    var screenSize: CGSize {
        UIWindow.fw.main?.frame.size ?? .zero
    }

    private var screenWidth: CGFloat {
        screenSize.width
    }

    private var screenHeight: CGFloat {
        screenSize.height
    }

    // MARK: - Content Builders
    public func body(content: Content) -> some View {
        content
            .frameGetter($presenterContentRect)
            .safeAreaGetter($safeAreaInsets)
            .overlay(
                Group {
                    if showContent, presenterContentRect != .zero {
                        sheetWithDragGesture()
                    }
                }
            )
    }

    @ViewBuilder
    private func contentView() -> some View {
        switch type {
        case let .scroll(headerView):
            VStack(spacing: 0) {
                headerView
                    .fixedSize(horizontal: false, vertical: true)
                ScrollView {
                    view()
                }
                // no heigher than its contents
                .frame(maxHeight: scrollViewContentHeight)
            }
            .introspect(.scrollView, on: .iOS(.v15, .v16, .v17, .v18)) { scrollView in
                configure(scrollView: scrollView)
            }
            .offset(CGSize(width: 0, height: scrollViewOffset.height))

        default:
            view()
        }
    }

    /// This is the builder for the sheet content
    @ViewBuilder
    func sheet() -> some View {
        if #available(iOS 17.0, *) {
            ZStack {
                VStack {
                    contentView()
                        .addTapIfNotTV(if: closeOnTap) {
                            dismissCallback(.tapInside)
                        }
                        .scaleEffect(actualScale) // scale is here to avoid it messing with frameGetter for sheetContentRect
                }
                .frameGetter($sheetContentRect)
                .position(x: sheetContentRect.width / 2 + actualCurrentOffset.x, y: sheetContentRect.height / 2 + actualCurrentOffset.y)
                .onChange(of: shouldShowContent.wrappedValue) { newValue in
                    if actualCurrentOffset == KeyboardHeightHelper.pointFarAwayFromScreen { // don't animate initial positioning outside the screen
                        DispatchQueue.main.async {
                            actualCurrentOffset = hiddenOffset
                            actualScale = hiddenScale
                        }
                    }

                    DispatchQueue.main.async {
                        withAnimation(animation) {
                            changeParamsWithAnimation(newValue)
                        } completion: {
                            animationCompletedCallback()
                        }
                    }
                }
                .onChange(of: keyboardHeightHelper.keyboardHeight) { _ in
                    if shouldShowContent.wrappedValue {
                        DispatchQueue.main.async {
                            withAnimation(animation) {
                                changeParamsWithAnimation(true)
                            }
                        }
                    }
                }
                .onChange(of: sheetContentRect.size) { _ in
                    positionIsCalculatedCallback()
                    if shouldShowContent.wrappedValue { // already displayed but the size has changed
                        actualCurrentOffset = targetCurrentOffset
                    }
                }
                .onOrientationChange(isLandscape: $isLandscape) {
                    actualCurrentOffset = targetCurrentOffset
                }
            }
        } else { // ios 16
            ZStack {
                VStack {
                    contentView()
                        .addTapIfNotTV(if: closeOnTap) {
                            dismissCallback(.tapInside)
                        }
                        .scaleEffect(actualScale) // scale is here to avoid it messing with frameGetter for sheetContentRect
                }
                .frameGetter($sheetContentRect)
                .position(x: sheetContentRect.width / 2 + actualCurrentOffset.x, y: sheetContentRect.height / 2 + actualCurrentOffset.y)
                .onChange(of: targetCurrentOffset) { newValue in
                    if !shouldShowContent.wrappedValue, newValue == hiddenOffset { // don't animate initial positioning outside the screen
                        actualCurrentOffset = newValue
                        actualScale = targetScale
                    } else {
                        withAnimation(animation) {
                            actualCurrentOffset = newValue
                            actualScale = targetScale
                        }
                    }
                }
                .onChange(of: targetScale) { newValue in
                    if !shouldShowContent.wrappedValue, newValue == hiddenScale { // don't animate initial positioning outside the screen
                        actualCurrentOffset = targetCurrentOffset
                        actualScale = newValue
                    } else {
                        withAnimation(animation) {
                            actualCurrentOffset = targetCurrentOffset
                            actualScale = newValue
                        }
                    }
                }
                .onChange(of: sheetContentRect.size) { _ in
                    positionIsCalculatedCallback()
                }
                .onOrientationChange(isLandscape: $isLandscape) {
                    actualCurrentOffset = targetCurrentOffset
                }
            }
        }
    }

    func sheetWithDragGesture() -> some View {
        let drag = DragGesture()
            .updating($dragState) { drag, state, _ in
                state = .dragging(translation: drag.translation)
            }
            .onEnded(onDragEnded)

        return sheet()
            .applyIf(dragToDismiss) {
                $0
                    .offset(dragOffset())
                    .gesture(drag)
            }
    }

    func changeParamsWithAnimation(_ isDisplayAnimation: Bool) {
        actualCurrentOffset = isDisplayAnimation ? CGPointMake(displayedOffsetX, displayedOffsetY) : hiddenOffset
        actualScale = isDisplayAnimation ? displayedScale : hiddenScale
    }

    func dragOffset() -> CGSize {
        if dragState.translation == .zero {
            return lastDragPosition
        }

        switch calculatedAppearFrom {
        case .topSlide:
            if dragState.translation.height < 0 {
                return CGSize(width: 0, height: dragState.translation.height)
            }
        case .bottomSlide:
            if dragState.translation.height > 0 {
                return CGSize(width: 0, height: dragState.translation.height)
            }
        case .leftSlide:
            if dragState.translation.width < 0 {
                return CGSize(width: dragState.translation.width, height: 0)
            }
        case .rightSlide:
            if dragState.translation.width > 0 {
                return CGSize(width: dragState.translation.width, height: 0)
            }
        case .centerScale:
            return .zero
        }
        return .zero
    }

    private func onDragEnded(drag: DragGesture.Value) {
        var referenceX = sheetContentRect.width / 3
        var referenceY = sheetContentRect.height / 3

        if let dragToDismissDistance {
            referenceX = dragToDismissDistance
            referenceY = dragToDismissDistance
        }

        var shouldDismiss = false
        switch calculatedAppearFrom {
        case .topSlide:
            if drag.translation.height < 0 {
                lastDragPosition = CGSize(width: 0, height: drag.translation.height)
            }
            if drag.translation.height < -referenceY {
                shouldDismiss = true
            }
        case .bottomSlide:
            if drag.translation.height > 0 {
                lastDragPosition = CGSize(width: 0, height: drag.translation.height)
            }
            if drag.translation.height > referenceY {
                shouldDismiss = true
            }
        case .leftSlide:
            if drag.translation.width < 0 {
                lastDragPosition = CGSize(width: drag.translation.width, height: 0)
            }
            if drag.translation.width < -referenceX {
                shouldDismiss = true
            }
        case .rightSlide:
            if drag.translation.width > 0 {
                lastDragPosition = CGSize(width: drag.translation.width, height: 0)
            }
            if drag.translation.width > referenceX {
                shouldDismiss = true
            }
        case .centerScale:
            break
        }

        if shouldDismiss {
            dismissCallback(.drag)
        } else {
            withAnimation {
                lastDragPosition = .zero
            }
        }
    }
}

public enum PopupDismissSource {
    case binding
    case tapInside
    case tapOutside
    case drag
    case autohide
}

extension UIScrollView {
    func maxContentOffsetHeight() -> CGFloat {
        let contentHeight = contentSize.height
        let visibleHeight = bounds.height
        let maxOffsetHeight = max(0, contentHeight - visibleHeight)
        return maxOffsetHeight
    }
}

final class PopupScrollViewDelegate: NSObject, ObservableObject, UIScrollViewDelegate {
    var scrollView: UIScrollView?

    var gestureIsCreated = false

    var didReachTop: (Double) -> Void = { _ in }
    var scrollEnded: (Double) -> Void = { _ in }

    @objc
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: scrollView)
        let contentOffset = scrollView?.contentOffset.y ?? 0
        let maxContentOffset = scrollView?.maxContentOffsetHeight() ?? 0

        if contentOffset - translation.y > 0 {
            scrollView?.contentOffset.y = min(contentOffset - translation.y, maxContentOffset)
            gesture.setTranslation(.zero, in: scrollView)
        } else {
            scrollView?.contentOffset.y = 0
            didReachTop(contentOffset - translation.y)
        }

        if gesture.state == .ended && contentOffset - translation.y < 0 {
            scrollEnded(contentOffset - translation.y)
        }
    }

    func addGestureIfNeeded() {
        guard let gestures = scrollView?.gestureRecognizers else { return }

        if !gestureIsCreated {
            let panGesture = gestures[1] as? UIPanGestureRecognizer
            panGesture?.addTarget(self, action: #selector(handlePan))
            scrollView?.bounces = false
            gestureIsCreated = true
        }
    }
}

struct PopupDismissKey: EnvironmentKey {
    static let defaultValue: (@Sendable @MainActor () -> Void)? = nil
}

extension EnvironmentValues {
    public var popupDismiss: (@Sendable @MainActor () -> Void)? {
        get { self[PopupDismissKey.self] }
        set { self[PopupDismissKey.self] = newValue }
    }
}

@available(iOS 14.0, *)
extension View {
    public func popup<PopupContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder view: @escaping () -> PopupContent,
        customize: @escaping (Popup<PopupContent>.PopupParameters) -> Popup<PopupContent>.PopupParameters
    ) -> some View {
        modifier(
            FullscreenPopup<Int, PopupContent>(
                isPresented: isPresented,
                isBoolMode: true,
                params: customize(Popup<PopupContent>.PopupParameters()),
                view: view,
                itemView: nil
            )
        )
        .environment(\.popupDismiss) {
            isPresented.wrappedValue = false
        }
    }

    public func popup<Item: Equatable, PopupContent: View>(
        item: Binding<Item?>,
        @ViewBuilder itemView: @escaping (Item) -> PopupContent,
        customize: @escaping (Popup<PopupContent>.PopupParameters) -> Popup<PopupContent>.PopupParameters
    ) -> some View {
        modifier(
            FullscreenPopup<Item, PopupContent>(
                item: item,
                isBoolMode: false,
                params: customize(Popup<PopupContent>.PopupParameters()),
                view: nil,
                itemView: itemView
            )
        )
        .environment(\.popupDismiss) {
            item.wrappedValue = nil
        }
    }

    public func popup<PopupContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder view: @escaping () -> PopupContent
    ) -> some View {
        modifier(
            FullscreenPopup<Int, PopupContent>(
                isPresented: isPresented,
                isBoolMode: true,
                params: Popup<PopupContent>.PopupParameters(),
                view: view,
                itemView: nil
            )
        )
        .environment(\.popupDismiss) {
            isPresented.wrappedValue = false
        }
    }

    public func popup<Item: Equatable, PopupContent: View>(
        item: Binding<Item?>,
        @ViewBuilder itemView: @escaping (Item) -> PopupContent
    ) -> some View {
        modifier(
            FullscreenPopup<Item, PopupContent>(
                item: item,
                isBoolMode: false,
                params: Popup<PopupContent>.PopupParameters(),
                view: nil,
                itemView: itemView
            )
        )
        .environment(\.popupDismiss) {
            item.wrappedValue = nil
        }
    }
}

@available(iOS 14.0, *)
extension View {
    func onOrientationChange(isLandscape: Binding<Bool>, onOrientationChange: @escaping () -> Void) -> some View {
        modifier(OrientationChangeModifier(isLandscape: isLandscape, onOrientationChange: onOrientationChange))
    }
}

@available(iOS 14.0, *)
struct OrientationChangeModifier: ViewModifier {
    @Binding var isLandscape: Bool
    let onOrientationChange: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default
                .publisher(for: UIDevice.orientationDidChangeNotification)
                .receive(on: DispatchQueue.main)
            ) { _ in
                updateOrientation()
            }
            .onChange(of: isLandscape) { _ in
                onOrientationChange()
            }
    }

    private func updateOrientation() {
        DispatchQueue.main.async {
            let newIsLandscape = UIDevice.current.orientation.isLandscape
            if newIsLandscape != isLandscape {
                isLandscape = newIsLandscape
                onOrientationChange()
            }
        }
    }
}

@available(iOS 14.0, *)
public struct FullscreenPopup<Item: Equatable, PopupContent: View>: ViewModifier {
    // MARK: - Presentation
    @State var id = UUID()

    @Binding var isPresented: Bool
    @Binding var item: Item?

    var isBoolMode: Bool

    var popupPresented: Bool {
        item != nil || isPresented
    }

    // MARK: - Parameters
    /// If nil - never hides on its own
    var autohideIn: Double?

    /// Should close on tap outside - default is `false`
    var closeOnTapOutside: Bool

    /// Background color for outside area - default is `Color.clear`
    var backgroundColor: Color

    /// Custom background view for outside area
    var backgroundView: AnyView?

    /// If opaque - taps do not pass through popup's background color
    var displayMode: Popup<PopupContent>.DisplayMode

    /// called when when dismiss animation starts
    var userWillDismissCallback: (PopupDismissSource) -> Void

    /// called when when dismiss animation ends
    var userDismissCallback: (PopupDismissSource) -> Void

    var params: Popup<PopupContent>.PopupParameters

    var view: (() -> PopupContent)!
    var itemView: ((Item) -> PopupContent)!

    // MARK: - Presentation animation
    /// Trigger popup showing/hiding animations and...
    @State private var shouldShowContent = false

    /// ... once hiding animation is finished remove popup from the memory using this flag
    @State private var showContent = false

    /// keep track of closing state to avoid unnecessary showing bug
    @State private var closingIsInProcess = false

    /// show transparentNonAnimatingFullScreenCover
    @State private var showSheet = false

    /// opacity of background color
    @State private var animatableOpacity: CGFloat = 0

    /// A temporary variable to hold a copy of the `itemView` when the item is nil (to complete `itemView`'s dismiss animation)
    @State private var tempItemView: PopupContent?

    // MARK: - Autohide
    /// Class reference for capturing a weak reference later in dispatch work holder.
    private var isPresentedRef: ClassReference<Binding<Bool>>?
    private var itemRef: ClassReference<Binding<Item?>>?

    /// holder for autohiding dispatch work (to be able to cancel it when needed)
    @State private var dispatchWorkHolder = DispatchWorkHolder()

    // MARK: - Internal
    /// Set dismiss source to pass to dismiss callback
    @State private var dismissSource: PopupDismissSource?

    /// Synchronize isPresented changes and animations
    private let eventsQueue = DispatchQueue(label: "eventsQueue", qos: .utility)
    @State private var eventsSemaphore = DispatchSemaphore(value: 1)

    init(isPresented: Binding<Bool> = .constant(false),
         item: Binding<Item?> = .constant(nil),
         isBoolMode: Bool,
         params: Popup<PopupContent>.PopupParameters,
         view: (() -> PopupContent)?,
         itemView: ((Item) -> PopupContent)?) {
        self._isPresented = isPresented
        self._item = item
        self.isBoolMode = isBoolMode

        self.params = params
        self.autohideIn = params.autohideIn
        self.closeOnTapOutside = params.closeOnTapOutside
        self.backgroundColor = params.backgroundColor
        self.backgroundView = params.backgroundView
        self.displayMode = params.displayMode
        self.userDismissCallback = params.dismissCallback
        self.userWillDismissCallback = params.willDismissCallback

        if let view {
            self.view = view
        }
        if let itemView {
            self.itemView = itemView
        }

        self.isPresentedRef = ClassReference(self.$isPresented)
        self.itemRef = ClassReference(self.$item)
    }

    public func body(content: Content) -> some View {
        if isBoolMode {
            main(content: content)
                .onChange(of: isPresented) { newValue in
                    eventsQueue.async { [eventsSemaphore] in
                        eventsSemaphore.wait()
                        DispatchQueue.main.async {
                            closingIsInProcess = !newValue
                            appearAction(popupPresented: newValue)
                        }
                    }
                }
                .onAppear {
                    if isPresented {
                        appearAction(popupPresented: true)
                    }
                }
        } else {
            main(content: content)
                .onChange(of: item) { newValue in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                        closingIsInProcess = newValue == nil
                        if let newValue {
                            tempItemView = itemView(newValue)
                        }
                        appearAction(popupPresented: newValue != nil)
                    }
                }
                .onAppear {
                    if let item {
                        tempItemView = itemView(item)
                        appearAction(popupPresented: true)
                    }
                }
        }
    }

    @ViewBuilder
    public func main(content: Content) -> some View {
        switch displayMode {
        case .overlay:
            ZStack {
                content
                constructPopup()
            }

        case .sheet:
            content.transparentNonAnimatingFullScreenCover(isPresented: $showSheet, dismissSource: dismissSource, userDismissCallback: userDismissCallback) {
                constructPopup()
            }

        case .window:
            content
                .onChange(of: showSheet) { newValue in
                    if newValue {
                        PopupWindowManager.showInNewWindow(id: id, dismissClosure: {
                            dismissSource = .binding
                            isPresented = false
                            item = nil
                        }) {
                            constructPopup()
                        }
                    } else {
                        PopupWindowManager.closeWindow(id: id)
                    }
                }
        }
    }

    @ViewBuilder
    func constructPopup() -> some View {
        if showContent {
            PopupBackgroundView(
                id: $id,
                isPresented: $isPresented,
                item: $item,
                animatableOpacity: $animatableOpacity,
                dismissSource: $dismissSource,
                backgroundColor: backgroundColor,
                closeOnTapOutside: closeOnTapOutside
            )
            .modifier(getModifier())
        }
    }

    var viewForItem: (() -> PopupContent)? {
        if let item {
            return { itemView(item) }
        } else if let tempItemView {
            return { tempItemView }
        }
        return nil
    }

    private func getModifier() -> Popup<PopupContent> {
        Popup(
            params: params,
            view: viewForItem != nil ? viewForItem! : view,
            popupPresented: popupPresented,
            shouldShowContent: $shouldShowContent,
            showContent: showContent,
            positionIsCalculatedCallback: {
                if !closingIsInProcess {
                    DispatchQueue.main.async {
                        shouldShowContent = true
                        withAnimation(.linear(duration: 0.2)) {
                            animatableOpacity = 1
                        }
                    }
                    setupAutohide()
                }
            },
            animationCompletedCallback: onAnimationCompleted,
            dismissCallback: { source in
                dismissSource = source
                isPresented = false
                item = nil
            }
        )
    }

    func appearAction(popupPresented: Bool) {
        if popupPresented {
            dismissSource = nil
            showSheet = true
            showContent = true
        } else {
            closingIsInProcess = true
            userWillDismissCallback(dismissSource ?? .binding)
            dispatchWorkHolder.work?.cancel()
            shouldShowContent = false
            animatableOpacity = 0
        }

        if #unavailable(iOS 17.0) {
            performWithDelay(0.3) {
                onAnimationCompleted()
            }
        }
    }

    func onAnimationCompleted() {
        if shouldShowContent {
            eventsSemaphore.signal()
            return
        }
        showContent = false
        tempItemView = nil
        performWithDelay(0.01) {
            showSheet = false
        }
        if displayMode != .sheet {
            userDismissCallback(dismissSource ?? .binding)
        }

        eventsSemaphore.signal()
    }

    func setupAutohide() {
        if let autohideIn {
            dispatchWorkHolder.work?.cancel()

            dispatchWorkHolder.work = DispatchWorkItem(block: { [weak isPresentedRef, weak itemRef] in
                dismissSource = .autohide
                isPresentedRef?.value.wrappedValue = false
                itemRef?.value.wrappedValue = nil
                dispatchWorkHolder.work = nil
            })
            if popupPresented, let work = dispatchWorkHolder.work {
                DispatchQueue.main.asyncAfter(deadline: .now() + autohideIn, execute: work)
            }
        }
    }

    func performWithDelay(_ delay: Double, block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            block()
        }
    }
}

struct PopupBackgroundView<Item: Equatable>: View {
    @Binding var id: UUID

    @Binding var isPresented: Bool
    @Binding var item: Item?

    @Binding var animatableOpacity: CGFloat
    @Binding var dismissSource: PopupDismissSource?

    var backgroundColor: Color
    var backgroundView: AnyView?
    var closeOnTapOutside: Bool

    var body: some View {
        Group {
            if let backgroundView {
                backgroundView
            } else {
                backgroundColor
            }
        }
        .opacity(animatableOpacity)
        .applyIf(closeOnTapOutside) { view in
            view.contentShape(Rectangle())
        }
        .addTapIfNotTV(if: closeOnTapOutside) {
            dismissSource = .tapOutside
            isPresented = false
            item = nil
        }
        .edgesIgnoringSafeArea(.all)
        .animation(.linear(duration: 0.2), value: animatableOpacity)
    }
}

struct PopupMemoryAddress<T>: CustomStringConvertible {
    let intValue: Int

    var description: String {
        let length = 2 + 2 * MemoryLayout<UnsafeRawPointer>.size
        return String(format: "%0\(length)p", intValue)
    }

    init(of structPointer: UnsafePointer<T>) {
        self.intValue = Int(bitPattern: structPointer)
    }
}

extension PopupMemoryAddress where T: AnyObject {
    init(of classInstance: T) {
        self.intValue = unsafeBitCast(classInstance, to: Int.self)
    }
}

final class DispatchWorkHolder {
    var work: DispatchWorkItem?
}

final class ClassReference<T> {
    var value: T

    init(_ value: T) {
        self.value = value
    }
}

@available(iOS 14.0, *)
extension View {
    @ViewBuilder
    func valueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
        self.onChange(of: value, perform: onChange)
    }
}

extension View {
    @ViewBuilder
    func applyIf<T: View>(_ condition: Bool, apply: (Self) -> T) -> some View {
        if condition {
            apply(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func addTapIfNotTV(if condition: Bool, onTap: @escaping () -> Void) -> some View {
        if condition {
            simultaneousGesture(
                TapGesture().onEnded {
                    onTap()
                }
            )
        } else {
            self
        }
    }
}

// MARK: - FrameGetter
struct FrameGetter: ViewModifier {
    @Binding var frame: CGRect

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy -> AnyView in
                    DispatchQueue.main.async {
                        let rect = proxy.frame(in: .global)
                        if rect.integral != frame.integral {
                            frame = rect
                        }
                    }
                    return AnyView(EmptyView())
                }
            )
    }
}

extension View {
    func frameGetter(_ frame: Binding<CGRect>) -> some View {
        modifier(FrameGetter(frame: frame))
    }
}

struct SafeAreaGetter: ViewModifier {
    @Binding var safeArea: EdgeInsets

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy -> AnyView in
                    DispatchQueue.main.async {
                        let area = proxy.safeAreaInsets
                        if area != safeArea {
                            safeArea = area
                        }
                    }
                    return AnyView(EmptyView())
                }
            )
    }
}

extension View {
    public func safeAreaGetter(_ safeArea: Binding<EdgeInsets>) -> some View {
        modifier(SafeAreaGetter(safeArea: safeArea))
    }
}

// MARK: - TransparentNonAnimatingFullScreenCover
@available(iOS 14.0, *)
extension View {
    func transparentNonAnimatingFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        dismissSource: PopupDismissSource?,
        userDismissCallback: @escaping (PopupDismissSource) -> Void,
        content: @escaping () -> Content
    ) -> some View {
        modifier(TransparentNonAnimatableFullScreenModifier(isPresented: isPresented, dismissSource: dismissSource, userDismissCallback: userDismissCallback, fullScreenContent: content))
    }
}

@available(iOS 14.0, *)
private struct TransparentNonAnimatableFullScreenModifier<FullScreenContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var dismissSource: PopupDismissSource?
    var userDismissCallback: (PopupDismissSource) -> Void
    let fullScreenContent: () -> (FullScreenContent)

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _ in
                UIView.setAnimationsEnabled(false)
            }
            .fullScreenCover(isPresented: $isPresented) {
                ZStack {
                    fullScreenContent()
                }
                .background(FullScreenCoverBackgroundRemovalView())
                .onAppear {
                    if !UIView.areAnimationsEnabled {
                        UIView.setAnimationsEnabled(true)
                    }
                }
                .onDisappear {
                    userDismissCallback(dismissSource ?? .binding)
                    if !UIView.areAnimationsEnabled {
                        UIView.setAnimationsEnabled(true)
                    }
                }
            }
    }
}

private struct FullScreenCoverBackgroundRemovalView: UIViewRepresentable {
    private class BackgroundRemovalView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            superview?.superview?.backgroundColor = .clear
        }
    }

    func makeUIView(context: Context) -> UIView {
        BackgroundRemovalView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - PopupWindowManager
@MainActor class HostingViewState<Content: View>: ObservableObject {
    @Published var content: Content
    let id1: UUID

    private var cancellable: AnyCancellable?

    init(content: Content, id: UUID) {
        self.content = content
        self.id1 = id
        self.cancellable = observeStateChanges()
    }

    private func observeStateChanges() -> AnyCancellable {
        Just(content)
            .sink { [weak self] newContent in
                guard let self else { return }
                PopupWindowManager.shared.windows[id1]?.rootViewController = UIHostingController(rootView: newContent)
            }
    }
}

@MainActor public final class PopupWindowManager {
    static let shared = PopupWindowManager()
    var windows: [UUID: UIWindow] = [:]

    public static func showInNewWindow<Content: View>(id: UUID, dismissClosure: @escaping () -> Void, content: @escaping () -> Content) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("No valid scene available")
            return
        }

        let window = PopupPassthroughWindow(windowScene: scene)
        window.backgroundColor = .clear

        let controller = PopupPassthroughController(rootView: content()
            .environment(\.popupDismiss) {
                dismissClosure()
            })
        controller.view.backgroundColor = .clear
        window.rootViewController = controller
        window.windowLevel = .alert + 1
        window.makeKeyAndVisible()

        shared.windows[id] = window
    }

    static func closeWindow(id: UUID) {
        shared.windows[id]?.isHidden = true
        shared.windows.removeValue(forKey: id)
    }
}

class PopupPassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let vc = rootViewController {
            vc.view.layoutSubviews()
            if let _ = isTouchInsideSubview(point: point, vc: vc.view) {
                return vc.view
            }
        }
        return nil
    }

    private func isTouchInsideSubview(point: CGPoint, vc: UIView) -> UIView? {
        for subview in vc.subviews {
            if subview.frame.contains(point) {
                return subview
            }
        }
        return nil
    }
}

class PopupPassthroughController<Content: View>: UIHostingController<Content> {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isTouchInsideSubview(touches) {
            super.touchesBegan(touches, with: event)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isTouchInsideSubview(touches) {
            super.touchesMoved(touches, with: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isTouchInsideSubview(touches) {
            super.touchesEnded(touches, with: event)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isTouchInsideSubview(touches) {
            super.touchesCancelled(touches, with: event)
        }
    }

    private func isTouchInsideSubview(_ touches: Set<UITouch>) -> Bool {
        guard let touch = touches.first else {
            return false
        }

        let touchLocation = touch.location(in: view)
        for subview in view.subviews {
            if subview.frame.contains(touchLocation) {
                return true
            }
        }
        return false
    }
}

// MARK: - KeyboardHeightHelper
@MainActor class KeyboardHeightHelper: ObservableObject {
    static var pointFarAwayFromScreen: CGPoint {
        CGPoint(x: 2 * UIScreen.main.bounds.size.width, y: 2 * UIScreen.main.bounds.size.height)
    }
    
    @Published var keyboardHeight: CGFloat = 0
    @Published var keyboardDisplayed: Bool = false

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardWillShowNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardWillHideNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func onKeyboardWillShowNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        DispatchQueue.main.async {
            self.keyboardHeight = keyboardRect.height
            self.keyboardDisplayed = true
        }
    }

    @objc private func onKeyboardWillHideNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        DispatchQueue.main.async {
            self.keyboardHeight = keyboardRect.height
            self.keyboardDisplayed = true
        }
    }
}

#endif

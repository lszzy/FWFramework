//
//  View+FWKeyboard.swift
//
//  Created by Nicholas Fox on 10/4/19.
//

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

/// https://github.com/nickffox/KeyboardObserving
@available(iOS 13.0, *)
struct FWKeyboardObserving: ViewModifier {

  var offset: CGFloat
  @State var keyboardHeight: CGFloat = 0
  @State var keyboardAnimationDuration: Double = 0

  func body(content: Content) -> some View {
    content
      .padding([.bottom], keyboardHeight)
      .edgesIgnoringSafeArea((keyboardHeight > 0) ? [.bottom] : [])
      .animation(.easeOut(duration: keyboardAnimationDuration))
      .onReceive(
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
          .receive(on: RunLoop.main),
        perform: updateKeyboardHeight
      )
  }

  func updateKeyboardHeight(_ notification: Notification) {
    guard let info = notification.userInfo else { return }
    // Get the duration of the keyboard animation
    keyboardAnimationDuration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double)
      ?? 0.25

    guard let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
      else { return }
    // If the top of the frame is at the bottom of the screen, set the height to 0.
    if keyboardFrame.origin.y == UIScreen.main.bounds.height {
      keyboardHeight = 0
    } else {
      // IMPORTANT: This height will _include_ the SafeAreaInset height.
      keyboardHeight = keyboardFrame.height + offset
    }
  }
}

@available(iOS 13.0, *)
struct FWHiddenOnKeyboardViewModifier: ViewModifier {
  @EnvironmentObject private var fwKeyboard: FWKeyboard

  let transition: AnyTransition

  func body(content: Content) -> some View {
    Group {
      if fwKeyboard.state.height == 0 {
        content
          .transition(transition)
          .animation(.easeOut(duration: fwKeyboard.state.animationDuration))
      } else {
        EmptyView()
      }
    }
  }
}

@available(iOS 13.0, *)
extension View {
  /// Automatically hides the view when keyboard is shown.
  /// - Warning: A Keyboard must be available in the Environment.
  /// - Parameter transition: Transition which will be used to hide or show the view during keyboard presentation. By default it animated opacity.
  /// - Returns: A view which is empty if keyboard is visible.
  public func fwHideOnKeyboard(transition: AnyTransition = .opacity) -> some View {
    self.modifier(FWHiddenOnKeyboardViewModifier(transition: transition))
  }
    
  public func fwKeyboardObserving(offset: CGFloat = 0.0) -> some View {
    self.modifier(FWKeyboardObserving(offset: offset))
  }
}

/// An object representing the keyboard
@available(iOS 13.0, *)
public final class FWKeyboard: ObservableObject {

  // MARK: - Published Properties

  @Published public var state: FWKeyboard.State = .default

  // MARK: - Private Properties

  private var cancellables: Set<AnyCancellable> = []
  private var notificationCenter: NotificationCenter

  // MARK: - Initializers

  public init(notificationCenter: NotificationCenter = .default) {
    self.notificationCenter = notificationCenter

    // Observe keyboard notifications and transform them into state updates
    notificationCenter.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
      .compactMap(FWKeyboard.State.from(notification:))
      .assign(to: \.state, on: self)
      .store(in: &cancellables)
  }

  deinit {
    cancellables.forEach { $0.cancel() }
  }
}

// MARK: - Nested Types
@available(iOS 13.0, *)
extension FWKeyboard {

  public struct State {

    // MARK: - Properties

    public let animationDuration: TimeInterval
    public let height: CGFloat

    // MARK: - Initializers

    init(animationDuration: TimeInterval, height: CGFloat) {
      self.animationDuration = animationDuration
      self.height = height
    }

    // MARK: - Static Properties

    fileprivate static let `default` = FWKeyboard.State(animationDuration: 0.25, height: 0)

    // MARK: - Static Methods

    static func from(notification: Notification) -> FWKeyboard.State? {
      return from(
        notification: notification,
        screen: .main
      )
    }

    // NOTE: A testable version of the transform that injects the dependencies.
    static func from(
      notification: Notification,
      screen: UIScreen
    ) -> FWKeyboard.State? {
      guard let userInfo = notification.userInfo else { return nil }
      // NOTE: We could eventually get the aniamtion curve here too.
      // Get the duration of the keyboard animation
      let animationDuration =
        (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        ?? 0.25

      // Get keyboard height
      var height: CGFloat = 0
      if let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
        // If the rectangle is at the bottom of the screen, set the height to 0.
        if keyboardFrame.origin.y == screen.bounds.height {
          height = 0
        } else {
          height = keyboardFrame.height
        }
      }

      return FWKeyboard.State(
        animationDuration: animationDuration,
        height: height
      )
    }
  }
}

/// A View that adjusts its content based on the keyboard.
///
/// Important: A Keyboard must be available in the Environment.
///
@available(iOS 13.0, *)
public struct FWKeyboardObservingView<Content: View>: View {

  @EnvironmentObject var fwKeyboard: FWKeyboard

  let content: Content

  public init(@ViewBuilder builder: () -> Content) {
    self.content = builder()
  }

  public var body: some View {
  
  // for some reason, this can cause stuttering
  // in mac catalyst applications
  // and we don't need to observe the keyboard
  // in mac catalist anyway
  // so only return the content in mac catalyst
  // (I think it's the animation, but I'm not sure)
  return content
      .padding([.bottom], fwKeyboard.state.height)
      .edgesIgnoringSafeArea((fwKeyboard.state.height > 0) ? [.bottom] : [])
      .animation(.easeOut(duration: fwKeyboard.state.animationDuration))
  }
}

#endif

//
//  BlocView.swift
//  FWFramework
//
//  Created by wuyong on 2025/8/7.
//

import Combine
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - Base
/// A state managing base class.
///
/// [SwiftBloc](https://github.com/kvs-coder/SwiftBloc)
open class Base<State>: ObservableObject where State: Equatable {
    /**
     Whenever a state will be changed, the instance of the **Cubit** wrapped in **ObservedObject** in your **View** structure will receive
     a new value of state. Based on this you can set the strict dependency of how to build your views.
     */
    @Published public internal(set) var state: State
    /**
     Additional variable to make sure that previously the cubit was not emitting any new states
     */
    var emitted = false
    /**
     Will return a shared instance of **BlocObserver** which will notify about changes and transitions of states
     You may create a custom observer of **BlocObserver**
     */
    var observer: BlocObserver {
        BlocObserver.shared
    }

    /**
     Cubit constructor
     - parameter state: initial state.
     */
    public init(state: State) {
        self.state = state
        observer.onCreate(base: self)
    }

    /**
     Deinitializer which will trigger observer callback **onClose**
     */
    deinit {
        observer.onClose(base: self)
    }
}

// MARK: - Cubit
/**
 A state managing class not dependent on incoming events.
 */
open class Cubit<State>: Base<State> where State: Equatable {
    /**
     Emits a new state.
     - parameter state: new state.
     */
    public func emit(state: State) {
        if state == self.state && emitted {
            observer.onError(base: self, error: CubitError.stateNotChanged)
            return
        }
        let change = Change(currentState: self.state, nextState: state)
        observer.onChange(base: self, change: change)
        self.state = state
        emitted = true
    }
}

// MARK: - Bloc
/**
 A state managing class with lower level of abstraction and unlike **Cubit** it depends on incoming events.
 */
open class Bloc<Event, State>: Base<State> where State: Equatable, Event: Equatable {
    /**
     Whenever a new event happens, the instance of the **Bloc** wrapped in **ObservedObject**  in your **View** structure will receive
     a new value of event..
     */
    @Published public internal(set) var event: Event?
    /**
     A collector for **AnyCancellable**
     */
    private var cancellables = Set<AnyCancellable>()
    /**
     Bloc constructor
     - parameter initialState: initial state.
     */
    public init(initialState: State) {
        super.init(state: initialState)
        bindEventsToStates()
    }

    /**
     Deinitializer which will trigger observer callback **onClose** and remove all cancellables.
     */
    deinit {
        cancellables.forEach { $0.cancel() }
        observer.onClose(base: self)
    }

    /**
     Adds a new event.
     - parameter event: new event.
     */
    public func add(event: Event) {
        observer.onEvent(bloc: self, event: event)
        self.event = event
    }

    /**
     The mapping function which is responsible for creating states out of event.
     The idea is to listen for the incoming event and based on that create an appropriate new state of the view
     - parameter event: incoming event.
     - returns: new state instance
     - warning: The function should be overridden in a child class

     # Notes: #
     1. If not overridden, will fail with **preconditionFailure**
     */
    open func mapEventToState(event: Event) -> State {
        preconditionFailure("This method must be overridden")
    }

    /**
     Binds event to state. Function **mapEventToState** is the core of the transition creation
     */
    private func bindEventsToStates() {
        $event
            .compactMap { [unowned self] event -> Transition<Event, State>? in
                guard let event else {
                    observer.onError(base: self, error: BlocError.noEvent)
                    return nil
                }
                let nextState = mapEventToState(event: event)
                return Transition(
                    currentState: state,
                    event: event,
                    nextState: nextState
                )
            }
            .map { [unowned self] transition -> State in
                if transition.nextState == state && emitted {
                    observer.onError(base: self, error: CubitError.stateNotChanged)
                    return state
                }
                observer.onTransition(bloc: self, transition: transition)
                emitted = true
                return transition.nextState
            }
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
}

// MARK: - BlocObserver
/**
 An observer to observe emitted states or added events.
 You may create your own singleton observer class and set a new value for a **shared** property
 */
open class BlocObserver {
    /**
     As a shared instance is used in **Cubit** and **Bloc** to make tracking of event/state changes via callbacks
     */
    public static var shared: BlocObserver {
        get { FrameworkConfiguration.sharedBlocObserver }
        set { FrameworkConfiguration.sharedBlocObserver = newValue }
    }
    /**
     BlocObserver constructor
     - parameter intialState: initial state.
     */
    public init() {
        logInfo("BlocObserver init")
    }

    deinit {
        logInfo("BlocObserver deinit")
    }

    /**
     Called when **Bloc** or **Cubit** instance is created.
     - parameter cubit: cubit or bloc.
     */
    open func onCreate<State>(base: Base<State>) {
        logInfo("onCreate - \(base)")
    }

    /**
     Called when a new event is added to **Bloc** instance.
     - parameter bloc: bloc.
     - parameter event: a new event.
     */
    open func onEvent<Event, State>(bloc: Bloc<Event, State>, event: Event) {
        logInfo("onEvent - \(bloc), \(event)")
    }

    /**
     Called when state changes in **Base** instance.
     - parameter base: base.
     - parameter change: a change to a new state.
     */
    open func onChange<State>(base: Base<State>, change: Change<State>) {
        logInfo("onChange - \(base), \(change)")
    }

    /**
     Called when state based on the event changes in **Bloc** instance.
     - parameter bloc: bloc.
     - parameter transition: a change to a new state.
     */
    open func onTransition<Event, State>(bloc: Bloc<Event, State>, transition: Transition<Event, State>) {
        logInfo("onTransition - \(bloc), \(transition)")
    }

    /**
     Called if an error occurs in **Cubit** or **Bloc** instance.
     - parameter base: cubit.
     - parameter error: a reported error.
     */
    open func onError<State>(base: Base<State>, error: Error) {
        logError("onError - \(base), \(error)")
    }

    /**
     Called when **BlocBase** or **Bloc** instance is destroyed.
     - parameter base: base.
     */
    open func onClose<State>(base: Base<State>) {
        logInfo("onClose - \(base)")
    }

    /**
     Log with info message.
     */
    open func logInfo(
        _ message: String,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        #if DEBUG
        Logger.debug(group: Logger.fw.moduleName, "Bloc: %@", message, function: function, file: file, line: line)
        #endif
    }

    /**
     Log with error message.
     */
    open func logError(
        _ message: String,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        #if DEBUG
        Logger.debug(group: Logger.fw.moduleName, "Bloc: %@", message, function: function, file: file, line: line)
        #endif
    }
}

// MARK: - BlocView
/**
 BlocViewBuilder
 - parameter state: current state.
 - returns: content view
 */
public typealias BlocViewBuilder<B: Base<S>, S: Equatable, Content: View> = (_ base: B) -> Content
/**
 BlocViewAction
 - parameter state: current state.
 */
public typealias BlocViewAction<B: Base<S>, S: Equatable> = (_ base: B) -> Void
/**
 A general protocol for the **BlocView** class.
 */
protocol BlocViewProtocol: View {
    associatedtype S where S: Equatable
    associatedtype B where B: Base<S>
    associatedtype Content where Content: View

    var base: B { get }

    func build(base: B) -> Content
}

/**
 A wrapper for a **View** conforming view providing BloC instance as **EnvironmentObject**.
 Expects **Cubit** (**Bloc** as well) conforming BloC component with **Equatable** state object.
 */
public struct BlocView<B: Base<S>, S: Equatable, Content: View>: BlocViewProtocol {
    /**
     A cubit/bloc property which holds the custom business logic
     */
    @ObservedObject var base: B
    /**
     Extract the current state from a cubit/bloc
     */
    private var state: S {
        base.state
    }

    /**
     @ViewBuilder callback. Builds views based on the state.
     */
    private let builder: BlocViewBuilder<B, S, Content>
    /**
     (Optional) Custom action callback. Called every time the state is changed.
     */
    private let action: BlocViewAction<B, S>?
    /**
     Required property of View Protocol. Body will set the current cubit/bloc instance as **EnvironmentObject** if the instance
     is wrapped in an **ObservedObject** property wrapper in your View.
     */
    public var body: some View {
        build(base: base)
            .listen(base: base, action: action)
            .environmentObject(base)
    }

    /**
     BlocView constructor
     - parameter builder: builder callback.
     - parameter action: custom action callback. Optional
     - parameter cubit: cubit/bloc instance.
     */
    public init(
        @ViewBuilder builder: @escaping BlocViewBuilder<B, S, Content>,
        action: BlocViewAction<B, S>? = nil,
        base: B
    ) {
        self.builder = builder
        self.action = action
        self.base = base
    }

    /**
     Builds the view **Content** based on the state
     - parameter base: the **Bloc** or **Cubit** object.
     - returns: content view
     */
    func build(base: B) -> Content {
        builder(base)
    }
}

// MARK: - Change
/**
 Change class for tracking state changes
 */
public class Change<State> {
    public let currentState: State
    public let nextState: State

    var description: String {
        "Change currentState: \(currentState) to nextState: \(nextState)"
    }

    init(currentState: State, nextState: State) {
        self.currentState = currentState
        self.nextState = nextState
    }
}

extension Change: Equatable where State: Equatable {
    public static func ==(lhs: Change<State>, rhs: Change<State>) -> Bool {
        lhs.currentState == rhs.currentState && lhs.nextState == rhs.nextState
    }
}

// MARK: - Transition
/**
 A transition which tracks states based on incoming events
 */
public class Transition<Event, State>: Change<State> {
    public let event: Event

    override var description: String {
        "Event: \(event) transition from currentState: \(currentState) to nextState: \(nextState)"
    }

    init(
        currentState: State,
        event: Event,
        nextState: State
    ) {
        self.event = event
        super.init(currentState: currentState, nextState: nextState)
    }
}

extension Transition where State: Equatable, Event: Equatable {
    public static func ==(lhs: Transition<Event, State>, rhs: Transition<Event, State>) -> Bool {
        lhs.currentState == rhs.currentState && lhs.nextState == rhs.nextState && lhs.event == rhs.event
    }
}

// MARK: - BlocError
/**
 Bloc errors
 */
public enum BlocError: Error {
    case noEvent
}

/**
 Cubit (more abstract) errors
 */
public enum CubitError: Error {
    case stateNotChanged
}

// MARK: - View+BlocView
extension View {
    func listen<B: Base<S>, S: Equatable>(
        base: B,
        action: BlocViewAction<B, S>?
    ) -> some View {
        action?(base)
        return self
    }
}

// MARK: - FrameworkConfiguration+BlocView
extension FrameworkConfiguration {
    fileprivate static var sharedBlocObserver: BlocObserver = BlocObserver()
}

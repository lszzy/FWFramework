//
//  BlocConsumer.swift
//  FWFramework
//
//  Created by wuyong on 2025/8/12.
//

import Combine
import SwiftUI

// MARK: - BlocBase
/// Bloc抽象基类
open class BlocBase<State>: ObservableObject where State: Equatable {
    /// 获取当前状态
    public var state: State { stateSubject.value }

    /// 状态发布者
    public var publisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private let stateSubject: CurrentValueSubject<State, Never>
    private var stateBag = Set<AnyCancellable>()
    var observer: BlocObserver { BlocObserver.shared }
    var emitted = false

    /// 初始化起始状态
    public init(_ initialState: State) {
        self.stateSubject = .init(initialState)
        observer.onCreate(bloc: self)
    }

    deinit {
        cancel()
        observer.onClose(bloc: self)
    }

    /// 提交新状态
    public func emit(_ state: State) {
        if state == self.state && emitted { return }
        onChange(Change(currentState: self.state, nextState: state))
        stateSubject.send(state)
        emitted = true
    }

    /// 报告错误，内部调用onError方法
    public func addError(_ error: Error) {
        onError(error)
    }

    /// 订阅状态值，释放时自动取消订阅，初始值也会触发
    @discardableResult
    public func sink(_ receiveValue: @escaping (State) -> Void) -> AnyCancellable {
        let cancellable = stateSubject.sink { value in
            receiveValue(value)
        }
        cancellable.store(in: &stateBag)
        return cancellable
    }

    /// 取消状态值订阅，默认nil时取消所有
    public func cancel(_ cancellable: AnyCancellable? = nil) {
        if let cancellable {
            cancellable.cancel()
            stateBag.remove(cancellable)
        } else {
            stateBag.forEach { $0.cancel() }
            stateBag.removeAll()
        }
    }

    /// 监听改变，子类可重写，必须调用super方法
    open func onChange(_ change: Change<State>) {
        observer.onChange(bloc: self, change: change)
    }

    /// 监听错误，子类可重写，必须调用super方法
    open func onError(_ error: Error) {
        observer.onError(bloc: self, error: error)
    }
}

// MARK: - Cubit
/// Cubit基类
open class Cubit<State>: BlocBase<State> where State: Equatable {}

// MARK: - Bloc
/// Bloc基类
open class Bloc<Event, State>: BlocBase<State> where State: Equatable, Event: Equatable {
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var eventBag = Set<AnyCancellable>()
    private let eventHandler: ((Event, State, @escaping (State) -> Void) -> Void)?

    public init(
        _ initialState: State,
        mapEventToState eventHandler: ((Event, State, @escaping (State) -> Void) -> Void)? = nil
    ) {
        self.eventHandler = eventHandler
        super.init(initialState)

        eventSubject
            .sink { [unowned self] event in
                mapEventToState(event) { [unowned self] nextState in
                    emit(nextState, event: event)
                }
            }
            .store(in: &eventBag)
    }

    deinit {
        eventBag.forEach { $0.cancel() }
        eventBag.removeAll()
    }

    /// 映射事件到状态
    open func mapEventToState(_ event: Event, emit: @escaping (State) -> Void) {
        if let eventHandler {
            eventHandler(event, state, emit)
        } else {
            preconditionFailure("The mapEventToState method should be overridden")
        }
    }

    /// 指定事件并提交新状态
    public func emit(_ state: State, event: Event) {
        if state == self.state && emitted { return }
        onTransition(Transition(currentState: self.state, event: event, nextState: state))
        super.emit(state)
    }

    /// 添加新事件
    public func add(_ event: Event) {
        onEvent(event)
        eventSubject.send(event)
    }

    /// 监听新事件，子类可重写，必须调用super方法
    open func onEvent(_ event: Event) {
        observer.onEvent(bloc: self, event: event)
    }

    /// 监听转换，子类可重写，必须调用super方法
    open func onTransition(_ transition: Transition<Event, State>) {
        observer.onTransition(bloc: self, transition: transition)
    }
}

// MARK: - BlocObserver
/// Bloc监听器
open class BlocObserver {
    /// 全局监听器，可赋值为自定义监听器实现
    public nonisolated(unsafe) static var shared: BlocObserver = .init()

    /// 构造函数
    public init() {}

    /// 监听Bloc实例创建
    open func onCreate<State>(bloc: BlocBase<State>) {
        log("\(bloc) onCreate")
    }

    /// 监听Bloc事件发生
    open func onEvent<Event, State>(bloc: Bloc<Event, State>, event: Event) {
        log("\(bloc) onEvent \(event)")
    }

    /// 监听Bloc状态改变
    open func onChange<State>(bloc: BlocBase<State>, change: Change<State>) {
        log("\(bloc) onChange \(change)")
    }

    /// 监听Bloc事件转换
    open func onTransition<Event, State>(bloc: Bloc<Event, State>, transition: Transition<Event, State>) {
        log("\(bloc) onTransition \(transition)")
    }

    /// 监听Bloc错误发生
    open func onError<State>(bloc: BlocBase<State>, error: Error) {
        log("\(bloc) onError \(error)")
    }

    /// 监听Bloc对象关闭
    open func onClose<State>(bloc: BlocBase<State>) {
        log("\(bloc) onClose")
    }

    /// 记录日志，子类可重写
    open func log(_ message: String) {
        #if DEBUG
        Logger.debug(group: Logger.fw.moduleName, "Bloc: %@", message)
        #endif
    }
}

// MARK: - Change
/// 状态改变对象
public class Change<State>: CustomStringConvertible {
    public let currentState: State
    public let nextState: State

    public var description: String {
        "Change { currentState: \(currentState), nextState: \(nextState) }"
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
/// 状态转换对象
public class Transition<Event, State>: Change<State> {
    public let event: Event

    override public var description: String {
        "Transition { currentState: \(currentState), event: \(event), nextState: \(nextState) }"
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

// MARK: - BlocConsumer+UIKit
extension UIView {
    /// Bloc消费者，初始值也会触发，子视图可使用blocConsumer(of:)读取父视图Bloc对象
    public func blocConsumer<B: BlocBase<S>, S: Equatable>(
        bloc: B,
        builder: @escaping (B, S) -> Void,
        listener: ((B) -> Void)? = nil
    ) {
        let key = String(describing: B.self as AnyObject)
        fw.setProperty(bloc, forName: key)
        bloc.sink { [weak self] state in
            guard let bloc = self?.fw.property(forName: key) as? B else { return }
            builder(bloc, state)
            listener?(bloc)
        }
    }

    /// 子视图读取父视图Bloc对象
    public func blocConsumer<B: BlocBase<S>, S: Equatable>(of type: B.Type = B.self) -> B? {
        let key = String(describing: B.self as AnyObject)
        var superview: UIView? = self
        while superview != nil {
            if let bloc = superview?.fw.property(forName: key) as? B {
                return bloc
            }
            superview = superview?.superview
        }
        return nil
    }
}

extension UIViewController {
    /// Bloc消费者，初始值也会触发，子视图可使用blocConsumer(of:)读取父视图Bloc对象
    public func blocConsumer<B: BlocBase<S>, S: Equatable>(
        bloc: B,
        builder: @escaping (B, S) -> Void,
        listener: ((B) -> Void)? = nil
    ) {
        view.blocConsumer(bloc: bloc, builder: builder, listener: listener)
    }
}

// MARK: - BlocConsumer+SwiftUI
/// Bloc消费者，初始值也会触发，子视图可使用\@EnvironmentObject读取父视图Bloc对象
public struct BlocConsumer<B: BlocBase<S>, S: Equatable, Content: View>: View {
    @State private var state: S
    @State private var inited = false

    private let bloc: B
    private let builder: (B, S) -> Content
    private let listener: ((B) -> Void)?

    public init(
        bloc: B,
        @ViewBuilder builder: @escaping (B, S) -> Content,
        listener: ((B) -> Void)? = nil
    ) {
        self.bloc = bloc
        self.builder = builder
        self.listener = listener
        self.state = bloc.state
    }

    public var body: some View {
        builder(bloc, state)
            .onReceive(bloc.publisher) { state in
                if self.state != state {
                    self.state = state
                    listener?(bloc)
                } else if !inited {
                    inited = true
                    listener?(bloc)
                }
            }
            .environmentObject(bloc)
    }
}

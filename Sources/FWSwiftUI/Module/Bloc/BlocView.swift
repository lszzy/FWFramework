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

// MARK: - BlocBase
/// Bloc基类
///
/// [SwiftBloc](https://github.com/kvs-coder/SwiftBloc)
open class BlocBase<State>: ObservableObject where State: Equatable {
    /// 状态更新时触发View刷新
    @Published public internal(set) var state: State
    
    var emitted = false
    var observer: BlocObserver { BlocObserver.shared }

    /// 初始化起始状态
    public init(_ initialState: State) {
        self.state = initialState
        observer.onCreate(bloc: self)
    }

    deinit {
        observer.onClose(bloc: self)
    }
    
    /// 触发新状态
    public func emit(_ state: State) {
        if state == self.state && emitted { return }
        onChange(Change(currentState: self.state, nextState: state))
        self.state = state
        emitted = true
    }
    
    /// 报告错误，内部调用onError方法
    public func addError(_ error: Error) {
        onError(error)
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
/// Bloc基类，必须重写mapEvent方法
open class Bloc<Event, State>: BlocBase<State> where State: Equatable, Event: Equatable {
    /// 事件发生时传递View接收
    @Published public internal(set) var event: Event?
    
    private var cancellables = Set<AnyCancellable>()
    
    public override init(_ initialState: State) {
        super.init(initialState)
        bindEvents()
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    /// 处理事件并返回新的状态，子类必须重写，否则报错
    open func mapEvent(_ event: Event) -> State {
        preconditionFailure("This method must be overridden")
    }

    /// 添加新事件
    public func add(event: Event) {
        onEvent(event)
        self.event = event
    }
    
    /// 监听新事件，子类可重写，必须调用super方法
    open func onEvent(_ event: Event) {
        observer.onEvent(bloc: self, event: event)
    }
    
    /// 监听转换，子类可重写，必须调用super方法
    open func onTransition(_ transition: Transition<Event, State>) {
        observer.onTransition(bloc: self, transition: transition)
    }
    
    private func bindEvents() {
        $event
            .compactMap { [unowned self] event -> Transition<Event, State>? in
                guard let event else { return nil }
                let nextState = mapEvent(event)
                return Transition(currentState: state, event: event, nextState: nextState)
            }
            .map { [unowned self] transition -> State in
                if transition.nextState == state && emitted { return state }
                onTransition(transition)
                return transition.nextState
            }
            .sink(receiveValue: { [unowned self] value in
                emit(value)
            })
            .store(in: &cancellables)
    }
}

// MARK: - BlocObserver
/// Bloc监听器
open class BlocObserver {
    /// 全局监听器，可赋值为自定义监听器实现
    public static var shared: BlocObserver {
        get { FrameworkConfiguration.sharedBlocObserver }
        set { FrameworkConfiguration.sharedBlocObserver = newValue }
    }

    public init() {
        logInfo("BlocObserver init")
    }

    deinit {
        logInfo("BlocObserver deinit")
    }

    /// 监听Bloc实例创建
    open func onCreate<State>(bloc: BlocBase<State>) {
        logInfo("\(bloc) onCreate")
    }

    /// 监听Bloc事件发生
    open func onEvent<Event, State>(bloc: Bloc<Event, State>, event: Event) {
        logInfo("\(bloc) onEvent \(event)")
    }

    /// 监听Bloc状态改变
    open func onChange<State>(bloc: BlocBase<State>, change: Change<State>) {
        logInfo("\(bloc) onChange \(change)")
    }

    /// 监听Bloc事件转换
    open func onTransition<Event, State>(bloc: Bloc<Event, State>, transition: Transition<Event, State>) {
        logInfo("\(bloc) onTransition \(transition)")
    }

    /// 监听Bloc错误发生
    open func onError<State>(bloc: BlocBase<State>, error: Error) {
        logError("\(bloc) onError \(error)")
    }

    /// 监听Bloc对象关闭
    open func onClose<State>(bloc: BlocBase<State>) {
        logInfo("\(bloc) onClose")
    }

    /// 记录消息日志，子类可重写
    open func logInfo(_ message: String) {
        #if DEBUG
        Logger.debug(group: Logger.fw.moduleName, "Bloc: %@", message)
        #endif
    }

    /// 记录错误日志，子类可重写
    open func logError(_ message: String) {
        #if DEBUG
        Logger.debug(group: Logger.fw.moduleName, "Bloc: %@", message)
        #endif
    }
}

// MARK: - BlocTest
/// Bloc测试基类
public final class BlocTest<S: Equatable, B: BlocBase<S>> {
    /// 执行Bloc测试
    public static func execute(
        build: () -> B,
        act: ((B) -> Void)?,
        wait: TimeInterval? = 0,
        expect: (() -> Any)?,
        verify: (Bool, String) -> Void
    ) {
        var areEqual = false
        var states = [S]()
        let bloc = build()
        let scheduler = ImmediateScheduler.shared
        let cancellable = bloc.$state
            .subscribe(on: scheduler)
            .delay(for: .seconds(wait ?? 0), scheduler: scheduler)
            .sink(receiveValue: { value in
                states.append(value)
            })
        act?(bloc)
        if expect != nil {
            let expected = expect!()
            areEqual = "\(states)" == "\(expected)"
            let message = "State received: \(states). \nStates expected: \(expected)"
            verify(areEqual, message)
        }
        cancellable.cancel()
    }
}

// MARK: - BlocView
/// BlocView创建句柄
public typealias BlocViewBuilder<B: BlocBase<S>, S: Equatable, Content: View> = (_ bloc: B) -> Content

/// BlocView监听句柄
public typealias BlocViewListener<B: BlocBase<S>, S: Equatable> = (_ bloc: B) -> Void

/// BlocView通用协议
protocol BlocViewProtocol: View {
    associatedtype S where S: Equatable
    associatedtype B where B: BlocBase<S>
    associatedtype Content where Content: View

    var bloc: B { get }

    func build(bloc: B) -> Content
}

/// Bloc视图
public struct BlocView<B: BlocBase<S>, S: Equatable, Content: View>: BlocViewProtocol {
    @ObservedObject var bloc: B
    
    private var state: S { bloc.state }
    private let builder: BlocViewBuilder<B, S, Content>
    private let listener: BlocViewListener<B, S>?
    
    public var body: some View {
        build(bloc: bloc)
            .listen(bloc: bloc, listener: listener)
            .environmentObject(bloc)
    }

    /// 构造函数
    public init(
        @ViewBuilder builder: @escaping BlocViewBuilder<B, S, Content>,
        listener: BlocViewListener<B, S>? = nil,
        bloc: B
    ) {
        self.builder = builder
        self.listener = listener
        self.bloc = bloc
    }

    func build(bloc: B) -> Content {
        builder(bloc)
    }
}

// MARK: - Change
/// 状态改变对象
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
/// 状态转换对象
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

// MARK: - View+BlocView
extension View {
    func listen<B: BlocBase<S>, S: Equatable>(
        bloc: B,
        listener: BlocViewListener<B, S>?
    ) -> some View {
        listener?(bloc)
        return self
    }
}

// MARK: - FrameworkConfiguration+BlocView
extension FrameworkConfiguration {
    fileprivate static var sharedBlocObserver: BlocObserver = .init()
}

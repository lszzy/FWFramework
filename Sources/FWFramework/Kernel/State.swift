//
//  State.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation

extension Notification.Name {
    /// 状态改变通知
    public static let StateChanged = Notification.Name("FWStateChangedNotification")
}

/// 有限状态机
///
/// [TransitionKit](https://github.com/blakewatters/TransitionKit)
public class StateMachine: @unchecked Sendable {
    /// 状态类
    public class State: @unchecked Sendable {
        /// 状态名称，只读
        public private(set) var name: String

        /// 即将进入block
        public var willEnterBlock: (@MainActor @Sendable (Transition?) -> Void)?

        /// 已进入block
        public var didEnterBlock: (@MainActor @Sendable (Transition?) -> Void)?

        /// 即将退出block
        public var willExitBlock: (@MainActor @Sendable (Transition) -> Void)?

        /// 已退出block
        public var didExitBlock: (@MainActor @Sendable (Transition) -> Void)?

        /// 从名称初始化
        public init(name: String) {
            self.name = name
        }
    }

    /// 状态事件类
    public class Event: @unchecked Sendable {
        /// 事件名称，只读
        public private(set) var name: String

        /// 来源状态列表，只读
        public fileprivate(set) var sourceStates: [State]

        /// 目标状态，只读
        public private(set) var targetState: State

        /// 能否触发block
        public var shouldFireBlock: (@MainActor @Sendable (Transition) -> Bool)?

        /// 即将触发block
        public var willFireBlock: (@MainActor @Sendable (Transition) -> Void)?

        /// 正在触发block，必须调用completion标记完成结果。YES事件完成、状态改变，NO事件失败、状态不变。不设置默认完成
        public var fireBlock: (@MainActor @Sendable (Transition, @escaping @Sendable (Bool) -> Void) -> Void)?

        /// 触发完成block，finished为完成状态
        public var didFireBlock: (@MainActor @Sendable (Transition, Bool) -> Void)?

        /// 初始化事件
        public init(name: String, from states: [State], to state: State) {
            self.name = name
            self.sourceStates = states
            self.targetState = state
        }
    }

    /// 状态转换器
    public class Transition: @unchecked Sendable {
        /// 有限状态机，只读
        public private(set) var machine: StateMachine

        /// 事件对象，只读
        public private(set) var event: Event

        /// 来源状态，只读
        public private(set) var sourceState: State

        /// 目标状态，只读
        public var targetState: State {
            event.targetState
        }

        /// 附加参数，只读
        public private(set) var object: Any?

        /// 初始化转换器
        public init(in machine: StateMachine, for event: Event, from state: State, object: Any? = nil) {
            self.machine = machine
            self.event = event
            self.sourceState = state
            self.object = object
        }
    }
    
    /// 状态列表，只读
    public private(set) var states: [State] = []

    /// 事件列表，只读
    public private(set) var events: [Event] = []

    /// 当前状态，只读
    public private(set) var state: State?

    /// 初始化状态，未激活时可写
    public var initialState: State? {
        get { _initialState }
        set {
            if isActive {
                #if DEBUG
                Logger.debug(Logger.fw.moduleName, "StateMachine is activated.")
                #endif
                return
            }
            _initialState = newValue
        }
    }

    private var _initialState: State?

    /// 是否已激活
    public private(set) var isActive = false

    private var lock = NSRecursiveLock()

    /// 初始化方法
    public init() {}

    /// 添加状态，未激活时生效
    /// - Parameter object: 状态对象
    public func addState(_ object: State) {
        if isActive {
            #if DEBUG
            Logger.debug(Logger.fw.moduleName, "StateMachine is activated.")
            #endif
            return
        }

        if stateNamed(object.name) != nil { return }
        if initialState == nil {
            initialState = object
        }
        states.append(object)
    }

    /// 批量添加状态，未激活时生效
    /// - Parameter objects: 状态数组
    public func addStates(_ objects: [State]) {
        for object in objects {
            addState(object)
        }
    }

    /// 从名称获取状态
    /// - Parameter name: 状态名称
    /// - Returns: 状态对象
    public func stateNamed(_ name: String) -> State? {
        for object in states {
            if object.name == name {
                return object
            }
        }
        return nil
    }

    /// 当前状态判断
    /// - Parameter object: 状态名称或对象
    /// - Returns: 判断结果
    public func isState(_ object: Any?) -> Bool {
        var targetState = object as? State
        if let name = object as? String {
            targetState = stateNamed(name)
        }
        guard let targetState else { return false }
        return state === targetState
    }

    /// 添加事件，未激活时生效
    /// - Parameter event: 事件对象
    public func addEvent(_ event: Event) {
        if isActive {
            #if DEBUG
            Logger.debug(Logger.fw.moduleName, "StateMachine is activated.")
            #endif
            return
        }

        if eventNamed(event.name) != nil { return }
        events.append(event)
    }

    /// 批量添加事件，未激活时生效
    /// - Parameter events: 事件数组
    public func addEvents(_ events: [Event]) {
        for event in events {
            addEvent(event)
        }
    }

    /// 从名称获取事件
    /// - Parameter name: 事件名称
    /// - Returns: 事件对象
    public func eventNamed(_ name: String) -> Event? {
        for event in events {
            if event.name == name {
                return event
            }
        }
        return nil
    }

    /// 激活并锁定状态机，锁定后不能修改初始状态、添加状态和事件
    public func activate() {
        if isActive {
            #if DEBUG
            Logger.debug(Logger.fw.moduleName, "StateMachine is activated.")
            #endif
            return
        }

        lock.lock()
        isActive = true

        DispatchQueue.fw.mainAsync { [weak self] in
            self?.initialState?.willEnterBlock?(nil)
        }
        state = initialState
        DispatchQueue.fw.mainAsync { [weak self] in
            self?.initialState?.didEnterBlock?(nil)
        }
        lock.unlock()
    }

    /// 事件是否可触发
    /// - Parameter name: 事件名称或对象
    /// - Returns: 是否可触发
    public func canFireEvent(_ name: Any?) -> Bool {
        var event = name as? Event
        if let name = name as? String {
            event = eventNamed(name)
        }
        guard let event, let state else { return false }
        return event.sourceStates.contains { $0 === state }
    }

    /// 触发事件，未激活时自动激活
    /// - Parameter name: 事件名称或对象
    /// - Parameter object: 附加参数，默认nil
    /// - Returns: 触发状态
    @discardableResult
    @MainActor public func fireEvent(_ name: Any?, object: Any? = nil) -> Bool {
        lock.lock()
        if !isActive {
            activate()
        }
        var event = name as? Event
        if let name = name as? String {
            event = eventNamed(name)
        }
        guard let event, let state,
              event.sourceStates.contains(where: { $0 === state }) else {
            lock.unlock()
            return false
        }

        let transition = Transition(in: self, for: event, from: state, object: object)
        if let shouldFireBlock = event.shouldFireBlock,
           !shouldFireBlock(transition) {
            lock.unlock()
            return false
        }

        fireBegin(transition)
        lock.unlock()
        return true
    }

    @MainActor private func fireBegin(_ transition: Transition) {
        transition.event.willFireBlock?(transition)

        if let fireBlock = transition.event.fireBlock {
            fireBlock(transition) { finished in
                DispatchQueue.fw.mainAsync {
                    transition.machine.fireEnd(transition, finished: finished)
                }
            }
        } else {
            fireEnd(transition, finished: true)
        }
    }

    @MainActor private func fireEnd(_ transition: Transition, finished: Bool) {
        lock.lock()
        if finished {
            let oldState = state
            let newState = transition.event.targetState
            oldState?.willExitBlock?(transition)
            newState.willEnterBlock?(transition)
            state = newState

            var userInfo: [AnyHashable: Any] = [:]
            if let oldState {
                userInfo[NSKeyValueChangeKey.oldKey] = oldState
            }
            userInfo[NSKeyValueChangeKey.newKey] = newState
            NotificationCenter.default.post(name: .StateChanged, object: self, userInfo: userInfo)

            oldState?.didExitBlock?(transition)
            newState.didEnterBlock?(transition)
        }

        transition.event.didFireBlock?(transition, finished)
        lock.unlock()
    }
}

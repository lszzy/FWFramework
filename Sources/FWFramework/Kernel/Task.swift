//
//  Task.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation

/// 任务操作类，可继承或直接使用
open class TaskOperation: Operation {
    
    private enum TaskState: Int {
        case created = 0
        case ready
        case loading
        case success
        case failure
        case cancelled
    }
    
    /// 任务句柄，执行完成需调用task.finish(error:)
    open var taskBlock: ((TaskOperation) -> Void)?
    
    /// 是否在主线程执行，会阻碍UI渲染，默认false
    open var onMainThread = false
    
    /// 任务错误信息
    open private(set) var error: Error?
    
    public override init() {
        super.init()
        self.state = .ready
    }
    
    public convenience init(onMainThread: Bool = false, queuePriority: Operation.QueuePriority = .normal, taskBlock: ((TaskOperation) -> Void)?) {
        self.init()
        self.onMainThread = onMainThread
        self.queuePriority = queuePriority
        self.taskBlock = taskBlock
    }

    /// 子类可重写，默认调用taskBlock，任务完成需调用finish(error:)
    @objc open func executeTask() {
        taskBlock?(self)
    }
    
    /// 是否主线程执行，子类可重写，会阻碍UI渲染，默认返回onMainThread
    open func needMainThread() -> Bool {
        return onMainThread
    }

    /// 标记任务完成，error为空表示任务成功
    open func finish(error: Error? = nil) {
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }
        
        if error != nil {
            self.error = error
            state = .failure
            
            #if DEBUG
            Logger.debug(group: Logger.fw_moduleName, "\n********** TASK %@ FAILED", NSStringFromClass(self.classForCoder))
            #endif
        } else {
            state = .success
            
            #if DEBUG
            Logger.debug(group: Logger.fw_moduleName, "\n********** TASK %@ FINISHED", NSStringFromClass(self.classForCoder))
            #endif
        }
        lock.unlock()
    }
    
    open override func start() {
        lock.lock()
        guard isReady else {
            lock.unlock()
            return
        }
        
        state = .loading
        lock.unlock()
        
        #if DEBUG
        Logger.debug(group: Logger.fw_moduleName, "\n********** TASK %@ STARTED", NSStringFromClass(self.classForCoder))
        #endif
        
        if needMainThread() {
            if Thread.isMainThread {
                executeTask()
            } else {
                performSelector(onMainThread: #selector(executeTask), with: nil, waitUntilDone: false)
            }
        } else {
            executeTask()
        }
    }
    
    open override func cancel() {
        lock.lock()
        
        if !isFinished {
            state = .cancelled
            super.cancel()
            
            #if DEBUG
            Logger.debug(group: Logger.fw_moduleName, "\n********** TASK %@ CANCELLED", NSStringFromClass(self.classForCoder))
            #endif
        }
        
        lock.unlock()
    }
    
    open override var isAsynchronous: Bool {
        return true
    }
    
    open override var isReady: Bool {
        return state == .ready && super.isReady
    }
    
    open override var isFinished: Bool {
        return state == .success || state == .failure || state == .cancelled
    }
    
    open override var isExecuting: Bool {
        return state == .loading
    }
    
    private var state: TaskState {
        get {
            return _state
        }
        set {
            lock.lock()
            if !isValidTransition(from: _state, to: newValue) {
                lock.unlock()
                return
            }
            
            switch newValue {
            case .cancelled:
                willChangeValue(forKey: "isExecuting")
                willChangeValue(forKey: "isFinished")
                willChangeValue(forKey: "isCancelled")
                _state = newValue
                didChangeValue(forKey: "isExecuting")
                didChangeValue(forKey: "isFinished")
                didChangeValue(forKey: "isCancelled")
            case .loading:
                willChangeValue(forKey: "isExecuting")
                _state = newValue
                didChangeValue(forKey: "isExecuting")
            case .success, .failure:
                willChangeValue(forKey: "isFinished")
                willChangeValue(forKey: "isExecuting")
                _state = newValue
                didChangeValue(forKey: "isFinished")
                didChangeValue(forKey: "isExecuting")
            case .ready:
                willChangeValue(forKey: "isReady")
                _state = newValue
                didChangeValue(forKey: "isReady")
            default:
                _state = newValue
                break
            }
            lock.unlock()
        }
    }
    
    private var _state: TaskState = .created
    
    private var lock = NSRecursiveLock()
    
    private func isValidTransition(from fromState: TaskState, to toState: TaskState) -> Bool {
        switch fromState {
        case .ready:
            switch toState {
            case .loading:
                return true
            case .success:
                return true
            case .failure:
                return true
            case .cancelled:
                return true
            default:
                return false
            }
        case .loading:
            switch toState {
            case .success:
                return true
            case .failure:
                return true
            case .cancelled:
                return true
            default:
                return false
            }
        case .created:
            if toState == .ready {
                return true
            } else {
                return false
            }
        default:
            return false
        }
    }
    
}

/// 任务管理器，兼容NSBlockOperation和NSInvocationOperation
open class TaskManager: NSObject {
    
    /// 单例模式
    public static let shared = TaskManager()
    
    /// 并发操作的最大任务数
    open var maxConcurrentTaskCount: Int {
        get { taskQueue.maxConcurrentOperationCount }
        set { taskQueue.maxConcurrentOperationCount = newValue }
    }

    /// 是否暂停，可恢复
    open var isSuspended: Bool {
        get { taskQueue.isSuspended }
        set { taskQueue.isSuspended = newValue }
    }
    
    private lazy var taskQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "FWTaskManager.taskQueue"
        return queue
    }()
    
    public convenience init(maxConcurrentTaskCount: Int, isSuspended: Bool = false) {
        self.init()
        self.maxConcurrentTaskCount = maxConcurrentTaskCount
        if isSuspended { self.isSuspended = isSuspended }
    }
    
    /// 添加单个任务
    open func addTask(_ task: Operation) {
        taskQueue.addOperation(task)
    }
    
    /// 批量添加任务
    open func addTasks(_ tasks: [Operation]) {
        guard !tasks.isEmpty else { return }
        taskQueue.addOperations(tasks, waitUntilFinished: false)
    }
    
    /// 从配置数组按顺序添加任务，支持className|dependency
    open func addTaskConfig(_ config: [[String: String]]) {
        var tasks: [Operation] = []
        var taskMap: [String: Operation] = [:]
        
        for taskInfo in config {
            // className
            if let className = taskInfo["className"],
               let operationClass = NSClassFromString(className) as? Operation.Type {
                let task = operationClass.init()
                tasks.append(task)
                taskMap[className] = task
                
                // dependency
                if let dependencyList = taskInfo["dependency"]?.components(separatedBy: ","),
                   !dependencyList.isEmpty {
                    for dependencyClass in dependencyList {
                        if let preTask = taskMap[dependencyClass] {
                            task.addDependency(preTask)
                        }
                    }
                }
            }
        }
        
        addTasks(tasks)
    }
    
    /// 取消所有任务
    open func cancelAllTasks() {
        taskQueue.cancelAllOperations()
    }
    
    /// 等待所有任务执行完成，会阻塞线程
    open func waitUntilFinished() {
        taskQueue.waitUntilAllOperationsAreFinished()
    }
    
}

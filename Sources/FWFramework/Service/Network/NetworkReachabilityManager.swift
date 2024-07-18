//
//  NetworkReachabilityManager.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation
import SystemConfiguration

/// 网络可达性管理器
///
/// [Alamofire](https://github.com/Alamofire/Alamofire)
open class NetworkReachabilityManager: @unchecked Sendable {
    
    /// 网络可达性状态枚举
    public enum NetworkReachabilityStatus: Equatable, Sendable {
        /// 未知状态
        case unknown
        /// 不可达
        case notReachable
        /// 可达
        case reachable(ConnectionType)

        init(_ flags: SCNetworkReachabilityFlags) {
            guard flags.isActuallyReachable else { self = .notReachable; return }

            var networkStatus: NetworkReachabilityStatus = .reachable(.ethernetOrWiFi)

            if flags.isCellular { networkStatus = .reachable(.cellular) }

            self = networkStatus
        }

        /// 网络连接类型枚举
        public enum ConnectionType: Sendable {
            /// 以太网或WiFi
            case ethernetOrWiFi
            /// 蜂窝网络
            case cellular
        }
    }

    /// 网络可达性监听句柄
    public typealias Listener = @Sendable (NetworkReachabilityStatus) -> Void

    /// 默认网络可达性管理器
    public static let shared = NetworkReachabilityManager()

    // MARK: - Accessor
    /// 当前是否可访问网络
    open var isReachable: Bool { isReachableOnCellular || isReachableOnEthernetOrWiFi }

    /// 当前是否通过蜂窝网络访问
    open var isReachableOnCellular: Bool { status == .reachable(.cellular) }

    /// 当前是否通过以太网或WiFi网络访问
    open var isReachableOnEthernetOrWiFi: Bool { status == .reachable(.ethernetOrWiFi) }

    /// 可达性更新时回调队列
    public let reachabilityQueue = DispatchQueue(label: "site.wuyong.queue.reachabilityQueue")

    /// 当前可访问类型标记
    open var flags: SCNetworkReachabilityFlags? {
        guard let reachability = reachability else { return nil }
        
        var flags = SCNetworkReachabilityFlags()
        return SCNetworkReachabilityGetFlags(reachability, &flags) ? flags : nil
    }

    /// 当前网络可达性状态
    open var status: NetworkReachabilityStatus {
        flags.map(NetworkReachabilityStatus.init) ?? .unknown
    }

    struct MutableState {
        var listener: Listener?
        var listenerQueue: DispatchQueue?
        var previousStatus: NetworkReachabilityStatus?
    }

    private let reachability: SCNetworkReachability?

    private var mutableState = MutableState()
    
    private let stateLock = NSLock()

    // MARK: - Lifecycle
    /// 指定host初始化
    public convenience init(host: String) {
        let reachability = SCNetworkReachabilityCreateWithName(nil, host)
        self.init(reachability: reachability)
    }

    /// 使用默认地址0.0.0.0初始化
    public convenience init() {
        var zero = sockaddr()
        zero.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zero.sa_family = sa_family_t(AF_INET)

        let reachability = SCNetworkReachabilityCreateWithAddress(nil, &zero)
        self.init(reachability: reachability)
    }

    private init(reachability: SCNetworkReachability?) {
        self.reachability = reachability
    }

    deinit {
        stopListening()
    }

    // MARK: - Public
    /// 是否正在监听中
    open var isListening: Bool {
        var listening = false
        stateLock.lock()
        listening = mutableState.listener != nil
        stateLock.unlock()
        return listening
    }
    
    /// 开始监听网络状态，自动停止之前已有的监听
    ///
    /// - Parameters:
    ///   - queue:    监听句柄回调队列，默认main
    ///   - listener: 监听句柄
    ///
    /// - Returns: `true` if listening was started successfully, `false` otherwise.
    @discardableResult
    open func startListening(onQueue queue: DispatchQueue = .main,
                             onUpdatePerforming listener: @escaping Listener) -> Bool {
        stopListening()

        stateLock.lock()
        mutableState.listenerQueue = queue
        mutableState.listener = listener
        stateLock.unlock()

        let weakManager = WeakManager(manager: self)

        var context = SCNetworkReachabilityContext(
            version: 0,
            info: Unmanaged.passUnretained(weakManager).toOpaque(),
            retain: { info in
                let unmanaged = Unmanaged<WeakManager>.fromOpaque(info)
                _ = unmanaged.retain()

                return UnsafeRawPointer(unmanaged.toOpaque())
            },
            release: { info in
                let unmanaged = Unmanaged<WeakManager>.fromOpaque(info)
                unmanaged.release()
            },
            copyDescription: { info in
                let unmanaged = Unmanaged<WeakManager>.fromOpaque(info)
                let weakManager = unmanaged.takeUnretainedValue()
                let description = weakManager.manager?.flags?.readableDescription ?? "nil"

                return Unmanaged.passRetained(description as CFString)
            }
        )
        let callback: SCNetworkReachabilityCallBack = { _, flags, info in
            guard let info = info else { return }

            let weakManager = Unmanaged<WeakManager>.fromOpaque(info).takeUnretainedValue()
            weakManager.manager?.notifyListener(flags)
        }

        var queueAdded = false
        var callbackAdded = false
        if let reachability = reachability {
            queueAdded = SCNetworkReachabilitySetDispatchQueue(reachability, reachabilityQueue)
            callbackAdded = SCNetworkReachabilitySetCallback(reachability, callback, &context)
        }

        if let currentFlags = flags {
            reachabilityQueue.async {
                self.notifyListener(currentFlags)
            }
        }

        return callbackAdded && queueAdded
    }

    /// 停止监听
    open func stopListening() {
        if let reachability = reachability {
            SCNetworkReachabilitySetCallback(reachability, nil, nil)
            SCNetworkReachabilitySetDispatchQueue(reachability, nil)
        }
        
        stateLock.lock()
        mutableState.listener = nil
        mutableState.listenerQueue = nil
        mutableState.previousStatus = nil
        stateLock.unlock()
    }

    // MARK: - Private
    func notifyListener(_ flags: SCNetworkReachabilityFlags) {
        let newStatus = NetworkReachabilityStatus(flags)

        stateLock.lock()
        if newStatus != mutableState.previousStatus {
            mutableState.previousStatus = newStatus
            
            let listener = mutableState.listener
            mutableState.listenerQueue?.async { listener?(newStatus) }
        }
        stateLock.unlock()
    }

    private final class WeakManager {
        weak var manager: NetworkReachabilityManager?

        init(manager: NetworkReachabilityManager?) {
            self.manager = manager
        }
    }
}

extension SCNetworkReachabilityFlags {
    var isReachable: Bool { contains(.reachable) }
    var isConnectionRequired: Bool { contains(.connectionRequired) }
    var canConnectAutomatically: Bool { contains(.connectionOnDemand) || contains(.connectionOnTraffic) }
    var canConnectWithoutUserInteraction: Bool { canConnectAutomatically && !contains(.interventionRequired) }
    var isActuallyReachable: Bool { isReachable && (!isConnectionRequired || canConnectWithoutUserInteraction) }
    var isCellular: Bool { contains(.isWWAN) }
    
    var readableDescription: String {
        let W = isCellular ? "W" : "-"
        let R = isReachable ? "R" : "-"
        let c = isConnectionRequired ? "c" : "-"
        let t = contains(.transientConnection) ? "t" : "-"
        let i = contains(.interventionRequired) ? "i" : "-"
        let C = contains(.connectionOnTraffic) ? "C" : "-"
        let D = contains(.connectionOnDemand) ? "D" : "-"
        let l = contains(.isLocalAddress) ? "l" : "-"
        let d = contains(.isDirect) ? "d" : "-"
        let a = contains(.connectionAutomatic) ? "a" : "-"

        return "\(W)\(R) \(c)\(t)\(i)\(C)\(D)\(l)\(d)\(a)"
    }
}

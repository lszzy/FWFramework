//
//  CloudStorage.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import Combine
import SwiftUI
import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - CloudStorage
/// [CloudStorage](https://github.com/nonstrict-hq/CloudStorage)
@propertyWrapper
@MainActor
public struct CloudStorage<Value>: DynamicProperty {
    @ObservedObject private var object: CloudStorageObject<Value>

    public var wrappedValue: Value {
        get { object.value }
        nonmutating set { object.value = newValue }
    }

    public var projectedValue: Binding<Value> {
        $object.value
    }

    public init(keyName key: String, syncGet: @escaping () -> Value, syncSet: @escaping (Value) -> Void) {
        self.object = CloudStorageObject(key: key, syncGet: syncGet, syncSet: syncSet)
    }

    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance instance: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> Value {
        get {
            instance[keyPath: storageKeyPath].object.keyObserver.enclosingObjectWillChange = instance.objectWillChange as? ObservableObjectPublisher
            return instance[keyPath: storageKeyPath].wrappedValue
        }
        set {
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}

@MainActor private let sync = CloudStorageSync.shared

@MainActor
class KeyObserver {
    weak var storageObjectWillChange: ObservableObjectPublisher?
    weak var enclosingObjectWillChange: ObservableObjectPublisher?

    func keyChanged() {
        storageObjectWillChange?.send()
        enclosingObjectWillChange?.send()
    }
}

@MainActor
class CloudStorageObject<Value>: ObservableObject {
    private let key: String
    private let syncGet: () -> Value
    private let syncSet: (Value) -> Void

    let keyObserver = KeyObserver()

    var value: Value {
        get { syncGet() }
        set {
            syncSet(newValue)
            sync.notifyObservers(for: key)
            sync.synchronize()
        }
    }

    init(key: String, syncGet: @escaping () -> Value, syncSet: @escaping (Value) -> Void) {
        self.key = key
        self.syncGet = syncGet
        self.syncSet = syncSet

        keyObserver.storageObjectWillChange = objectWillChange
        sync.addObserver(keyObserver, key: key)
    }

    deinit {
        Task { @MainActor [keyObserver] in
            sync.removeObserver(keyObserver)
        }
    }
}

extension CloudStorage: Sendable where Value: Sendable {}

extension CloudStorage where Value == Bool {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.bool(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value == Int {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.int(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value == Double {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.double(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value == String {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.string(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value == URL {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.url(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value == Date {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.date(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value == Data {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.data(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value: RawRepresentable, Value.RawValue == Int {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.int(for: key).flatMap(Value.init) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue.rawValue, for: key) }
        )
    }
}

extension CloudStorage where Value: RawRepresentable, Value.RawValue == String {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.string(for: key).flatMap(Value.init) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue.rawValue, for: key) }
        )
    }
}

extension CloudStorage where Value == Bool? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.bool(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value == Int? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.int(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value == Double? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.double(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value == String? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.string(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value == URL? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.url(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value == Date? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.date(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value == Data? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.data(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage where Value: AnyArchivable {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { Value.archiveDecode(sync.data(for: key)) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue.archiveEncode(), for: key) }
        )
    }
}

extension CloudStorage {
    public init<R>(_ key: String) where Value == R?, R: RawRepresentable, R.RawValue == String {
        self.init(
            keyName: key,
            syncGet: { sync.rawRepresentable(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

extension CloudStorage {
    public init<R>(_ key: String) where Value == R?, R: RawRepresentable, R.RawValue == Int {
        self.init(
            keyName: key,
            syncGet: { sync.rawRepresentable(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) }
        )
    }
}

// MARK: - CloudStorageSync
@MainActor
public final class CloudStorageSync: ObservableObject {
    public static let shared = CloudStorageSync()

    private let ubiquitousKvs: NSUbiquitousKeyValueStore
    private var observers: [String: [KeyObserver]] = [:]

    @Published public private(set) var status: Status

    private init() {
        self.ubiquitousKvs = NSUbiquitousKeyValueStore.default
        self.status = Status(date: Date(), source: .initial, keys: [])

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let sendableNotification = SendableValue(notification)
            MainActor.assumeIsolated {
                self.didChangeExternally(notification: sendableNotification.value)
            }
        }
        ubiquitousKvs.synchronize()

        NotificationCenter.default.addObserver(
            ubiquitousKvs,
            selector: #selector(NSUbiquitousKeyValueStore.synchronize),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    private func didChangeExternally(notification: Notification) {
        let reasonRaw = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int ?? -1
        let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] ?? []
        let reason = ChangeReason(rawValue: reasonRaw)

        DispatchQueue.main.async {
            self.status = Status(date: Date(), source: .externalChange(reason), keys: keys)

            for key in keys {
                for observer in self.observers[key, default: []] {
                    observer.keyChanged()
                }
            }
        }
    }

    func notifyObservers(for key: String) {
        DispatchQueue.main.async {
            for observer in self.observers[key, default: []] {
                observer.keyChanged()
            }
        }
    }

    func addObserver(_ observer: KeyObserver, key: String) {
        DispatchQueue.main.async {
            self.observers[key, default: []].append(observer)
        }
    }

    func removeObserver(_ observer: KeyObserver) {
        DispatchQueue.main.async {
            self.observers = self.observers.mapValues { $0.filter { $0 !== observer } }
        }
    }

    func synchronize() {
        ubiquitousKvs.synchronize()
    }
}

// Wrap calls to NSUbiquitousKeyValueStore
extension CloudStorageSync {
    public func object(forKey key: String) -> Any? {
        ubiquitousKvs.object(forKey: key)
    }

    public func set(_ object: Any?, for key: String) {
        ubiquitousKvs.set(object, forKey: key)
    }

    public func remove(for key: String) {
        ubiquitousKvs.removeObject(forKey: key)
    }

    public func string(for key: String) -> String? {
        ubiquitousKvs.string(forKey: key)
    }

    public func url(for key: String) -> URL? {
        ubiquitousKvs.string(forKey: key).flatMap(URL.init(string:))
    }

    public func array(for key: String) -> [Any]? {
        ubiquitousKvs.array(forKey: key)
    }

    public func dictionary(for key: String) -> [String: Any]? {
        ubiquitousKvs.dictionary(forKey: key)
    }

    public func date(for key: String) -> Date? {
        guard let obj = ubiquitousKvs.object(forKey: key) else { return nil }
        return obj as? Date
    }

    public func data(for key: String) -> Data? {
        ubiquitousKvs.data(forKey: key)
    }

    public func int(for key: String) -> Int? {
        if ubiquitousKvs.object(forKey: key) == nil { return nil }
        return Int(ubiquitousKvs.longLong(forKey: key))
    }

    public func int64(for key: String) -> Int64? {
        if ubiquitousKvs.object(forKey: key) == nil { return nil }
        return ubiquitousKvs.longLong(forKey: key)
    }

    public func double(for key: String) -> Double? {
        if ubiquitousKvs.object(forKey: key) == nil { return nil }
        return ubiquitousKvs.double(forKey: key)
    }

    public func bool(for key: String) -> Bool? {
        if ubiquitousKvs.object(forKey: key) == nil { return nil }
        return ubiquitousKvs.bool(forKey: key)
    }

    public func rawRepresentable<R>(for key: String) -> R? where R: RawRepresentable, R.RawValue == String {
        guard let str = ubiquitousKvs.string(forKey: key) else { return nil }
        return R(rawValue: str)
    }

    public func rawRepresentable<R>(for key: String) -> R? where R: RawRepresentable, R.RawValue == Int {
        if ubiquitousKvs.object(forKey: key) == nil { return nil }
        let int = Int(ubiquitousKvs.longLong(forKey: key))
        return R(rawValue: int)
    }

    public func set(_ value: String?, for key: String) {
        ubiquitousKvs.set(value, forKey: key)
        status = Status(date: Date(), source: .localChange, keys: [key])
    }

    public func set(_ value: URL?, for key: String) {
        ubiquitousKvs.set(value?.absoluteString, forKey: key)
        status = Status(date: Date(), source: .localChange, keys: [key])
    }

    public func set(_ value: Data?, for key: String) {
        ubiquitousKvs.set(value, forKey: key)
        status = Status(date: Date(), source: .localChange, keys: [key])
    }

    public func set(_ value: [Any]?, for key: String) {
        ubiquitousKvs.set(value, forKey: key)
        status = Status(date: Date(), source: .localChange, keys: [key])
    }

    public func set(_ value: [String: Any]?, for key: String) {
        ubiquitousKvs.set(value, forKey: key)
        status = Status(date: Date(), source: .localChange, keys: [key])
    }

    public func set(_ value: Int?, for key: String) {
        ubiquitousKvs.set(value, forKey: key)
        status = Status(date: Date(), source: .localChange, keys: [key])
    }

    public func set(_ value: Int64?, for key: String) {
        ubiquitousKvs.set(value, forKey: key)
        status = Status(date: Date(), source: .localChange, keys: [key])
    }

    public func set(_ value: Double?, for key: String) {
        ubiquitousKvs.set(value, forKey: key)
        status = Status(date: Date(), source: .localChange, keys: [key])
    }

    public func set(_ value: Bool?, for key: String) {
        ubiquitousKvs.set(value, forKey: key)
        status = Status(date: Date(), source: .localChange, keys: [key])
    }

    public func set<R>(_ value: R?, for key: String) where R: RawRepresentable, R.RawValue == String {
        ubiquitousKvs.set(value?.rawValue, forKey: key)
        status = Status(date: Date(), source: .localChange, keys: [key])
    }

    public func set<R>(_ value: R?, for key: String) where R: RawRepresentable, R.RawValue == Int {
        ubiquitousKvs.set(value?.rawValue, forKey: key)
        status = Status(date: Date(), source: .localChange, keys: [key])
    }
}

extension CloudStorageSync {
    public enum ChangeReason {
        case serverChange
        case initialSyncChange
        case quotaViolationChange
        case accountChange

        init?(rawValue: Int) {
            switch rawValue {
            case NSUbiquitousKeyValueStoreServerChange:
                self = .serverChange
            case NSUbiquitousKeyValueStoreInitialSyncChange:
                self = .initialSyncChange
            case NSUbiquitousKeyValueStoreQuotaViolationChange:
                self = .quotaViolationChange
            case NSUbiquitousKeyValueStoreAccountChange:
                self = .accountChange
            default:
                assertionFailure("Unknown NSUbiquitousKeyValueStoreChangeReason \(rawValue)")
                return nil
            }
        }
    }

    public struct Status: CustomStringConvertible {
        public enum Source {
            case initial
            case localChange
            case externalChange(ChangeReason?)
        }

        public var date: Date
        public var source: Source
        public var keys: [String]

        public var description: String {
            let timeString = statusDateFormatter.string(from: date)
            let keysString = keys.joined(separator: ", ")

            switch source {
            case .initial:
                return "[\(timeString)] Initial"

            case .localChange:
                return "[\(timeString)] Local change: \(keysString)"

            case let .externalChange(reason?):
                return "[\(timeString)] External change (\(reason)): \(keysString)"

            case .externalChange(nil):
                return "[\(timeString)] External change (unknown): \(keysString)"
            }
        }
    }
}

private let statusDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    return formatter
}()

//
//  CloudDrive.swift
//  FWFramework
//
//  Created by wuyong on 2025/8/30.
//

import Foundation
import os
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - CloudDrive
public protocol CloudDriveObserver {
    func cloudDriveDidChange(_ cloudDrive: CloudDrive, rootRelativePaths: [RootRelativePath])
}

public protocol CloudDriveConflictResolver {
    func cloudDrive(_ cloudDrive: CloudDrive, resolveConflictAt path: RootRelativePath)
}

/// [SwiftCloudDrive](https://github.com/drewmccormack/SwiftCloudDrive)
public final class CloudDrive: @unchecked Sendable {
    /// Types of storage available
    public enum Storage {
        case iCloudContainer(containerIdentifier: String?)
        case localDirectory(rootURL: URL)
    }

    /// The type of storage used (eg iCloud, local)
    public let storage: Storage

    /// Pass in nil to get the default container. Eg. "iCloud.my.company.app"
    public var ubiquityContainerIdentifier: String? {
        if case let .iCloudContainer(id) = storage {
            return id
        } else {
            return nil
        }
    }

    /// The path of the directory for this drive, relative to the root of the iCloud container
    @available(*, deprecated, renamed: "relativePathToRoot")
    public var relativePathToRootInContainer: String {
        relativePathToRoot
    }

    /// The path of the directory for this drive, relative to the root of the drive
    public let relativePathToRoot: String

    /// Set this to receive notification of changes in the cloud drive.
    public var observer: CloudDriveObserver?

    /// Optional conflict resolution. If not set, the most recent version wins, and others are deleted.
    public var conflictResolver: CloudDriveConflictResolver?

    /// If the user is signed in to iCloud, this should be true. Otherwise false. When iCloud is not used, it is always true
    public var isConnected: Bool {
        switch storage {
        case .iCloudContainer:
            return FileManager.default.ubiquityIdentityToken != nil
        case .localDirectory:
            return true
        }
    }

    private let metadataMonitor: MetadataMonitor?
    private let fileMonitor: FileMonitor
    public let rootDirectory: URL

    // MARK: - Init
    /// Pass in the type of storage (eg iCloud container), and an optional path relative to the root directory where the drive will be anchored.
    public init(storage: Storage, relativePathToRoot: String = "") async throws {
        self.storage = storage
        self.relativePathToRoot = relativePathToRoot

        let fileManager = FileManager.default
        switch storage {
        case let .iCloudContainer(containerIdentifier):
            guard fileManager.ubiquityIdentityToken != nil else { throw CloudDriveError.notSignedIntoCloud }
            guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: containerIdentifier) else {
                throw CloudDriveError.couldNotAccessUbiquityContainer
            }
            let url = relativePathToRoot.isEmpty ? containerURL : containerURL.appendingPathComponent(relativePathToRoot, isDirectory: true)
            self.rootDirectory = url.standardizedFileURL
            self.metadataMonitor = MetadataMonitor(rootDirectory: rootDirectory)
        case let .localDirectory(rootURL):
            let url = relativePathToRoot.isEmpty ? rootURL : URL(fileURLWithPath: relativePathToRoot, isDirectory: true, relativeTo: rootURL)
            self.rootDirectory = url.standardizedFileURL
            try fileManager.createDirectory(atPath: rootDirectory.path, withIntermediateDirectories: true)
            self.metadataMonitor = nil
        }

        // Use the FileMonitor even for non-ubiquitious files
        let monitor = FileMonitor(rootDirectory: rootDirectory)
        self.fileMonitor = monitor
        monitor.changeHandler = { [weak self] changedPaths in
            guard let self, let observer else { return }
            observer.cloudDriveDidChange(self, rootRelativePaths: changedPaths)
        }
        monitor.conflictHandler = { [weak self] rootRelativePath in
            guard let self, let resolver = conflictResolver else { return false }
            resolver.cloudDrive(self, resolveConflictAt: rootRelativePath)
            return true
        }

        try await performInitialSetup()
    }

    /// Pass in the container id, but also an optional root direcotry. All relative paths will then be relative to this root.
    public convenience init(ubiquityContainerIdentifier: String? = nil, relativePathToRootInContainer: String = "") async throws {
        try await self.init(storage: .iCloudContainer(containerIdentifier: ubiquityContainerIdentifier), relativePathToRoot: relativePathToRootInContainer)
    }

    // MARK: Setup

    private func performInitialSetup() async throws {
        try await setupRootDirectory()
        metadataMonitor?.startMonitoringMetadata()
        fileMonitor.startMonitoring()
    }

    private func setupRootDirectory() async throws {
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let (exists, isDirectory) = try await coordinatedFileManager.fileExists(coordinatingAccessAt: rootDirectory)
        if exists {
            guard isDirectory else { throw CloudDriveError.rootDirectoryURLIsNotDirectory }
        } else {
            try await coordinatedFileManager.createDirectory(coordinatingAccessAt: rootDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - File Operations
    /// Returns whether the file exists. If it is a directory, returns false
    public func fileExists(at path: RootRelativePath) async throws -> Bool {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let fileURL = try path.fileURL(forRoot: rootDirectory)
        let result = try await coordinatedFileManager.fileExists(coordinatingAccessAt: fileURL)
        return result.exists && !result.isDirectory
    }

    /// Returns whether the directory exists
    public func directoryExists(at path: RootRelativePath) async throws -> Bool {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let dirURL = try path.directoryURL(forRoot: rootDirectory)
        let result = try await coordinatedFileManager.fileExists(coordinatingAccessAt: dirURL)
        return result.exists && result.isDirectory
    }

    /// Creates a directory in the cloud. Always creates intermediate directories if needed.
    public func createDirectory(at path: RootRelativePath) async throws {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let dirURL = try path.directoryURL(forRoot: rootDirectory)
        return try await coordinatedFileManager.createDirectory(coordinatingAccessAt: dirURL, withIntermediateDirectories: true)
    }

    /// Returns the contents of a directory. It doesn't recurse into subdirectories
    public func contentsOfDirectory(at path: RootRelativePath, includingPropertiesForKeys keys: [URLResourceKey]? = nil, options mask: FileManager.DirectoryEnumerationOptions = []) async throws -> [URL] {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let dirURL = try path.directoryURL(forRoot: rootDirectory)
        return try await coordinatedFileManager.contentsOfDirectory(coordinatingAccessAt: dirURL, includingPropertiesForKeys: keys, options: mask)
    }

    /// Removes a directory at the path passed
    public func removeDirectory(at path: RootRelativePath) async throws {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let dirURL = try path.directoryURL(forRoot: rootDirectory)
        let result = try await coordinatedFileManager.fileExists(coordinatingAccessAt: dirURL)
        guard result.exists, result.isDirectory else { throw CloudDriveError.invalidFileType }
        return try await coordinatedFileManager.removeItem(coordinatingAccessAt: dirURL)
    }

    /// Removes a file at the path passed. If there is no file, or there is a directory, it gives an error
    public func removeFile(at path: RootRelativePath) async throws {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let fileURL = try path.fileURL(forRoot: rootDirectory)
        let result = try await coordinatedFileManager.fileExists(coordinatingAccessAt: fileURL)
        guard result.exists, !result.isDirectory else { throw CloudDriveError.invalidFileType }
        return try await coordinatedFileManager.removeItem(coordinatingAccessAt: fileURL)
    }

    /// Copies a file from outside the container, into the container. If there is a file already at the destination it will give an error and fail.
    public func upload(from fromURL: URL, to path: RootRelativePath) async throws {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let toURL = try path.fileURL(forRoot: rootDirectory)
        try await coordinatedFileManager.copyItem(coordinatingAccessFrom: fromURL, to: toURL)
    }

    /// Attempts to copy a file inside the container out to a file URL not in the cloud.
    public func download(from path: RootRelativePath, toURL: URL) async throws {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let fromURL = try path.fileURL(forRoot: rootDirectory)
        try await coordinatedFileManager.copyItem(coordinatingAccessFrom: fromURL, to: toURL)
    }

    /// Copies within the container.
    public func copy(from source: RootRelativePath, to destination: RootRelativePath) async throws {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let sourceURL = try source.fileURL(forRoot: rootDirectory)
        let destinationURL = try destination.fileURL(forRoot: rootDirectory)
        try await coordinatedFileManager.copyItem(coordinatingAccessFrom: sourceURL, to: destinationURL)
    }

    /// Reads the contents of a file in the cloud, returning it as data.
    public func readFile(at path: RootRelativePath) async throws -> Data {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let fileURL = try path.fileURL(forRoot: rootDirectory)
        return try await coordinatedFileManager.contentsOfFile(coordinatingAccessAt: fileURL)
    }

    /// Writes the contents of a file. If the file doesn't exist, it will be created. If it already exists, it will be overwritten.
    public func writeFile(with data: Data, at path: RootRelativePath) async throws {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let fileURL = try path.fileURL(forRoot: rootDirectory)
        return try await coordinatedFileManager.write(data, coordinatingAccessTo: fileURL)
    }

    /// Make any change to the file contents desired for the path given. Can be used for in-place updates.
    public func updateFile(at path: RootRelativePath, in block: @Sendable @escaping (URL) throws -> Void) async throws {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let fileURL = try path.fileURL(forRoot: rootDirectory)
        try await coordinatedFileManager.updateFile(coordinatingAccessTo: fileURL) { url in
            try block(url)
        }
    }

    /// As updateFile, but coordinated for reading.
    public func readFile(at path: RootRelativePath, in block: @Sendable @escaping (URL) throws -> Void) async throws {
        guard isConnected else { throw CloudDriveError.queriedWhileNotConnected }
        let coordinatedFileManager = CoordinatedFileManager(presenter: fileMonitor)
        let fileURL = try path.fileURL(forRoot: rootDirectory)
        try await coordinatedFileManager.readFile(coordinatingAccessTo: fileURL) { url in
            try block(url)
        }
    }
}

// MARK: - CoordinatedFileManager
public actor CoordinatedFileManager {
    private(set) var presenter: (any NSFilePresenter)?

    private let fileManager = FileManager()

    public init(presenter: (any NSFilePresenter)? = nil) {
        self.presenter = presenter
    }

    public func fileExists(coordinatingAccessAt fileURL: URL) throws -> (exists: Bool, isDirectory: Bool) {
        let (exists, isDirectory) = try coordinate(readingItemAt: fileURL) { url in
            var isDir: ObjCBool = false
            let exists = self.fileManager.fileExists(atPath: url.path, isDirectory: &isDir)
            return (exists, isDir.boolValue)
        }
        return (exists, isDirectory)
    }

    public func createDirectory(coordinatingAccessAt dirURL: URL, withIntermediateDirectories: Bool) throws {
        try coordinate(writingItemAt: dirURL, options: .forMerging) { [self] url in
            try fileManager.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
        }
    }

    public func removeItem(coordinatingAccessAt dirURL: URL) throws {
        try coordinate(writingItemAt: dirURL, options: .forDeleting) { [self] url in
            try fileManager.removeItem(at: url)
        }
    }

    public func copyItem(coordinatingAccessFrom fromURL: URL, to toURL: URL) throws {
        try coordinate(readingItemAt: fromURL, readOptions: [], writingItemAt: toURL, writeOptions: .forReplacing) { readURL, writeURL in
            try self.fileManager.copyItem(at: readURL, to: writeURL)
        }
    }

    public func contentsOfDirectory(coordinatingAccessAt dirURL: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        try coordinate(readingItemAt: dirURL) { [self] url in
            try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: mask)
        }
    }

    public func contentsOfFile(coordinatingAccessAt url: URL) throws -> Data {
        var data: Data = .init()
        try coordinate(readingItemAt: url) { url in
            data = try Data(contentsOf: url)
        }
        return data
    }

    public func write(_ data: Data, coordinatingAccessTo url: URL) throws {
        try coordinate(writingItemAt: url) { url in
            try data.write(to: url)
        }
    }

    public func updateFile(coordinatingAccessTo url: URL, in block: @Sendable @escaping (URL) throws -> Void) throws {
        try coordinate(writingItemAt: url) { url in
            try block(url)
        }
    }

    public func readFile(coordinatingAccessTo url: URL, in block: @Sendable @escaping (URL) throws -> Void) throws {
        try coordinate(readingItemAt: url) { url in
            try block(url)
        }
    }

    private var executionBlock: ((URL) throws -> Void)?
    private func execute(onSecurityScopedResource url: URL) throws {
        guard let executionBlock else { fatalError() }
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        try executionBlock(url)
        self.executionBlock = nil
    }

    private func coordinate<T>(readingItemAt url: URL, options: NSFileCoordinator.ReadingOptions = [], with block: @escaping (URL) throws -> T) throws -> T {
        var coordinatorError: NSError?
        var managerError: Swift.Error?
        var result: T!
        let coordinator = NSFileCoordinator(filePresenter: presenter)
        executionBlock = {
            result = try block($0)
        }
        coordinator.coordinate(readingItemAt: url, options: options, error: &coordinatorError) { url in
            do {
                try self.execute(onSecurityScopedResource: url)
            } catch {
                managerError = error
            }
        }
        guard coordinatorError == nil else { throw coordinatorError! }
        guard managerError == nil else { throw managerError! }
        return result
    }

    private func coordinate(writingItemAt url: URL, options: NSFileCoordinator.WritingOptions = [], with block: @escaping (URL) throws -> Void) throws {
        var coordinatorError: NSError?
        var managerError: Swift.Error?
        let coordinator = NSFileCoordinator(filePresenter: presenter)
        executionBlock = block
        coordinator.coordinate(writingItemAt: url, options: options, error: &coordinatorError) { url in
            do {
                try execute(onSecurityScopedResource: url)
            } catch {
                managerError = error
            }
        }
        guard coordinatorError == nil else { throw coordinatorError! }
        guard managerError == nil else { throw managerError! }
    }

    private func coordinate(readingItemAt readURL: URL, readOptions: NSFileCoordinator.ReadingOptions = [], writingItemAt writeURL: URL, writeOptions: NSFileCoordinator.WritingOptions = [], with block: (_ readURL: URL, _ writeURL: URL) throws -> Void) throws {
        var coordinatorError: NSError?
        var managerError: Swift.Error?
        let coordinator = NSFileCoordinator(filePresenter: presenter)
        coordinator.coordinate(readingItemAt: readURL, options: readOptions, writingItemAt: writeURL, options: writeOptions, error: &coordinatorError) { (read: URL, write: URL) in
            do {
                let shouldStopAccessingRead = read.startAccessingSecurityScopedResource()
                let shouldStopAccessingWrite = write.startAccessingSecurityScopedResource()
                defer {
                    if shouldStopAccessingRead {
                        read.stopAccessingSecurityScopedResource()
                    }
                    if shouldStopAccessingWrite {
                        write.stopAccessingSecurityScopedResource()
                    }
                }
                try block(read, write)
            } catch {
                managerError = error
            }
        }
        guard coordinatorError == nil else { throw coordinatorError! }
        guard managerError == nil else { throw managerError! }
    }
}

// MARK: - RootRelativePath
public struct RootRelativePath: Hashable, Sendable {
    public var path: String

    public init(path: String) {
        self.path = path
    }

    public func fileURL(forRoot rootDirURL: URL) throws -> URL {
        guard rootDirURL.isFileURL, rootDirURL.hasDirectoryPath else {
            throw CloudDriveError.rootDirectoryURLIsNotDirectory
        }
        return rootDirURL.appendingPathComponent(path)
    }

    public func directoryURL(forRoot rootDirURL: URL) throws -> URL {
        guard rootDirURL.isFileURL, rootDirURL.hasDirectoryPath else {
            throw CloudDriveError.rootDirectoryURLIsNotDirectory
        }
        return rootDirURL.appendingPathComponent(path, isDirectory: true)
    }

    public func appending(_ addition: String) -> RootRelativePath {
        .init(path: (path as NSString).appendingPathComponent(addition))
    }

    /// The root of the container
    public static let root: Self = .init(path: "")
}

// MARK: - CloudDriveError
public enum CloudDriveError: Swift.Error, Sendable {
    case couldNotAccessUbiquityContainer
    case queriedWhileNotConnected
    case rootDirectoryURLIsNotDirectory
    case notSignedIntoCloud
    case invalidMetadata
    case invalidFileType
    case foundationError(NSError)
}

// MARK: - FileMonitor
final class FileMonitor: NSObject, NSFilePresenter, @unchecked Sendable {
    let rootDirectory: URL
    var presentedItemURL: URL? { rootDirectory }

    /// Called when any file changes, is added, or removed
    var changeHandler: (([RootRelativePath]) -> Void)?

    /// Returns true if resolved. If it returns false, or is nil, the default resolution is applied
    var conflictHandler: ((RootRelativePath) -> Bool)?

    lazy var presentedItemOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }

    deinit {
        NSFileCoordinator.removeFilePresenter(self)
    }

    /// This needs to be called when the monitor is fully setup
    func startMonitoring() {
        NSFileCoordinator.addFilePresenter(self)
    }

    func presentedSubitemDidAppear(at url: URL) {
        informOfChange(at: url)
    }

    func presentedSubitemDidChange(at url: URL) {
        informOfChange(at: url)
    }

    /// Should not really be needed, but there is some suggestion that deletions may be the same as moving to the trash, so we treat this as a deletion.
    func presentedSubitem(at oldURL: URL, didMoveTo newURL: URL) {
        informOfChange(at: oldURL)
    }

    func presentedItemDidGain(_ version: NSFileVersion) {
        do {
            if version.isConflict {
                try resolveConflicts(for: version.url)
            }
            informOfChange(at: version.url)
        } catch {
            os_log("Failed to handle cloud metadata")
        }
    }

    private func relativePath(for url: URL) -> RootRelativePath {
        let rootLength = rootDirectory.resolvingSymlinksInPath().standardized.path.count
        var path = String(url.resolvingSymlinksInPath().standardized.path.dropFirst(rootLength))
        if path.first == "/" { path.removeFirst() }
        let rootRelativePath = RootRelativePath(path: path)
        return rootRelativePath
    }

    private func informOfChange(at url: URL) {
        let rootRelativePath = relativePath(for: url)
        changeHandler?([rootRelativePath])
    }

    private func resolveConflicts(for url: URL) throws {
        let rootRelativePath = relativePath(for: url)
        let resolved = conflictHandler?(rootRelativePath) ?? false
        guard !resolved else { return }

        let coordinator = NSFileCoordinator(filePresenter: self)
        var coordinatorError: NSError?
        var versionError: Swift.Error?
        coordinator.coordinate(writingItemAt: url, options: .forDeleting, error: &coordinatorError) { newURL in
            do {
                try NSFileVersion.removeOtherVersionsOfItem(at: newURL)
            } catch {
                versionError = error
            }
        }

        guard versionError == nil else { throw versionError! }
        guard coordinatorError == nil else { throw CloudDriveError.foundationError(coordinatorError!) }

        let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: url)
        conflictVersions?.forEach { $0.isResolved = true }
    }
}

// MARK: - MetadataMonitor
final class MetadataMonitor: @unchecked Sendable {
    let rootDirectory: URL
    let fileManager: FileManager = .init()

    private var metadataQuery: NSMetadataQuery?

    init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: metadataQuery)
        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: metadataQuery)

        nonisolated(unsafe) let query = metadataQuery
        Task { @MainActor in
            guard let query else { return }
            query.disableUpdates()
            query.stop()
        }
    }

    func startMonitoringMetadata() {
        // Predicate that queries which files are in the cloud, not local, and need to begin downloading
        let predicate = NSPredicate(format: "%K = %@ AND %K = FALSE AND %K BEGINSWITH %@", NSMetadataUbiquitousItemDownloadingStatusKey, NSMetadataUbiquitousItemDownloadingStatusNotDownloaded, NSMetadataUbiquitousItemIsDownloadingKey, NSMetadataItemPathKey, rootDirectory.path)

        metadataQuery = NSMetadataQuery()
        guard let metadataQuery else { fatalError() }

        metadataQuery.notificationBatchingInterval = 3.0
        metadataQuery.searchScopes = [NSMetadataQueryUbiquitousDataScope, NSMetadataQueryUbiquitousDocumentsScope]
        metadataQuery.predicate = predicate

        NotificationCenter.default.addObserver(self, selector: #selector(handleMetadataNotification(_:)), name: .NSMetadataQueryDidFinishGathering, object: metadataQuery)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMetadataNotification(_:)), name: .NSMetadataQueryDidUpdate, object: metadataQuery)

        nonisolated(unsafe) let query = metadataQuery
        Task { @MainActor in
            query.start()
        }
    }

    @objc private func handleMetadataNotification(_ notif: Notification) {
        let urls = updatedURLsInMetadataQuery()
        for url in urls {
            do {
                try fileManager.startDownloadingUbiquitousItem(at: url)
            } catch {
                os_log("Failed to start downloading file")
            }
        }
    }

    private func updatedURLsInMetadataQuery() -> [URL] {
        guard let metadataQuery else { fatalError() }

        metadataQuery.disableUpdates()

        guard let results = metadataQuery.results as? [NSMetadataItem] else { return [] }
        let urls = results.compactMap { item in
            item.value(forAttribute: NSMetadataItemURLKey) as? URL
        }

        metadataQuery.enableUpdates()

        return urls
    }
}

// MARK: - Autoloader+Cloud
@objc extension Autoloader {
    static func loadPlugin_Cloud() {}
}

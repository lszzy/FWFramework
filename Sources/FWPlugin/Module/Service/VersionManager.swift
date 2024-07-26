//
//  Version.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - VersionStatus
/// 版本状态
public enum VersionStatus: Int, Sendable {
    /// 已发布
    case published = 0
    /// 需要更新
    case updating = 1
    /// 正在审核
    case auditing = 2
}

// MARK: - VersionManager
/// 版本管理器
public class VersionManager: @unchecked Sendable {
    
    // MARK: - Accessor
    /// 单例模式
    public static let shared = VersionManager()
    
    /// 当前版本号，可自定义。小于最新版本号表示需要更新，大于最新版本号表示正在审核
    public var currentVersion: String = ""
    
    /// 最新版本号，可自定义。默认从AppStore获取
    public var latestVersion: String?
    
    /// 当前版本状态，可自定义。根据最新版本号和当前版本号比较获得
    public var status: VersionStatus = .published
    
    /// 最新版本更新备注，可自定义。默认从AppStore获取
    public var releaseNotes: String?
    
    /// 应用Id，可选，默认自动根据BundleId获取
    public var appId: String?
    
    /// 地区码，可选，仅当app不能在美区访问时提供。示例：中国-cn
    public var countryCode: String?
    
    /// 版本发布延迟检测天数，可选，默认1天，防止上架后AppStore缓存用户无法立即更新
    public var delayDays: Int = 1
    
    /// 数据版本号，可自定义。当数据版本号小于当前版本号时，会依次执行数据更新句柄
    public var dataVersion: String?
    
    private var checkDate: Date?
    private var hasResult: Bool = false
    private var dataMigrations: [String: () -> Void] = [:]
    
    // MARK: - Lifecycle
    public init() {
        currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        checkDate = UserDefaults.standard.object(forKey: "FWVersionManagerCheckDate") as? Date
        dataVersion = UserDefaults.standard.object(forKey: "FWVersionManagerDataVersion") as? String
    }
    
    // MARK: - Public
    /// 检查应用版本号并进行比较，检查成功时回调。interval为频率(天)，0立即检查，1一天一次，7一周一次
    @discardableResult
    public func checkVersion(_ interval: Int, completion: (@Sendable () -> Void)?) -> Bool {
        if interval > 0 {
            if let checkDate = checkDate {
                // 根据当天0点时间和缓存0点时间计算间隔天数，大于等于interval需要请求。效果为每隔N天第一次运行时检查更新
                let components = Calendar.current.dateComponents([.day], from: checkDate, to: toCheckDate())
                if let day = components.day, day >= interval {
                    requestVersion(completion)
                    return true
                }
            } else {
                checkDate = toCheckDate()
                requestVersion(completion)
                return true
            }
        } else {
            requestVersion(completion)
            return true
        }
        return false
    }
    
    /// 跳转AppStore更新页，force为是否强制更新
    public func openAppStore(force: Bool = false) {
        guard let appId = appId, let storeUrl = URL(string: "https://apps.apple.com/app/id\(appId)") else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(storeUrl, options: [:]) { success in
                if force && success {
                    exit(EXIT_SUCCESS)
                }
            }
        }
    }
    
    /// 检查数据版本号并指定版本迁移方法，调用migrateData之前生效，仅会调用一次
    @discardableResult
    public func checkDataVersion(_ version: String, migration: @escaping () -> Void) -> Bool {
        // 需要执行时才放到队列中
        if checkDataVersion(version) {
            dataMigrations[version] = migration
            return true
        }
        return false
    }
    
    /// 比较数据版本号并依次进行数据迁移，迁移完成时回调(不执行迁移不回调)
    @discardableResult
    public func migrateData(_ completion: (@MainActor @Sendable () -> Void)?) -> Bool {
        // 版本号从低到高排序
        let versions = dataMigrations.keys.sorted { str1, str2 in
            return str1.compare(str2, options: .numeric) == .orderedAscending
        }
        
        // 是否需要执行迁移
        var result = false
        for version in versions {
            if !checkDataVersion(version) { continue }
            guard let migration = dataMigrations[version] else { continue }
            // 执行并从队列移除
            migration()
            dataMigrations.removeValue(forKey: version)
            result = true
            
            // 保存当前数据版本
            dataVersion = version
            UserDefaults.standard.set(dataVersion, forKey: "FWVersionManagerDataVersion")
            UserDefaults.standard.synchronize()
        }
        
        // 执行迁移完成主线程回调
        if result, let completion = completion {
            DispatchQueue.main.async(execute: completion)
        }
        return result
    }
    
    // MARK: - Private
    private func requestVersion(_ completion: (@Sendable () -> Void)?) {
        var requestUrl = "https://itunes.apple.com/lookup"
        if let appId = appId {
            requestUrl.append("?id=\(appId)")
        } else {
            requestUrl.append("?bundleId=\(Bundle.main.bundleIdentifier ?? "")")
        }
        if let countryCode = countryCode {
            requestUrl.append("&country=\(countryCode)")
        }
        
        guard let url = URL(string: requestUrl) else { return }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 30.0)
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard error == nil, let data = data else { return }
            self?.parseResponse(data, completion: completion)
        }
        task.resume()
    }
    
    private func parseResponse(_ data: Data, completion: (@Sendable () -> Void)?) {
        // 解析数据错误
        guard let dataDict = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else { return }
        guard let results = dataDict["results"] as? [[String: Any]] else { return }
        
        // 第一个版本审核中查询不到结果，是否兼容当前iOS系统版本
        hasResult = results.count > 0
        guard let appData = results.first, isOsCompatible(appData) else {
            checkCallback(completion)
            return
        }
        
        // 请求成功更新检查日期
        checkDate = toCheckDate()
        UserDefaults.standard.set(self.checkDate, forKey: "FWVersionManagerCheckDate")
        UserDefaults.standard.synchronize()
        
        // 检查发布日期是否满足条件(当前时间比发布时间间隔delayDays及以上)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        guard let releaseDateString = appData["currentVersionReleaseDate"] as? String,
              let releaseDate = dateFormatter.date(from: releaseDateString),
              let day = Calendar.current.dateComponents([.day], from: releaseDate, to: Date()).day,
              day >= delayDays else {
            checkCallback(completion)
            return
        }
        
        // 间隔day大于等于delayDays说明满足条件则获取版本信息
        if latestVersion == nil { latestVersion = appData["version"] as? String }
        if releaseNotes == nil { releaseNotes = appData["releaseNotes"] as? String }
        if appId == nil { appId = appData["trackId"] as? String }
        checkCallback(completion)
    }
    
    private func checkCallback(_ completion: (@Sendable () -> Void)?) {
        DispatchQueue.main.async {
            if let latestVersion = self.latestVersion {
                let result = self.currentVersion.compare(latestVersion, options: .numeric)
                switch result {
                // 当前版本小于最新版本，需要更新
                case .orderedAscending:
                    self.status = .updating
                // 当前版本大于最新版本，正在审核
                case .orderedDescending:
                    self.status = .auditing
                // 当前版本等于最新版本，已发布
                default:
                    self.status = .published
                }
            } else {
                // 有结果，但不符合条件，不需要更新
                if self.hasResult {
                    self.status = .published
                // 第一次审核查询不到结果，正在审核
                } else {
                    self.status = .auditing
                }
            }
            
            completion?()
        }
    }
    
    private func isOsCompatible(_ appData: [String: Any]) -> Bool {
        guard let minimumOsVersion = appData["minimumOsVersion"] as? String else { return false }
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        return versionString.compare(minimumOsVersion, options: .numeric) != .orderedAscending
    }
    
    private func checkDataVersion(_ version: String) -> Bool {
        // 指定版本大于当前版本不执行
        if version.compare(currentVersion, options: .numeric) == .orderedDescending { return false }
        // 第一次需要执行
        guard let dataVersion = dataVersion else { return true }
        // 当前数据版本小于指定版本需要执行
        return dataVersion.compare(version, options: .numeric) == .orderedAscending
    }
    
    private func toCheckDate() -> Date {
        // 转换为当天0点时间
        let date = Date()
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return Calendar.current.date(from: components) ?? date
    }
    
}

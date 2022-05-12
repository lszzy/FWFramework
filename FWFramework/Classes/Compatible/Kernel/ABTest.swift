//
//  ABTest.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

// MARK: - ABVersion
/// AB测试版本类
///
/// [ABKit](https://github.com/recruit-mp/ABKit)
@objc(FWABVersion)
@objcMembers public class ABVersion: NSObject {
    
    // MARK: - Accessor
    /// 版本名称
    public let name: String
    let behavior: (ABVersion) -> Void
    
    // MARK: - Lifecycle
    /// 初始化方法
    public init(name: String, behavior: @escaping (ABVersion) -> Void) {
        self.name = name
        self.behavior = behavior
    }
    
}

// MARK: - ABSplitTest
/// AB分离测试类
@objc(FWABSplitTest)
@objcMembers public class ABSplitTest: NSObject {
    
    // MARK: - Accessor
    /// 测试名称
    public let name: String
    /// 默认版本
    public let defaultVersion: ABVersion
    /// 随机数仓库
    public let randomRepository: ABRandomRepository
    
    var versionWeights: [ABVersionWeight] = []
    
    // MARK: - Lifecycle
    /// 初始化方法，指定随机数仓库
    public init(name: String, defaultVersion: ABVersion, randomRepository: ABRandomRepository) {
        self.name = name
        self.defaultVersion = defaultVersion
        self.randomRepository = randomRepository
    }
    
    /// 初始化方法，使用默认UserDefaults随机数仓库
    public convenience init(name: String, defaultVersion: ABVersion) {
        self.init(name: name, defaultVersion: defaultVersion, randomRepository: ABDefaultRepository.sharedInstance)
    }
    
    // MARK: - Public
    /// 添加版本并指定权重
    public func addVersion(_ version: ABVersion, weight: Double) {
        let versionWeight = ABVersionWeight(version: version, weight: Int(weight * 100))
        versionWeights.append(versionWeight)
    }
    
    /// 设置随机数
    public func setRandomNumber(_ randomNumber: Int) {
        randomRepository.setRandomNumber(randomNumber, key: "FWAB-\(name)")
    }
    
    /// 移除随机数
    public func removeRandomNumber() {
        randomRepository.removeRandomNumber(key: "FWAB-\(name)")
    }
    
    /// 运行测试
    public func run() {
        let totalWeight = versionWeights.reduce(0) { $0 + $1.weight }
        if totalWeight > 100 { return }
        
        var weightIndex = 0
        for (index, versionWeight) in versionWeights.enumerated() {
            let min = weightIndex
            let max = weightIndex + versionWeight.weight
            versionWeights[index].weightRange = min..<max
            weightIndex = versionWeight.weight
        }
        
        let randomNumber = randomRepository.getRandomNumber(key: "FWAB-\(name)")
        let versions = versionWeights.filter { $0.contains(number: randomNumber) }.map { $0.version }
        let version = versions.first ?? defaultVersion
        version.behavior(version)
    }
    
}

// MARK: - ABConditionalTest
/// AB条件测试类
@objc(FWABConditionalTest)
@objcMembers public class ABConditionalTest: NSObject {
    
    // MARK: - Accessor
    /// 测试名称
    public let name: String
    /// 默认版本
    public let defaultVersion: ABVersion

    private var versions: [ABConditionalVersion] = []
    
    // MARK: - Lifecycle
    /// 初始化方法
    public init(name: String, defaultVersion: ABVersion) {
        self.name = name
        self.defaultVersion = defaultVersion
    }
    
    // MARK: - Public
    /// 添加版本和条件处理闭包
    public func addVersion(_ version: ABVersion, condition: @escaping (Any?) -> Bool) {
        let conditionalVersion = ABConditionalVersion(name: version.name, behavior: version.behavior, condition: condition)
        versions.append(conditionalVersion)
    }
    
    /// 运行测试
    public func run(value: Any?) {
        var treated = false
        for version in versions {
            if version.condition(value) {
                version.behavior(version)
                treated = true
                break
            }
        }
        
        if !treated {
            defaultVersion.behavior(defaultVersion)
        }
    }
    
}

// MARK: - ABRandomRepository
/// 随机数仓库协议
@objc(FWABRandomRepository)
public protocol ABRandomRepository {
    
    /// 获取指定key随机数
    func getRandomNumber(key: String) -> Int
    /// 设置指定key随机数
    func setRandomNumber(_ randomNumber: Int, key: String)
    /// 删除指定key随机数
    func removeRandomNumber(key: String)
    
}

// MARK: - ABDefaultRepository
/// 默认随机数仓库，存储于UserDefaults
@objc(FWABDefaultRepository)
@objcMembers public class ABDefaultRepository: NSObject, ABRandomRepository {
    
    // MARK: - Accessor
    /// 单例模式
    public static let sharedInstance = ABDefaultRepository()
    
    private var userDefaults: UserDefaults
    
    // MARK: - Lifecycle
    /// 初始化，使用默认UserDefaults
    public override init() {
        userDefaults = .standard
    }
    
    /// 初始化，指定UserDefaults
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Public
    /// 获取指定key随机数
    public func getRandomNumber(key: String) -> Int {
        var randomNumber = userDefaults.integer(forKey: key)
        if randomNumber == 0 {
            randomNumber = Int(arc4random_uniform(100))
            userDefaults.set(randomNumber, forKey: key)
            userDefaults.synchronize()
        }
        return randomNumber
    }
    
    /// 设置指定key随机数
    public func setRandomNumber(_ randomNumber: Int, key: String) {
        userDefaults.set(randomNumber, forKey: key)
        userDefaults.synchronize()
    }
    
    /// 删除指定key随机数
    public func removeRandomNumber(key: String) {
        userDefaults.removeObject(forKey: key)
        userDefaults.synchronize()
    }
    
}

// MARK: - ABVersionWeight
/// 内部版本权重类
class ABVersionWeight {
    
    // MARK: - Accessor
    let version: ABVersion
    let weight: Int
    var weightRange: Range<Int> = 0..<100
    
    // MARK: - Lifecycle
    init(version: ABVersion, weight: Int) {
        self.version = version
        self.weight = weight
    }
    
    // MARK: - Public
    func contains(number: Int) -> Bool {
        return weightRange.contains(number)
    }
    
}

// MARK: - ABConditionalVersion
/// 内部条件版本类
class ABConditionalVersion: ABVersion {
    
    // MARK: - Accessor
    let condition: (Any?) -> Bool
    
    // MARK: - Lifecycle
    init(name: String, behavior: @escaping (ABVersion) -> Void, condition: @escaping (Any?) -> Bool) {
        self.condition = condition
        super.init(name: name, behavior: behavior)
    }
    
}

//
//  FWABTest.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// AB测试版本类
///
/// [ABKit](https://github.com/recruit-mp/ABKit)
@objcMembers public class FWABVersion: NSObject {
    /// 版本名称
    public let name: String
    let behavior: (FWABVersion) -> Void
    
    /// 初始化方法
    public init(name: String, behavior: @escaping (FWABVersion) -> Void) {
        self.name = name
        self.behavior = behavior
    }
}

/// 内部版本权重类
class FWABVersionWeight {
    let version: FWABVersion
    let weight: Int
    var weightRange: Range<Int> = 0..<100
    
    init(version: FWABVersion, weight: Int) {
        self.version = version
        self.weight = weight
    }
    
    func contains(number: Int) -> Bool {
        return weightRange.contains(number)
    }
}

/// 随机数仓库协议
@objc public protocol FWABRandomRepository {
    /// 获取指定key随机数
    func getRandomNumber(key: String) -> Int
    /// 设置指定key随机数
    func setRandomNumber(_ randomNumber: Int, key: String)
    /// 删除指定key随机数
    func removeRandomNumber(key: String)
}

/// 默认随机数仓库，存储于UserDefaults
@objcMembers public class FWABDefaultRepository: NSObject, FWABRandomRepository {
    /// 单例模式
    public static let sharedInstance = FWABDefaultRepository()
    
    private var userDefaults: UserDefaults
    
    /// 初始化，使用默认UserDefaults
    public override init() {
        userDefaults = .standard
    }
    
    /// 初始化，指定UserDefaults
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
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

/// AB分离测试类
@objcMembers public class FWABSplitTest: NSObject {
    /// 测试名称
    public let name: String
    /// 默认版本
    public let defaultVersion: FWABVersion
    /// 随机数仓库
    public let randomRepository: FWABRandomRepository
    
    var versionWeights: [FWABVersionWeight] = []
    
    /// 初始化方法，指定随机数仓库
    public init(name: String, defaultVersion: FWABVersion, randomRepository: FWABRandomRepository) {
        self.name = name
        self.defaultVersion = defaultVersion
        self.randomRepository = randomRepository
    }
    
    /// 初始化方法，使用默认UserDefaults随机数仓库
    public convenience init(name: String, defaultVersion: FWABVersion) {
        self.init(name: name, defaultVersion: defaultVersion, randomRepository: FWABDefaultRepository.sharedInstance)
    }
    
    /// 添加版本并指定权重
    public func addVersion(_ version: FWABVersion, weight: Double) {
        let versionWeight = FWABVersionWeight(version: version, weight: Int(weight * 100))
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

/// 内部条件版本类
class FWABConditionalVersion: FWABVersion {
    let condition: (Any?) -> Bool
    
    init(name: String, behavior: @escaping (FWABVersion) -> Void, condition: @escaping (Any?) -> Bool) {
        self.condition = condition
        super.init(name: name, behavior: behavior)
    }
}

/// AB条件测试类
@objcMembers public class FWABConditionalTest: NSObject {
    /// 测试名称
    public let name: String
    /// 默认版本
    public let defaultVersion: FWABVersion

    private var versions: [FWABConditionalVersion] = []
    
    /// 初始化方法
    public init(name: String, defaultVersion: FWABVersion) {
        self.name = name
        self.defaultVersion = defaultVersion
    }
    
    /// 添加版本和条件处理闭包
    public func addVersion(_ version: FWABVersion, condition: @escaping (Any?) -> Bool) {
        let conditionalVersion = FWABConditionalVersion(name: version.name, behavior: version.behavior, condition: condition)
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

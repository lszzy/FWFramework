//
//  TestCacheController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/1.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestCacheController: UIViewController {
    
    private var cache: CacheProtocol?
    
    private static var testCacheKey = "testCacheKey"
    private static var testExpireKey = "testCacheKey.__EXPIRE__"
    
    private lazy var cacheLabel: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.textAlignment = .center
        return result
    }()
    
    private lazy var refreshButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("读取缓存", for: .normal)
        result.fw.addTouch { [weak self] _ in
            self?.refreshCache()
        }
        return result
    }()
    
    private lazy var cacheButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("写入缓存", for: .normal)
        result.fw.addTouch { [weak self] _ in
            self?.cache?.setObject(UUID().uuidString, forKey: TestCacheController.testCacheKey)
            self?.refreshCache()
        }
        return result
    }()
    
    private lazy var expireButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("写入缓存(10s)", for: .normal)
        result.fw.addTouch { [weak self] _ in
            self?.cache?.setObject(UUID().uuidString, forKey: TestCacheController.testCacheKey, withExpire: 10)
            self?.refreshCache()
        }
        return result
    }()
    
    private lazy var deleteButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("删除缓存", for: .normal)
        result.fw.addTouch { [weak self] _ in
            self?.cache?.removeObject(forKey: TestCacheController.testCacheKey)
            self?.refreshCache()
        }
        return result
    }()
    
    private lazy var clearButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("清空缓存", for: .normal)
        result.fw.addTouch { [weak self] _ in
            self?.cache?.removeAllObjects()
            self?.refreshCache()
        }
        return result
    }()
    
}

extension TestCacheController: ViewControllerProtocol {
    
    func setupNavbar() {
        fw.setRightBarItem("切换") { [weak self] _ in
            self?.fw.showSheet(title: "选择缓存类型", message: nil, actions: ["CacheMemory", "CacheUserDefaults", "CacheKeychain", "CacheFile", "CacheSqlite"], actionBlock: { index in
                if index == 0 {
                    self?.cache = CacheManager.manager(withType: .memory)
                } else if index == 1 {
                    self?.cache = CacheManager.manager(withType: .userDefaults)
                } else if index == 2 {
                    self?.cache = CacheManager.manager(withType: .keychain)
                } else if index == 3 {
                    self?.cache = CacheManager.manager(withType: .file)
                } else if index == 4 {
                    self?.cache = CacheManager.manager(withType: .sqlite)
                }
                self?.refreshCache()
            })
        }
    }
    
    func setupSubviews() {
        view.addSubview(cacheLabel)
        view.addSubview(refreshButton)
        view.addSubview(cacheButton)
        view.addSubview(expireButton)
        view.addSubview(deleteButton)
        view.addSubview(clearButton)
    }
    
    func setupLayout() {
        cacheLabel.fw.layoutChain
            .horizontal(10)
            .top(toSafeArea: 10)
        
        refreshButton.fw.layoutChain
            .top(toViewBottom: cacheLabel, offset: 10)
            .centerX()
        
        cacheButton.fw.layoutChain
            .top(toViewBottom: refreshButton, offset: 10)
            .centerX()
        
        expireButton.fw.layoutChain
            .top(toViewBottom: cacheButton, offset: 10)
            .centerX()
        
        deleteButton.fw.layoutChain
            .top(toViewBottom: expireButton, offset: 10)
            .centerX()
        
        clearButton.fw.layoutChain
            .top(toViewBottom: deleteButton, offset: 10)
            .centerX()
        
        setupCache()
    }
    
}

extension TestCacheController {
    
    func setupCache() {
        cache = CacheMemory.shared
        refreshCache()
    }
    
    func refreshCache() {
        var statusStr = ""
        if let cacheClass = cache as? NSObject {
            statusStr += NSStringFromClass(cacheClass.classForCoder)
            statusStr += "\n"
        }
        
        var hasCache = false
        if let cacheStr = cache?.object(forKey: TestCacheController.testCacheKey) as? String, !cacheStr.isEmpty {
            statusStr += cacheStr
            hasCache = true
        } else {
            statusStr += "缓存不存在"
            hasCache = false
        }
        statusStr += "\n"
        
        if let expireNum = cache?.object(forKey: TestCacheController.testExpireKey) as? NSNumber {
            statusStr += String(format: "%.1fs有效", expireNum.doubleValue - Date().timeIntervalSince1970)
        } else {
            statusStr += hasCache ? "永久有效" : "缓存无效"
        }
        cacheLabel.text = statusStr
    }
    
}
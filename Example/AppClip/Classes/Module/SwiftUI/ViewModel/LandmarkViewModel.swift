//
//  LandmarkViewModel.swift
//  AppClip
//
//  Created by wuyong on 2020/12/1.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - propertyWrapper

@propertyWrapper
public struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

public struct AppUserDefaults {
    @UserDefault("user_region", defaultValue: Locale.current.regionCode ?? "US")
    public static var region: String
        
    @UserDefault("original_title", defaultValue: false)
    public static var alwaysOriginalTitle: Bool
}

// MARK: - ViewModel

protocol LandmarkViewAction {
    func refreshData(_ callback: @escaping () -> Void)
    func loadData(_ callback: @escaping () -> Void)
}

class LandmarkViewModel: ObservableObject, LandmarkViewAction {
    @Published var items: [String] = []
    
    func refreshData(_ callback: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.items = ["1", "2", "3"]
            callback()
        }
    }
    
    func loadData(_ callback: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.items.append("1")
            callback()
        }
    }
}

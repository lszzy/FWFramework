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

protocol UnidirectionalDataFlowType {
    associatedtype InputType
    
    func apply(_ input: InputType)
}

class LandmarkViewModel: ObservableObject, UnidirectionalDataFlowType {
    typealias InputType = Input
    
    @Published var data: String? = nil
    
    enum Input {
        case onAppear
    }
    
    func apply(_ input: Input) {
        switch input {
        case .onAppear:
            request()
        }
    }
    
    private func request() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.data = "Data From Response"
        }
    }
}

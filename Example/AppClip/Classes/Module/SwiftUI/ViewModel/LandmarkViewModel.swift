//
//  LandmarkViewModel.swift
//  AppClip
//
//  Created by wuyong on 2020/12/1.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI
import Combine
import FWFramework

// MARK: - AppUserDefaults

public struct AppUserDefaults {
    @FWUserDefault("userName", defaultValue: "test")
    public static var userName: String
}

// MARK: - ViewModel

final class LandmarkViewModel: ObservableObject {
    enum State {
        case idle
        case loaded([String])
        case error(Error?)
    }
    
    @Published private(set) var state = State.idle
    
    func onRefreshing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            switch self.state {
            case .idle:
                self.state = .loaded(["1", "2", "3"])
            case .error(_):
                self.state = .loaded(["1", "2", "3", "4"])
            default:
                self.state = .error(nil)
            }
        }
    }
}

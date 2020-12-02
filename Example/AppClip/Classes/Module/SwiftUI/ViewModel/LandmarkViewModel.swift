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
    @FWUserDefaultAnnotation("userName", defaultValue: "test")
    public static var userName: String
}

// MARK: - ViewModel

final class LandmarkViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded([String])
        case error(Error)
    }
    
    enum Event {
        case refresh
    }
    
    @Published private(set) var state = State.idle
    
    private var cancelBag = Set<AnyCancellable>()
    private let stateSubject = PassthroughSubject<State, Never>()
    
    init() {
        let stateStream = stateSubject
            .assign(to: \.state, on: self)
        
        cancelBag.insert(stateStream)
    }
    
    func send(_ event: Event) {
        switch event {
        case .refresh:
            onRefreshing()
        }
    }
    
    private var testCount: Int = 0
    
    private func onRefreshing() {
        self.testCount += 1
        self.stateSubject.send(.loading)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.testCount % 2 == 1 {
                self.stateSubject.send(.loaded(["1", "2", "3"]))
            } else {
                self.stateSubject.send(.error(NSError(domain: "Test", code: 0, userInfo: nil)))
            }
        }
    }
}

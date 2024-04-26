//
//  ExampleApp.swift
//  FWSwiftUI
//
//  Created by wuyong on 2024/4/26.
//

import SwiftUI
import FWFramework

@main
struct ExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        print("Application is starting...")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            .onOpenURL { url in
                print("Received URL: \(url)")
            }
        }
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active:
                print("App is active")
            case .inactive:
                print("App is inactive")
            case .background:
                print("App is in background")
            @unknown default:
                print("Oh - interesting: I received an unexpected new value.")
            }
        }
    }
}

class AppDelegate: AppResponder {}

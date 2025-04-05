//
//  ExampleApp.swift
//  FWSwiftUI
//
//  Created by wuyong on 2024/4/26.
//

import FWFramework
import FWUIKit
import SwiftUI

@main
struct ExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @Environment(\.scenePhase) var scenePhase

    init() {
        print("App is starting")

        if #available(iOS 16.1, *) {
            ActivityManager.requestAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if #available(iOS 16.1, *) {
                    ContentView()
                } else {
                    VStack {
                        Image(systemName: "globe")
                            .imageScale(.large)

                        Text("Hello, world!")
                    }
                    .padding()
                }
            }
            .onOpenURL { url in
                print("Received URL: \(url)")
                UIWindow.wrapperExtension.showMessage(text: url.absoluteString)
            }
            .onAppear {
                print("View onAppear")
            }
            .onDisappear {
                print("View onDisappear")
            }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                print("App is active")
            case .inactive:
                print("App is inactive")
            case .background:
                print("App is in background")
            @unknown default:
                print("App is \(phase)")
            }
        }
    }
}

class AppDelegate: AppResponder {}

//
//  SceneDelegate.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// SceneDelegate基类
@available(iOS 13.0, *)
open class SceneResponder: UIResponder, UIWindowSceneDelegate {
    
    /// 场景主window
    open var window: UIWindow?
    
    /// 初始化根控制器，子类重写
    open func setupController() {
        /*
        window?.rootViewController = TabBarController()
         */
    }
    
    // MARK: - UIWindowSceneDelegate
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
            window?.makeKeyAndVisible()
            setupController()
        }
    }
    
    public func sceneDidDisconnect(_ scene: UIScene) {
        
    }
    
    public func sceneDidBecomeActive(_ scene: UIScene) {
        
    }
    
    public func sceneWillResignActive(_ scene: UIScene) {
        
    }
    
    public func sceneWillEnterForeground(_ scene: UIScene) {
        
    }
    
    public func sceneDidEnterBackground(_ scene: UIScene) {
        
    }
    
}

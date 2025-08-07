//
//  SceneDelegate.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// SceneDelegate基类
open class SceneResponder: UIResponder, UIWindowSceneDelegate {
    /// 应用主delegate
    public class var shared: Self! {
        UIWindow.fw.mainScene?.delegate as? Self
    }
    
    /// 场景主window
    open var window: UIWindow?

    // MARK: - Override
    /// 初始化根控制器，子类重写
    open func setupController() {
        /*
         window?.rootViewController = TabBarController()
          */
    }
    
    /// 重新加载根控制器，按需使用，子类可重写
    open func reloadController() {
        setupController()
    }

    // MARK: - UIWindowSceneDelegate
    open func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.makeKeyAndVisible()
        setupController()
    }

    open func sceneDidDisconnect(_ scene: UIScene) {}

    open func sceneDidBecomeActive(_ scene: UIScene) {}

    open func sceneWillResignActive(_ scene: UIScene) {}

    open func sceneWillEnterForeground(_ scene: UIScene) {}

    open func sceneDidEnterBackground(_ scene: UIScene) {}
}

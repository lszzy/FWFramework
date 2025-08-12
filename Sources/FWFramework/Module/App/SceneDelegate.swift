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
    /// 初始化窗口，优先级1，子类可重写
    open func setupWindow(_ windowScene: UIWindowScene) {
        window = UIWindow(windowScene: windowScene)
        window?.makeKeyAndVisible()
    }

    /// 初始化根控制器，优先级2，子类需重写
    open func setupController() {
        /*
         window?.rootViewController = TabBarController()
          */
    }

    /// 初始化场景，优先级3，子类可重写
    open func setupScene(_ windowScene: UIWindowScene) {
        /**
         自定义场景，其它场景设置
         */
    }

    /// 重新加载根控制器，按需使用，子类可重写
    open func reloadController() {
        setupController()
    }

    // MARK: - UIWindowSceneDelegate
    open func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        setupWindow(windowScene)
        setupController()
        setupScene(windowScene)

        if let appResponder = UIApplication.shared.delegate as? AppResponder {
            appResponder.sceneDidConnect(windowScene)
        }
    }

    open func sceneDidDisconnect(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }

        if let appResponder = UIApplication.shared.delegate as? AppResponder {
            appResponder.sceneDidDisconnect(windowScene)
        }
    }

    open func sceneDidBecomeActive(_ scene: UIScene) {}

    open func sceneWillResignActive(_ scene: UIScene) {}

    open func sceneWillEnterForeground(_ scene: UIScene) {}

    open func sceneDidEnterBackground(_ scene: UIScene) {}
}

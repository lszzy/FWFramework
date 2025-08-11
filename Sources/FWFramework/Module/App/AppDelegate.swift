//
//  AppDelegate.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// AppDelegate基类
open class AppResponder: UIResponder, UIApplicationDelegate {
    /// 应用主delegate
    public class var shared: Self! {
        UIApplication.shared.delegate as? Self
    }

    // MARK: - Override
    /// 初始化应用环境，优先级1，willFinishLaunching子模块之前调用，子类重写
    open func setupEnvironment() {
        /*
         Mediator.multicastDelegateEnabled = true
         ErrorManager.startCapture()
          */
    }

    /// 初始化应用配置，优先级2，didFinishLaunching子模块之前调用，子类重写
    open func setupApplication(_ application: UIApplication, options: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        /*
         NotificationManager.shared.clearNotificationBadges()
         if let remoteNotification = options?[.remoteNotification] {
             NotificationManager.shared.handleRemoteNotification(remoteNotification)
         }
         if let localNotification = options?[.localNotification] {
             NotificationManager.shared.handleLocalNotification(localNotification)
         }
          */

        /*
         NotificationManager.shared.registerNotificationHandler()
         NotificationManager.shared.requestAuthorize(nil)
          */
    }

    /// 初始化应用服务，优先级3，didFinishLaunching子模块之后调用，子类重写
    open func setupService(options: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        /*
         定制应用服务、初始化三方SDK等
          */
    }
    
    /// 场景已连接，优先级4，场景window及根控制器创建完成后自动调用
    open func sceneDidConnect(_ windowScene: UIWindowScene) {
        /*
         界面已初始化后的处理、检查App更新、预加载启动广告等
          */
    }
    
    /// 场景已断开，场景断开连接时自动调用
    open func sceneDidDisconnect(_ windowScene: UIWindowScene) {
        /**
         释放场景资源等
         */
    }

    // MARK: - UIApplicationDelegate
    @discardableResult
    open func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Autoloader.autoload()
        setupEnvironment()

        Mediator.setupAllModules()
        if Mediator.multicastDelegateEnabled {
            Mediator.checkAllModules { _ = $0.application?(application, willFinishLaunchingWithOptions: launchOptions) }
        } else {
            Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:willFinishLaunchingWithOptions:)), arguments: [application, launchOptions ?? NSNull()])
        }
        return true
    }

    @discardableResult
    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        setupApplication(application, options: launchOptions)

        if Mediator.multicastDelegateEnabled {
            Mediator.checkAllModules { _ = $0.application?(application, didFinishLaunchingWithOptions: launchOptions) }
        } else {
            Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)), arguments: [application, launchOptions ?? NSNull()])
        }

        setupService(options: launchOptions)
        return true
    }

    open func applicationWillResignActive(_ application: UIApplication) {
        if Mediator.multicastDelegateEnabled {
            Mediator.checkAllModules { $0.applicationWillResignActive?(application) }
        } else {
            Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.applicationWillResignActive(_:)), arguments: [application])
        }
    }

    open func applicationDidEnterBackground(_ application: UIApplication) {
        if Mediator.multicastDelegateEnabled {
            Mediator.checkAllModules { $0.applicationDidEnterBackground?(application) }
        } else {
            Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), arguments: [application])
        }
    }

    open func applicationWillEnterForeground(_ application: UIApplication) {
        if Mediator.multicastDelegateEnabled {
            Mediator.checkAllModules { $0.applicationWillEnterForeground?(application) }
        } else {
            Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), arguments: [application])
        }

        /*
         NotificationManager.shared.clearNotificationBadges()
          */
    }

    open func applicationDidBecomeActive(_ application: UIApplication) {
        if Mediator.multicastDelegateEnabled {
            Mediator.checkAllModules { $0.applicationDidBecomeActive?(application) }
        } else {
            Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), arguments: [application])
        }
    }

    open func applicationWillTerminate(_ application: UIApplication) {
        if Mediator.multicastDelegateEnabled {
            Mediator.checkAllModules { $0.applicationWillTerminate?(application) }
        } else {
            Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.applicationWillTerminate(_:)), arguments: [application])
        }
    }

    // MARK: - UIScene
    open func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        /*
         默认名称"Default Configuration"，子类可重写
         */
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    open func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        /*
         清理scene资源
          */
    }

    // MARK: - Notification
    open func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if Mediator.multicastDelegateEnabled {
            Mediator.checkAllModules { $0.application?(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken) }
        } else {
            Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)), arguments: [application, deviceToken])
        }

        /*
         UIDevice.fw.setDeviceTokenData(deviceToken)
          */
    }

    open func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        if Mediator.multicastDelegateEnabled {
            Mediator.checkAllModules { $0.application?(application, didFailToRegisterForRemoteNotificationsWithError: error) }
        } else {
            Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:)), arguments: [application, error])
        }

        /*
         UIDevice.fw.setDeviceTokenData(nil)
          */
    }

    open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Mediator.multicastDelegateEnabled {
            Mediator.checkAllModules { $0.application?(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler) }
        } else {
            Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)), arguments: [application, userInfo, completionHandler])
        }

        /*
         NotificationManager.shared.handleRemoteNotification(userInfo)
         completionHandler(.newData)
          */
    }

    // MARK: - URL
    @discardableResult
    open func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if Mediator.multicastDelegateEnabled {
            var result = false
            Mediator.checkAllModules { delegate in
                let returnValue = delegate.application?(app, open: url, options: options)
                if !result, let returnValue {
                    result = returnValue
                }
            }
            return result
        } else {
            return Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:open:options:)), arguments: [app, url, options])
        }

        /*
         Router.openURL(url)
         return true
          */
    }

    @discardableResult
    open func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if Mediator.multicastDelegateEnabled {
            var result = false
            Mediator.checkAllModules { delegate in
                let returnValue = delegate.application?(application, continue: userActivity, restorationHandler: restorationHandler)
                if !result, let returnValue {
                    result = returnValue
                }
            }
            return result
        } else {
            return Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:continue:restorationHandler:)), arguments: [application, userActivity, restorationHandler])
        }

        /*
         if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let webpageURL = userActivity.webpageURL {
             Router.openURL(webpageURL)
             return true
         }
         return false
          */
    }
}

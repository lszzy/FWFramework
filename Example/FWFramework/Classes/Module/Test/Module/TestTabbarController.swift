//
//  TestTabbarController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestTabbarController: TabBarController, UITabBarControllerDelegate {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        app.leftBarItem = Icon.backImage
        delegate = self
        
        setupSubviews()
        setupController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = selectedViewController?.navigationItem.title
    }
    
    func setupSubviews() {
        tabBar.app.foregroundColor = AppTheme.textColor
        tabBar.app.backgroundColor = AppTheme.barColor
        tabBar.app.shadowColor = nil
        tabBar.app.setShadowColor(.app.color(hex: 0x040000, alpha: 0.15), offset: CGSize(width: 0, height: 1), radius: 3)
    }
    
    func setupController() {
        let homeController = TestTabbarChildController()
        homeController.hidesBottomBarWhenPushed = false
        homeController.navigationItem.title = APP.localized("homeTitle")
        homeController.tabBarItem.image = APP.iconImage("zmdi-var-home", 26)
        homeController.tabBarItem.title = APP.localized("homeTitle")
        
        let testController = TestTabbarChildController()
        testController.hidesBottomBarWhenPushed = false
        testController.navigationItem.title = APP.localized("testTitle")
        testController.tabBarItem.image = Icon.iconImage("zmdi-var-bug", size: 26)
        testController.tabBarItem.title = APP.localized("testTitle")
        
        let settingsControlelr = TestTabbarChildController()
        settingsControlelr.hidesBottomBarWhenPushed = false
        settingsControlelr.navigationItem.title = APP.localized("settingTitle")
        let tabBarItem = TabBarItem()
        tabBarItem.contentView.highlightTextColor = AppTheme.textColor
        tabBarItem.contentView.highlightIconColor = AppTheme.textColor
        settingsControlelr.tabBarItem = tabBarItem
        settingsControlelr.tabBarItem.image = APP.icon("zmdi-var-settings", 26)?.image
        settingsControlelr.tabBarItem.title = APP.localized("settingTitle")
        viewControllers = [homeController, testController, settingsControlelr]
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        navigationItem.title = viewController.navigationItem.title
    }
    
}

class TestTabbarChildController: UIViewController, ViewControllerProtocol {
    
    func setupSubviews() {
        view.backgroundColor = UIColor.app.randomColor
        view.app.addTapGesture { [weak self] sender in
            let viewController = TestTabbarChildController()
            var title = APP.safeString(self?.navigationItem.title)
            if let index = title.firstIndex(of: "-") {
                let count = Int(title.suffix(from: title.index(index, offsetBy: 1))) ?? 0
                title = "\(title.prefix(upTo: index))-\(count + 1)"
            } else {
                title = "\(title)-1"
            }
            viewController.navigationItem.title = title
            Navigator.push(viewController, animated: true)
        }
    }
    
}

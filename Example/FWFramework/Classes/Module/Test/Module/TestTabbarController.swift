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
        let testBarItem = TabBarItem()
        testBarItem.contentView = TestTabbarContentView()
        testBarItem.contentView.highlightTextColor = AppTheme.textColor
        testBarItem.contentView.highlightIconColor = AppTheme.textColor
        testBarItem.image = Icon.iconImage("zmdi-var-bug", size: 50)
        testBarItem.title = APP.localized("testTitle")
        testController.tabBarItem = testBarItem
        
        let settingsControlelr = TestTabbarChildController()
        settingsControlelr.hidesBottomBarWhenPushed = false
        settingsControlelr.navigationItem.title = APP.localized("settingTitle")
        let settingsBarItem = TabBarItem()
        settingsBarItem.contentView.highlightTextColor = AppTheme.textColor
        settingsBarItem.contentView.highlightIconColor = AppTheme.textColor
        settingsControlelr.tabBarItem = settingsBarItem
        settingsControlelr.tabBarItem.image = APP.icon("zmdi-var-settings", 26)?.image
        settingsControlelr.tabBarItem.title = APP.localized("settingTitle")
        viewControllers = [homeController, testController, settingsControlelr]
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        navigationItem.title = viewController.navigationItem.title
    }
    
}

class TestTabbarContentView: TabBarItemContentView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView.backgroundColor = AppTheme.barColor
        self.imageView.layer.cornerRadius = 35
        self.insets = UIEdgeInsets(top: -35, left: 0, bottom: 0, right: 0)
        self.imageInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateLayout() {
        super.updateLayout()
        self.imageView.frame = CGRect(x: (bounds.size.width - 70) / 2.0, y: 0, width: 70, height: 70)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let p = CGPoint(x: point.x - imageView.frame.origin.x, y: point.y - imageView.frame.origin.y)
        return sqrt(pow(imageView.bounds.size.width / 2.0 - p.x, 2) + pow(imageView.bounds.size.height / 2.0 - p.y, 2)) < imageView.bounds.size.width / 2.0
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

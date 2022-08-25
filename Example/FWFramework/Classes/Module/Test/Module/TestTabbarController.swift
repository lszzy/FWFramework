//
//  TestTabbarController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestTabbarController: UIViewController, ViewControllerProtocol {
    
    private lazy var childView: UIView = {
        let result = UIView()
        return result
    }()
    
    private lazy var tabBarView: ToolbarView = {
        let result = ToolbarView(type: .tabBar)
        result.backgroundColor = AppTheme.barColor
        result.tintColor = AppTheme.textColor
        result.menuView.leftButton = homeButton
        result.menuView.centerButton = testButton
        result.menuView.rightButton = settingsButton
        return result
    }()
    
    private lazy var homeButton: ToolbarButton = {
        let result = ToolbarButton(image: FW.iconImage("zmdi-var-home", 26), title: FW.localized("homeTitle"))
        result.titleLabel?.font = FW.font(10)
        result.fw.addTouch(target: self, action: #selector(onButtonClicked(_:)))
        result.tag = 1
        return result
    }()
    
    private lazy var testButton: ToolbarButton = {
        let result = ToolbarButton(image: Icon.iconImage("zmdi-var-bug", size: 26), title: FW.localized("testTitle"))
        result.titleLabel?.font = FW.font(10)
        result.fw.addTouch(target: self, action: #selector(onButtonClicked(_:)))
        result.tag = 2
        return result
    }()
    
    private lazy var settingsButton: ToolbarButton = {
        let result = ToolbarButton(image: FW.icon("zmdi-var-settings", 26)?.image, title: FW.localized("settingTitle"))
        result.titleLabel?.font = FW.font(10)
        result.fw.addTouch(target: self, action: #selector(onButtonClicked(_:)))
        result.tag = 3
        return result
    }()
    
    private lazy var homeController: UIViewController = {
        let result = TestTabbarChildController()
        result.title = FW.localized("homeTitle")
        return result
    }()
    
    private lazy var testController: UIViewController = {
        let result = TestTabbarChildController()
        result.title = FW.localized("testTitle")
        return result
    }()
    
    private lazy var settingsController: UIViewController = {
        let result = TestTabbarChildController()
        result.title = FW.localized("settingTitle")
        return result
    }()
    
    private var childController: UIViewController?
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        homeButton.contentEdgeInsets = UIEdgeInsets(top: FW.isLandscape ? 2 : 8, left: 8, bottom: FW.isLandscape ? 2 : 8, right: 8)
        homeButton.fw.setImageEdge(FW.isLandscape ? .left : .top, spacing: FW.isLandscape ? 4 : 2)
        testButton.contentEdgeInsets = homeButton.contentEdgeInsets
        testButton.fw.setImageEdge(FW.isLandscape ? .left : .top, spacing: FW.isLandscape ? 4 : 2)
        settingsButton.contentEdgeInsets = homeButton.contentEdgeInsets
        settingsButton.fw.setImageEdge(FW.isLandscape ? .left : .top, spacing: FW.isLandscape ? 4 : 2)
    }
    
    func setupSubviews() {
        view.addSubview(childView)
        view.addSubview(tabBarView)
        childView.fw.layoutChain.left().right().top()
        tabBarView.fw.layoutChain.left().right().bottom().top(toViewBottom: childView)
    }
    
    func setupLayout() {
        fw.navigationBarHidden = true
        onButtonClicked(homeButton)
    }
    
    @objc func onButtonClicked(_ sender: UIButton) {
        if let child = childController {
            fw.removeChildViewController(child)
        }
        
        var child: UIViewController
        if sender.tag == 1 {
            homeButton.tintColor = AppTheme.textColor
            testButton.tintColor = AppTheme.textColor.withAlphaComponent(0.6)
            settingsButton.tintColor = AppTheme.textColor.withAlphaComponent(0.6)
            
            child = homeController
        } else if sender.tag == 2 {
            homeButton.tintColor = AppTheme.textColor.withAlphaComponent(0.6)
            testButton.tintColor = AppTheme.textColor
            settingsButton.tintColor = AppTheme.textColor.withAlphaComponent(0.6)
            
            child = testController
        } else {
            homeButton.tintColor = AppTheme.textColor.withAlphaComponent(0.6)
            testButton.tintColor = AppTheme.textColor.withAlphaComponent(0.6)
            settingsButton.tintColor = AppTheme.textColor
            
            child = settingsController
        }
        fw.addChildViewController(child, in: childView)
    }
    
}

class TestTabbarChildController: UIViewController, ViewControllerProtocol {
    private lazy var navigationView: ToolbarView = {
        let result = ToolbarView(type: .navBar)
        result.backgroundColor = AppTheme.barColor
        result.tintColor = AppTheme.textColor
        result.menuView.leftButton = ToolbarButton(object: Icon.backImage, block: { sender in
            Navigator.closeViewController(animated: true)
        })
        return result
    }()
    
    override var title: String? {
        didSet {
            navigationView.menuView.title = title
        }
    }
    
    func setupSubviews() {
        fw.navigationBarHidden = true
        
        view.backgroundColor = UIColor.fw.randomColor
        view.addSubview(navigationView)
        navigationView.fw.layoutChain.left().right().top()
        view.fw.addTapGesture { [weak self] sender in
            let viewController = TestTabbarChildController()
            var title = FW.safeString(self?.title)
            if let index = title.firstIndex(of: "-") {
                let count = Int(title.suffix(from: title.index(index, offsetBy: 1))) ?? 0
                title = "\(title.prefix(upTo: index))-\(count + 1)"
            } else {
                title = "\(title)-1"
            }
            viewController.title = title
            Navigator.push(viewController, animated: true)
        }
    }
}

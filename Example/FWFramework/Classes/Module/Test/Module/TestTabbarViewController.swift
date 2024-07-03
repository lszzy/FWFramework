//
//  TestTabbarViewController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestTabbarViewController: UIViewController, ViewControllerProtocol {
    
    private lazy var childView: UIView = {
        let result = UIView()
        return result
    }()
    
    private lazy var tabBarView: ToolbarView = {
        let result = ToolbarView(type: .tabBar)
        result.backgroundColor = AppTheme.barColor
        result.tintColor = AppTheme.textColor
        result.menuView.verticalOverflow = true
        result.menuView.leftButton = homeButton
        result.menuView.centerButton = testButton
        result.menuView.rightButton = settingsButton
        return result
    }()
    
    private lazy var homeButton: ToolbarButton = {
        let result = ToolbarButton(image: APP.iconImage("zmdi-var-home", 26), title: APP.localized("homeTitle"))
        result.titleLabel?.font = APP.font(10)
        result.app.addTouch(target: self, action: #selector(onButtonClicked(_:)))
        result.tag = 1
        return result
    }()
    
    private lazy var testButton: TestTabbarViewButton = {
        let result = TestTabbarViewButton(image: Icon.iconImage("zmdi-var-toys", size: 50)?.app.image(insets: UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10), color: nil), title: APP.localized("testTitle"))
        result.titleLabel?.font = APP.font(10)
        result.imageView?.backgroundColor = AppTheme.barColor
        result.imageView?.layer.cornerRadius = 35
        result.app.addTouch(target: self, action: #selector(onButtonClicked(_:)))
        result.tag = 2
        return result
    }()
    
    private lazy var settingsButton: ToolbarButton = {
        let result = ToolbarButton(image: APP.icon("zmdi-var-settings", 26)?.image, title: APP.localized("settingTitle"))
        result.titleLabel?.font = APP.font(10)
        result.app.addTouch(target: self, action: #selector(onButtonClicked(_:)))
        result.tag = 3
        return result
    }()
    
    private lazy var homeController: UIViewController = {
        let result = TestTabbarViewChildController()
        result.title = APP.localized("homeTitle")
        return result
    }()
    
    private lazy var testController: UIViewController = {
        let result = TestTabbarViewChildController()
        result.title = APP.localized("testTitle")
        return result
    }()
    
    private lazy var settingsController: UIViewController = {
        let result = TestTabbarViewChildController()
        result.title = APP.localized("settingTitle")
        return result
    }()
    
    private var childController: UIViewController?
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        homeButton.contentEdgeInsets = UIEdgeInsets(top: APP.isLandscape ? 2 : 8, left: 8, bottom: APP.isLandscape ? 2 : 8, right: 8)
        homeButton.app.setImageEdge(APP.isLandscape ? .left : .top, spacing: APP.isLandscape ? 4 : 2)
        testButton.contentEdgeInsets = homeButton.contentEdgeInsets
        testButton.app.setImageEdge(APP.isLandscape ? .left : .top, spacing: APP.isLandscape ? 4 : 2)
        settingsButton.contentEdgeInsets = homeButton.contentEdgeInsets
        settingsButton.app.setImageEdge(APP.isLandscape ? .left : .top, spacing: APP.isLandscape ? 4 : 2)
    }
    
    func setupSubviews() {
        view.addSubview(childView)
        view.addSubview(tabBarView)
        childView.app.layoutChain.left().right().top()
        tabBarView.app.layoutChain.left().right().bottom().top(toViewBottom: childView)
    }
    
    func setupLayout() {
        app.navigationBarHidden = true
        onButtonClicked(homeButton)
    }
    
    @objc func onButtonClicked(_ sender: UIButton) {
        if let child = childController {
            app.removeChild(child)
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
        app.addChild(child, in: childView)
    }
    
}

class TestTabbarViewButton: ToolbarButton {
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let imageView = imageView else {
            return super.point(inside: point, with: event)
        }
        
        if (self.bounds.contains(point) && point.y >= imageView.bounds.size.height / 2.0) {
            return true
        }
        
        let p = CGPoint(x: point.x - imageView.frame.origin.x, y: point.y - imageView.frame.origin.y)
        let result = sqrt(pow(imageView.bounds.size.width / 2.0 - p.x, 2) + pow(imageView.bounds.size.height / 2.0 - p.y, 2)) < imageView.bounds.size.width / 2.0
        return result
    }
    
}

class TestTabbarViewChildController: UIViewController, ViewControllerProtocol {
    
    private lazy var navigationView: ToolbarView = {
        let result = ToolbarView(type: .navBar)
        result.backgroundColor = AppTheme.barColor
        result.tintColor = AppTheme.textColor
        result.menuView.leftButton = ToolbarButton(object: Icon.backImage, block: { sender in
            Navigator.close(animated: true)
        })
        return result
    }()
    
    override var title: String? {
        didSet {
            navigationView.menuView.title = title
        }
    }
    
    func setupSubviews() {
        app.navigationBarHidden = true
        
        view.backgroundColor = UIColor.app.randomColor
        view.addSubview(navigationView)
        navigationView.app.layoutChain.left().right().top()
        view.app.addTapGesture { [weak self] sender in
            let viewController = TestTabbarViewChildController()
            var title = APP.safeString(self?.title)
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

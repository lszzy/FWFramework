//
//  TestBadgeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/21.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestBadgeController: UIViewController, ViewControllerProtocol {
    
    func didInitialize() {
        hidesBottomBarWhenPushed = false
        fw.extendedLayoutEdge = .bottom
    }
    
    func setupNavbar() {
        fw.tabBarHidden = false
        fw.setLeftBarItem(Icon.backImage, target: self, action: #selector(onClose))
        var badgeView = BadgeView(badgeStyle: .dot)
        navigationItem.leftBarButtonItem?.fw.showBadgeView(badgeView)
        
        let rightItem = UIBarButtonItem.fw.item(object: Icon.backImage, target: self, action: #selector(onClick(_:)))
        badgeView = BadgeView(badgeStyle: .small)
        rightItem.fw.showBadgeView(badgeView, badgeValue: "1")
        
        let customView = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        customView.backgroundColor = AppTheme.textColor
        let customItem = UIBarButtonItem.fw.item(object: customView, target: self, action: #selector(onClick(_:)))
        badgeView = BadgeView(badgeStyle: .small)
        customItem.fw.showBadgeView(badgeView, badgeValue: "1")
        navigationItem.rightBarButtonItems = [rightItem, customItem]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        var badgeView = BadgeView(badgeStyle: .dot)
        tabBarController?.tabBar.items?[0].fw.showBadgeView(badgeView)
        badgeView = BadgeView(badgeStyle: .small)
        tabBarController?.tabBar.items?[1].fw.showBadgeView(badgeView, badgeValue: "99")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.items?[0].fw.hideBadgeView()
        tabBarController?.tabBar.items?[1].fw.hideBadgeView()
    }
    
    func setupSubviews() {
        var view = UIView(frame: CGRect(x: 20, y: 20, width: 50, height: 50))
        view.backgroundColor = AppTheme.textColor
        var badgeView = BadgeView(badgeStyle: .dot)
        view.fw.showBadgeView(badgeView)
        self.view.addSubview(view)
        
        view = UIView(frame: CGRect(x: 20, y: 90, width: 50, height: 50))
        view.backgroundColor = AppTheme.textColor
        badgeView = BadgeView(badgeStyle: .small)
        view.fw.showBadgeView(badgeView, badgeValue: "9")
        self.view.addSubview(view)
        
        view = UIView(frame: CGRect(x: 90, y: 90, width: 50, height: 50))
        view.backgroundColor = AppTheme.textColor
        badgeView = BadgeView(badgeStyle: .small)
        view.fw.showBadgeView(badgeView, badgeValue: "99")
        self.view.addSubview(view)
        
        view = UIView(frame: CGRect(x: 160, y: 90, width: 50, height: 50))
        view.backgroundColor = AppTheme.textColor
        badgeView = BadgeView(badgeStyle: .small)
        view.fw.showBadgeView(badgeView, badgeValue: "99+")
        self.view.addSubview(view)
        
        view = UIView(frame: CGRect(x: 20, y: 160, width: 50, height: 50))
        view.backgroundColor = AppTheme.textColor
        badgeView = BadgeView(badgeStyle: .big)
        view.fw.showBadgeView(badgeView, badgeValue: "9")
        self.view.addSubview(view)
        
        view = UIView(frame: CGRect(x: 90, y: 160, width: 50, height: 50))
        view.backgroundColor = AppTheme.textColor
        badgeView = BadgeView(badgeStyle: .big)
        view.fw.showBadgeView(badgeView, badgeValue: "99")
        self.view.addSubview(view)
        
        view = UIView(frame: CGRect(x: 160, y: 160, width: 50, height: 50))
        view.backgroundColor = AppTheme.textColor
        badgeView = BadgeView(badgeStyle: .big)
        view.fw.showBadgeView(badgeView, badgeValue: "99+")
        self.view.addSubview(view)
    }
    
    override var shouldPopController: Bool {
        onClose()
        return false
    }
    
    @objc func onClose() {
        fw.showConfirm(title: nil, message: "是否关闭") { [weak self] in
            self?.fw.close()
        }
    }
    
    @objc func onClick(_ sender: UIBarButtonItem) {
        sender.fw.hideBadgeView()
    }
    
}

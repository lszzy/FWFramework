//
//  TestPopupController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestPopupController: UIViewController, ViewControllerProtocol, PopupMenuDelegate, UITextFieldDelegate {
    
    let titles: [String] = ["修改", "删除", "扫一扫", "付款"]
    let iconPhone: UIImage = APP.iconImage("zmdi-var-smartphone-iphone", 24)!
    let icons: [UIImage] = [APP.iconImage("zmdi-var-edit", 24)!, APP.iconImage("zmdi-var-delete", 24)!, APP.iconImage("zmdi-var-smartphone-iphone", 24)!, APP.iconImage("zmdi-var-card", 24)!]
    
    var popupMenu: PopupMenu?
    
    private lazy var textField: UITextField = {
        let result = UITextField()
        result.placeholder = "我是输入框"
        result.textColor = AppTheme.textColor
        result.app.setBorderColor(AppTheme.borderColor, width: 0.5, cornerRadius: 5)
        result.delegate = self
        return result
    }()
    
    private lazy var customLabel: UILabel = {
        let result = UILabel.app.label(font: UIFont.app.font(ofSize: 16), textColor: AppTheme.textColor, text: "我是自定义标签")
        result.backgroundColor = AppTheme.cellColor
        return result
    }()
    
    private lazy var titleView: ToolbarTitleView = {
        let result = ToolbarTitleView()
        result.alignmentLeft = true
        result.isExpandedSize = true
        return result
    }()
    
    func setupNavbar() {
        navigationItem.titleView = titleView
        app.addRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { _ in
            UIWindow.app.showMessage(text: "点击了刷新按钮")
        }
        app.addRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { _ in
            UIWindow.app.showMessage(text: "点击了动作按钮")
        }
    }
    
    func setupSubviews() {
        var button = UIButton.app.button(image: iconPhone)
        button.app.addTouch(target: self, action: #selector(self.onPopupClick(_:)))
        view.addSubview(button)
        button.app.layoutChain
            .left(10)
            .top(toSafeArea: 10)
            .size(CGSize(width: 44, height: 44))
        
        button = UIButton.app.button(image: iconPhone)
        button.app.addTouch(target: self, action: #selector(self.onPopupClick(_:)))
        view.addSubview(button)
        button.app.layoutChain
            .right(10)
            .top(toSafeArea: 10)
            .size(CGSize(width: 44, height: 44))
        
        button = UIButton.app.button(image: iconPhone)
        button.app.addTouch(target: self, action: #selector(self.onPopupClick(_:)))
        view.addSubview(button)
        button.app.layoutChain
            .left(10)
            .bottom(10)
            .size(CGSize(width: 44, height: 44))
        
        button = UIButton.app.button(image: iconPhone)
        button.app.addTouch(target: self, action: #selector(self.onPopupClick(_:)))
        view.addSubview(button)
        button.app.layoutChain
            .right(10)
            .bottom(10)
            .size(CGSize(width: 44, height: 44))
        
        view.addSubview(textField)
        textField.app.layoutChain
            .left(50)
            .right(50)
            .top(toSafeArea: 200)
            .height(45)
        
        view.addSubview(customLabel)
        customLabel.app.layoutChain
            .centerX()
            .top(toViewBottom: textField, offset: 50)
            .size(CGSize(width: 200, height: 50))
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    @objc func onPopupClick(_ sender: UIButton) {
        PopupMenu.showRely(on: sender, titles: titles, icons: icons, menuWidth: 120) { [weak self] popupMenu in
            popupMenu.delegate = self
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.randomElement() else { return }
        let point = touch.location(in: view.window)
        let frame = customLabel.superview?.convert(customLabel.frame, to: view.window) ?? .zero
        if frame.contains(point) {
            showCustomPopupMenu(point)
        } else {
            showDarkPopupMenu(point)
        }
    }
    
    private func showCustomPopupMenu(_ point: CGPoint) {
        PopupMenu.show(at: point, titles: titles, icons: nil, menuWidth: 110) { popupMenu in
            popupMenu.dismissOnSelected = true
            popupMenu.showsShadow = true
            popupMenu.delegate = self
            popupMenu.arrowHeight = 0
            popupMenu.separatorColor = UIColor.red
            popupMenu.separatorInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            popupMenu.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
            popupMenu.titleEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
            // popupMenu.tag = 100
            popupMenu.rectCorner = [.topLeft, .topRight]
        }
    }
    
    private func showDarkPopupMenu(_ point: CGPoint) {
        PopupMenu.show(at: point, titles: titles, icons: nil, menuWidth: 110) { popupMenu in
            popupMenu.dismissOnSelected = false
            popupMenu.showsShadow = true
            popupMenu.delegate = self
            popupMenu.offset = 10
            popupMenu.textColor = UIColor.lightGray
            popupMenu.backColor = UIColor(red: 0.25, green: 0.27, blue: 0.29, alpha: 1)
            popupMenu.rectCorner = [.bottomLeft, .bottomRight]
        }
    }
    
    func popupMenu(_ popupMenu: PopupMenu, didSelectedAt index: Int) {
        app.showMessage(text: "点击了 \(popupMenu.titles?[index] ?? "")")
    }
    
    func popupMenuBeganDismiss(_ popupMenu: PopupMenu) {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }
    
    func popupMenu(_ popupMenu: PopupMenu, cellForRowAt index: Int) -> UITableViewCell? {
        if popupMenu.tag != 100 { return nil }
        
        var cell = popupMenu.tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        cell?.textLabel?.text = titles[index]
        cell?.imageView?.image = icons[index]
        return cell
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        popupMenu = PopupMenu.showRely(on: textField, titles: ["密码必须为数字、大写字母、小写字母和特殊字符中至少三种的组合，长度不少于8且不大于20"], icons: nil, menuWidth: textField.bounds.width, otherSettings: { popupMenu in
            popupMenu.delegate = self
            popupMenu.showsMaskView = false
            popupMenu.priorityDirection = .bottom
            popupMenu.maxVisibleCount = 1
            popupMenu.itemHeight = 60
            popupMenu.borderWidth = 1
            popupMenu.fontSize = 12
            popupMenu.dismissOnTouchOutside = true
            popupMenu.dismissOnSelected = false
            popupMenu.borderColor = .brown
            popupMenu.textColor = .brown
            popupMenu.animationManager.style = .fade
            popupMenu.animationManager.duration = 0.25
        })
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        popupMenu?.dismiss()
        return true
    }
    
}

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
        app.addRightBarItem(APP.iconImage("zmdi-var-help-outline", 24)) { [weak self] _ in
            self?.showGuide()
        }
        app.addRightBarItem(UIBarButtonItem.SystemItem.action) { [weak self] _ in
            let customView = UIImageView()
            customView.image = UIImage.app.appIconImage()
            customView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            customView.isUserInteractionEnabled = true

            let popupMenu = PopupMenu.show(at: self?.view.center ?? .zero, customView: customView, menuWidth: customView.frame.width) { popupMenu in
                popupMenu.dismissOnTouchOutside = false
                popupMenu.arrowHeight = 0
            }
            customView.app.addTapGesture { _ in
                popupMenu.dismiss()
            }
        }
    }

    func setupSubviews() {
        var button = UIButton.app.button(image: iconPhone)
        button.app.addTouch(target: self, action: #selector(onPopupClick(_:)))
        view.addSubview(button)
        button.app.layoutChain
            .left(10)
            .top(toSafeArea: 10)
            .size(CGSize(width: 44, height: 44))

        button = UIButton.app.button(image: iconPhone)
        button.app.addTouch(target: self, action: #selector(onPopupClick(_:)))
        view.addSubview(button)
        button.app.layoutChain
            .right(10)
            .top(toSafeArea: 10)
            .size(CGSize(width: 44, height: 44))

        button = UIButton.app.button(image: iconPhone)
        button.app.addTouch(target: self, action: #selector(onPopupClick(_:)))
        view.addSubview(button)
        button.app.layoutChain
            .left(10)
            .bottom(10)
            .size(CGSize(width: 44, height: 44))

        button = UIButton.app.button(image: iconPhone)
        button.app.addTouch(target: self, action: #selector(onPopupClick(_:)))
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

    func showGuide() {
        var items: [GuideViewItem] = []
        let textItem = GuideViewItem(sourceView: textField, text: "我是输入框的引导")
        items.append(textItem)
        let labelItem = GuideViewItem(sourceView: customLabel, image: UIImage.app.appIconImage())
        items.append(labelItem)
        let rectItem = GuideViewItem(rect: CGRect(x: 10, y: app.topBarHeight + 10, width: 44, height: 44), text: NSAttributedString(string: "我是最左侧的引导", attributes: [.font: UIFont.app.font(ofSize: 16), .foregroundColor: UIColor.yellow]))
        items.append(rectItem)

        let vc = GuideViewController(items: items)
        vc.arrowImage = UIImage(named: "guideArrow")
        vc.indexWillChangeBlock = { index, _ in
            print("showGuide indexWillChangeBlock: \(index)")
        }
        vc.indexDidChangeBlock = { index, _ in
            print("showGuide indexDidChangeBlock: \(index)")
        }
        vc.show(from: self) {
            print("showGuide completion")
        }
    }

    @objc func onPopupClick(_ sender: UIButton) {
        PopupMenu.show(relyOn: sender, titles: titles, icons: icons, menuWidth: 120) { [weak self] popupMenu in
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
            popupMenu.menuBackgroundColor = UIColor(red: 0.25, green: 0.27, blue: 0.29, alpha: 1)
            popupMenu.rectCorner = [.bottomLeft, .bottomRight]
        }
    }

    func popupMenu(_ popupMenu: PopupMenu, didSelectAt index: Int) {
        app.showMessage(text: "点击了 \(popupMenu.titles[index])")
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
        popupMenu = PopupMenu.show(relyOn: textField, titles: ["密码必须为数字、大写字母、小写字母和特殊字符中至少三种的组合，长度不少于8且不大于20"], icons: nil, menuWidth: textField.bounds.width, customize: { popupMenu in
            popupMenu.delegate = self
            popupMenu.maskViewColor = .clear
            popupMenu.priorityDirection = .bottom
            popupMenu.maxVisibleCount = 1
            popupMenu.itemHeight = 60
            popupMenu.borderWidth = 1
            popupMenu.font = UIFont.systemFont(ofSize: 12)
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

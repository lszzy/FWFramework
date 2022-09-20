//
//  TestAlertController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestAlertController: UIViewController, TableViewControllerProtocol {
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupNavbar() {
        fw.setRightBarItem("切换插件") { _ in
            if PluginManager.loadPlugin(AlertPlugin.self) != nil {
                PluginManager.unloadPlugin(AlertPlugin.self)
                PluginManager.unregisterPlugin(AlertPlugin.self)
            } else {
                PluginManager.registerPlugin(AlertPlugin.self, with: AlertControllerImpl.self)
            }
        }
    }
    
    func setupSubviews() {
        tableData.addObjects(from: [
            ["警告框(简单)", "onAlert1"],
            ["警告框(详细)", "onAlert2"],
            ["确认框(简单)", "onConfirm1"],
            ["确认框(详细)", "onConfirm2"],
            ["输入框(简单)", "onPrompt1"],
            ["输入框(详细)", "onPrompt2"],
            ["输入框(复杂)", "onPrompt3"],
            ["警告框(容错)", "onAlertE"],
            ["操作表(简单)", "onSheet1"],
            ["操作表(详细)", "onSheet2"],
            ["弹出框(完整)", "onAlertF"],
            ["弹出框(头部视图)", "onAlertH"],
            ["弹出框(整个视图)", "onAlertV"],
            ["警告框(样式)", "onAlertA"],
            ["操作表(样式)", "onSheetA"],
            ["警告框(优先)", "onAlertP"],
            ["操作表(优先)", "onSheetP"],
            ["关闭弹出框", "onCloseA"],
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(tableView: tableView)
        let rowData = tableData.object(at: indexPath.row) as! [String]
        cell.textLabel?.text = rowData[0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData.object(at: indexPath.row) as! [String]
        fw.invokeMethod(NSSelectorFromString(rowData[1]))
    }
    
}

@objc extension TestAlertController {
    
    func onAlert1() {
        fw.showAlert(title: "警告框标题", message: "警告框消息", cancel: nil) {
            UIWindow.fw.showMessage(text: "顶部控制器：\(String(describing: Navigator.topPresentedController))")
        }
    }
    
    func onAlert2() {
        fw.showAlert(title: "警告框标题", message: "警告框消息", style: .default, cancel: nil, actions: ["按钮1", "按钮2"]) { index in
            UIWindow.fw.showMessage(text: "点击的按钮index: \(index)")
        } cancelBlock: {
            UIWindow.fw.showMessage(text: "点击了取消按钮")
        }
    }
    
    func onConfirm1() {
        fw.showConfirm(title: "确认框标题", message: "确认框消息", cancel: nil, confirm: nil) {
            UIWindow.fw.showMessage(text: "点击了确定按钮")
        }
    }
    
    func onConfirm2() {
        fw.showConfirm(title: "确认框标题", message: "确认框消息", cancel: nil, confirm: "我是很长的确定按钮") {
            UIWindow.fw.showMessage(text: "点击了确定按钮")
        } cancelBlock: {
            UIWindow.fw.showMessage(text: "点击了取消按钮")
        }
    }
    
    func onPrompt1() {
        fw.showPrompt(title: "输入框标题", message: "输入框消息", cancel: nil, confirm: nil) { text in
            UIWindow.fw.showMessage(text: "输入内容：\(text)")
        }
    }
    
    func onPrompt2() {
        fw.showPrompt(title: "输入框标题", message: "输入框消息", cancel: nil, confirm: nil, promptBlock: { textField in
            textField.placeholder = "请输入密码"
            textField.isSecureTextEntry = true
        }) { text in
            UIWindow.fw.showMessage(text: "输入内容：\(text)")
        } cancelBlock: {
            UIWindow.fw.showMessage(text: "点击了取消按钮")
        }
    }
    
    func onPrompt3() {
        fw.showPrompt(title: "输入框标题", message: "输入框消息", cancel: nil, confirm: nil, promptCount: 2, promptBlock: { textField, index in
            if index == 0 {
                textField.placeholder = "请输入用户名"
                textField.isSecureTextEntry = false
            } else {
                textField.placeholder = "请输入密码"
                textField.isSecureTextEntry = true
            }
        }) { values in
            UIWindow.fw.showMessage(text: "输入内容：\(values)")
        } cancelBlock: {
            UIWindow.fw.showMessage(text: "点击了取消按钮")
        }
    }
    
    func onAlertE() {
        fw.showAlert(title: nil, message: nil, cancel: nil) {
            UIWindow.fw.showMessage(text: "顶部控制器：\(String(describing: Navigator.topPresentedController))")
        }
    }
    
    func onSheet1() {
        fw.showSheet(title: nil, message: nil, cancel: "取消", actions: ["操作1"], currentIndex: -1) { index in
            UIWindow.fw.showMessage(text: "点击的操作index: \(index)")
        }
    }
    
    func onSheet2() {
        fw.showSheet(title: "操作表标题", message: "操作表消息", cancel: "取消", actions: ["操作1", "操作2", "操作3"], currentIndex: 1) { index in
            UIWindow.fw.showMessage(text: "点击的操作index: \(index)")
        } cancelBlock: {
            UIWindow.fw.showMessage(text: "点击了取消操作")
        }
    }
    
    func onAlertF() {
        fw.showAlert(title: "请输入账号信息，我是很长很长很长很长很长很长的标题", message: "账户信息必填，我是很长很长很长很长很长很长的消息", style: .default, cancel: "取消", actions: ["重试", "高亮", "禁用", "确定"], promptCount: 2) { textField, index in
            if index == 0 {
                textField.placeholder = "请输入用户名"
                textField.isSecureTextEntry = false
            } else {
                textField.placeholder = "请输入密码"
                textField.isSecureTextEntry = true
            }
        } actionBlock: { [weak self] values, index in
            if index == 0 {
                self?.onAlertF()
            } else {
                UIWindow.fw.showMessage(text: "输入内容：\(values)")
            }
        } cancelBlock: {
            UIWindow.fw.showMessage(text: "点击了取消按钮")
        } customBlock: { param in
            if let alert = param as? UIAlertController {
                alert.preferredAction = alert.actions[1]
                alert.actions[2].isEnabled = false
            } else if let alert = param as? AlertController {
                alert.preferredAction = alert.actions[1]
                alert.actions[2].isEnabled = false
                alert.image = UIImage.fw.appIconImage()
            }
        }
    }
    
    func onAlertH() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        headerView.backgroundColor = .white
        
        AlertControllerImpl.shared.viewController(self, showAlertWith: .alert, headerView: headerView, cancel: "取消", actions: ["确定"]) { index in
            UIWindow.fw.showMessage(text: "点击了确定按钮")
        } cancel: {
            UIWindow.fw.showMessage(text: "点击了取消按钮")
        }
    }
    
    func onAlertV() {
        let alertView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        alertView.backgroundColor = .white
        alertView.fw.addTapGesture { [weak self] _ in
            self?.presentedViewController?.dismiss(animated: true)
        }
        
        AlertControllerImpl.shared.viewController(self, showAlertWith: .alert, headerView: alertView, cancel: nil, actions: nil, actionBlock: nil, cancel: nil) { param in
            if let alert = param as? AlertController {
                alert.tapBackgroundViewDismiss = true
            }
        }
    }
    
    func onAlertA() {
        let title = NSMutableAttributedString()
        let attachment = NSTextAttachment()
        attachment.image = UIImage.fw.appIconImage()?.withRenderingMode(.alwaysOriginal)
        attachment.bounds = CGRect(x: 0, y: -20, width: 30, height: 30)
        title.append(NSAttributedString(attachment: attachment))
        var attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.fw.boldFont(ofSize: 17),
            .foregroundColor: UIColor.red,
        ]
        title.append(NSAttributedString(string: "\n\n警告框标题", attributes: attrs))
        
        let message = NSMutableAttributedString()
        attrs = [
            .font: UIFont.fw.font(ofSize: 15),
            .foregroundColor: UIColor.green,
        ]
        message.append(NSAttributedString(string: "警告框消息", attributes: attrs))
        
        fw.showAlert(title: title, message: message, style: .default, cancel: nil, actions: ["按钮1", "按钮2", "按钮3", "按钮4"], actionBlock: nil, cancelBlock: nil)
    }
    
    func onSheetA() {
        let title = NSMutableAttributedString()
        let attachment = NSTextAttachment()
        attachment.image = UIImage.fw.appIconImage()?.withRenderingMode(.alwaysOriginal)
        attachment.bounds = CGRect(x: 0, y: -20, width: 30, height: 30)
        title.append(NSAttributedString(attachment: attachment))
        var attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.fw.boldFont(ofSize: 17),
            .foregroundColor: UIColor.red,
        ]
        title.append(NSAttributedString(string: "\n\n操作表标题", attributes: attrs))
        
        let message = NSMutableAttributedString()
        attrs = [
            .font: UIFont.fw.font(ofSize: 15),
            .foregroundColor: UIColor.green,
        ]
        message.append(NSAttributedString(string: "操作表消息", attributes: attrs))
        
        fw.showSheet(title: title, message: message, cancel: "取消", actions: ["操作1", "操作2", "操作3", "操作4", "操作5", "操作6", "操作7", "操作8", "操作9", "操作10"], currentIndex: -1) { index in
            UIWindow.fw.showMessage(text: "点击的操作index: \(index)")
        }
    }
    
    func onAlertP() {
        fw.showAlert(title: "高优先级", message: "警告框消息", cancel: nil) { [weak self] in
            self?.fw.showAlert(title: "普通优先级", message: "警告框消息", cancel: nil, cancelBlock: {
                self?.fw.showAlert(title: "低优先级", message: "警告框消息", cancel: nil, cancelBlock: nil)
            })
        }
    }
    
    func onSheetP() {
        fw.showSheet(title: "高优先级", message: "操作表消息", cancel: nil) { [weak self] in
            self?.fw.showSheet(title: "普通优先级", message: "操作表消息", cancel: nil, cancelBlock: {
                self?.fw.showSheet(title: "低优先级", message: "操作表消息", cancel: nil, cancelBlock: nil)
            })
        }
    }
    
    func onCloseA() {
        fw.showAlert(title: nil, message: "我将在两秒后自动关闭")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Navigator.topPresentedController?.fw.showAlert(title: nil, message: "我将在一秒后自动关闭")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.fw.hideAlert(animated: true)
        }
    }
    
}

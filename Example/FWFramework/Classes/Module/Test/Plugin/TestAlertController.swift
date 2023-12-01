//
//  TestAlertController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestAlertController: UIViewController, TableViewControllerProtocol {
    
    typealias TableElement = [String]
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: ["切换按钮样式"], actionBlock: { index in
                if AlertAppearance.appearance.preferredActionColor == nil {
                    AlertAppearance.appearance.preferredActionColor = UIColor.red
                    AlertAppearance.appearance.preferredActionBlock = { vc in
                        return vc.actions.first
                    }
                    AlertControllerAppearance.appearance.preferredActionColor = UIColor.red
                    AlertControllerAppearance.appearance.preferredActionBlock = { vc in
                        return vc.actions.first
                    }
                } else {
                    AlertAppearance.appearance.preferredActionColor = nil
                    AlertAppearance.appearance.preferredActionBlock = nil
                    AlertControllerAppearance.appearance.preferredActionColor = nil
                    AlertControllerAppearance.appearance.preferredActionBlock = nil
                }
            })
        }
    }
    
    func setupSubviews() {
        tableData.append(contentsOf: [
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
            ["操作表(多个)", "onSheetM"],
            ["关闭弹出框", "onCloseA"],
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let rowData = tableData[indexPath.row]
        cell.textLabel?.text = rowData[0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData[indexPath.row]
        app.invokeMethod(NSSelectorFromString(rowData[1]))
    }
    
}

@objc extension TestAlertController {
    
    func onAlert1() {
        app.showAlert(title: "警告框标题", message: "警告框消息", cancel: nil) {
            UIWindow.app.showMessage(text: "顶部控制器：\(String(describing: Navigator.topPresentedController))")
        }
    }
    
    func onAlert2() {
        app.showAlert(title: "警告框标题", message: "警告框消息", style: .default, cancel: nil, actions: ["按钮1", "按钮2"]) { index in
            UIWindow.app.showMessage(text: "点击的按钮index: \(index)")
        } cancelBlock: {
            UIWindow.app.showMessage(text: "点击了取消按钮")
        }
    }
    
    func onConfirm1() {
        app.showConfirm(title: "确认框标题", message: "确认框消息", cancel: nil, confirm: nil) {
            UIWindow.app.showMessage(text: "点击了确定按钮")
        }
    }
    
    func onConfirm2() {
        app.showConfirm(title: "确认框标题", message: "确认框消息", cancel: nil, confirm: "我是很长的确定按钮") {
            UIWindow.app.showMessage(text: "点击了确定按钮")
        } cancelBlock: {
            UIWindow.app.showMessage(text: "点击了取消按钮")
        }
    }
    
    func onPrompt1() {
        app.showPrompt(title: "输入框标题", message: "输入框消息", cancel: nil, confirm: nil) { text in
            UIWindow.app.showMessage(text: "输入内容：\(text)")
        }
    }
    
    func onPrompt2() {
        app.showPrompt(title: "输入框标题", message: "输入框消息", cancel: nil, confirm: nil, promptBlock: { textField in
            textField.placeholder = "请输入密码"
            textField.isSecureTextEntry = true
        }) { text in
            UIWindow.app.showMessage(text: "输入内容：\(text)")
        } cancelBlock: {
            UIWindow.app.showMessage(text: "点击了取消按钮")
        }
    }
    
    func onPrompt3() {
        app.showPrompt(title: "输入框标题", message: "输入框消息", cancel: nil, confirm: nil, promptCount: 2, promptBlock: { textField, index in
            if index == 0 {
                textField.placeholder = "请输入用户名"
                textField.isSecureTextEntry = false
            } else {
                textField.placeholder = "请输入密码"
                textField.isSecureTextEntry = true
            }
        }) { values in
            UIWindow.app.showMessage(text: "输入内容：\(values)")
        } cancelBlock: {
            UIWindow.app.showMessage(text: "点击了取消按钮")
        }
    }
    
    func onAlertE() {
        app.showAlert(title: nil, message: nil, cancel: nil) {
            UIWindow.app.showMessage(text: "顶部控制器：\(String(describing: Navigator.topPresentedController))")
        }
    }
    
    func onSheet1() {
        app.showSheet(title: nil, message: nil, cancel: "取消", actions: ["操作1"], currentIndex: -1) { index in
            UIWindow.app.showMessage(text: "点击的操作index: \(index)")
        }
    }
    
    func onSheet2() {
        app.showSheet(title: "操作表标题", message: "操作表消息", cancel: "取消", actions: ["操作1", "操作2", "操作3"], currentIndex: 1) { index in
            UIWindow.app.showMessage(text: "点击的操作index: \(index)")
        } cancelBlock: {
            UIWindow.app.showMessage(text: "点击了取消操作")
        }
    }
    
    func onAlertF() {
        app.showAlert(title: "请输入账号信息，我是很长很长很长很长很长很长的标题", message: "账户信息必填，我是很长很长很长很长很长很长的消息", style: .default, cancel: "取消", actions: ["重试", "高亮", "禁用", "确定"], promptCount: 2) { textField, index in
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
                UIWindow.app.showMessage(text: "输入内容：\(values)")
            }
        } cancelBlock: {
            UIWindow.app.showMessage(text: "点击了取消按钮")
        } customBlock: { param in
            if let alert = param as? UIAlertController {
                alert.preferredAction = alert.actions[1]
                alert.actions[2].isEnabled = false
            } else if let alert = param as? AlertController {
                alert.preferredAction = alert.actions[1]
                alert.actions[2].isEnabled = false
                alert.image = UIImage.app.appIconImage()
            }
        }
    }
    
    func onAlertH() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        headerView.backgroundColor = .white
        
        AlertControllerImpl.shared.showAlert(style: .alert, headerView: headerView, cancel: "取消", actions: ["确定"], actionBlock: { index in
            UIWindow.app.showMessage(text: "点击了确定按钮")
        }, cancelBlock: {
            UIWindow.app.showMessage(text: "点击了取消按钮")
        }, in: self)
    }
    
    func onAlertV() {
        let alertView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        alertView.backgroundColor = .white
        alertView.app.addTapGesture { [weak self] _ in
            self?.presentedViewController?.dismiss(animated: true)
        }
        
        AlertControllerImpl.shared.showAlert(style: .alert, headerView: alertView, cancel: nil, actions: nil, actionBlock: nil, cancelBlock: nil, customBlock: { param in
            if let alert = param as? AlertController {
                alert.tapBackgroundViewDismiss = true
            }
        }, in: self)
    }
    
    func onAlertA() {
        let title = NSMutableAttributedString()
        let attachment = NSTextAttachment()
        attachment.image = UIImage.app.appIconImage()?.withRenderingMode(.alwaysOriginal)
        attachment.bounds = CGRect(x: 0, y: -20, width: 30, height: 30)
        title.append(NSAttributedString(attachment: attachment))
        var attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.app.boldFont(ofSize: 17),
            .foregroundColor: UIColor.red,
        ]
        title.append(NSAttributedString(string: "\n\n警告框标题", attributes: attrs))
        
        let message = NSMutableAttributedString()
        attrs = [
            .font: UIFont.app.font(ofSize: 15),
            .foregroundColor: UIColor.green,
        ]
        message.append(NSAttributedString(string: "警告框消息", attributes: attrs))
        
        app.showAlert(title: title, message: message, style: .default, cancel: nil, actions: ["按钮1", "按钮2", NSAttributedString(string: "按钮3", attributes: [.foregroundColor: UIColor.red]), NSAttributedString(string: "按钮4", attributes: [.foregroundColor: UIColor.green])], actionBlock: nil, cancelBlock: nil)
    }
    
    func onSheetA() {
        let title = NSMutableAttributedString()
        let attachment = NSTextAttachment()
        attachment.image = UIImage.app.appIconImage()?.withRenderingMode(.alwaysOriginal)
        attachment.bounds = CGRect(x: 0, y: -20, width: 30, height: 30)
        title.append(NSAttributedString(attachment: attachment))
        var attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.app.boldFont(ofSize: 17),
            .foregroundColor: UIColor.red,
        ]
        title.append(NSAttributedString(string: "\n\n操作表标题", attributes: attrs))
        
        let message = NSMutableAttributedString()
        attrs = [
            .font: UIFont.app.font(ofSize: 15),
            .foregroundColor: UIColor.green,
        ]
        message.append(NSAttributedString(string: "操作表消息", attributes: attrs))
        
        app.showSheet(title: title, message: message, cancel: "取消", actions: ["操作1", "操作2", NSAttributedString(string: "操作3", attributes: [.foregroundColor: UIColor.red]), NSAttributedString(string: "操作4", attributes: [.foregroundColor: UIColor.green]), "操作5", "操作6", NSAttributedString(string: "操作7", attributes: [.foregroundColor: UIColor.red]), NSAttributedString(string: "操作8", attributes: [.foregroundColor: UIColor.green]), "操作9", "操作10"], currentIndex: -1) { index in
            UIWindow.app.showMessage(text: "点击的操作index: \(index)")
        }
    }
    
    func onAlertP() {
        let taskManager = TaskManager(maxConcurrentTaskCount: 1)
        
        let task = TaskOperation(onMainThread: true, queuePriority: .low) { [weak self] task in
            self?.app.showAlert(title: "低优先级", message: "警告框消息", cancel: nil, cancelBlock: {
                task.finish()
            })
        }
        
        let task2 = TaskOperation(onMainThread: true, queuePriority: .normal) { [weak self] task in
            self?.app.showAlert(title: "普通优先级", message: "警告框消息", cancel: nil, cancelBlock: {
                task.finish()
            })
        }
        
        let task3 = TaskOperation(onMainThread: true, queuePriority: .high) { [weak self] task in
            self?.app.showAlert(title: "高优先级", message: "警告框消息", cancel: nil, cancelBlock: {
                task.finish()
            })
        }
        
        taskManager.addTasks([task, task2, task3])
    }
    
    func onSheetP() {
        let taskManager = TaskManager(maxConcurrentTaskCount: 1, isSuspended: true)
        
        let task = TaskOperation(onMainThread: true, queuePriority: .low) { [weak self] task in
            self?.app.showSheet(title: "低优先级", message: "操作表消息", cancel: nil, cancelBlock: {
                task.finish()
            })
        }
        
        let task2 = TaskOperation(onMainThread: true, queuePriority: .normal) { [weak self] task in
            self?.app.showSheet(title: "普通优先级", message: "操作表消息", cancel: nil, cancelBlock: {
                task.finish()
            })
        }
        
        let task3 = TaskOperation(onMainThread: true, queuePriority: .high) { [weak self] task in
            self?.app.showSheet(title: "高优先级", message: "操作表消息", cancel: nil) {
                task.finish()
            }
        }
        
        taskManager.addTask(task)
        taskManager.addTask(task2)
        taskManager.addTask(task3)
        taskManager.isSuspended = false
    }
    
    func onSheetM() {
        Navigator.topPresentedController?.app.showSheet(title: "第一个操作表", message: nil, cancel: "取消", actions: ["操作"], actionBlock: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Navigator.topPresentedController?.app.showSheet(title: "第二个操作表", message: nil, cancel: "取消", actions: ["操作"], actionBlock: nil)
        }
    }
    
    func onCloseA() {
        app.showAlert(title: nil, message: "我将在两秒后自动关闭")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Navigator.topPresentedController?.app.showAlert(title: nil, message: "我将在一秒后自动关闭")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.app.hideAlert(animated: true)
        }
    }
    
}

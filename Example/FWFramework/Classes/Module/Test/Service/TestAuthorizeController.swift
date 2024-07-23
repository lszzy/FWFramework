//
//  TestAuthorizeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework
import LocalAuthentication

class TestAuthorizeController: UIViewController, TableViewControllerProtocol {

    @StoredValue("biometryPasscode")
    var biometryPasscode: Bool = false
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.action) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: ["跳转设置", (self?.biometryPasscode ?? false) ? "关闭密码验证" : "打开密码验证"], actionBlock: { index in
                if index == 0 {
                    UIApplication.app.openAppSettings()
                } else if index == 1 {
                    self?.biometryPasscode = !(self?.biometryPasscode ?? false)
                }
            })
        }
        
        // 手工修改设置返回页面自动刷新权限，释放时自动移除监听
        app.observeNotification(UIApplication.didBecomeActiveNotification) { [weak self] _ in
            DispatchQueue.app.mainAsync { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
   
    func setupSubviews() {
        let authorizeList: [[Any]] = [
            ["定位(使用中)", AuthorizeType.locationWhenInUse],
            ["定位(始终)", AuthorizeType.locationAlways],
            ["麦克风", AuthorizeType.microphone],
            ["相册", AuthorizeType.photoLibrary],
            ["照相机", AuthorizeType.camera],
            ["联系人", AuthorizeType.contacts],
            ["日历(完全)", AuthorizeType.calendars],
            ["日历(仅写入)", AuthorizeType.calendarsWriteOnly],
            ["提醒", AuthorizeType.reminders],
            ["通知", AuthorizeType.notifications],
            ["广告追踪", AuthorizeType.tracking],
            ["生物识别", AuthorizeType.biometry],
        ]
        tableData.append(contentsOf: authorizeList)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let rowData = tableData[indexPath.row] as! [Any]
        let type = rowData[1] as! AuthorizeType
        
        let manager = AuthorizeManager.manager(type: type)
        let status = manager?.authorizeStatus()
        var typeText = rowData[0] as! String
        var canSelect = false
        if status == .restricted {
            typeText += "受限制"
        } else if status == .authorized {
            typeText += "已开启"
        } else if status == .denied {
            typeText += "已拒绝"
        } else {
            typeText += "未授权"
            canSelect = true
        }
        cell.textLabel?.text = typeText
        cell.accessoryType = canSelect ? .disclosureIndicator : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData[indexPath.row] as! [Any]
        let type = rowData[1] as! AuthorizeType
        
        let manager = AuthorizeManager.manager(type: type)
        if type == .biometry {
            AuthorizeBiometry.shared.policy = biometryPasscode ? .deviceOwnerAuthentication : .deviceOwnerAuthenticationWithBiometrics
            manager?.requestAuthorize({ [weak self] status, error in
                self?.tableView.reloadRows(at: [indexPath], with: .fade)
                if status == .authorized {
                    self?.app.showMessage(text: "验证成功")
                } else {
                    self?.app.showAlert(error: error)
                }
            })
        } else if manager?.authorizeStatus() == .notDetermined {
            manager?.requestAuthorize({ [weak self] _, _ in
                self?.tableView.reloadRows(at: [indexPath], with: .fade)
            })
        } else if type == .notifications {
            self.app.showConfirm(title: "跳转通知设置", message: nil, cancel: "取消", confirm: "设置") {
                UIApplication.app.openAppNotificationSettings()
            }
        }
    }
    
}

//
//  TestAuthorizeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestAuthorizeController: UIViewController, TableViewControllerProtocol {
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupNavbar() {
        fw.setRightBarItem("设置") { _ in
            UIApplication.fw.openAppSettings()
        }
        
        // 手工修改设置返回页面自动刷新权限，释放时自动移除监听
        fw.observeNotification(UIApplication.didBecomeActiveNotification) { [weak self] _ in
            self?.tableView.reloadData()
        }
    }
   
    func setupSubviews() {
        tableData.addObjects(from: [
            ["定位", AuthorizeType.locationWhenInUse],
            ["后台定位", AuthorizeType.locationAlways],
            ["麦克风", AuthorizeType.microphone],
            ["相册", AuthorizeType.photoLibrary],
            ["照相机", AuthorizeType.camera],
            ["联系人", AuthorizeType.contacts],
            ["日历", AuthorizeType.calendars],
            ["提醒", AuthorizeType.reminders],
            ["音乐", AuthorizeType.appleMusic],
            ["通知", AuthorizeType.notifications],
            ["广告追踪", AuthorizeType.tracking],
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(tableView: tableView)
        let rowData = tableData.object(at: indexPath.row) as! NSArray
        let type = rowData.object(at: 1) as! AuthorizeType
        
        let manager = AuthorizeManager.manager(type: type)
        let status = manager?.authorizeStatus()
        var typeText = rowData.object(at: 0) as! String
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
        let rowData = tableData.object(at: indexPath.row) as! NSArray
        let type = rowData.object(at: 1) as! AuthorizeType
        
        let manager = AuthorizeManager.manager(type: type)
        if manager?.authorizeStatus() == .notDetermined {
            manager?.authorize({ [weak self] _ in
                self?.tableView.reloadRows(at: [indexPath], with: .fade)
            })
        } else if type == .notifications {
            self.fw.showConfirm(title: "跳转通知设置", message: nil, cancel: "取消", confirm: "设置") {
                UIApplication.fw.openAppNotificationSettings()
            }
        }
    }
    
}

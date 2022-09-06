//
//  TestNotificationController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/2.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestNotificationController: UIViewController, TableViewControllerProtocol {
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupTableView() {
        tableData.addObjects(from: [
            ["本地通知(不重复，立即)", "onNotification1"],
            ["本地通知(不重复，5秒后)", "onNotification2"],
            ["本地通知(重复，每1分钟)", "onNotification3"],
            ["取消本地通知(批量)", "onNotification4"],
            ["取消本地通知(所有)", "onNotification5"],
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(tableView: tableView)
        let rowData = tableData.object(at: indexPath.row) as! NSArray
        cell.textLabel?.text = rowData.object(at: 0) as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData.object(at: indexPath.row) as! NSArray
        let selector = NSSelectorFromString(rowData.object(at: 1) as! String)
        fw.invokeMethod(selector)
    }
    
}

@objc extension TestNotificationController {
    
    func onNotification1() {
        NotificationManager.shared.registerLocalNotification("test", title: "立即通知", subtitle: nil, body: "body", userInfo: ["id": "test"], badge: 0, soundName: nil, timeInterval: 0, repeats: false) { content in
            // iOS15时效性通知，需entitlements开启配置生效
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }
        }
    }
    
    func onNotification2() {
        NotificationManager.shared.registerLocalNotification("test2", title: "5秒后通知", subtitle: "subtitle", body: "body", userInfo: ["id": "test2"], badge: 1, soundName: "default", timeInterval: 5, repeats: false) { content in
            // iOS15时效性通知，需entitlements开启配置生效
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }
        }
    }
    
    func onNotification3() {
        NotificationManager.shared.registerLocalNotification("test3", title: "重复1分钟通知", subtitle: "subtitle", body: "body", userInfo: ["id": "test3"], badge: 1, soundName: "default", timeInterval: 60, repeats: true)
    }
    
    func onNotification4() {
        NotificationManager.shared.removeLocalNotification(["test", "test2", "test3"])
    }
    
    func onNotification5() {
        NotificationManager.shared.removeAllLocalNotifications()
    }
    
}

//
//  TestEmptyController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestEmptyController: UIViewController, TableViewControllerProtocol {
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }

    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
            self?.app.hideEmptyView()
            self?.tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        view.app.hasEmptyView ? 0 : 6
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let row = indexPath.row
        if row == 0 {
            cell.textLabel?.text = "显示提示语"
        } else if row == 1 {
            cell.textLabel?.text = "显示提示语和详情"
        } else if row == 2 {
            cell.textLabel?.text = "显示图片和提示语"
        } else if row == 3 {
            cell.textLabel?.text = "显示提示语及操作按钮"
        } else if row == 4 {
            cell.textLabel?.text = "显示加载视图"
        } else if row == 5 {
            cell.textLabel?.text = "显示所有视图"
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = indexPath.row
        if row == 0 {
            app.showEmptyView(text: "联系人为空")
        } else if row == 1 {
            app.showEmptyView(text: "联系人为空", detail: "请到设置-隐私查看你的联系人权限设置")
        } else if row == 2 {
            app.showEmptyView(text: "暂无数据", detail: nil, image: UIImage.app.appIconImage())
        } else if row == 3 {
            app.showEmptyView(text: "请求失败", detail: "请检查网络连接", image: nil, action: "重试") { [weak self] _ in
                self?.app.hideEmptyView()
                self?.tableView.reloadData()
            }
        } else if row == 4 {
            app.showEmptyLoading()
        } else if row == 5 {
            app.showEmptyView(text: NSAttributedString(string: "请求失败", attributes: [.font: UIFont.app.semiboldFont(ofSize: 15), .foregroundColor: UIColor.red]), detail: "请检查网络连接", image: UIImage.app.appIconImage(), loading: true, actions: ["取消", NSAttributedString(string: "重试", attributes: [.font: UIFont.app.semiboldFont(ofSize: 15), .foregroundColor: UIColor.red])]) { [weak self] index, _ in
                if index == 0 {
                    self?.app.showEmptyView(text: "请求失败", detail: "请检查网络连接", image: UIImage.app.appIconImage(), loading: true, actions: nil, block: nil)
                } else {
                    self?.app.hideEmptyView()
                    self?.tableView.reloadData()
                }
            }
        }
        tableView.reloadData()
    }
}

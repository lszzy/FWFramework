//
//  TestToastController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestToastController: UIViewController, TableViewControllerProtocol {
    
    static var isCancelled = false
    static var count: Int = 0
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupSubviews() {
        tableData.addObjects(from: [
            ["无文本", "onIndicator"],
            ["有文本(可取消)", "onIndicator2"],
            ["文本太长", "onIndicator3"],
            ["加载动画", "onLoading"],
            ["进度动画(可取消)", "onProgress"],
            ["加载动画(window)", "onLoadingWindow"],
            ["加载进度动画(window)", "onProgressWindow"],
            ["单行吐司(可点击)", "onToast"],
            ["多行吐司(默认不可点击)", "onToast2"],
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

@objc extension TestToastController {
    
    func onIndicator() {
        fw.showLoading(text: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.fw.hideLoading()
        }
    }
    
    func onIndicator2() {
        Self.isCancelled = false
        fw.showLoading(text: nil) { [weak self] in
            Self.isCancelled = true
            self?.fw.showMessage(text: "已取消")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if Self.isCancelled { return }
            self?.fw.hideLoading()
        }
    }
    
    func onIndicator3() {
        fw.showLoading(text: "我是很长很长很长很长很长很长很长很长很长很长的加载文案")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.fw.hideLoading()
        }
    }
    
    func onLoading() {
        fw.showLoading(text: "加载中\n请耐心等待")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.fw.hideLoading()
        }
    }
    
    func onProgress() {
        Self.isCancelled = false
        TestController.mockProgress { [weak self] progress, finished in
            if Self.isCancelled { return }
            if !finished {
                self?.fw.showProgress(progress, text: String(format: "上传中(%.0f%%)", progress * 100), cancelBlock: {
                    Self.isCancelled = true
                    self?.fw.showMessage(text: "已取消")
                })
            } else {
                self?.fw.hideProgress()
            }
        }
    }
    
    func onLoadingWindow() {
        view.window?.fw.toastInsets = UIEdgeInsets(top: FW.topBarHeight, left: 0, bottom: 0, right: 0)
        view.window?.fw.showLoading(text: "加载中")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.view.window?.fw.toastInsets = .zero
            self?.view.window?.fw.hideLoading()
        }
    }
    
    func onProgressWindow() {
        TestController.mockProgress { [weak self] progress, finished in
            if !finished {
                self?.view.window?.fw.showLoading(text: String(format: "上传中(%.0f%%)", progress * 100))
            } else {
                self?.view.window?.fw.hideLoading()
            }
        }
    }
    
    func onToast() {
        view.tag = 100
        Self.count += 1
        fw.showMessage(text: "吐司消息\(Self.count)")
    }
    
    func onToast2() {
        fw.showMessage(text: "我是很长很长很长很长很长很长很长很长很长很长很长的吐司消息", style: .default) { [weak self] in
            self?.onToast()
        }
    }
    
}

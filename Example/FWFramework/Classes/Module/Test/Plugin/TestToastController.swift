//
//  TestToastController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestToastController: UIViewController, TableViewControllerProtocol {
    
    typealias TableElement = [String]
    
    static var isCancelled = false
    static var count: Int = 0
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupSubviews() {
        tableData.append(contentsOf: [
            ["无文本", "onIndicator"],
            ["有文本(可取消)", "onIndicator2"],
            ["文本太长", "onIndicator3"],
            ["加载动画", "onLoading"],
            ["加载动画(连续)", "onContinuous"],
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
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let rowData = tableData[indexPath.row]
        cell.textLabel?.text = rowData[0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData[indexPath.row]
        _ = self.perform(NSSelectorFromString(rowData[1]))
    }
    
}

@objc extension TestToastController {
    
    func onIndicator() {
        app.showLoading(text: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.app.hideLoading()
        }
    }
    
    func onIndicator2() {
        Self.isCancelled = false
        app.showLoading(text: nil) { [weak self] in
            Self.isCancelled = true
            self?.app.showMessage(text: "已取消")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if Self.isCancelled { return }
            self?.app.hideLoading()
        }
    }
    
    func onIndicator3() {
        app.showLoading(text: "我是很长很长很长很长很长很长很长很长很长很长的加载文案")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.app.hideLoading()
        }
    }
    
    func onLoading() {
        app.showLoading(text: "加载中\n请耐心等待")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.app.hideLoading()
        }
    }
    
    func onContinuous() {
        app.showLoading(text: "加载1中")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.app.hideLoading(delayed: true)
            
            self?.app.showLoading(text: "加载2中")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.app.hideLoading()
            }
        }
    }
    
    func onProgress() {
        Self.isCancelled = false
        TestController.mockProgress { [weak self] progress, finished in
            if Self.isCancelled { return }
            if !finished {
                self?.app.showProgress(progress, text: String(format: "上传中(%.0f%%)", progress * 100), cancelBlock: {
                    Self.isCancelled = true
                    self?.app.showMessage(text: "已取消")
                })
            } else {
                self?.app.hideProgress()
            }
        }
    }
    
    func onLoadingWindow() {
        view.window?.app.toastInsets = UIEdgeInsets(top: APP.topBarHeight, left: 0, bottom: 0, right: 0)
        view.window?.app.showLoading(text: "加载中")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.view.window?.app.toastInsets = .zero
            self?.view.window?.app.hideLoading()
        }
    }
    
    func onProgressWindow() {
        TestController.mockProgress { [weak self] progress, finished in
            if !finished {
                self?.view.window?.app.showLoading(text: String(format: "上传中(%.0f%%)", progress * 100))
            } else {
                self?.view.window?.app.hideLoading()
            }
        }
    }
    
    func onToast() {
        view.tag = 100
        Self.count += 1
        app.showMessage(text: "吐司消息\(Self.count)")
    }
    
    func onToast2() {
        app.showMessage(text: "我是很长很长很长很长很长很长很长很长很长很长很长的吐司消息", style: .default) { [weak self] in
            self?.onToast()
        }
    }
    
}

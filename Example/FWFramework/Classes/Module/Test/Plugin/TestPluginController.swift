//
//  TestPluginController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/16.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestPluginController: UIViewController, TableViewControllerProtocol {
    
    typealias TableElement = [Int]
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupTableView() {
        tableData.append([0, 1])
        tableData.append([0, 1, 2, 3, 4, 5, 6])
        tableData.append([0])
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionData = tableData[section]
        return sectionData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionData = tableData[indexPath.section]
        let rowData = sectionData[indexPath.row]
        if indexPath.section == 0 {
            let cell = UITableViewCell.app.cell(tableView: tableView, style: .default, reuseIdentifier: "cell1")
            cell.selectionStyle = .none
            var view = cell.viewWithTag(100) as? ProgressView
            if view == nil {
                let progressView = ProgressView()
                view = progressView
                progressView.tag = 100
                progressView.color = AppTheme.textColor
                cell.contentView.addSubview(progressView)
                progressView.app.layoutChain.center()
            }
            view?.annular = rowData == 0 ? true : false
            TestController.mockProgress { progress, finished in
                view?.progress = progress
            }
            return cell
        }
        
        if indexPath.section == 2 {
            let cell = UITableViewCell.app.cell(tableView: tableView, style: .default, reuseIdentifier: "cell3")
            cell.selectionStyle = .none
            var view = cell.viewWithTag(100) as? LottiePluginView
            if view == nil {
                let lottieView = LottiePluginView()
                view = lottieView
                lottieView.tag = 100
                lottieView.setAnimation(name: "Lottie")
                lottieView.color = AppTheme.textColor
                cell.contentView.addSubview(lottieView)
                lottieView.app.layoutChain.center()
            }
            view?.startAnimating()
            return cell
        }
        
        let cell = UITableViewCell.app.cell(tableView: tableView, style: .default, reuseIdentifier: "cell2")
        cell.selectionStyle = .none
        var view = cell.viewWithTag(100) as? IndicatorView
        if view == nil {
            let indicatorView = IndicatorView()
            view = indicatorView
            indicatorView.tag = 100
            indicatorView.color = AppTheme.textColor
            cell.contentView.addSubview(indicatorView)
            indicatorView.app.layoutChain.center()
        }
        view?.type = IndicatorViewAnimationType(rawValue: rowData)
        view?.startAnimating()
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        app.showAlert(title: "请选择", message: nil, style: .default, cancel: nil, actions: ["预览", "设置全局样式"]) { [weak self] index in
            if index == 0 {
                self?.onPreview(indexPath)
            } else {
                self?.onSettings(indexPath)
            }
        }
    }
    
    func onPreview(_ indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.section == 0 {
            let progressView = cell?.viewWithTag(100) as? ProgressView
            TestController.mockProgress { progress, finished in
                progressView?.progress = progress
            }
            return
        }
        
        if indexPath.section == 2 {
            let toastPlugin = ToastPluginImpl()
            toastPlugin.customBlock = { toastView in
                let lottieView = LottiePluginView()
                lottieView.setAnimation(name: "Lottie")
                toastView.indicatorView = lottieView
            }
            tableView.isHidden = true
            toastPlugin.showLoading(withAttributedText: NSAttributedString(string: "Loading..."), cancel: nil, in: self.view)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                toastPlugin.showLoading(withAttributedText: NSAttributedString(string: "Authenticating..."), cancel: nil, in: self.view)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                toastPlugin.hideLoading(false, in: self.view)
                self.tableView.isHidden = false
            }
            return
        }
        
        let sectionData = tableData[indexPath.section]
        let rowData = sectionData[indexPath.row]
        let type = IndicatorViewAnimationType(rawValue: rowData)
        let toastPlugin = ToastPluginImpl()
        toastPlugin.customBlock = { toastView in
            toastView.indicatorView = IndicatorView(type: type)
        }
        tableView.isHidden = true
        toastPlugin.showLoading(withAttributedText: NSAttributedString(string: "Loading..."), cancel: nil, in: self.view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            toastPlugin.showLoading(withAttributedText: NSAttributedString(string: "Authenticating..."), cancel: nil, in: self.view)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            toastPlugin.hideLoading(false, in: self.view)
            self.tableView.isHidden = false
        }
    }
    
    func onSettings(_ indexPath: IndexPath) {
        if indexPath.section == 0 {
            let annular = indexPath.row == 0
            ViewPluginImpl.shared.customProgressView = { style in
                let progressView = ProgressView()
                progressView.annular = annular
                return progressView
            }
            RefreshPluginImpl.shared.pullRefreshBlock = nil
            RefreshPluginImpl.shared.infiniteScrollBlock = nil
            return
        }
        
        if indexPath.section == 2 {
            ViewPluginImpl.shared.customIndicatorView = { style in
                let lottieView = LottiePluginView()
                lottieView.setAnimation(name: "Lottie")
                return lottieView
            }
            // FWLottieView也支持进度显示
            ViewPluginImpl.shared.customProgressView = { style in
                let lottieView = LottiePluginView()
                lottieView.setAnimation(name: "Lottie")
                lottieView.hidesWhenStopped = false
                return lottieView
            }
            // FWLottieView支持下拉进度显示
            RefreshPluginImpl.shared.pullRefreshBlock = { view in
                let lottieView = LottiePluginView(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
                lottieView.contentInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
                lottieView.setAnimation(name: "Lottie")
                lottieView.hidesWhenStopped = false
                view.setAnimation(lottieView)
            }
            RefreshPluginImpl.shared.infiniteScrollBlock = { view in
                let lottieView = LottiePluginView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
                lottieView.setAnimation(name: "Lottie")
                lottieView.hidesWhenStopped = false
                view.setAnimation(lottieView)
            }
            return
        }
        
        let sectionData = tableData[indexPath.section]
        let rowData = sectionData[indexPath.row]
        let type = IndicatorViewAnimationType(rawValue: rowData)
        ViewPluginImpl.shared.customIndicatorView = { style in
            return IndicatorView(type: type)
        }
        // IndicatorView也支持进度显示
        ViewPluginImpl.shared.customProgressView = { style in
            let indicatorView = IndicatorView(type: type)
            indicatorView.hidesWhenStopped = false
            return indicatorView
        }
        RefreshPluginImpl.shared.pullRefreshBlock = nil
        RefreshPluginImpl.shared.infiniteScrollBlock = nil
    }
    
}

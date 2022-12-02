//
//  SettingsController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework
#if DEBUG
import FWDebug
#endif

class SettingsController: UIViewController {
    
    // MARK: - Accessor
    private lazy var loginButton: UIButton = {
        let button = AppTheme.largeButton()
        button.fw.addTouch(target: self, action: #selector(onMediator))
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        renderData()
    }
    
}

extension SettingsController: TableViewControllerProtocol {
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupTableView() {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: FW.screenWidth, height: 90))
        tableView.tableFooterView = footerView
        
        footerView.addSubview(loginButton)
        loginButton.fw.layoutChain.center()
    }
    
    func renderData() {
        navigationItem.title = FW.localized("settingTitle")
        
        #if DEBUG
        fw.setRightBarItem(FW.localized("debugButton")) { _ in
            FWDebugManager.sharedInstance().toggle()
        }
        #endif

        if UserService.shared.isLogin() {
            loginButton.setTitle(FW.localized("mediatorLogout"), for: .normal)
        } else {
            loginButton.setTitle(FW.localized("mediatorLogin"), for: .normal)
        }

        tableData.removeAllObjects()
        tableData.add([FW.localized("languageTitle"), "onLanguage"])
        tableData.add([FW.localized("themeTitle"), "onTheme"])
        tableView.reloadData()
    }
    
}

extension SettingsController {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(tableView: tableView, style: .value1)
        cell.accessoryType = .disclosureIndicator
        
        let rowData = tableData[indexPath.row] as! NSArray
        let text = FW.safeValue(rowData[0] as? String)
        let action = FW.safeValue(rowData[1] as? String)
        cell.textLabel?.text = text
        
        if "onLanguage" == action {
            var language = FW.localized("systemTitle")
            if let localized = Bundle.fw.localizedLanguage, localized.count > 0 {
                language = localized.hasPrefix("zh") ? "中文" : "English"
            } else {
                language = language.appending("(\(FW.safeString(Bundle.fw.systemLanguage)))")
            }
            cell.detailTextLabel?.text = language
        } else if "onTheme" == action {
            if UIWindow.fw.main?.fw.hasGrayView ?? false {
                cell.detailTextLabel?.text = FW.localized("themeGray")
            } else {
                let mode = ThemeManager.shared.mode
                let theme = mode == .system ? FW.localized("systemTitle").appending(ThemeManager.shared.style == .dark ? "(\(FW.localized("themeDark")))" : "(\(FW.localized("themeLight")))") : (mode == .dark ? FW.localized("themeDark") : FW.localized("themeLight"))
                cell.detailTextLabel?.text = theme
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData[indexPath.row] as! NSArray
        let action = FW.safeValue(rowData[1] as? String)
        fw.invokeMethod(Selector(action))
    }
    
}

// MARK: - Action
private extension SettingsController {
    
    @objc func onMediator() {
        if UserService.shared.isLogin() {
            onLogout()
        } else {
            onLogin()
        }
    }
    
    @objc func onLogin() {
        UserService.shared.login { [weak self] in
            self?.renderData()
        }
    }
    
    @objc func onLogout() {
        fw.showConfirm(title: FW.localized("logoutConfirm"), message: nil, cancel: nil, confirm: nil) { [weak self] in
            UserService.shared.logout {
                self?.renderData()
            }
        }
    }
    
    @objc func onLanguage() {
        fw.showSheet(title: FW.localized("languageTitle"), message: nil, cancel: FW.localized("取消"), actions: [FW.localized("systemTitle"), "中文", "English"], currentIndex: -1) { (index) in
            let language: String? = index == 1 ? "zh-Hans" : (index == 2 ? "en" : nil)
            Bundle.fw.localizedLanguage = language
            TabController.refreshController()
        }
    }
    
    @objc func onTheme() {
        var actions = [FW.localized("systemTitle"), FW.localized("themeLight")]
        if #available(iOS 13.0, *) {
            actions.append(FW.localized("themeDark"))
            actions.append(FW.localized("themeGray"))
        }
        
        fw.showSheet(title: FW.localized("themeTitle"), message: nil, cancel: FW.localized("取消"), actions: actions, currentIndex:-1) { (index) in
            if #available(iOS 13.0, *), index == actions.count - 1 {
                if UIWindow.fw.main?.fw.hasGrayView ?? false {
                    UIWindow.fw.main?.fw.hideGrayView()
                } else {
                    UIWindow.fw.main?.fw.showGrayView()
                }
            } else {
                ThemeManager.shared.mode = ThemeMode(index)
                TabController.refreshController()
            }
        }
    }
    
}

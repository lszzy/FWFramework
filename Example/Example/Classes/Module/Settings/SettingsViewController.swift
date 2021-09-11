//
//  SettingsViewController.swift
//  Example
//
//  Created by wuyong on 2021/3/19.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

import Foundation
#if DEBUG
import FWDebug
#endif

class SettingsViewController: UIViewController, FWTableViewController {
    private lazy var loginButton: UIButton = {
        let button = Theme.largeButton()
        button.fwAddTouchTarget(self, action: #selector(onMediator))
        return button
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        renderData()
    }
    
    // MARK: - Protected
    func renderTableStyle() -> UITableView.Style {
        return .grouped
    }
    
    func renderTableView() {
        fwNavigationView.scrollView = tableView
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: FWScreenWidth, height: 90))
        tableView.tableFooterView = footerView
        
        footerView.addSubview(loginButton)
        loginButton.fwLayoutChain.center()
    }
    
    func renderData() {
        fwBarTitle = FWLocalizedString("settingTitle")
        
        #if DEBUG
        fwSetRightBarItem(FWLocalizedString("debugButton")) { (sender) in
            if FWDebugManager.sharedInstance().isHidden {
                FWDebugManager.sharedInstance().show()
            } else {
                FWDebugManager.sharedInstance().hide()
            }
        }
        #endif
        
        if Mediator.userModule.isLogin() {
            loginButton.setTitle(FWLocalizedString("mediatorLogout"), for: .normal)
        } else {
            loginButton.setTitle(FWLocalizedString("mediatorLogin"), for: .normal)
        }
        
        tableData.removeAllObjects()
        tableData.add([FWLocalizedString("languageTitle"), "onLanguage"])
        tableData.add([FWLocalizedString("themeTitle"), "onTheme"])
        tableData.add([FWLocalizedString("rootTitle"), "onRoot"])
        tableData.add([FWLocalizedString("optionTitle"), "onOption"])
        tableView.reloadData()
    }
    
    // MARK: - Action
    @objc func onMediator() {
        if Mediator.userModule.isLogin() {
            onLogout()
        } else {
            onLogin()
        }
    }
    
    @objc func onLogin() {
        Mediator.userModule.login { [weak self] in
            self?.renderData()
        }
    }
    
    @objc func onLogout() {
        fwShowConfirm(withTitle: FWLocalizedString("logoutConfirm"), message: nil, cancel: nil, confirm: nil) { [weak self] in
            Mediator.userModule.logout {
                self?.renderData()
            }
        }
    }
    
    @objc func onLanguage() {
        fwShowSheet(withTitle: FWLocalizedString("languageTitle"), message: nil, cancel: FWLocalizedString("取消"), actions: [FWLocalizedString("systemTitle"), "中文", "English", FWLocalizedString("changeTitle")]) { [weak self] (index) in
            if index < 3 {
                let language: String? = index == 1 ? "zh-Hans" : (index == 2 ? "en" : nil)
                Bundle.fwLocalizedLanguage = language
                UITabBarController.refreshController()
            } else {
                let localized = Bundle.fwLocalizedLanguage
                let language: String? = localized == nil ? "zh-Hans" : (localized!.hasPrefix("zh") ? "en" : nil)
                Bundle.fwLocalizedLanguage = language
                self?.renderData()
            }
        }
    }
    
    @objc func onTheme() {
        var actions = [FWLocalizedString("systemTitle"), FWLocalizedString("themeLight")]
        if #available(iOS 13.0, *) {
            actions.append(FWLocalizedString("themeDark"))
        }
        actions.append(FWLocalizedString("changeTitle"))
        
        fwShowSheet(withTitle: FWLocalizedString("themeTitle"), message: nil, cancel: FWLocalizedString("取消"), actions: actions) { (index) in
            var mode = FWThemeMode(index)
            if index > actions.count - 2 {
                let currentMode = FWThemeManager.sharedInstance.mode
                mode = currentMode == .system ? .light : (currentMode == .light && actions.count > 3 ? .dark : .system)
            }
            FWThemeManager.sharedInstance.mode = mode
            UITabBarController.refreshController()
        }
    }
    
    @objc func onRoot() {
        fwShowSheet(withTitle: FWLocalizedString("rootTitle"), message: nil, cancel: FWLocalizedString("取消"), actions: ["UITabBar+Navigation", "FWTabBar+Navigation", "Navigation+UITabBar", "Navigation+FWTabBar"]) { (index) in
            switch index {
            case 0:
                AppConfig.isRootNavigation = false
                AppConfig.isRootCustom = false
            case 1:
                AppConfig.isRootNavigation = false
                AppConfig.isRootCustom = true
            case 2:
                AppConfig.isRootNavigation = true
                AppConfig.isRootCustom = false
            case 3:
                AppConfig.isRootNavigation = true
                AppConfig.isRootCustom = true
            default:
                break
            }
            UITabBarController.refreshController()
        }
    }
    
    @objc func onOption() {
        fwShowSheet(withTitle: FWLocalizedString("optionTitle"), message: nil, cancel: FWLocalizedString("取消"), actions: [AppConfig.isRootLogin ? FWLocalizedString("loginOptional") : FWLocalizedString("loginRequired"), Theme.isNavBarCustom ? FWLocalizedString("navBarSystem") : FWLocalizedString("navBarCustom"), Theme.isNavStyleCustom ? FWLocalizedString("navStyleDefault") : FWLocalizedString("navStyleCustom"), Theme.isLargeTitles ? FWLocalizedString("normalTitles") : FWLocalizedString("largeTitles"), Theme.isBarTranslucent ? "导航栏不透明" : "导航栏半透明", Theme.isBarAppearance ? "禁用导航栏Appearance" : "启用导航栏Appearance"]) { (index) in
            switch index {
            case 0:
                AppConfig.isRootLogin = !AppConfig.isRootLogin
            case 1:
                Theme.isNavBarCustom = !Theme.isNavBarCustom
            case 2:
                Theme.isNavStyleCustom = !Theme.isNavStyleCustom
            case 3:
                Theme.isLargeTitles = !Theme.isLargeTitles
            case 4:
                Theme.isBarTranslucent = !Theme.isBarTranslucent
            case 5:
                Theme.isBarAppearance = !Theme.isBarAppearance
                Theme.themeChanged()
            default:
                break
            }
            UITabBarController.refreshController()
        }
    }
}

extension SettingsViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fwCell(with: tableView, style: .value1)
        cell.accessoryType = .disclosureIndicator
        
        let rowData = tableData[indexPath.row] as! NSArray
        let text = FWSafeValue(rowData[0] as? String)
        let action = FWSafeValue(rowData[1] as? String)
        cell.textLabel?.text = text
        
        if "onLanguage" == action {
            var language = FWLocalizedString("systemTitle")
            if let localized = Bundle.fwLocalizedLanguage, localized.count > 0 {
                language = localized.hasPrefix("zh") ? "中文" : "English"
            }
            cell.detailTextLabel?.text = language
        } else if "onTheme" == action {
            let mode = FWThemeManager.sharedInstance.mode
            let theme = mode == .system ? FWLocalizedString("systemTitle") : (mode == .dark ? FWLocalizedString("themeDark") : FWLocalizedString("themeLight"))
            cell.detailTextLabel?.text = theme
        } else if "onRoot" == action {
            var root: String?
            if AppConfig.isRootNavigation {
                root = AppConfig.isRootCustom ? "Navigation+FWTabBar" : "Navigation+UITabBar"
            } else {
                root = AppConfig.isRootCustom ? "FWTabBar+Navigation" : "UITabBar+Navigation"
            }
            cell.detailTextLabel?.text = root
        } else if "onOption" == action {
            cell.detailTextLabel?.text = Theme.isNavBarCustom ? FWLocalizedString("navBarCustom") : FWLocalizedString("navBarSystem")
        } else {
            cell.detailTextLabel?.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData[indexPath.row] as! NSArray
        let action = FWSafeValue(rowData[1] as? String)
        fwPerform(Selector(action))
    }
}

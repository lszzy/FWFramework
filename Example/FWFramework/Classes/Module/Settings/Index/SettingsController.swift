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
        button.app.addTouch(target: self, action: #selector(onMediator))
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        renderData()
    }
    
}

extension SettingsController: TableViewControllerProtocol {
    
    typealias TableElement = [String]
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupTableView() {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: APP.screenWidth, height: 90))
        tableView.tableFooterView = footerView
        
        footerView.addSubview(loginButton)
        loginButton.app.layoutChain.center()
    }
    
    func renderData() {
        navigationItem.title = APP.localized("settingTitle")
        
        #if DEBUG
        app.setRightBarItem(APP.localized("debugButton")) { _ in
            FWDebugManager.sharedInstance().toggle()
        }
        #endif

        if UserService.shared.isLogin() {
            loginButton.setTitle(APP.localized("mediatorLogout"), for: .normal)
        } else {
            loginButton.setTitle(APP.localized("mediatorLogin"), for: .normal)
        }

        tableData.removeAll()
        tableData.append([APP.localized("languageTitle"), "onLanguage"])
        tableData.append([APP.localized("themeTitle"), "onTheme"])
        tableData.append([APP.localized("pluginTitle"), "onPlugin"])
        tableView.reloadData()
    }
    
}

extension SettingsController {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView, style: .value1)
        cell.accessoryType = .disclosureIndicator
        
        let rowData = tableData[indexPath.row]
        let text = APP.safeValue(rowData[0])
        let action = APP.safeValue(rowData[1])
        cell.textLabel?.text = text
        
        if "onLanguage" == action {
            var language = APP.localized("systemTitle")
            if let localized = Bundle.app.localizedLanguage, localized.count > 0 {
                language = localized.hasPrefix("zh") ? "中文" : "English"
            } else {
                language = language.appending("(\(APP.safeString(Bundle.app.systemLanguage)))")
            }
            cell.detailTextLabel?.text = language
        } else if "onTheme" == action {
            if UIWindow.app.main?.app.hasGrayView ?? false {
                cell.detailTextLabel?.text = APP.localized("themeGray")
            } else {
                let mode = ThemeManager.shared.mode
                let theme = mode == .system ? APP.localized("systemTitle").appending(ThemeManager.shared.style == .dark ? "(\(APP.localized("themeDark")))" : "(\(APP.localized("themeLight")))") : (mode == .dark ? APP.localized("themeDark") : APP.localized("themeLight"))
                cell.detailTextLabel?.text = theme
            }
        } else {
            cell.detailTextLabel?.text = APP.localized("pluginDetail")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData[indexPath.row]
        let action = APP.safeValue(rowData[1])
        app.invokeMethod(Selector(action))
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
        app.showConfirm(title: APP.localized("logoutConfirm"), message: nil, cancel: nil, confirm: nil) { [weak self] in
            UserService.shared.logout {
                self?.renderData()
            }
        }
    }
    
    @objc func onLanguage() {
        app.showSheet(title: APP.localized("languageTitle"), message: nil, cancel: APP.localized("取消"), actions: [APP.localized("systemTitle"), "中文", "English"], currentIndex: -1) { (index) in
            let language: String? = index == 1 ? "zh-Hans" : (index == 2 ? "en" : nil)
            Bundle.app.localizedLanguage = language
            TabController.refreshController()
        }
    }
    
    @objc func onTheme() {
        var actions = [APP.localized("systemTitle"), APP.localized("themeLight")]
        actions.append(APP.localized("themeDark"))
        actions.append(APP.localized("themeGray"))
        
        app.showSheet(title: APP.localized("themeTitle"), message: nil, cancel: APP.localized("取消"), actions: actions, currentIndex:-1) { (index) in
            if index == actions.count - 1 {
                if UIWindow.app.main?.app.hasGrayView ?? false {
                    UIWindow.app.main?.app.hideGrayView()
                } else {
                    UIWindow.app.main?.app.showGrayView()
                }
            } else {
                ThemeManager.shared.mode = ThemeMode(index)
                TabController.refreshController()
            }
        }
    }
    
    @objc func onPlugin() {
        let plugins: [[String]] = [
            ["AlertPlugin", "onAlertPlugin"],
            ["EmptyPlugin", "onEmptyPlugin"],
            ["RefreshPlugin", "onRefreshPlugin"],
            ["ToastPlugin", "onToastPlugin"],
            ["ViewPlugin", "onViewPlugin"],
            ["ImagePlugin", "onImagePlugin"],
            ["ImagePickerPlugin", "onImagePickerPlugin"],
            ["ImagePreviewPlugin", "onImagePreviewPlugin"],
        ]
        
        app.showSheet(title: APP.localized("pluginTitle"), message: nil, actions: plugins.map({ $0[0] })) { [weak self] index in
            let action = plugins[index][1]
            self?.app.invokeMethod(Selector(action))
        }
    }
    
    @objc func onAlertPlugin() {
        let actions = Autoloader.alertPlugins.map {
            $0 == Autoloader.alertPluginImpl ? "[\($0)]" : $0
        }
        app.showSheet(title: "AlertPlugin", message: nil, actions: actions) { index in
            Autoloader.alertPluginImpl = Autoloader.alertPlugins[index]
            Autoloader().loadPlugin()
        }
    }
    
    @objc func onEmptyPlugin() {
        let actions = Autoloader.emptyPlugins.map {
            $0 == Autoloader.emptyPluginImpl ? "[\($0)]" : $0
        }
        app.showSheet(title: "EmptyPlugin", message: nil, actions: actions) { index in
            Autoloader.emptyPluginImpl = Autoloader.emptyPlugins[index]
            Autoloader().loadPlugin()
        }
    }
    
    @objc func onToastPlugin() {
        let actions = Autoloader.toastPlugins.map {
            $0 == Autoloader.toastPluginImpl ? "[\($0)]" : $0
        }
        app.showSheet(title: "ToastPlugin", message: nil, actions: actions) { index in
            Autoloader.toastPluginImpl = Autoloader.toastPlugins[index]
            Autoloader().loadPlugin()
        }
    }
    
    @objc func onViewPlugin() {
        let actions = Autoloader.viewPlugins.map {
            $0 == Autoloader.viewPluginImpl ? "[\($0)]" : $0
        }
        app.showSheet(title: "ViewPlugin", message: nil, actions: actions) { index in
            Autoloader.viewPluginImpl = Autoloader.viewPlugins[index]
            Autoloader().loadPlugin()
        }
    }
    
    @objc func onRefreshPlugin() {
        let actions = Autoloader.refreshPlugins.map {
            $0 == Autoloader.refreshPluginImpl ? "[\($0)]" : $0
        }
        app.showSheet(title: "RefreshPlugin", message: nil, actions: actions) { index in
            Autoloader.refreshPluginImpl = Autoloader.refreshPlugins[index]
            Autoloader().loadPlugin()
        }
    }
    
    @objc func onImagePlugin() {
        let actions = Autoloader.imagePlugins.map {
            $0 == Autoloader.imagePluginImpl ? "[\($0)]" : $0
        }
        app.showSheet(title: "ImagePlugin", message: nil, actions: actions) { index in
            Autoloader.imagePluginImpl = Autoloader.imagePlugins[index]
            Autoloader().loadPlugin()
        }
    }
    
    @objc func onImagePickerPlugin() {
        let actions = Autoloader.imagePickerPlugins.map {
            $0 == Autoloader.imagePickerPluginImpl ? "[\($0)]" : $0
        }
        app.showSheet(title: "ImagePickerPlugin", message: nil, actions: actions) { index in
            Autoloader.imagePickerPluginImpl = Autoloader.imagePickerPlugins[index]
            Autoloader().loadPlugin()
        }
    }
    
    @objc func onImagePreviewPlugin() {
        let actions = Autoloader.imagePreviewPlugins.map {
            $0 == Autoloader.imagePreviewPluginImpl ? "[\($0)]" : $0
        }
        app.showSheet(title: "ImagePreviewPlugin", message: nil, actions: actions) { index in
            Autoloader.imagePreviewPluginImpl = Autoloader.imagePreviewPlugins[index]
            Autoloader().loadPlugin()
        }
    }
    
}

@objc extension Autoloader {
    
    @StoredValue("alertPluginImpl")
    static var alertPluginImpl = alertPlugins[0]
    static let alertPlugins = ["AlertPluginImpl", "AlertControllerImpl"]
    
    @StoredValue("emptyPluginImpl")
    static var emptyPluginImpl = emptyPlugins[0]
    static let emptyPlugins = ["EmptyPluginImpl"]
    
    @StoredValue("refreshPluginImpl")
    static var refreshPluginImpl = refreshPlugins[0]
    static let refreshPlugins = ["RefreshPluginImpl"]
    
    @StoredValue("toastPluginImpl")
    static var toastPluginImpl = toastPlugins[0]
    static let toastPlugins = ["ToastPluginImpl"]
    
    @StoredValue("viewPluginImpl")
    static var viewPluginImpl = viewPlugins[0]
    static let viewPlugins = ["ViewPluginImpl"]
    
    @StoredValue("imagePluginImpl")
    static var imagePluginImpl = imagePlugins[0]
    static let imagePlugins = ["ImagePluginImpl", "SDWebImageImpl"]
    
    @StoredValue("imagePickerPluginImpl")
    static var imagePickerPluginImpl = imagePickerPlugins[0]
    static let imagePickerPlugins = ["ImagePickerPluginImpl", "ImagePickerControllerImpl"]
    
    @StoredValue("imagePreviewPluginImpl")
    static var imagePreviewPluginImpl = imagePreviewPlugins[0]
    static let imagePreviewPlugins = ["ImagePreviewPluginImpl"]
    
    func loadPlugin() {
        PluginManager.unloadPlugin(AlertPlugin.self)
        PluginManager.registerPlugin(AlertPlugin.self, object: Autoloader.alertPluginImpl == Autoloader.alertPlugins[0] ? AlertPluginImpl.self : AlertControllerImpl.self)
        
        PluginManager.unloadPlugin(ImagePlugin.self)
        PluginManager.registerPlugin(ImagePlugin.self, object: Autoloader.imagePluginImpl == Autoloader.imagePlugins[0] ? ImagePluginImpl.self : SDWebImageImpl.self)
        
        PluginManager.unloadPlugin(ImagePickerPlugin.self)
        PluginManager.registerPlugin(ImagePickerPlugin.self, object: Autoloader.imagePickerPluginImpl == Autoloader.imagePickerPlugins[0] ? ImagePickerPluginImpl.self : ImagePickerControllerImpl.self)
    }
    
}

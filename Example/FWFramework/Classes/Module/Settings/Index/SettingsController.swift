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
    private lazy var mediatorButton: UIButton = {
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
        
        footerView.addSubview(mediatorButton)
        mediatorButton.app.layoutChain.center()
    }
    
    func setupTableLayout() {
        // 示例父视图布局，scrollView自适应contentInset
        tableView.contentInsetAdjustmentBehavior = .automatic
        tableView.layoutChain.edges()
    }
    
    func renderData() {
        navigationItem.title = APP.localized("settingTitle")
        
        #if DEBUG
        app.setRightBarItem(Icon.iconImage("zmdi-var-bug", size: 24)) { _ in
            FWDebugManager.sharedInstance().toggle()
        }
        #endif

        if UserService.shared.isLogin() {
            mediatorButton.setTitle(APP.localized("mediatorLogout"), for: .normal)
        } else {
            mediatorButton.setTitle(APP.localized("mediatorLogin"), for: .normal)
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
            let currentLanguage = Bundle.app.currentLanguage ?? ""
            var language = Bundle.app.languageName(for: currentLanguage, localeIdentifier: currentLanguage)
            if Bundle.app.localizedLanguage == nil {
                language = APP.localized("systemTitle") + "(\(language))"
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
        _ = self.perform(Selector(action))
    }
    
}

// MARK: - Action
private extension SettingsController {
    
    @objc func onMediator() {
        if UserService.shared.isLogin() {
            UserService.shared.logout { [weak self] in
                self?.renderData()
            }
        } else {
            UserService.shared.login { [weak self] in
                self?.renderData()
            }
        }
    }
    
    @objc func onLanguage() {
        var actions: [String] = [APP.localized("systemTitle")]
        let languages = Bundle.app.availableLanguages
        actions.append(contentsOf: languages.map({ Bundle.app.languageName(for: $0, localeIdentifier: $0) }))
        
        app.showSheet(title: APP.localized("languageTitle"), message: nil, cancel: APP.localized("取消"), actions: actions, currentIndex: -1) { (index) in
            var language: String?
            if index > 0 {
                language = languages[index - 1]
            }
            
            Bundle.app.localizedLanguage = language
            AppDelegate.shared.reloadController()
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
                AppDelegate.shared.reloadController()
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
            ["RequestPlugin", "onRequestPlugin"],
        ]
        
        app.showSheet(title: APP.localized("pluginTitle"), message: nil, actions: plugins.map({ $0[0] })) { [weak self] index in
            let action = plugins[index][1]
            _ = self?.perform(Selector(action))
        }
    }
    
    @objc func onAlertPlugin() {
        var actions = SettingsController.alertPlugins.map {
            $0 == SettingsController.alertPluginImpl ? "[\($0)]" : $0
        }
        actions.append(SettingsController.alertHidesSheetCancel ? "[hidesSheetCancel]" : "hidesSheetCancel")
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "AlertPlugin", message: nil, actions: actions) { index in
            if index < SettingsController.alertPlugins.count {
                SettingsController.alertPluginImpl = SettingsController.alertPlugins[index]
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.alertPlugins.count {
                SettingsController.alertHidesSheetCancel = !SettingsController.alertHidesSheetCancel
                Autoloader.shared.loadApp_Plugin()
            } else {
                Navigator.push(TestAlertController())
            }
        }
    }
    
    @objc func onEmptyPlugin() {
        var actions = SettingsController.emptyPlugins.map {
            $0 == SettingsController.emptyPluginImpl ? "[\($0)]" : $0
        }
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "EmptyPlugin", message: nil, actions: actions) { index in
            if index < SettingsController.emptyPlugins.count {
                SettingsController.emptyPluginImpl = SettingsController.emptyPlugins[index]
                Autoloader.shared.loadApp_Plugin()
            } else {
                Navigator.push(TestEmptyController())
            }
        }
    }
    
    @objc func onToastPlugin() {
        var actions = SettingsController.toastPlugins.map {
            $0 == SettingsController.toastPluginImpl ? "[\($0)]" : $0
        }
        actions.append(SettingsController.toastHorizontalAlignment ? "[horizontalAlignment]" : "horizontalAlignment")
        actions.append(SettingsController.toastPluginPosition == ToastViewPosition.center.rawValue ? "[positionCenter]" : "positionCenter")
        actions.append(SettingsController.toastPluginPosition == ToastViewPosition.top.rawValue ? "[positionTop]" : "positionTop")
        actions.append(SettingsController.toastPluginPosition == ToastViewPosition.bottom.rawValue ? "[positionBottom]" : "positionBottom")
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "ToastPlugin", message: nil, actions: actions) { index in
            if index < SettingsController.toastPlugins.count {
                SettingsController.toastPluginImpl = SettingsController.toastPlugins[index]
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.toastPlugins.count {
                SettingsController.toastHorizontalAlignment = !SettingsController.toastHorizontalAlignment
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.toastPlugins.count + 1 {
                SettingsController.toastPluginPosition = ToastViewPosition.center.rawValue
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.toastPlugins.count + 2 {
                SettingsController.toastPluginPosition = ToastViewPosition.top.rawValue
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.toastPlugins.count + 3 {
                SettingsController.toastPluginPosition = ToastViewPosition.bottom.rawValue
                Autoloader.shared.loadApp_Plugin()
            } else {
                Navigator.push(TestToastController())
            }
        }
    }
    
    @objc func onViewPlugin() {
        var actions = SettingsController.viewPlugins.map {
            $0 == SettingsController.viewPluginImpl ? "[\($0)]" : $0
        }
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "ViewPlugin", message: nil, actions: actions) { index in
            if index < SettingsController.viewPlugins.count {
                SettingsController.viewPluginImpl = SettingsController.viewPlugins[index]
                Autoloader.shared.loadApp_Plugin()
            } else {
                Navigator.push(TestPluginController())
            }
        }
    }
    
    @objc func onRefreshPlugin() {
        var actions = SettingsController.refreshPlugins.map {
            $0 == SettingsController.refreshPluginImpl ? "[\($0)]" : $0
        }
        actions.append(SettingsController.refreshShowsFinishedView ? "[showsFinishedView]" : "showsFinishedView")
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "RefreshPlugin", message: nil, actions: actions) { index in
            if index < SettingsController.refreshPlugins.count {
                SettingsController.refreshPluginImpl = SettingsController.refreshPlugins[index]
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.refreshPlugins.count {
                SettingsController.refreshShowsFinishedView = !SettingsController.refreshShowsFinishedView
                Autoloader.shared.loadApp_Plugin()
            } else {
                Navigator.push(TestRefreshController())
            }
        }
    }
    
    @objc func onImagePlugin() {
        var actions = SettingsController.imagePlugins.map {
            $0 == SettingsController.imagePluginImpl ? "[\($0)]" : $0
        }
        actions.append(SettingsController.imageShowsIndicator ? "[showsIndicator]" : "showsIndicator")
        actions.append(SettingsController.imageHidesPlaceholderIndicator ? "[hidesPlaceholderIndicator]" : "hidesPlaceholderIndicator")
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "ImagePlugin", message: nil, actions: actions) { index in
            if index < SettingsController.imagePlugins.count {
                SettingsController.imagePluginImpl = SettingsController.imagePlugins[index]
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.imagePlugins.count {
                SettingsController.imageShowsIndicator = !SettingsController.imageShowsIndicator
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.imagePlugins.count + 1 {
                SettingsController.imageHidesPlaceholderIndicator = !SettingsController.imageHidesPlaceholderIndicator
                Autoloader.shared.loadApp_Plugin()
            } else {
                Navigator.push(TestImageController())
            }
        }
    }
    
    @objc func onImagePickerPlugin() {
        var actions = SettingsController.imagePickerPlugins.map {
            $0 == SettingsController.imagePickerPluginImpl ? "[\($0)]" : $0
        }
        actions.append(SettingsController.imagePickerCropControllerEnabled ? "[cropControllerEnabled]" : "cropControllerEnabled")
        actions.append(SettingsController.imagePickerPhotoPickerDisabled ? "[photoPickerDisabled]" : "photoPickerDisabled")
        actions.append(SettingsController.imagePickerPhotoNavigationEnabled ? "[photoNavigationEnabled]" : "photoNavigationEnabled")
        actions.append(SettingsController.imagePickerPresentationFullScreen ? "[presentationFullScreen]" : "presentationFullScreen")
        actions.append(SettingsController.imagePickerShowsAlbumController ? "[showsAlbumController]" : "showsAlbumController")
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "ImagePickerPlugin", message: nil, actions: actions) { index in
            if index < SettingsController.imagePickerPlugins.count {
                SettingsController.imagePickerPluginImpl = SettingsController.imagePickerPlugins[index]
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.imagePickerPlugins.count {
                SettingsController.imagePickerCropControllerEnabled = !SettingsController.imagePickerCropControllerEnabled
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.imagePickerPlugins.count + 1 {
                SettingsController.imagePickerPhotoPickerDisabled = !SettingsController.imagePickerPhotoPickerDisabled
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.imagePickerPlugins.count + 2 {
                SettingsController.imagePickerPhotoNavigationEnabled = !SettingsController.imagePickerPhotoNavigationEnabled
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.imagePickerPlugins.count + 3 {
                SettingsController.imagePickerPresentationFullScreen = !SettingsController.imagePickerPresentationFullScreen
                Autoloader.shared.loadApp_Plugin()
            } else if index == SettingsController.imagePickerPlugins.count + 4 {
                SettingsController.imagePickerShowsAlbumController = !SettingsController.imagePickerShowsAlbumController
                Autoloader.shared.loadApp_Plugin()
            } else {
                Navigator.push(TestPickerController())
            }
        }
    }
    
    @objc func onImagePreviewPlugin() {
        var actions = SettingsController.imagePreviewPlugins.map {
            $0 == SettingsController.imagePreviewPluginImpl ? "[\($0)]" : $0
        }
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "ImagePreviewPlugin", message: nil, actions: actions) { index in
            if index < SettingsController.imagePreviewPlugins.count {
                SettingsController.imagePreviewPluginImpl = SettingsController.imagePreviewPlugins[index]
                Autoloader.shared.loadApp_Plugin()
            } else {
                Navigator.push(TestPreviewController())
            }
        }
    }
    
    @objc func onRequestPlugin() {
        var actions = SettingsController.requestPlugins.map {
            $0 == SettingsController.requestPluginImpl ? "[\($0)]" : $0
        }
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "RequestPlugin", message: nil, actions: actions) { index in
            if index < SettingsController.requestPlugins.count {
                SettingsController.requestPluginImpl = SettingsController.requestPlugins[index]
                Autoloader.shared.loadApp_Plugin()
            } else {
                Navigator.push(TestRequestController())
            }
        }
    }
    
}

extension SettingsController {
    @StoredValue("alertPluginImpl")
    static var alertPluginImpl = alertPlugins[0]
    static let alertPlugins = ["AlertPluginImpl", "AlertControllerImpl"]
    @StoredValue("alertHidesSheetCancel")
    static var alertHidesSheetCancel = false
    
    @StoredValue("emptyPluginImpl")
    static var emptyPluginImpl = emptyPlugins[0]
    static let emptyPlugins = ["EmptyPluginImpl"]
    
    @StoredValue("refreshPluginImpl")
    static var refreshPluginImpl = refreshPlugins[0]
    static let refreshPlugins = ["RefreshPluginImpl"]
    @StoredValue("refreshShowsFinishedView")
    static var refreshShowsFinishedView = true
    
    @StoredValue("toastPluginImpl")
    static var toastPluginImpl = toastPlugins[0]
    static let toastPlugins = ["ToastPluginImpl"]
    @StoredValue("toastHorizontalAlignment")
    static var toastHorizontalAlignment = false
    @StoredValue("toastPluginPosition")
    static var toastPluginPosition: Int = 0
    
    @StoredValue("viewPluginImpl")
    static var viewPluginImpl = viewPlugins[0]
    static let viewPlugins = ["ViewPluginImpl"]
    
    @StoredValue("imagePluginImpl")
    static var imagePluginImpl = imagePlugins[0]
    static let imagePlugins = ["ImagePluginImpl", "SDWebImageImpl"]
    @StoredValue("imageShowsIndicator")
    static var imageShowsIndicator = false
    @StoredValue("imageHidesPlaceholderIndicator")
    static var imageHidesPlaceholderIndicator = false
    
    @StoredValue("imagePickerPluginImpl")
    static var imagePickerPluginImpl = imagePickerPlugins[0]
    static let imagePickerPlugins = ["ImagePickerPluginImpl", "ImagePickerControllerImpl"]
    @StoredValue("imagePickerCropControllerEnabled")
    static var imagePickerCropControllerEnabled = false
    @StoredValue("imagePickerPhotoPickerDisabled")
    static var imagePickerPhotoPickerDisabled = false
    @StoredValue("imagePickerPhotoNavigationEnabled")
    static var imagePickerPhotoNavigationEnabled = false
    @StoredValue("imagePickerPresentationFullScreen")
    static var imagePickerPresentationFullScreen = false
    @StoredValue("imagePickerShowsAlbumController")
    static var imagePickerShowsAlbumController = false
    
    @StoredValue("imagePreviewPluginImpl")
    static var imagePreviewPluginImpl = imagePreviewPlugins[0]
    static let imagePreviewPlugins = ["ImagePreviewPluginImpl"]
    
    @StoredValue("requestPluginImpl")
    static var requestPluginImpl = requestPlugins[0]
    static let requestPlugins = ["RequestPluginImpl", "AlamofireImpl"]
}

@objc extension Autoloader {
    @MainActor func loadApp_Plugin() {
        PluginManager.unloadPlugin(AlertPlugin.self)
        PluginManager.registerPlugin(AlertPlugin.self, object: SettingsController.alertPluginImpl == SettingsController.alertPlugins[0] ? AlertPluginImpl.self : AlertControllerImpl.self)
        AlertControllerImpl.shared.hidesSheetCancel = SettingsController.alertHidesSheetCancel
        
        ToastPluginImpl.shared.customBlock = { toastView in
            toastView.horizontalAlignment = SettingsController.toastHorizontalAlignment
            toastView.position = .init(rawValue: SettingsController.toastPluginPosition) ?? .center
        }
        
        RefreshPluginImpl.shared.showsFinishedView = SettingsController.refreshShowsFinishedView
        
        PluginManager.unloadPlugin(ImagePlugin.self)
        PluginManager.registerPlugin(ImagePlugin.self, object: SettingsController.imagePluginImpl == SettingsController.imagePlugins[0] ? ImagePluginImpl.self : SDWebImageImpl.self)
        ImagePluginImpl.shared.showsIndicator = SettingsController.imageShowsIndicator
        SDWebImageImpl.shared.showsIndicator = SettingsController.imageShowsIndicator
        ImagePluginImpl.shared.hidesPlaceholderIndicator = SettingsController.imageHidesPlaceholderIndicator
        SDWebImageImpl.shared.hidesPlaceholderIndicator = SettingsController.imageHidesPlaceholderIndicator
        
        PluginManager.unloadPlugin(ImagePickerPlugin.self)
        PluginManager.registerPlugin(ImagePickerPlugin.self, object: SettingsController.imagePickerPluginImpl == SettingsController.imagePickerPlugins[0] ? ImagePickerPluginImpl.self : ImagePickerControllerImpl.self)
        ImagePickerPluginImpl.shared.cropControllerEnabled = SettingsController.imagePickerCropControllerEnabled
        ImagePickerPluginImpl.shared.photoPickerDisabled = SettingsController.imagePickerPhotoPickerDisabled
        ImagePickerPluginImpl.shared.photoNavigationEnabled = SettingsController.imagePickerPhotoNavigationEnabled
        ImagePickerPluginImpl.shared.presentationFullScreen = SettingsController.imagePickerPresentationFullScreen
        ImagePickerControllerImpl.shared.showsAlbumController = SettingsController.imagePickerShowsAlbumController
        
        PluginManager.unloadPlugin(RequestPlugin.self)
        PluginManager.registerPlugin(RequestPlugin.self, object: SettingsController.requestPluginImpl == SettingsController.requestPlugins[0] ? RequestPluginImpl.self : AlamofireImpl.self)
    }
}

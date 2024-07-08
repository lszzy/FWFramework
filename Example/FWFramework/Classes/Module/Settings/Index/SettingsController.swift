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
        tableView.chain.edges()
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
        var actions = Autoloader.alertPlugins.map {
            $0 == Autoloader.alertPluginImpl ? "[\($0)]" : $0
        }
        actions.append(Autoloader.alertHidesSheetCancel ? "[hidesSheetCancel]" : "hidesSheetCancel")
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "AlertPlugin", message: nil, actions: actions) { index in
            if index < Autoloader.alertPlugins.count {
                Autoloader.alertPluginImpl = Autoloader.alertPlugins[index]
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.alertPlugins.count {
                Autoloader.alertHidesSheetCancel = !Autoloader.alertHidesSheetCancel
                Autoloader.loadApp_Plugin()
            } else {
                Navigator.push(TestAlertController())
            }
        }
    }
    
    @objc func onEmptyPlugin() {
        var actions = Autoloader.emptyPlugins.map {
            $0 == Autoloader.emptyPluginImpl ? "[\($0)]" : $0
        }
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "EmptyPlugin", message: nil, actions: actions) { index in
            if index < Autoloader.emptyPlugins.count {
                Autoloader.emptyPluginImpl = Autoloader.emptyPlugins[index]
                Autoloader.loadApp_Plugin()
            } else {
                Navigator.push(TestEmptyController())
            }
        }
    }
    
    @objc func onToastPlugin() {
        var actions = Autoloader.toastPlugins.map {
            $0 == Autoloader.toastPluginImpl ? "[\($0)]" : $0
        }
        actions.append(Autoloader.toastHorizontalAlignment ? "[horizontalAlignment]" : "horizontalAlignment")
        actions.append(Autoloader.toastPluginPosition == ToastViewPosition.center.rawValue ? "[positionCenter]" : "positionCenter")
        actions.append(Autoloader.toastPluginPosition == ToastViewPosition.top.rawValue ? "[positionTop]" : "positionTop")
        actions.append(Autoloader.toastPluginPosition == ToastViewPosition.bottom.rawValue ? "[positionBottom]" : "positionBottom")
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "ToastPlugin", message: nil, actions: actions) { index in
            if index < Autoloader.toastPlugins.count {
                Autoloader.toastPluginImpl = Autoloader.toastPlugins[index]
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.toastPlugins.count {
                Autoloader.toastHorizontalAlignment = !Autoloader.toastHorizontalAlignment
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.toastPlugins.count + 1 {
                Autoloader.toastPluginPosition = ToastViewPosition.center.rawValue
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.toastPlugins.count + 2 {
                Autoloader.toastPluginPosition = ToastViewPosition.top.rawValue
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.toastPlugins.count + 3 {
                Autoloader.toastPluginPosition = ToastViewPosition.bottom.rawValue
                Autoloader.loadApp_Plugin()
            } else {
                Navigator.push(TestToastController())
            }
        }
    }
    
    @objc func onViewPlugin() {
        var actions = Autoloader.viewPlugins.map {
            $0 == Autoloader.viewPluginImpl ? "[\($0)]" : $0
        }
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "ViewPlugin", message: nil, actions: actions) { index in
            if index < Autoloader.viewPlugins.count {
                Autoloader.viewPluginImpl = Autoloader.viewPlugins[index]
                Autoloader.loadApp_Plugin()
            } else {
                Navigator.push(TestPluginController())
            }
        }
    }
    
    @objc func onRefreshPlugin() {
        var actions = Autoloader.refreshPlugins.map {
            $0 == Autoloader.refreshPluginImpl ? "[\($0)]" : $0
        }
        actions.append(Autoloader.refreshShowsFinishedView ? "[showsFinishedView]" : "showsFinishedView")
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "RefreshPlugin", message: nil, actions: actions) { index in
            if index < Autoloader.refreshPlugins.count {
                Autoloader.refreshPluginImpl = Autoloader.refreshPlugins[index]
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.refreshPlugins.count {
                Autoloader.refreshShowsFinishedView = !Autoloader.refreshShowsFinishedView
                Autoloader.loadApp_Plugin()
            } else {
                Navigator.push(TestRefreshController())
            }
        }
    }
    
    @objc func onImagePlugin() {
        var actions = Autoloader.imagePlugins.map {
            $0 == Autoloader.imagePluginImpl ? "[\($0)]" : $0
        }
        actions.append(Autoloader.imageShowsIndicator ? "[showsIndicator]" : "showsIndicator")
        actions.append(Autoloader.imageHidesPlaceholderIndicator ? "[hidesPlaceholderIndicator]" : "hidesPlaceholderIndicator")
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "ImagePlugin", message: nil, actions: actions) { index in
            if index < Autoloader.imagePlugins.count {
                Autoloader.imagePluginImpl = Autoloader.imagePlugins[index]
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.imagePlugins.count {
                Autoloader.imageShowsIndicator = !Autoloader.imageShowsIndicator
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.imagePlugins.count + 1 {
                Autoloader.imageHidesPlaceholderIndicator = !Autoloader.imageHidesPlaceholderIndicator
                Autoloader.loadApp_Plugin()
            } else {
                Navigator.push(TestImageController())
            }
        }
    }
    
    @objc func onImagePickerPlugin() {
        var actions = Autoloader.imagePickerPlugins.map {
            $0 == Autoloader.imagePickerPluginImpl ? "[\($0)]" : $0
        }
        actions.append(Autoloader.imagePickerCropControllerEnabled ? "[cropControllerEnabled]" : "cropControllerEnabled")
        actions.append(Autoloader.imagePickerPhotoPickerDisabled ? "[photoPickerDisabled]" : "photoPickerDisabled")
        actions.append(Autoloader.imagePickerPhotoNavigationEnabled ? "[photoNavigationEnabled]" : "photoNavigationEnabled")
        actions.append(Autoloader.imagePickerPresentationFullScreen ? "[presentationFullScreen]" : "presentationFullScreen")
        actions.append(Autoloader.imagePickerShowsAlbumController ? "[showsAlbumController]" : "showsAlbumController")
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "ImagePickerPlugin", message: nil, actions: actions) { index in
            if index < Autoloader.imagePickerPlugins.count {
                Autoloader.imagePickerPluginImpl = Autoloader.imagePickerPlugins[index]
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.imagePickerPlugins.count {
                Autoloader.imagePickerCropControllerEnabled = !Autoloader.imagePickerCropControllerEnabled
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.imagePickerPlugins.count + 1 {
                Autoloader.imagePickerPhotoPickerDisabled = !Autoloader.imagePickerPhotoPickerDisabled
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.imagePickerPlugins.count + 2 {
                Autoloader.imagePickerPhotoNavigationEnabled = !Autoloader.imagePickerPhotoNavigationEnabled
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.imagePickerPlugins.count + 3 {
                Autoloader.imagePickerPresentationFullScreen = !Autoloader.imagePickerPresentationFullScreen
                Autoloader.loadApp_Plugin()
            } else if index == Autoloader.imagePickerPlugins.count + 4 {
                Autoloader.imagePickerShowsAlbumController = !Autoloader.imagePickerShowsAlbumController
                Autoloader.loadApp_Plugin()
            } else {
                Navigator.push(TestPickerController())
            }
        }
    }
    
    @objc func onImagePreviewPlugin() {
        var actions = Autoloader.imagePreviewPlugins.map {
            $0 == Autoloader.imagePreviewPluginImpl ? "[\($0)]" : $0
        }
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "ImagePreviewPlugin", message: nil, actions: actions) { index in
            if index < Autoloader.imagePreviewPlugins.count {
                Autoloader.imagePreviewPluginImpl = Autoloader.imagePreviewPlugins[index]
                Autoloader.loadApp_Plugin()
            } else {
                Navigator.push(TestPreviewController())
            }
        }
    }
    
    @objc func onRequestPlugin() {
        var actions = Autoloader.requestPlugins.map {
            $0 == Autoloader.requestPluginImpl ? "[\($0)]" : $0
        }
        actions.append(APP.localized("pluginDemo"))
        app.showSheet(title: "RequestPlugin", message: nil, actions: actions) { index in
            if index < Autoloader.requestPlugins.count {
                Autoloader.requestPluginImpl = Autoloader.requestPlugins[index]
                Autoloader.loadApp_Plugin()
            } else {
                Navigator.push(TestRequestController())
            }
        }
    }
    
}

@objc extension Autoloader {
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
    
    static func loadApp_Plugin() {
        PluginManager.unloadPlugin(AlertPlugin.self)
        PluginManager.registerPlugin(AlertPlugin.self, object: Autoloader.alertPluginImpl == Autoloader.alertPlugins[0] ? AlertPluginImpl.self : AlertControllerImpl.self)
        AlertControllerImpl.shared.hidesSheetCancel = Autoloader.alertHidesSheetCancel
        
        ToastPluginImpl.shared.horizontalAlignment = Autoloader.toastHorizontalAlignment
        ToastPluginImpl.shared.customBlock = { toastView in
            toastView.position = .init(rawValue: Autoloader.toastPluginPosition) ?? .center
        }
        
        RefreshPluginImpl.shared.showsFinishedView = Autoloader.refreshShowsFinishedView
        
        PluginManager.unloadPlugin(ImagePlugin.self)
        PluginManager.registerPlugin(ImagePlugin.self, object: Autoloader.imagePluginImpl == Autoloader.imagePlugins[0] ? ImagePluginImpl.self : SDWebImageImpl.self)
        ImagePluginImpl.shared.showsIndicator = Autoloader.imageShowsIndicator
        SDWebImageImpl.shared.showsIndicator = Autoloader.imageShowsIndicator
        ImagePluginImpl.shared.hidesPlaceholderIndicator = Autoloader.imageHidesPlaceholderIndicator
        SDWebImageImpl.shared.hidesPlaceholderIndicator = Autoloader.imageHidesPlaceholderIndicator
        
        PluginManager.unloadPlugin(ImagePickerPlugin.self)
        PluginManager.registerPlugin(ImagePickerPlugin.self, object: Autoloader.imagePickerPluginImpl == Autoloader.imagePickerPlugins[0] ? ImagePickerPluginImpl.self : ImagePickerControllerImpl.self)
        ImagePickerPluginImpl.shared.cropControllerEnabled = Autoloader.imagePickerCropControllerEnabled
        ImagePickerPluginImpl.shared.photoPickerDisabled = Autoloader.imagePickerPhotoPickerDisabled
        ImagePickerPluginImpl.shared.photoNavigationEnabled = Autoloader.imagePickerPhotoNavigationEnabled
        ImagePickerPluginImpl.shared.presentationFullScreen = Autoloader.imagePickerPresentationFullScreen
        ImagePickerControllerImpl.shared.showsAlbumController = Autoloader.imagePickerShowsAlbumController
        
        PluginManager.unloadPlugin(RequestPlugin.self)
        PluginManager.registerPlugin(RequestPlugin.self, object: Autoloader.requestPluginImpl == Autoloader.requestPlugins[0] ? RequestPluginImpl.self : AlamofireImpl.self)
    }
}

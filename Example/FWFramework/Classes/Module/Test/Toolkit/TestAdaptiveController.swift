//
//  TestAdaptiveController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/20.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestAdaptiveController: UIViewController, TableViewControllerProtocol {
    
    var hideToast = false
    
    private lazy var frameLabel: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.textColor = AppTheme.textColor
        result.font = FW.font(15)
        result.textAlignment = .center
        return result
    }()
    
    func setupNavbar() {
        fw.tabBarHidden = true
        fw.observeNotification(UIDevice.orientationDidChangeNotification, target: self, action: #selector(refreshBarFrame))
        
        if !hideToast {
            fw.setRightBarItem("启用") { _ in
                UINavigationController.fw.enableBarTransition()
            }
        } else {
            fw.setLeftBarItem(Icon.closeImage) { [weak self] _ in
                self?.fw.close()
            }
        }
    }
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupTableLayout() {
        view.addSubview(frameLabel)
        frameLabel.fw.layoutChain
            .left(10)
            .right(10)
            .bottom(FW.tabBarHeight + 10)
        
        tableView.backgroundColor = AppTheme.tableColor
        tableView.fw.layoutChain
            .horizontal()
            .top()
            .bottom(toViewTop: frameLabel, offset: -10)
    }
    
    func setupSubviews() {
        tableData.addObjects(from: [
            ["状态栏切换", "onStatusBar"],
            ["状态栏样式", "onStatusStyle"],
            ["导航栏切换", "onNavigationBar"],
            ["导航栏样式", "onNavigationStyle"],
            ["标题栏颜色", "onTitleColor"],
            ["大标题切换", "onLargeTitle"],
            ["标签栏切换", "onTabBar"],
            ["工具栏切换", "onToolBar"],
            ["导航栏转场", "onTransitionBar"],
        ])
        if !hideToast {
            tableData.addObjects(from: [
                ["Present(默认)", "onPresent"],
                ["Present(FullScreen)", "onPresent2"],
                ["Present(PageSheet)", "onPresent3"],
                ["Present(默认带导航栏)", "onPresent4"],
                ["Present(Popover)", "onPresent5:"],
            ])
        } else {
            tableData.addObjects(from: [
                ["Dismiss", "onDismiss"]
            ])
        }
        tableData.addObjects(from: [
            ["设备转向", "onOrientation"]
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !hideToast {
            UIWindow.fw.showMessage(text: "viewWillAppear: \(animated)")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !hideToast {
            UIWindow.fw.showMessage(text: "viewWillDisappear: \(animated)")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshBarFrame()
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
        fw.invokeMethod(NSSelectorFromString(rowData[1]), object: indexPath)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        refreshBarFrame()
    }
    
    override var prefersStatusBarHidden: Bool {
        return fw.statusBarHidden
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return fw.statusBarStyle
    }
    
    @objc func refreshBarFrame() {
        frameLabel.text = String(format: "全局状态栏：%.0f 当前状态栏：%.0f\n全局导航栏：%.0f 当前导航栏：%.0f\n全局顶部栏：%.0f 当前顶部栏：%.0f\n全局标签栏：%.0f 当前标签栏：%.0f\n全局工具栏：%.0f 当前工具栏：%.0f\n全局安全区域：{%.0f, %.0f, %.0f, %.0f}", UIScreen.fw.statusBarHeight, fw.statusBarHeight, UIScreen.fw.navigationBarHeight, fw.navigationBarHeight, UIScreen.fw.topBarHeight, fw.topBarHeight, UIScreen.fw.tabBarHeight, fw.tabBarHeight, UIScreen.fw.toolBarHeight, fw.toolBarHeight, UIScreen.fw.safeAreaInsets.top, UIScreen.fw.safeAreaInsets.left, UIScreen.fw.safeAreaInsets.bottom, UIScreen.fw.safeAreaInsets.right)
    }
    
    @objc func onStatusBar() {
        fw.statusBarHidden = !fw.statusBarHidden
        refreshBarFrame()
    }
    
    @objc func onStatusStyle() {
        if fw.statusBarStyle == .default {
            fw.statusBarStyle = .lightContent
        } else {
            fw.statusBarStyle = .default
        }
        refreshBarFrame()
    }
    
    @objc func onNavigationBar() {
        fw.navigationBarHidden = !fw.navigationBarHidden
        refreshBarFrame()
    }
    
    @objc func onNavigationStyle() {
        if fw.navigationBarStyle == .default {
            fw.navigationBarStyle = .white
        } else {
            fw.navigationBarStyle = .default
        }
        refreshBarFrame()
    }
    
    @objc func onTitleColor() {
        navigationController?.navigationBar.fw.titleAttributes = navigationController?.navigationBar.fw.titleAttributes != nil ? nil : [NSAttributedString.Key.foregroundColor: AppTheme.buttonColor]
        refreshBarFrame()
    }
    
    @objc func onLargeTitle() {
        navigationController?.navigationBar.prefersLargeTitles = !FW.safeValue(navigationController?.navigationBar.prefersLargeTitles)
        refreshBarFrame()
    }
    
    @objc func onTabBar() {
        fw.tabBarHidden = !fw.tabBarHidden
        refreshBarFrame()
    }
    
    @objc func onToolBar() {
        if fw.toolBarHidden {
            let item = UIBarButtonItem.fw.item(object: UIBarButtonItem.SystemItem.cancel.rawValue, target: self, action: #selector(onToolBar))
            let item2 = UIBarButtonItem.fw.item(object: UIBarButtonItem.SystemItem.done.rawValue, target: self, action: #selector(onPresent))
            toolbarItems = [item, item2]
            fw.toolBarHidden = false
        } else {
            fw.toolBarHidden = true
        }
        refreshBarFrame()
    }
    
    @objc func onPresent() {
        let vc = TestAdaptiveController()
        vc.fw.presentationDidDismiss = {
            UIWindow.fw.showMessage(text: "presentationDidDismiss")
        }
        vc.fw.completionHandler = { _ in
            UIWindow.fw.showMessage(text: "completionHandler")
        }
        vc.hideToast = true
        present(vc, animated: true)
    }
    
    @objc func onPresent2() {
        let vc = TestAdaptiveController()
        vc.hideToast = true
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    @objc func onPresent3() {
        let vc = TestAdaptiveController()
        vc.fw.presentationDidDismiss = {
            UIWindow.fw.showMessage(text: "presentationDidDismiss")
        }
        vc.fw.completionHandler = { _ in
            UIWindow.fw.showMessage(text: "completionHandler")
        }
        vc.hideToast = true
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }
    
    @objc func onPresent4() {
        let vc = TestAdaptiveController()
        vc.hideToast = true
        let nav = UINavigationController(rootViewController: vc)
        nav.fw.presentationDidDismiss = {
            UIWindow.fw.showMessage(text: "presentationDidDismiss")
        }
        nav.fw.completionHandler = { _ in
            UIWindow.fw.showMessage(text: "completionHandler")
        }
        present(nav, animated: true)
    }
    
    @objc func onPresent5(_ indexPath: IndexPath) {
        if presentedViewController != nil {
            dismiss(animated: true)
            return
        }
        
        let vc = TestAdaptiveController()
        vc.hideToast = true
        vc.preferredContentSize = CGSize(width: FW.screenWidth / 2, height: FW.screenHeight / 2)
        vc.fw.setPopoverPresentation({ [weak self] controller in
            controller.barButtonItem = self?.navigationItem.rightBarButtonItem
            controller.permittedArrowDirections = .up
            let cell = self?.tableView.cellForRow(at: indexPath)
            controller.passthroughViews = cell != nil ? [cell!] : []
        }, shouldDismiss: [true, false].randomElement()!)
        vc.fw.presentationDidDismiss = {
            UIWindow.fw.showMessage(text: "presentationDidDismiss")
        }
        vc.fw.completionHandler = { _ in
            UIWindow.fw.showMessage(text: "completionHandler")
        }
        present(vc, animated: true)
    }
    
    @objc func onDismiss() {
        dismiss(animated: true) { [weak self] in
            NSLog("self: %@", String(describing: self))
        }
    }
    
    @objc func onTransitionBar() {
        navigationController?.pushViewController(TestAdaptiveChildController(), animated: true)
    }
    
    @objc func onOrientation() {
        if UIDevice.fw.isDeviceLandscape {
            UIDevice.fw.setDeviceOrientation(.portrait)
        } else {
            UIDevice.fw.setDeviceOrientation(.landscapeLeft)
        }
        refreshBarFrame()
    }
    
}

class TestAdaptiveChildController: UIViewController, ViewControllerProtocol {
    
    var index: Int = 0
    
    func setupNavbar() {
        fw.extendedLayoutEdge = .all
        if index < 1 {
            fw.navigationBarStyle = .default
        } else if index < 2 {
            fw.navigationBarStyle = .white
        } else if index < 3 {
            fw.navigationBarStyle = .transparent
        } else {
            fw.navigationBarStyle = .init([-1, 0, 1, 2].randomElement()!)
            fw.navigationBarHidden = fw.navigationBarStyle.rawValue == -1
        }
        navigationItem.title = "标题:\(index + 1) 样式:\(fw.navigationBarStyle.rawValue)"
        
        fw.setRightBarItem("打开界面") { [weak self] _ in
            let vc = TestAdaptiveChildController()
            vc.index = FW.safeValue(self?.index) + 1
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        view.fw.addTapGesture { [weak self] _ in
            let vc = TestAdaptiveChildController()
            vc.index = FW.safeValue(self?.index) + 1
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

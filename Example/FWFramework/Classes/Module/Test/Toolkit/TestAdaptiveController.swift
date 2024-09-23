//
//  TestAdaptiveController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/20.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestAdaptiveController: UIViewController, TableViewControllerProtocol {
    typealias TableElement = [String]

    var hideToast = false
    var globalThread = false

    private lazy var frameLabel: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.textColor = AppTheme.textColor
        result.font = APP.font(15)
        result.textAlignment = .center
        return result
    }()

    func setupNavbar() {
        app.statusBarStyle = .default
        app.statusBarHidden = false
        app.observeNotification(UIDevice.orientationDidChangeNotification, target: self, action: #selector(refreshBarFrame))

        if !hideToast {
            app.setRightBarItem(UIBarButtonItem.SystemItem.action) { [weak self] _ in
                self?.app.showSheet(title: nil, message: nil, actions: [self?.globalThread == true ? "切换主线程调用" : "切换后台线程调用", "启用导航栏转场优化"], actionBlock: { [weak self] index in
                    if index == 0 {
                        self?.globalThread.toggle()
                        self?.refreshBarFrame()
                    } else {
                        UINavigationController.app.enableBarTransition()
                    }
                })
            }
        } else {
            app.setLeftBarItem(Icon.closeImage) { [weak self] _ in
                self?.app.close()
            }
        }
    }

    func setupTableStyle() -> UITableView.Style {
        .grouped
    }

    func setupTableLayout() {
        view.addSubview(frameLabel)
        frameLabel.app.layoutChain
            .left(10)
            .right(10)
            .bottom(APP.safeAreaInsets.bottom + 10)

        tableView.backgroundColor = AppTheme.tableColor
        tableView.app.layoutChain
            .horizontal()
            .top()
            .bottom(toViewTop: frameLabel, offset: -10)
    }

    func setupSubviews() {
        tableData.append(contentsOf: [
            ["状态栏切换", "onStatusBar"],
            ["状态栏样式", "onStatusStyle"],
            ["导航栏切换", "onNavigationBar"],
            ["导航栏样式", "onNavigationStyle"],
            ["标题栏颜色", "onTitleColor"],
            ["大标题切换", "onLargeTitle"],
            ["标签栏切换", "onTabBar"],
            ["工具栏切换", "onToolBar"],
            ["导航栏转场", "onTransitionBar"]
        ])
        if !hideToast {
            tableData.append(contentsOf: [
                ["Present(默认)", "onPresent"],
                ["Present(FullScreen)", "onPresent2"],
                ["Present(PageSheet)", "onPresent3"],
                ["Present(默认带导航栏)", "onPresent4"],
                ["Present(Popover)", "onPresent5:"]
            ])
        } else {
            tableData.append(contentsOf: [
                ["Dismiss", "onDismiss"]
            ])
        }
        tableData.append(contentsOf: [
            ["设备转向", "onOrientation"]
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !hideToast {
            UIWindow.app.showMessage(text: "viewWillAppear: \(animated)")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if !hideToast {
            UIWindow.app.showMessage(text: "viewWillDisappear: \(animated)")
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
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let rowData = tableData[indexPath.row]
        cell.textLabel?.text = rowData[0]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData[indexPath.row]
        _ = perform(NSSelectorFromString(rowData[1]), with: indexPath)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        refreshBarFrame()
    }

    @objc func refreshBarFrame() {
        if !globalThread {
            let barText = String(
                format: "全局状态栏：%.0f 当前状态栏：%.0f\n全局导航栏：%.0f 当前导航栏：%.0f\n全局顶部栏：%.0f 当前顶部栏：%.0f\n全局标签栏：%.0f 当前标签栏：%.0f\n全局工具栏：%.0f 当前工具栏：%.0f\n全局安全区域：{%.0f, %.0f, %.0f, %.0f}\n设备横屏：%@ 界面横屏：%@\n全面屏：%@ 灵动岛：%@",
                UIScreen.app.statusBarHeight, app.statusBarHeight,
                UIScreen.app.navigationBarHeight, app.navigationBarHeight,
                UIScreen.app.topBarHeight, app.topBarHeight,
                UIScreen.app.tabBarHeight, app.tabBarHeight,
                UIScreen.app.toolBarHeight, app.toolBarHeight,
                UIScreen.app.safeAreaInsets.top, UIScreen.app.safeAreaInsets.left, UIScreen.app.safeAreaInsets.bottom, UIScreen.app.safeAreaInsets.right,
                String(describing: UIDevice.app.isDeviceLandscape), String(describing: UIScreen.app.isInterfaceLandscape),
                String(describing: UIScreen.app.isNotchedScreen), String(describing: UIScreen.app.isDynamicIsland)
            )
            frameLabel.text = barText
        } else {
            DispatchQueue.global().async { [weak self] in
                let barText = String(
                    format: "设备尺寸：(%.0f, %.0f) 屏幕尺寸：(%.0f, %.0f)\n是否是iPad：%@ 屏幕缩放比：%.0f\n设计图尺寸：(%.0f, %.0f)\n宽度缩放比：%.3f 高度缩放比：%.3f\n设备横屏：%@ 界面横屏：%@\nIDFV: %@\nIDFA: %@\nUUID: %@",
                    UIDevice.app.deviceWidth, UIDevice.app.deviceHeight, UIScreen.app.screenWidth, UIScreen.app.screenHeight,
                    String(describing: UIDevice.app.isIpad), UIScreen.app.screenScale,
                    UIScreen.app.referenceSize.width, UIScreen.app.referenceSize.height,
                    UIScreen.app.relativeScale, UIScreen.app.relativeHeightScale,
                    String(describing: UIDevice.app.isDeviceLandscape), String(describing: UIScreen.app.isInterfaceLandscape),
                    UIDevice.app.deviceIDFV ?? "",
                    UIDevice.app.deviceIDFA,
                    UIDevice.app.deviceUUID
                )
                DispatchQueue.main.async { [weak self] in
                    self?.frameLabel.text = barText
                }
            }
        }
    }

    @objc func onStatusBar() {
        app.statusBarHidden = !app.statusBarHidden
        refreshBarFrame()
    }

    @objc func onStatusStyle() {
        if app.statusBarStyle == .default {
            app.statusBarStyle = .lightContent
        } else {
            app.statusBarStyle = .default
        }
        refreshBarFrame()
    }

    @objc func onNavigationBar() {
        app.navigationBarHidden = !app.navigationBarHidden
        refreshBarFrame()
    }

    @objc func onNavigationStyle() {
        if app.navigationBarStyle == .default {
            app.navigationBarStyle = .white
        } else {
            app.navigationBarStyle = .default
        }
        refreshBarFrame()
    }

    @objc func onTitleColor() {
        navigationController?.navigationBar.app.titleAttributes = navigationController?.navigationBar.app.titleAttributes != nil ? nil : [NSAttributedString.Key.foregroundColor: AppTheme.buttonColor]
        refreshBarFrame()
    }

    @objc func onLargeTitle() {
        navigationController?.navigationBar.prefersLargeTitles = !APP.safeValue(navigationController?.navigationBar.prefersLargeTitles)
        refreshBarFrame()
    }

    @objc func onTabBar() {
        // iOS18如果hidesBottomBarWhenPushed为true时，需调用tabBar.isHidden才能生效
        let hidden = !app.tabBarHidden
        if hidesBottomBarWhenPushed {
            tabBarController?.tabBar.isHidden = hidden
        }
        app.tabBarHidden = hidden
        refreshBarFrame()
    }

    @objc func onToolBar() {
        if app.toolBarHidden {
            let item = UIBarButtonItem.app.item(object: UIBarButtonItem.SystemItem.cancel.rawValue, target: self, action: #selector(onToolBar))
            let item2 = UIBarButtonItem.app.item(object: UIBarButtonItem.SystemItem.done.rawValue, target: self, action: #selector(onPresent))
            toolbarItems = [item, item2]
            app.toolBarHidden = false
        } else {
            app.toolBarHidden = true
        }
        refreshBarFrame()
    }

    @objc func onPresent() {
        let vc = TestAdaptiveController()
        vc.app.presentationDidDismiss = { @MainActor @Sendable in
            UIWindow.app.showMessage(text: "presentationDidDismiss")
        }
        vc.app.completionHandler = { _ in
            UIWindow.app.showMessage(text: "completionHandler")
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
        vc.app.presentationDidDismiss = { @MainActor @Sendable in
            UIWindow.app.showMessage(text: "presentationDidDismiss")
        }
        vc.app.completionHandler = { _ in
            UIWindow.app.showMessage(text: "completionHandler")
        }
        vc.hideToast = true
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }

    @objc func onPresent4() {
        let vc = TestAdaptiveController()
        vc.hideToast = true
        let nav = UINavigationController(rootViewController: vc)
        nav.app.presentationDidDismiss = { @MainActor @Sendable in
            UIWindow.app.showMessage(text: "presentationDidDismiss")
        }
        nav.app.completionHandler = { _ in
            UIWindow.app.showMessage(text: "completionHandler")
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
        vc.preferredContentSize = CGSize(width: APP.screenWidth / 2, height: APP.screenHeight / 2)
        vc.app.setPopoverPresentation({ [weak self] controller in
            controller.barButtonItem = self?.navigationItem.rightBarButtonItem
            controller.permittedArrowDirections = .up
            let cell = self?.tableView.cellForRow(at: indexPath)
            controller.passthroughViews = cell != nil ? [cell!] : []
        }, shouldDismiss: Bool.random())
        vc.app.presentationDidDismiss = { @MainActor @Sendable in
            UIWindow.app.showMessage(text: "presentationDidDismiss")
        }
        vc.app.completionHandler = { _ in
            UIWindow.app.showMessage(text: "completionHandler")
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
        if UIDevice.app.isDeviceLandscape {
            UIDevice.app.setDeviceOrientation(.portrait)
        } else {
            UIDevice.app.setDeviceOrientation(.landscapeLeft)
        }
        refreshBarFrame()
    }
}

class TestAdaptiveChildController: UIViewController, ViewControllerProtocol {
    var index: Int = 0

    func setupNavbar() {
        app.extendedLayoutEdge = .all
        if index < 1 {
            app.navigationBarStyle = .default
        } else if index < 2 {
            app.navigationBarStyle = .white
        } else if index < 3 {
            app.navigationBarStyle = .transparent
        } else {
            app.navigationBarStyle = .init([-1, 0, 1, 2].randomElement()!)
            app.navigationBarHidden = app.navigationBarStyle.rawValue == -1
        }
        navigationItem.title = "标题:\(index + 1) 样式:\(app.navigationBarStyle.rawValue)"

        app.setRightBarItem("打开界面") { [weak self] _ in
            let vc = TestAdaptiveChildController()
            vc.index = APP.safeValue(self?.index) + 1
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        view.app.addTapGesture { [weak self] _ in
            let vc = TestAdaptiveChildController()
            vc.index = APP.safeValue(self?.index) + 1
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

//
//  TestController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestController: UIViewController {
    var testData: [[Any]] = [
        ["Kernel", [
            ["Router", "TestRouterController"],
            ["Navigator", "TestWorkflowController"],
            ["Promise", "TestPromiseController"],
            ["Concurrency", "TestConcurrencyController"],
            ["State", "TestStateController"]
        ]],
        ["Service", [
            ["Theme", "TestThemeController"],
            ["Authorize", "TestAuthorizeController"],
            ["Notification", "TestNotificationController"],
            ["Cache", "TestCacheController"],
            ["Database", "TestDatabaseController"],
            ["Encode", "TestEncodeController"],
            ["Codable", "TestCodableController"],
            ["Request", "TestRequestController"],
            ["Socket", "TestSocketController"],
            ["AudioPlayer", "TestAudioController"],
            ["VideoPlayer", "TestVideoController"]
        ]],
        ["Toolkit", [
            ["Adaptive", "TestAdaptiveController"],
            ["Compatible", "TestCompatibleController"],
            ["Animation", "TestAnimationController"],
            ["AutoLayout", "TestLayoutController"],
            ["CollectionLayout", "TestCollectionController"],
            ["TableLayout", "TestTableController"],
            ["Keyboard", "TestKeyboardController"],
            ["Thread", "TestThreadController"],
            ["Button", "TestButtonController"],
            ["Icon", "TestIconController"]
        ]],
        ["Plugin", [
            ["AlertPlugin", "TestAlertController"],
            ["EmptyPlugin", "TestEmptyController"],
            ["ToastPlugin", "TestToastController"],
            ["RefreshPlugin", "TestRefreshController"],
            ["ViewPlugin", "TestPluginController"],
            ["ImagePlugin", "TestImageController"],
            ["ImagePicker", "TestPickerController"],
            ["ImageCamera", "TestCameraController"],
            ["ImagePreview", "TestPreviewController"]
        ]],
        ["Module", [
            ["BadgeView", "TestBadgeController"],
            ["BannerView", "TestBannerController"],
            ["BarrageView", "TestBarrageController"],
            ["DrawerView", "TestDrawerController"],
            ["JSBridge", "TestBridgeController"],
            ["ViewController", "TestSwiftController"],
            ["ViewTransition", "TestTransitionController"],
            ["FloatingView", "TestFloatingController"],
            ["GridView", "TestGridController"],
            ["PagingView", "TestPagingController"],
            ["PasscodeView", "TestPasscodeController"],
            ["PopupMenu", "TestPopupController"],
            ["ScanView", "TestQrcodeController"],
            ["ToolbarView", "TestToolbarController"],
            ["TabbarView", "TestTabbarViewController"],
            ["TabbarController", "TestTabbarController"],
            ["SegmentedControl", "TestSegmentController"],
            ["Statistical", "TestStatisticalController"],
            ["SkeletonView", "TestSkeletonController"],
            ["SwiftUI", "TestSwiftUIController"]
        ]]
    ]

    var isSearch: Bool = false
    var searchResult = [Any]()

    // MARK: - Subviews
    private lazy var searchBar: UISearchBar = {
        let result = UISearchBar()
        result.placeholder = "Search"
        result.delegate = self
        result.app.backgroundColor = AppTheme.barColor
        result.app.textFieldBackgroundColor = AppTheme.tableColor
        result.app.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        result.app.searchIconCenter = true
        result.app.searchIconOffset = 10
        result.app.searchTextOffset = 4
        result.app.clearIconOffset = -6

        result.app.font = APP.font(12)
        result.app.textField.app.setCornerRadius(16)
        return result
    }()

    private var displayData: [Any] {
        isSearch ? searchResult : tableData
    }

    // MARK: - Public
    static func mockProgress(_ block: @escaping @MainActor @Sendable (Double, Bool) -> Void) {
        block(0, false)
        DispatchQueue.global().async {
            let progress = SendableObject<Double>(0)
            while progress.object < 1 {
                usleep(50_000)
                progress.object += 0.02
                DispatchQueue.main.async {
                    block(min(progress.object, 1), progress.object >= 1)
                }
            }
        }
    }
}

extension TestController: TableViewControllerProtocol {
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }

    func setupTableView() {
        tableView.backgroundColor = AppTheme.tableColor
        tableView.keyboardDismissMode = .onDrag
    }

    func setupTableLayout() {
        // 示例安全区域布局，scrollView关闭contentInset自适应
        app.adjustExtendedLayout(compatible: true)
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.layoutChain.edges(toSafeArea: .zero)
    }

    func setupNavbar() {
        let titleView = ExpandedTitleView.titleView(searchBar)
        navigationItem.titleView = titleView
    }

    func setupSubviews() {
        tableData.append(contentsOf: testData)
        tableView.reloadData()
    }
}

extension TestController {
    func numberOfSections(in tableView: UITableView) -> Int {
        displayData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionData = displayData[section] as! [Any]
        let sectionList = sectionData[1] as! [Any]
        return sectionList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        cell.accessoryType = .disclosureIndicator
        let sectionData = displayData[indexPath.section] as! [Any]
        let sectionList = sectionData[1] as! [Any]
        let rowData = sectionList[indexPath.row] as! [Any]
        let title = rowData[0] as? String ?? ""
        cell.textLabel?.text = title
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionData = displayData[section] as! [Any]
        return sectionData[0] as? String
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionData = displayData[indexPath.section] as! [Any]
        let sectionList = sectionData[1] as! [Any]
        let rowData = sectionList[indexPath.row] as! [Any]
        let title = rowData[0] as? String ?? ""

        var className = rowData[1] as! String
        var controllerClass: AnyClass? = NSClassFromString(className)
        if controllerClass == nil {
            className = UIApplication.app.appExecutable + "." + className
            controllerClass = NSClassFromString(className)
        }

        if let controllerClass = controllerClass as? UIViewController.Type {
            let viewController = controllerClass.init()
            viewController.navigationItem.title = title
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

extension TestController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.app.searchIconCenter = false
        return true
    }

    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.app.searchIconCenter = true
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearch = !searchText.app.trimString.isEmpty
        if !isSearch {
            searchResult.removeAll()
            tableView.reloadData()
            return
        }

        var resultData: [Any] = []
        for sectionData in tableData as! [NSArray] {
            var sectionResult: [Any] = []
            for rowData in sectionData[1] as! [NSArray] {
                if APP.safeString(rowData[0]).lowercased()
                    .contains(searchText.app.trimString.lowercased()) {
                    sectionResult.append(rowData)
                }
            }
            if sectionResult.count > 0 {
                resultData.append([sectionData[0], sectionResult])
            }
        }
        searchResult = resultData
        tableView.reloadData()
    }
}

extension TestController: TabControllerDelegate {
    func tabBarItemClicked() {
        tableView.app.scroll(to: .top)
    }
}

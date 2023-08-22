//
//  TestController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework
import Darwin

@objcMembers class TestController: UIViewController {
    
    var testData: [[Any]] = [
        ["Kernel", [
            ["Router", "TestRouterController"],
            ["Navigator", "TestWorkflowController"],
            ["Promise", "TestPromiseController"],
            ["State", "TestStateController"],
        ]],
        ["Service", [
            ["Theme", "TestThemeController"],
            ["Authorize", "TestAuthorizeController"],
            ["Notification", "TestNotificationController"],
            ["Cache", "TestCacheController"],
            ["Database", "TestDatabaseController"],
            ["Socket", "TestSocketController"],
            ["AudioPlayer", "TestAudioController"],
            ["VideoPlayer", "TestVideoController"],
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
            ["Icon", "TestIconController"],
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
            ["ImagePreview", "TestPreviewController"],
        ]],
        ["Module", [
            ["BadgeView", "TestBadgeController"],
            ["BannerView", "TestBannerController"],
            ["BarrageView", "TestBarrageController"],
            ["DrawerView", "TestDrawerController"],
            ["JSBridge", "TestBridgeController"],
            ["ViewController", "TestSwiftController"],
            ["ViewTransition", "TestTransitionController"],
            ["FloatLayoutView", "TestFloatController"],
            ["GridView", "TestGridController"],
            ["PagingView", "TestPagingController"],
            ["PasscodeView", "TestPasscodeController"],
            ["PopupMenu", "TestPopupController"],
            ["ScanView", "TestQrcodeController"],
            ["ToolbarView", "TestToolbarController"],
            ["TabbarController", "TestTabbarController"],
            ["SegmentedControl", "TestSegmentController"],
            ["Statistical", "TestStatisticalController"],
            ["SkeletonView", "TestSkeletonController"],
            ["SwiftUI", "TestSwiftUIController"],
        ]],
    ]
    
    var isSearch: Bool = false
    var searchResult = NSMutableArray()
    
    // MARK: - Subviews
    private lazy var searchBar: UISearchBar = {
        let result = UISearchBar(frame: CGRect(x: 0, y: 0, width: FW.screenWidth, height: FW.navigationBarHeight))
        result.placeholder = "Search"
        result.delegate = self
        result.showsCancelButton = true
        result.fw.cancelButton?.setTitle(AppBundle.cancelButton, for: .normal)
        result.fw.forceCancelButtonEnabled = true
        result.fw.backgroundColor = AppTheme.barColor
        result.fw.textFieldBackgroundColor = AppTheme.tableColor
        result.fw.contentInset = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 0)
        result.fw.cancelButtonInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        result.fw.searchIconCenter = true
        result.fw.searchIconOffset = 10
        result.fw.searchTextOffset = 4
        
        if let textField = result.fw.textField {
            textField.font = FW.font(12)
            textField.fw.setCornerRadius(16)
            textField.fw.touchResign = true
        }
        return result
    }()
    
    private lazy var titleView: UIView = {
        let titleView = TestExpandedView()
        titleView.frame = CGRect(x: 0, y: 0, width: FW.screenWidth, height: FW.navigationBarHeight)
        titleView.fw.layoutChain.height(FW.navigationBarHeight)
        titleView.backgroundColor = UIColor.clear
        titleView.addSubview(searchBar)
        searchBar.fw.layoutChain.edges()
        return titleView
    }()
    
    private var displayData: NSArray {
        return isSearch ? searchResult : tableData
    }
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchBar.fw.cancelButton?.setTitle(AppBundle.cancelButton, for: .normal)
    }
    
    // MARK: - Public
    static func mockProgress(_ block: @escaping (Double, Bool) -> Void) {
        block(0, false)
        DispatchQueue.global().async {
            var progress: Double = 0
            while progress < 1 {
                usleep(50000)
                progress += 0.02
                DispatchQueue.main.async {
                    block(min(progress, 1), progress >= 1)
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
    
    func setupNavbar() {
        navigationItem.titleView = titleView
    }
    
    func setupSubviews() {
        tableData.addObjects(from: testData)
        tableView.reloadData()
    }
    
}

extension TestController {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return displayData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionData = displayData.object(at: section) as! NSArray
        let sectionList = sectionData.object(at: 1) as! NSArray
        return sectionList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(tableView: tableView)
        cell.accessoryType = .disclosureIndicator
        let sectionData = displayData.object(at: indexPath.section) as! NSArray
        let sectionList = sectionData.object(at: 1) as! NSArray
        let rowData = sectionList.object(at: indexPath.row) as! NSArray
        cell.textLabel?.text = rowData.object(at: 0) as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionData = displayData.object(at: section) as! NSArray
        return sectionData.object(at: 0) as? String
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionData = displayData.object(at: indexPath.section) as! NSArray
        let sectionList = sectionData.object(at: 1) as! NSArray
        let rowData = sectionList.object(at: indexPath.row) as! NSArray
        
        var className = rowData.object(at: 1) as! String
        var controllerClass: AnyClass? = NSClassFromString(className)
        if controllerClass == nil {
            className = UIApplication.fw.appExecutable + "." + className
            controllerClass = NSClassFromString(className)
        }
        
        if let controllerClass = controllerClass as? UIViewController.Type {
            let viewController = controllerClass.init()
            viewController.navigationItem.title = rowData.object(at: 0) as? String
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
}

extension TestController: UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.fw.searchIconCenter = false
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.fw.searchIconCenter = true
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearch = !searchText.fw.trimString.isEmpty
        if !isSearch {
            searchResult.removeAllObjects()
            tableView.reloadData()
            return
        }
        
        var resultData: [Any] = []
        for sectionData in tableData as! [NSArray] {
            var sectionResult: [Any] = []
            for rowData in sectionData[1] as! [NSArray] {
                if FW.safeString(rowData[0]).lowercased()
                    .contains(searchText.fw.trimString.lowercased()) {
                    sectionResult.append(rowData)
                }
            }
            if sectionResult.count > 0 {
                resultData.append([sectionData[0], sectionResult])
            }
        }
        searchResult.setArray(resultData)
        tableView.reloadData()
    }
    
}

class TestExpandedView: UIView {
    
    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
    
}

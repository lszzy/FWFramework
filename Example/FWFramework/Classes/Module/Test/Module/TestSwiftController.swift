//
//  TestSwiftController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestSwiftController: UIViewController, TableViewControllerProtocol {
    
    func setupSubviews() {
        tableData.append(contentsOf: [
            "ViewController",
            "CollectionViewController",
            "ScrollViewController",
            "TableViewController",
            "WebViewController",
            "PopupViewController",
            "RequestViewController",
            "TestSwiftProtocol默认实现",
            "TestSwiftProtocol类实现",
            "TestSwiftProtocol继承实现",
            "TestObjcProtocol默认实现",
            "TestObjcProtocol类实现",
            "TestObjcProtocol继承实现",
            "InvokeMethod返回对象",
            "InvokeMethod返回整数",
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let value = tableData[indexPath.row] as? String
        cell.textLabel?.text = value
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var viewController: UIViewController? = nil
        switch indexPath.row {
        case 1:
            viewController = SwiftTestCollectionViewController()
        case 2:
            viewController = SwiftTestScrollViewController()
        case 3:
            viewController = SwiftTestTableViewController()
        case 4:
            viewController = SwiftTestWebViewController()
        case 5:
            let popupController = SwiftTestPopupViewController()
            if [true, false].randomElement()! {
                present(popupController, animated: true)
            } else {
                present(popupController.wrappedNavigationController(), animated: true)
            }
            return
        case 6:
            viewController = SwiftTestRequestViewController()
        case 7:
            viewController = TestSwiftProtocolDefaultController()
        case 8:
            viewController = TestSwiftProtocolBaseController()
        case 9:
            viewController = TestSwiftProtocolViewController()
        case 10:
            viewController = TestObjcProtocolDefaultController()
        case 11:
            viewController = TestObjcProtocolBaseController()
        case 12:
            viewController = TestObjcProtocolViewController()
        case 13:
            let value = app.invokeMethod(#selector(self.onInvokeObject(param1:param2:param3:)), objects: ["参数1", NSNull(), "3"])?.takeUnretainedValue() as? String
            app.showMessage(text: value != nil ? "调用成功：\(value!)" : "调用失败")
            return
        case 14:
            let value = app.invokeMethod(#selector(self.onInvokeInt(param1:param2:param3:)), objects: [NSObject(), NSNull(), NSNumber(value: 3)])?.takeUnretainedValue() as? Int
            app.showMessage(text: value != nil ? "调用成功：\(value!)" : "调用失败")
            return
        default:
            viewController = SwiftTestViewController()
        }
        viewController?.navigationItem.title = tableData[indexPath.row] as? String
        navigationController?.pushViewController(viewController!, animated: true)
    }
    
    @objc func onInvokeObject(param1: NSObject, param2: Any?, param3: String) -> String {
        return "\(param1.description)-\(String(describing: param2))-\(param3)"
    }
    
    @objc func onInvokeInt(param1: NSObject, param2: Any?, param3: Int) -> Int {
        return param3
    }
    
}

class SwiftTestViewController: UIViewController, ViewControllerProtocol {
    var state: ViewState = .ready {
        didSet {
            setupSubviews()
        }
    }
    
    func setupSubviews() {
        switch state {
        case .ready:
            view.backgroundColor = AppTheme.backgroundColor
            state = .loading
        case .loading:
            view.app.showLoading(text: "开始加载")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.view.app.hideLoading()
                
                if [0, 1].randomElement() == 1 {
                    self?.state = .success("加载成功")
                } else {
                    self?.state = .failure(NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "加载失败"]))
                }
            }
        case .success(let object):
            view.app.showEmptyView(text: object as? String)
        case .failure(let error):
            view.app.showEmptyView(text: error?.localizedDescription, detail: nil, image: nil, action: "重新加载") { [weak self] (sender) in
                self?.view.app.hideEmptyView()
                
                self?.state = .loading
            }
        }
    }
    
}

class SwiftTestRequestViewController: UIViewController, ViewControllerProtocol, RequestViewControllerProtocol {
    var dataModel: String = ""
    
    func setupSubviews() {
        view.backgroundColor = AppTheme.backgroundColor
        
        requestData()
    }
    
    func setupData() {
        view.app.showEmptyView(text: dataModel)
    }
    
    func startDataRequest(isRefreshing: Bool, completion: @escaping Completion) {
        let request = TestModelRequest()
        request.testFailed = [0, 1].randomElement() == 0
        request.start { request in
            self.dataModel = Date(timeIntervalSince1970: request.responseServerTime).app.stringValue
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                completion(request, true)
            }
        } failure: { request in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                completion(request, false)
            }
        }
    }
    
    func showRequestLoading(isShowing: Bool) {
        if isShowing {
            if !app.isDataLoaded {
                app.showEmptyLoading()
            }
        } else {
            app.hideEmptyView()
        }
    }
    
}

class SwiftTestCollectionViewController: UIViewController, CollectionDelegateControllerProtocol, CollectionViewDelegateFlowLayout {
    lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.layer.masksToBounds = true
        return contentView
    }()
    
    lazy var flowLayout: CollectionViewFlowLayout = {
        let flowLayout = CollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = .zero
        flowLayout.scrollDirection = .horizontal
        flowLayout.verticalColumnCount = 4
        flowLayout.verticalRowCount = 3
        return flowLayout
    }()
    
    lazy var centerView: UICollectionView = {
        let layout = CollectionViewFlowLayout()
        layout.isPagingEnabled = true
        layout.isPagingCenter = true
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        layout.itemSize = CGSize(width: APP.screenWidth - 60, height: 150)
        
        let result = UICollectionView.app.collectionView(layout)
        result.decelerationRate = .fast
        result.backgroundColor = AppTheme.backgroundColor
        result.delegate = result.app.collectionDelegate
        result.dataSource = result.app.collectionDelegate
        result.app.collectionDelegate.itemCount = 10
        result.app.collectionDelegate.cellForItem = { collectionView, indexPath in
            let cell = UICollectionViewCell.app.cell(collectionView: collectionView, indexPath: indexPath)
            cell.contentView.backgroundColor = UIColor.app.randomColor
            return cell
        }
        result.app.collectionDelegate.didSelectItem = { [weak self] collectionView, indexPath in
            layout.scrollToPage(indexPath.item)
        }
        return result
    }()
    
    lazy var bottomView: UICollectionView = {
        let layout = CollectionViewFlowLayout()
        layout.isPagingEnabled = true
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        layout.itemSize = CGSize(width: (APP.screenWidth - 40) / 3.0 * 2.0, height: 150)
        
        let result = UICollectionView.app.collectionView(layout)
        result.decelerationRate = .fast
        result.backgroundColor = AppTheme.backgroundColor
        result.delegate = result.app.collectionDelegate
        result.dataSource = result.app.collectionDelegate
        result.app.collectionDelegate.itemCount = 10
        result.app.collectionDelegate.cellForItem = { collectionView, indexPath in
            let cell = UICollectionViewCell.app.cell(collectionView: collectionView, indexPath: indexPath)
            cell.contentView.backgroundColor = UIColor.app.randomColor
            return cell
        }
        result.app.collectionDelegate.didSelectItem = { [weak self] collectionView, indexPath in
            layout.scrollToPage(indexPath.item)
        }
        return result
    }()
    
    func setupCollectionViewLayout() -> UICollectionViewLayout {
        return flowLayout
    }
    
    func setupCollectionView() {
        view.backgroundColor = AppTheme.backgroundColor
        collectionView.backgroundColor = AppTheme.tableColor
        collectionView.isPagingEnabled = true
        collectionDelegate.sectionCount = 2
        collectionDelegate.numberOfItems = { [weak self] _ in
            guard let self = self else { return 0 }
            return self.flowLayout.itemRenderCount(self.collectionData.count)
        }
        collectionDelegate.cellForItem = { [weak self] collectionView, indexPath in
            guard let self = self else { return nil }
            let cell = UICollectionViewCell.app.cell(collectionView: collectionView, indexPath: indexPath)
            var label = cell.contentView.viewWithTag(100) as? UILabel
            if label == nil {
                let textLabel = UILabel.app.label(font: .systemFont(ofSize: 16), textColor: .white)
                label = textLabel
                textLabel.tag = 100
                cell.contentView.addSubview(textLabel)
                textLabel.app.layoutChain.center()
            }
            if indexPath.item < self.collectionData.count {
                label?.text = "\(indexPath.section) : \(indexPath.item)"
            } else {
                label?.text = nil
            }
            return cell
        }
        collectionDelegate.sizeForItem = { collectionView, indexPath in
            return CGSize(width: (APP.screenWidth - 40) / 4, height: indexPath.item % 3 == 0 ? 70 : 40)
        }
        collectionDelegate.viewForHeader = { collectionView, indexPath in
            let view = UICollectionReusableView.app.reusableView(collectionView: collectionView, kind: UICollectionView.elementKindSectionHeader, indexPath: indexPath)
            view.backgroundColor = UIColor.app.randomColor
            return view
        }
        collectionDelegate.viewForFooter = { collectionView, indexPath in
            let view = UICollectionReusableView.app.reusableView(collectionView: collectionView, kind: UICollectionView.elementKindSectionFooter, indexPath: indexPath)
            view.backgroundColor = UIColor.app.randomColor
            return view
        }
        collectionDelegate.sizeForHeader = { collectionView, section in
            return CGSize(width: 40, height: 150)
        }
        collectionDelegate.sizeForFooter = { collectionView, section in
            return CGSize(width: 40, height: 150)
        }
        collectionDelegate.didSelectItem = { [weak self] collectionView, indexPath in
            guard let self = self else { return }
            if indexPath.item < self.collectionData.count {
                self.app.showMessage(text: "点击section: \(indexPath.section) item: \(indexPath.item)")
            }
        }
    }
    
    func setupCollectionLayout() {
        view.addSubview(contentView)
        contentView.app.layoutChain
            .horizontal()
            .top(toSafeArea: .zero)
            .height(150)
        
        collectionView.removeFromSuperview()
        contentView.addSubview(collectionView)
        collectionView.app.layoutChain.edges(excludingEdge: .bottom).height(150)
        
        view.addSubview(centerView)
        centerView.app.layoutChain
            .horizontal()
            .top(toViewBottom: contentView, offset: 20)
            .height(150)
        
        view.addSubview(bottomView)
        bottomView.app.layoutChain
            .horizontal()
            .top(toViewBottom: centerView, offset: 20)
            .height(150)
    }
    
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] (sender) in
            guard let self = self else { return }
            
            self.flowLayout.itemRenderVertical = !self.flowLayout.itemRenderVertical
            self.collectionView.reloadData()
        }
    }
    
    func setupSubviews() {
        for _ in 0 ..< 18 {
            collectionData.append(UIColor.app.randomColor)
        }
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, configForSectionAt section: Int) -> CollectionViewSectionConfig? {
        let sectionConfig = CollectionViewSectionConfig()
        sectionConfig.backgroundColor = UIColor.app.randomColor
        return sectionConfig
    }
    
}

class SwiftTestScrollViewController: UIViewController, ScrollViewControllerProtocol {
    func setupScrollView() {
        let view = UIView()
        view.backgroundColor = UIColor.app.randomColor
        contentView.addSubview(view)
        view.app.layoutMaker { (make) in
            make.edges().height(1000).width(APP.screenWidth)
        }
    }
}

class SwiftTestTableViewController: UIViewController, TableDelegateControllerProtocol, RequestViewControllerProtocol {
    class Cell: UITableViewCell {
        var index: Int = 0
    }
    
    func setupTableView() {
        view.backgroundColor = AppTheme.backgroundColor
        tableDelegate.cellClass = Cell.self
        tableDelegate.numberOfRows = { [weak self] _ in
            return self?.tableData.count ?? 0
        }
        tableDelegate.cellConfiguation = { cell, indexPath in
            let cell = cell as! Cell
            cell.app.maxYViewExpanded = true
            cell.index = indexPath.row
            cell.textLabel?.text = "\(indexPath.row)"
        }
        tableView.app.setRefreshing { [weak self] in
            self?.requestData()
        }
        tableView.app.setLoading { [weak self] in
            self?.loadingData()
        }
    }
    
    func setupSubviews() {
        if [0, 1].randomElement() == 1 {
            tableView.app.beginRefreshing()
        } else {
            tableView.isHidden = true
            requestData()
        }
    }
    
    func startDataRequest(isRefreshing: Bool, completion: @escaping Completion) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if [0, 1, 2].randomElement() != 0 {
                if isRefreshing {
                    self?.tableData.removeAll()
                }
                let count = self?.tableData.count ?? 0
                self?.tableData.append(contentsOf: [count, count + 1, count + 2])
                
                let request = HTTPRequest()
                completion(request, count >= 12)
            } else {
                let request = HTTPRequest()
                request.error = NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "请求失败"])
                completion(request, false)
            }
        }
    }
}

class SwiftTestWebViewController: UIViewController, WebViewControllerProtocol {
    func setupWebView() {
        webView.app.navigationItems = [
            Icon.backImage as Any,
            Icon.closeImage as Any
        ]
        
        webRequest = "http://kvm.wuyong.site/test.php"
    }
}

class SwiftTestPopupViewController: UIViewController, PopupViewControllerProtocol {
    func setupPopupConfiguration(_ configuration: PopupConfiguration) {
        let edges: [UIRectEdge] = [.bottom, .top, .left, .right, .all]
        let edge = edges.randomElement()!
        if edge == .all {
            configuration.centerAnimation = true
            configuration.alertAnimation = [true, false].randomElement()!
            configuration.padding = 50
        } else {
            configuration.animationEdge = edge
            configuration.padding = 0
        }
        configuration.cornerRadius = 8
        configuration.interactEnabled = [true, false].randomElement()!
        configuration.interactScreenEdge = [true, false].randomElement()!
        configuration.dismissCompletion = {
            print("Popup已关闭")
            UIWindow.app.showMessage(text: "Popup已关闭")
        }
    }
    
    func setupPopupView() {
        guard navigationController != nil else { return }
        
        popupView.backgroundColor = UIColor.app.randomColor
        popupView.app.addTapGesture { _ in
            Router.openURL("https://www.baidu.com")
        }
    }
    
    func setupPopupLayout() {
        let useWidth = popupConfiguration.animationEdge == .left || popupConfiguration.animationEdge == .right
        if !popupConfiguration.centerAnimation, useWidth {
            popupView.app.layoutChain.width(APP.screenWidth / 2.0)
        } else {
            popupView.app.layoutChain.height(APP.screenHeight / 2.0)
        }
    }
}

protocol TestSwiftProtocol {
    func testMethod()
}

extension TestSwiftProtocol where Self: UIViewController {
    func testMethod() {
        UIWindow.app.showMessage(text: "TestSwiftProtocol.testMethod") { [weak self] in
            self?.app.close()
        }
    }
}

class TestSwiftProtocolDefaultController: UIViewController, ViewControllerProtocol, TestSwiftProtocol {
    func setupSubviews() {
        view.backgroundColor = AppTheme.backgroundColor
        view.app.addTapGesture { [weak self] _ in
            self?.testMethod()
        }
    }
}

class TestSwiftProtocolBaseController: UIViewController, ViewControllerProtocol, TestSwiftProtocol {
    func setupSubviews() {
        view.backgroundColor = AppTheme.backgroundColor
        view.app.addTapGesture { [weak self] _ in
            self?.testMethod()
        }
    }
    
    // 如果testMethod方法放到extension中，则不能继承; 非extension中可以继承
    func testMethod() {
        UIWindow.app.showMessage(text: "SwiftBaseController.testMethod") { [weak self] in
            self?.app.close()
        }
    }
}

class TestSwiftProtocolViewController: TestSwiftProtocolBaseController {
    // 父类testMethod必须放到非extension中，否则编译报错
    override func testMethod() {
        UIWindow.app.showMessage(text: "SwiftViewController.testMethod") { [weak self] in
            self?.app.close()
        }
    }
}

@objc protocol TestObjcProtocol {
    func testObjcMethod()
    // @objc optional func testObjcMethod()
}

extension UIViewController {
    @objc func testObjcMethod() {
        UIWindow.app.showMessage(text: "TestObjcProtocol.testObjcMethod") { [weak self] in
            self?.app.close()
        }
    }
}

class TestObjcProtocolDefaultController: UIViewController, ViewControllerProtocol, TestObjcProtocol {
    func setupSubviews() {
        view.backgroundColor = AppTheme.backgroundColor
        view.app.addTapGesture { [weak self] _ in
            self?.testObjcMethod()
        }
    }
}

class TestObjcProtocolBaseController: UIViewController, ViewControllerProtocol {
    func setupSubviews() {
        view.backgroundColor = AppTheme.backgroundColor
        view.app.addTapGesture { [weak self] _ in
            self?.testObjcMethod()
        }
    }
}

extension TestObjcProtocolBaseController: TestObjcProtocol {
    override func testObjcMethod() {
        UIWindow.app.showMessage(text: "ObjcBaseController.testObjcMethod") { [weak self] in
            self?.app.close()
        }
    }
}

class TestObjcProtocolViewController: TestObjcProtocolBaseController {
    override func testObjcMethod() {
        UIWindow.app.showMessage(text: "ObjcViewController.testObjcMethod") { [weak self] in
            self?.app.close()
        }
    }
}

//
//  TestSwiftController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestSwiftController: UIViewController, TableViewControllerProtocol {
    
    func setupNavbar() {
        fw.setRightBarItem("Popup") { _ in
            let viewController = SwiftTestPopupViewController()
            Navigator.present(viewController, animated: true)
        }
    }
    
    func setupSubviews() {
        tableData.append(contentsOf: [
            "ViewController",
            "CollectionViewController",
            "ScrollViewController",
            "TableViewController",
            "WebViewController",
            "TestSwiftProtocol默认实现",
            "TestSwiftProtocol类实现",
            "TestSwiftProtocol继承实现",
            "TestObjcProtocol默认实现",
            "TestObjcProtocol类实现",
            "TestObjcProtocol继承实现"
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(tableView: tableView)
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
            viewController = TestSwiftProtocolDefaultController()
        case 6:
            viewController = TestSwiftProtocolBaseController()
        case 7:
            viewController = TestSwiftProtocolViewController()
        case 8:
            viewController = TestObjcProtocolDefaultController()
        case 9:
            viewController = TestObjcProtocolBaseController()
        case 10:
            viewController = TestObjcProtocolViewController()
        default:
            viewController = SwiftTestViewController()
        }
        viewController?.navigationItem.title = tableData[indexPath.row] as? String
        navigationController?.pushViewController(viewController!, animated: true)
    }
    
}

class SwiftTestViewController: UIViewController, ViewControllerProtocol {
    var state: ViewControllerLoadState = .ready {
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
            view.fw.showLoading(text: "开始加载")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.view.fw.hideLoading()
                
                if [0, 1].randomElement() == 1 {
                    self?.state = .success("加载成功")
                } else {
                    self?.state = .failure(NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "加载失败"]))
                }
            }
        case .success(let object):
            view.fw.showEmptyView(text: object as? String)
        case .failure(let error):
            view.fw.showEmptyView(text: error?.localizedDescription, detail: nil, image: nil, action: "重新加载") { [weak self] (sender) in
                self?.view.fw.hideEmptyView()
                
                self?.state = .loading
            }
        }
    }
    
}

class SwiftTestCollectionViewController: UIViewController, CollectionViewControllerProtocol, CollectionViewDelegateFlowLayout {
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
        flowLayout.columnCount = 4
        flowLayout.rowCount = 3
        return flowLayout
    }()
    
    func setupCollectionViewLayout() -> UICollectionViewLayout {
        return flowLayout
    }
    
    func setupCollectionView() {
        view.backgroundColor = AppTheme.backgroundColor
        collectionView.backgroundColor = AppTheme.tableColor
        collectionView.isPagingEnabled = true
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "view")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "view")
    }
    
    func setupCollectionLayout() {
        view.addSubview(contentView)
        contentView.fw.layoutChain
            .horizontal()
            .top(toSafeArea: .zero)
            .height(200)
        
        collectionView.removeFromSuperview()
        contentView.addSubview(collectionView)
        collectionView.fw.layoutChain.edges(excludingEdge: .bottom).height(200)
    }
    
    func setupNavbar() {
        fw.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] (sender) in
            guard let self = self else { return }
            
            self.flowLayout.itemRenderVertical = !self.flowLayout.itemRenderVertical
            self.collectionView.reloadData()
        }
    }
    
    func setupSubviews() {
        for _ in 0 ..< 18 {
            collectionData.append(UIColor.fw.randomColor)
        }
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return flowLayout.itemRenderCount(collectionData.count)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        var label = cell.contentView.viewWithTag(100) as? UILabel
        if label == nil {
            let textLabel = UILabel.fw.label(font: .systemFont(ofSize: 16), textColor: .white)
            label = textLabel
            textLabel.tag = 100
            cell.contentView.addSubview(textLabel)
            textLabel.fw.layoutChain.center()
        }
        if indexPath.item < collectionData.count {
            label?.text = "\(indexPath.section) : \(indexPath.item)"
        } else {
            label?.text = nil
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "view", for: indexPath)
        view.backgroundColor = UIColor.fw.randomColor
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, configForSectionAt section: Int) -> CollectionViewSectionConfig? {
        let sectionConfig = CollectionViewSectionConfig()
        sectionConfig.backgroundColor = UIColor.fw.randomColor
        return sectionConfig
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (FW.screenWidth - 40) / 4, height: indexPath.item % 3 == 0 ? 80 : 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 40, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: 40, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < collectionData.count {
            view.fw.showMessage(text: "点击section: \(indexPath.section) item: \(indexPath.item)")
        }
    }
    
}

class SwiftTestScrollViewController: UIViewController, ScrollViewControllerProtocol {
    func setupScrollView() {
        let view = UIView()
        view.backgroundColor = UIColor.fw.randomColor
        contentView.addSubview(view)
        view.fw.layoutMaker { (make) in
            make.edges().height(1000).width(FW.screenWidth)
        }
    }
}

class SwiftTestTableViewController: UIViewController, TableViewControllerProtocol {
    func setupTableView() {
        view.backgroundColor = AppTheme.backgroundColor
    }
    
    func setupSubviews() {
        tableData.append(contentsOf: [0, 1, 2])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }
}

class SwiftTestWebViewController: UIViewController, WebViewControllerProtocol {
    func setupWebView() {
        webView.fw.navigationItems = [
            Icon.backImage as Any,
            Icon.closeImage as Any
        ]
        
        webRequest = "http://kvm.wuyong.site/test.php"
    }
}

class SwiftTestPopupViewController: UIViewController, ViewControllerProtocol {
    // MARK: - Accessor
    lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.fw.addTapGesture { [weak self] _ in
            self?.fw.close()
        }
        return view
    }()
    
    lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    // MARK: - Lifecycle
    func didInitialize() {
        modalPresentationStyle = .custom
        fw.navigationBarHidden = true
        fw.setPresentTransition(nil)
    }
    
    func setupSubviews() {
        view.backgroundColor = .clear
        view.addSubview(backgroundView)
        view.addSubview(contentView)
        backgroundView.fw.layoutChain
            .edges(excludingEdge: .bottom)
        contentView.fw.layoutChain
            .edges(excludingEdge: .top)
            .top(toViewBottom: backgroundView)
        
        contentView.fw.layoutChain.height(FW.screenHeight / 2.0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.fw.setCornerLayer([.topLeft, .topRight], radius: 8)
    }
}

protocol TestSwiftProtocol {
    func testMethod()
}

extension TestSwiftProtocol where Self: UIViewController {
    func testMethod() {
        UIWindow.fw.showMessage(text: "TestSwiftProtocol.testMethod") { [weak self] in
            self?.fw.close()
        }
    }
}

class TestSwiftProtocolDefaultController: UIViewController, ViewControllerProtocol, TestSwiftProtocol {
    func setupSubviews() {
        view.backgroundColor = AppTheme.backgroundColor
        view.fw.addTapGesture { [weak self] _ in
            self?.testMethod()
        }
    }
}

class TestSwiftProtocolBaseController: UIViewController, ViewControllerProtocol, TestSwiftProtocol {
    func setupSubviews() {
        view.backgroundColor = AppTheme.backgroundColor
        view.fw.addTapGesture { [weak self] _ in
            self?.testMethod()
        }
    }
    
    // 如果testMethod方法放到extension中，则不能继承; 非extension中可以继承
    func testMethod() {
        UIWindow.fw.showMessage(text: "SwiftBaseController.testMethod") { [weak self] in
            self?.fw.close()
        }
    }
}

class TestSwiftProtocolViewController: TestSwiftProtocolBaseController {
    // 父类testMethod必须放到非extension中，否则编译报错
    override func testMethod() {
        UIWindow.fw.showMessage(text: "SwiftViewController.testMethod") { [weak self] in
            self?.fw.close()
        }
    }
}

@objc protocol TestObjcProtocol {
    func testObjcMethod()
    // @objc optional func testObjcMethod()
}

extension UIViewController {
    @objc func testObjcMethod() {
        UIWindow.fw.showMessage(text: "TestObjcProtocol.testObjcMethod") { [weak self] in
            self?.fw.close()
        }
    }
}

class TestObjcProtocolDefaultController: UIViewController, ViewControllerProtocol, TestObjcProtocol {
    func setupSubviews() {
        view.backgroundColor = AppTheme.backgroundColor
        view.fw.addTapGesture { [weak self] _ in
            self?.testObjcMethod()
        }
    }
}

class TestObjcProtocolBaseController: UIViewController, ViewControllerProtocol {
    func setupSubviews() {
        view.backgroundColor = AppTheme.backgroundColor
        view.fw.addTapGesture { [weak self] _ in
            self?.testObjcMethod()
        }
    }
}

extension TestObjcProtocolBaseController: TestObjcProtocol {
    override func testObjcMethod() {
        UIWindow.fw.showMessage(text: "ObjcBaseController.testObjcMethod") { [weak self] in
            self?.fw.close()
        }
    }
}

class TestObjcProtocolViewController: TestObjcProtocolBaseController {
    override func testObjcMethod() {
        UIWindow.fw.showMessage(text: "ObjcViewController.testObjcMethod") { [weak self] in
            self?.fw.close()
        }
    }
}

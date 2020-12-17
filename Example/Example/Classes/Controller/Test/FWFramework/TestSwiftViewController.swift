//
//  TestSwiftViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

@objcMembers class TestSwiftViewController: BaseTableViewController {
    override func renderData() {
        tableData.addObjects(from: [
            "FWViewController",
            "FWCollectionViewController",
            "FWScrollViewController",
            "FWTableViewController",
            "FWWebViewController",
        ])
    }
    
    override func renderCellData(_ cell: UITableViewCell!, indexPath: IndexPath!) {
        let value = tableData.object(at: indexPath.row) as? String
        cell.textLabel?.text = value
        cell.accessoryType = .disclosureIndicator
    }
    
    override func onCellSelect(_ indexPath: IndexPath!) {
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
        default:
            viewController = SwiftTestViewController()
        }
        viewController?.title = tableData.object(at: indexPath.row) as? String
        navigationController?.pushViewController(viewController!, animated: true)
    }
}

@objcMembers class SwiftTestViewController: UIViewController, FWViewController {
    func renderView() {
        view.backgroundColor = UIColor.fwRandom()
    }
}

@objcMembers class SwiftTestCollectionViewController: UIViewController, FWCollectionViewController, UICollectionViewDelegateFlowLayout {
    lazy var flowLayout: FWCollectionViewFlowLayout = {
        let flowLayout = FWCollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = .zero
        flowLayout.scrollDirection = .horizontal
        flowLayout.columnCount = 4
        flowLayout.rowCount = 3
        return flowLayout
    }()
    
    func renderCollectionViewLayout() -> UICollectionViewLayout {
        return flowLayout
    }
    
    func renderCollectionView() {
        view.backgroundColor = UIColor.appColorBg()
        collectionView.backgroundColor = UIColor.appColorTable()
        collectionView.isPagingEnabled = true
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    }
    
    func renderCollectionLayout() {
        collectionView.fwLayoutChain.edges(excludingEdge: .bottom).height(200)
    }
    
    func renderModel() {
        fwSetRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] (sender) in
            guard let self = self else { return }
            
            self.flowLayout.itemRenderVertical = !self.flowLayout.itemRenderVertical
            self.collectionView.reloadData()
        }
    }
    
    func renderData() {
        for _ in 0 ..< 18 {
            collectionData.add(UIColor.fwRandom())
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
        cell.contentView.backgroundColor = collectionData.fwObject(at: indexPath.item) as? UIColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: FWScreenWidth / 4, height: indexPath.item % 3 == 0 ? 80 : 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < collectionData.count {
            view.fwShowMessage(withText: "点击section: \(indexPath.section) item: \(indexPath.item)")
        }
    }
}

@objcMembers class SwiftTestScrollViewController: UIViewController, FWScrollViewController {
    func renderScrollView() {
        let view = UIView()
        view.backgroundColor = UIColor.fwRandom()
        contentView.addSubview(view)
        view.fwLayoutMaker { (make) in
            make.edges().height(1000).width(FWScreenWidth)
        }
    }
}

@objcMembers class SwiftTestTableViewController: UIViewController, FWTableViewController {
    func renderTableView() {
        view.backgroundColor = UIColor.appColorBg()
        tableView.backgroundColor = UIColor.appColorTable()
    }
    
    func renderData() {
        tableData.addObjects(from: [0, 1, 2])
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

@objcMembers class SwiftTestWebViewController: UIViewController, FWWebViewController {
    var webItems: NSArray? = {
        return [
            UIImage(named: "public_back") as Any,
            UIImage(named: "public_close") as Any
        ]
    }()
    
    func renderWebView() {
        webRequest = "http://kvm.wuyong.site/test.php"
    }
}

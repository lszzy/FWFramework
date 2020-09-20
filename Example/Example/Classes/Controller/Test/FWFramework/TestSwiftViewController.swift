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

class SwiftTestCollectionCell: UICollectionViewCell {
    lazy var bgView: UIView = {
        let view = UIView()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(bgView)
        bgView.fwLayoutChain.edges()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@objcMembers class SwiftTestCollectionViewController: UIViewController, FWCollectionViewController {
    func renderCollectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (FWScreenWidth - 10) / 2.0, height: 100)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        return layout
    }
    
    func renderCollectionView() {
        view.backgroundColor = UIColor.appColorBg()
        collectionView.backgroundColor = UIColor.appColorTable()
        collectionView.register(SwiftTestCollectionCell.self, forCellWithReuseIdentifier: "cell")
    }
    
    func renderData() {
        collectionData.addObjects(from: [0, 1, 2])
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! SwiftTestCollectionCell
        cell.bgView.backgroundColor = UIColor.fwRandom()
        return cell
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

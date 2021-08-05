//
//  TestNavigationScrollViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

class TestNavigationTitleLabel: UILabel, FWNavigationTitleViewProtocol {
    override init(frame: CGRect) {
        super.init(frame: frame)
        font = UIFont.boldSystemFont(ofSize: 17)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var title: String? {
        get { return text }
        set { text = newValue }
    }
}

@objcMembers class TestNavigationScrollViewController: TestViewController, FWTableViewController {
    private lazy var navigationView: FWNavigationView = {
        let navigationView = FWNavigationView()
        navigationView.style = .custom
        navigationView.backgroundColor = Theme.barColor
        navigationView.contentView.titleView = TestNavigationTitleLabel()
        navigationView.contentView.title = "我是很长很长要多长有多长长得不得了的按钮"
        navigationView.contentView.tintColor = Theme.textColor
        let leftButton = FWNavigationButton(image: CoreBundle.imageNamed("back"))
        leftButton.fwAddTouch { sender in
            FWRouter.closeViewController(animated: true)
        }
        navigationView.contentView.leftButton = leftButton
        return navigationView
    }()
    
    override func renderInit() {
        fwNavigationBarStyle = .hidden
    }
    
    override func renderView() {
        tableView.backgroundColor = Theme.tableColor
        tableView.fwPullRefreshHeight = FWPullRefreshView.height + UIScreen.fwSafeAreaInsets.top
        tableView.fwSetRefreshingTarget(self, action: #selector(onRefreshing))
    }
    
    override func renderData() {
        tableData.addObjects(from: [
            "FWViewController",
            "FWCollectionViewController",
            "FWScrollViewController",
            "FWTableViewController",
            "FWWebViewController",
        ])
    }
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return navigationView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return navigationView.height
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fwCell(with: tableView)
        let value = tableData.object(at: indexPath.row) as? String
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
        default:
            viewController = SwiftTestViewController()
        }
        viewController?.fwNavigationItem.title = tableData.object(at: indexPath.row) as? String
        navigationController?.pushViewController(viewController!, animated: true)
    }
    
    // MARK: - Action
    @objc func onRefreshing() {
        NSLog("开始刷新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            NSLog("刷新完成")
            self?.tableView.reloadData()
            self?.tableView.fwEndRefreshing()
        }
    }
}

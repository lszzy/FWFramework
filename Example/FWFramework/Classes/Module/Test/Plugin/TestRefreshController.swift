//
//  TestRefreshController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/19.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestRefreshController: UIViewController, TableViewControllerProtocol, EmptyViewDelegate {
    
    static var showsFinishedView = true
    var emptyViewMode: Int = 0
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupTableView() {
        tableView.app.resetTableStyle()
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.alwaysBounceVertical = true
        tableView.register(TestRefreshCell.self, forCellReuseIdentifier: "Cell")
    }
    
    func setupNavbar() {
        app.extendedLayoutEdge = []
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: [TestRefreshController.showsFinishedView ? "隐藏FinishedView" : "显示FinishedView", self?.emptyViewMode == 1 ? "隐藏view空界面" : "显示view空界面", self?.emptyViewMode == 2 ? "隐藏tableView空界面" : "显示tableView空界面"], actionBlock: { index in
                if index == 0 {
                    TestRefreshController.showsFinishedView = !TestRefreshController.showsFinishedView
                    RefreshPluginImpl.shared.infiniteScrollBlock = { view in
                        view.showsFinishedView = TestRefreshController.showsFinishedView
                    }
                    let vc = TestRefreshController()
                    vc.emptyViewMode = self?.emptyViewMode ?? 0
                    self?.navigationController?.app.push(vc, popTopWorkflowAnimated: false)
                } else {
                    if index == 1 {
                        self?.emptyViewMode = self?.emptyViewMode == 1 ? 0 : 1
                    } else {
                        self?.emptyViewMode = self?.emptyViewMode == 2 ? 0 : 2
                    }
                    self?.tableView.app.beginRefreshing()
                }
            })
        }
    }
    
    func setupSubviews() {
        InfiniteScrollView.height = 64
        tableView.app.setRefreshing(target: self, action: #selector(onRefreshing))
        tableView.app.setLoading(target: self, action: #selector(onLoading))
        
        let pullView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        pullView.image = ModuleBundle.imageNamed("Loading.gif")
        tableView.app.pullRefreshView?.shouldChangeAlpha = false
        tableView.app.pullRefreshView?.setCustomView(pullView, for: .all)
        tableView.app.pullRefreshView?.stateBlock = { [weak self] view, state in
            self?.navigationItem.title = "refresh state-\(state.rawValue)"
        }
        tableView.app.pullRefreshView?.progressBlock = { [weak self] view, progress in
            self?.navigationItem.title = String(format: "refresh progress-%.2f", progress)
        }
        
        let infiniteView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        infiniteView.image = ModuleBundle.imageNamed("Loading.gif")
        tableView.app.infiniteScrollView?.setCustomView(infiniteView, for: .all)
        // tableView.app.infiniteScrollView?.preloadHeight = 200
        tableView.app.infiniteScrollView?.stateBlock = { [weak self] view, state in
            self?.navigationItem.title = "load state-\(state.rawValue)"
        }
        tableView.app.infiniteScrollView?.progressBlock = { [weak self] view, progress in
            self?.navigationItem.title = String(format: "load progress-%.2f", progress)
        }
    }
    
    func setupLayout() {
        tableView.app.beginRefreshing()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TestRefreshCell
        cell.object = tableData[indexPath.row] as? TestRefreshObject
        return cell
    }
    
    func emptyViewShouldScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func randomObject() -> TestRefreshObject {
        let object = TestRefreshObject()
        object.title = [
            "",
            "这是标题",
            "这是复杂的标题这是复杂的标题这是复杂的标题",
            "这是复杂的标题这是复杂的标题\n这是复杂的标题这是复杂的标题",
            "这是复杂的标题\n这是复杂的标题\n这是复杂的标题\n这是复杂的标题",
        ].randomElement() ?? ""
        object.text = [
            "",
            "这是内容",
            "这是复杂的内容这是复杂的内容这是复杂的内容这是复杂的内容这是复杂的内容这是复杂的内容这是复杂的内容这是复杂的内容这是复杂的内容",
            "这是复杂的内容这是复杂的内容\n这是复杂的内容这是复杂的内容",
            "这是复杂的内容这是复杂的内容\n这是复杂的内容这是复杂的内容\n这是复杂的内容这是复杂的内容\n这是复杂的内容这是复杂的内容",
        ].randomElement() ?? ""
        let imageName = [
            "",
            "Animation.png",
        ].randomElement() ?? ""
        if !imageName.isEmpty {
            object.image = ModuleBundle.imageNamed(imageName)
        }
        return object
    }
    
    @objc func onRefreshing() {
        NSLog("开始刷新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            NSLog("刷新完成")
            
            self.view.app.hideEmptyView()
            self.tableView.app.hideEmptyView()
            self.tableView.app.emptyViewDelegate = nil
            
            if self.emptyViewMode == 0 {
                self.tableData.removeAll()
                for _ in 0 ..< 5 {
                    self.tableData.append(self.randomObject())
                }
                self.tableView.reloadData()
                self.tableView.app.endRefreshing(finished: self.tableData.count >= 10)
            } else if self.emptyViewMode == 1 {
                self.tableData.removeAll()
                self.tableView.reloadData()
                self.view.app.showEmptyView()
                self.tableView.app.endRefreshing(finished: true)
            } else {
                self.tableData.removeAll()
                self.tableView.app.emptyViewDelegate = self
                self.tableView.reloadData()
                self.tableView.app.endRefreshing(finished: true)
            }
        }
    }
    
    @objc func onLoading() {
        NSLog("开始加载")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            NSLog("加载完成")
            
            for _ in 0 ..< 5 {
                self.tableData.append(self.randomObject())
            }
            self.tableView.reloadData()
            self.tableView.app.endLoading(finished: self.tableData.count >= 10)
        }
    }
    
}

class TestRefreshObject: NSObject {
    
    var title: String = ""
    var text: String = ""
    var image: UIImage?
    
}

class TestRefreshCell: UITableViewCell {
    
    var object: TestRefreshObject? {
        didSet {
            myTitleLabel.text = object?.title
            myImageView.image = object?.image
            myTextLabel.text = object?.text
            myTextLabel.isHidden = APP.safeString(object?.text).isEmpty
        }
    }
    
    lazy var myTitleLabel: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.font = UIFont.app.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        return result
    }()
    
    lazy var myTextLabel: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.font = UIFont.app.font(ofSize: 13)
        result.textColor = AppTheme.textColor
        return result
    }()
    
    lazy var myImageView: UIImageView = {
        let result = UIImageView()
        return result
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        app.separatorInset = .zero
        contentView.addSubview(myTitleLabel)
        contentView.addSubview(myTextLabel)
        contentView.addSubview(myImageView)
        
        myTitleLabel.app.pinEdge(toSuperview: .left, inset: 15)
        myTitleLabel.app.pinEdge(toSuperview: .right, inset: 15)
        var constraint = myTitleLabel.app.pinEdge(toSuperview: .top, inset: 15)
        myTitleLabel.app.addCollapseConstraint(constraint)
        myTitleLabel.app.autoCollapse = true
        
        myTextLabel.app.hiddenCollapse = true
        myTextLabel.app.pinEdge(toSuperview: .left, inset: 15)
        myTextLabel.app.pinEdge(toSuperview: .right, inset: 15)
        constraint = myTextLabel.app.pinEdge(.top, toEdge: .bottom, ofView: myTitleLabel, offset: 10)
        myTextLabel.app.addCollapseConstraint(constraint)
        
        myImageView.app.pinEdge(toSuperview: .left, inset: 15)
        myImageView.app.pinEdge(toSuperview: .right, inset: 15, relation: .greaterThanOrEqual)
        myImageView.app.pinEdge(toSuperview: .bottom, inset: 15)
        constraint = myImageView.app.pinEdge(.top, toEdge: .bottom, ofView: myTextLabel, offset: 10)
        myImageView.app.addCollapseConstraint(constraint)
        myImageView.app.autoCollapse = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

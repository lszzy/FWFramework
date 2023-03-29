//
//  TestTableController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/27.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestTableController: UIViewController, TableViewControllerProtocol {
    
    typealias TableElement = TestTableDynamicLayoutObject
    
    static var isExpanded = false
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupTableView() {
        tableView.app.resetGroupedStyle()
        tableView.alwaysBounceVertical = true
        tableView.backgroundColor = AppTheme.tableColor
        tableView.app.setRefreshing { [weak self] in
            self?.onRefreshing()
        }
        tableView.app.pullRefreshView?.stateBlock = { [weak self] view, state in
            self?.navigationItem.title = "refresh state-\(state.rawValue)"
        }
        tableView.app.pullRefreshView?.progressBlock = { [weak self] view, progress in
            self?.navigationItem.title = String(format: "refresh progress-%.2f", progress)
        }
        
        InfiniteScrollView.height = 64
        tableView.app.setLoading { [weak self] in
            self?.onLoading()
        }
        // tableView.app.infiniteScrollView?.preloadHeight = 200
        tableView.app.infiniteScrollView?.stateBlock = { [weak self] view, state in
            self?.navigationItem.title = "load state-\(state.rawValue)"
        }
        tableView.app.infiniteScrollView?.progressBlock = { [weak self] view, progress in
            self?.navigationItem.title = String(format: "load progress-%.2f", progress)
        }
    }
    
    func setupCollectionLayout() {
        tableView.app.pinEdges(toSuperview: .zero, excludingEdge: .top)
        tableView.app.pinEdge(toSafeArea: .top)
    }
    
    func setupNavbar() {
        Self.isExpanded = false
        app.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
            self?.app.showSheet(title: nil, message: "滚动视图顶部未延伸", cancel: "取消", actions: [self?.tableView.contentInsetAdjustmentBehavior == .never ? "contentInset自适应" : "contentInset不适应", Self.isExpanded ? "布局不撑开" : "布局撑开"], currentIndex: -1, actionBlock: { index in
                if index == 0 {
                    self?.tableView.contentInsetAdjustmentBehavior = self?.tableView.contentInsetAdjustmentBehavior == .never ? .automatic : .never
                } else {
                    Self.isExpanded = !Self.isExpanded
                }
                self?.setupSubviews()
            })
        }
    }
    
    func setupSubviews() {
        tableView.app.beginRefreshing()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TestTableDynamicLayoutCell.app.cell(tableView: tableView)
        cell.imageClicked = { [weak self] object in
            self?.onPhotoBrowser(cell, indexPath: indexPath)
        }
        cell.object = tableData[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        // 最后一次上拉会产生跳跃，处理此方法即可
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.app.height(cellClass: TestTableDynamicLayoutCell.self, cacheBy: indexPath) { [weak self] cell in
            cell.object = self?.tableData[indexPath.row]
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "删除"
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableData.remove(at: indexPath.row)
            tableView.app.clearHeightCache()
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableData.count < 1 {
            return nil
        }
        let headerView = TestTableDynamicLayoutHeaderView.app.headerFooterView(tableView: tableView)
        headerView.renderData("我是表格Header\n我是表格Header")
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableData.count < 1 {
            return 0
        }
        return tableView.app.height(headerFooterViewClass: TestTableDynamicLayoutHeaderView.self, type: .header) { headerView in
            headerView.renderData("我是表格Header\n我是表格Header")
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if tableData.count < 1 {
            return nil
        }
        let footerView = TestTableDynamicLayoutHeaderView.app.headerFooterView(tableView: tableView)
        footerView.renderData("我是表格Footer\n我是表格Footer\n我是表格Footer")
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if tableData.count < 1 {
            return 0
        }
        return tableView.app.height(headerFooterViewClass: TestTableDynamicLayoutHeaderView.self, type: .footer) { footerView in
            footerView.renderData("我是表格Footer\n我是表格Footer\n我是表格Footer")
        }
    }
    
    func randomObject() -> TestTableDynamicLayoutObject {
        let object = TestTableDynamicLayoutObject()
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
        object.imageUrl = [
            "",
            "Animation.png",
            "http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
            "http://littlesvr.ca/apng/images/SteamEngine.webp",
            "Loading.gif",
            "http://ww2.sinaimg.cn/thumbnail/9ecab84ejw1emgd5nd6eaj20c80c8q4a.jpg",
            "http://ww2.sinaimg.cn/thumbnail/642beb18gw1ep3629gfm0g206o050b2a.gif",
            "http://ww4.sinaimg.cn/thumbnail/9e9cb0c9jw1ep7nlyu8waj20c80kptae.jpg",
            "https://pic3.zhimg.com/b471eb23a_im.jpg",
            "http://ww4.sinaimg.cn/thumbnail/8e88b0c1gw1e9lpr4nndfj20gy0o9q6i.jpg",
            "http://ww3.sinaimg.cn/thumbnail/8e88b0c1gw1e9lpr57tn9j20gy0obn0f.jpg",
            "http://ww2.sinaimg.cn/thumbnail/677febf5gw1erma104rhyj20k03dz16y.jpg",
            "http://ww4.sinaimg.cn/thumbnail/677febf5gw1erma1g5xd0j20k0esa7wj.jpg"
        ].randomElement() ?? ""
        return object
    }
    
    @objc func onRefreshing() {
        NSLog("开始刷新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            NSLog("刷新完成")
            self.tableData.removeAll()
            for _ in 0 ..< 1 {
                self.tableData.append(self.randomObject())
            }
            self.tableView.app.clearHeightCache()
            self.tableView.reloadData()
            
            self.tableView.app.shouldRefreshing = self.tableData.count < 20
            self.tableView.app.endRefreshing()
            if !self.tableView.app.shouldRefreshing {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    @objc func onLoading() {
        NSLog("开始加载")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            NSLog("加载完成")
            for _ in 0 ..< 1 {
                self.tableData.append(self.randomObject())
            }
            self.tableView.reloadData()
            
            self.tableView.app.loadingFinished = self.tableData.count >= 20
            self.tableView.app.endLoading()
        }
    }
    
    func onPhotoBrowser(_ cell: TestTableDynamicLayoutCell, indexPath: IndexPath) {
        // 移除所有缓存
        ImageDownloader.defaultInstance().imageCache?.removeAllImages()
        ImageDownloader.defaultURLCache().removeAllCachedResponses()
        
        var pictureUrls: [Any] = []
        for object in self.tableData {
            if object.imageUrl.app.isValid(.isUrl) || object.imageUrl.isEmpty {
                pictureUrls.append(object.imageUrl)
            } else {
                pictureUrls.append(ModuleBundle.imageNamed(object.imageUrl) as Any)
            }
        }
        
        app.showImagePreview(imageURLs: pictureUrls, imageInfos: nil, currentIndex: indexPath.row) { [weak self] index in
            let cell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? TestTableDynamicLayoutCell
            return cell?.myImageView
        }
    }
    
}

class TestTableDynamicLayoutObject: NSObject {
    
    var title = ""
    var text = ""
    var imageUrl = ""
    
}

class TestTableDynamicLayoutCell: UITableViewCell {
    
    var object: TestTableDynamicLayoutObject? {
        didSet {
            guard let object = object else { return }
            myTitleLabel.text = object.title
            if object.imageUrl.app.isValid(.isUrl) {
                myImageView.app.setImage(url: object.imageUrl, placeholderImage: UIImage.app.appIconImage())
            } else if !object.imageUrl.isEmpty {
                myImageView.image = ModuleBundle.imageNamed(object.imageUrl)
            } else {
                myImageView.image = nil
            }
            myTextLabel.text = object.text
            myImageView.app.constraint(toSuperview: .bottom)?.isActive = TestTableController.isExpanded
            app.maxYViewExpanded = TestTableController.isExpanded
        }
    }
    
    var imageClicked: ((TestTableDynamicLayoutObject) -> Void)?
    
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
        result.app.setContentModeAspectFill()
        result.isUserInteractionEnabled = true
        result.app.addTapGesture(target: self, action: #selector(TestTableDynamicLayoutCell.onImageClick(_:)))
        return result
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        app.separatorInset = .zero
        selectionStyle = .none
        contentView.backgroundColor = AppTheme.cellColor
        // maxY视图不需要和bottom布局，默认平齐，可设置底部间距
        app.maxYViewPadding = 15
        
        contentView.addSubview(myTitleLabel)
        contentView.addSubview(myTextLabel)
        contentView.addSubview(myImageView)
        
        myTitleLabel.app.pinEdge(toSuperview: .left, inset: 15)
        myTitleLabel.app.pinEdge(toSuperview: .right, inset: 15)
        myTitleLabel.app.pinEdge(toSuperview: .top, inset: 15)
        
        myTextLabel.app.pinEdge(toSuperview: .left, inset: 15)
        myTextLabel.app.pinEdge(toSuperview: .right, inset: 15)
        var constraint = myTextLabel.app.pinEdge(.top, toEdge: .bottom, ofView: myTitleLabel, offset: 10)
        myTextLabel.app.addCollapseConstraint(constraint)
        myTextLabel.app.autoCollapse = true
        
        myImageView.app.pinEdge(toSuperview: .left, inset: 15)
        myImageView.app.pinEdge(toSuperview: .bottom, inset: 15)
        constraint = myImageView.app.pinEdge(.top, toEdge: .bottom, ofView: myTextLabel, offset: 10)
        myImageView.app.addCollapseConstraint(constraint)
        constraint = myImageView.app.setDimension(.width, size: 100)
        myImageView.app.addCollapseConstraint(constraint)
        constraint = myImageView.app.setDimension(.height, size: 100)
        myImageView.app.addCollapseConstraint(constraint)
        myImageView.app.autoCollapse = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onImageClick(_ gesture: UIGestureRecognizer) {
        if let object = object {
            imageClicked?(object)
        }
    }
    
}

class TestTableDynamicLayoutHeaderView: UITableViewHeaderFooterView {
    
    lazy var titleLabel: UILabel = {
        let result = UILabel.app.label(font: UIFont.app.font(ofSize: 15), textColor: AppTheme.textColor)
        result.numberOfLines = 0
        return result
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = AppTheme.cellColor
        app.maxYViewPadding = 15
        addSubview(titleLabel)
        titleLabel.app.layoutChain.edges(UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15))
        renderData(nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func renderData(_ text: String?) {
        titleLabel.text = APP.safeString(text)
        titleLabel.app.constraint(toSuperview: .bottom)?.isActive = TestTableController.isExpanded
        app.maxYViewExpanded = TestTableController.isExpanded
    }
    
}

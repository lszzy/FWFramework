//
//  TestTableController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/27.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestTableController: UIViewController, TableViewControllerProtocol {
    
    static var isExpanded = false
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupTableView() {
        tableView.fw.resetTableStyle()
        tableView.alwaysBounceVertical = true
        tableView.backgroundColor = AppTheme.tableColor
        tableView.fw.setRefreshing { [weak self] in
            self?.onRefreshing()
        }
        tableView.fw.pullRefreshView?.stateBlock = { [weak self] view, state in
            self?.navigationItem.title = "refresh state-\(state.rawValue)"
        }
        tableView.fw.pullRefreshView?.progressBlock = { [weak self] view, progress in
            self?.navigationItem.title = String(format: "refresh progress-%.2f", progress)
        }
        
        InfiniteScrollView.height = 64
        tableView.fw.setLoading { [weak self] in
            self?.onLoading()
        }
        // tableView.fw.infiniteScrollView?.preloadHeight = 200
        tableView.fw.infiniteScrollView?.stateBlock = { [weak self] view, state in
            self?.navigationItem.title = "load state-\(state.rawValue)"
        }
        tableView.fw.infiniteScrollView?.progressBlock = { [weak self] view, progress in
            self?.navigationItem.title = String(format: "load progress-%.2f", progress)
        }
    }
    
    func setupCollectionLayout() {
        tableView.fw.pinEdges(toSuperview: .zero, excludingEdge: .top)
        tableView.fw.pinEdge(toSafeArea: .top)
    }
    
    func setupNavbar() {
        Self.isExpanded = false
        fw.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
            self?.fw.showSheet(title: nil, message: "滚动视图顶部未延伸", cancel: "取消", actions: [self?.tableView.contentInsetAdjustmentBehavior == .never ? "contentInset自适应" : "contentInset不适应", Self.isExpanded ? "布局不撑开" : "布局撑开"], currentIndex: -1, actionBlock: { index in
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
        tableView.fw.beginRefreshing()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TestTableDynamicLayoutCell.fw.cell(tableView: tableView)
        cell.imageClicked = { [weak self] object in
            self?.onPhotoBrowser(cell, indexPath: indexPath)
        }
        cell.object = tableData.object(at: indexPath.row) as? TestTableDynamicLayoutObject
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        // 最后一次上拉会产生跳跃，处理此方法即可
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.fw.height(cellClass: TestTableDynamicLayoutCell.self, cacheBy: indexPath) { [weak self] cell in
            cell.object = self?.tableData.object(at: indexPath.row) as? TestTableDynamicLayoutObject
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let object = tableData[indexPath.row] as! TestTableDynamicLayoutObject
        tableView.app.willDisplay(cell, at: indexPath, key: object.hash) {
            NSLog("曝光index: %@ object: %@", "\(indexPath.row)", "\(object.index)")
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
            tableData.removeObject(at: indexPath.row)
            tableView.fw.clearHeightCache()
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableData.count < 1 {
            return nil
        }
        let headerView = TestTableDynamicLayoutHeaderView.fw.headerFooterView(tableView: tableView)
        headerView.renderData("我是表格Header\n我是表格Header")
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableData.count < 1 {
            return 0
        }
        return tableView.fw.height(headerFooterViewClass: TestTableDynamicLayoutHeaderView.self, type: .header) { headerView in
            headerView.renderData("我是表格Header\n我是表格Header")
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if tableData.count < 1 {
            return nil
        }
        let footerView = TestTableDynamicLayoutHeaderView.fw.headerFooterView(tableView: tableView)
        footerView.renderData("我是表格Footer\n我是表格Footer\n我是表格Footer")
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if tableData.count < 1 {
            return 0
        }
        return tableView.fw.height(headerFooterViewClass: TestTableDynamicLayoutHeaderView.self, type: .footer) { footerView in
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
        object.index = self.tableData.count
        return object
    }
    
    @objc func onRefreshing() {
        NSLog("开始刷新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            NSLog("刷新完成")
            self.tableData.removeAllObjects()
            for _ in 0 ..< 1 {
                self.tableData.add(self.randomObject())
            }
            self.tableView.fw.clearHeightCache()
            self.tableView.reloadData()
            
            self.tableView.fw.shouldRefreshing = self.tableData.count < 20
            self.tableView.fw.endRefreshing()
            if !self.tableView.fw.shouldRefreshing {
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
                self.tableData.add(self.randomObject())
            }
            self.tableView.reloadData()
            
            self.tableView.fw.loadingFinished = self.tableData.count >= 20
            self.tableView.fw.endLoading()
        }
    }
    
    func onPhotoBrowser(_ cell: TestTableDynamicLayoutCell, indexPath: IndexPath) {
        // 移除所有缓存
        ImageDownloader.defaultInstance().imageCache?.removeAllImages()
        ImageDownloader.defaultURLCache().removeAllCachedResponses()
        
        var pictureUrls: [Any] = []
        for object in self.tableData {
            guard let object = object as? TestTableDynamicLayoutObject else { continue }
            if object.imageUrl.fw.isFormatUrl() || object.imageUrl.isEmpty {
                pictureUrls.append(object.imageUrl)
            } else {
                pictureUrls.append(ModuleBundle.imageNamed(object.imageUrl) as Any)
            }
        }
        
        fw.showImagePreview(imageURLs: pictureUrls, imageInfos: nil, currentIndex: indexPath.row) { [weak self] index in
            let cell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? TestTableDynamicLayoutCell
            return cell?.myImageView
        }
    }
    
}

class TestTableDynamicLayoutObject: NSObject {
    
    var title = ""
    var text = ""
    var imageUrl = ""
    var index: Int = 0
    
}

class TestTableDynamicLayoutCell: UITableViewCell {
    
    var object: TestTableDynamicLayoutObject? {
        didSet {
            guard let object = object else { return }
            myTitleLabel.text = object.title
            if object.imageUrl.fw.isFormatUrl() {
                myImageView.fw.setImage(url: object.imageUrl, placeholderImage: UIImage.fw.appIconImage())
            } else if !object.imageUrl.isEmpty {
                myImageView.image = ModuleBundle.imageNamed(object.imageUrl)
            } else {
                myImageView.image = nil
            }
            myTextLabel.text = object.text
            myImageView.fw.constraint(toSuperview: .bottom)?.isActive = TestTableController.isExpanded
            fw.maxYViewExpanded = TestTableController.isExpanded
        }
    }
    
    var imageClicked: ((TestTableDynamicLayoutObject) -> Void)?
    
    lazy var myTitleLabel: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.font = UIFont.fw.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        return result
    }()
    
    lazy var myTextLabel: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.font = UIFont.fw.font(ofSize: 13)
        result.textColor = AppTheme.textColor
        return result
    }()
    
    lazy var myImageView: UIImageView = {
        let result = UIImageView()
        result.fw.setContentModeAspectFill()
        result.isUserInteractionEnabled = true
        result.fw.addTapGesture(target: self, action: #selector(TestTableDynamicLayoutCell.onImageClick(_:)))
        return result
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        fw.separatorInset = .zero
        selectionStyle = .none
        contentView.backgroundColor = AppTheme.cellColor
        // maxY视图不需要和bottom布局，默认平齐，可设置底部间距
        fw.maxYViewPadding = 15
        
        contentView.addSubview(myTitleLabel)
        contentView.addSubview(myTextLabel)
        contentView.addSubview(myImageView)
        
        myTitleLabel.fw.pinEdge(toSuperview: .left, inset: 15)
        myTitleLabel.fw.pinEdge(toSuperview: .right, inset: 15)
        myTitleLabel.fw.pinEdge(toSuperview: .top, inset: 15)
        
        myTextLabel.fw.pinEdge(toSuperview: .left, inset: 15)
        myTextLabel.fw.pinEdge(toSuperview: .right, inset: 15)
        var constraint = myTextLabel.fw.pinEdge(.top, toEdge: .bottom, ofView: myTitleLabel, offset: 10)
        myTextLabel.fw.addCollapseConstraint(constraint)
        myTextLabel.fw.autoCollapse = true
        
        myImageView.fw.pinEdge(toSuperview: .left, inset: 15)
        myImageView.fw.pinEdge(toSuperview: .bottom, inset: 15)
        constraint = myImageView.fw.pinEdge(.top, toEdge: .bottom, ofView: myTextLabel, offset: 10)
        myImageView.fw.addCollapseConstraint(constraint)
        constraint = myImageView.fw.setDimension(.width, size: 100)
        myImageView.fw.addCollapseConstraint(constraint)
        constraint = myImageView.fw.setDimension(.height, size: 100)
        myImageView.fw.addCollapseConstraint(constraint)
        myImageView.fw.autoCollapse = true
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
        let result = UILabel.fw.label(font: UIFont.fw.font(ofSize: 15), textColor: AppTheme.textColor)
        result.numberOfLines = 0
        return result
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = AppTheme.cellColor
        fw.maxYViewPadding = 15
        addSubview(titleLabel)
        titleLabel.fw.layoutChain.edges(UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15))
        renderData(nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func renderData(_ text: String?) {
        titleLabel.text = FW.safeString(text)
        titleLabel.fw.constraint(toSuperview: .bottom)?.isActive = TestTableController.isExpanded
        fw.maxYViewExpanded = TestTableController.isExpanded
    }
    
}

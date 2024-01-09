//
//  TestSkeletonController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/10/18.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestSkeletonController: UIViewController, TableViewControllerProtocol, SkeletonViewDelegate {
    
    lazy var headerView: TestSkeletonTableHeaderView = {
        let result = TestSkeletonTableHeaderView()
        result.frame = CGRect(x: 0, y: 0, width: APP.screenWidth, height: 0)
        return result
    }()
    
    lazy var footerView: TestSkeletonTableFooterView = {
        let result = TestSkeletonTableFooterView()
        result.frame = CGRect(x: 0, y: 0, width: APP.screenWidth, height: 0)
        return result
    }()
    
    var scrollStyle: Int = 0
    
    func setupTableView() {
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
        headerView.app.autoLayoutSubviews()
        footerView.app.autoLayoutSubviews()
        
        tableView.app.setRefreshing(target: self, action: #selector(onRefreshing))
        tableView.app.setLoading(target: self, action: #selector(onLoading))
    }
    
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: ["shimmer", "solid", "scale", "none", "tableView滚动", "scrollView滚动", "添加数据"], actionBlock: { index in
                guard let self = self else { return }
                
                if index == 4 {
                    self.scrollStyle = self.scrollStyle != 0 ? 0 : 1
                    self.renderData()
                    return
                }
                
                if index == 5 {
                    self.scrollStyle = self.scrollStyle != 0 ? 0 : 2
                    self.renderData()
                    return
                }
                
                if index == 6 {
                    let lastIndex = self.tableData.last.safeInt
                    self.tableData.append(contentsOf: [lastIndex + 1, lastIndex + 2])
                    self.tableView.reloadData()
                    self.renderData()
                    return
                }
                
                var animation: SkeletonAnimation?
                if index == 0 {
                    animation = SkeletonAnimation.shimmer
                } else if index == 1 {
                    animation = SkeletonAnimation.solid
                } else if index == 2 {
                    animation = SkeletonAnimation.scale
                }
                SkeletonAppearance.appearance.animation = animation
                self.renderData()
            })
        }
    }
    
    func setupSubviews() {
        renderData()
    }
    
    func renderData() {
        tableView.app.beginRefreshing()
    }
    
    @objc func onRefreshing() {
        headerView.isHidden = true
        footerView.isHidden = true
        
        app.showSkeleton()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.app.hideSkeleton()
            
            self.headerView.isHidden = false
            self.footerView.isHidden = false
            
            self.tableData.removeAll()
            self.tableData.append(contentsOf: [1, 2])
            self.tableView.reloadData()
            
            self.tableView.app.endRefreshing()
        }
    }
    
    @objc func onLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let lastIndex = self.tableData.last.safeInt
            self.tableData.append(contentsOf: [lastIndex + 1, lastIndex + 2])
            self.tableView.reloadData()
            
            self.tableView.app.endLoading()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.app.height(cellClass: TestSkeletonCell.self) { [weak self] cell in
            cell.configure(object: self?.tableData[indexPath.row] as? String ?? "")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TestSkeletonCell.app.cell(tableView: tableView)
        cell.configure(object: tableData[indexPath.row] as? String ?? "")
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = TestSkeletonHeaderView.app.headerFooterView(tableView: tableView)
        headerView.configure(object: "1")
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableView.app.height(headerFooterViewClass: TestSkeletonHeaderView.self, type: .header) { headerView in
            headerView.configure(object: "1")
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = TestSkeletonFooterView.app.headerFooterView(tableView: tableView)
        footerView.configure(object: "1")
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return tableView.app.height(headerFooterViewClass: TestSkeletonFooterView.self, type: .footer) { footerView in
            footerView.configure(object: "1")
        }
    }
    
    func skeletonViewLayout(_ layout: SkeletonLayout) {
        layout.setScrollView(self.tableView)
        
        if self.scrollStyle == 0 {
            if let tableView = layout.addSkeletonView(self.tableView) as? SkeletonTableView {
                tableView.tableDelegate.cellClass = TestSkeletonCell.self
                tableView.tableDelegate.headerViewClass = TestSkeletonHeaderView.self
            }
        } else if self.scrollStyle == 1 {
            if let tableView = layout.addSkeletonView(self.tableView) as? SkeletonTableView {
                tableView.tableDelegate.cellClass = TestSkeletonCell.self
                tableView.tableView.isScrollEnabled = true
            }
        } else {
            let scrollView = UIScrollView()
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            layout.addSubview(scrollView)
            scrollView.app.layoutChain.edges()
            
            if let tableView = SkeletonLayout.parseSkeletonView(self.tableView) as? SkeletonTableView {
                tableView.tableDelegate.cellClass = TestSkeletonCell.self
                scrollView.app.contentView.addSubview(tableView)
                tableView.app.layoutChain.edges().size(self.tableView.frame.size)
            }
        }
    }
    
}

class TestSkeletonCell: UITableViewCell {
    
    lazy var iconView: UIImageView = {
        let result = UIImageView()
        result.image = UIImage.app.appIconImage()
        return result
    }()
    
    lazy var iconLabel: UILabel = {
        let result = UILabel()
        result.font = UIFont.app.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        result.text = "我是文本"
        return result
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        app.maxYViewPadding = 20
        contentView.addSubview(iconView)
        contentView.addSubview(iconLabel)
        
        iconView.app.layoutChain
            .top(20)
            .left(20)
            .size(CGSize(width: 50, height: 50))
        
        iconLabel.app.layoutChain
            .centerY()
            .right(20)
            .left(toViewRight: iconView, offset: 20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(object: String) {
        iconLabel.text = "我是文本\(object)"
    }
    
}

class TestSkeletonHeaderView: UITableViewHeaderFooterView {
    
    lazy var iconView: UIImageView = {
        let result = UIImageView()
        result.image = UIImage.app.appIconImage()
        return result
    }()
    
    lazy var iconLabel: UILabel = {
        let result = UILabel()
        result.font = UIFont.app.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        result.text = "我是头视图"
        return result
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        app.maxYViewPadding = 20
        contentView.addSubview(iconView)
        contentView.addSubview(iconLabel)
        
        iconView.app.layoutChain
            .top(20)
            .left(20)
            .size(CGSize(width: 20, height: 20))
        
        iconLabel.app.layoutChain
            .right(20)
            .centerY(toView: iconView)
            .left(toViewRight: iconView, offset: 20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(object: String) {
        iconLabel.text = "我是头视图\(object)"
    }
    
}

class TestSkeletonFooterView: UITableViewHeaderFooterView {
    
    lazy var iconView: UIImageView = {
        let result = UIImageView()
        result.image = UIImage.app.appIconImage()
        return result
    }()
    
    lazy var iconLabel: UILabel = {
        let result = UILabel()
        result.font = UIFont.app.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        result.text = "我是尾视图"
        return result
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        app.maxYViewPadding = 20
        contentView.addSubview(iconView)
        contentView.addSubview(iconLabel)
        
        iconView.app.layoutChain
            .top(20)
            .left(20)
            .size(CGSize(width: 20, height: 20))
        
        iconLabel.app.layoutChain
            .right(20)
            .centerY(toView: iconView)
            .left(toViewRight: iconView, offset: 20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(object: String) {
        iconLabel.text = "我是尾视图\(object)"
    }
    
}

class TestSkeletonTableHeaderView: UIView {
    
    lazy var testView: UIView = {
        let result = UIView()
        result.backgroundColor = .red
        result.app.setCornerRadius(5)
        return result
    }()
    
    lazy var rightView: UIView = {
        let result = UIView()
        result.backgroundColor = .red
        result.app.setCornerRadius(5)
        return result
    }()
    
    lazy var childView: UIView = {
        let result = UIView()
        result.backgroundColor = .yellow
        return result
    }()
    
    lazy var imageView: UIImageView = {
        let result = UIImageView()
        result.image = UIImage.app.appIconImage()
        result.app.setContentModeAspectFill()
        result.app.setCornerRadius(5)
        return result
    }()
    
    lazy var childView2: UIView = {
        let result = UIView()
        result.backgroundColor = .yellow
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(testView)
        addSubview(rightView)
        rightView.addSubview(childView)
        addSubview(imageView)
        addSubview(childView2)
        
        testView.app.layoutChain
            .left(20)
            .top(20)
            .size(CGSize(width: APP.screenWidth / 2 - 40, height: 50))
        
        rightView.app.layoutChain
            .right(20)
            .top(20)
            .size(CGSize(width: APP.screenWidth / 2 - 40, height: 50))
        
        childView.app.layoutChain
            .edges(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        
        imageView.app.layoutChain
            .centerX(toView: testView)
            .top(toViewBottom: testView, offset: 20)
            .size(CGSize(width: 50, height: 50))
        
        childView2.app.layoutChain
            .centerX(toView: childView)
            .centerY(toView: imageView)
            .size(toView: childView)
            .bottom(20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class TestSkeletonTableFooterView: UIView {
    
    lazy var label1: UILabel = {
        let result = UILabel()
        result.textColor = AppTheme.textColor
        result.text = "我是Label1"
        return result
    }()
    
    lazy var label2: UILabel = {
        let result = UILabel()
        result.font = UIFont.systemFont(ofSize: 12)
        result.textColor = AppTheme.textColor
        result.numberOfLines = 0
        result.text = "我是Label2222222222\n我是Label22222\n我是Label2"
        return result
    }()
    
    lazy var textView1: UITextView = {
        let result = UITextView()
        result.isEditable = false
        result.textColor = AppTheme.textColor
        result.text = "我是TextView1"
        return result
    }()
    
    lazy var textView2: UITextView = {
        let result = UITextView()
        result.font = UIFont.systemFont(ofSize: 12)
        result.isEditable = false
        result.textColor = AppTheme.textColor
        result.text = "我是TextView2222\n我是TextView2\n我是TextView"
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label1)
        addSubview(label2)
        addSubview(textView1)
        addSubview(textView2)
        
        label1.app.layoutChain
            .left(20)
            .top(20)
        
        label2.app.layoutChain
            .top(20)
            .right(20)
            .size(CGSize(width: APP.screenWidth / 2 - 40, height: 50))
        
        textView1.app.layoutChain
            .left(20)
            .top(toViewBottom: label1, offset: 20)
            .size(CGSize(width: APP.screenWidth / 2 - 40, height: 50))
        
        textView2.app.layoutChain
            .right(20)
            .top(toViewBottom: label2, offset: 20)
            .size(CGSize(width: APP.screenWidth / 2 - 40, height: 50))
            .bottom(20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

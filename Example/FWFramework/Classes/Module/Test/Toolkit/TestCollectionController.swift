//
//  TestCollectionController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/27.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestCollectionController: UIViewController, CollectionViewControllerProtocol, UICollectionViewDelegateFlowLayout {
    
    static var isExpanded = false
    var mode: Int = 0
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let result = UICollectionViewFlowLayout()
        result.minimumLineSpacing = 0
        result.minimumInteritemSpacing = 0
        return result
    }()
    
    func setupCollectionViewLayout() -> UICollectionViewLayout {
        flowLayout
    }
    
    func setupCollectionView() {
        collectionView.backgroundColor = AppTheme.tableColor
        collectionView.fw.setRefreshing { [weak self] in
            self?.onRefreshing()
        }
        collectionView.fw.setLoading { [weak self] in
            self?.onLoading()
        }
    }
    
    func setupCollectionLayout() {
        collectionView.fw.pinEdges(toSuperview: .zero, excludingEdge: .top)
        collectionView.fw.pinEdge(toSafeArea: .top)
    }
    
    func setupNavbar() {
        Self.isExpanded = false
        fw.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
            self?.fw.showSheet(title: nil, message: nil, cancel: "取消", actions: ["不固定宽高", "固定宽度", "固定高度", "布局撑开", "布局不撑开"], currentIndex: -1, actionBlock: { index in
                if index < 3 {
                    self?.mode = index
                } else {
                    Self.isExpanded = index == 3 ? true : false
                }
                self?.setupSubviews()
            })
        }
    }
    
    func setupSubviews() {
        if mode == 2 {
            flowLayout.scrollDirection = .horizontal
        } else {
            flowLayout.scrollDirection = .vertical
        }
        collectionView.fw.beginRefreshing()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = TestCollectionDynamicLayoutCell.fw.cell(collectionView: collectionView, indexPath: indexPath)
        cell.object = collectionData.object(at: indexPath.row) as? TestCollectionDynamicLayoutObject
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let reusableView = TestCollectionDynamicLayoutHeaderView.fw.reusableView(collectionView: collectionView, kind: kind, indexPath: indexPath)
            reusableView.renderData("我是集合Header\n我是集合Header")
            return reusableView
        } else {
            let reusableView = TestCollectionDynamicLayoutHeaderView.fw.reusableView(collectionView: collectionView, kind: kind, indexPath: indexPath)
            reusableView.renderData("我是集合Footer\n我是集合Footer\n我是集合Footer")
            return reusableView
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if mode == 0 {
            return collectionView.fw.size(cellClass: TestCollectionDynamicLayoutCell.self, cacheBy: indexPath) { [weak self] cell in
                guard let cell = cell as? TestCollectionDynamicLayoutCell else { return }
                cell.object = self?.collectionData.object(at: indexPath.row) as? TestCollectionDynamicLayoutObject
            }
        } else if mode == 1 {
            return collectionView.fw.size(cellClass: TestCollectionDynamicLayoutCell.self, width: FW.screenWidth - 30, cacheBy: indexPath) { [weak self] cell in
                guard let cell = cell as? TestCollectionDynamicLayoutCell else { return }
                cell.object = self?.collectionData.object(at: indexPath.row) as? TestCollectionDynamicLayoutObject
            }
        } else {
            return collectionView.fw.size(cellClass: TestCollectionDynamicLayoutCell.self, height: FW.screenHeight - FW.topBarHeight, cacheBy: indexPath) { [weak self] cell in
                guard let cell = cell as? TestCollectionDynamicLayoutCell else { return }
                cell.object = self?.collectionData.object(at: indexPath.row) as? TestCollectionDynamicLayoutObject
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if collectionData.count < 1 {
            return .zero
        }
        if mode == 0 {
            return collectionView.fw.size(reusableViewClass: TestCollectionDynamicLayoutHeaderView.self, kind: UICollectionView.elementKindSectionHeader, cacheBy: section) { reusableView in
                guard let reusableView = reusableView as? TestCollectionDynamicLayoutHeaderView else { return }
                reusableView.renderData("我是集合Header\n我是集合Header")
            }
        } else if mode == 1 {
            return collectionView.fw.size(reusableViewClass: TestCollectionDynamicLayoutHeaderView.self, width: FW.screenWidth - 30, kind: UICollectionView.elementKindSectionHeader, cacheBy: section) { reusableView in
                guard let reusableView = reusableView as? TestCollectionDynamicLayoutHeaderView else { return }
                reusableView.renderData("我是集合Header\n我是集合Header")
            }
        } else {
            return collectionView.fw.size(reusableViewClass: TestCollectionDynamicLayoutHeaderView.self, height: FW.screenHeight - FW.topBarHeight, kind: UICollectionView.elementKindSectionHeader, cacheBy: section) { reusableView in
                guard let reusableView = reusableView as? TestCollectionDynamicLayoutHeaderView else { return }
                reusableView.renderData("我是集合Header\n我是集合Header")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if collectionData.count < 1 {
            return .zero
        }
        if mode == 0 {
            return collectionView.fw.size(reusableViewClass: TestCollectionDynamicLayoutHeaderView.self, kind: UICollectionView.elementKindSectionFooter, cacheBy: section) { reusableView in
                guard let reusableView = reusableView as? TestCollectionDynamicLayoutHeaderView else { return }
                reusableView.renderData("我是集合Footer\n我是集合Footer\n我是集合Footer")
            }
        } else if mode == 1 {
            return collectionView.fw.size(reusableViewClass: TestCollectionDynamicLayoutHeaderView.self, width: FW.screenWidth - 30, kind: UICollectionView.elementKindSectionFooter, cacheBy: section) { reusableView in
                guard let reusableView = reusableView as? TestCollectionDynamicLayoutHeaderView else { return }
                reusableView.renderData("我是集合Footer\n我是集合Footer\n我是集合Footer")
            }
        } else {
            return collectionView.fw.size(reusableViewClass: TestCollectionDynamicLayoutHeaderView.self, height: FW.screenHeight - FW.topBarHeight, kind: UICollectionView.elementKindSectionFooter, cacheBy: section) { reusableView in
                guard let reusableView = reusableView as? TestCollectionDynamicLayoutHeaderView else { return }
                reusableView.renderData("我是集合Footer\n我是集合Footer\n我是集合Footer")
            }
        }
    }
    
    func randomObject() -> TestCollectionDynamicLayoutObject {
        let object = TestCollectionDynamicLayoutObject()
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
            self.collectionData.removeAllObjects()
            for _ in 0 ..< 4 {
                self.collectionData.add(self.randomObject())
            }
            self.collectionView.fw.clearSizeCache()
            self.collectionView.fw.reloadDataWithoutAnimation()
            
            self.collectionView.fw.shouldRefreshing = self.collectionData.count < 20
            self.collectionView.fw.endRefreshing()
            if !self.collectionView.fw.shouldRefreshing {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    @objc func onLoading() {
        NSLog("开始加载")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            NSLog("加载完成")
            for _ in 0 ..< 4 {
                self.collectionData.add(self.randomObject())
            }
            self.collectionView.fw.reloadDataWithoutAnimation()
            
            self.collectionView.fw.loadingFinished = self.collectionData.count >= 20
            self.collectionView.fw.endLoading()
        }
    }
    
}

class TestCollectionDynamicLayoutObject: NSObject {
    
    var title = ""
    var text = ""
    var imageUrl = ""
    
}

class TestCollectionDynamicLayoutCell: UICollectionViewCell {
    
    var object: TestCollectionDynamicLayoutObject? {
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
            myImageView.fw.constraint(toSuperview: .bottom)?.isActive = TestCollectionController.isExpanded
            fw.maxYViewExpanded = TestCollectionController.isExpanded
        }
    }
    
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
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
    
}

class TestCollectionDynamicLayoutHeaderView: UICollectionReusableView {
    
    lazy var titleLabel: UILabel = {
        let result = UILabel.fw.label(font: UIFont.fw.font(ofSize: 15), textColor: AppTheme.textColor)
        result.numberOfLines = 0
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppTheme.cellColor
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
        titleLabel.fw.constraint(toSuperview: .bottom)?.isActive = TestCollectionController.isExpanded
        fw.maxYViewExpanded = TestCollectionController.isExpanded
    }
    
}

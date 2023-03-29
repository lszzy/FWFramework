//
//  TestCollectionController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/27.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestCollectionController: UIViewController, CollectionViewControllerProtocol, UICollectionViewDelegateFlowLayout, CollectionViewDelegateWaterfallLayout {
    
    typealias CollectionElement = TestCollectionDynamicLayoutObject
    
    static var isExpanded = false
    var mode: Int = 0
    var isWaterfall = false
    var pinHeader = false
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let result = UICollectionViewFlowLayout()
        result.minimumLineSpacing = 0
        result.minimumInteritemSpacing = 0
        return result
    }()
    
    lazy var waterfallLayout: CollectionViewWaterfallLayout = {
        let result = CollectionViewWaterfallLayout()
        result.minimumColumnSpacing = 10
        result.minimumInteritemSpacing = 10
        result.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        result.headerInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        return result
    }()
    
    func setupCollectionViewLayout() -> UICollectionViewLayout {
        if isWaterfall {
            return waterfallLayout
        }
        return flowLayout
    }
    
    func setupCollectionView() {
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = AppTheme.tableColor
        collectionView.app.setRefreshing { [weak self] in
            self?.onRefreshing()
        }
        collectionView.app.setLoading { [weak self] in
            self?.onLoading()
        }
    }
    
    func setupCollectionLayout() {
        collectionView.app.pinEdges(toSuperview: .zero, excludingEdge: .top)
        collectionView.app.pinEdge(toSafeArea: .top)
    }
    
    func setupNavbar() {
        Self.isExpanded = false
        if isWaterfall {
            app.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
                self?.app.showSheet(title: nil, message: nil, cancel: "取消", actions: ["切换Header悬停"], currentIndex: -1, actionBlock: { index in
                    self?.pinHeader = !(self?.pinHeader ?? false)
                    self?.setupSubviews()
                })
            }
        } else {
            app.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
                self?.app.showSheet(title: nil, message: nil, cancel: "取消", actions: ["不固定宽高", "固定宽度", "固定高度", "布局撑开", "布局不撑开", "切换瀑布流", "切换Header悬停"], currentIndex: -1, actionBlock: { index in
                    if index < 3 {
                        self?.mode = index
                        self?.setupSubviews()
                    } else if index < 5 {
                        Self.isExpanded = index == 3 ? true : false
                        self?.setupSubviews()
                    } else if index < 6 {
                        let vc = TestCollectionController()
                        vc.isWaterfall = !(self?.isWaterfall ?? false)
                        self?.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        self?.pinHeader = !(self?.pinHeader ?? false)
                        self?.setupSubviews()
                    }
                })
            }
        }
    }
    
    func setupSubviews() {
        if isWaterfall {
            waterfallLayout.sectionHeadersPinToVisibleBounds = pinHeader
        } else {
            if mode == 2 {
                flowLayout.scrollDirection = .horizontal
            } else {
                flowLayout.scrollDirection = .vertical
            }
            flowLayout.sectionHeadersPinToVisibleBounds = pinHeader
        }
        collectionView.app.beginRefreshing()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        }
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = UICollectionViewCell.app.cell(collectionView: collectionView, indexPath: indexPath)
            cell.contentView.backgroundColor = AppTheme.cellColor
            return cell
        }
        
        let cell = TestCollectionDynamicLayoutCell.app.cell(collectionView: collectionView, indexPath: indexPath)
        cell.object = collectionData[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let reusableView = TestCollectionDynamicLayoutHeaderView.app.reusableView(collectionView: collectionView, kind: kind, indexPath: indexPath)
            reusableView.renderData("我是集合Header\(indexPath.section)\n我是集合Header\(indexPath.section)")
            return reusableView
        } else {
            let reusableView = TestCollectionDynamicLayoutHeaderView.app.reusableView(collectionView: collectionView, kind: kind, indexPath: indexPath)
            reusableView.renderData("我是集合Footer\(indexPath.section)\n我是集合Footer\(indexPath.section)\n我是集合Footer\(indexPath.section)")
            return reusableView
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: isWaterfall ? (APP.screenWidth - 30) / 2.0 : APP.screenWidth, height: 0)
        }
        
        if mode == 0 {
            return collectionView.app.size(cellClass: TestCollectionDynamicLayoutCell.self, width: isWaterfall ? (APP.screenWidth - 30) / 2.0 : APP.screenWidth, cacheBy: indexPath) { [weak self] cell in
                cell.object = self?.collectionData[indexPath.row]
            }
        } else if mode == 1 {
            return collectionView.app.size(cellClass: TestCollectionDynamicLayoutCell.self, width: APP.screenWidth - 30, cacheBy: indexPath) { [weak self] cell in
                cell.object = self?.collectionData[indexPath.row]
            }
        } else {
            return collectionView.app.size(cellClass: TestCollectionDynamicLayoutCell.self, height: APP.screenHeight - APP.topBarHeight, cacheBy: indexPath) { [weak self] cell in
                cell.object = self?.collectionData[indexPath.row]
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForHeaderInSection section: Int) -> CGFloat {
        return self.collectionView(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section).height
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForFooterInSection section: Int) -> CGFloat {
        return self.collectionView(collectionView, layout: collectionViewLayout, referenceSizeForFooterInSection: section).height
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if collectionData.count < 1 {
            return .zero
        }
        
        if mode == 0 {
            return collectionView.app.size(reusableViewClass: TestCollectionDynamicLayoutHeaderView.self, kind: UICollectionView.elementKindSectionHeader, cacheBy: section) { reusableView in
                reusableView.renderData("我是集合Header\(section)\n我是集合Header\(section)")
            }
        } else if mode == 1 {
            return collectionView.app.size(reusableViewClass: TestCollectionDynamicLayoutHeaderView.self, width: APP.screenWidth - 30, kind: UICollectionView.elementKindSectionHeader, cacheBy: section) { reusableView in
                reusableView.renderData("我是集合Header\(section)\n我是集合Header\(section)")
            }
        } else {
            return collectionView.app.size(reusableViewClass: TestCollectionDynamicLayoutHeaderView.self, height: APP.screenHeight - APP.topBarHeight, kind: UICollectionView.elementKindSectionHeader, cacheBy: section) { reusableView in
                reusableView.renderData("我是集合Header\(section)\n我是集合Header\(section)")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if collectionData.count < 1 {
            return .zero
        }
        
        if mode == 0 {
            return collectionView.app.size(reusableViewClass: TestCollectionDynamicLayoutHeaderView.self, kind: UICollectionView.elementKindSectionFooter, cacheBy: section) { reusableView in
                reusableView.renderData("我是集合Footer\(section)\n我是集合Footer\(section)\n我是集合Footer\(section)")
            }
        } else if mode == 1 {
            return collectionView.app.size(reusableViewClass: TestCollectionDynamicLayoutHeaderView.self, width: APP.screenWidth - 30, kind: UICollectionView.elementKindSectionFooter, cacheBy: section) { reusableView in
                reusableView.renderData("我是集合Footer\(section)\n我是集合Footer\(section)\n我是集合Footer\(section)")
            }
        } else {
            return collectionView.app.size(reusableViewClass: TestCollectionDynamicLayoutHeaderView.self, height: APP.screenHeight - APP.topBarHeight, kind: UICollectionView.elementKindSectionFooter, cacheBy: section) { reusableView in
                reusableView.renderData("我是集合Footer\(section)\n我是集合Footer\(section)\n我是集合Footer\(section)")
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
            self.collectionData.removeAll()
            for _ in 0 ..< 4 {
                self.collectionData.append(self.randomObject())
            }
            self.collectionView.app.clearSizeCache()
            self.collectionView.app.reloadDataWithoutAnimation()
            
            self.collectionView.app.shouldRefreshing = self.collectionData.count < 20
            self.collectionView.app.endRefreshing()
            if !self.collectionView.app.shouldRefreshing {
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
                self.collectionData.append(self.randomObject())
            }
            self.collectionView.app.reloadDataWithoutAnimation()
            
            self.collectionView.app.loadingFinished = self.collectionData.count >= 20
            self.collectionView.app.endLoading()
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
            if object.imageUrl.app.isValid(.isUrl) {
                myImageView.app.setImage(url: object.imageUrl, placeholderImage: UIImage.app.appIconImage())
            } else if !object.imageUrl.isEmpty {
                myImageView.image = ModuleBundle.imageNamed(object.imageUrl)
            } else {
                myImageView.image = nil
            }
            myTextLabel.text = object.text
            myImageView.app.constraint(toSuperview: .bottom)?.isActive = TestCollectionController.isExpanded
            app.maxYViewExpanded = TestCollectionController.isExpanded
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
        result.app.setContentModeAspectFill()
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
    
}

class TestCollectionDynamicLayoutHeaderView: UICollectionReusableView {
    
    lazy var titleLabel: UILabel = {
        let result = UILabel.app.label(font: UIFont.app.font(ofSize: 15), textColor: AppTheme.textColor)
        result.numberOfLines = 0
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppTheme.cellColor
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
        titleLabel.app.constraint(toSuperview: .bottom)?.isActive = TestCollectionController.isExpanded
        app.maxYViewExpanded = TestCollectionController.isExpanded
    }
    
}

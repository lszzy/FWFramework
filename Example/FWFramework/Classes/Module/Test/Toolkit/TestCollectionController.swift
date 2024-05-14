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
    
    @StoredValue("testCollectionRandomKey")
    static var testRandomKey: String = ""
    
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
        collectionView.app.addMovementGesture()
    }
    
    func setupCollectionLayout() {
        collectionView.app.pinEdges(toSuperview: .zero, excludingEdge: .top)
        collectionView.app.pinEdge(toSafeArea: .top)
    }
    
    func setupNavbar() {
        Self.isExpanded = false
        if isWaterfall {
            app.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
                self?.app.showSheet(title: nil, message: nil, cancel: "取消", actions: ["切换Header悬停", "reloadData"], currentIndex: -1, actionBlock: { index in
                    if index == 0 {
                        self?.pinHeader = !(self?.pinHeader ?? false)
                        self?.setupSubviews()
                    } else {
                        self?.collectionView.reloadData()
                    }
                })
            }
        } else {
            app.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
                self?.app.showSheet(title: nil, message: nil, cancel: "取消", actions: ["不固定宽高", "固定宽度", "固定高度", "布局撑开", "布局不撑开", "切换瀑布流", "切换Header悬停", "reloadData", "重置图片缓存"], currentIndex: -1, actionBlock: { index in
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
                    } else if index < 7 {
                        self?.pinHeader = !(self?.pinHeader ?? false)
                        self?.setupSubviews()
                    } else if index < 8 {
                        self?.collectionView.reloadData()
                    } else {
                        TestCollectionController.testRandomKey = "\(Date.app.currentTime)"
                        self?.collectionView.reloadData()
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
        cell.imageClicked = { [weak self] object in
            self?.onPhotoBrowser(cell, indexPath: indexPath)
        }
        cell.object = collectionData[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.section == 0 { return }
        
        let object = collectionData[indexPath.row]
        collectionView.app.willDisplay(cell, at: indexPath, key: object.hash) {
            NSLog("曝光index: %@ object: %@", "\(indexPath.row)", "\(object.index)")
        }
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
            return collectionView.app.size(cellClass: TestCollectionDynamicLayoutCell.self, width: isWaterfall ? (APP.screenWidth - 30) / 2.0 : APP.screenWidth/*, cacheBy: indexPath*/) { [weak self] cell in
                cell.object = self?.collectionData[indexPath.row]
            }
        } else if mode == 1 {
            return collectionView.app.size(cellClass: TestCollectionDynamicLayoutCell.self, width: APP.screenWidth - 30/*, cacheBy: indexPath*/) { [weak self] cell in
                cell.object = self?.collectionData[indexPath.row]
            }
        } else {
            return collectionView.app.size(cellClass: TestCollectionDynamicLayoutCell.self, height: APP.screenHeight - APP.topBarHeight/*, cacheBy: indexPath*/) { [weak self] cell in
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
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if indexPath.item == 0 { return false }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let model = collectionData[sourceIndexPath.row]
        collectionData.remove(at: sourceIndexPath.row)
        collectionData.insert(model, at: destinationIndexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath, atCurrentIndexPath currentIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        if proposedIndexPath.item == 0 { return IndexPath(item: 1, section: proposedIndexPath.section) }
        return proposedIndexPath
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
            "https://img2.baidu.com/it/u=1624963289,2527746346&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=750",
            "https://up.enterdesk.com/edpic_source/b0/d1/f3/b0d1f35504e4106d48c84434f2298ada.jpg",
            "https://up.enterdesk.com/edpic_source/eb/34/40/eb34405739ad0e41ec34cd8e16711f30.jpg",
            "https://up.enterdesk.com/edpic_source/05/85/a7/0585a766f5d7702e82f3caf317e6491b.jpg",
            "https://up.enterdesk.com/edpic_source/b4/4a/a7/b44aa778ac9f784ebcee27961d81759f.jpg",
            "https://up.enterdesk.com/edpic_source/3d/42/3e/3d423e3cb05d7edc35c38e3173af2a0d.jpg",
            "https://up.enterdesk.com/edpic_source/84/f7/fc/84f7fcc08f21419a860dbedde45fe233.jpg",
            "https://lmg.jj20.com/up/allimg/1114/042421135351/210424135351-1-1200.jpg",
            "https://img2.baidu.com/it/u=673329217,4275796533&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=889",
            "https://up.enterdesk.com/edpic_source/59/fc/06/59fc069244210ceb384c3fb88ec88121.jpg",
            "https://img1.baidu.com/it/u=2468098533,3730291157&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=800",
            "https://img2.baidu.com/it/u=4228499675,3913167569&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=889",
            "https://m.ixiunv.com/uploadfile/ixiunv-pic/2019/0916/20190916094832595.jpg",
            "https://pics1.baidu.com/feed/377adab44aed2e73f1080b24cbbc338c86d6fa1e.jpeg?token=d6d74d0211e3f22534f0986a53ebf7e8",
        ].randomElement() ?? ""
        object.index = self.collectionData.count
        return object
    }
    
    @objc func onRefreshing() {
        NSLog("开始刷新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            NSLog("刷新完成")
            self.collectionData.removeAll()
            for _ in 0 ..< 5 {
                self.collectionData.append(self.randomObject())
            }
            self.collectionView.app.clearSizeCache()
            self.collectionView.app.reloadDataWithoutAnimation()
            
            self.collectionView.app.shouldRefreshing = self.collectionData.count < 50
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
            for _ in 0 ..< 5 {
                self.collectionData.append(self.randomObject())
            }
            self.collectionView.app.reloadDataWithoutAnimation()
            
            self.collectionView.app.loadingFinished = self.collectionData.count >= 50
            self.collectionView.app.endLoading()
        }
    }
    
    func onPhotoBrowser(_ cell: TestCollectionDynamicLayoutCell, indexPath: IndexPath) {
        var pictureUrls: [Any] = []
        for object in self.collectionData {
            if object.imageUrl.app.isValid(.isUrl) {
                pictureUrls.append(object.imageUrl + (object.imageUrl.contains("?") ? "&" : "?") + "t=\(Self.testRandomKey)")
            } else if object.imageUrl.isEmpty {
                pictureUrls.append(object.imageUrl)
            } else {
                pictureUrls.append(ModuleBundle.imageNamed(object.imageUrl) as Any)
            }
        }
        
        app.showImagePreview(imageURLs: pictureUrls, imageInfos: nil, currentIndex: indexPath.row) { [weak self] index in
            let cell = self?.collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? TestCollectionDynamicLayoutCell
            return cell?.myImageView
        } placeholderImage: { [weak self] index in
            let cell = self?.collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? TestCollectionDynamicLayoutCell
            return cell?.myImageView.image
        }
    }
    
}

class TestCollectionDynamicLayoutObject: NSObject {
    
    var title = ""
    var oldTitle = ""
    var text = ""
    var oldText = ""
    var imageUrl = ""
    var index: Int = 0
    
}

class TestCollectionDynamicLayoutCell: UICollectionViewCell {
    
    var object: TestCollectionDynamicLayoutObject? {
        didSet {
            guard let object = object else { return }
            myTitleLabel.text = object.title
            if object.imageUrl.app.isValid(.isUrl) {
                let imageUrl = object.imageUrl + (object.imageUrl.contains("?") ? "&" : "?") + "t=\(TestCollectionController.testRandomKey)"
                myImageView.app.setImage(url: imageUrl, placeholderImage: UIImage.app.appIconImage()) { [weak self] image, _ in
                    self?.myImageView.image = image
                    if TestTableController.faceAware {
                        self?.myImageView.app.faceAware()
                    }
                }
            } else if !object.imageUrl.isEmpty {
                myImageView.image = ModuleBundle.imageNamed(object.imageUrl)
                if TestTableController.faceAware {
                    myImageView.app.faceAware()
                }
            } else {
                myImageView.image = nil
                if TestTableController.faceAware {
                    myImageView.app.faceAware()
                }
            }
            myTextLabel.text = object.text
            myImageView.app.constraint(toSuperview: .bottom)?.isActive = TestCollectionController.isExpanded
            app.maxYViewExpanded = TestCollectionController.isExpanded
        }
    }
    
    var imageClicked: ((TestCollectionDynamicLayoutObject) -> Void)?
    
    lazy var myTitleLabel: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.font = UIFont.app.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        result.isUserInteractionEnabled = true
        result.app.addTapGesture(target: self, action: #selector(TestCollectionDynamicLayoutCell.onTitleClick(_:)))
        return result
    }()
    
    lazy var myTextLabel: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.font = UIFont.app.font(ofSize: 13)
        result.textColor = AppTheme.textColor
        result.isUserInteractionEnabled = true
        result.app.addTapGesture(target: self, action: #selector(TestCollectionDynamicLayoutCell.onTextClick(_:)))
        return result
    }()
    
    lazy var myImageView: UIImageView = {
        let result = UIImageView()
        result.app.setContentModeAspectFill()
        result.isUserInteractionEnabled = true
        result.app.addTapGesture(target: self, action: #selector(TestCollectionDynamicLayoutCell.onImageClick(_:)))
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
    
    @objc func onImageClick(_ gesture: UIGestureRecognizer) {
        if let object = object {
            imageClicked?(object)
        }
    }
    
    @objc func onTitleClick(_ gesture: UIGestureRecognizer) {
        guard let object = object else { return }
        
        if object.title != "收起标题，点击展开" {
            object.oldTitle = object.title
            object.title = "收起标题，点击展开"
        } else {
            object.title = object.oldTitle
            object.oldTitle = ""
        }
        app.performBatchUpdates { collectionView, indexPath in
            guard let indexPath = indexPath else { return }
            
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    @objc func onTextClick(_ gesture: UIGestureRecognizer) {
        guard let object = object else { return }
        
        if object.text != "收起内容，点击展开" {
            object.oldText = object.text
            object.text = "收起内容，点击展开"
        } else {
            object.text = object.oldText
            object.oldText = ""
        }
        app.performBatchUpdates { collectionView, indexPath in
            guard let indexPath = indexPath else { return }
            
            collectionView.reloadItems(at: [indexPath])
        }
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

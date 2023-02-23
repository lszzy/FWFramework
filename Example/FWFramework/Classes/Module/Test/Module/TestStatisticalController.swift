//
//  TestStatisticalController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/10/19.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestStatisticalController: UIViewController, TableViewControllerProtocol, CollectionViewControllerProtocol {
    
    lazy var shieldView: UIView = {
        let result = UIView()
        result.backgroundColor = AppTheme.tableColor
        result.fw.addTapGesture { [weak self] _ in
            self?.shieldView.isHidden = true
            self?.shieldView.removeFromSuperview()
            // 手工触发曝光计算
            self?.view.isHidden = self?.view.isHidden ?? false
        }
        
        let label = UILabel()
        label.text = "点击关闭"
        label.textAlignment = .center
        result.addSubview(label)
        label.fw.layoutChain.edges()
        return result
    }()
    
    lazy var bannerView: BannerView = {
        let result = BannerView()
        result.autoScroll = true
        result.autoScrollTimeInterval = 6
        result.placeholderImage = UIImage.fw.appIconImage()
        result.itemDidScrollOperationBlock = { index in
            // FW.debug("currentIndex: \(index)")
        }
        return result
    }()
    
    lazy var testView: UIView = {
        let result = UIView()
        result.backgroundColor = UIColor.fw.randomColor
        
        let label = UILabel()
        label.text = "Banner"
        label.textAlignment = .center
        result.addSubview(label)
        label.fw.layoutChain.edges()
        return result
    }()
    
    lazy var testButton: UIButton = {
        let result = UIButton(type: .custom)
        result.setTitle("Button", for: .normal)
        result.fw.setBackgroundColor(UIColor.fw.randomColor, for: .normal)
        return result
    }()
    
    lazy var testSwitch: UISwitch = {
        let result = UISwitch()
        result.thumbTintColor = UIColor.fw.randomColor
        result.onTintColor = result.thumbTintColor
        return result
    }()
    
    lazy var segmentedControl: SegmentedControl = {
        let result = SegmentedControl()
        result.backgroundColor = AppTheme.cellColor
        result.selectedSegmentIndex = 1
        result.selectionStyle = .box
        result.segmentEdgeInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 5)
        result.selectionIndicatorEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        result.segmentWidthStyle = .dynamic
        result.selectionIndicatorLocation = .bottom
        result.titleTextAttributes = [NSAttributedString.Key.font: UIFont.fw.font(ofSize: 16), NSAttributedString.Key.foregroundColor: AppTheme.textColor]
        result.selectedTitleTextAttributes = [NSAttributedString.Key.font: UIFont.fw.boldFont(ofSize: 18), NSAttributedString.Key.foregroundColor: AppTheme.textColor]
        return result
    }()
    
    lazy var tagCollectionView: TextTagCollectionView = {
        let result = TextTagCollectionView()
        result.verticalSpacing = 10
        result.horizontalSpacing = 10
        return result
    }()
    
    func didInitialize() {
        StatisticalManager.shared.statisticalEnabled = true
    }
    
    func setupTableView() {
        let headerView = UIView()
        headerView.addSubview(bannerView)
        bannerView.fw.layoutChain.left(10).top(50).right(10).height(100)
        
        headerView.addSubview(testView)
        testView.fw.layoutChain.width(100).height(30).centerX().top(toViewBottom: bannerView, offset: 50)
        
        headerView.addSubview(testButton)
        testButton.fw.layoutChain.width(100).height(30).centerX().top(toViewBottom: testView, offset: 50)
        
        headerView.addSubview(testSwitch)
        testSwitch.fw.layoutChain.centerX().top(toViewBottom: testButton, offset: 50)
        
        headerView.addSubview(segmentedControl)
        segmentedControl.fw.layoutChain.left(10).right(10).top(toViewBottom: testSwitch, offset: 50).height(50)
        
        headerView.addSubview(tagCollectionView)
        tagCollectionView.fw.layoutChain.left(10).right(10).top(toViewBottom: segmentedControl, offset: 50).height(100).bottom(50)
        
        tableView.tableHeaderView = headerView
        headerView.fw.autoLayoutSubviews()
    }
    
    func setupTableLayout() {
        tableView.fw.layoutChain.edges()
    }
    
    func setupCollectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (FW.screenWidth - 10) / 2.0, height: 100)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        return layout
    }
    
    func setupCollectionLayout() {
        collectionView.fw.layoutChain.edges()
    }
    
    func setupSubviews() {
        UIWindow.fw.main?.addSubview(shieldView)
        shieldView.fw.layoutChain.edges()
        
        testView.fw.addTapGesture { [weak self] _ in
            self?.testView.backgroundColor = UIColor.fw.randomColor
            self?.bannerView.makeScrollScroll(to: 0)
        }
        
        testButton.fw.addTouch { [weak self] _ in
            self?.testButton.fw.setBackgroundColor(UIColor.fw.randomColor, for: .normal)
        }
        
        testSwitch.fw.addBlock({ [weak self] _ in
            self?.testSwitch.thumbTintColor = UIColor.fw.randomColor
            self?.testSwitch.onTintColor = self?.testSwitch.thumbTintColor
        }, for: .valueChanged)
        
        self.bannerView.clickItemOperationBlock = { [weak self] index in
            self?.clickHandler(index)
        }
        
        self.segmentedControl.indexChangeBlock = { [weak self] _ in
            self?.segmentedControl.selectionIndicatorBoxColor = UIColor.fw.randomColor
        }
    }
    
    func setupLayout() {
        collectionView.isHidden = true
        fw.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
            if self?.collectionView.isHidden ?? false {
                self?.collectionView.isHidden = false
                self?.tableView.isHidden = true
            } else {
                self?.collectionView.isHidden = true
                self?.tableView.isHidden = false
            }
        }
        
        let imageUrls = [
            "http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg",
            UIImage.fw.appIconImage() as Any,
            "http://kvm.wuyong.site/images/images/animation.png",
            "http://littlesvr.ca/apng/images/SteamEngine.webp",
            "not_found.jpg",
            "http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"
        ]
        bannerView.imageURLStringsGroup = imageUrls
        
        let sectionTitles = ["Section0", "Section1", "Section2", "Section3", "Section4", "Section5", "Section6", "Section7", "Section8"]
        segmentedControl.sectionTitles = sectionTitles
        
        tagCollectionView.addTags(["标签0", "标签1", "标签2", "标签3", "标签4", "标签5"])
        tagCollectionView.removeTag("标签4")
        tagCollectionView.removeTag("标签5")
        tagCollectionView.addTags(["标签4", "标签5", "标签6", "标签7"])
        
        renderData()
    }
    
    func renderData() {
        StatisticalManager.shared.globalHandler = { [weak self] object in
            if object.isExposure {
                FW.debug("%@曝光通知: \nindexPath: %@\ncount: %@\nname: %@\nobject: %@\nuserInfo: %@\nduration: %@\ntotalDuration: %@", NSStringFromClass(object.view?.classForCoder ?? Self.classForCoder()), "\(object.indexPath?.section ?? 0).\(object.indexPath?.row ?? 0)", "\(object.triggerCount)", FW.safeString(object.name), FW.safeString(object.object), FW.safeString(object.userInfo), "\(object.triggerDuration)", "\(object.totalDuration)")
            } else {
                self?.showToast(String(format: "%@点击事件: \nindexPath: %@\ncount: %@\nname: %@\nobject: %@\nuserInfo: %@", NSStringFromClass(object.view?.classForCoder ?? Self.classForCoder()), "\(object.indexPath?.section ?? 0).\(object.indexPath?.row ?? 0)", "\(object.triggerCount)", FW.safeString(object.name), FW.safeString(object.object), FW.safeString(object.userInfo)))
            }
        }
        
        // ViewController
        fw.statisticalExposure = StatisticalObject(name: "exposure_viewController", object: "viewController")
        
        // Click
        testView.fw.statisticalClick = StatisticalObject(name: "click_view", object: "view")
        testButton.fw.statisticalClick = StatisticalObject(name: "click_button", object: "button")
        testSwitch.fw.statisticalClick = StatisticalObject(name: "click_switch", object: "switch")
        tableView.fw.statisticalClick = StatisticalObject(name: "click_tableView", object: "table")
        bannerView.fw.statisticalClick = StatisticalObject(name: "click_banner", object: "banner")
        segmentedControl.fw.statisticalClick = StatisticalObject(name: "click_segment", object: "segment")
        tagCollectionView.fw.statisticalClick = StatisticalObject(name: "click_tag", object: "tag")
        
        // Exposure
        testView.fw.statisticalExposure = StatisticalObject(name: "exposure_view", object: "view")
        configShieldView(testView.fw.statisticalExposure)
        testButton.fw.statisticalExposure = StatisticalObject(name: "exposure_button", object: "button")
        testButton.fw.statisticalExposure?.triggerOnce = true
        configShieldView(testButton.fw.statisticalExposure)
        testSwitch.fw.statisticalExposure = StatisticalObject(name: "exposure_switch", object: "switch")
        configShieldView(testSwitch.fw.statisticalExposure)
        tableView.fw.statisticalExposure = StatisticalObject(name: "exposure_tableView", object: "table")
        configShieldView(tableView.fw.statisticalExposure)
        bannerView.fw.statisticalExposure = StatisticalObject(name: "exposure_banner", object: "banner")
        configShieldView(bannerView.fw.statisticalExposure)
        segmentedControl.fw.statisticalExposure = StatisticalObject(name: "exposure_segment", object: "segment")
        configShieldView(segmentedControl.fw.statisticalExposure)
        tagCollectionView.fw.statisticalExposure = StatisticalObject(name: "exposure_tag", object: "tag")
        configShieldView(tagCollectionView.fw.statisticalExposure)
    }
    
    func configShieldView(_ object: StatisticalObject?) {
        object?.shieldViewBlock = { [weak self] _ in
            if !(self?.shieldView.isHidden ?? false) {
                return self?.shieldView
            }
            return nil
        }
    }
    
    func showToast(_ message: String) {
        fw.showMessage(text: message)
    }
    
    func clickHandler(_ index: Int) {
        FW.debug("点击了: %@", NSNumber(value: index))
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        50
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(tableView: tableView, style: .default)
        cell.textLabel?.text = "\(indexPath.row)"
        cell.contentView.backgroundColor = UIColor.fw.randomColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.contentView.backgroundColor = UIColor.fw.randomColor
        clickHandler(indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        50
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = TestStatisticalCell.fw.cell(collectionView: collectionView, indexPath: indexPath)
        cell.textLabel.text = "\(indexPath.row)"
        cell.contentView.backgroundColor = UIColor.fw.randomColor
        cell.fw.statisticalClick = StatisticalObject(name: "click_collectionView", object: "cell")
        cell.fw.statisticalExposure = StatisticalObject(name: "exposure_collectionView", object: "cell")
        cell.fw.statisticalExposure?.triggerOnce = true
        configShieldView(cell.fw.statisticalExposure)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.backgroundColor = UIColor.fw.randomColor
        clickHandler(indexPath.row)
    }
    
}

class TestStatisticalCell: UICollectionViewCell {
    
    lazy var textLabel: UILabel = {
        let result = UILabel()
        result.font = UIFont.fw.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(textLabel)
        textLabel.fw.layoutChain.center()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
